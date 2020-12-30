to build and simulate with GHDL and GTKwave:

```shell
ghdl --clean
ghdl --remove
ghdl -a spi_master.vhdl spi_master_tb.vhdl
ghdl -e spi_master_tb
ghdl -r spi_master_tb --wave=sim.ghw
gtkwave sim.ghw
```
