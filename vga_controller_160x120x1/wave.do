onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /vga_controller_tb/vga/vga_clock
add wave -noupdate /vga_controller_tb/vga/reset
add wave -noupdate /vga_controller_tb/vga/data_write_clk
add wave -noupdate /vga_controller_tb/vga/data_write_addr
add wave -noupdate /vga_controller_tb/vga/data_write_data
add wave -noupdate /vga_controller_tb/vga/red
add wave -noupdate /vga_controller_tb/vga/green
add wave -noupdate /vga_controller_tb/vga/blue
add wave -noupdate /vga_controller_tb/vga/hsync
add wave -noupdate /vga_controller_tb/vga/vsync
add wave -noupdate -radix unsigned /vga_controller_tb/vga/vertical_pixel_counter
add wave -noupdate -radix unsigned /vga_controller_tb/vga/horizontal_pixel_counter
add wave -noupdate -radix unsigned /vga_controller_tb/vga/vertical_pixel_pos
add wave -noupdate -radix unsigned /vga_controller_tb/vga/horizontal_pixel_pos
add wave -noupdate -radix unsigned /vga_controller_tb/vga/rdaddress_sig
add wave -noupdate /vga_controller_tb/vga/black_white_pixel
add wave -noupdate -radix unsigned /vga_controller_tb/vga/frame_pixel_index
add wave -noupdate -radix unsigned /vga_controller_tb/vga/downscaled_horizontal_pixel_pos
add wave -noupdate -radix unsigned /vga_controller_tb/vga/downscaled_vertical_pixel_pos
add wave -noupdate -radix unsigned /vga_controller_tb/vga/downscaled_frame_pixel_index
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {15671228 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 331
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {15489145 ns} {15821373 ns}
