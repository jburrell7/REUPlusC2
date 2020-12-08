-- CSG REU/REC compatible RAM expansion controller
-- initial version: 2.9.2001 by Rainer Buchty (rainer@buchty.net)
-- syntactically correct, but completely untested -- so use at your own risk
--
-- 32MB DRAM to 64kB C64 memory controller
--
--
--
--
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use work.Reu2c5_pkg.all;

entity R8800R1 is
generic(
	ADR_REG_START			: std_logic_vector(7 downto 0) := x"00";
	ADR_REG_END				: std_logic_vector(7 downto 0) := x"3F"
	);
port(
	clk100			: in std_logic;								-- system level clock
	rst_n				: in std_logic;
	
	reuDisable		: in std_logic;
	
-- C64 bus records
--		these records are defined in the QmTechREU_pkg
	c64BusDrv		: out t_c64BusDrive;			-- signals that drive the C64 bus
	c64BusInputs	: in t_c64BusInputs;			-- signals from the C64 bus

	reuHasBus		: out std_logic;
	reuActive		: out std_logic;
	phiPosEdge		: in std_logic;
	davPos			: in std_logic;
	davNeg			: in std_logic;
	
	syncPhi2			: in std_logic;
	
	debug				: out std_logic_vector(15 downto 0);
	
-- SDRAM signals
	sdramAdr			: out std_logic_vector(24 downto 0);
	sdramDatTo		: out std_logic_vector(15 downto 0);
	sdramRfshCmd	: out std_logic;
	sdramRWCmd		: out std_logic;
	sdramWe_n		: out std_logic;
	
	sdramDatFrom	: in std_logic_vector(15 downto 0);
	sdramOpDone		: in std_logic;
	sdramFsmIdle	: in std_logic
    );
end entity;



-- --------------------------------------------------------------------------
architecture arch_rec of R8800R1 is

----------- REU registers and nodes
signal regReuImr				: std_logic_vector(2 downto 0);
signal regReuAcr				: std_logic_vector(1 downto 0);
signal regReuAdr64			: std_logic_vector(15 downto 0);
signal regReuAdrMem			: std_logic_vector(23 downto 0);
signal regReuXfrLen			: std_logic_vector(15 downto 0);
signal regReuXpsa				: std_logic_vector(7 downto 0);

signal regRomLowBase			: std_logic_vector(15 downto 0);
signal regRomHighBase		: std_logic_vector(15 downto 0);
signal regMemBase				: std_logic_vector(16 downto 0);

signal reuDatOutNode			: std_logic_vector(7 downto 0);
signal dmaDataReg				: std_logic_vector(7 downto 0);

signal reuAdr					: std_logic_vector(23 downto 0);

signal dmaDatOutNode			: std_logic_vector(7 downto 0);
signal dmaAdrNode				: std_logic_vector(31 downto 0);

	
signal iHaveTheBus			: std_logic;
signal sdramDataFromReg		: std_logic_vector(7 downto 0);

signal stateNr					: std_logic_vector(2 downto 0);


---- main state machine
type t_memStates	is (
		init, idle,
		
		reu, reu1,
		
		cpu2reu, cpu2reu1, cpu2Reu2, cpu2Reu3,
		
		reu2cpu, reu2cpu1, reu2cpu2, reu2cpu3,
		
		reuSwap, reuSwap1, reuSwap2, reuSwap3,
		reuVerify, reuVerify1, reuVerify2, reuVerify3,
		reuC64Write, reuC64Write1, reuC64Write2, reuC64Write3, reuC64Write4,
		reuC64Read, reuC64Read1, reuC64Read2, 
		
		sdramWait, sdramWait1,
		
		reuHousekeep, reuHousekeep1, reuHousekeep2,
		
		waitMemAccess, waitMemAccess1, waitMemAccess2,
		
		regAccess,
		regRd, regRd1, regRd2,
		regWr, regWr1, regWr2,
		
		sdramWr1, sdramWr2, sdramRd1, sdramRd2, sdramRd3,
		doRfrsh, doRfrsh1, doRfrsh2, doRfrsh3,
		
		rdRegs, rdRegs1, rdRegs2,
		wrRegs, wrRegs1, wrRegs2,
		
		eepRd1, eep, eep1
		);
		
signal memStates			: t_memStates;
signal rtnState			: t_memStates;


signal reuRunning				: std_logic;
signal reuRdRegSpace			: std_logic;

