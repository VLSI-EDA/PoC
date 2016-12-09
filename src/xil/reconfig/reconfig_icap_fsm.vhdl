-- EMACS settings: -*-  tab-width: 4; indent-tabs-mode: t -*-
-- vim: tabstop=4:shiftwidth=4:noexpandtab
-- kate: tab-width 4; replace-tabs off; indent-width 4;
-- =============================================================================
-- Authors:					Paul Genssler
--
-- Entity:					ICAP FSM
--
-- Description:
-- -------------------------------------
-- This module parses the data stream to the Xilinx "Internal Configuration Access Port" (ICAP)
-- primitives to generate control signals. Tested on:
--
-- * Virtex-6
-- * Virtex-7
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
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library poc;
use POC.utils.all;
use POC.vectors.all;

entity reconfig_icap_fsm is
	port  (
		clk				: in	std_logic;
		reset			: in	std_logic;						-- high-active reset
		-- interface to connect to the icap
		icap_in			: out	std_logic_vector(31 downto 0);	-- data that will go into the icap
		icap_out		: in	std_logic_vector(31 downto 0);	-- data from the icap
		icap_csb		: out	std_logic;
		icap_rw			: out	std_logic;

		-- data interface, no internal fifos
		in_data			: in	std_logic_vector(31 downto 0);	-- new configuration data
		in_data_valid	: in	std_logic;						-- input data is valid
		in_data_rden	: out	std_logic;						-- possible to send data
		out_data		: out	std_logic_vector(31 downto 0);	-- data read from the fifo
		out_data_valid	: out	std_logic;						-- data from icap is valid
		out_data_full	: in	std_logic;						-- receiving buffer is full, halt icap

		-- control structures
		status			: out	std_logic_vector(31 downto 0)	-- status vector
	);
end reconfig_icap_fsm;

architecture arch of reconfig_icap_fsm is

	type t_state is (ready, abort0, abort1, abort2, abort3, write, writing, pre_reg_read0, pre_reg_read1, pre_stream_read0, read, reading, post_read);
	signal cur_state : t_state := ready;
	signal nxt_state : t_state := ready;

	-- detect the status of the synchronization
	type t_sync_state is (none, dummy0, bus_width0, bus_width1, dummy1, synced, cmdWrite, dsynced);
	signal sync_state : t_sync_state;
	-- flag will be (re)set in the clocking process for the main fsm
	signal sync_state_flag : boolean;

	constant sync_s_dummy	: std_logic_vector(31 downto 0) := x"FFFFFFFF";
	constant sync_s_bus_p_0	: std_logic_vector(31 downto 0) := x"000000BB";
	constant sync_s_bus_p_1	: std_logic_vector(31 downto 0) := x"11220044";
	constant sync_s_sync	: std_logic_vector(31 downto 0) := x"AA995566";
	constant sync_s_regW	: std_logic_vector(31 downto 0) := x"30008001";
	constant sync_s_dsync	: std_logic_vector(31 downto 0) := x"0000000D";

	constant cmd_nop		: std_logic_vector(31 downto 0) := x"20000000";

	-- commands for icap's cmd register
	constant cmd_reg_wcfg		: std_logic_vector(4 downto 0) := "00001";	-- write cfg data prior to write
	constant reg_fdro		: std_logic_vector(4 downto 0) := "00011";	-- read cfg data register

	signal icap_enable			: boolean := false;
	signal icap_read			: boolean := false;
	signal icap_in_r			: std_logic_vector(31 downto 0);
	-- icap bit switching
	signal in_data_swap			: std_logic_vector(31 downto 0);
	signal icap_out_swap		: std_logic_vector(31 downto 0);

	-- icap status word signals
	signal icap_error			: std_logic := '0';
	signal icap_sync			: std_logic := '0';
	signal icap_abort			: std_logic := '0';
	signal icap_status_valid	: std_logic := '0';

	signal readback_cnt			: unsigned(26 downto 0) := (others=>'0');
	signal readback_cnt_en		: boolean;
	signal readback_cnt_rst		: boolean := true;

	-- delayed signals
	signal in_data_valid_d		: std_logic;
	signal in_data_valid_re		: std_logic;	-- rising edge on in_data_valid signal

	-- status word signals
	signal pr_reset				: boolean := false;
	signal status_error			: boolean := false;
