
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity reuVid is
generic(
		ADR_DAT_REG			: std_logic_vector(7 downto 0) := x"40";
		ADR_STAT_REG		: std_logic_vector(7 downto 0) := x"41"
	);
port (
	clk50				: in std_logic;
	rst_n_i			: in std_logic;								-- active low reset

	c64Adr_i			: in std_logic_vector(7 downto 0);
	c64Wr_n_i		: in std_logic;
	c64Dav			: in std_logic;
	c64Mosi_i		: in std_logic_vector(7 downto 0);
	c64Miso_o		: out std_logic_vector(7 downto 0);		-- c64 IO2_n signal
	c64IoSel_n_i	: in std_logic;								-- high when the C64 is addressing the
																			--		I/O space this resides in
	c64SelMe_o		: out std_logic;								-- high when the C64 should gate this
																			--		peripheral onto the read bus
	c64Intr_n_o		: out std_logic;
	
	z80Adr_i			: in std_logic_vector(7 downto 0);
	z80Wr_n_i		: in std_logic;
	z80Rd_n_i		: in std_logic;
	z80Iorq_n		: in std_logic;
	z80Mosi_i		: in std_logic_vector(7 downto 0);
	z80Miso_o		: out std_logic_vector(7 downto 0);
	z80SelMe_o		: out std_logic;								-- high when the coprocessor should gate this
																			--		peripheral onto the read bus
	
	useCop			: in std_logic;								-- '1' selects the z80 for the controller
	
-- 
	hSync				: out std_logic;
	vSync				: out std_logic;
	
	videoR0			: out std_logic;
	videoR1			: out std_logic;
	videoG0			: out std_logic;
	videoG1			: out std_logic;
	videoB0			: out std_logic;
	videoB1			: out std_logic;
	
	monoVid			: out std_logic
	
);
end reuVid;



architecture rtl of reuVid is

signal cpuAdr		: std_logic_vector(7 downto 0);
signal cpuWr_n		: std_logic;
signal cpuMosi		: std_logic_vector(7 downto 0);
signal cpuCSel_n	: std_logic;
signal copSel		: std_logic;

signal vidWr_n			: std_logic;
signal vidRd_n			: std_logic;
signal vidMiso			: std_logic_vector(7 downto 0);

signal myIoSpace_n	: std_logic;

begin

vid:work.SBCTextDisplayRGB
	generic map(
		EXTENDED_CHARSET				=> 1, 			-- 1 = 256 chars, 0 = 128 chars
		COLOUR_ATTS_ENABLED			=> 1, 			-- 1=Colour for each character, 0=Colour applied to whole display
		DEFAULT_ATT 					=> "11110000",	-- background iBGR | foreground iBGR (i=intensity)
		ANSI_DEFAULT_ATT 				=> "11110000"	-- background iBGR | foreground iBGR (i=intensity)
	)
	port map(
		n_reset	=> rst_n_i,
		clk		=> clk50,
		n_wr		=> vidWr_n,
		n_rd		=> vidRd_n,
		regSel	=> cpuAdr(0),
		dataIn	=> cpuMosi,
		dataOut	=> vidMiso,
		n_int		=> open,
		n_rts		=> open,
		
		-- RGB video signals
		videoR0	=> videoR0,
		videoR1	=> videoR1,
		videoG0	=> videoG0,
		videoG1	=> videoG1,
		videoB0	=> videoB0,
		videoB1	=> videoB1,
				
		hSync  	=> hSync,
		vSync		=> vSync,
		
		hBlank	=> open,
		vBlank	=> open,
		cepix		=> open,
	
		-- Monochrome video signals
		video		=> monoVid,
		sync		=> open
 );

-- convenience signal that is '1' when our I/O space is being addressed
	myIoSpace_n		<= '0' when ((cpuCSel_n = '0') and ((cpuAdr = ADR_DAT_REG) or (cpuAdr = ADR_STAT_REG))) else
							'1';
-- return signals that tell the upper level logic the video data
--		are being addressed
	c64SelMe_o		<= (not useCop) and c64Wr_n_i and (not myIoSpace_n);
	z80SelMe_o		<= (not z80Iorq_n) and (not myIoSpace_n);
	
-- assign data back to the processors
	z80Miso_o		<= vidMiso;
	c64Miso_o		<= vidMiso;
							
process(useCop, z80Iorq_n, z80Adr_i, z80Mosi_i, myIoSpace_n, z80Wr_n_i, 
			z80Rd_n_i, c64IoSel_n_i, c64Adr_i, c64Mosi_i, c64Wr_n_i, c64Dav)
begin

	if (useCop = '1') then
		cpuCSel_n	<= z80Iorq_n;
		cpuAdr		<= z80Adr_i;
		cpuMosi		<= z80Mosi_i;		
		vidWr_n		<= myIoSpace_n or z80Wr_n_i;
		vidRd_n		<= myIoSpace_n or z80Rd_n_i;
	else
		cpuCSel_n	<= c64IoSel_n_i;
		cpuAdr		<= c64Adr_i;
		cpuMosi		<= c64Mosi_i;
		vidWr_n		<= myIoSpace_n or      c64Wr_n_i  or (not c64Dav);
		vidRd_n		<= myIoSpace_n or (not c64Wr_n_i);
	end if;
end process;

	
end rtl;
