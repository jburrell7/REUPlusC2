
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

package Reu2c5_pkg is

	-- Type Declaration (optional)

	-- Subtype Declaration (optional)

	-- Constant Declaration (optional)

	-- Signal Declaration (optional)

	-- Component Declaration (optional)

	
constant DATA_TO_C64					: std_logic := '1';
constant DATA_FROM_C64				: std_logic := '0';
constant DATA_ENA						: std_logic := '0';
constant DATA_DIS						: std_logic := '1';

constant ADRS_TO_C64					: std_logic := '1';
constant ADRS_FROM_C64				: std_logic := '0';
constant ADRS_ENA						: std_logic := '0';
constant ADRS_DIS						: std_logic := '1';

constant ASSERT_WENA					: std_logic := '0';
constant ASSERT_DMA					: std_logic := '0';
constant ASSERT_WRGATE				: std_logic := '0';

constant ASSERT_NMI					: std_logic := '0';
constant ASSERT_INTR					: std_logic := '0';
constant ASSERT_GAME					: std_logic := '0';
constant ASSERT_XROM					: std_logic := '0';



-- signals that drive the C64 bus
type t_c64BusDrive is
record
-- outputs
	nmi_n			: std_logic;
	game_n		: std_logic;
	irq_n			: std_logic;
	exrom_n		: std_logic;
	dma_n			: std_logic;
	
	nwr1			: std_logic;
	rnw_drv		: std_logic;
	adr_dir		: std_logic;
	adr_oen		: std_logic;
	dat_dir		: std_logic;
	dat_oen		: std_logic;
	
-- inouts
	adr			: std_logic_vector(15 downto 0);
	dat			: std_logic_vector( 7 downto 0);
	
end record;

-- signals driven by the C64 bus
type t_c64BusInputs is
record
	rst_n			: std_logic;
	romh_n		: std_logic;
	phi2			: std_logic;
	rnw			: std_logic;
	dotClk		: std_logic;
	io1_n			: std_logic;
	io2_n			: std_logic;
	roml_n		: std_logic;
	ba				: std_logic;
	
	adrIn			: std_logic_vector(15 downto 0);
	datIn			: std_logic_vector( 7 downto 0);
end record;

-- set up the default values for the C64 bus driven
--		signals
constant C64DRV_DEFAULT	: t_c64BusDrive := (
	not ASSERT_NMI, 			-- nmi_n
	not ASSERT_GAME,			-- game_n
	not ASSERT_INTR, 			-- irq_n
	not ASSERT_XROM,			-- exrom_n
	not ASSERT_DMA,			-- dma_n
	
	not ASSERT_WRGATE,		-- nwr1
	not ASSERT_WENA,			-- rnw_drv
		 ADRS_FROM_C64,		-- adr_dir
		 ADRS_ENA,				-- adr_oen
		 DATA_FROM_C64,		-- dat_dir
		 DATA_ENA,				-- dat_oen
		 "0000000000000000",	-- adr
		 "00000000"				-- dat
	);
	
	
	
	
-- Used by the module that generates the syncronized phi2 signals	
constant CNT_LATCPUDAT				: std_logic_vector(7 downto 0) := x"14";		-- 20
constant CNT_CTRMAX					: std_logic_vector(7 downto 0) := x"23";		-- 35
constant CNT_WAITVAL					: std_logic_vector(7 downto 0) := x"19";		-- 25

constant REU_REG_START				: std_logic_vector(7 downto 0)	:= x"00";
constant REU_REG_END					: std_logic_vector(7 downto 0)	:= x"1F";

------------------------------------------------------------
-- Classic REU registers
--	
constant REU_STAT_REG				: std_logic_vector(7 downto 0)	:= x"00";
constant 	REU_BIT_INTR_PENDING		: integer := 7;
constant 	REU_BIT_EOB					: integer := 6;
constant 	REU_BIT_FAULT				: integer := 5;
constant 	REU_BIT_SIZE				: integer := 4;
constant 	REU_BIT_VER					: integer := 3;

