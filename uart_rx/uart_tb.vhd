library ieee;
use ieee.std_logic_1164.all;

entity uart_tb is
end entity;

architecture simulation of uart_tb is
	signal clk : std_logic := '0';
	signal reset : std_logic := '1';
	signal simulation_end : boolean := false;
	signal rx_stimulus : std_logic := '1';
begin

	DUT : entity work.uart_rx
		generic map(
			baud_rate_divisor => 625, --  12 MHz / 625 -> 19.200 Baud
			num_bits => 8,
			parity => '1' -- odd parity
		)
		port map(
			reset => reset,
			clk_in => clk,
			rx => rx_stimulus,
			rx_data => open,
			rx_busy => open
		);
	
	main_clk_gen : process
	begin
		clk <= '0';
		wait for 41_667 ps; -- 12 MHz
		clk <= '1';
		wait for 41_667 ps;
		--stop simulation after all stimuli are over
		if simulation_end then
			wait;
		end if;
	end process;
	
	stimuli : process
	begin
		rx_stimulus <= '1';
		reset <= '1';
		wait for 1 us;
		reset <= '0';
		wait for 1 us;
		
		-- first test transmission "01010011_0" with @ 19200 Baud (52.1µs/bit) --
		rx_stimulus <= '0'; -- start bit
		wait for 52.1 us;
		rx_stimulus <= '1'; -- 0
		wait for 52.1 us;
		rx_stimulus <= '1'; -- 1
		wait for 52.1 us;
		rx_stimulus <= '0'; -- 2
		wait for 52.1 us;
		rx_stimulus <= '0'; -- 3
		wait for 52.1 us;
		rx_stimulus <= '1'; -- 4
		wait for 52.1 us;
		rx_stimulus <= '0'; -- 5
		wait for 52.1 us;
		rx_stimulus <= '1'; -- 6
		wait for 52.1 us;
		rx_stimulus <= '0'; -- 7
		wait for 52.1 us;
		rx_stimulus <= '0'; -- parity bit
		wait for 52.1 us;
		rx_stimulus <= '1'; -- stop bit
		wait for 52.1 us;
		
		wait for 200 us;
		-- second test transmission "01011110_0" with @ 19200 Baud (52.1µs/bit) --
		rx_stimulus <= '0'; -- start bit
		wait for 52.1 us;
		rx_stimulus <= '0'; -- 0
		wait for 52.1 us;
		rx_stimulus <= '1'; -- 1
		wait for 52.1 us;
		rx_stimulus <= '1'; -- 2
		wait for 52.1 us;
		rx_stimulus <= '1'; -- 3
		wait for 52.1 us;
		rx_stimulus <= '1'; -- 4
		wait for 52.1 us;
		rx_stimulus <= '0'; -- 5
		wait for 52.1 us;
		rx_stimulus <= '1'; -- 6
		wait for 52.1 us;
		rx_stimulus <= '0'; -- 7
		wait for 52.1 us;
		rx_stimulus <= '1'; -- parity bit
		wait for 52.1 us;
		rx_stimulus <= '1'; -- stop bit
		wait for 52.1 us;
		-- end test transmission --
		
		wait for 1 ms;
		reset <= '1';
		-------END-------
		simulation_end <= true;
		wait;
	end process;

end architecture simulation;