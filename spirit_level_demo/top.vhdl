library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity top is
	port(
		CLK12M : in std_logic;
		SPI_CS : out std_logic;
		SPI_SCLK : out std_logic;
		SPI_MOSI : out std_logic;
		SPI_MISO : in std_logic;
		board_leds : out std_logic_vector(7 downto 0);
		-- "fake" port to prevent Quartus from optimizing unused signal 'signaltap_clk'
		signaltap_clk : out std_logic
	);
end entity;


architecture behavioral of top is
	signal clk : std_logic := '0';
	signal acc_x, acc_y, acc_z : signed(11 downto 0) := (others => '0');
	signal roll : signed(15 downto 0) := (others => '0');
	signal roll_v : std_logic_vector(15 downto 0) := (others => '0');
	
begin
	

	-- 'roll' is in sign + 2bit integer + 13bit fractional fixed point (signed) format
	roll <= signed(roll_v);
	-- compute angle from y- and z-acceleration using IP atan2 module: angle=arctan(acc_y/acc_z)
	atan2 : entity work.cordic_atan
		port map (
			areset => '0',
			clk => clk,
			q => roll_v,
			x => std_logic_vector(acc_y),
			y => std_logic_vector(acc_z)
		);

	pll_inst : entity work.pll
		port map(
			inclk0 => CLK12M,
			c0	 => clk,	-- 12 MHz
			c1	 => signaltap_clk -- 1MHz
		);
		
	accelerometer_inst : entity work.accelerometer_lis3dh
		port map(
			clk => clk,
			SPI_CS => SPI_CS,
			SPI_SCLK => SPI_SCLK,
			SPI_MOSI => SPI_MOSI,
			SPI_MISO => SPI_MISO,
			acc_x => acc_x,
			acc_y => acc_y,
			acc_z => acc_z
		);
	
	-- spirit level (Wasserwaage) demo with onboard LEDs
	leds : process(clk, roll)
	begin
		if roll > to_signed(14000, 16) then
			board_leds <= (7=>'1', others=>'0');
		elsif (roll > to_signed(13200, 16)) and (roll <= to_signed(14000, 16)) then
			board_leds <= (6=>'1', others=>'0');
		elsif (roll > to_signed(12800, 16)) and (roll <= to_signed(13200, 16)) then
			board_leds <= (5=>'1', others=>'0');
		elsif (roll > 12700) and (roll <= to_signed(12800, 16)) then
			board_leds <= (4=>'1', others=>'0');	
		elsif (roll > to_signed(12600, 16)) and (roll <= to_signed(12800, 16)) then
			board_leds <= (3=>'1', others=>'0');
		elsif (roll > to_signed(12100, 16)) and (roll <= to_signed(12600, 16)) then
			board_leds <= (2=>'1', others=>'0');
		elsif (roll > to_signed(11400, 16)) and (roll <= to_signed(12100, 16)) then
			board_leds <= (1=>'1', others=>'0');	
		elsif roll < to_signed(11400, 16) then
			board_leds <= (0=>'1', others=>'0');
		end if;
	end process;

end architecture;