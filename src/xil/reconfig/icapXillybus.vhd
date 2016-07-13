-- EMACS settings: -*-  tab-width: 4; indent-tabs-mode: t -*-
-- vim: tabstop=4:shiftwidth=4:noexpandtab
-- kate: tab-width 4; replace-tabs off; indent-width 4;
-- =============================================================================
-- Authors:					Paul Genssler
--
-- Entity:					ICAP Xillybus Controller
--
-- Description:
-- -------------------------------------
-- This module was designed to connect the Xilinx "Internal Configuration Access Port" (ICAP)
-- to a Xillybus endpoint. Tested on:
--
-- * Virtex-6
-- * Virtex-7
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany,
--										 Chair for VLSI-Design, Diagnostics and Architecture
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
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.vcomponents.all;

library poc;
use poc.utils.all;


entity icap_xillybus is
	generic (
		MIN_DEPTH_OUT     : positive := 256;
		MIN_DEPTH_IN      : positive := 256
	);
	port (
		data_clk 		: in	std_logic;
		icap_clk 		: in	std_logic;
		
		icap_res		: in	std_logic;
		data_res		: in	std_logic;
				
		-- used to reset the newly configured design, icap clock
		partial_reset	: out	std_logic;
		
		---- external clock ---- 
		-- FIFO in
		write_wren		: in	std_logic;
		write_full		: out	std_logic;
		write_data		: in	std_logic_vector(D_BITS-1 DOWNTO 0);
		write_open		: in	std_logic;
		
		-- FIFO out
		read_rden		: in		std_logic;
		read_empty 		: buffer	std_logic;
		read_data 		: out		std_logic_vector(D_BITS-1 DOWNTO 0);
		read_eof 		: buffer	std_logic;
		read_open 		: in		std_logic
	);
end icap_xillybus;

architecture Behavioral of icap_xillybus is

	signal reset					: std_logic;
	signal read_valid				: std_logic;

	signal in_data_opened			: std_logic;
	signal in_data_open				: std_logic;
	signal in_data_open_r			: std_logic;
	
	signal byte_swap				: std_logic;
	
	signal in_data_valid			: std_logic;
	constant STATE_BITS 			: positive := 2;
	constant state_bit_ones			: std_logic_vector(STATE_BITS -1 downto 0) := (others=>'1');
	signal in_data_almost_full		: std_logic_vector(STATE_BITS -1 downto 0);
	signal in_data_rden				: std_logic;
	signal in_data_rden_state		: std_logic;		-- high after enough data was written into the pci->icap fifo
	signal icap_rden				: std_logic;		-- icap wants some yummy data
	-- output of the fifo
	signal in_data_raw				: std_logic_vector(31 downto 0);
	-- maybe swapped bytes, depends on the byte_swap bit
	signal in_data					: std_logic_vector(31 downto 0);
	
	signal out_data_eof				: std_logic;
	signal out_data_full			: std_logic;
	signal out_data_wren			: std_logic;
	signal out_data					: std_logic_vector(31 downto 0);
	signal out_data_raw				: std_logic_vector(31 downto 0);
	
	signal icap_data_config			: std_logic_vector(31 downto 0);
	signal icap_data_readback		: std_logic_vector(31 downto 0);
	signal icap_csb					: std_logic;
	signal icap_rw					: std_logic;
	
	signal icap_data_config_r		: std_logic_vector(31 downto 0);
	signal icap_data_readback_r		: std_logic_vector(31 downto 0);
	signal icap_csb_r				: std_logic;
	signal icap_rw_r				: std_logic;
	
	signal fsm_status				: std_logic_vector(31 downto 0);
	signal fsm_idle					: std_logic := '0';	
