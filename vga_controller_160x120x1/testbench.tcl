# stop any simulation that is currently running
quit -sim
# create the default "work" library
vlib work;
# compile (you can use *.vhd to compile all VHDL files in the working directory)
vcom vga_ram.vhd vga_mult.vhd vga_controller.vhdl testbench.vhdl
# simulate with timescale of 1ns to make sim faster
vsim work.vga_controller_tb -t ns
# display waveforms according to config file 'wave.do'
do wave.do
# run simulation for certain time
run 25 ms