
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.Reu2c5_pkg.all;


entity Reu2c5 is
	PORT
	(
		CLOCK50			: in std_logic;
		RESET_SW			: in std_logic;
		
		DRAM_CAS_N		: out std_logic;
		DRAM_RAS_N		: out std_logic;
		DRAM_LDQM		: out std_logic;
		DRAM_WE_N		: out std_logic;
		DRAM_CLK			: out std_logic;
		DRAM_UDQM		: out std_logic;
		DRAM_ADDR		: out std_logic_vector(12 downto 0);
		DRAM_CKE			: out std_logic;
		DRAM_BA			: out std_logic_vector(1 downto 0);
		DRAM_CS_N		: out std_logic;
		DRAM_DQ			: inout std_logic_vector(15 downto 0);
		
		VIDEO				: out std_logic;
		VSYNC				: out std_logic;
		HSYNC				: out std_logic;

		RTC_SDA			: inout std_logic;
		RTC_SCL			: inout std_logic;

		F_RST_N			: in std_logic;
		F_PHI2			: in std_logic;
		F_DOTCLK			: in std_logic;
		F_BA				: in std_logic;
		F_RNW				: in std_logic;
		F_IO1_N			: in std_logic;
		F_IO2_N			: in std_logic;
		F_ROMH_N			: in std_logic;
		F_ROML_N			: in std_logic;

		F_DMA_N			: out std_logic;
		F_GAME_N			: out std_logic;
		F_EXROM_N		: out std_logic;
		F_IRQ_N			: out std_logic;

		F_ADR				: inout std_logic_vector(15 downto 0);
		F_DAT				: inout std_logic_vector(7 downto 0);

		F_NWR1			: out std_logic;
		F_RNWDRV			: out std_logic;
		ADR_DIR			: out std_logic;
		DAT_DIR			: out std_logic
	);

END Reu2c5;


architecture behave of Reu2c5 is
constant FPGA_VER			: std_logic_vector(7 downto 0) := conv_std_logic_vector(11, 8);

constant BIT_I2C_SCLDRV		: integer := 0;
constant BIT_I2C_SDADRV		: integer := 1;
constant BIT_I2C_REGOP		: integer := 2;
constant BIT_I2C_DATDIR		: integer := 3;
constant BIT_I2C_RDY			: integer := 4;
constant BIT_I2C_ACKBIT		: integer := 5;
constant BIT_I2C_SCLPIN		: integer := 6;
constant BIT_I2C_SDAPIN		: integer := 7;

-- this will disable the boot rom on reset
--constant BOOTROM_RSTVAL		: std_logic := '1';
-- this will enable the boot rom on reset
constant BOOTROM_RSTVAL		: std_logic := '0';



type t_copRegs is array (0 to 7) of std_logic_vector(7 downto 0);
signal c64ToCopRegs		: t_copRegs;
signal copToC64Regs		: t_copRegs;

-------------------------------------------
-- clock PLL signals
--
signal clk100				: std_logic;
signal clk100dly			: std_logic;
signal clk50				: std_logic;
signal pllLocked			: std_logic;
-------------------------------------------
-- timing generator signals
--
signal phi2Sync			: std_logic;
signal dlyCpuWr			: std_logic;
signal dlyCpuRd			: std_logic;
signal phi2PosEdge		: std_logic;
signal phi2NegEdge		: std_logic;
signal davPos				: std_logic;
signal davNeg				: std_logic;
-------------------------------------------
-- C64 bus signals
--
signal c64BusDrive_node		: t_c64BusDrive;
signal c64BusInputs			: t_c64BusInputs;

signal reuC64Drive			: t_c64BusDrive;
signal cpuC64Drive			: t_c64BusDrive;
signal ezRomC64Drive			: t_c64BusDrive;
signal regsC64Drive			: t_c64BusDrive;

signal c64BusDrvIsReu		: std_logic;
signal c64BusDrvIsRegs		: std_logic;

-------------------------------------------
-- QmTech SDRAM
--
signal dramCke				: std_logic;
signal dramCsn				: std_logic;
signal dramRasn			: std_logic;
signal dramCasn			: std_logic;
signal dramWen				: std_logic;
signal dramBa				: std_logic_vector( 1 downto 0);
signal dramAddr			: std_logic_vector(12 downto 0);
signal dramDq				: std_logic_vector(15 downto 0);
signal dramUdqm			: std_logic;
signal dramLdqm			: std_logic;
signal dramClkNode		: std_logic;


