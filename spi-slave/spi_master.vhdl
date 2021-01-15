library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- SPI Master
-- hardcoded CPOL=0, CPHA=0 (mode 0)
---------------------------------------------------------
-- usage: 0.) pull 'reset' low 
--             1.) wire data to be transmitted to 'tx_data' port
--             2.) set 'enable' high
--             3.) transmission starts, 'busy' flag goes high
--             4.) wait until 'finished' flag goes high
--             5.) read slave's response from 'rx_data' port
--             6.) pull 'enable' low
--             7.) go to 1.) for next transmission
-- NOTE: if the 'enable' is not kept high until the 'finished' flag is high, the 'busy' flag goes low before the 'finished' flag goes high,
--            it means that the 'enable' was pulled low prematurely. The transmission is not completed and thus erroneous.

entity spi_master is 
        generic(
                main_clock_freq : integer := 1000000; -- frequency of 'clk_in'  [Hertz]
                spi_target_freq : integer := 100000 -- frequency of 'spi_sclk' [Hertz]
                );
        port(
                clk_in   : in std_logic; -- main clock input
                tx_data : in std_logic_vector(7 downto 0); -- data to be sent via SPI
                rx_data : out std_logic_vector(7 downto 0); -- response received from SPI slave
                reset          : in std_logic; --active high
                enable        : in std_logic; --active high
                busy           : out std_logic; -- busy flag active high
                finished      : out std_logic; -- transmission finished flag (active high)
                spi_sclk      : out std_logic; -- SPI clock line (SCLK)
                spi_mosi     : out std_logic; -- Master Out Slave In
                spi_miso     : in std_logic; -- Master In Slave Out
                spi_ce         : out std_logic -- SPI Chip Enable (CE) a.k.a. Slave Select (SS)
                );
end entity;

architecture arch of spi_master is
        -- declarations--------------------------------------------------------------------------------------------------
        constant spi_clk_divider : integer := ( main_clock_freq / ( 2*spi_target_freq ) ) - 1;
        signal spi_clk_counter : integer range 0 to ( main_clock_freq / ( 2*spi_target_freq ) );
        signal spi_clk_sig : std_logic := '0';
        signal tx_register : std_logic_vector(7 downto 0) := (others => '0');
        signal rx_register : std_logic_vector(7 downto 0) := (others => '0');
        
        -- use one hot encoding for the FSM's states
        constant reset_state : std_logic_vector(18 downto 0) := "0000000000000000001";
        constant idle_state : std_logic_vector(18 downto 0) :=   "0000000000000000010";
        constant tx0_state : std_logic_vector(18 downto 0) :=    "0000000000000000100";
        constant rx0_state : std_logic_vector(18 downto 0) :=    "0000000000000001000";
        constant tx1_state : std_logic_vector(18 downto 0) :=    "0000000000000010000";
        constant rx1_state : std_logic_vector(18 downto 0) :=    "0000000000000100000";
        constant tx2_state : std_logic_vector(18 downto 0) :=    "0000000000001000000";
        constant rx2_state : std_logic_vector(18 downto 0) :=    "0000000000010000000";
        constant tx3_state : std_logic_vector(18 downto 0) :=    "0000000000100000000";
        constant rx3_state : std_logic_vector(18 downto 0) :=    "0000000001000000000";
        constant tx4_state : std_logic_vector(18 downto 0) :=    "0000000010000000000";
        constant rx4_state : std_logic_vector(18 downto 0) :=    "0000000100000000000";   
        constant tx5_state : std_logic_vector(18 downto 0) :=    "0000001000000000000";
        constant rx5_state : std_logic_vector(18 downto 0) :=    "0000010000000000000"; 
        constant tx6_state : std_logic_vector(18 downto 0) :=    "0000100000000000000";
        constant rx6_state : std_logic_vector(18 downto 0) :=    "0001000000000000000";
        constant tx7_state : std_logic_vector(18 downto 0) :=    "0010000000000000000";
        constant rx7_state : std_logic_vector(18 downto 0) :=    "0100000000000000000";     
        constant finish_state : std_logic_vector(18 downto 0) := "1000000000000000000"; 
        
        signal state : std_logic_vector(18 downto 0) := (others => '0'); -- FSM state (one hot encoding)
