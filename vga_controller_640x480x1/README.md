# VGA controller written in VHDL

features:
* 640x480 resolution with 1bit color depth (i.e. monochrome or black and white)
* BRAM memory buffer that holds one image frame, can be accessed modified at any time

example top.vhdl:

a sample image is written to the memory during programming using a memory initialization file (.mif)
this image is displayed by the monitor

to simulate the design with ModelSim, go to the directory and execute 'do testbench.tcl'

the whole demo project for the MAX1000 development board is in the .qar-file