-------------------------------------------
-- REU SDRAM memory signals
--
signal reuRfrshCmd		: std_logic;
signal reuMemRwCmd		: std_logic;
signal reuMemRdy			: std_logic;
signal reuMemWena_n		: std_logic;
signal reuMemDatIn		: std_logic_vector(15 downto 0);
signal reuMemAdr			: std_logic_vector(24 downto 0);
signal reuActive			: std_logic;

-- read output from the SDRAM controller
signal sdramMemQ			: std_logic_vector(15 downto 0);
-- REU side of the cop DPSR
signal copMbReuQ			: std_logic_vector(15 downto 0);
signal copMbReuBena		: std_logic_vector(1 downto 0);
signal copMbReuSel		: std_logic;
signal copMbReuWena		: std_logic;

-------------------------------------------
-- misc signals

-------------------------------------------
-- signals to keep Modelsim happy
signal sdramRst			: std_logic;
signal sramUb				: std_logic;

signal reuDebug			: std_logic_vector(15 downto 0);

signal clkCtr				: std_logic_vector(31 downto 0);
signal ledNode				: std_logic;


signal rstNode				: std_logic;
signal syncReset_n		: std_logic;
signal syncReset			: std_logic;
signal syncResetSreg		: std_logic_vector(3 downto 0);
signal syncResetCtr		: integer range 0 to 524287;
signal syncResetState	: integer range 0 to 3;


signal key0Sync			: std_logic_vector(3 downto 0) := "0000";
signal c64RstSync			: std_logic_vector(3 downto 0) := "0000";


signal reuRegSpace		: std_logic;
signal tstNode				: std_logic;

signal adrNode				: std_logic_vector(15 downto 0);
signal adrDirNode			: std_logic;
signal datOutNode			: std_logic_vector(7 downto 0);
signal datDirNode			: std_logic;

signal debugNode			: std_logic_vector(15 downto 0);

-----------------------------------------------------------
-- Z80 signals
signal z80sdramRWCmd			: std_logic;
signal z80sdramRfshCmd		: std_logic;
signal z80sdramWr_n			: std_logic;
signal z80sdramAddr			: std_logic_vector(24 downto 0);
signal z80sdramQ				: std_logic_vector(15 downto 0);
signal z80sdramD				: std_logic_vector(15 downto 0);
signal z80sdramCmdDone		: std_logic;
signal z80sdramFsmIdle		: std_logic;

signal z80ioDatIn				: std_logic_vector(7 downto 0);
signal z80ioDatOut			: std_logic_vector(7 downto 0);
signal z80ioAdr				: std_logic_vector(15 downto 0);
signal z80mreq_n				: std_logic;
signal z80iorq_n				: std_logic;
signal z80rd_n					: std_logic;
signal z80wr_n					: std_logic;
signal z80CEN					: std_logic;
signal z80Reset_n				: std_logic;

signal copEnaReg			: std_logic		:= '0';
signal enaCopLatch		: std_logic;
signal enaC64Latch		: std_logic;
signal copFsmState		: integer range 0 to 3;

signal sdcRfrshCmd		: std_logic;
signal sdcRW				: std_logic;
signal sdcWe_n				: std_logic;
signal sdcAddr				: std_logic_vector(23 downto 0);
signal sdcDatIn			: std_logic_vector(15 downto 0);
signal sdcUb				: std_logic;
signal sdcLb				: std_logic;
signal sdcRdy				: std_logic;
signal sdcCmdDone			: std_logic;
signal sdcFsmIdle			: std_logic;
signal sdcMemQ				: std_logic_vector(15 downto 0);

signal vidDatOutC64		: std_logic_vector(7 downto 0);
signal vidItsMeC64		: std_logic	:= '0';
signal hSyncNode			: std_logic;
signal vSyncNode			: std_logic;
signal vidNode				: std_logic;

signal iHaveTheBus		: std_logic;
signal useCop				: std_logic;
signal copSel				: std_logic;

signal rdBackRegs			: std_logic;
signal regsNode			: std_logic_vector(7 downto 0);
signal copHasSdram		: std_logic;
signal copHasVid			: std_logic;



signal dmaNode				: std_logic;

signal i2cItsMeCop			: std_logic;
signal i2cDatOutCop			: std_logic_vector(7 downto 0);
signal vidItsMeCop			: std_logic;
signal vidDatOutCop			: std_logic_vector(7 downto 0);
signal epcsItsMeCop			: std_logic;
signal epcsDatOutCop			: std_logic_vector(7 downto 0);

signal testTrig				: std_logic;
signal copClk					: std_logic;
signal romCtlReg				: std_logic_vector(7 downto 0);

