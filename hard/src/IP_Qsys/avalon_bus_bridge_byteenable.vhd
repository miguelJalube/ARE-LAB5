------------------------------------------------------------------------------------------
-- HEIG-VD ///////////////////////////////////////////////////////////////////////////////
-- Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
-- School of Business and Engineering in Canton de Vaud
------------------------------------------------------------------------------------------
-- REDS Institute ////////////////////////////////////////////////////////////////////////
-- Reconfigurable Embedded Digital Systems
------------------------------------------------------------------------------------------
--
-- File                 : avalon_bus_bridge_byteenable.vhd
-- Author               : Anthony Convers
-- Date                 : 04.07.2022
--
-- Context              : ARE
--
------------------------------------------------------------------------------------------
-- Description : Avalon bus slave bridge in Qsys with byteenable
--   
------------------------------------------------------------------------------------------
-- Dependencies : 
--   
------------------------------------------------------------------------------------------
-- Modifications :
-- Ver    Date        Engineer    Comments
-- 0.0    04.07.2022  ACS         Initial version
-- 0.1    21.04.2023  ACS         add bytenebale signal

------------------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    
entity avalon_bus_bridge_byteenable is
  port(
    -- HPS part: Avalon bus slave
    hps_clk             : in  std_logic;
    hps_reset           : in  std_logic;
    hps_address         : in  std_logic_vector(13 downto 0);
    hps_byteenable      : in  std_logic_vector(3 downto 0);
    hps_write           : in  std_logic;
    hps_writedata       : in  std_logic_vector(31 downto 0);
    hps_read            : in  std_logic;
    hps_readdatavalid   : out std_logic;
    hps_readdata        : out std_logic_vector(31 downto 0);
    hps_waitrequest     : out std_logic;
    -- Logic part: Avalon bus slave
    logic_clk           : out std_logic;
    logic_reset         : out std_logic;
    logic_address       : out std_logic_vector(13 downto 0);
    logic_byteenable    : out  std_logic_vector(3 downto 0);
    logic_write         : out std_logic;
    logic_writedata     : out std_logic_vector(31 downto 0);
    logic_read          : out std_logic;
    logic_readdatavalid : in  std_logic;
    logic_readdata      : in  std_logic_vector(31 downto 0);
    logic_waitrequest   : in  std_logic
  );
end avalon_bus_bridge_byteenable;

architecture rtl of avalon_bus_bridge_byteenable is

    --| Components declaration |--------------------------------------------------------------
    --| Constants declarations |--------------------------------------------------------------
    --| Signals declarations   |--------------------------------------------------------------   

begin

----- Connect all signals from HPS to the logic part
logic_clk           <= hps_clk;
logic_reset         <= hps_reset;
logic_address       <= hps_address;
logic_byteenable    <= hps_byteenable;
logic_write         <= hps_write;
--logic_writedata     <= hps_writedata;
--Force writedata to 0 when byteenable is not used to avoid cache usage from ARM_DS
logic_writedata(31 downto 24) <= hps_writedata(31 downto 24) when hps_byteenable(3)='1' else "00000000";
logic_writedata(23 downto 16) <= hps_writedata(23 downto 16) when hps_byteenable(2)='1' else "00000000";
logic_writedata(15 downto 8) <= hps_writedata(15 downto 8) when hps_byteenable(1)='1' else "00000000";
logic_writedata(7 downto 0) <= hps_writedata(7 downto 0) when hps_byteenable(0)='1' else "00000000";

logic_read          <= hps_read;
hps_readdatavalid   <= logic_readdatavalid;
hps_readdata        <= logic_readdata;
hps_waitrequest     <= logic_waitrequest;

end rtl; 