library ieee;
use ieee.std_logic_1164.all;
library work;
use work.vga_640x480x1_frame_type.all;


entity vga_controller_tb is
end entity vga_controller_tb;

architecture simulation of vga_controller_tb is

constant vga_clock_half_cycle : time := 1 sec / (2 * 25175000);
signal clk : std_logic := '0';
signal reset : std_logic := '1';
signal vga_r, vga_g, vga_b, h_sync, v_sync : std_logic;

signal test_frame : vga_640x480x1_frame;

signal simulation_finished : boolean := false;

begin

        uut : entity work.vga_controller port map(   vga_clock    => clk,
                                                                                reset           => reset,
                                                                                frame          => test_frame,
                                                                                red              => vga_r,
                                                                                green           => vga_g,
                                                                                blue             => vga_b,
                                                                                hsync           => h_sync,
                                                                                vsync           => v_sync               );
                                                                                
        vga_clock_gen: process
        begin
                if simulation_finished then
                        wait;
                else
                        clk <= '0';
                        wait for vga_clock_half_cycle;
                        clk <= '1';
                        wait for vga_clock_half_cycle;
                end if;
        end process vga_clock_gen;

        simulation_stimuli : process
        begin
                -- begin stimuli
                wait for 1 us;
                reset <= '0';
                wait for 20 ms;
                -- end stimuli
                simulation_finished <= true;
                wait;
                -- stop simulation in a not-so-elegant way
                --report LF & LF & "-----------------------------------------------------------------" & LF
                                         --& "  THIS IS NOT AN ERROR. SIMULATION FINISHED" & LF 
                                         --& "-----------------------------------------------------------------" severity failure;
        end process simulation_stimuli;
        
end architecture simulation;
