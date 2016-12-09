-- EMACS settings: -*-  tab-width: 4; indent-tabs-mode: t -*-
-- vim: tabstop=4:shiftwidth=4:noexpandtab
-- kate: tab-width 4; replace-tabs off; indent-width 4;
-- =============================================================================
-- Authors:					Paul Genssler
--
-- Entity:					Simple ICAP wrapper with a fifo interface and a few status signals
--
-- Description:
-- -------------------------------------
-- This module was designed to connect the Xilinx "Internal Configuration Access Port" (ICAP)
-- to a PCIe endpoint on a Dini board. Tested on:
--
-- tbd
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany,
--										 Chair of VLSI-Design, Diagnostics and Architecture
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--		http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- =============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.vcomponents.all;

library poc;
use poc.utils.all;

entity reconfig_icap_wrapper is
	generic (
		MIN_DEPTH_OUT     : positive := 256;
		MIN_DEPTH_IN      : positive := 256
	);
	port (
		clk 			: in	std_logic;
		reset			: in	std_logic;
		clk_icap		: in	std_logic;		-- clock signal for ICAP, max 100 MHz (double check with manual)

		icap_busy		: out	std_logic;		-- the ICAP is processing the data
		icap_readback	: out	std_logic;		-- high during a readback
		icap_partial_res: out	std_logic;		-- high during reconfiguration

		-- data in
		write_put		: in	std_logic;
		write_full		: out	std_logic;
		write_data		: in	std_logic_vector(31 downto 0);
		write_done		: in	std_logic;		-- high pulse/edge after all data was written

		-- data out
		read_got		: in	std_logic;
		read_valid 		: out	std_logic;
		read_data 		: out	std_logic_vector(31 downto 0)
	);
end reconfig_icap_wrapper;

architecture Behavioral of reconfig_icap_wrapper is
	signal reset_icap				: std_logic;

	signal write_done_d				: std_logic;
	signal write_done_edge			: std_logic;
	signal write_done_icapclk		: std_logic;

	signal in_data_valid			: std_logic;
	constant STATE_BITS 			: positive := 2;
	constant state_almost_full		: std_logic_vector(STATE_BITS -1 downto 0) := (0 => '0', others => '1');
	signal in_data_fill_state		: std_logic_vector(STATE_BITS -1 downto 0);
	signal in_data_rden				: std_logic;
	signal in_data_start			: std_logic;		-- high after enough data was written into the pci->icap fifo
														-- or write done (status register)
	signal icap_rden				: std_logic;		-- icap wants some yummy data
	signal in_data					: std_logic_vector(31 downto 0);

	signal out_data_full			: std_logic;
	signal out_data_put				: std_logic;
	signal out_data					: std_logic_vector(31 downto 0);

	signal icap_data_config			: std_logic_vector(31 downto 0);
	signal icap_data_readback		: std_logic_vector(31 downto 0);
	signal icap_csb					: std_logic;
	signal icap_rw					: std_logic;

	signal icap_data_config_r		: std_logic_vector(31 downto 0);
	signal icap_data_readback_r		: std_logic_vector(31 downto 0);
	signal icap_csb_r				: std_logic;
	signal icap_rw_r				: std_logic;

	signal fsm_status				: std_logic_vector(31 downto 0);
	signal fsm_status_clk			: std_logic_vector(31 downto 0);
	signal fsm_ready				: std_logic;
	signal fsm_ready_d				: std_logic;
