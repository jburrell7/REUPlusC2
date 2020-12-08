
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.T80_Pack.all;

entity reuT80s is
	port(
		sdramClk			: in std_logic;
		sdramRWCmd		: out std_logic;
		sdramRfshCmd	: out std_logic;
		sdramWr_n		: out std_logic;
		sdramAddr		: out std_logic_vector(24 downto 0);
		sdramQ			: in std_logic_vector(15 downto 0);
		sdramD			: out std_logic_vector(15 downto 0);
		sdramCmdDone	: in std_logic;
		sdramFsmIdle	: in std_logic;
		
		reset_n			: in std_logic;
		cpuClk			: in std_logic;
		CEN				: in std_logic		:= '1';
		ioDatIn			: in std_logic_vector(7 downto 0);
		ioDatOut			: out std_logic_vector(7 downto 0);
		ioAdr				: out std_logic_vector(15 downto 0);
		
	-- mailbox signals
		z80MbrAdr		: out std_logic_vector(8 downto 0);
		z80MbrD			: out std_logic_vector(7 downto 0);
		z80MbrQ			: in std_logic_vector(7 downto 0);
		z80MbrSel		: out std_logic;
		z80ProcReset	: in std_logic;
		
		mreq_n			: out std_logic;
		iorq_n			: out std_logic;
		rd_n				: out std_logic;
		wr_n				: out std_logic
	);
end reuT80s;



architecture rtl of reuT80s is
constant ADR_BANKREG0			: std_logic_vector(7 downto 0) := x"30";
constant ADR_BANKREG1			: std_logic_vector(7 downto 0) := x"31";
constant ADR_BANKREG2			: std_logic_vector(7 downto 0) := x"32";
constant ADR_BANKREG3			: std_logic_vector(7 downto 0) := x"33";

constant MBR_BANK_REG			: std_logic_vector(7 downto 0) := x"29";
constant MBREG0					: std_logic_vector(7 downto 0) := x"30";
constant MBREG16					: std_logic_vector(7 downto 0) := x"3F";


signal z80Mreq_n		: std_logic;
signal z80Ioreq_n		: std_logic;
signal z80Rd_n			: std_logic;
signal z80Wr_n			: std_logic;
signal z80Rfsh_n		: std_logic;
signal z80Addr			: std_logic_vector(15 downto 0);
signal z80Din			: std_logic_vector( 7 downto 0);
signal z80Dout			: std_logic_vector( 7 downto 0);

signal memBank			: std_logic_vector( 7 downto 0);

signal z80RstNode				: std_logic;


begin

	sdramD		<= z80Dout & z80Dout;
	sdramAddr	<= "111" & memBank & z80Addr(13 downto 0);
	ioDatOut		<= z80Dout;
	ioAdr			<= z80Addr;
	mreq_n		<= z80Mreq_n;
	iorq_n		<= z80Ioreq_n;
	rd_n			<= z80Rd_n;
	wr_n			<= z80Wr_n;

	z80RstNode		<= reset_n and z80ProcReset;
	
z80:work.T80s
	generic map(
		Mode		=> 0,				-- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
		T2Write	=> 0,				-- 0 => WR_n active in T3, /=0 => WR_n active in T2
		IOWait	=> 1				-- 0 => Single cycle I/O, 1 => Std I/O cycle
	)
	port map(
		RESET_n	=> z80RstNode,
		CLK_n		=> cpuClk,
		CEN		=> CEN,
		WAIT_n	=> '1',
		INT_n		=> '1',
		NMI_n		=> '1',
		BUSRQ_n	=> '1',
		M1_n		=> open,
		MREQ_n	=> z80Mreq_n,
		IORQ_n	=> z80Ioreq_n,
		RD_n		=> z80Rd_n,
		WR_n		=> z80Wr_n,
		RFSH_n	=> z80Rfsh_n,
		HALT_n	=> open,
		BUSAK_n	=> open,
		A			=> z80Addr,
		DI			=> z80Din,
		DO			=> z80Dout
	);
	
	
bankRegs:process(reset_n, z80Addr, z80Ioreq_n, 
						z80Wr_n, ioDatIn, z80Mreq_n, 
						sdramQ)
						