constant REU_CTL_REG			: std_logic_vector(7 downto 0)	:= x"01";
constant		REU_BIT_EXECUTE			: integer := 7;
constant		REU_BIT_RSV6				: integer := 6;
constant		REU_BIT_LOAD				: integer := 5;
constant		REU_BIT_FF00				: integer := 4;
constant		REU_BIT_RSV3				: integer := 3;
constant		REU_BIT_RSV2				: integer := 2;
constant		REU_BIT_XFRTYPE			: integer := 1;
constant 		XFR_C64TORAM				: std_logic_vector(1 downto 0) := "00";
constant 		XFR_RAMTOC64				: std_logic_vector(1 downto 0) := "01";
constant 		XFR_SWAP						: std_logic_vector(1 downto 0) := "10";
constant 		XFR_VFY						: std_logic_vector(1 downto 0) := "11";

constant REU_64ADRL_REG		: std_logic_vector(7 downto 0)	:= x"02";
constant REU_64ADRH_REG		: std_logic_vector(7 downto 0)	:= x"03";
constant REU_XPADRL_REG		: std_logic_vector(7 downto 0)	:= x"04";
constant REU_XPADRM_REG		: std_logic_vector(7 downto 0)	:= x"05";
constant REU_XPADRH_REG		: std_logic_vector(7 downto 0)	:= x"06";
constant REU_XFRL_REG		: std_logic_vector(7 downto 0)	:= x"07";
constant REU_XFRH_REG		: std_logic_vector(7 downto 0)	:= x"08";

constant REU_IMR_REG			: std_logic_vector(7 downto 0)	:= x"09";
constant		REU_BIT_INTRENA_MSK		: integer := 7;
constant		REU_BIT_EOB_MSK			: integer := 6;
constant		REU_BIT_VFY_MSK			: integer := 5;

constant REU_ACR_REG			: std_logic_vector(7 downto 0)	:= x"0A";
constant 	REU_INCR_BOTH				: std_logic_vector(1 downto 0) := "00";
constant 	REU_FIX_XPAN				: std_logic_vector(1 downto 0) := "01";
constant 	REU_FIX_C64					: std_logic_vector(1 downto 0) := "10";
constant 	REU_FIX_BOTH				: std_logic_vector(1 downto 0) := "11";


constant REU_XPADRH_REGX				: std_logic_vector(7 downto 0) := x"1E";
constant REU_SBANK_REG					: std_logic_vector(7 downto 0) := x"1F";

------------------------------------------------------------
-- ROM address registers
--	
constant ROML_BASELOW			: std_logic_vector(7 downto 0)	:= x"10";
constant ROML_BASEHIGH			: std_logic_vector(7 downto 0)	:= x"11";
constant ROMH_BASELOW			: std_logic_vector(7 downto 0)	:= x"12";
constant ROMH_BASEHIGH			: std_logic_vector(7 downto 0)	:= x"13";
constant MEM_BASELOW				: std_logic_vector(7 downto 0)	:= x"14";
constant MEM_BASEMID				: std_logic_vector(7 downto 0)	:= x"15";
constant MEM_BASEHIGH			: std_logic_vector(7 downto 0)	:= x"16";


constant VID_STAT_REG			: std_logic_vector(7 downto 0) := x"20";
constant VID_DAT_REG				: std_logic_vector(7 downto 0) := x"21";


constant ROM_SEL_REG				: std_logic_vector(7 downto 0) := x"28";
constant 	BIT_SELGAME				: integer := 0;
constant 	BIT_SELEXROM			: integer := 1;
constant		BIT_DISABOOTROM		: integer := 7;

