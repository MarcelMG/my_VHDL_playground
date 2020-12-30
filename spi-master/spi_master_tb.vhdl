library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- simple testbench for SPI master. loops back MOSI to MISO (echo)
---------------------------------------------------------------------------------------------

entity spi_master_tb is
end entity;

architecture arch of spi_master_tb is
        signal clk : std_logic := '0';
        signal reset : std_logic := '1';
        signal enable : std_logic := '0';
        signal finished_flag : std_logic;
        constant tx_message : std_logic_vector(7 downto 0) := "10110101";
        signal rx_message : std_logic_vector(7 downto 0);
        signal miso_mosi_loop : std_logic;
begin
        -- generate main clock of 1 MHz
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

        uut : entity work.spi_master
        port map(
                        clk_in          => clk,
                        tx_data       => tx_message,
                        rx_data       => rx_message,
                        reset           => reset,
                        enable        => enable,
                        busy           => open,
                        finished      => finished_flag,
                        spi_sclk      => open,
                        spi_mosi     => miso_mosi_loop,
                        spi_miso     => miso_mosi_loop,
                        spi_ce         => open
                        );

        simulation : process
        begin
                -- begin stimuli
                wait for 2 us;
                reset <= '0';
                wait for 2 us;
                enable <= '1';
                wait until finished_flag = '1';
                wait for 500 ns;  -- so we can see the 'finished' flag/state, otherwise we won't see it since there'd be an immediate transition from finised_state to idle_state
                enable <= '0';
                wait for 100 us;
                -- end stimuli
                wait;
        end process;
        
end architecture;
