library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- displays 640x480*1bit monochrome (black&white) image via VGA output
-- image to be displayed is stored in BRAM and can be modified via the memory interface
entity vga_controller is
	port (
		vga_clock : in std_logic; -- 25.175MHz VGA clock input
		reset : in std_logic;
		-- memory interface with BRAM VGA frame buffer
		data_write_clk : in std_logic; --
		data_write_addr : in std_logic_vector(18 downto 0);
		data_write_data : in std_logic_vector(0 downto 0);
		-- hardware output signals
		red : out std_logic;
		green : out std_logic;
		blue : out std_logic;
		hsync : out std_logic;
		vsync : out std_logic
	);
end entity vga_controller;

architecture behavioral of vga_controller is

	signal vertical_pixel_counter : integer range 0 to 525 := 0;
	signal horizontal_pixel_counter : integer range 0 to 800 := 0;
	signal frame_pixel_index : integer range 0 to 640*480 := 0;
	signal rdaddress_sig : std_logic_vector(18 downto 0) := (others => '0');
	signal black_white_pixel : std_logic_vector(0 downto 0) := "0";

begin
	-- convert and wire VGA frame buffer index to BRAM read adress
	rdaddress_sig <= std_logic_vector(to_unsigned(frame_pixel_index, rdaddress_sig'length));
	-- wire RBG outputs to BRAM data output pixel value (black and white)
	red <= black_white_pixel(0);
	green <= black_white_pixel(0);
	blue <= black_white_pixel(0);

	--use a Block-RAM (BRAM) to store a 640x480x1=307200 bit image
	vga_ram_inst : entity work.vga_ram port map (
			data	 => data_write_data,
			rdaddress	 => rdaddress_sig,
			rdclock	 => vga_clock, -- BRAM output data is latched at rising edge of vga_clock
			wraddress	 => data_write_addr,
			wrclock	 => data_write_clk,
			wren	 => '1', -- write enable always on
			q	 => black_white_pixel -- output pixel value (1 bit) from BRAM frame buffer
	);

	reset_and_count : process (reset, vga_clock)
	begin
		if rising_edge(vga_clock) then
			if (reset = '1') then
				vertical_pixel_counter <= 0;
				horizontal_pixel_counter <= 0;
			else
				-- increment pixel counters
				if horizontal_pixel_counter >= 800 - 1 then
					horizontal_pixel_counter <= 0;
					if vertical_pixel_counter >= 525 - 1 then
						vertical_pixel_counter <= 0;
					else
						vertical_pixel_counter <= vertical_pixel_counter + 1;
					end if;
				else
					horizontal_pixel_counter <= horizontal_pixel_counter + 1;
				end if;
			end if;
		end if;
	end process reset_and_count;
	
	h_sync : process (vga_clock)
	begin
		if rising_edge(vga_clock) then
			-- horizontal synch (96 pixels long)
			if (horizontal_pixel_counter >= 0) and (horizontal_pixel_counter < 96) then
				hsync <= '0';
				-- horizontal back porch (48 pixels long)
			elsif (horizontal_pixel_counter >= 96) and (horizontal_pixel_counter < 144) then
				hsync <= '1';
				-- video signal (640 pixels)
			elsif (horizontal_pixel_counter >= 144) and (horizontal_pixel_counter < 784) then
				hsync <= '1';
				-- horizontal front porch (16 pixels long)
			elsif (horizontal_pixel_counter >= 784) and (horizontal_pixel_counter < 800) then
				hsync <= '1';
			else -- this branch should normally never be entered
				-- the 'synthesis translate_off/on' directives tell the tool (Quartus) to ignore the enclosed code for synthesis
				-- synthesis translate_off
				report "error IN PROCESS 'h_sync': entered 'ELSE'-branch. this should NOT occur" severity error;
				report "horizontal_pixel_counter = " & integer'image(horizontal_pixel_counter) severity note;
				-- synthesis translate_on
				null;
			end if;
		end if;
	end process h_sync;
	
	v_sync : process (vga_clock)
	begin
		if rising_edge(vga_clock) then
			-- vertical synch (2 pixels long)
			if (vertical_pixel_counter >= 0) and (vertical_pixel_counter < 2) then
				vsync <= '0';
				-- vertical back porch (33 pixels long)
			elsif (vertical_pixel_counter >= 2) and (vertical_pixel_counter < 35) then
				vsync <= '1';
				-- video signal (480 pixels)
			elsif (vertical_pixel_counter >= 35) and (vertical_pixel_counter < 515) then
				vsync <= '1';
				-- vertical front porch (10 pixels long)
			elsif (vertical_pixel_counter >= 515) and (vertical_pixel_counter < 525) then
				vsync <= '1';
			else -- this branch should normally never be entered
				-- the 'synthesis translate_off/on' directives tell the tool (Quartus) to ignore the enclosed code for synthesis
				-- synthesis translate_off
				report "error IN PROCESS 'v_sync': entered 'ELSE'-branch. this should NOT occur" severity error;
				report "vertical_pixel_counter = " & integer'image(vertical_pixel_counter) severity note;
				-- synthesis translate_on
				null;
			end if;
		end if;
	end process v_sync;
	
	frame_buffer_index_counter : process (vga_clock)
	begin
		if rising_edge(vga_clock) then
			-- check if the video signal should be active based on the pixel counters
			if (vertical_pixel_counter >= 35) and (vertical_pixel_counter < 515) and (horizontal_pixel_counter >= 144) and (horizontal_pixel_counter < 784) then
				-- increment or reset frame buffer index (i.e. BRAM read adress)
				if frame_pixel_index < 640*480-1 then
					frame_pixel_index <= frame_pixel_index + 1;
				else
					frame_pixel_index <= 0;
				end if;
			end if;
		end if;
	end process frame_buffer_index_counter;
	
end architecture behavioral;