--constant 				: std_logic_vector(7 downto 0) := x"39";
constant I2C_CMD_REG				: std_logic_vector(7 downto 0) := x"2A";
constant		I2CCMD_NOP				: std_logic_vector(7 downto 0) := x"00";
constant		I2CCMD_START			: std_logic_vector(7 downto 0) := x"01";
constant		I2CCMD_STOP				: std_logic_vector(7 downto 0) := x"02";
constant		I2CCMD_SEND				: std_logic_vector(7 downto 0) := x"03";
constant		I2CCMD_RXACK			: std_logic_vector(7 downto 0) := x"04";
constant		I2CCMD_RXNAK			: std_logic_vector(7 downto 0) := x"05";
constant I2C_DATRD_REG			: std_logic_vector(7 downto 0) := x"2B";
constant I2C_DATWR_REG			: std_logic_vector(7 downto 0) := x"2C";
--constant I2C_BBANG_REG			: std_logic_vector(7 downto 0) := x"2D";
constant FPGA_REV_REG			: std_logic_vector(7 downto 0) := x"2E";
constant COP_SEL_REG				: std_logic_vector(7 downto 0) := x"2F";
constant 	BIT_COP_SDRAMCTL			: integer := 7;
constant 	BIT_COP_VIDCTL				: integer := 6;
constant 	BIT_COP_RESETN				: integer := 5;
constant 	BIT_COP_Z80CEN				: integer := 4;
constant 	BIT_COP_Z80RESET			: integer := 3;
constant 	BIT_COP_CENSTATE			: integer := 2;

constant 	BIT_COP_ENAREU				: integer := 0;

constant MBRBANK_REG				: std_logic_vector(7 downto 0) := x"26";
constant Z80CTL_REG				: std_logic_vector(7 downto 0) := x"27";
constant		BIT_SELBOOTROM			: integer := 7;
constant MBREG0					: std_logic_vector(7 downto 0) := x"30";
constant MBREG16					: std_logic_vector(7 downto 0) := x"3F";

component sdramSimple4Mx4x2
	port(
	-- Host side
		clk_100m0_i		: in std_logic;				-- Master clock
		reset_i			: in std_logic := '0';		-- Reset, active high
		refresh_i		: in std_logic := '0';		-- Initiate a refresh cycle, active high
		rw_i				: in std_logic := '0';		-- Initiate a read or write operation, active high
		we_i				: in std_logic := '0';		-- Write enable, active low
		addr_i			: in std_logic_vector(23 downto 0) := (others => '0');	-- Address from host to SDRAM
		data_i			: in std_logic_vector(15 downto 0) := (others => '0');	-- Data from host to SDRAM
		ub_i				: in std_logic;				-- Data upper byte enable, active low
		lb_i				: in std_logic;				-- Data lower byte enable, active low
		ready_o			: out std_logic := '0';		-- Set to '1' when the memory is ready
		done_o			: out std_logic := '0';		-- Read, write, or refresh, operation is done
		idle_o			: out std_logic;				-- the SDRAM FSM is idle
		data_o			: out std_logic_vector(15 downto 0);	-- Data from SDRAM to host

	-- SDRAM side
		sdCke_o			: out std_logic;				-- Clock-enable to SDRAM
		sdCe_bo			: out std_logic;				-- Chip-select to SDRAM
		sdRas_bo			: out std_logic;				-- SDRAM row address strobe
		sdCas_bo			: out std_logic;				-- SDRAM column address strobe
		sdWe_bo			: out std_logic;				-- SDRAM write enable
		sdBs_o			: out std_logic_vector(1 downto 0);		-- SDRAM bank address
		sdAddr_o			: out std_logic_vector(12 downto 0);	-- SDRAM row/column address
		sdData_io		: inout std_logic_vector(15 downto 0);	-- Data to/from SDRAM
		sdDqmh_o			: out std_logic;				-- Enable upper-byte of SDRAM databus if true
		sdDqml_o			: out std_logic				-- Enable lower-byte of SDRAM databus if true
     );
end component;


component timingGen
port (
	rst_n				: in std_logic;
	clk50_i			: in std_logic;
	phi2				: in std_logic;
	
	clk50_o			: out std_logic;
	clk100_o			: out std_logic;
	clk100dly		: out std_logic;
	pllLocked		: out std_logic;	
	copClk			: out std_logic;
	
	phi2Sync			: out std_logic;	
	phi2PosEdge		: out std_logic;
	davPos			: out std_logic;
	phi2NegEdge		: out std_logic;
	davNeg			: out std_logic
);
end component;


