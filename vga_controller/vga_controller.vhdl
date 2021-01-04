library ieee;
use ieee.std_logic_1164.all;
library work;
use work.vga_640x480x1_frame_type.all;

entity vga_controller is       
        port(vga_clock : in std_logic;
                reset : in std_logic;
                frame : in vga_640x480x1_frame; -- must be 25.175 MHz clock
                red : out std_logic;
                green : out std_logic;
                blue : out std_logic;
                hsync : out std_logic;
                vsync : out std_logic
                );
end entity vga_controller;

architecture behavioral of vga_controller is

signal vertical_pixel_counter : integer range 0 to 525-1;
signal horizontal_pixel_counter : integer range 0 to 800-1;
signal active : boolean;

begin
        -- asynchronous reset with synchronous de-assertion
        reset_and_count : process(reset, vga_clock)
        begin
                -- asynchronous reset assertion
                if (reset = '1') then
                        active <= false;
                        vertical_pixel_counter <= 0;
                        horizontal_pixel_counter <= 0;
                elsif rising_edge(vga_clock) then
                        -- synchronous reset de-assertion
                        if (reset = '0') then
                                active <= true;
                                -- increment pixel counters
                                if horizontal_pixel_counter >= 800-1 then
                                        horizontal_pixel_counter <= 0;
                                        if vertical_pixel_counter >= 525-1 then
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

        h_sync : process(vga_clock)
        begin
                if active and rising_edge(vga_clock) then
                        -- horizontal synch (96 pixels long)
                        if (horizontal_pixel_counter >= 0) and (horizontal_pixel_counter < 96) then
                                hsync <= '1';
                        -- horizontal back porch (48 pixels long)
                        elsif (horizontal_pixel_counter >= 96) and (horizontal_pixel_counter < 144) then
                                hsync <= '0';
                        -- video signal (640 pixels)
                        elsif (horizontal_pixel_counter >= 144) and (horizontal_pixel_counter < 784) then
                                hsync <= '0';
                        -- horizontal front porch (16 pixels long)
                        elsif (horizontal_pixel_counter >= 784) and (horizontal_pixel_counter < 800) then
                                hsync <= '0';
                        else -- this branch should normally never be entered
                                -- the 'synthesis translate_off/on' directives tell the tool (Quartus) to ignore the enclosed code for synthesis
                                -- synthesis translate_off
                                report "error in process 'h_sync': entered 'else'-branch. this should not occur" severity error;
                                report "horizontal_pixel_counter = " & integer'image(horizontal_pixel_counter) severity note;
                                -- synthesis translate_on
                                null;
                        end if;
                elsif not(active) then
                        hsync <= '1'; -- idle state
                else -- (active=true) and falling edge(vga_clock)
                        null;
                end if;
        end process h_sync;

        v_sync : process(vga_clock)
        begin
                if active and rising_edge(vga_clock) then
                        -- vertical synch (2 pixels long)
                        if (vertical_pixel_counter >= 0) and (vertical_pixel_counter < 2) then
                                vsync <= '1';
                        -- vertical back porch (33 pixels long)
                        elsif (vertical_pixel_counter >= 2) and (vertical_pixel_counter < 35) then
                                vsync <= '0';
                        -- video signal (480 pixels)
                        elsif (vertical_pixel_counter >= 35) and (vertical_pixel_counter < 515) then
                                vsync <= '0';
                        -- vertical front porch (10 pixels long)
                        elsif (vertical_pixel_counter >= 515) and (vertical_pixel_counter < 525) then
                                vsync <= '0';
                        else -- this branch should normally never be entered
                                -- the 'synthesis translate_off/on' directives tell the tool (Quartus) to ignore the enclosed code for synthesis
                                -- synthesis translate_off
                                report "error in process 'v_sync': entered 'else'-branch. this should not occur" severity error;
                                report "vertical_pixel_counter = " & integer'image(vertical_pixel_counter) severity note;
                                -- synthesis translate_on
                                null;
                        end if;
                elsif not(active) then
                        vsync <= '1'; -- idle state
                else -- (active=true) and falling edge(vga_clock)
                        null;
                end if;
        end process v_sync;
        
        video : process(vga_clock)
        variable black_white_pixel : std_logic;
        variable pixel_index_x : integer range 0 to 640-1;
        variable pixel_index_y : integer range 0 to 480-1;
        begin
                if rising_edge(vga_clock)
                                and active
                                -- check if the video signal should be active based on the pixel counters
                                and (vertical_pixel_counter >= 35) and (vertical_pixel_counter < 515)
                                and (horizontal_pixel_counter >= 144) and (horizontal_pixel_counter < 784) then
                        -- compute x- and y-indices for image frame pixel array
                        pixel_index_x := horizontal_pixel_counter - 144;
                        pixel_index_y := vertical_pixel_counter - 35;
                        -- get current black&white pixel to be outputted from image 'frame' (2D-array)
                        black_white_pixel := frame(pixel_index_x)(pixel_index_y);
                        -- output either RGB=(0, 0, 0) or RGB=(1,1,1) to create black&white image (no greyscale or color)
                        red <= black_white_pixel;
                        green <= black_white_pixel;
                        blue <= black_white_pixel;
                end if;
        end process video;
end architecture behavioral;