variable bankReg0			: std_logic_vector(7 downto 0);
variable bankReg1			: std_logic_vector(7 downto 0);
variable bankReg2			: std_logic_vector(7 downto 0);
variable bankReg3			: std_logic_vector(7 downto 0);
variable mailboxReg		: std_logic_vector(7 downto 0);
variable z80MbrBAdrReg	: std_logic_vector(7 downto 0);
begin

	if (reset_n = '0') then
		bankReg0				:= x"00";
		bankReg0				:= x"01";
		bankReg0				:= x"02";
		bankReg0				:= x"03";
	elsif (rising_edge(z80Wr_n) and (z80Ioreq_n = '0')) then
		if		(z80Addr(7 downto 0) = ADR_BANKREG0) then
			bankReg0			:= z80Dout;
		elsif	(z80Addr(7 downto 0) = ADR_BANKREG1) then
			bankReg1			:= z80Dout;
		elsif	(z80Addr(7 downto 0) = ADR_BANKREG2) then
			bankReg2			:= z80Dout;
		elsif	(z80Addr(7 downto 0) = ADR_BANKREG3) then
			bankReg3			:= z80Dout;

-- this register selects one of the 32 16-byte banks
--		in the 512 byte mailbox
		elsif	(z80Addr(7 downto 0) = MBR_BANK_REG) then
			z80MbrBAdrReg	:= z80Dout;
		else
			null;
		end if;
	end if;
	


	z80MbrAdr		<= z80MbrBAdrReg(4 downto 0) & z80Addr(3 downto 0);
	z80MbrD			<= z80Dout;
	z80MbrSel		<= '0';
	
-- I/O read
	if (z80Ioreq_n = '0') then
		if		(z80Addr(7 downto 0) = ADR_BANKREG0) then
			z80Din						<= bankReg0;
		elsif	(z80Addr(7 downto 0) = ADR_BANKREG1) then
			z80Din						<= bankReg0;
		elsif	(z80Addr(7 downto 0) = ADR_BANKREG2) then
			z80Din						<= bankReg0;
		elsif	(z80Addr(7 downto 0) = ADR_BANKREG3) then
			z80Din						<= bankReg0;
		elsif ((z80Addr(7 downto 0) >= MBREG0) and (z80Addr(7 downto 0) <= MBREG16)) then
			z80Din						<= z80MbrQ;
			z80MbrSel					<= '1';
		elsif	(z80Addr(7 downto 0) = MBR_BANK_REG) then
			z80Din						<= z80MbrBAdrReg;
		else
			z80Din		<= ioDatIn;
		end if;
	elsif	(z80Mreq_n = '0') then
		if (z80Addr(0) = '0') then
			z80Din		<= sdramQ( 7 downto 0);
		else
			z80Din		<= sdramQ(15 downto 8);
		end if;
	else
		z80Din			<= x"00";
	end if;
	
	if		(z80Addr(15 downto 14) = "00") then
		memBank		<= bankReg0;
	elsif	(z80Addr(15 downto 14) = "01") then
		memBank		<= bankReg1;
	elsif	(z80Addr(15 downto 14) = "10") then
		memBank		<= bankReg2;
	else
		memBank		<= bankReg3;
	end if;

end process; 	
	
sdram:process(sdramClk, reset_n)
variable sdrState			: integer range 0 to 7;
variable memrqSync		: std_logic;
variable rfshSync			: std_logic;
begin

	if		(reset_n = '0') then
		sdrState			:= 0;
		sdramRWCmd		<= '0';
		sdramRfshCmd	<= '0';
		sdramWr_n		<= '1';
	elsif rising_edge(sdramClk) then
		case sdrState is
		when 0 =>
			sdramRWCmd		<= '0';
			sdramRfshCmd	<= '0';
			sdramWr_n		<= '1';
			
			if		(memrqSync = '0') then
				if		(z80Rd_n = '0') then
					sdramRWCmd		<= '1';
					sdrState			:= 1;
				elsif	(z80Wr_n = '0') then
					sdramRWCmd		<= '1';
					sdramWr_n		<= '0';
					sdrState			:= 1;
				end if;
			elsif	(rfshSync = '0') then
				sdramRfshCmd		<= '1';
				sdrState				:= 3;
			end if;
		when 1 =>
		-- process a memory read or write command
			if	(sdramFsmIdle = '0') then
				sdrState			:= 2;
			end if;
		when 2 =>
			if (memrqSync = '1') then
				sdrState			:= 0;
			end if;
			
		when 3 =>
		-- process a refresh
			if	(sdramFsmIdle = '0') then
				sdrState			:= 4;
			end if;
		when 4 =>
			if (rfshSync = '1') then
				sdrState			:= 0;
			end if;		
		when others =>
			sdrState			:= 0;
		end case;
	end if;
		
	if		(reset_n = '0') then
		memrqSync		:= '1';
		rfshSync			:= '1';
	elsif rising_edge(sdramClk) then
		memrqSync		:= z80Mreq_n;
		rfshSync			:= z80Rfsh_n;
	end if;
		

end process;


	
end;
