library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- UART Receiver mode (1 start bit, variable data bits, optional parity bit, and 1 stop bit)	
entity uart_rx is
	generic(
		baud_rate_divisor : positive := 625; -- frequency {clk_in} / baud_rate_divisor = baud rate
		num_bits : positive := 8; -- bits per transmission, is almost always 8
		parity : std_logic := 'X' -- '1' for odd, '0' for even, other (e.g. 'X') to disable parity bit
		);
	port(
		reset : in std_logic; -- active high synchronous reset
		clk_in : in std_logic; -- clock input, should ideally be an integer multiple of the baud rate
		rx : in std_logic; -- RX port
		rx_data : buffer std_logic_vector((num_bits - 1) downto 0); -- received data can be read from this port
		rx_busy : buffer std_logic; -- is high ('1') during ongoing reception, falling edge indicates that received data is ready to be read from 'rx_data'
		rx_parity_error :  out std_logic -- '1' if parity bit is wrong, '0' if correct (or if parity bit generic option is disabled)
		);
end entity uart_rx;


architecture behavioral of uart_rx is
--------------------------architecture header------------------------------------
	signal rx_counter : integer range 0 to baud_rate_divisor;
	signal rx_bit_counter : integer range 0 to (num_bits + 2);
	signal rx_edge_tmp : std_logic_vector(1 downto 0);
	
	-- returns '1' if odd parity, '0' if even parity
	function compute_parity(x : std_logic_vector) return std_logic is
		variable par : std_logic := '0';
	begin
		for i in x'range loop
		  par := par xor x(i);
		end loop;
		return par;
	end function compute_parity;
---------------------------architecture body--------------------------
begin

	-- 2-bit synchronous left shift register to detect falling edge on RX line (start bit)
	rx_start_detect : process(clk_in, rx, rx_edge_tmp)
	begin
		if rising_edge(clk_in) then
			if reset = '1' then
				rx_edge_tmp <= (others => '0');
			else
				rx_edge_tmp <= rx_edge_tmp(0) & rx;
			end if;
		end if;
	end process;

	-------- version with parity check -------
	par_check_true : if (parity = '1') or (parity = '0') generate
		signal parity_bit : std_logic;
		signal computed_parity_bit : std_logic;
	begin
		rx_main : process(clk_in, reset)
		begin
			if rising_edge(clk_in) then
				if reset = '1' then
					rx_parity_error <= '0';
					rx_busy <= '0';
					rx_counter <= 0;
					rx_bit_counter <= 0;
					rx_data <= (others => '0');
				else
					-- check for start bit (falling edge on RX line)
					if (rx_busy = '0') and (rx_edge_tmp = "10") then
						rx_busy <= '1';
						rx_counter <= 0;
						rx_bit_counter <= 0;
					end if;
					if rx_busy = '1' then
						-- bit counter
						if rx_counter < (baud_rate_divisor - 1) then
							rx_counter <= rx_counter + 1;
						else
							rx_counter <= 0;
							rx_bit_counter <= rx_bit_counter + 1;
						end if;
					end if;
					-- sample data bits in the middle (at rx_counter = (baud_rate_divisor / 2 - 1))
					if (rx_bit_counter >= 1) and (rx_bit_counter <= num_bits) and (rx_counter = (baud_rate_divisor / 2 - 1)) then
						rx_data(rx_bit_counter-1) <= rx; -- sample and store bit
					-- sample parity bit in the middle (at rx_counter = (baud_rate_divisor / 2 - 1))
					elsif rx_bit_counter = (num_bits + 1) and (rx_counter = (baud_rate_divisor / 2 - 1)) then
						parity_bit <= rx; -- sample and store bit
						computed_parity_bit <= compute_parity(rx_data); -- compute parity of received data bytes
					 -- received stop bit -> finished receiving
					elsif rx_bit_counter > (num_bits + 1) then
						rx_bit_counter <= 0;-- reset bit counter
						rx_busy <= '0'; -- clear busy flag -> reception complete
						rx_parity_error <= computed_parity_bit xor parity_bit; -- compare computed with expected parity and set error flag accordingly
					end if;
				end if;	
			end if;
		end process;
	end generate par_check_true;
	
	-------- version without parity check -------
	par_check_false : if not( (parity = '1') or (parity = '0') ) generate
		rx_main : process(clk_in, reset)
		begin
			if rising_edge(clk_in) then
				if reset = '1' then
					rx_parity_error <= '0';
					rx_busy <= '0';
					rx_counter <= 0;
					rx_bit_counter <= 0;
					rx_data <= (others => '0');
				else
					-- check for start bit (falling edge on RX line)
					if (rx_busy = '0') and (rx_edge_tmp = "10") then
						rx_busy <= '1';
						rx_counter <= 0;
						rx_bit_counter <= 0;
					end if;
					if rx_busy = '1' then
						-- bit counter
						if rx_counter < (baud_rate_divisor - 1) then
							rx_counter <= rx_counter + 1;
						else
							rx_counter <= 0;
							rx_bit_counter <= rx_bit_counter + 1;
						end if;
					end if;
					 -- sample data bits in the middle (rx_counter = (baud_rate_divisor / 2 - 1))
					if (rx_bit_counter >= 1) and (rx_bit_counter <= num_bits) and (rx_counter = (baud_rate_divisor / 2 - 1)) then
						rx_data(rx_bit_counter-1) <= rx; -- sample and store bit
					 -- received stop bit -> finished receiving
					elsif rx_bit_counter > num_bits then
						rx_bit_counter <= 0; -- reset bit counter
						rx_busy <= '0'; -- clear busy flag -> reception complete
					end if;		
				end if;	
			end if;
		end process;	
	end generate par_check_false;
	
end architecture behavioral;			
			