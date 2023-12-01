------------------------------------------------------------------------------------------
-- HEIG-VD ///////////////////////////////////////////////////////////////////////////////
-- Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
-- School of Business and Engineering in Canton de Vaud
------------------------------------------------------------------------------------------
-- REDS Institute ////////////////////////////////////////////////////////////////////////
-- Reconfigurable Embedded Digital Systems
------------------------------------------------------------------------------------------
--
-- File                 : avl_user_interface.vhd
-- Author               : 
-- Date                 : 04.08.2022
--
-- Context              : Avalon user interface
--
------------------------------------------------------------------------------------------
-- Description : 
--   
------------------------------------------------------------------------------------------
-- Dependencies : 
--   
------------------------------------------------------------------------------------------
-- Modifications :
-- Ver    Date        Engineer    Comments
-- 0.0    See header              Initial version

------------------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    
entity avl_user_interface is
  port(
    -- Avalon bus
    avl_clk_i           : in  std_logic;
    avl_reset_i         : in  std_logic;
    avl_address_i       : in  std_logic_vector(13 downto 0);
    avl_byteenable_i    : in  std_logic_vector(3 downto 0);
    avl_write_i         : in  std_logic;
    avl_writedata_i     : in  std_logic_vector(31 downto 0);
    avl_read_i          : in  std_logic;
    avl_readdatavalid_o : out std_logic;
    avl_readdata_o      : out std_logic_vector(31 downto 0);
    avl_waitrequest_o   : out std_logic;
    -- User interface
    button_i            : in  std_logic_vector(3 downto 0);
    switch_i            : in  std_logic_vector(9 downto 0);
    led_o               : out std_logic_vector(9 downto 0);
    -- Gen nombres
    nbr_a_i             : in  std_logic_vector(21 downto 0);
    nbr_b_i             : in  std_logic_vector(21 downto 0);
    nbr_c_i             : in  std_logic_vector(21 downto 0);
    nbr_d_i             : in  std_logic_vector(21 downto 0);
    cmd_init_o          : out std_logic;
    cmd_new_nbr_o       : out std_logic;
    auto_o              : out std_logic;
    delay_o             : out std_logic_vector(1 downto 0)
  );
end avl_user_interface;

architecture rtl of avl_user_interface is

    --| Components declaration |--------------------------------------------------------------
    
    --| Constants declarations |--------------------------------------------------------------
    
    --| Signals declarations   |--------------------------------------------------------------   

begin
    
    -- Read access part
    
    -- Write access part
    
    -- Interface management

    
end rtl; 