signal z80MbrAdr				: std_logic_vector(8 downto 0);
signal z80MbrD					: std_logic_vector(7 downto 0);
signal z80MbrQ					: std_logic_vector(7 downto 0);
signal z80MbrSel				: std_logic;
signal z80MbrWena				: std_logic;
signal z80ProcReset			: std_logic;

signal mboxC64Adr				: std_logic_vector(7 downto 0);
signal mboxC64Q				: std_logic_vector(7 downto 0);
signal mboxMemWeNode			: std_logic;
signal mboxC64Wena			: std_logic;

signal reuDisableNode		: std_logic;
signal bitDEnableReu			: std_logic;
signal bromDat					: std_logic_vector(7 downto 0);

signal regCopCtl				: std_logic_vector(7 downto 0);
signal i2cbbReg				: std_logic_vector(7 downto 0);
signal i2cWrDatReg			: std_logic_vector(7 downto 0);
signal i2cShiftReg			: std_logic_vector(7 downto 0);
signal i2cCmdReg				: std_logic_vector(7 downto 0);
signal i2cShifterRdy			: std_logic;
signal i2cAckNode				: std_logic;
signal sdaNode					: std_logic;
signal sclNode					: std_logic;
signal i2cClrCmd				: std_logic;
signal i2cIsIdle				: std_logic;

signal enaBootRom				: std_logic;


begin

	copSel			<= copHasSdram;

	F_ADR			<= adrNode		when (adrDirNode = ADRS_TO_C64) else
						"ZZZZZZZZZZZZZZZZ";
	F_DAT			<= datOutNode	when (datDirNode = DATA_TO_C64) else
						"ZZZZZZZZ";
	ADR_DIR  	<= adrDirNode;				-- adr_dir
	DAT_DIR  	<= datDirNode;				-- dat_dir

	iHaveTheBus	<= F_BA and F_PHI2 and F_RNW;
	
	
---------------------------------------------
-- C64 bus signal assignments
--
c64Drv:process(reuC64Drive, c64BusDrvIsReu, F_RNW, 
					vidItsMeC64, vidDatOutC64, iHaveTheBus, 
					dmaNode, copSel)
begin
----------- Outputs to the C64 -----------
	if (c64BusDrvIsReu = '1') then
	-- the REU is in control of the C64 bus
		dmaNode  	<= reuC64Drive.dma_n;
		F_NWR1   	<= reuC64Drive.nwr1;
		F_RNWDRV 	<= reuC64Drive.rnw_drv;

		adrDirNode	<= reuC64Drive.adr_dir;
		adrNode		<= reuC64Drive.adr;
		datDirNode	<= reuC64Drive.dat_dir;		
		datOutNode	<= reuC64Drive.dat;
		
		

	elsif ((F_ROML_N = '0') and (bitDEnableReu = '0')) then
	-- using the boot ROM
		F_NWR1   	<= not ASSERT_WRGATE;
		F_RNWDRV 	<=	not ASSERT_WENA;
		adrDirNode	<= ADRS_FROM_C64;
		adrNode		<= "----------------";
		datDirNode	<= DATA_TO_C64;
		datOutNode	<= bromDat;
	elsif	(rdBackRegs = '1') then
--		dmaNode		<= '1';
		F_NWR1   	<= not ASSERT_WRGATE;
		F_RNWDRV 	<=	not ASSERT_WENA;
		adrDirNode	<= ADRS_FROM_C64;
		adrNode		<= "----------------";
		datDirNode	<= DATA_TO_C64;
		datOutNode	<= regsNode;
	elsif	(vidItsMeC64 = '1') then
--		dmaNode		<= '1';
		F_NWR1   	<= not ASSERT_WRGATE;
		F_RNWDRV 	<=	not ASSERT_WENA;
		adrDirNode	<= ADRS_FROM_C64;
		adrNode		<= "----------------";
		datDirNode	<= DATA_TO_C64;
		datOutNode	<= vidDatOutC64;
	else
	-- default C64 bus assignments
		dmaNode		<= '1';
		F_NWR1   	<= not ASSERT_WRGATE;
		F_RNWDRV 	<=	not ASSERT_WENA;
		
		adrDirNode	<= ADRS_FROM_C64;
		adrNode		<= "----------------";
		datDirNode	<= DATA_FROM_C64;	
		datOutNode	<= "--------";
	end if;

	F_DMA_N		<= dmaNode;	
	F_IRQ_N  	<= reuC64Drive.irq_n;	
end process;

