to build and simulate with GHDL and GTKwave:

ghdl --clean; ghdl --remove
ghdl -a spi_master.vhdl spi_slave.vhdl spi_master_slave_tb.vhdl
ghdl -e spi_master_slave_tb
ghdl -r spi_master_slave_tb --wave=sim.ghw
gtkwave sim.ghw
