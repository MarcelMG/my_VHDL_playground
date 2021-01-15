library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity vga_controller is
	port (
		vga_clock : in std_logic; -- 25.175MHz VGA clock input
		reset : in std_logic;
		-- memory interface with BRAM VGA frame buffer
		data_write_clk : in std_logic;
		data_write_addr : in std_logic_vector(14 downto 0);
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
	signal vertical_pixel_counter : unsigned(9 downto 0) := (others =>'0');
	signal horizontal_pixel_counter : unsigned(9 downto 0) := (others =>'0');
	signal vertical_pixel_pos : unsigned(9 downto 0) := (others =>'0');
	signal horizontal_pixel_pos : unsigned(9 downto 0) := (others =>'0');
	signal downscaled_vertical_pixel_pos : unsigned(7 downto 0) := (others =>'0');
	signal downscaled_horizontal_pixel_pos : unsigned(7 downto 0) := (others =>'0');
	signal frame_pixel_index : unsigned(18 downto 0) := (others =>'0');
	signal downscaled_frame_pixel_index : unsigned(14 downto 0) := (others =>'0');
	signal mult_result : std_logic_vector(15 downto 0) := (others =>'0');
	signal rdaddress_sig : std_logic_vector(14 downto 0) := (others =>'0');
	signal black_white_pixel : std_logic_vector(0 downto 0) := "0";
	signal divide_by_4_counter : unsigned(1 downto 0) := (others => '0');
	
begin

	-- convert and wire VGA frame buffer index to BRAM read adress
	rdaddress_sig <= std_logic_vector(downscaled_frame_pixel_index);
	
	-- wire RBG outputs to BRAM data output pixel value
	red <= black_white_pixel(0);
	green <= black_white_pixel(0);
	blue <= black_white_pixel(0);

	--use a Block-RAM (BRAM) to store a 160x120x1=19200 bit image
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
				vertical_pixel_counter <= (others =>'0');
				horizontal_pixel_counter <= (others =>'0');
			else
				-- increment pixel counters
				if horizontal_pixel_counter >= 800 - 1 then
					horizontal_pixel_counter <= (others =>'0');
					if vertical_pixel_counter >= 525 - 1 then
						vertical_pixel_counter <= (others =>'0');
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
				-- synthesis translate_on
				null;
			end if;
		end if;
	end process v_sync;
	
	-- downscaled_pixel_pos <= pixel_pos / 4
	-- division by 4 is equivalent to right shift by 2
	downscaled_vertical_pixel_pos <= vertical_pixel_pos(9 downto 2);
	downscaled_horizontal_pixel_pos <= horizontal_pixel_pos(9 downto 2);
	-- linear frame buffer index = vertical_pixel_index * 160 + horizontal_pixel_index
	downscaled_frame_pixel_index <= unsigned(mult_result(14 downto 0)) + downscaled_horizontal_pixel_pos;	
	-- multiply downscaled vertical pixel with 160 (datab input is constant)
	multiplier : entity work.vga_mult port map (
		dataa	 => std_logic_vector(downscaled_vertical_pixel_pos),
		result => mult_result
	);
	
	frame_buffer_index_counter : process (vga_clock)
	begin
		if rising_edge(vga_clock) then
			-- check if the video signal should be active based on the pixel counters
			if (vertical_pixel_counter >= 35) and (vertical_pixel_counter < 515) and (horizontal_pixel_counter >= 144) and (horizontal_pixel_counter < 784) then
				vertical_pixel_pos <= vertical_pixel_counter - 35;
				horizontal_pixel_pos <= horizontal_pixel_counter - 144;	
				if frame_pixel_index < 640*480-1 then
					frame_pixel_index <= frame_pixel_index + 1;
				else
					frame_pixel_index <= (others =>'0');
				end if;
			end if;
		end if;
	end process frame_buffer_index_counter;
end architecture behavioral;
