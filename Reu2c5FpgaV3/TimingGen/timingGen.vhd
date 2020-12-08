----------------------------------------------------------------------------------
-- Creation Date: 21:12:48 05/06/2010 
-- Module Name: RS232/UART Interface - Behavioral
-- Used TAB of 4 Spaces
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity timingGen is
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
	davNeg			: out std_logic;
	
	RESET_SW			: in std_logic;
	F_RST_N			: in std_logic;
	sdcRdy			: in std_logic;
	sdramRst			: out std_logic;
	syncReset_n		: out std_logic;
	syncReset		: out std_logic
	
);
end timingGen;

architecture Behavioral of timingGen is

constant EDGE_WIDTH			: integer := 7;
constant DAV_START			: integer := 30;
constant DAV_END				: integer := 38;
constant COPCLKCTR_MAX		: integer := 4;

component clk16MDrv
	PORT
	(
		inclk		: IN STD_LOGIC ;
		outclk		: OUT STD_LOGIC 
	);
end component;

signal clk100					: std_logic;
signal copClkCtrNode			: std_logic;
signal pllLockedNode			: std_logic;

begin





--=======================================================
-- Generate signals syncronized to the C64 and the 100MHz
--	clock
--
process(pllLockedNode, clk100, phi2)
variable ph2SyncSr		: std_logic_vector(2 downto 0);
variable ph2PosCtr		: integer range 0 to 63;
variable ph2NegCtr		: integer range 0 to 63;
variable copClkCtr		: integer range 0 to 15;
begin

	phi2Sync			<= ph2SyncSr(2);
	if (pllLockedNode = '0') then
		ph2SyncSr	:= "000";
	elsif rising_edge(clk100) then
		ph2SyncSr	:= ph2SyncSr(1 downto 0) & phi2; 
	end if;

	if (pllLockedNode = '0') then
		ph2PosCtr		:= 0;
		ph2NegCtr		:= 0;
	elsif rising_edge(clk100) then
		if (ph2SyncSr(2 downto 1) = "01") then
			ph2PosCtr 	:= 0;
		elsif (ph2PosCtr /= 63) then
			ph2PosCtr	:= ph2PosCtr + 1;
		end if;
		
		if (ph2SyncSr(2 downto 1) = "10") then
			ph2NegCtr 	:= 0;
		elsif (ph2NegCtr /= 63) then
			ph2NegCtr	:= ph2NegCtr + 1;
		end if;
		
		if (ph2PosCtr < EDGE_WIDTH) then
			phi2PosEdge		<= '1';
		else
			phi2PosEdge		<= '0';
		end if;
		if ((ph2PosCtr >= DAV_START) and (ph2PosCtr <= DAV_END)) then
			davPos	<= '1';
		else
			davPos	<= '0';
		end if;

		if (ph2NegCtr < EDGE_WIDTH) then
			phi2NegEdge		<= '1';
		else
			phi2NegEdge		<= '0';
		end if;
		if ((ph2NegCtr >= DAV_START) and (ph2NegCtr <= DAV_END)) then
			davNeg	<= '1';
		else
			davNeg	<= '0';
		end if;
	end if;	
end process;

--=======================================================
-- PLL used to generate the video and SDRAM clock
--
	pllLocked			<= pllLockedNode;
	clk100_o				<= clk100;
clkgen:work.clkPll
	PORT MAP(
		inclk0	=> clk50_i,
		c0			=> clk100,
		c1			=> clk100dly,
		c2			=> clk50_o,
		locked	=> pllLockedNode
	);

--=======================================================
-- Generate the coprocessor clock
--	
copClkGen:process(pllLockedNode, clk100, phi2)
variable copClkCtr		: integer range 0 to 15;
begin

	if (pllLockedNode = '0') then
		copClkCtr			:= 0;
		copClkCtrNode		<= '0';
	elsif rising_edge(clk100) then
		if (copClkCtr = COPCLKCTR_MAX) then
			copClkCtr		:= 0;
			copClkCtrNode	<= not copClkCtrNode;
		else
			copClkCtr		:= copClkCtr + 1;
		end if;
	end if;
end process;
	
copBuf:work.clk16MDrv
	port map(
		inclk		=> copClkCtrNode,
		outclk	=> copClk
	);


--=======================================================
-- Reset 
--	


rstKey:process(RESET_SW, clk100, pllLockedNode, sdcRdy)
variable key0Sync				: std_logic_vector(3 downto 0) := "0000";
variable c64RstSync			: std_logic_vector(3 downto 0) := "0000";

variable syncResetSreg		: std_logic_vector(3 downto 0);
variable syncResetCtr		: integer range 0 to 524287;
variable syncResetState		: integer range 0 to 3;
variable rstNode				: std_logic;
variable syncResetNode_n	: std_logic;
begin

	sdramRst			<= (not pllLockedNode) or (not key0Sync(3)) or (not c64RstSync(3));

--
-- async reset
--
	rstNode			:= RESET_SW and pllLockedNode and sdcRdy;
	syncReset_n		<= syncResetNode_n;
	syncReset		<= not syncResetNode_n;

	if (rstNode = '0') then
		syncResetSreg		:= "1111";
	elsif rising_edge(clk100) then
		syncResetSreg		:= syncResetSreg(3 downto 1) & rstNode;
	end if;

	if (rstNode = '0') then
		syncResetNode_n	:= '0';
		syncResetCtr		:= 0;
		syncResetState		:= 0;
	elsif rising_edge(clk100) then
		syncResetNode_n			:= '1';
		case syncResetState is
		when 0 =>
			if	(syncResetSreg(3 downto 2) = "10") then
				syncResetState		:= 1;
			else
				syncResetState		:= 0;
			end if;
		when 1 =>
			syncResetNode_n		:= '0';
			syncResetCtr			:= syncResetCtr + 1;
			if (syncResetCtr = 500000) then
				syncResetState		:= 2;
			else
				syncResetState		:= 1;
			end if;
		when 2 =>
			syncResetNode_n		:= '0';
			if (syncResetSreg(3) = '1') then
				syncResetState		:= 0;
			else
				syncResetState		:= 2;
			end if;
		when others =>
			syncResetState		:= 0;
		end case;
	end if;

-- syncronize the button input
	if rising_edge(clk100) then
		key0Sync		:= key0Sync(2 downto 0) & RESET_SW;
	end if;

	if rising_edge(clk100) then
		c64RstSync	:= c64RstSync(2 downto 0) & F_RST_N;
	end if;

end process;


	
end Behavioral;
