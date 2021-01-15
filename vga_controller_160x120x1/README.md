# VGA controller written in VHDL

features:
* 160x120 pixel image resolution with 4x upscaling to 640x480 VGA signal
* 1bit black and white (monochrome) color depth
* BRAM frame buffer stores image to be displayed, can be modified at any time

how is the 160x120 image upscaled to 640x480 resolution?

-> as the VGA controller 'scans' the horizontal and vertical lines of the video signal, it keeps track of the current pixel position with a horizontal and a vertical pixel counter. A 2bit-counter is used to divide this count by 4, so we get two 'downscaled' pixel positions. To finally compute the linear adress of the pixel value stored in the BRAM frame buffer, we compute adress = 160 * vertical_pos + horizontal_pos. For the multiplication, a 9bit hardware multiplier of the MAX10 FPGA is used. 

example top.vhdl:

a sample image is written to the memory during programming using a memory initialization file (.mif) this image is displayed by the monitor

the .mif-file was created with a simple Python script, you can find it [here](https://github.com/MarcelMG/Miscellaneous/blob/master/image_to_altera_mif/image_to_altera_mif.ipynb).

to simulate the design with ModelSim, go to the directory and execute 'do testbench.tcl'

the whole demo project for the MAX1000 development board is in the .qar-file


![](https://github.com/MarcelMG/my_VHDL_playground/raw/main/vga_controller_160x120x1/160x120_test_image.jpg)
