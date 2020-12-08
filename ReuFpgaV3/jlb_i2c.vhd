


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.NavBrdPkg.all;

entity jlb_i2c is
port (
	niosClk			: in std_logic;
	niosReset		: in std_logic;
	niosAdr			: in std_logic_vector(9 downto 0);
	niosMosi		: in std_logic_vector(31 downto 0);
	niosWrEna		: in std_logic;
	niosSel			: in std_logic;
	niosMiso		: out std_logic_vector(31 downto 0);
	niosItsMe		: out std_logic;
	niosIntr		: out std_logic;
		
	-- External Interface
	pi2cSDAin	: in	std_logic_vector(3 downto 0);
	i2cSDAout	: out	std_logic_vector(3 downto 0);
	pi2cSCLin	: in	std_logic_vector(3 downto 0);
	i2cSCLout	: out	std_logic_vector(3 downto 0)
);

end jlb_i2c;

architecture Behavioral of jlb_i2c is



constant SET_ERR		: integer := 122;
constant RAISE_SCL		: integer := 123;
constant DROP_SCL		: integer := 124;
constant RAISE_SDA		: integer := 125;
constant DROP_SDA		: integer := 126;
constant BIT_WAIT		: integer := 127;


-- prescaler for the I2C clock. set for a double rate clock
constant CLK_DIV			: integer := 250;

signal txSReg				: std_logic_vector(7 downto 0);
signal rxSReg				: std_logic_vector(7 downto 0);

signal clkPreScale		: integer range 0 to 511;
signal bitCtr				: integer range 0 to 7;

signal bitBusy				: std_logic;
signal bitBusErr			: std_logic;

signal bitSda				: std_logic;
signal bitScl				: std_logic;

signal statusByte			: std_logic_vector(7 downto 0);
signal chanSelReg			: std_logic_vector(7 downto 0);

signal adrLatch			: std_logic_vector(3 downto 0);
signal startLatch		: std_logic;
signal cmdLatch			: std_logic_vector(7 downto 0);
signal opCode			: std_logic_vector(3 downto 0);
signal procBusy			: std_logic;

type fsmStates_t is (fsmIdle, fsmReset,
			fsmStart, fsmStart1, fsmStart2, fsmStart3, fsmStart4,
			fsmStart5,
			fsmStop, fsmStop1, fsmStop2, fsmStop3, fsmStop4,
			fsmDropScl, fsmRaiseScl, fsmDropSda, fsmRaiseSda,
			fsmBitWait, fsmWait1, fsmSetErr, fsmResetErr,
			fsmSendByte, fsmSendByte1, fsmSendByte1a, fsmSendByte2, fsmSendByte3, 
			fsmSendByte4, fsmSendByte4a, fsmSendByte5,
			fsmRxAck, fsmRxAck1, fsmRxAck2, fsmRxAck3, fsmRxAck4, 
			fsmRxAck5, fsmRxAck6, fsmRxAck6a, fsmRxAck7, fsmRxAck8,
			fsmCmdDone);
			
signal fsmState			: fsmStates_t;			

signal resetOpCode	: std_logic := '0';

signal i2cSDAin		: std_logic;
signal i2cSCLin		: std_logic;

signal timerIs0		: std_logic;
signal runTimer		: std_logic;
signal loadTimer		: std_logic;
signal timerReg		: std_logic_vector(15 downto 0);
signal noAck			: std_logic;



begin

	niosItsMe		<= '0';
	niosIntr		<= '0';

-- output pins

process(chanSelReg, bitSda, bitScl, pi2cSDAin, pi2cSCLin)
begin

	i2cSDAout	<= "1111";
	i2cSCLout	<= "1111";
	
	case chanSelReg(1 downto 0) is
	when "00" =>
		i2cSDAout(0)	<= bitSda;
		i2cSCLout(0)	<= bitScl;
		i2cSDAin		<= pi2cSDAin(0);
		i2cSCLin		<= pi2cSCLin(0);
	when "01" =>
		i2cSDAout(1)	<= bitSda;
		i2cSCLout(1)	<= bitScl;
		i2cSDAin		<= pi2cSDAin(1);
		i2cSCLin		<= pi2cSCLin(1);
	when "10" =>
		i2cSDAout(2)	<= bitSda;
		i2cSCLout(2)	<= bitScl;
		i2cSDAin		<= pi2cSDAin(2);
		i2cSCLin		<= pi2cSCLin(2);
	when others =>
		i2cSDAout(3)	<= bitSda;
		i2cSCLout(3)	<= bitScl;
		i2cSDAin		<= pi2cSDAin(3);
		i2cSCLin		<= pi2cSCLin(3);
	end case;