begin
	write_done_d <= write_done when rising_edge(clk);
	write_done_edge <= to_sl(write_done = '1' and write_done_d = '0');

	icap_busy			<= not fsm_status_clk(3);
	icap_readback		<= fsm_status_clk(1);
	icap_partial_res	<= fsm_status_clk(0);

	fsm_ready <= fsm_status(3);
	fsm_ready_d <= fsm_ready when rising_edge(clk_icap);

	-- buffer some data before starting the icap, icap needs to be sync'ed before it can be paused
	in_data_buffer_p : process (clk_icap) begin
		if rising_edge(clk_icap) then
			if (reset_icap = '1') then
				in_data_start <= '0';
			else
				if fsm_ready = '1' and fsm_ready_d = '0' then	-- reset after icap is done
					in_data_start <= '0';
				elsif in_data_fill_state = state_almost_full or write_done_icapclk = '1' then	-- set when fifo almost full or write already done
					in_data_start <= '1';
				end if;
			end if;
		end if;
	end process in_data_buffer_p;

	in_data_rden <= icap_rden and in_data_start and in_data_valid;

	-- sync the written pci data into the user clk
	-- writer: pci
	-- reader: core
	fifo_in : entity poc.fifo_ic_got
		generic map(
			D_BITS			=> 32,
			MIN_DEPTH		=> MIN_DEPTH_IN,
			OUTPUT_REG		=> false,
			FSTATE_RD_BITS	=> STATE_BITS
		)
		port map(
			clk_wr 			=> clk,
			rst_wr 			=> reset,
			put    			=> write_put,
			din    			=> write_data,
			full   			=> write_full,
			estate_wr		=> open,

			clk_rd 			=> clk_icap,
			rst_rd 			=> reset_icap,
			got    			=> in_data_rden,
			valid  			=> in_data_valid,
			dout   			=> in_data,
			fstate_rd		=> in_data_fill_state
		);

	-- sync data from this core to the pci bus
	-- writer: core
	-- reader: pci
	fifo_out : entity poc.fifo_ic_got
		generic map(
			D_BITS			=> 32,
			MIN_DEPTH		=> MIN_DEPTH_OUT,
			OUTPUT_REG		=> false
		)
		port map(
			clk_wr 			=> clk_icap,
			rst_wr 			=> reset_icap,
			put    			=> out_data_put,
			din    			=> out_data,
			full   			=> out_data_full,

			clk_rd 			=> clk,
			rst_rd 			=> reset,
			got    			=> read_got,
			valid  			=> read_valid,
			dout   			=> read_data
		);

	icap_fsm_inst: entity poc.reconfig_icap_fsm port map(
		clk => clk_icap,
		reset => reset_icap,
		icap_in => icap_data_config_r,
		icap_out => icap_data_readback_r,
		icap_csb => icap_csb_r,
		icap_rw => icap_rw_r,
		in_data => in_data,
		in_data_valid => in_data_rden,		-- TODO start one clock cycle later
		in_data_rden => icap_rden,
		out_data => out_data,
		out_data_valid => out_data_put,
		out_data_full => out_data_full,
		status => fsm_status
	);

	-- icap
	icap_reg_p : process (clk_icap) begin
		if rising_edge(clk_icap) then
			icap_data_readback_r <= icap_data_readback;
			icap_csb <= icap_csb_r;
			icap_rw <= icap_rw_r;
			icap_data_config <= icap_data_config_r;
		end if;
	end process icap_reg_p;

	icap_inst : entity poc.xil_ICAP
	port map (
		clk			=> clk_icap,
		disable		=> icap_csb,
		busy		=> open,
		data_in		=> icap_data_config,
		data_out	=> icap_data_readback,
		rd_wr		=> icap_rw
	);

	strobe_sync : entity poc.sync_Strobe
	port map (
		clock1 => clk,
		clock2 => clk_icap,
		input(0) => write_done_edge,
		output(0) => write_done_icapclk,
		busy => open
	);

	reset_sync : entity poc.sync_Bits
	port map (
		clock => clk_icap,
		input(0) => reset,
		output(0) => reset_icap
	);

	fsm_status_sync : entity poc.sync_vector
	generic map (
		master_bits => 32
	) port map (
		clock1 => clk_icap,
		clock2 => clk,
		input => fsm_status,
		output => fsm_status_clk,
		busy => open,
		changed => open
	);


end Behavioral;