---------- Inputs from the C64 -----------
	c64BusInputs.rst_n		<= syncReset_n;
	c64BusInputs.romh_n		<= F_ROMH_N;
	c64BusInputs.phi2			<= F_PHI2;
	c64BusInputs.rnw			<= F_RNW;
	c64BusInputs.dotClk		<= F_DOTCLK;
	c64BusInputs.io1_n		<= F_IO1_N;
	c64BusInputs.io2_n		<= F_IO2_N;
-- inhibit this signal if the boot ROM is active
-- this will cause the REU to be blind to the C64
--	accessing the ROML bank when the boot ROM is
--	in use.
	c64BusInputs.roml_n		<= F_ROML_N or enaBootRom;
	c64BusInputs.ba			<= F_BA;
	c64BusInputs.adrIn		<= F_ADR;
	c64BusInputs.datIn		<= F_DAT;


	reuDisableNode			<= copSel or bitDEnableReu;
	
	
reu88:work.R8800R1
	generic map(
	ADR_REG_START	=> REU_REG_START,
	ADR_REG_END		=> REU_REG_END
	)
	port map(
	clk100			=> clk100,
	rst_n				=> syncReset_n,
	
	reuDisable		=> copSel,

	c64BusDrv		=> reuC64Drive,
	c64BusInputs	=> c64BusInputs,

	reuHasBus		=> c64BusDrvIsReu,
	reuActive		=> reuActive,
	phiPosEdge		=> phi2PosEdge,
	davPos			=> davPos,
	davNeg			=> davNeg,

	syncPhi2			=> phi2Sync,

	debug				=> reuDebug,

	sdramAdr			=> reuMemAdr,
	sdramDatTo		=> reuMemDatIn,
	sdramRfshCmd	=> reuRfrshCmd,
	sdramRWCmd		=> reuMemRwCmd,
	sdramWe_n		=> reuMemWena_n,

	sdramDatFrom	=> sdcMemQ,
	sdramOpDone		=> sdcCmdDone,
	sdramFsmIdle	=> sdcFsmIdle
    );

process(copSel, reuRfrshCmd, reuMemRwCmd, reuMemWena_n, 
			reuMemAdr, reuMemDatIn, z80sdramRfshCmd, 
			z80sdramRWCmd, z80sdramWr_n, z80sdramAddr,
			z80sdramD)
begin
	 if (copSel = '0') then
-- assign the R8800 signals to the SDRAM controller
		sdcRfrshCmd		<= reuRfrshCmd;
		sdcRW				<= reuMemRwCmd;
		sdcWe_n			<= reuMemWena_n;
		sdcAddr			<= reuMemAdr(24 downto 1);
		sdcDatIn			<= reuMemDatIn;
		sdcUb				<= not reuMemAdr(0);
		sdcLb				<= reuMemAdr(0);
	else
-- assign the Z80 signals to the SDRAM controller
		sdcRfrshCmd			<= z80sdramRfshCmd;
		sdcRW					<= z80sdramRWCmd;		
		sdcWe_n				<= z80sdramWr_n;
		sdcAddr				<= z80sdramAddr(24 downto 1);
		sdcDatIn				<= z80sdramD;
		z80sdramQ			<= sdcMemQ;
		z80sdramCmdDone	<= sdcCmdDone;
		sdcUb					<= not z80sdramAddr(0);
		sdcLb					<= z80sdramAddr(0);
	end if;
end process;
	
	
reuMem:sdramSimple4Mx4x2
	port map(
	-- Host side
		clk_100m0_i		=> clk100,
		reset_i			=> sdramRst,

		refresh_i		=> sdcRfrshCmd,
		rw_i				=> sdcRW,
		we_i				=> sdcWe_n,
		addr_i			=> sdcAddr,
		data_i			=> sdcDatIn,
		ub_i				=> sdcUb,
		lb_i				=> sdcLb,
		ready_o			=> sdcRdy,
		done_o			=> sdcCmdDone,
		idle_o			=> sdcFsmIdle,
		data_o			=> sdcMemQ,

	-- SDRAM side
		sdCke_o			=> DRAM_CKE,
		sdCe_bo			=> DRAM_CS_N,
		sdRas_bo			=> DRAM_RAS_N,
		sdCas_bo			=> DRAM_CAS_N,
		sdWe_bo			=> DRAM_WE_N,
		sdBs_o			=> DRAM_BA,
		sdAddr_o			=> DRAM_ADDR,
		sdData_io		=> DRAM_DQ,
		sdDqmh_o			=> DRAM_UDQM,
		sdDqml_o			=> DRAM_LDQM
		);
	DRAM_CLK				<= not clk100;		--clk100dly;
	