end process;

		
fsm:process(niosClk, niosReset, bitScl, bitSda, 
				fsmState, niosAdr, niosWrEna, niosSel)
variable rtnState				: fsmStates_t;
variable ackBit				: std_logic;
variable startSync			: std_logic_vector(1 downto 0);
begin

	if (niosReset = '1') then
		bitSda			<= '1';
		bitScl			<= '1';
		clkPreScale		<= 0;
		fsmState		<= fsmIdle;
		bitBusy			<= '1';
		ackBit			:= '0';
		resetOpCode		<= '0';
		rxSReg			<= X"00";
		runTimer			<= '0';
		loadTimer		<= '0';
		noAck				<= '0';
	elsif rising_edge(niosClk) then
		bitBusy			<= '1';
		resetOpCode		<= '0';
		runTimer			<= '1';
		case fsmState is
		when fsmIdle =>
			runTimer			<= '0';
			loadTimer		<= '0';
			clkPreScale		<= 0;
			bitCtr			<= 7;
			bitBusy			<= '0';
			
			case opCode is
			when CMD_I2C_START =>
				noAck			<= '0';
			-- this attempts to speed up the process by using the current
			--	state of the SDA and SCL lines to determine what to do next
				if		((bitScl = '1') and (bitSda = '0')) then
					fsmState		<= fsmStart;
				elsif	((bitScl = '0') and (bitSda = '0')) then
					fsmState		<= fsmStart1;
				elsif	((bitScl = '0') and (bitSda = '1')) then
					fsmState		<= fsmStart2;
				else
					fsmState		<= fsmStart3;
				end if;
				
			when CMD_I2C_STOP =>
				noAck			<= '0';
			-- this attempts to speed up the process by using the current
			--	state of the SDA and SCL lines to determine what to do next
				if		((bitScl = '1') and (bitSda = '1')) then
					fsmState		<= fsmStop;
				elsif	((bitScl = '0') and (bitSda = '1')) then
					fsmState		<= fsmStop1;
				elsif	((bitScl = '0') and (bitSda = '0')) then
					fsmState		<= fsmStop2;
				else	
					fsmState		<= fsmStop3;
				end if;

			when CMD_I2C_SENDDAT =>
				noAck			<= '0';
				fsmState		<= fsmSendByte;
				
			when CMD_I2C_RCVACK =>
				ackBit		:= '0';
				noAck			<= '0';
				fsmState		<= fsmRxAck;
			when CMD_I2C_RCVNACK =>
				ackBit		:= '1';
				noAck			<= '0';
				fsmState		<= fsmRxAck;
			when CMD_I2C_RESET =>
				bitSda		<= '1';
				bitScl		<= '1';				
				fsmState		<= fsmResetErr;
			when CMD_I2C_NOP =>
				fsmState		<= fsmIdle;
			when others =>
				fsmState		<= fsmReset;
			end case;
		
	-- START command
		when fsmStart =>
		-- drop SCL
			rtnState				:= fsmStart1;
			fsmState				<= fsmDropScl;
		when fsmStart1 =>
		-- raise SDA
			rtnState				:= fsmStart2;
			fsmState				<= fsmRaiseSda;
		when fsmStart2 =>
		-- raise SCL
			rtnState				:= fsmStart3;
			fsmState				<= fsmRaiseScl;
		when fsmStart3 =>
		-- drop SDA
			loadTimer			<= '1';
			rtnState				:= fsmStart4;
			fsmState				<= fsmDropSda;
		when fsmStart4 =>
		-- drop SCL
			rtnState				:= fsmCmdDone;
			fsmState				<= fsmDropScl;
			
	-- STOP command
		when fsmStop =>
		-- enter here if both SCL and SDA are high
			fsmState			<= fsmDropScl;
			rtnState			:= fsmStop1;
		when fsmStop1 =>
		-- enter here if SCL is low and SDA is high
			fsmState			<= fsmDropSda;
			rtnState			:= fsmStop2;
		when fsmStop2 =>
		-- enter here if SCL is low and SDA is low
			fsmState			<= fsmRaiseScl;
			rtnState			:= fsmStop3;
		when fsmStop3 =>
		-- enter here if SCL is high and SDA is low
			loadTimer		<= '1';
			fsmState			<= fsmRaiseSda;
			rtnState			:= fsmStop4;
		when fsmStop4	=>
			if ((i2cSCLin = '1') and (i2cSDAin = '1')) then
			-- normal state after a STOP
				fsmState		<= fsmCmdDone;
			else
				fsmState		<= fsmSetErr;
			end if;

