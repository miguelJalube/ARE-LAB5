-----------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenierie et de Gestion du canton de Vaud
-- Institut REDS, Reconfigurable & Embedded Digital Systems
--
-- Fichier      : avalon_slv_tb.vhd
-- Description  : testbench pour interface avalon slave
--
-- Auteur       : S. Masle
-- Date         : 11.07.2022
--
-- Utilise      : 
--
--| Modifications |-----------------------------------------------------------
-- Ver   Auteur Date         Description
-- 1.0   SMS    11.07.2022   Version initiale
------------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.uniform;

entity avalon_console_sim is
end avalon_console_sim;

architecture Behavioral of avalon_console_sim is

    component avl_user_interface
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
            nbr_a_i             : in  std_logic_vector(21 downto 0);
            nbr_b_i             : in  std_logic_vector(21 downto 0);
            nbr_c_i             : in  std_logic_vector(21 downto 0);
            nbr_d_i             : in  std_logic_vector(21 downto 0);
            cmd_init_o          : out std_logic;
            cmd_new_nbr_o       : out std_logic;
            auto_o              : out std_logic;
            delay_o             : out std_logic_vector(1 downto 0)
        );
    end component;
    
    component generateur_nombres is
        port (
            clock_i       : in  std_logic;  -- system clock
            reset_i       : in  std_logic;  -- reset
            cmd_init_i    : in  std_logic;
            cmd_new_nbr_i : in  std_logic;
            auto_i        : in  std_logic;
            delay_i       : in  std_logic_vector(1 downto 0); -- delay value for input pulses
            nbr_a_o       : out std_logic_vector(21 downto 0);
            nbr_b_o       : out std_logic_vector(21 downto 0);
            nbr_c_o       : out std_logic_vector(21 downto 0);
            nbr_d_o       : out std_logic_vector(21 downto 0)
        );
    end component generateur_nombres;

    constant ClockPeriod : TIME := 20 ns;
    constant pulse_c     : time := 4 ns;

    signal clock_sti : std_logic;
    signal reset_sti : std_logic;

    signal address_sti         : std_logic_vector(13 downto 0);
    signal byteenable_sti      : std_logic_vector(3 downto 0);
    signal read_sti            : std_logic;
    signal read_data_valid_obs : std_logic;
    signal read_data_obs       : std_logic_vector(31 downto 0);
    signal write_sti           : std_logic;
    signal write_data_sti      : std_logic_vector(31 downto 0);
    signal waitrequest_obs     : std_logic;
    signal button_n_s          : std_logic_vector(3 downto 0);
    signal button_sti          : std_logic_vector(31 downto 0);
    signal switch_sti          : std_logic_vector(31 downto 0);
    signal lp36_status_sti     : std_logic_vector(31 downto 0);
    signal led_obs             : std_logic_vector(31 downto 0) := (others => '0');
    signal nbr_a_sti           : std_logic_vector(21 downto 0);
    signal nbr_b_sti           : std_logic_vector(21 downto 0);
    signal nbr_c_sti           : std_logic_vector(21 downto 0);
    signal nbr_d_sti           : std_logic_vector(21 downto 0);
    signal cmd_init_obs        : std_logic;
    signal cmd_new_nbr_obs     : std_logic;
    signal auto_obs            : std_logic;
    signal delay_obs           : std_logic_vector(1 downto 0);

    
begin

    DUT: entity work.avl_user_interface
        port map (
            -- Avalon bus
            avl_clk_i           => clock_sti,
            avl_reset_i         => reset_sti,
            avl_address_i       => address_sti,
            avl_byteenable_i    => byteenable_sti,
            avl_write_i         => write_sti,
            avl_writedata_i     => write_data_sti,
            avl_read_i          => read_sti,
            avl_readdatavalid_o => read_data_valid_obs,
            avl_readdata_o      => read_data_obs,
            avl_waitrequest_o   => waitrequest_obs,
    
            -- User input-output
            button_i            => button_n_s,
            switch_i            => switch_sti(9 downto 0),
            led_o               => led_obs(9 downto 0),
            nbr_a_i             => nbr_a_sti,
            nbr_b_i             => nbr_b_sti,
            nbr_c_i             => nbr_c_sti,
            nbr_d_i             => nbr_d_sti,
            cmd_init_o          => cmd_init_obs,
            cmd_new_nbr_o       => cmd_new_nbr_obs,
            auto_o              => auto_obs,
            delay_o             => delay_obs
        );
        
    button_n_s <= not button_sti(3 downto 0);   -- button_i (key) is active low
    
    gen_nbr_inst: entity work.generateur_nombres
        port map (
            clock_i       => clock_sti,
            reset_i       => reset_sti,
            cmd_init_i    => cmd_init_obs,
            cmd_new_nbr_i => cmd_new_nbr_obs,
            auto_i        => auto_obs,
            delay_i       => delay_obs,
            nbr_a_o       => nbr_a_sti,
            nbr_b_o       => nbr_b_sti,
            nbr_c_o       => nbr_c_sti,
            nbr_d_o       => nbr_d_sti
        );

    -- Generate clock signal
    GENERATE_REFCLOCK : process
    begin
 
        while true loop
            clock_sti <= '1',
                         '0' after ClockPeriod/2;
            wait for ClockPeriod;
        end loop;
        wait;
    end process;

end Behavioral;
