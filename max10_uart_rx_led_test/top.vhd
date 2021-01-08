library ieee;
use ieee.std_logic_1164.all;
 
-- top level entity
entity top is
	port(
		CLK12M : in std_logic; -- onboard 12MHz clock
		BDBUS0 : in std_logic; -- Transmitter output (Tx) of FT2232H USB UART adapter
		LED : out std_logic_vector(7 downto 0) -- onboard LEDs
	);
end entity;

architecture behavioral of top is

	signal clk, rx : std_logic;
	signal rx_buffer : std_logic_vector(7 downto 0) := (others => '0');
	signal rx_busy_tmp : std_logic_vector(1 downto 0) := "00";
	signal msg_received : boolean := false;
	signal busy : std_logic := '0';
	signal rx_error : std_logic := '0';
	
begin
	
	clk <= CLK12M;
	rx <= BDBUS0;
	
	uart_rx_instance : entity work.uart_rx
		generic map(
			baud_rate_divisor => 625, -- 12MHz/625=19200 Baud
			num_bits => 8,
			parity => 'X' -- no parity bit
		)
		port map(
			reset => '0',
			clk_in => clk,
			rx => rx,
			rx_data => rx_buffer,
			rx_busy => busy,
			rx_parity_error => rx_error
		);
	
	-- 2-bit synchronous left shift register to detect falling edge on 'rx_busy' -> detect when a message is received
	rx_busy_detect : process(clk, busy, rx_busy_tmp)
	begin
		if rising_edge(clk) then
			rx_busy_tmp <= rx_busy_tmp(0) & busy;
		end if;
	end process;
	msg_received <= (rx_busy_tmp = "10"); -- 'msg_received' is true on falling edge of 'rx_busy'
	
	main : process(clk, msg_received, rx_error)
	begin
		if rising_edge(clk) and msg_received and (rx_error = '0') then
			-- light N-th LED according to ASCII number received ( '1' lights first LED, '2' lights second etc. ) 
			case rx_buffer is
				when x"31" =>
					LED(0) <= '1';
				when x"32" =>
					LED(1) <= '1';
				when x"33" =>
					LED(2) <= '1';			
				when x"34" =>
					LED(3) <= '1';	
				when x"35" =>
					LED(4) <= '1';
				when x"36" =>
					LED(5) <= '1';
				when x"37" =>
					LED(6) <= '1';
				when x"38" =>
					LED(7) <= '1';
				when others =>
					LED <= (others => '0');
			end case;
		end if;
	end process;
	
end architecture;