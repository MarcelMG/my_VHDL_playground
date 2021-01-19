library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity accelerometer_lis3dh is
	port(
		clk : in std_logic;
		SPI_CS : out std_logic;
		SPI_SCLK : out std_logic;
		SPI_MOSI : out std_logic;
		SPI_MISO : in std_logic;
		acc_x : out signed(11 downto 0);
		acc_y : out signed(11 downto 0);
		acc_z : out signed(11 downto 0)
	);

end entity;

architecture behavioral of accelerometer_lis3dh is

	signal spi_tx_buf, spi_rx_buf : std_logic_vector(15 downto 0) := (others => '0');
	signal spi_write_enable, spi_rx_finished : std_logic := '0';
	type state_type is ( 	config_start_state,
							get_device_id_state,
							verify_device_id_state,
							write_config_state_1,
							write_config_state_2,
							write_config_state_3,
							write_config_state_4,
							write_config_state_5,
							write_config_state_6,
							error_state,
							x_read_state1,
							x_read_state2,
							x_read_state3,
							x_read_state4,
							x_read_state5,
							x_read_state6,
							y_read_state1,
							y_read_state2,
							y_read_state3,
							y_read_state4,
							y_read_state5,
							y_read_state6,
							z_read_state1,
							z_read_state2,
							z_read_state3,
							z_read_state4,
							z_read_state5,
							z_read_state6
							);

	signal state : state_type := config_start_state;
	signal delay_counter : integer range 0 to 1000 := 0;
	constant delay_N_cycles : integer := 48;
	constant read_dummy_byte : std_logic_vector(7 downto 0) := (others => '0');
	-- who-am-i and configuration register adresses
	constant who_am_i_reg_addr : std_logic_vector(6 downto 0) := "0001111";
	constant ctrl_reg1_addr : std_logic_vector(6 downto 0) := "0100000";
	constant ctrl_reg4_addr : std_logic_vector(6 downto 0) := "0100011";
	constant write_bit : std_logic := '0';
	constant read_bit : std_logic := '1';
	-- hardcoded ID in the who-am-i register, to verify against read ID
	constant who_am_i_expected_value : std_logic_vector(7 downto 0) := "00110011";
	-- 10Hz data rate, normal mode, all 3 axes enabled
	constant ctrl_reg1_cfg : std_logic_vector(7 downto 0) := "00100111";
	-- high-resolution (12bit) mode, +-2g full scale
	constant ctrl_reg4_cfg : std_logic_vector(7 downto 0) := "00001000";
	-- data register adresses
	constant out_x_l_reg_addr : std_logic_vector(6 downto 0) := "0101000";
	constant out_x_h_reg_addr : std_logic_vector(6 downto 0) := "0101001";
	constant out_y_l_reg_addr : std_logic_vector(6 downto 0) := "0101010";
	constant out_y_h_reg_addr : std_logic_vector(6 downto 0) := "0101011";
	constant out_z_l_reg_addr : std_logic_vector(6 downto 0) := "0101100";
	constant out_z_h_reg_addr : std_logic_vector(6 downto 0) := "0101101";
	-- temporary values for assembling low- and high-byte
	signal x_data_tmp : std_logic_vector(11 downto 0) := (others => '0');
	signal y_data_tmp : std_logic_vector(11 downto 0) := (others => '0');
	signal z_data_tmp : std_logic_vector(11 downto 0) := (others => '0');
	
