library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_controller_tb is
end entity vga_controller_tb;

architecture simulation of vga_controller_tb is

constant main_clock_half_cycle : time := 1 sec / (2 * 48000000);
constant vga_clock_half_cycle : time := 1 sec / (2 * 25200000);

--signal clk : std_logic; -- main clock (48MHz)
signal vga_clk : std_logic; -- 25.2MHz VGA clock
signal framebuf_write_clk : std_logic := '0';
signal framebuf_write_addr : std_logic_vector(14 downto 0) := (others => '0');
signal framebuf_write_value : std_logic := '0';

signal simulation_finished : boolean := false;

begin
		
	-- main_clock_gen: process
	-- begin
		-- if simulation_finished then
			-- wait;
		-- else
			-- clk <= '0';
			-- wait for main_clock_half_cycle;
			-- clk <= '1';
			-- wait for main_clock_half_cycle;
		-- end if;
	-- end process;

	vga_clock_gen: process
	begin
		if simulation_finished then
			wait;
		else
			vga_clk <= '0';
			wait for vga_clock_half_cycle;
			vga_clk <= '1';
			wait for vga_clock_half_cycle;
		end if;
	end process;

	-- instantiate VGA controller
	vga : entity work.vga_controller
	port map(
		vga_clock => vga_clk,
		reset => '0',
		-- memory interface with BRAM VGA frame buffer
		data_write_clk => framebuf_write_clk,
		data_write_addr => framebuf_write_addr,
		data_write_data(0) => framebuf_write_value, -- note: 'data_write_data' is a std_logic_vector of length 1, so (0) access is necessary to wire it to std_logic
		-- hardware output signals
		red => open,
		green => open,
		blue => open,
		hsync => open,
		vsync => open
	);




	simulation_stimuli : process
	begin
		-- begin stimuli
		wait for 25 ms;
		-- end stimuli
		simulation_finished <= true;
		wait;
	end process simulation_stimuli;
        
end architecture simulation;