tgen:work.timingGen
	port map(
	rst_n				=> pllLocked,
	clk50_i			=> CLOCK50,
	phi2				=> c64BusInputs.phi2,

	phi2Sync			=> phi2Sync,
	phi2PosEdge		=> phi2PosEdge,
	davPos			=> davPos,
	phi2NegEdge		=> phi2NegEdge,
	davNeg			=> davNeg,
	
	clk50_o			=> clk50,
	clk100_o			=> clk100,
	clk100dly		=> clk100dly,
	pllLocked		=> pllLocked,
	copClk			=> copClk,
	
	RESET_SW			=> RESET_SW,
	F_RST_N			=> F_RST_N,
	sdcRdy			=> sdcRdy,
	sdramRst			=> sdramRst,
	syncReset_n		=> syncReset_n,
	syncReset		=> syncReset
);

	
process(syncReset_n, F_IO2_N, F_RNW, F_ADR, 
			davPos, RTC_SDA, RTC_SCL)
begin
	
	if (syncReset_n = '0') then
		regCopCtl			<= x"00";
		i2cbbReg				<= x"00";
		romCtlReg			<= BOOTROM_RSTVAL & "0000000";
		i2cCmdReg			<= x"00";
		i2cWrDatReg			<= x"00";
		mboxC64Adr			<= x"00";
	elsif (i2cClrCmd = '1') then
		i2cCmdReg			<= x"00";
	elsif (rising_edge(davPos) and (F_IO2_N = '0') and 
			(F_RNW = '0')) then
		if		(F_ADR(7 downto 0) = COP_SEL_REG) then
			regCopCtl		<= F_DAT;
		elsif		(F_ADR(7 downto 0) = FPGA_REV_REG) then
			i2cbbReg			<= F_DAT;
		elsif (F_ADR(7 downto 0) = ROM_SEL_REG) then
			romCtlReg		<= F_DAT;
--		elsif	(F_ADR(7 downto 0) = I2C_BBANG_REG) then
--			i2cbbReg			<= F_DAT;
		elsif	(F_ADR(7 downto 0) = I2C_DATWR_REG) then
			i2cWrDatReg		<= F_DAT;
		elsif	(F_ADR(7 downto 0) = I2C_CMD_REG) then
			i2cCmdReg		<= "00000" & F_DAT(2 downto 0);

		elsif	(F_ADR(7 downto 0) = MBRBANK_REG) then
			mboxC64Adr				<= F_DAT;
		end if;
	end if;
	
	copHasSdram		<= regCopCtl(BIT_COP_SDRAMCTL);
	copHasVid		<= regCopCtl(BIT_COP_VIDCTL);
	bitDEnableReu	<= regCopCtl(BIT_COP_ENAREU);
	
	F_GAME_N 	<= not romCtlReg(BIT_SELGAME);
	F_EXROM_N	<= (not romCtlReg(BIT_SELEXROM)) and (not enaBootRom);
	enaBootRom	<=     romCtlReg(BIT_SELBOOTROM);
	
	if ((F_IO2_N = '0') and (F_RNW = '1')) then
		if 	(F_ADR(7 downto 0) = COP_SEL_REG) then
			rdBackRegs	<= '1';
			regsNode		<= regCopCtl(7 DOWNTO 4) & z80CEN & regCopCtl(2 downto 0);
		elsif (F_ADR(7 downto 0) = FPGA_REV_REG) then
			rdBackRegs	<= '1';
			regsNode		<= FPGA_VER;
		elsif	(F_ADR(7 downto 0) = I2C_DATRD_REG) then
			rdBackRegs	<= '1';
			regsNode		<= i2cShiftReg;
		elsif	(F_ADR(7 downto 0) = I2C_DATWR_REG) then
			rdBackRegs	<= '1';
			regsNode		<= i2cWrDatReg;		
		elsif	(F_ADR(7 downto 0) = I2C_CMD_REG) then
			rdBackRegs	<= '1';
			regsNode		<= i2cShifterRdy & i2cAckNode & i2cIsIdle & RTC_SDA & RTC_SCL & i2cCmdReg(2 downto 0);
		elsif (F_ADR(7 downto 0) = ROM_SEL_REG) then
			rdBackRegs	<= '1';
			regsNode		<= romCtlReg;
			
		elsif (F_ADR(7 downto 0) = MBRBANK_REG) then
			rdBackRegs	<= '1';
			regsNode		<= mboxC64Adr;
		elsif ((F_ADR(7 downto 0) >= MBREG0) and (F_ADR(7 downto 0) <= MBREG16)) then
			rdBackRegs	<= '1';
		-- read the Z80 mailbox RAM to me
			regsNode		<= mboxC64Q;
			
		else
			rdBackRegs	<= '0';
			regsNode		<= "--------"; 
		end if;
	else
		rdBackRegs	<= '0';
		regsNode		<= "--------";
	end if;	
