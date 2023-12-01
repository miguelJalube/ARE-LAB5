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


    
    constant DBG_RD_CST : std_logic_vector(avl_readdata_o'range) := x"10101010";
    constant DBG_WR_CST : std_logic_vector(avl_readdata_o'range) := x"09090909";
    
    constant INTERFACE_ID1         : std_logic_vector(avl_readdata_o'range) := x"DEADBEEF";
    constant DEFAULT_INTERFACE_ID2 : std_logic_vector(avl_readdata_o'range) := x"CAFE0369";

    -- Behind the Avalon bus, we get a relative offset, like:
    constant OFFSET_INTERF_ID1  : integer :=  0; -- from offset: 0x000 with attributs: R
    constant OFFSET_KEYS        : integer :=  1; -- from offset: 0x004 with attributs: R/W
    constant OFFSET_SWITCHES    : integer :=  2; -- ...........: 0x008 ..............: R
    constant OFFSET_LEDS        : integer :=  3; -- ...........: 0x00C ..............: R/W
    constant OFFSET_STATUS      : integer :=  4; -- ...........: 0x010 ..............: R/W
    constant OFFSET_MODE_DELAY  : integer :=  5; -- ...........: 0x014 ..............: R/W
    --nos adresses--------------------
    constant OFFSET_FUNC1       : integer :=  6; -- ...........: 0x018 ..............: R/W
    constant OFFSET_FUNC2       : integer :=  7; -- ...........: 0x01C ..............: R/W
    --nos adresses--------------------
    constant OFFSET_NA          : integer :=  8; -- ...........: 0x020 ..............: R
    constant OFFSET_NB          : integer :=  9; -- ...........: 0x024 ..............: R
    constant OFFSET_NC          : integer := 10; -- ...........: 0x028 ..............: R
    constant OFFSET_ND          : integer := 11; -- ...........: 0x02C ..............: R

    --| Signals declarations   |--------------------------------------------------------------
    --| Avalon interface       |
    signal avl_interf_id2_s    : std_logic_vector(avl_readdata_o'range);
    signal avl_readdata_s      : std_logic_vector(avl_readdata_o'range);
    signal avl_readdatavalid_s : std_logic;
    signal addr_int_s          : integer := 0;
    --| I/O's                  |
    signal led_s       : std_logic_vector(led_o'range);
  

begin
    -- Avalon address cast as integer for Reading & Writing address decoding simplicities
    addr_int_s <= to_integer(unsigned(avl_address_i));

  

    -- Read access part
    ---------------------------------------------------------------------------
    read_channel: process (avl_clk_i, avl_reset_i)
    ---------------------------------------------------------------------------
    begin
      if avl_reset_i = '1' then
        avl_readdata_s <= (others => '0');

      elsif rising_edge(avl_clk_i) then
        -- By default, fully set read data to 0 & later on, affect only concerned part
        avl_readdata_s <= (others => '0');

        -- Update when read wanted
        if avl_read_i = '1' then
          case addr_int_s is
            when OFFSET_INTERF_ID1 => avl_readdata_s(INTERFACE_ID1'range)    <= INTERFACE_ID1;

            when OFFSET_INTERF_ID2 => avl_readdata_s(avl_interf_id2_s'range) <= avl_interf_id2_s;

            when OFFSET_SWITCHES   => avl_readdata_s(switch_i'range)         <= switch_i;

            when OFFSET_KEYS       => avl_readdata_s(boutton_i'range)        <= boutton_i;

            when OFFSET_LEDS       => avl_readdata_s(led_s'range)            <= led_s;

            when others            => avl_readdata_s    <= DBG_RD_CST;
          end case;
        end if;
      end if;
    end process;

    -- Write access part
    ---------------------------------------------------------------------------
    write_channel: process (avl_clk_i, avl_reset_i)
    ---------------------------------------------------------------------------
    begin
      if avl_reset_i = '1' then
        avl_interf_id2_s    <= DEFAULT_INTERFACE_ID2;
        led_s               <= (others => '0');


      elsif rising_edge(avl_clk_i) then
        cs_wr_max10_datas_s <= '0';
      
        -- Update when write wanted
        if avl_write_i = '1' then
          case addr_int_s is
            when OFFSET_INTERF_ID2 => avl_interf_id2_s <= avl_writedata_i;

            when OFFSET_LEDS       => led_s            <= avl_writedata_i(led_s'range);

            when OFFSET_MAX10_LEDS => lp36_data_s         <= avl_writedata_i;
                                      cs_wr_max10_datas_s <= '1'; -- Create pulse

            when OFFSET_MAX10_CFG  => lp36_sel_s       <= avl_writedata_i(lp36_sel_s'range);

            when others            => NULL;
                                      --avl_readdata_s   <= DBG_WR_CST; -- Used during simulation
          end case;
        end if;
      end if;
    end process;

    -- Interface management
    ---------------------------------------------------------------------------
    fut_state_dec: process(cs_wr_max10_datas_s, curr_state_s, avl_clk_i, avl_reset_i)
    ---------------------------------------------------------------------------
    begin
      -- Counter register
      if avl_reset_i = '1' then
        counter_curr_s <= (others => '0');
      
      elsif rising_edge(avl_clk_i) then
        counter_curr_s <= counter_fut_s;
      end if;
      
      -- Default value(s)
      lp36_we_s <= '0';
      
      -- Default state
      fut_state_s <= WAIT_WR_MAX10_DATAS;

      --!! Rem: Only actives outputs are given by state !!
      case curr_state_s is
          when WAIT_WR_MAX10_DATAS =>
            counter_fut_s <= to_unsigned(0, counter_fut_s'length);
            
            if cs_wr_max10_datas_s = '1' then
              fut_state_s <= BUSY;
            end if;
            
          when BUSY =>
            if counter_curr_s /= COUNTER_ITERATIONS then
              lp36_we_s   <= '1';
              fut_state_s <= INC_COUNTER;
            else
              fut_state_s <= WAIT_WR_MAX10_DATAS;
            end if;
            
          when INC_COUNTER =>
            counter_fut_s <= counter_curr_s + 1;
            lp36_we_s     <= '1';
            fut_state_s   <= BUSY;

          when others =>
                fut_state_s <= WAIT_WR_MAX10_DATAS;
      end case;
    end process fut_state_dec;

    -- Connection internal signals to real signals
 

end rtl;