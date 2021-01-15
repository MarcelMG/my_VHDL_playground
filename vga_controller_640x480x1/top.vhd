library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
	port(
		CLK12M : in std_logic; -- 12MHz onboard clock source
		vga_hsync : out std_logic;
		vga_vsync : out std_logic;
		vga_red : out std_logic;
		vga_green : out std_logic;
		vga_blue : out std_logic
	);
end entity top;

architecture behavioral of top is
 
signal clk : std_logic; -- main clock (48MHz)
signal vga_clk : std_logic; -- 25.2MHz VGA clock
-- signals to interface VGA BRAM memory
signal framebuf_write_clk : std_logic := '0';
signal framebuf_write_addr : std_logic_vector(18 downto 0) := (others => '0');
signal framebuf_write_value : std_logic := '1';

begin
	
	--instantiate PLL IP module
	pll_inst : entity work.pll
	port map (
			inclk0	=> CLK12M, -- 12MHz onboard clock source
			c0	 		=> vga_clk, -- 25.2 MHz VGA clock (should ideally be 25.175, but 25.2MHz is in tolerance band)
			c1	 		=> clk -- 48MHz main clock
		);
	
	-- instantiate VGA controller
	vga : entity work.vga_controller
	port map(
		vga_clock => vga_clk,
		reset => '0',
		-- memory interface with BRAM VGA frame buffer
		data_write_clk => clk,
		data_write_addr => framebuf_write_addr,
		data_write_data(0) => framebuf_write_value, -- note: 'data_write_data' is a std_logic_vector of length 1, so (0) access is necessary to wire it to std_logic
		-- hardware output signals
		red => vga_red,
		green => vga_green,
		blue => vga_blue,
		hsync => vga_hsync,
		vsync => vga_vsync
	);
	
	-- BRAM VGA buffer content is initialized with a sample image via *.mif-file
  
end architecture behavioral;