end process;

	mboxMemWeNode	<= '1' when ((F_IO2_N = '0') and (F_RNW = '0') and 
										 (davPos = '1') and (F_ADR(7 downto 0) >= MBREG0) and 
										 (F_ADR(7 downto 0) <= MBREG16)) else
							'0';
	mboxC64Wena		<= mboxMemWeNode when rising_edge(clk100);
	z80MbrWena		<= (z80MbrSel and (not z80wr_n)) when  rising_edge(clk100);
mailboxRam:work.MbRam
	PORT map(
-- C64 side
		clock_a		=> clk100,
		wren_a		=> mboxC64Wena,
		address_a	=> mboxC64Adr(4 downto 0) & F_ADR(3 downto 0),
		data_a		=> F_DAT,
		q_a			=> mboxC64Q,
		
-- Z80 side
		clock_b		=> clk100,
		wren_b		=> z80MbrWena,
		address_b	=> z80MbrAdr,
		data_b		=> z80MbrD,
		q_b			=> z80MbrQ
	);


		
vga:work.reuVid
generic map(
		ADR_DAT_REG		=> VID_DAT_REG,
		ADR_STAT_REG	=> VID_STAT_REG
	)
port map(
	clk50				=> clk50,
	rst_n_i			=> syncReset_n,

	c64Adr_i			=> F_ADR(7 downto 0),
	c64Wr_n_i		=> F_RNW,
	c64Dav			=> davPos,
	c64Mosi_i		=> F_DAT,
	c64Miso_o		=> vidDatOutC64,
	c64IoSel_n_i	=> F_IO2_N,

	c64SelMe_o		=> vidItsMeC64,
	c64Intr_n_o		=> open,
	
	z80Adr_i			=> z80ioAdr(7 downto 0),
	z80Wr_n_i		=> z80wr_n,
	z80Rd_n_i		=> z80rd_n,
	z80Iorq_n		=> z80iorq_n,
	z80Mosi_i		=> z80ioDatOut,
	z80Miso_o		=> z80ioDatIn,
	z80SelMe_o		=> open,
	
	useCop			=> copHasVid,	
-- 
	hSync				=> hSyncNode,
	vSync				=> vSyncNode,
	
	videoR0			=> open,
	videoR1			=> open,
	videoG0			=> open,
	videoG1			=> open,
	videoB0			=> open,
	videoB1			=> open,
	
	monoVid			=> vidNode
	
);

	HSYNC			<= not hSyncNode;
	VSYNC			<= not vSyncNode;
	VIDEO			<= not vidNode;

--	HSYNC			<= i2cbbReg(0);
--	VSYNC			<= not vSyncNode;
--	VIDEO			<= (not vidNode) or (not hSyncNode);
	
	
	
	z80Reset_n		<= regCopCtl(BIT_COP_RESETN) and syncReset_n;
	z80CEN			<= (regCopCtl(BIT_COP_Z80CEN) or (not(z80mreq_n and z80iorq_n))) when falling_edge(copClk);
	
z80:work.reuT80s
	port map(
		sdramClk			=> clk100,
		sdramRWCmd		=> z80sdramRWCmd,
		sdramRfshCmd	=> z80sdramRfshCmd,
		sdramWr_n		=> z80sdramWr_n,
		sdramAddr		=> z80sdramAddr,
		sdramQ			=> z80sdramQ,
		sdramD			=> z80sdramD,
		sdramCmdDone	=> z80sdramCmdDone,
		sdramFsmIdle	=> z80sdramFsmIdle,
		
		reset_n			=> z80Reset_n,
		cpuClk			=> copClk,
		CEN				=> z80CEN,
		ioDatIn			=> z80ioDatIn,
		ioDatOut			=> z80ioDatOut,
		ioAdr				=> z80ioAdr,
		
		z80MbrAdr		=> z80MbrAdr,
		z80MbrD			=> z80MbrD,
		z80MbrQ			=> z80MbrQ,
		z80MbrSel		=> z80MbrSel,
		z80ProcReset	=> z80ProcReset,
		
		mreq_n			=> z80mreq_n,
		iorq_n			=> z80iorq_n,
		rd_n				=> z80rd_n,
		wr_n				=> z80wr_n
	);

	
