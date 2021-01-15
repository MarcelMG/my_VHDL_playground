library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- hardcoded CPOL=0, CPHA=0 (mode 0)
entity spi_slave is 
        port(
                tx_data : in std_logic_vector(7 downto 0);
                rx_data : out std_logic_vector(7 downto 0);
                reset          : in std_logic; --active high
                enable        : in std_logic; --active high
                busy           : out std_logic;
                error_flag   : out std_logic;
                spi_sclk      : in std_logic;
                spi_mosi     : in std_logic;
                spi_miso     : out std_logic;
                spi_ce         : in std_logic
                );
end entity;

architecture arch of spi_slave is
        type spi_state is (idle_state, reset_state, active_state, error_state);
        signal state : spi_state := reset_state;
        signal bit_counter : integer range 0 to 9 := 0;
        signal tx_register : std_logic_vector(7 downto 0) := (others => '0');
        signal rx_register : std_logic_vector(7 downto 0) := (others => '0');
begin
        -- "hardwired" connections
        rx_data <= rx_register;
        spi_miso <= tx_register(tx_register'left); -- MISO output is tied to the MSB of the TX shift register
        
        process(spi_ce, reset, enable, spi_sclk)
        begin
                if reset = '1' then
                        bit_counter <= 0;
                        rx_data <= (others => '0');
                        busy <= '0';
                        error_flag <= '0';
                        state <= reset_state;
                elsif (reset = '0') and (enable = '0') then
                        if (state = reset_state) then
                                state <= idle_state;
                        elsif (state = active_state) then -- SPI slave was disabled during an ongoing transmission -> ERROR
                                error_flag <= '1';
                                state <= error_state;
                        else -- idle_state or error_state
                                null; -- remain in state
                        end if;
                else -- ( (reset = '0') and (enable = '1') ) or (state /= reset_state)
                        if spi_ce = '0' then
                                state <= active_state;
                                busy <= '1';
                                tx_register <= tx_data; -- load TX register with data to be transmitted
                                if rising_edge(spi_sclk) then -- CPOL=0, CPHA=0 (mode 0) -> sample MOSI at rising edge of SCLK
                                        rx_register <= rx_register( (rx_register'left - 1) downto 0 ) & spi_mosi; -- sample bit and shift register left
                                        bit_counter <= bit_counter + 1;
                                elsif falling_edge(spi_sclk) then -- CPOL=0, CPHA=0 (mode 0) -> output MISO at falling edge of SCLK
                                        tx_register <= rx_register( (rx_register'left - 1) downto 0 ) & '0'; -- shift RX register left
                                end if;
                        elsif spi_ce = '1' then
                                busy <= '0';
                                if bit_counter < 8 then -- the SPI CE line was pulled high by the master before all 8 bits were transmitted -> ERROR
                                        error_flag <= '1';
                                        state <= error_state;
                                else ---- the SPI CE line was pulled high by the master after all 8 bits were transmitted -> OK, transmission finished
                                        state <= idle_state;
                                end if;
                        end if;
                end if;
        end process;
        
end architecture;
