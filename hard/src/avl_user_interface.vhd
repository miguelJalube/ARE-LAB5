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
    auto_o              : out std_logic;
    cmd_new_nbr_o       : out std_logic;
    delay_o             : out std_logic_vector(1 downto 0)
  );
end avl_user_interface;


architecture rtl of avl_user_interface is
    --| Components declaration |--------------------------------------------------------------


    
    constant DBG_RD_CST : std_logic_vector(avl_readdata_o'range) := x"10101010";
    constant DBG_WR_CST : std_logic_vector(avl_readdata_o'range) := x"09090909";
    
    constant INTERFACE_ID1         : std_logic_vector(avl_readdata_o'range) := x"DEADBEEF";
    constant CODE_NA    : std_logic_vector(1 downto 0)   := "00";
    constant CODE_NB    : std_logic_vector(1 downto 0)   := "01";
    constant CODE_NC    : std_logic_vector(1 downto 0)   := "10";
    constant CODE_ND    : std_logic_vector(1 downto 0)   := "11";

    -- Behind the Avalon bus, we get a relative offset, like:
    --constant OFFSET_INTERF_ID1  : integer :=  0; -- from offset: 0x000 with attributs: R
    --constant OFFSET_KEYS        : integer :=  1; -- from offset: 0x004 with attributs: R/W
    --constant OFFSET_SWITCHES    : integer :=  2; -- ...........: 0x008 ..............: R
    --constant OFFSET_LEDS        : integer :=  3; -- ...........: 0x00C ..............: R/W
    --constant OFFSET_STATUS      : integer :=  4; -- ...........: 0x010 ..............: R/W
    --constant OFFSET_MODE_DELAY  : integer :=  5; -- ...........: 0x014 ..............: R/W
    --nos adresses--------------------
    constant OFFSET_FUNC1       : integer :=  6; -- ...........: 0x018 ..............: R/W
    constant OFFSET_FUNC2       : integer :=  7; -- ...........: 0x01C ..............: R/W
    --nos adresses--------------------
    --constant OFFSET_NA          : integer :=  8; -- ...........: 0x020 ..............: R
    --constant OFFSET_NB          : integer :=  9; -- ...........: 0x024 ..............: R
    --constant OFFSET_NC          : integer := 10; -- ...........: 0x028 ..............: R
    --constant OFFSET_ND          : integer := 11; -- ...........: 0x02C ..............: R

    --| Signals declarations   |--------------------------------------------------------------
    signal nbrs_save_s : std_logic;
    signal status_s    : std_logic_vector(1 downto 0);
    signal led_s       : std_logic_vector(led_o'range);
    signal delay_s          : std_logic_vector(1 downto 0);
    signal mode_gen_s       : std_logic;
    signal init_nbr_s       : std_logic;
    signal new_nbr_s        : std_logic;
    signal nbr_a_s          : std_logic_vector(21 downto 0);
    signal nbr_b_s          : std_logic_vector(21 downto 0);
    signal nbr_c_s          : std_logic_vector(21 downto 0);
    signal nbr_d_s          : std_logic_vector(21 downto 0);
    signal avl_interf_id2_s : std_logic_vector(avl_readdata_o'range);
    signal addr_int_s       : integer;
    signal avl_readdata_s      : std_logic_vector(avl_readdata_o'range);
    signal avl_readdatavalid_s : std_logic;

begin
    -- Avalon address cast as integer for Reading & Writing address decoding simplicities
  addr_int_s <= to_integer(unsigned(avl_address_i));

  number_gen: process (avl_clk_i, avl_reset_i)
  begin 
    if avl_reset_i = '1' then
      nbr_a_s <= (others => '0');
      nbr_b_s <= (others => '0');
      nbr_c_s <= (others => '0');
      nbr_d_s <= (others => '0');
    elsif rising_edge(avl_clk_i) then
      --ajouter un if pour le mode auto fiable    
          nbr_a_s <= nbr_a_s;
          nbr_b_s <= nbr_b_s;
          nbr_c_s <= nbr_c_s;
          nbr_d_s <= nbr_d_s;
      end if;
  end process;

    -- Read access part
    ---------------------------------------------------------------------------
    read_channel: process (avl_clk_i, avl_reset_i)
    ---------------------------------------------------------------------------
    begin
      if avl_reset_i = '1' then
        avl_readdatavalid_s <= '0';
        avl_readdata_s <= (others => '0');
        status_s(1) <= '0';

      elsif rising_edge(avl_clk_i) then
        -- By default, fully set read data to 0 & later on, affect only concerned part
        avl_readdatavalid_s <= avl_read_i;
        avl_readdata_s <= (others => '0');
        

        -- Update when read wanted
        if avl_read_i = '1' then
          case addr_int_s is
            when 0       => avl_readdata_s(INTERFACE_ID1'range)    <= INTERFACE_ID1;

            when 1       => avl_readdata_s(button_i'range)         <= button_i;
            
            when 2       => avl_readdata_s(switch_i'range)         <= switch_i;

            when 3       => avl_readdata_s(led_s'range)            <= led_s;

            when 4       => avl_readdata_s(status_s'range)         <= status_s;

            when 5       => avl_readdata_s(4 downto 0)     <= mode_gen_s & "00" & delay_s;
            
            when 8       => avl_readdata_s(nbr_a_s'high+CODE_NA'length downto nbr_a_s'low)          <= CODE_NA & nbr_a_s;
            when 9       => avl_readdata_s(nbr_b_s'high+CODE_NB'length downto nbr_b_s'low)          <= CODE_NB & nbr_b_s;
            when 10      => avl_readdata_s(nbr_c_s'high+CODE_NC'length downto nbr_c_s'low)          <= CODE_NC & nbr_c_s;
            when 11      => avl_readdata_s(nbr_d_s'high+CODE_ND'length downto nbr_d_s'low)          <= CODE_ND & nbr_d_s;

            when others  => avl_readdata_s    <= DBG_RD_CST;
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
        led_s               <= (others => '0');

        mode_gen_s          <= '0';
        delay_s             <= (others => '0');

        new_nbr_s           <= '0';
        init_nbr_s          <= '0';

      elsif rising_edge(avl_clk_i) then
        -- Update when write wanted
        if avl_write_i = '1' then
          case addr_int_s is
            when 3     => led_s            <= avl_writedata_i(led_s'range);

            when 4     => new_nbr_s        <= avl_writedata_i(4);
                          init_nbr_s       <= avl_writedata_i(0);

            when 5 => mode_gen_s       <= avl_writedata_i(4);
                      delay_s          <= avl_writedata_i(1 downto 0);
            
            --add func 2 0x1C for reliable

            when others            => NULL;
            --avl_readdata_s   <= DBG_WR_CST; -- Used during simulation
          end case;
        end if;
      end if;
    end process;

    -- MSS for relaiable


    -- Connection internal signals to real signals
  
    led_o               <= led_s;

    auto_o              <= mode_gen_s;
    delay_o             <= delay_s;

    cmd_init_o          <= init_nbr_s;
    cmd_new_nbr_o       <= new_nbr_s;

    avl_readdata_o      <= avl_readdata_s;
    avl_readdatavalid_o <= avl_readdatavalid_s;

    avl_waitrequest_o   <= '0';

end rtl;