brom:work.bootRom
	PORT map(
	address		=> F_ADR(9 downto 0),
	clock			=> F_DOTCLK,
	q				=> bromDat
	);
	
triggerGen:process(syncReset_n, clk100, F_PHI2, F_BA)

variable baSync			: std_logic_vector(2 downto 0);
variable p2Sync			: std_logic_vector(2 downto 0);
variable stateCtr			: integer range 0 to 3;

begin

	if rising_edge(clk100) then
		baSync		:= baSync(1 downto 0) & F_BA;
		p2Sync		:= p2Sync(1 downto 0) & F_PHI2;
	end if;
	
	if (syncReset_n = '0') then
		stateCtr		:= 0;
		testTrig		<= '0';
	elsif rising_edge(clk100) then
		case stateCtr is
		when 0 =>
			if (p2Sync(2) = '1') and (baSync(2 downto 1) = "10") then
				stateCtr		:= 1;
				testTrig		<= '1';
			end if;
		when 1 =>
			if (p2Sync(2 downto 1) = "01") then
				stateCtr		:= 2;
			end if;
		when 2 =>
			if (p2Sync(2 downto 1) = "01") then
				testTrig		<= '0';
				stateCtr		:= 0;
			end if;
		when others =>
			stateCtr		:= 0;
		end case;
	end if;
end process;

	RTC_SDA		<= '0' when (sdaNode = '0') else 'Z';
	RTC_SCL		<= '0' when (sclNode = '0') else 'Z';
	
i2cFsm:process(syncReset_n, clk100)
variable fsmSda			: std_logic;
variable fsmScl			: std_logic;

variable fsmState			: integer range 0 to 31;
variable clkCtr			: integer range 0 to 511;
variable bitCtr			: integer range 0 to 7;

variable ackBit			: std_logic;
variable isIdle			: std_logic;

variable testBit			: std_logic;

begin
	i2cIsIdle		<= isIdle;

	sdaNode		<= fsmSda;
	sclNode		<= fsmScl;
	
	if (syncReset_n = '0') then
		fsmState				:= 0;
		fsmSda				:= '0';
		fsmScl				:= '0';
		i2cShifterRdy		<= '0';
		clkCtr				:= 0;
		bitCtr				:= 7;
		i2cAckNode			<= '1';
		i2cClrCmd			<= '0';
		isIdle				:= '1';
	elsif rising_edge(clk100) then
		isIdle				:= '0';
		testBit				:= '0';
		case fsmState is
		when 0 =>
		-- mirror the I2C pin state
			fsmSda				:= RTC_SDA;
			fsmScl				:= RTC_SCL;
			i2cShifterRdy		<= '0';
			bitCtr				:= 0;
			i2cClrCmd			<= '0';
			isIdle				:= '1';
		-- wait until the command register value is valid
			if (davNeg = '1') then			
				case i2cCmdReg is
				when I2CCMD_START =>
					fsmState		:= 16;
				when I2CCMD_STOP =>
					fsmState		:= 22;
				when I2CCMD_SEND =>
					fsmState		:= 1;
				when I2CCMD_RXACK =>
					fsmState		:= 8;
				when I2CCMD_RXNAK =>
					fsmState		:= 8;
				when others =>
				end case;
			end if;

	-- Write to I2C devoce
		when 1 =>
			fsmScl				:= '0';
			i2cShifterRdy		<= '1';
			bitCtr				:= 7;
			clkCtr				:= 0;
			i2cShifterRdy		<= '1';
			if		(i2cCmdReg /= I2CCMD_SEND) then
				fsmState			:= 0;
			elsif	(davPos = '1') then
				if	((F_ADR(7 downto 0) = I2C_DATWR_REG) and (F_RNW = '0') and (F_IO2_N = '0')) then
				-- the C64 is writing to the shift register
					fsmState		:= 2;
				end if;
			end if;
		when 2 =>
		-- wait until we are sure the register write is done
			if (davNeg = '1') then
				i2cShifterRdy		<= '0';
				clkCtr				:= 0;
				fsmState				:= 3;
			end if;
		when 3 =>
			fsmSda		:= i2cWrDatReg(bitCtr);
			clkCtr		:= clkCtr + 1;
			if		(clkCtr = 127) then
				fsmScl	:= '1';
			elsif (clkCtr = 255) then
				fsmScl	:= '0';
				fsmState	:= 4;
			end if;
		when 4 =>
			clkCtr		:= 0;
			if (bitCtr = 0) then
				bitCtr	:= 7;
			else
				bitCtr	:= bitCtr - 1;
			end if;
			fsmState		:= 5;
		when 5 =>
			if (bitCtr = 7) then
				fsmState	:= 6;
			else
			-- more bits to receive
				clkCtr	:= clkCtr + 1;
				if (clkCtr = 31) then
					fsmState := 3;
				end if;
			end if;
		when 6 =>
		-- get the ACK
			clkCtr	:= clkCtr + 1;
			fsmSda	:= '1';
			if	(clkCtr = 127) then
				fsmScl		:= '1';
			elsif (clkCtr = 191) then
				i2cAckNode	<= RTC_SDA;
			elsif	(clkCtr = 255) then
				fsmScl		:= '0';
				fsmState		:= 1;
			end if;
			