signal execute, ff00			: std_logic;
signal tt						: std_logic_vector(1 downto 0);
signal trb						: std_logic_vector(1 downto 0);
signal load						: std_logic;
--
---- SR
signal ip, eob, fault		: std_logic;
constant version				: std_logic_vector(3 downto 0):="0000";

-- transfer control registers
signal base_reu				: std_logic_vector(31 downto 0);
signal base_c64				: std_logic_vector(15 downto 0);
signal xfer_cnt				: std_logic_vector(15 downto 0);

signal ff00Flag				: std_logic;

signal regNode					: std_logic_vector(7 downto 0);
signal size						: std_logic := '1';

signal setEob					: std_logic;
signal setFault				: std_logic;

--------------------------------------
-- C64 bus control signals
--
signal reuNwr1				: std_logic;
signal reuRnwDrv			: std_logic;
signal reuAdrDir			: std_logic;
signal reuDatDir			: std_logic;
signal reuDmaCtl			: std_logic;
signal c64AdrOut			: std_logic_vector(15 downto 0);
signal c64DatOut			: std_logic_vector( 7 downto 0);

signal c64DataFromReg	: std_logic_vector(7 downto 0);

signal testNode			: std_logic;
signal useMem				: std_logic;
signal useDma				: std_logic;
signal useEpLow			: std_logic;
signal useEpHigh			: std_logic;

signal memAccessNode		: std_logic;

signal sramOpDoneNode	: std_logic;
signal sramOpDoneRst		: std_logic;

signal syncRnW					: std_logic;
signal syncIo1					: std_logic;
signal syncIo2					: std_logic;
signal syncRomH				: std_logic;
signal syncRomL				: std_logic;
signal syncBa					: std_logic;

signal sdramAdrNode		: std_logic_vector(24 downto 0);

signal sdrInDataNode		: std_logic_vector(7 downto 0);

signal sdramFsmIdleSync		: std_logic;
signal fsmIdle					: std_logic;

signal reuRegSpace			: std_logic;

begin

	debug(0)			<= fault;

-- convenience signal - '1' when the REU register space is being addressed
	reuRegSpace		<= '1' when ((c64BusInputs.adrIn(7 downto 0) >= ADR_REG_START) and 
										 (c64BusInputs.adrIn(7 downto 0) <= ADR_REG_END) and 
										 (c64BusInputs.io2_n = '0')) else
							'0';


-- assign the interrupt bit
	sdrInDataNode	<= sdramDatFrom( 7 downto 0) when (sdramAdrNode(0) = '0') else
							sdramDatFrom(15 downto 8);
	
	
signalSync:process(clk100)
begin

	if rising_edge(clk100) then
		syncRnW			<= c64BusInputs.rnw;
		syncIo1			<= c64BusInputs.io1_n;
		syncIo2			<= c64BusInputs.io2_n;
		syncRomH			<= c64BusInputs.romh_n;
		syncRomL			<= c64BusInputs.roml_n;
		syncBa			<= c64BusInputs.ba;
	end if;

end process;

	
busMux:process(reuRdRegSpace, regReuImr, ip, reuRunning, regNode,
					reuDmaCtl, reuNwr1, reuRnwDrv, reuAdrDir, 
					reuDatDir, base_c64, sdramDataFromReg, base_reu, 
					c64DataFromReg, useMem, useDma, useEpLow, useEpHigh,
					regMemBase, c64BusInputs, regRomLowBase, 
					regRomHighBase, sdramAdrNode)
begin	

-- the default state removes the REU from the
--		C64 bus
	c64BusDrv				<= C64DRV_DEFAULT;
	c64BusDrv.irq_n		<= not ip;				
	c64BusDrv.dma_n		<= reuDmaCtl;
	
	if	(reuRunning = '1') then
		if (reuRdRegSpace = '1') then
		-- reading from the REU registers
		--		all other signals are set by C64DRV_DEFAULT
			c64BusDrv.dat_dir		<= DATA_TO_C64;
			c64BusDrv.dat			<=	regNode;
		else
		-- the REU is doing its thing
			c64BusDrv.nwr1			<= reuNwr1;
			c64BusDrv.rnw_drv		<= reuRnwDrv;
			
			c64BusDrv.adr_dir		<= reuAdrDir;
			c64BusDrv.adr			<=	base_c64;
			
			c64BusDrv.dat_dir		<= reuDatDir;
			c64BusDrv.dat			<=	sdramDataFromReg;
		end if;	
	end if;