begin
	-- map icap_enable to the low-active csb
	icap_csb	<= to_sl(not icap_enable) when rising_edge(clk);
	icap_rw		<= to_sl(icap_read) when rising_edge(clk);

	-- drive icap data
	icap_in		<= icap_in_r when rising_edge(clk);
	icap_in_r	<= in_data_swap when in_data_valid = '1' else x"00000000";

	out_data	<= icap_out_swap when rising_edge(clk);

	-- TODO  detect errors
	status_error <= false;

	-- construct status word
	status(0) <= to_sl(pr_reset) when rising_edge(clk);
	status(1) <= to_sl(not readback_cnt_rst) when rising_edge(clk);		-- readback in progress
	status(2) <= to_sl(status_error) when rising_edge(clk);
	status(3) <= to_sl(cur_state = ready) when rising_edge(clk);
	status(31 downto 4) <= (others => '0');

	-- edge detection
	in_data_valid_d		<= in_data_valid when rising_edge(clk);
	in_data_valid_re	<= not in_data_valid_d and in_data_valid;

	-- combinatorial state machine
	cur_state <= nxt_state when rising_edge(clk);

	combi : process (reset, nxt_state, cur_state, in_data, in_data_valid, in_data_valid_re,
						sync_state, sync_state_flag, out_data_full, readback_cnt, pr_reset) begin
		-- default assignments
		nxt_state	<= cur_state;
		icap_enable <= false;
		icap_read	<= false;
		out_data_valid <= '0';
		in_data_rden <= '0';
		readback_cnt_rst <= true;
		readback_cnt_en <= false;
		-- TODO abort when error or reset
 		case cur_state is
			when ready =>
				in_data_rden <= '1';
				if in_data_valid_re = '1' then
					nxt_state <= write;
				end if;
			when write =>
				in_data_rden <= '1';
				if in_data_valid = '1' then
					nxt_state <= writing;
					icap_enable <= true;
				elsif sync_state_flag then
					nxt_state <= ready;
				end if;
			when writing =>
				in_data_rden <= '1';
				if in_data_valid = '0' then
					nxt_state <= write;
					icap_enable <= false;
				else
					icap_enable <= true;
					-- a type 1 package with a read op, after sync, but before pr_reset
					if in_data(31 downto 27) = "00101" and sync_state = synced and pr_reset = false then
						if in_data(17 downto 13) = reg_fdro then	-- FDRO read cfg register
							nxt_state <= pre_stream_read0;
						else
							nxt_state <= pre_reg_read0;
						end if;
					end if;
				end if;
			when pre_reg_read0 =>
				in_data_rden <= '1';
				readback_cnt_rst <= false;
				icap_enable <= true;
				if in_data /= cmd_nop then			-- after the nops are done, there should be 00000000 an the stream
					nxt_state <= pre_reg_read1;
					in_data_rden <= '0';
				end if;
			when pre_reg_read1 =>
				readback_cnt_rst <= false;
				icap_read <= true;
				if out_data_full = '0' then
					nxt_state <= reading;
				else
					nxt_state <= read;
				end if;
			when pre_stream_read0 =>	-- delay for one cycle to get the correct readback counter value
				in_data_rden <= '1';
				icap_enable <= true;
				nxt_state <= pre_reg_read0;
			when read =>
				readback_cnt_rst <= false;
				icap_read <= true;
				icap_enable <= false;
				if out_data_full = '0' then
					nxt_state <= reading;
				end if;
			when reading =>
				readback_cnt_rst <= false;
				readback_cnt_en <= true;
				icap_enable <= true;
				icap_read <= true;
				out_data_valid <= '1';
				if readback_cnt = 0 then
					nxt_state <= post_read;
				elsif out_data_full = '1' then
					nxt_state <= read;
				end if;
			when post_read =>
				in_data_rden <= '1';
				nxt_state <= write;
			when others =>

		end case;
	end process combi;

	-- readback counter process
	readback_cnt_p : process(clk)
	begin
		if rising_edge(clk) then
			if readback_cnt_rst then	-- load coutner with length from data word
				if in_data(31 downto 29) = "001" then		-- type 1 package
					readback_cnt(10 downto 0) <= unsigned(in_data(10 downto 0));	-- only 11 bit for count
					readback_cnt(26 downto 11) <= (others=>'0');
				else		-- type 2 package, 27 bit for count
					 readback_cnt <= unsigned(in_data(26 downto 0));
				end if;
			elsif readback_cnt_en then
				readback_cnt <= readback_cnt - 1;
			end if;
		end if;
	end process;


	-- update sync status
	sync_p : process(clk)
	begin
		if rising_edge(clk) then
			-- TODO consider status word's dsync bit
			if in_data_valid = '1' then
				case sync_state is
					when none =>
						pr_reset <= false;
						if cur_state = ready then
							sync_state_flag <= false;		-- reset flag after all data was passed to the icap
						end if;
						if in_data = sync_s_dummy then
							sync_state <= dummy0;
						end if;
					when dummy0 =>
						if in_data = sync_s_bus_p_0 then
							sync_state <= bus_width0;
						elsif in_data /= sync_s_dummy then
							sync_state <= none;
						end if;
					when bus_width0 =>
						if in_data = sync_s_bus_p_1 then
							sync_state <= bus_width1;
						else
							sync_state <= none;
						end if;
					when bus_width1 =>
						if in_data = sync_s_dummy then
							sync_state <= dummy1;
						else
							sync_state <= none;
						end if;
					when dummy1 =>
						if in_data = sync_s_sync then
							sync_state <= synced;
						elsif in_data /= sync_s_dummy then
							sync_state <= none;
						end if;
					when synced =>
						if in_data = sync_s_regW then
							sync_state <= cmdWrite;
						end if;
					when cmdWrite =>
						if in_data(4 downto 0) = cmd_reg_wcfg then	-- wcfg command, reconfig imminent
							pr_reset <= true;
						end if;
						if in_data = sync_s_dsync then
							sync_state <= dsynced;
						else
							sync_state <= synced;
						end if;
					when dsynced =>
						pr_reset <= false;
						sync_state <= none;
						sync_state_flag <= true;		-- set flag
				end case;
			end if;
		end if;
	end process;

	in_data_swap <= bit_swap(in_data, 8);
	icap_out_swap <= bit_swap(icap_out, 8);

end arch;

