onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /uart_tb/clk
add wave -noupdate /uart_tb/reset
add wave -noupdate /uart_tb/rx_stimulus
add wave -noupdate /uart_tb/DUT/rx_data
add wave -noupdate /uart_tb/DUT/rx_busy
add wave -noupdate /uart_tb/DUT/rx_counter
add wave -noupdate /uart_tb/DUT/rx_bit_counter
add wave -noupdate /uart_tb/DUT/rx_edge_tmp
add wave -noupdate /uart_tb/DUT/parity
add wave -noupdate /uart_tb/DUT/par_check_true/computed_parity_bit
add wave -noupdate /uart_tb/DUT/par_check_true/parity_bit
add wave -noupdate /uart_tb/DUT/rx_parity_error
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1285315899 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 249
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
WaveRestoreZoom {307617169 ps} {717773419 ps}
