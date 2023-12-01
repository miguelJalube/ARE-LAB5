------------------------------------------------------------------------------------------
-- HEIG-VD
-- Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
-- School of Business and Engineering in Canton de Vaud
------------------------------------------------------------------------------------------
-- REDS Institute
-- Reconfigurable Embedded Digital Systems
------------------------------------------------------------------------------------------
--
-- File                 : generateur_nombres.vhd
-- Author               : Anthony Convers
-- Date                 : 14.11.2022
--
-- Context              : ARE acquisition nombre lab
--
------------------------------------------------------------------------------------------
-- Description : calculates machine positions
--
------------------------------------------------------------------------------------------
-- Dependencies :
--
------------------------------------------------------------------------------------------
-- Modifications :
-- Ver    Date        Engineer      Comments
-- 0.0    14.11.2022  ACS           Initial version.
-- 0.1    18.07.2023  ACS           Change nomber formula.
--
------------------------------------------------------------------------------------------

library IEEE;
use IEEE.Std_Logic_1164.all;
use ieee.numeric_std.all;

entity generateur_nombres is
    port (clock_i       : in  std_logic;  -- system clock
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
end generateur_nombres;

architecture struct of generateur_nombres is

    --| Components declaration |------------------------------------------------------------

    --| Signals declaration    |------------------------------------------------------------
    constant x_axis_init_val_c : signed(17 downto 0) := to_signed(0, 18);
    constant cpt_val_0_c : unsigned(31 downto 0) := to_unsigned(50000000, 32);  --1Hz
    constant cpt_val_1_c : unsigned(31 downto 0) := to_unsigned(50000, 32);	    --1kHz
    constant cpt_val_2_c : unsigned(31 downto 0) := to_unsigned(500, 32);		--100kHz
    constant cpt_val_3_c : unsigned(31 downto 0) := to_unsigned(50, 32);		--1MHz

    signal x_axis_val_s  : std_logic_vector(21 downto 0);
    signal nbr_a_val_s   : std_logic_vector(21 downto 0);
    signal nbr_b_val_s   : std_logic_vector(21 downto 0);
    signal nbr_c_val_s   : std_logic_vector(21 downto 0);
    signal nbr_d_val_s   : std_logic_vector(21 downto 0);
    signal init_system_s : std_logic;
    signal auto_s        : std_logic;
    signal lfsr_s        : std_logic;
    signal cmd_new_nbr_reg_s  : std_logic_vector(1 downto 0);
    signal cpt_s         : unsigned(31 downto 0);
    signal pulse_s       : std_logic;

begin

    ----------------------------------------------------------------------------------------
    --| Components intanciation |-----------------------------------------------------------


    ----------------------------------------------------------------------------------------
    --| pulse system processing |-----------------------------------------------------------
    process(clock_i, reset_i)
    begin
        if reset_i = '1' then
            x_axis_val_s <= "0000"&std_logic_vector(x_axis_init_val_c);
            nbr_a_val_s  <= "0000"&std_logic_vector(x_axis_init_val_c);
            nbr_b_val_s  <= "0000"&std_logic_vector(x_axis_init_val_c);
            nbr_c_val_s  <= "0000"&std_logic_vector(x_axis_init_val_c);
            nbr_d_val_s  <= "0000"&std_logic_vector(x_axis_init_val_c);
        elsif rising_edge(clock_i) then
            if init_system_s = '1' then
                x_axis_val_s <= "0000"&std_logic_vector(x_axis_init_val_c);
                nbr_a_val_s  <= "0000"&std_logic_vector(x_axis_init_val_c);
                nbr_b_val_s  <= "0000"&std_logic_vector(x_axis_init_val_c);
                nbr_c_val_s  <= "0000"&std_logic_vector(x_axis_init_val_c);
                nbr_d_val_s  <= "0000"&std_logic_vector(x_axis_init_val_c);
            else
                if auto_s = '1' then    -- Auto generate pulse
                    if pulse_s = '1' then
                        x_axis_val_s <= "0000" & x_axis_val_s(16 downto 0) & lfsr_s;
                    end if;
                else                    -- Manual generate pulse
                    if ((cmd_new_nbr_reg_s(1) = '0') and (cmd_new_nbr_reg_s(0) = '1')) then
                        x_axis_val_s <= "0000" & x_axis_val_s(16 downto 0) & lfsr_s;
                    end if;
                end if;
                
                nbr_a_val_s <= std_logic_vector(unsigned(x_axis_val_s));                                            -- X
                nbr_b_val_s <= std_logic_vector(unsigned(x_axis_val_s(20 downto 0)&'0')+unsigned(x_axis_val_s));    -- 2*X + X
                nbr_c_val_s <= std_logic_vector(unsigned(x_axis_val_s(19 downto 0)&"00")+unsigned(x_axis_val_s));   -- 4*X + X
                nbr_d_val_s <= std_logic_vector(unsigned(x_axis_val_s(18 downto 0)&"000")+unsigned(x_axis_val_s));  -- 8*X + X
                
            end if;
        end if;
    end process;
    
    lfsr_s <= x_axis_val_s(17) XNOR x_axis_val_s(10);

    process(clock_i, reset_i)
    begin
      if reset_i = '1' then
        init_system_s <= '0';
        auto_s        <= '0';
        cmd_new_nbr_reg_s  <= "00";
      elsif rising_edge(clock_i) then
        init_system_s <= cmd_init_i;
        auto_s        <= auto_i;
        cmd_new_nbr_reg_s  <= cmd_new_nbr_reg_s(0) & cmd_new_nbr_i;
      end if;
    end process;
    
    process(clock_i, reset_i)
    begin
      if reset_i = '1' then
        cpt_s   <= cpt_val_0_c;
        pulse_s <= '0';
      elsif rising_edge(clock_i) then
        if auto_s = '1' then
          if cpt_s = 0 then
            if delay_i="00" then
				cpt_s   <= cpt_val_0_c;
            elsif delay_i="01" then
				cpt_s   <= cpt_val_1_c;
            elsif delay_i="10" then
				cpt_s   <= cpt_val_2_c;
            else
				cpt_s   <= cpt_val_3_c;
            end if;
            pulse_s <= '1';
          else
            cpt_s   <= cpt_s - 1;
            pulse_s <= '0';
          end if;
        else
          if delay_i="00" then
			cpt_s   <= cpt_val_0_c;
          elsif delay_i="01" then
			cpt_s   <= cpt_val_1_c;
          elsif delay_i="10" then
			cpt_s   <= cpt_val_2_c;
          else
			cpt_s   <= cpt_val_3_c;
          end if;
          pulse_s <= '0';
        end if;
      end if;
    end process;

    nbr_a_o <= nbr_a_val_s;
    nbr_b_o <= nbr_b_val_s;
    nbr_c_o <= nbr_c_val_s;
    nbr_d_o <= nbr_d_val_s;

end struct;