--component R8800R1
--generic(
--	ADR_REG_START			: std_logic_vector(7 downto 0) := x"00";
--	ADR_REG_END				: std_logic_vector(7 downto 0) := x"3F"
--	);
--port(
--	clk100			: in std_logic;								-- system level clock
--	rst_n				: in std_logic;
--	
---- C64 bus records
----		these records are defined in the QmTechREU_pkg
--	c64BusDrv		: out t_c64BusDrive;			-- signals that drive the C64 bus
--	c64BusInputs	: in t_c64BusInputs;			-- signals from the C64 bus
--
--	reuHasBus		: out std_logic;
--	reuActive		: out std_logic;
--	phiPosEdge		: in std_logic;
--	davPos			: in std_logic;
--	davNeg			: in std_logic;
--	
--	syncPhi2			: in std_logic;
--	
--	debug				: out std_logic_vector(15 downto 0);
--	
---- SDRAM signals
--	sdramAdr			: out std_logic_vector(24 downto 0);
--	sdramDatTo		: out std_logic_vector(15 downto 0);
--	sdramRfshCmd	: out std_logic;
--	sdramRWCmd		: out std_logic;
--	sdramWe_n		: out std_logic;
--	
--	sdramDatFrom	: in std_logic_vector(15 downto 0);
--	sdramOpDone		: in std_logic;
--	sdramFsmIdle	: in std_logic
--    );
--end component;


--component epcsTop
--	generic(
--		EPCS_CTL_REG			: std_logic_vector(7 downto 0) := x"20";
--		EPCS_CMD_REG			: std_logic_vector(7 downto 0) := x"21";
--		EPCS_STAT_REG			: std_logic_vector(7 downto 0) := x"22";
--		EPCS_ADR_LOW_REG		: std_logic_vector(7 downto 0) := x"23";
--		EPCS_ADR_MID_REG		: std_logic_vector(7 downto 0) := x"24";
--		EPCS_ADR_HI_REG		: std_logic_vector(7 downto 0) := x"25";
--		EPCS_DAT_REG			: std_logic_vector(7 downto 0) := x"26"
--	);
--	PORT
--	(
--		CLOCK50_i		: in std_logic;
--		RESET_N_i		: in std_logic;
--		
--		io2Sel_n_i		: in std_logic;
--		
--		cpuAdr_i			: in std_logic_vector(7 downto 0);
--		cpuDat_i			: in std_logic_vector(7 downto 0);
--		cpuDat_o			: out std_logic_vector(7 downto 0);
--		cpuWen_n_i		: in std_logic;
--		
--		useEpcs			: out std_logic;
--		regItsMe			: out std_logic
--	);
--end component;

component T80s
	generic(
		Mode : integer := 0;	-- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
		T2Write : integer := 0;	-- 0 => WR_n active in T3, /=0 => WR_n active in T2
		IOWait : integer := 1	-- 0 => Single cycle I/O, 1 => Std I/O cycle
	);
	port(
		RESET_n	: in std_logic;
		CLK_n		: in std_logic;
		CEN		: in std_logic		:= '1';
		WAIT_n	: in std_logic;
		INT_n		: in std_logic;
		NMI_n		: in std_logic;
		BUSRQ_n	: in std_logic;
		M1_n		: out std_logic;
		MREQ_n	: out std_logic;
		IORQ_n	: out std_logic;
		RD_n		: out std_logic;
		WR_n		: out std_logic;
		RFSH_n	: out std_logic;
		HALT_n	: out std_logic;
		BUSAK_n	: out std_logic;
		A			: out std_logic_vector(15 downto 0);
		DI			: in std_logic_vector(7 downto 0);
		DO			: out std_logic_vector(7 downto 0)
	);
end component;	
	