--------------------------------------------------------------
	-- send a byte of data
	--		the clock is assumed to be low
		when fsmSendByte =>
		-- present the data bit
			loadTimer		<= '1';
			rtnState			:= fsmSendByte1;
			if (txSReg(bitCtr) = '0') then
				fsmState		<= fsmDropSda;
			else
				fsmState		<= fsmRaiseSda;
			end if;
		when fsmSendByte1 =>
			if (bitCtr /= 0) then
				bitCtr		<= bitCtr - 1;
			else
				bitCtr		<= 7;
			end if;
			rtnState			:= fsmSendByte1a;
		-- raise the clock
			fsmState			<= fsmRaiseScl;
		when fsmSendByte1a =>
			rtnState			:= fsmSendByte2; 
			fsmState			<= fsmWait1;
		when fsmSendByte2 =>
		-- drop the clock
			rtnState			:=	fsmSendByte3;
			fsmState			<= fsmDropScl;

		when fsmSendByte3 =>
			if (bitCtr /=7) then
				fsmState		<= fsmSendByte;
			else
				rtnState		:= fsmSendByte4;
				fsmState		<= fsmRaiseSda;
			end if;
			
	-- get the ACK from the slave
		when fsmSendByte4 =>
			rtnState			:= fsmSendByte4a;
		-- raise the clock to clock out the ACK
			fsmState			<= fsmRaiseScl;
		when fsmSendByte4a =>
			fsmState			<= fsmWait1;
			rtnState			:= fsmSendByte5;

		when fsmSendByte5 =>
			if (i2cSDAin = '0') then
				noAck				<= '0';
			else
				noAck				<= '1';
			end if;
			rtnState			:= fsmCmdDone;
			fsmState			<= fsmDropScl;

--------------------------------------------------------------
	-- receive a byte with ACK/NAK
	--		assumes SCL is low
		when fsmRxAck =>		-- 90
			loadTimer		<= '1';
			rtnState			:= fsmRxAck1;
			fsmState			<= fsmRaiseSda;		-- release the bus so the slave can talk
		when fsmRxAck1 =>
			rtnState			:= fsmRxAck2;		
			fsmState			<= fsmRaiseScl;		-- clock out the first bit
		when fsmRxAck2 =>
			rxSReg(bitCtr) 		<= i2cSDAin;
			rtnState			:= fsmRxAck3;		
			fsmState			<= fsmRaiseScl;		-- eat up some time
		when fsmRxAck3 =>
			if (bitCtr /= 0) then
				bitCtr		<= bitCtr - 1;
			else
				bitCtr		<= 7;
			end if;
			rtnState			:= fsmRxAck4;
			fsmState			<= fsmDropScl;
		when fsmRxAck4 =>
			if (bitCtr /=7) then
				rtnState		:= fsmRxAck1;
			else
				rtnState		:= fsmRxAck5;
			end if;
			fsmState		<= fsmDropScl;
		when fsmRxAck5 =>
			rtnState			:= fsmRxAck6;
			if (ackBit = '0') then
				fsmState	<= fsmDropSda;
			else
				fsmState	<= fsmRaiseSda;
			end if;
		when fsmRxAck6 =>
			rtnState			:= fsmRxAck6a;
			fsmState			<= fsmRaiseScl;

		when fsmRxAck6a =>
			rtnState			:= fsmRxAck7;
			fsmState			<= fsmRaiseScl;

		when fsmRxAck7 =>
			rtnState			:= fsmCmdDone;
			fsmState			<= fsmDropScl;
	
		when fsmRxAck8 =>
--			bitBusy			<= '1';
			rtnState			:= fsmCmdDone;
			fsmState			<= fsmBitWait;

