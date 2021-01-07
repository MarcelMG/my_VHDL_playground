# stop any simulation that is currently running
quit -sim
# create the default "work" library
vlib work;
# compile (you can use *.vhd to compile all VHDL files in the working directory)
vcom uart_rx.vhd uart_tb.vhd
vsim work.uart_tb
# display waveforms according to config file 'wave.do'
do wave.do
# run simulation
run 25 ms