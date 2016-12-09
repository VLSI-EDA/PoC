-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Entity:				 	A generic buffer module for the PoC.Stream protocol.
--
-- Description:
-- -------------------------------------
-- .. TODO:: No documentation available.
--
-- License:
-- =============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany
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
-- WITHOUT WARRANTIES OR CONDITIONS of ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- =============================================================================

library IEEE;
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.NUMERIC_STD.all;

library PoC;
use			PoC.config.all;
use			PoC.utils.all;
use			PoC.vectors.all;


entity stream_DeMux is
	generic (
		PORTS							: positive									:= 2;
		DATA_BITS					: positive									:= 8;
		META_BITS					: natural										:= 8;
		META_REV_BITS			: natural										:= 2
	);
	port (
		Clock							: in	std_logic;
		Reset							: in	std_logic;
		-- Control interface
		DeMuxControl			: in	std_logic_vector(PORTS - 1 downto 0);
		-- IN Port
		In_Valid					: in	std_logic;
		In_Data						: in	std_logic_vector(DATA_BITS - 1 downto 0);
		In_Meta						: in	std_logic_vector(META_BITS - 1 downto 0);
		In_Meta_rev				: out	std_logic_vector(META_REV_BITS - 1 downto 0);
		In_SOF						: in	std_logic;
		In_EOF						: in	std_logic;
		In_Ack						: out	std_logic;
		-- OUT Ports
		Out_Valid					: out	std_logic_vector(PORTS - 1 downto 0);
		Out_Data					: out	T_SLM(PORTS - 1 downto 0, DATA_BITS - 1 downto 0);
		Out_Meta					: out	T_SLM(PORTS - 1 downto 0, META_BITS - 1 downto 0);
		Out_Meta_rev			: in	T_SLM(PORTS - 1 downto 0, META_REV_BITS - 1 downto 0);
		Out_SOF						: out	std_logic_vector(PORTS - 1 downto 0);
		Out_EOF						: out	std_logic_vector(PORTS - 1 downto 0);
		Out_Ack						: in	std_logic_vector(PORTS - 1 downto 0)
	);
end entity;


architecture rtl of stream_DeMux is
	attribute KEEP										: boolean;
	attribute FSM_ENCODING						: string;

	subtype T_CHANNEL_INDEX is natural range 0 to PORTS - 1;

	type T_STATE		is (ST_IDLE, ST_DATAFLOW, ST_DISCARD_FRAME);

	signal State								: T_STATE					:= ST_IDLE;
	signal NextState						: T_STATE;

	signal Is_SOF								: std_logic;
	signal Is_EOF								: std_logic;

	signal In_Ack_i							: std_logic;
	signal Out_Valid_i					: std_logic;
	signal DiscardFrame					: std_logic;

	signal ChannelPointer_rst		: std_logic;
	signal ChannelPointer_en		: std_logic;
	signal ChannelPointer				: std_logic_vector(PORTS - 1 downto 0);
	signal ChannelPointer_d			: std_logic_vector(PORTS - 1 downto 0)								:= (others => '0');

	signal ChannelPointer_bin		: unsigned(log2ceilnz(PORTS) - 1 downto 0);
	signal idx									: T_CHANNEL_INDEX;

	signal Out_Data_i						: T_SLM(PORTS - 1 downto 0, DATA_BITS - 1 downto 0)		:= (others => (others => 'Z'));		-- necessary default assignment 'Z' to get correct simulation results (iSIM, vSIM, ghdl/gtkwave)
	signal Out_Meta_i						: T_SLM(PORTS - 1 downto 0, META_BITS - 1 downto 0)		:= (others => (others => 'Z'));		-- necessary default assignment 'Z' to get correct simulation results (iSIM, vSIM, ghdl/gtkwave)
begin

	In_Ack_i			<= slv_or(Out_Ack	 and ChannelPointer);
	DiscardFrame	<= slv_nor(DeMuxControl);

	Is_SOF			<= In_Valid and In_SOF;
	Is_EOF			<= In_Valid and In_EOF;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Reset = '1') then
				State				<= ST_IDLE;
			else
				State				<= NextState;
			end if;
		end if;
	end process;

	process(State, In_Ack_i, In_Valid, Is_SOF, Is_EOF, DiscardFrame, DeMuxControl, ChannelPointer_d)
	begin
		NextState									<= State;

		ChannelPointer_rst				<= Is_EOF;
		ChannelPointer_en					<= '0';
		ChannelPointer						<= ChannelPointer_d;

		In_Ack										<= '0';
		Out_Valid_i								<= '0';

		case State is
			when ST_IDLE =>
				ChannelPointer					<= DeMuxControl;

				if (Is_SOF = '1') then
					if (DiscardFrame = '0') then
						ChannelPointer_en		<= '1';
						In_Ack							<= In_Ack_i;
						Out_Valid_i					<= '1';

						NextState						<= ST_DATAFLOW;
					else
						In_Ack							<= '1';

						NextState						<= ST_DISCARD_FRAME;
					end if;
				end if;

			when ST_DATAFLOW =>
				In_Ack									<= In_Ack_i;
				Out_Valid_i							<= In_Valid;
				ChannelPointer					<= ChannelPointer_d;

				if (Is_EOF = '1') then
					NextState							<= ST_IDLE;
				end if;

			when ST_DISCARD_FRAME =>
				In_Ack									<= '1';

				if (Is_EOF = '1') then
					NextState							<= ST_IDLE;
				end if;
		end case;
	end process;


	process(Clock)
	begin
		if rising_edge(Clock) then
			if ((Reset or ChannelPointer_rst) = '1') then
				ChannelPointer_d		<= (others => '0');
			elsif (ChannelPointer_en = '1') then
				ChannelPointer_d		<= DeMuxControl;
			end if;
		end if;
	end process;

	ChannelPointer_bin	<= onehot2bin(ChannelPointer_d);
	idx									<= to_integer(ChannelPointer_bin);

	In_Meta_rev					<= get_row(Out_Meta_rev, idx);

	genOutput : for i in 0 to PORTS - 1 generate
		Out_Valid(i)			<= Out_Valid_i and ChannelPointer(i);
		assign_row(Out_Data_i, In_Data, i);
		assign_row(Out_Meta_i, In_Meta, i);
		Out_SOF(i)				<= In_SOF;
		Out_EOF(i)				<= In_EOF;
	end generate;

	Out_Data		<= Out_Data_i;
	Out_Meta		<= Out_Meta_i;

end architecture;