component z80BootRom
	PORT
	(
		address	: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q			: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
end component;

--component reuVid is
--generic(
--		ADR_DAT_REG			: std_logic_vector(7 downto 0) := x"40";
--		ADR_STAT_REG		: std_logic_vector(7 downto 0) := x"41";
---- register for this module		
--		ADR_BUSSEL_REG		: std_logic_vector(7 downto 0) := x"44"
--	);
--port (	
--	rst_n_i			: in std_logic;								-- active low reset
--
--	c64Adr_i			: in std_logic_vector(7 downto 0);
--	c64Wr_n_i		: in std_logic;
--	c64Mosi_i		: in std_logic_vector(7 downto 0);
--	c64Miso_o		: out std_logic_vector(7 downto 0);
--	c64IoSel_n_i	: in std_logic;								-- high when the C64 is addressing the
--																			--		I/O space this resides in
--	c64SelMe_o		: out std_logic;								-- high when the C64 should gate this
--																			--		peripheral onto the read bus
--	c64Intr_n_o		: out std_logic;
--	
--	copAdr_i			: in std_logic_vector(7 downto 0);
--	copWr_n_i		: in std_logic;
--	copMosi_i		: in std_logic_vector(7 downto 0);
--	copMiso_o		: out std_logic_vector(7 downto 0);
--	copIoSel_n_i	: in std_logic;								-- high when the coprocessor is addressing the
--																			--		I/O space this resides in
--	copSelMe_o		: out std_logic;								-- high when the coprocessor should gate this
--																			--		peripheral onto the read bus
--	copIntr_n_o		: out std_logic;
--
---- 
--	clk50				: in std_logic;
--	hSync				: out std_logic;
--	vSync				: out std_logic;
--	
--	videoR0			: out std_logic;
--	videoR1			: out std_logic;
--	videoG0			: out std_logic;
--	videoG1			: out std_logic;
--	videoB0			: out std_logic;
--	videoB1			: out std_logic;
--	
--	monoVid			: out std_logic;
--	
--	bitsOut			: out std_logic_vector(3 downto 0);
--	
--	debug_o			: Out std_logic_vector(15 downto 0)
--);
--end component;
 
--component reuI2c
--generic(
--		ADR_I2CDATA			: std_logic_vector(7 downto 0) := x"38";
--		ADR_I2CCMD			: std_logic_vector(7 downto 0) := x"39";
--		ADR_I2CSTAT			: std_logic_vector(7 downto 0) := x"3A";
---- register for this module		
--		ADR_BUSSEL_REG		: std_logic_vector(7 downto 0) := x"3B"
--	);
--port (	
--	rst_n_i			: in std_logic;								-- active low reset
--	clk50				: in std_logic;
--
--	c64Adr_i			: in std_logic_vector(7 downto 0);
--	c64Wr_n_i		: in std_logic;
--	c64Mosi_i		: in std_logic_vector(7 downto 0);
--	c64Miso_o		: out std_logic_vector(7 downto 0);
--	c64IoSel_n_i	: in std_logic;								-- high when the C64 is addressing the
--																			--		I/O space this resides in
--	c64SelMe_o		: out std_logic;								-- high when the C64 should gate this
--																			--		peripheral onto the read bus
--	copAdr_i			: in std_logic_vector(7 downto 0);
--	copWr_n_i		: in std_logic;
--	copMosi_i		: in std_logic_vector(7 downto 0);
--	copMiso_o		: out std_logic_vector(7 downto 0);
--	copIoSel_n_i	: in std_logic;								-- high when the coprocessor is addressing the
--																			--		I/O space this resides in
--	copSelMe_o		: out std_logic;								-- high when the coprocessor should gate this
--
--	
--	sda				: inout std_logic;
--	scl				: inout std_logic;
--	
--	
--	bitsOut_o		: out std_logic_vector(3 downto 0);
--	
--	debug_o			: Out std_logic_vector(15 downto 0)
--);
--end component;
	
end Reu2c5_pkg;


package body Reu2c5_pkg is

	-- Type Declaration (optional)

	-- Subtype Declaration (optional)

	-- Constant Declaration (optional)

	-- Function Declaration (optional)

	-- Function Body (optional)

	-- Procedure Declaration (optional)

	-- Procedure Body (optional)
	

end Reu2c5_pkg;