--
-- gate address and data to the SDRAM
--
	if		(useMem = '1') then
		sdramAdrNode	<= regMemBase & c64BusInputs.adrIn(7 downto 0);
		sdramDatTo		<= c64BusInputs.datIn & c64BusInputs.datIn;	
--	elsif	(useDma = '1') then
	elsif	(useEpLow = '1') then
		sdramAdrNode	<= regRomLowBase(11 downto 0) & c64BusInputs.adrIn(12 downto 0);
		sdramDatTo		<= c64BusInputs.datIn & c64BusInputs.datIn;
	elsif	(useEpHigh = '1') then
		sdramAdrNode	<= regRomHighBase(11 downto 0) & c64BusInputs.adrIn(12 downto 0);
		sdramDatTo		<= c64BusInputs.datIn & c64BusInputs.datIn;
	else
		sdramAdrNode	<= base_reu(24 downto 0);
		sdramDatTo		<= c64DataFromReg & c64DataFromReg;
	end if;
	
	sdramAdr		<= sdramAdrNode;
	
end process;

-- high if the REU registers are being read or if 
	reuHasBus			<= reuRunning;
	reuActive			<= reuRunning;
	iHaveTheBus			<= syncPhi2 and syncBa;
	
-- --------------------------------------------------------------------------
--
-- --------------------------------------------------------------------------
mainFsm:process(clk100, rst_n, regReuImr, eob, fault, syncRnW,
					syncIo1, syncIo2, syncRomH, syncRomL, syncBa)
					
variable bufReg						: std_logic_vector(7 downto 0);
begin

	memAccessNode		<= syncIo1 and syncRomH and syncRomL;

	if (rst_n = '0') then
	-- initialize the registers
		regReuAdr64		<= x"0000";		-- shadow
		base_c64			<= x"0000";		-- counter
		regReuAdrMem	<= x"000000";	-- shadow
		base_reu			<= x"00000000";-- counter
		regReuXfrLen	<= x"FFFF";		-- shadow
		xfer_cnt			<= x"FFFF";		-- counter
	-- initialize the interrupt mask register
		regReuImr			<= "000";
		regReuAcr			<= "00";
		regReuXpsa			<= x"00";
		
		regRomLowBase		<= (others => '0');
		regRomHighBase		<= (others => '0');
		regMemBase			<= (others => '0');
		
		execute				<= '0';
		load					<= '0';
		ff00					<= '1';
		fault					<= '0';
		eob					<= '0';
		ip						<= '0';

		reuRunning			<= '0';
		reuRdRegSpace		<= '0';
		reuDmaCtl			<= '1';
	
		memStates		<= init;
		
		sdramRfshCmd	<= '0';
		sdramRWCmd		<= '0';
		sdramWe_n		<= '1';


		reuNwr1			<= not ASSERT_WRGATE;
		reuRnwDrv		<= not ASSERT_WENA;
		reuAdrDir		<= ADRS_FROM_C64;
		reuDatDir		<= DATA_FROM_C64;
		
		testNode			<= '0';
		
		useMem			<= '0';
		useDma			<= '0';
		useEpLow			<= '0';
		useEpHigh		<= '0';
		sramOpDoneRst	<= '1';
		
		fsmIdle			<= '0';
		
	stateNr			<= "000";

	
	elsif rising_edge(clk100) then
	
		sdramRfshCmd	<= '0';
		sdramRWCmd		<= '0';	

		reuNwr1			<= not ASSERT_WRGATE;
		reuRnwDrv		<= not ASSERT_WENA;
		reuAdrDir		<= ADRS_FROM_C64;
		reuDatDir		<= DATA_FROM_C64;
		reuRdRegSpace	<= '0';
		sramOpDoneRst	<= '0';

		testNode			<= '0';
		
		fsmIdle			<= '0';

		case memStates is
		when init =>
		-- set up the REU after reset
			reuRunning			<= '0';
			reuDmaCtl			<= '1';
			
			useMem			<= '0';
			useDma			<= '0';
			useEpLow			<= '0';
			useEpHigh		<= '0';
			
			memStates			<= idle;
			testNode				<= '0';
		when idle =>
			fsmIdle				<= '1';
			reuRunning			<= '0';
			reuDmaCtl			<= '1';
			sdramWe_n			<= '1';
			sramOpDoneRst		<= '1';

