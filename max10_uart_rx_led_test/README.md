# demo project for my UART receiver on FPGA dev-board

runs on the Arrow MAX1000 dev-board (intel MAX10 10M08SAU169C8G FPGA)

FPGA receives commands via UART and onboard USB-UART adapter (FTDI FT2232H)

UART receiver support parity check (if enabled)

sending ASCII characters 1 to 8 light up the corresponding LED on the board

sending a different character turns all LEDs off