begin
        ---------------------------------------------------------------------------------------------------------------------- 
        
        -- "hardwired" connections
        spi_sclk <= spi_clk_sig;
        spi_mosi <= tx_register(tx_register'left); -- wire MOSI to MSB of tx_register
        
        spi_clock_generator : process(clk_in)
        begin
                if ( state /= reset_state ) and ( state /= idle_state ) and ( state /= finish_state ) then
                        -- divide main clock to generate SPI clock
                        if rising_edge(clk_in) then
                                if spi_clk_counter < spi_clk_divider then
                                        spi_clk_counter <= spi_clk_counter + 1;
                                else
                                        spi_clk_counter <= 0;
                                        spi_clk_sig <= not(spi_clk_sig); -- toggle SPI clock line
                                end if;
                        end if;
                end if;
        end process;
        
        FSM_transitions : process(spi_clk_sig, enable, reset)
        begin
                if spi_clk_sig'event or enable'event or reset'event then
                        case state is
                                when reset_state =>
                                        if reset = '1' then
                                                state <= reset_state;
                                        elsif (reset = '0') and (enable = '0') then
                                                state <= idle_state;
                                        else --(reset = '0') and (enable = '1')
                                                state <= tx0_state;
                                        end if;
                                when idle_state =>
                                        if reset = '1' then
                                                state <= reset_state;
                                        elsif (reset = '0') and (enable = '0') then
                                                state <= idle_state;
                                        else
                                                state <= tx0_state;
                                        end if;
                                when tx0_state =>
                                        if reset = '1' then
                                                state <= reset_state;
                                        elsif (reset = '0') and (enable = '0') then
                                                -- ERROR: the 'enable' line was pulled low prematurely, the transmission is aborted
                                                state <= idle_state;
                                        else --(reset = '0') and (enable = '1')
                                                state <= rx0_state;
                                        end if;                       
                                
                                when rx7_state =>
                                        if reset = '1' then
                                                state <= reset_state;
                                        elsif (reset = '0') and (enable = '0') then
                                                -- ERROR: the 'enable' line was pulled low prematurely, the transmission is aborted
                                                state <= idle_state;
                                        else --(reset = '0') and (enable = '1')
                                                state <= finish_state;
                                        end if;                                
                                when finish_state =>
                                        if reset = '1' then
                                                state <= reset_state;
                                        elsif (reset = '0') and (enable = '0') then
                                                state <= idle_state;
                                        else --(reset = '0') and (enable = '1')
                                                state <= finish_state;
                                        end if;                          
                                when others => -- states tx0, rx0, tx1, rx1 etc. without rx7
                                        if reset = '1' then
                                                state <= reset_state;
                                        elsif (reset = '0') and (enable = '0') then
                                                -- ERROR: the 'enable' line was pulled low prematurely, the transmission is aborted
                                                state <= idle_state;
                                        else --(reset = '0') and (enable = '1')
                                                if spi_clk_sig'event then -- rising or falling edge of SPI clock
                                                        state <= state( (state'left - 1) downto 0 ) & '0'; -- transition state by left shift
                                                else
                                                        state <= state; -- remain in state
                                                end if;
                                        end if;  
                        end case;
                end if;
        end process;

        FSM_state_outputs : process(state, spi_clk_sig)
        begin
                if state'event or spi_clk_sig'event then
                        case state is
                                when reset_state =>
                                        spi_ce <= '1';
                                        busy <= '0';
                                        finished <= '0';
                                        tx_register <= (others => '0');
                                        rx_register <= (others => '0');
                                when idle_state =>
                                        tx_register <= tx_data; -- load data to be sent
                                        spi_ce <= '1';
                                        busy <= '0';
                                        finished <= '0';
                                when finish_state =>
                                        spi_ce <= '1';
                                        busy <= '0';
                                        finished <= '1';
                                        rx_data <= rx_register; -- output received data
                                when others =>
                                        spi_ce <= '0';
                                        busy <= '1';
                                        finished <= '0';
                                        if rising_edge(spi_clk_sig) then -- SPI mode 0 : sample MISO on rising edge of spi_clk_counter
                                                rx_register <= rx_register( (rx_register'left - 1) downto 0) & spi_miso; -- sample MISO and shift register left
                                        elsif falling_edge(spi_clk_sig) then -- SPI mode 0 : output next bit on MOSI at falling_edge of spi_clk_counter
                                                tx_register <= tx_register( (tx_register'left - 1) downto 0) & '0'; -- shift register left
                                        else
                                                null; -- do nothing
                                        end if;    
                        end case;
                end if;
        end process;
end architecture;
