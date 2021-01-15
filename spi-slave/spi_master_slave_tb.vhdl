library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_master_slave_tb is
end entity;

architecture arch of spi_master_slave_tb is
        signal clk : std_logic := '0';
        signal reset : std_logic := '1';
        signal enable : std_logic := '0';
        signal master_busy : std_logic;
        signal slave_busy : std_logic;
        constant master_tx_message : std_logic_vector(7 downto 0) := "10110101";
        signal master_rx_message : std_logic_vector(7 downto 0);
        constant slave_tx_message : std_logic_vector(7 downto 0) := "11110001";
        signal slave_rx_message : std_logic_vector(7 downto 0);
        signal spi_clock : std_logic;
        signal mosi : std_logic;
        signal miso : std_logic;
        signal ce : std_logic;
begin
        clock_process: process
        begin
                clk <= '0';
                wait for 500 ns;
                clk <= '1';
                wait for 500 ns;
                --stop simulation after certain time
                if NOW > 200 us then
                        wait;
                end if;
        end process;

        uut_spi_master : entity work.spi_master
        port map(
                        clk_in          => clk,
                        tx_data       => master_tx_message,
                        rx_data       => master_rx_message,
                        reset           => reset,
                        enable        => enable,
                        busy           => master_busy,
                        spi_sclk      => spi_clock,
                        spi_mosi     => mosi,
                        spi_miso     => miso,
                        spi_ce         => ce
                        );

        uut_spi_slave : entity work.spi_slave
        port map(
                        tx_data       => slave_tx_message,
                        rx_data       => slave_rx_message,
                        reset           => reset,
                        enable        => enable,
                        busy           => slave_busy,
                        spi_sclk      => spi_clock,
                        spi_mosi     => mosi,
                        spi_miso     => miso,
                        spi_ce         => ce
                        );
                        
        simulation : process
        begin
                -- begin stimuli
                wait for 2 us;
                reset <= '0';
                wait for 2 us;
                enable <= '1';
                wait until master_busy = '0';
                enable <= '0';
                wait for 100 us;
                -- end stimuli
                wait;
        end process;
end architecture;
