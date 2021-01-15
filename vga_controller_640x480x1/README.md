# VGA controller written in VHDL

features:
* 640x480 resolution with 1bit color depth (i.e. monochrome or black and white)
* BRAM memory buffer that holds one image frame, can be accessed modified at any time

example top.vhdl:

a sample image is written to the memory during programming using a memory initialization file (.mif)
this image is then displayed by the monitor

the .mif-file was created with a simple Python script, you can find it [here](https://github.com/MarcelMG/Miscellaneous/blob/master/image_to_altera_mif/image_to_altera_mif.ipynb).

to simulate the design with ModelSim, go to the directory and execute 'do testbench.tcl'

the whole demo project for the MAX1000 development board is in the .qar-file

![](https://github.com/MarcelMG/my_VHDL_playground/raw/main/vga_controller_640x480x1/640x480_test_image.jpg)