-- read from the I2C device.
		when 8 =>
			fsmScl				:= '0';
			fsmSda				:= '1';
			i2cShifterRdy		<= '1';
			bitCtr				:= 7;
			clkCtr				:= 0;
			i2cShifterRdy		<= '1';
			if		((i2cCmdReg /= I2CCMD_RXACK) and (i2cCmdReg /= I2CCMD_RXNAK)) then
				fsmState			:= 0;
			elsif	(davPos = '1') then
				if (i2cCmdReg = I2CCMD_RXNAK) then
					ackBit		:= '1';
				else
					ackBit		:= '0';
				end if;
				if	((F_ADR(7 downto 0) = I2C_DATRD_REG) and (F_RNW = '1') and (F_IO2_N = '0')) then
				-- the C64 is reading from to the shift register
					fsmState		:= 9;
				end if;
			end if;
		when 9 =>
			testBit				:= '1';
			i2cShifterRdy		<= '0';
			if (davNeg = '1') then
				bitCtr 		:= 0;
				clkCtr		:= 0;
				fsmState		:= 10;
			end if;
		when 10 =>
			clkCtr	:= clkCtr + 1;
			if 	(clkCtr = 127) then
				fsmScl			:= '1';
			elsif	(clkCtr = 191) then
				i2cShiftReg		<= i2cShiftReg(6 downto 0) & RTC_SDA;
			elsif	(clkCtr = 255) then
				fsmScl			:= '0';
				if (bitCtr = 7) then
					bitCtr	:= 0;
				else
					bitCtr	:= bitCtr + 1;
				end if;
				fsmState		:= 11;
			end if;
		when 11 =>
			clkCtr	:= 0;
			if (bitCtr = 0) then
				fsmState		:= 12;
			else
				fsmState		:= 10;
			end if;
		when 12 =>
			fsmSda		:= ackBit;
			clkCtr		:= clkCtr + 1;
			if		(clkCtr = 127) then
				fsmScl	:= '1';
			elsif	(clkCtr = 255) then
				fsmScl	:= '0';
				fsmState	:= 13;
			end if;
		when 13 =>
			fsmSda		:= '1';
			fsmState		:= 8;
		
	-- I2C START command
		when 16 =>
			clkCtr		:= 0;
		-- drop the clock to ensure we do not muck anything up
			fsmScl		:= '0';
			fsmState		:= 17;
		when 17 =>
			clkCtr := clkCtr + 1;
			if		(clkCtr = 127) then
			-- raise the data line
				fsmSda	:= '1';
			elsif	(clkCtr = 255) then
			-- raise the clock line
				fsmScl	:= '1';
			elsif (clkCtr = 382) then
			-- drop the data line (this is the actual START
			--		condition.
				fsmSda	:= '0';
			elsif	(clkCtr = 500) then
				fsmScl	:= '0';
				fsmState	:= 18;
			end if;
		when 18 =>
			clkCtr		:= 0;
			fsmState		:= 19;
		when 19 =>
			clkCtr	:= clkCtr + 1;
			i2cClrCmd			<= '1';
			if (clkCtr = 255) then
				fsmState	:= 0;
			end if;
				
	-- I2C STOP command
		when 22 =>
			clkCtr		:= 0;
		-- drop the clock to ensure we do not muck anything up
			fsmScl		:= '0';
			fsmState		:= 23;
		when 23 =>
			clkCtr := clkCtr + 1;
			if		(clkCtr = 127) then
			-- drop the data line
				fsmSda	:= '0';
			elsif	(clkCtr = 255) then
			-- raise the clock line
				fsmScl	:= '1';
			elsif (clkCtr = 382) then
			-- drop the data line (this is the actual STOP
			--		condition.
				fsmSda	:= '1';
			elsif	(clkCtr = 500) then
				fsmScl	:= '0';
				fsmState	:= 18;
			end if;
		when others =>
			fsmState		:= 0;
		end case;
	end if;
end process;

	
end behave;