--
-- original working (sorta')		
--		
			if (reuDisable = '0') then
				if		((execute = '1') and ((ff00 or ff00Flag) = '1')) then
				-- REU DMA is active
					if (syncPhi2 = '0') then
						memStates	<= reu;
					else
						memStates	<= idle;
					end if;
				elsif	((syncIo2 = '0') and (syncRnw = '0') and 
						 (reuRegSpace = '1')) then
				-- write to REU register space
					reuRunning	<= '1';
					if (davPos = '1') then
					-- write to the REU registers
						memStates	<= wrRegs;
					end if;
				elsif	((syncIo2 = '0') and (phiPosEdge = '1') and
						 (syncRnw = '1') and (reuRegSpace = '1')) then
					reuRunning	<= '1';
				-- read from the REU registers
					memStates	<= rdRegs;
				elsif	((syncRomL = '0') and (syncRnw = '0')) then
				-- write to the low EEPROM
					reuRunning	<= '1';
					useEpLow		<= '1';
					if (davPos = '1') then
						memStates	<= sdramWr1;
						rtnState		<= eep;
					end if;
				elsif	((syncRomL = '0') and (phiPosEdge = '1') and
						 (syncRnw = '1')) then
				-- read from the low EEPROM
					reuRunning	<= '1';
					useEpLow		<= '1';
					reuDatDir	<= DATA_TO_C64;
					memStates	<= eepRd1;
				elsif	((syncRomH = '0') and (syncRnw = '0')) then
				-- write to the high EEPROM
					reuRunning	<= '1';
					useEpHigh	<= '1';
					if (davPos = '1') then
						memStates	<= sdramWr1;
						rtnState		<= eep;
					end if;
				elsif	((syncRomH = '0') and (phiPosEdge = '1') and
						 (syncRnw = '1')) then
				-- read from the high EEPROM
					reuRunning	<= '1';
					useEpHigh	<= '1';
					reuDatDir	<= DATA_TO_C64;
					memStates	<= eepRd1;
				elsif	((syncIo1 = '0') and (syncRnw = '0')) then
				-- write to the SDRAM via the 256 byte window at Io1
					reuRunning	<= '1';
					useMem		<= '1';
					if (davPos = '1') then
						memStates	<= sdramWr1;
						rtnState		<= eep;
					end if;
				elsif	((syncIo1 = '0') and (phiPosEdge = '1') and
						 (syncRnw = '1')) then
				-- read from the SDRAM via the 256 byte window at Io1
					reuRunning	<= '1';
					useMem		<= '1';
					reuDatDir	<= DATA_TO_C64;
					memStates	<= eepRd1;					
				elsif	(davNeg = '1') then
					reuRunning	<= '0';
				-- do a refresh cycle
					memStates	<= doRfrsh;
					rtnState		<= idle;
				else
					reuRunning	<= '0';
					rtnState		<= idle;
				end if;		
			else
				memStates	<= idle;					
			end if;
-------------------------------  Standard REU   -------------------------------
		when reu =>	
		-- When we get here we will be in VIC II time AND
		--	the 6510 will next be reading an instrunction so it 
		-- will be safe to assert the DMA command in the next state.
			reuDmaCtl			<= '0';
			reuRunning			<= '1';
			if (syncPhi2 = '1') then
			-- transfer the shadow registers to the counters	
				base_c64			<= regReuAdr64;
				base_reu			<= regReuXpsa & regReuAdrMem;
				xfer_cnt			<= regReuXfrLen;
				memStates		<= reu1;
			else
				memStates		<= reu;
			end if;	
			
		when reu1 =>
			sdramWe_n			<= '1';
			if (execute = '1') then
				if (syncPhi2 = '0') then
					case tt is
					when XFR_C64TORAM =>			-- C64 -> REU
						memStates		<= cpu2reu;
					when XFR_RAMTOC64 =>			-- REU -> C64
					-- read a byte from the sdram
						memStates		<= sdramRd1;
						rtnState			<= reu2cpu;
					when XFR_SWAP =>				-- SWAP
					-- read a byte from the c64
						memStates		<= sdramRd1;
						rtnState			<= reuSwap;
					when others =>					-- VERIFY
						memStates		<= sdramRd1;
						rtnState			<= reuVerify;
					end case;
				else
					memStates			<= reu1;
				end if;
			else
				eob			<= '1';
				ip				<= (regReuImr(2) and (regReuImr(0) and '1')) or
									(regReuImr(2) and (regReuImr(1) and fault));
				memStates	<= idle;
			end if;
			
-----------------------------------------------------------		
-- housekeeping for the REU
--
		when reuHousekeep =>
		-- update the address counters
			if (regReuAcr(0) = '0') then
			-- increment the expansion address
				if (base_reu = x"FFFFFFFF") then
					base_reu		<= (others => '0');
				else
					base_reu		<= base_reu + 1;
				end if;
			end if;

			if (regReuAcr(1) = '0') then
			-- increment the C64 address
				if (base_c64 = x"FFFF") then
					base_c64		<= (others => '0');
				else
					base_c64		<= base_c64 + 1;
				end if;
			end if;
			memStates			<= reuHousekeep1;
		when reuHousekeep1 =>
			if (xfer_cnt = x"0001") then
			-- we are done			
			-- disable the execute bit
				execute			<= '0';
			-- load the shadow registers from the counters.
			--		if the user does not reload the the shadow
			--		registers, we will pick up from where we left
			--		off. The user must reprogram the transfer
			--		length or only one byte will be transferred
				if (load = '1') then
					base_c64							<= regReuAdr64;
					base_reu(31 downto 24)		<= regReuXpsa;
					base_reu(23 downto  0)		<= regReuAdrMem;
					xfer_cnt							<= regReuXfrLen;
				else
					regReuAdr64						<= base_c64;
					regReuXpsa						<= base_reu(31 downto 24);
					regReuAdrMem					<= base_reu(23 downto  0);
					regReuXfrLen					<= xfer_cnt;
				end if;
				memStates		<= reu1;
			else
			-- decrement the transfer count and loop back
			--		for more
				if (xfer_cnt = x"0000") then
					xfer_cnt		<= (others => '1');
				else
					xfer_cnt		<= xfer_cnt - 1;
				end if;
				memStates		<= reuHousekeep2;
			end if;
		when reuHousekeep2 =>
			memStates		<= reu1;
	
	
		when eepRd1 =>
		-- this state allows the C64 address bus to settle
			if (phiPosEdge = '0') then
				memStates	<= sdramrd1;
				rtnState		<= eep;
			else
				memStates	<= eepRd1;
			end if;
			
		when eep =>
		-- release the SDRAM lines
			useMem			<= '0';
			useDma			<= '0';
			useEpLow			<= '0';
			useEpHigh		<= '0';
			memStates		<= eep1;
		when eep1 =>
		-- wait until the access cycle
		--		is complete
			if (memAccessNode = '1') then
				reuDatDir	<= DATA_FROM_C64;
				memStates	<= idle;
			else
				memStates	<= eep1;
			end if;
	
-----------------------------------------------------------		
-- transfer one byte C64 -> REU
--
		when cpu2reu =>
			if (iHaveTheBus = '1') then
			-- wait until we can read from the C64
				rtnState		<= cpu2reu1;
				memStates	<= reuC64Read;
			else
				rtnState		<= cpu2reu;
			end if;
		when cpu2reu1 =>
		-- write the c64 byte to the SDRAM
			rtnState		<= cpu2reu2;
			memStates	<= sdramWr1;
		when cpu2reu2 =>
			rtnState		<= cpu2reu3;
			memStates	<= doRfrsh;
		when cpu2reu3 =>
			if (syncPhi2 = '0') then
			-- spin here until we are in the second half
			--		of phi2. this may or may not waste
			--		some time, but we have it to spare
				memStates	<= reuHousekeep;
			else
--				memStates	<= cpu2reu1;
				memStates	<= cpu2reu3;
			end if;

-----------------------------------------------------------		
-- transfer one byte REU -> C64
--
--	The FSM has already read a byte from the SDRAM.
--
		when reu2cpu =>
			rtnState		<= reu2cpu1;
			memStates	<= doRfrsh;
			
		when reu2cpu1 =>
	-- wait until we can access the C64 bus
			if (iHaveTheBus = '1') then
				rtnState		<= reuHousekeep;
				memStates	<= reuC64Write;
			else
				memStates	<= reu2cpu1;
			end if;
			
-----------------------------------------------------------		
-- SWAP one byte between the REU and C64
--
-- The FSM has already read a byte from the SDRAM
--
		when reuSwap =>
		-- read the required byte from the C64
			if (iHaveTheBus = '1') then
			-- wait until we can read from the C64
				rtnState		<= reuSwap1;
				memStates	<= reuC64Read;
			else
				memStates	<= reuSwap;
			end if;
		when reuSwap1 =>
		-- write the byte to the SDRAM
		-- write the c64 byte to the SDRAM
			rtnState		<= reuSwap2;
			memStates	<= sdramWr1;			
		when reuSwap2 =>
		-- do a refresh
			rtnState		<= reuSwap3;
			memStates	<= doRfrsh;
		when reuSwap3 =>
		-- write the byte to the C64
			if (iHaveTheBus = '1') then
				rtnState		<= reuHousekeep;
				memStates	<= reuC64Write;
			else
				memStates	<= reuSwap3;
			end if;
			
-----------------------------------------------------------		
-- VERIFY an REU and C64 byte
--
-- The FSM has already read a byte from the SDRAM
--
		when reuVerify	 =>
		-- read the required byte from the C64
			if (iHaveTheBus = '1') then
			-- wait until we can read from the C64
				rtnState		<= reuVerify1;
				memStates	<= reuC64Read;
			else
				rtnState		<= reuVerify;
			end if;
		when reuVerify1 =>
		-- do a refresh
			rtnState		<= reuVerify2;
			memStates	<= doRfrsh;
		when reuVerify2 =>
			if (c64DataFromReg /= sdramDataFromReg) then
				fault		<= '1';
				execute	<= '0';
			end if;
			memStates	<= reuHousekeep;
			
--------- write a byte to the C64
-- Note that we try to emulate the 6510 to allow
--		the PLA to do its thing
		when reuC64Write =>
		-- assert all control signals for the full
		--	phi2 time
			reuNwr1			<= ASSERT_WRGATE;
			reuRnwDrv		<= ASSERT_WENA;
			reuAdrDir		<= ADRS_TO_C64;
			reuDatDir		<= DATA_TO_C64;
			memStates		<= reuC64Write1;
			if (syncPhi2 = '0') then
				memStates	<= reuC64Write1;
			else
				memStates	<= reuC64Write;
			end if;
		when reuC64Write1 =>
		-- first drive the write enable high
			reuNwr1			<= ASSERT_WRGATE;
			reuRnwDrv		<= not ASSERT_WENA;
			reuAdrDir		<= ADRS_TO_C64;
			reuDatDir		<= DATA_to_C64;
			memStates		<= reuC64Write2;
		when reuC64Write2 =>
		-- last, release the drive to the write enable
			reuNwr1			<= not ASSERT_WRGATE;
			reuRnwDrv		<= not ASSERT_WENA;
			reuAdrDir		<= ADRS_TO_C64;
			reuDatDir		<= DATA_to_C64;
			memStates		<= rtnState;

-----------------------------------------------------------		
-- read a byte from the C64
-- Note that we try to emulate the 6510 to allow
--		the PLA to do its thing
		when reuC64Read =>
			reuNwr1			<=  not ASSERT_WRGATE;
			reuRnwDrv		<=  not ASSERT_WENA;
			reuAdrDir		<=  ADRS_TO_C64;
			reuDatDir		<=  DATA_FROM_C64;
--			if (davPos = '1') then
-- wait until the last instant to latch the data
			if (syncPhi2 = '0') then
				c64DataFromReg	<= c64BusInputs.datIn;
				memStates		<= reuC64Read1;
			else
				memStates		<= reuC64Read;
			end if;
		when reuC64Read1 =>
		-- don't drive the C64 bus since we are coming up on
		--		VIC II time
			reuAdrDir		<= ADRS_FROM_C64;
			memStates		<= rtnState;
		
-------------------------------  SDRAM commands -------------------------------		
		when sdramWr1 =>
		-- perform a SDRAM write			
			sdramRWCmd			<= '1';
			sdramWe_n			<= '0';
			if (sdramFsmIdleSync = '1') then
				memStates		<= sdramWr1;
			else
				memStates		<= sdramWait;
			end if;
		when sdramRd1 =>
		-- perform a SDRAM read
			sdramRWCmd			<= '1';
			if (sdramFsmIdleSync = '1') then
				memStates		<= sdramRd1;
			else
				memStates		<= sdramRd2;
			end if;
		when sdramRd2 =>
		-- wait until the data lines settle in the upper
		--		level multiplexers
			memStates		<= sdramRd3;
		when sdramRd3 =>
			memStates		<= sdramWait;
			
			
		when sdramWait =>
			testNode					<= '1';
		-- wait for the SDRAM to be done
			if (sramOpDoneNode = '1') then
--				testNode				<= '1';
			-- latch the SDRAM data. if a write operation was done
			--	this is a safe thing to do since nobody will look at it
				if (sdramAdrNode(0) = '0') then
					sdramDataFromReg	<= sdramDatFrom(7 downto 0);
				else
					sdramDataFromReg	<= sdramDatFrom(15 downto 8);
				end if;
				sdramWe_n		<= '1';
				memStates		<= sdramWait1;
			else
			-- wait for SDRAM to complete the operation
				memStates		<= sdramWait;
			end if;
		when sdramWait1 =>
			sramOpDoneRst		<= '1';
			memStates			<= rtnState;

------------------------------------------------------------------
-- Perform a SDRAM refresh
		when doRfrsh =>
			sdramRfshCmd	<= '1';
			memStates		<= doRfrsh1;
		when doRfrsh1 =>
			sdramRfshCmd	<= '1';
			memStates		<= doRfrsh2;
		when doRfrsh2 =>
			sdramRfshCmd	<= '1';
			memStates		<= doRfrsh3;
		when doRfrsh3 =>
			if ((sramOpDoneNode = '1') and (davNeg = '0')) then
			-- return to caller
				memStates	<= sdramWait1;
			else
			-- wait for SDRAM to complete the operation
				memStates	<= doRfrsh3;
			end if;

------------------------------------------------------------------
-- Allow the C64 to write to the REU register file
--
		when wrRegs =>
			case c64BusInputs.adrIn(7 downto 0) is
			when REU_CTL_REG =>  -- CR
				execute		<= c64BusInputs.datIn(7);
				load			<= c64BusInputs.datIn(5);
				ff00			<= c64BusInputs.datIn(4);
				tt				<= c64BusInputs.datIn(1 downto 0);
				trb			<= c64BusInputs.datIn(3 downto 2);	-- emulates real REU
	-------------------------------------------------------------------------		
	-- This section of code mimics the behavior of the real REU registers.
	--	When one byte of a 16 bit register is loaded (say R2/R3) the counter
	--	byte is loaded simultaneously. In addition, the opposite counter 
	--	byte is updated from the corresponding shadow register
			when REU_64ADRL_REG =>  -- c64 start address
				regReuAdr64( 7 downto 0)	<= c64BusInputs.datIn;
				base_c64(7 downto 0)			<= c64BusInputs.datIn;
				base_c64(15 downto 8)		<= regReuAdr64(15 downto 8);
				
			when REU_64ADRH_REG =>
				regReuAdr64(15 downto 8)	<= c64BusInputs.datIn;
				base_c64(15 downto 8)		<= c64BusInputs.datIn;
				base_c64(7 downto 0)			<= regReuAdr64(7 downto 0);
				
			when REU_XPADRL_REG =>  -- reu start address
				regReuAdrMem( 7 downto 0)	<= c64BusInputs.datIn;
				base_reu( 7 downto  0)		<= c64BusInputs.datIn;
				base_reu(15 downto 8)		<= regReuAdrMem(15 downto 8);
				
			when REU_XPADRM_REG =>
				regReuAdrMem(15 downto 8)	<= c64BusInputs.datIn;
				base_reu(15 downto 8)		<= c64BusInputs.datIn;
				base_reu(7 downto 0)			<= regReuAdrMem(7 downto 0);

			when REU_XPADRH_REG =>
			-- this is a standalone register, so handle it as such
				regReuAdrMem(23 downto  16)	<= c64BusInputs.datIn;
				base_reu(23 downto 16)			<= c64BusInputs.datIn;
				
			when REU_XFRL_REG =>  -- transfer length
				regReuXfrLen( 7 downto  0)		<= c64BusInputs.datIn;
				xfer_cnt( 7 downto  0)			<= c64BusInputs.datIn;
				xfer_cnt(15 downto 8)			<= regReuXfrLen(15 downto 8);

			when REU_XFRH_REG =>
				regReuXfrLen(15 downto  8)		<= c64BusInputs.datIn;
				xfer_cnt(15 downto  8)			<= c64BusInputs.datIn;
				xfer_cnt(7 downto 0)				<= regReuXfrLen(7 downto 0);

			when REU_IMR_REG =>  -- IMR
				regReuImr							<= c64BusInputs.datIn(7 downto 5);
			when REU_ACR_REG =>  -- ACR
				regReuAcr							<= c64BusInputs.datIn(7 downto 6);
			when REU_SBANK_REG =>
				regReuXpsa							<= c64BusInputs.datIn;
				
			when ROML_BASELOW =>
				regRomLowBase( 7 downto  0)		<= c64BusInputs.datIn;
			when ROML_BASEHIGH =>
				regRomLowBase(15 downto  8)		<= c64BusInputs.datIn;
				
			when ROMH_BASELOW =>
				regRomHighBase( 7 downto  0)		<= c64BusInputs.datIn;
			when ROMH_BASEHIGH =>
				regRomHighBase(15 downto  8)		<= c64BusInputs.datIn;
				
			when MEM_BASELOW =>
				regMemBase( 7 downto  0)			<= c64BusInputs.datIn;
			when MEM_BASEMID =>
				regMemBase(15 downto  8)			<= c64BusInputs.datIn;
			when MEM_BASEHIGH =>
				regMemBase(16)							<= c64BusInputs.datIn(0);
				
			when others =>
				null;
			end case;

			
			memStates		<= wrRegs1;				
		when wrRegs1 =>
			if (davPos = '0') then
				memStates	<= idle;
			else
				memStates	<= wrRegs1;
			end if;
			
------------------------------------------------------------------
-- read the REU registers
--
		when rdRegs =>
		-- spin here until we are sure the C64 address bus is
		--		stable
			reuRdRegSpace	<= '1';
			if (davPos = '1') then
				memStates	<= rdRegs1;
			else
				memStates	<= rdRegs;
			end if;
		
			reuRdRegSpace			<= '1';
			case c64BusInputs.adrIn(7 downto 0) is
				when REU_STAT_REG =>  -- SR
					regNode			<= ip & eob & fault & size & version;
				when REU_CTL_REG =>  -- CR
					regNode			<= execute & '1' & load & ff00 & trb & tt;
				when REU_64ADRL_REG =>  -- c64 start address
					regNode			<= base_c64( 7 downto  0);
				when REU_64ADRH_REG =>
					regNode			<= base_c64(15 downto  8);
				when REU_XPADRL_REG =>  -- reu start address
					regNode			<= base_reu( 7 downto  0);
				when REU_XPADRM_REG =>
					regNode			<= base_reu(15 downto  8);
				when REU_XPADRH_REG =>
				-- this is a standalone register, so handle it as such
					regNode			<= "11111" & base_reu(18 downto  16);
				when REU_XFRL_REG =>  -- transfer length
					regNode			<= xfer_cnt( 7 downto  0);
				when REU_XFRH_REG =>
					regNode			<= xfer_cnt(15 downto  8);
				when REU_IMR_REG =>  -- IMR
					regNode			<= regReuImr & "11111";
				when REU_ACR_REG =>  -- ACR
					regNode			<= regReuAcr & "111111";
					
				when REU_XPADRH_REGX =>
					regNode			<= base_reu(23 downto  16);
				when REU_SBANK_REG =>
					regNode			<= regReuXpsa;
					
				when ROML_BASELOW =>
					regNode			<= regRomLowBase(7 downto 0);
				when ROML_BASEHIGH =>
					regNode			<= regRomLowBase(15 downto 8);
					
				when ROMH_BASELOW =>
					regNode			<= regRomHighBase(7 downto 0);
				when ROMH_BASEHIGH =>
					regNode			<= regRomHighBase(15 downto 8);
					
				when MEM_BASELOW =>
					regNode			<= regMemBase(7 downto 0);
				when MEM_BASEMID =>
					regNode			<= regMemBase(15 downto 8);
				when MEM_BASEHIGH =>
					regNode			<= "0000000" & regMemBase(16);
				when others =>
					reuRdRegSpace	<= '0';
					regNode			<= X"FF";
			end case;
	
		when rdRegs1 =>
		-- spin here until we are in VIC II time
			if (syncPhi2 = '0') then
				memStates	<= idle;		-- rdRegs2;
			else
				memStates	<= rdRegs2;
			end if;
		when rdRegs2 =>
		-- the C64 has the flag data, so clear them
			if (c64BusInputs.adrIn(7 downto 0) = REU_STAT_REG) then 
				fault				<= '0';
				eob				<= '0';
				ip					<= '0';
			end if;
			memStates		<= idle;
------------------------------------------------------------------
			
		when others =>
			memStates	<= init;
			execute		<= '0';
		end case;
	end if;
	
	
	if rising_edge(clk100) then
		sdramFsmIdleSync		<= sdramFsmIdle;
	end if;
	
	if rising_edge(clk100) then
		if ((c64BusInputs.adrIn = x"FF00") and (syncPhi2 = '1') and (memStates = idle)) then
			ff00Flag		<= '1';
		else
			ff00Flag		<= '0';
		end if;
	end if;
	
end process;

latOpDone:process(c64BusInputs, sramOpDoneRst, sdramOpDone)
begin

	if (sramOpDoneRst = '1') then
		sramOpDoneNode			<= '0';
	elsif rising_edge(sdramOpDone) then
		sramOpDoneNode			<= '1';
	end if;
		 
end process;

	

end architecture;