--------------------------------------------------------------
		when fsmCmdDone =>
			resetOpCode			<= '1';
			fsmState			<= fsmIdle;

--------------------------------------------------------------
		when fsmSetErr =>
		-- state to set bus error bit
			fsmState			<= fsmCmdDone;
			
		when fsmResetErr =>
			noAck				<= '0';
			fsmState			<= fsmCmdDone;
			
--------------------------------------------------------------
-- routines to control the SCL and SDA lines
--			
		when fsmRaiseScl =>
		-- raise the clock line
			bitScl				<= '1';
			fsmState				<= fsmWait1;
			
		when fsmDropScl =>
		-- drop the clock line
			bitScl				<= '0';
			fsmState				<= fsmWait1;
			
		when fsmRaiseSda =>
		-- raise the data line
			bitSda				<= '1';
			fsmState				<= fsmWait1;
			
		when fsmDropSda =>
		-- drop the data line
			bitSda				<= '0';
			fsmState				<= fsmWait1;
			
--------------------------------------------------------------
-- Set the wait time for 1/2 bit time
--
		when fsmBitWait =>
		-- wait 
			clkPreScale		<= clkPreScale + 1;
			if (clkPreScale = CLK_DIV) then
				clkPreScale		<= 0;
				fsmState			<= fsmWait1;
			end if;
	-- wait 1/4 bit time
		when fsmWait1 =>
			clkPreScale		<= clkPreScale + 1;
			if (clkPreScale = CLK_DIV) then
				clkPreScale		<= 0;
				fsmState			<= rtnState;
			end if;

			
		when fsmReset =>
			bitScl				<= '1';
			bitSda				<= '1';
			rtnState			:= fsmIdle;
			fsmState			<= fsmBitWait;
		
		when others =>
			fsmState			<= fsmIdle;
		end case;
	end if;
	
	if 	(niosReset = '1') then
		bitBusErr	<= '0';
	elsif	(fsmState = fsmResetErr) then
		bitBusErr	<= '0';
	elsif	(fsmState = fsmSetErr) then
		bitBusErr	<= '1';
	elsif	((niosAdr = ADR_I2C_STATREG) and 
			 (niosWrEna = '1') and 
			 (niosSel = '1')) then
		bitBusErr	<= '0';
	end if;
	
end process;

------------------------------------------------
-- This process interfaces with the processor.
procIfc:process(niosClk, niosReset, resetOpCode)
variable timer					: std_logic_vector(15 downto 0);
begin
-- write to the registers
	if (niosReset = '1') then
		opCode			<= CMD_I2C_NOP;
		chanSelReg		<= X"00";
		txSReg			<= X"00";
	elsif (resetOpCode = '1') then
		opCode			<= CMD_I2C_NOP;
	elsif rising_edge(niosClk) then
		if ((niosSel = '1') and (niosWrEna = '1')) then
			case niosAdr(3 downto 0) is
			when ADR_I2C_RXDATREG =>
				txSReg		<= niosMosi(7 downto 0);
			when ADR_I2C_SELREG =>
				chanSelReg	<= niosMosi(7 downto 0);
			when ADR_I2C_CMDREG =>
				opCode		<= niosMosi(3 downto 0);
			when ADR_I2C_TIMERREG =>
				timerReg		<= niosMosi(15 downto 0);
			when others =>
				null;
			end case;
		end if;
		
		if (loadTimer = '1') then
			timer		:= timerReg;
		elsif ((runTimer = '1') and
				 (timer /= X"0000")) then
			timer		:= timer - 1;
		end if;
		
	end if;
	
	if (timer = X"0000") then
		timerIs0		<= '1';
	else
		timerIs0		<= '0';
	end if;

end process;


	statusByte	<= i2cSDAin & i2cSCLin & "00" & noAck & timerIs0 & bitBusErr & bitBusy;

	with niosAdr(3 downto 0) select niosMiso <=
		X"000000" & rxSReg			when ADR_I2C_RXDATREG,
		X"000000" & statusByte		when ADR_I2C_STATREG,
		X"000000" & chanSelReg		when ADR_I2C_SELREG,
		x"0000"   & timerReg			when ADR_I2C_TIMERREG,
		X"00000000"					when others;


end Behavioral;