begin
	reset <= icap_res;
	-- TODO assign the config from the register
	byte_swap <= '1';
	
	partial_reset <= fsm_status(0);
	
	icap_fsm_inst: entity work.icap_fsm PORT MAP(
		clk => icap_clk,
		reset => reset,
		icap_in => icap_data_config_r,
		icap_out => icap_data_readback_r,
		icap_csb => icap_csb_r,
		icap_rw => icap_rw_r,
		in_data => in_data,
		in_data_valid => in_data_valid,
		in_data_rden => icap_rden,
		out_data => out_data,
		out_data_valid => out_data_wren,
		out_data_full => out_data_full,
		status => fsm_status
	);

	-- buffer some data before starting the icap, icap needs to be sync'ed before it can be paused
	in_data_buffer_p : process (icap_clk) begin
		if (rising_edge(icap_clk)) then
			if (reset = '1') then
				in_data_rden_state <= '0';
			else
				if in_data_opened = '1' then	-- reset after new file was opend
					in_data_rden_state <= '0';
				else
					-- icap has to be always ready to take data
					-- if it is, keep getting data, or start if the pci->icap fifo is almost full or the file was closed (small bitstream)
					in_data_rden_state <= to_sl(in_data_rden_state = '1' or in_data_almost_full = state_bit_ones or in_data_open = '0'); 
				end if;
			end if;
		end if;	
	end process in_data_buffer_p;
	
	-- swap data bytes (pci = little endian; icap = big endian)
	byte_swapper_i : entity work.byteSwap
	port map(
		enable => byte_swap,
		i => in_data_raw,
		o => in_data
	);
	byte_swapper_o : entity work.byteSwap
	port map(
		enable => byte_swap,
		i => out_data,
		o => out_data_raw
	);
	
	-- sync the written pci data into the user clk
	-- writer: pci
	-- reader: core
	fifo_in : ENTITY poc.fifo_ic_got
		generic map(
			D_BITS			=> D_BITS,
			MIN_DEPTH		=> MIN_DEPTH_IN,
			OUTPUT_REG		=> false,
			FSTATE_RD_BITS	=> STATE_BITS
		)
		port map(
			clk_wr 			=> data_clk,
			rst_wr 			=> data_res,
			put    			=> write_wren,
			din    			=> write_data,
			full   			=> write_full,
			estate_wr		=> open,

			clk_rd 			=> icap_clk,
			rst_rd 			=> icap_res,
			got    			=> in_data_rden,
			valid  			=> in_data_valid,
			dout   			=> in_data_raw,
			fstate_rd		=> in_data_almost_full
		);
		
	in_data_rden <= icap_rden and in_data_rden_state;
	
	-- sync data from this core to the pci bus
	-- writer: core
	-- reader: pci
	fifo_out : ENTITY poc.fifo_ic_got
		generic map(
			D_BITS			=> D_BITS,
			MIN_DEPTH		=> MIN_DEPTH_OUT,
			OUTPUT_REG		=> false
		)
		port map(
			clk_wr 			=> icap_clk,
			rst_wr 			=> icap_res,
			put    			=> out_data_wren,
			din    			=> out_data_raw,
			full   			=> out_data_full,

			clk_rd 			=> data_clk,
			rst_rd 			=> data_res,
			got    			=> read_rden,
			valid  			=> read_valid,
			dout   			=> read_data
		);
		
	read_empty <= not read_valid;
	-- eof if reset or readback is done and data is empty
	out_data_eof <= read_empty and fsm_idle when rising_edge(data_clk);
	read_eof <= icap_res or (not out_data_eof and (read_empty and fsm_idle));
	
	-- sync the write open flag into the icap clk
	sync_write_open : entity poc.sync_Bits
		generic map(
			BITS    => 1, 
			INIT    => "0"
		)
		port map(
			Clock		=> icap_clk, 
			Input(0)	=> write_open, 
			Output(0)	=> in_data_open
	);	

	-- sync the fsm_idle single into the data clk
	sync_fsm_idle : entity poc.sync_Bits
		generic map(
			BITS    => 1, 
			INIT    => "0"
		)
		port map(
			Clock		=> data_clk, 
			Input(0)	=> fsm_status(3), 
			Output(0)	=> fsm_idle
	);	
	
	-- detect a pci file opening
	in_data_open_r <= in_data_open when rising_edge(icap_clk);
	in_data_opened <= (not in_data_open_r) and in_data_open;
	in_data_closed <= in_data_open_r and (not in_data_open);
	
	-- icap
	icap_reg_p : process (icap_clk) begin
		if rising_edge(icap_clk) then
			icap_data_readback_r <= icap_data_readback;
			icap_csb <= icap_csb_r;
			icap_rw <= icap_rw_r;
			icap_data_config <= icap_data_config_r;
		end if;
	end process icap_reg_p;
	
	icap_inst : icap
	port map (
		clk			=> icap_clk,
		disable		=> icap_csb,
		busy		=> open,
		data_in		=> icap_data_config,
		data_out	=> icap_data_readback,
		rd_wr		=> icap_rw
	);
end Behavioral;