begin

	spi_master_instance : entity work.spi_master
		generic map (   
			N => 16,                                            -- 32bit serial word length is default
			CPOL => '1',                                        -- SPI mode selection (mode 0 default)
			CPHA => '1',                                      -- CPOL = clock polarity, CPHA = clock phase.
			SPI_2X_CLK_DIV => 12                                -- for a 12MHz sclk_i, yields a 500kHz SCK
		)
		 port map (  
			sclk_i => clk,                                   -- high-speed serial interface system clock
			pclk_i => clk,                                   -- high-speed parallel interface system clock
			rst_i => '0',                                    -- reset core
			---- serial interface ----
			spi_ssel_o => SPI_CS,                                     -- spi bus slave select line
			spi_sck_o => SPI_SCLK,                                      -- spi bus sck
			spi_mosi_o => SPI_MOSI,                                     -- spi bus mosi output
			spi_miso_i => SPI_MISO,                               -- spi bus spi_miso_i input
			---- parallel interface ----
			di_req_o => open,                                       -- preload lookahead data request line
			di_i => spi_tx_buf,  -- parallel data in (clocked on rising spi_clk after last bit)
			wren_i => spi_write_enable,                                   -- user data write enable, starts transmission when interface is idle
			wr_ack_o => open,                                       -- write acknowledge
			do_valid_o => spi_rx_finished,                                     -- do_o data valid signal, valid during one spi_clk rising edge.
			do_o => spi_rx_buf 
			);

	FSM : process(clk)
	begin
		if rising_edge(clk) then
			case state is
				when config_start_state =>
					-- delay between SPI transactions so that the SPI master will pull CS high inbetween transactions (otherwise the SPI master performs continuous transmissions, i.e. CS stays low)
					if delay_counter < delay_N_cycles then
						delay_counter <= delay_counter + 1;
					else
						delay_counter <= 0;
						spi_tx_buf <= (read_bit & who_am_i_reg_addr & read_dummy_byte);
						state <= get_device_id_state;
					end if;
				when get_device_id_state =>
					spi_write_enable <= '1';
					state <= verify_device_id_state;
				when verify_device_id_state =>
					spi_write_enable <= '0';
					if spi_rx_finished = '1' then
						if spi_rx_buf(7 downto 0) = who_am_i_expected_value then
							state <= write_config_state_1;
						else
							state <= error_state;
							----SIMULATION ONLY BEGIN------------------------------------------------
							-- bypass id-check during simulation (since I didn't simulate the slave)
							-- synthesis translate_off
							state <= write_config_state_1;
							-- synthesis translate_on
							----SIMULATION ONLY END-------------------------------------------------
						end if;
					end if;
				when error_state =>
					null;
				when write_config_state_1 =>
					-- delay between SPI transactions so that the SPI master will pull CS high inbetween transactions
					if delay_counter < delay_N_cycles then
						delay_counter <= delay_counter + 1;
					else
						delay_counter <= 0;
						spi_tx_buf <= (write_bit & ctrl_reg1_addr & ctrl_reg1_cfg);
						state <= write_config_state_2;
					end if;
				when write_config_state_2 =>
					spi_write_enable <= '1';
					state <= write_config_state_3;
				when write_config_state_3 =>
					spi_write_enable <= '0';
					if spi_rx_finished = '1' then
						state <= write_config_state_4;
					end if;
				when write_config_state_4 =>
					-- delay between SPI transactions so that the SPI master will pull CS high inbetween transactions
					if delay_counter < delay_N_cycles then
						delay_counter <= delay_counter + 1;
					else
						delay_counter <= 0;
						spi_tx_buf <= (write_bit & ctrl_reg4_addr & ctrl_reg4_cfg);
						state <= write_config_state_5;
					end if;
				when write_config_state_5 =>
					spi_write_enable <= '1';
					state <= write_config_state_6;
				when write_config_state_6 =>
					spi_write_enable <= '0';
					if spi_rx_finished = '1' then
						state <= x_read_state1;
					end if;
				---- READ X-AXIS DATA
				when x_read_state1 =>
					-- delay between SPI transactions so that the SPI master will pull CS high inbetween transactions
					if delay_counter < delay_N_cycles then
						delay_counter <= delay_counter + 1;
					else
						delay_counter <= 0;
						spi_tx_buf <= (read_bit & out_x_l_reg_addr & read_dummy_byte);
						state <= x_read_state2;
					end if;
				when x_read_state2 =>
					spi_write_enable <= '1';
					state <= x_read_state3;
				when x_read_state3 =>
					spi_write_enable <= '0';
					if spi_rx_finished = '1' then
						-- data from LIS3DH is left-justified
						x_data_tmp(3 downto 0) <= spi_rx_buf(7 downto 4);
						state <= x_read_state4;
					end if;
				when x_read_state4 =>
					-- delay between SPI transactions so that the SPI master will pull CS high inbetween transactions
					if delay_counter < delay_N_cycles then
						delay_counter <= delay_counter + 1;
					else
						delay_counter <= 0;
						spi_tx_buf <= (read_bit & out_x_h_reg_addr & read_dummy_byte);
						state <= x_read_state5;
					end if;
				when x_read_state5 =>
					spi_write_enable <= '1';
					state <= x_read_state6;
				when x_read_state6 =>
					spi_write_enable <= '0';
					if spi_rx_finished = '1' then
						x_data_tmp(11 downto 4) <= spi_rx_buf(7 downto 0);
						acc_x <= signed(x_data_tmp);
						state <= y_read_state1;						
					end if;
				---- READ Y-AXIS DATA
				when y_read_state1 =>
					-- delay between SPI transactions so that the SPI master will pull CS high inbetween transactions
					if delay_counter < delay_N_cycles then
						delay_counter <= delay_counter + 1;
					else
						delay_counter <= 0;
						spi_tx_buf <= (read_bit & out_y_l_reg_addr & read_dummy_byte);
						state <= y_read_state2;
					end if;
				when y_read_state2 =>
					spi_write_enable <= '1';
					state <= y_read_state3;
				when y_read_state3 =>
					spi_write_enable <= '0';
					if spi_rx_finished = '1' then
						-- data from LIS3DH is left-justified
						y_data_tmp(3 downto 0) <= spi_rx_buf(7 downto 4);
						state <= y_read_state4;
					end if;
				when y_read_state4 =>
					-- delay between SPI transactions so that the SPI master will pull CS high inbetween transactions
					if delay_counter < delay_N_cycles then
						delay_counter <= delay_counter + 1;
					else
						delay_counter <= 0;
						spi_tx_buf <= (read_bit & out_y_h_reg_addr & read_dummy_byte);
						state <= y_read_state5;
					end if;
				when y_read_state5 =>
					spi_write_enable <= '1';
					state <= y_read_state6;
				when y_read_state6 =>
					spi_write_enable <= '0';
					if spi_rx_finished = '1' then
						y_data_tmp(11 downto 4) <= spi_rx_buf(7 downto 0);
						acc_y <= signed(y_data_tmp);
						state <= z_read_state1;						
					end if;
				---- READ Z-AXIS DATA
				when z_read_state1 =>
					-- delay between SPI transactions so that the SPI master will pull CS high inbetween transactions
					if delay_counter < delay_N_cycles then
						delay_counter <= delay_counter + 1;
					else
						delay_counter <= 0;
						spi_tx_buf <= (read_bit & out_z_l_reg_addr & read_dummy_byte);
						state <= z_read_state2;
					end if;
				when z_read_state2 =>
					spi_write_enable <= '1';
					state <= z_read_state3;
				when z_read_state3 =>
					spi_write_enable <= '0';
					if spi_rx_finished = '1' then
						-- data from LIS3DH is left-justified
						z_data_tmp(3 downto 0) <= spi_rx_buf(7 downto 4);
						state <= z_read_state4;
					end if;
				when z_read_state4 =>
					-- delay between SPI transactions so that the SPI master will pull CS high inbetween transactions
					if delay_counter < delay_N_cycles then
						delay_counter <= delay_counter + 1;
					else
						delay_counter <= 0;
						spi_tx_buf <= (read_bit & out_z_h_reg_addr & read_dummy_byte);
						state <= z_read_state5;
					end if;
				when z_read_state5 =>
					spi_write_enable <= '1';
					state <= z_read_state6;
				when z_read_state6 =>
					spi_write_enable <= '0';
					if spi_rx_finished = '1' then
						z_data_tmp(11 downto 4) <= spi_rx_buf(7 downto 0);
						acc_z <= signed(z_data_tmp);
						state <= x_read_state1;						
					end if;
				when others =>
					null;
			end case;
		end if;	
	
	end process FSM;
	
end architecture;