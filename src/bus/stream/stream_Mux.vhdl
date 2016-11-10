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


entity stream_Mux is
	generic (
		PORTS							: positive									:= 2;
		DATA_BITS					: positive									:= 8;
		META_BITS					: natural										:= 8;
		META_REV_BITS			: natural										:= 2--;
--		WEIGHTS						: T_INTVEC									:= (1, 1)
	);
	port (
		Clock							: in	std_logic;
		Reset							: in	std_logic;
		-- IN Ports
		In_Valid					: in	std_logic_vector(PORTS - 1 downto 0);
		In_Data						: in	T_SLM(PORTS - 1 downto 0, DATA_BITS - 1 downto 0);
		In_Meta						: in	T_SLM(PORTS - 1 downto 0, META_BITS - 1 downto 0);
		In_Meta_rev				: out	T_SLM(PORTS - 1 downto 0, META_REV_BITS - 1 downto 0);
		In_SOF						: in	std_logic_vector(PORTS - 1 downto 0);
		In_EOF						: in	std_logic_vector(PORTS - 1 downto 0);
		In_Ack						: out	std_logic_vector(PORTS - 1 downto 0);
		-- OUT Port
		Out_Valid					: out	std_logic;
		Out_Data					: out	std_logic_vector(DATA_BITS - 1 downto 0);
		Out_Meta					: out	std_logic_vector(META_BITS - 1 downto 0);
		Out_Meta_rev			: in	std_logic_vector(META_REV_BITS - 1 downto 0);
		Out_SOF						: out	std_logic;
		Out_EOF						: out	std_logic;
		Out_Ack						: in	std_logic
	);
end entity;


architecture rtl of stream_Mux is
	attribute KEEP										: boolean;
	attribute FSM_ENCODING						: string;

	subtype T_CHANNEL_INDEX is natural range 0 to PORTS - 1;

	type T_STATE is (ST_IDLE, ST_DATAFLOW);

	signal State											: T_STATE					:= ST_IDLE;
	signal NextState									: T_STATE;

	signal FSM_Dataflow_en						: std_logic;

	signal RequestVector							: std_logic_vector(PORTS - 1 downto 0);
	signal RequestWithSelf						: std_logic;
	signal RequestWithoutSelf					: std_logic;

	signal RequestLeft								: unsigned(PORTS - 1 downto 0);
	signal SelectLeft									: unsigned(PORTS - 1 downto 0);
	signal SelectRight								: unsigned(PORTS - 1 downto 0);

	signal ChannelPointer_en					: std_logic;
	signal ChannelPointer							: std_logic_vector(PORTS - 1 downto 0);
	signal ChannelPointer_d						: std_logic_vector(PORTS - 1 downto 0)						:= to_slv(2 ** (PORTS - 1), PORTS);
	signal ChannelPointer_nxt					: std_logic_vector(PORTS - 1 downto 0);
	signal ChannelPointer_bin					: unsigned(log2ceilnz(PORTS) - 1 downto 0);

	signal idx												: T_CHANNEL_INDEX;

	signal Out_EOF_i									: std_logic;

begin
	RequestVector				<= In_Valid and In_SOF;
	RequestWithSelf			<= slv_or(RequestVector);
	RequestWithoutSelf	<= slv_or(RequestVector and not ChannelPointer_d);

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

	process(State, RequestWithSelf, RequestWithoutSelf, Out_Ack, Out_EOF_i, ChannelPointer_d, ChannelPointer_nxt)
	begin
		NextState									<= State;

		FSM_Dataflow_en						<= '0';

		ChannelPointer_en					<= '0';
		ChannelPointer						<= ChannelPointer_d;

		case State is
			when ST_IDLE =>
				if (RequestWithSelf = '1') then
					ChannelPointer_en		<= '1';

					NextState						<= ST_DATAFLOW;
				end if;

			when ST_DATAFLOW =>
				FSM_Dataflow_en				<= '1';

				if ((Out_Ack and Out_EOF_i) = '1') then
					if (RequestWithoutSelf = '0') then
						NextState					<= ST_IDLE;
					else
						ChannelPointer_en	<= '1';
					end if;
				end if;
		end case;
	end process;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Reset = '1') then
				ChannelPointer_d			<= to_slv(2 ** (PORTS - 1), PORTS);
			elsif (ChannelPointer_en = '1') then
				ChannelPointer_d		<= ChannelPointer_nxt;
			end if;
		end if;
	end process;

	RequestLeft					<= (not ((unsigned(ChannelPointer_d) - 1) or unsigned(ChannelPointer_d))) and unsigned(RequestVector);
	SelectLeft					<= (unsigned(not RequestLeft) + 1)		and RequestLeft;
	SelectRight					<= (unsigned(not RequestVector) + 1)	and unsigned(RequestVector);
	ChannelPointer_nxt	<= std_logic_vector(ite((RequestLeft = (RequestLeft'range => '0')), SelectRight, SelectLeft));

	ChannelPointer_bin	<= onehot2bin(ChannelPointer);
	idx									<= to_integer(ChannelPointer_bin);

	Out_Data						<= get_row(In_Data, idx);
	Out_Meta						<= get_row(In_Meta, idx);

	Out_SOF							<= In_SOF(to_integer(ChannelPointer_bin));
	Out_EOF_i						<= In_EOF(to_integer(ChannelPointer_bin));
	Out_Valid						<= In_Valid(to_integer(ChannelPointer_bin)) and FSM_Dataflow_en;
	Out_EOF							<= Out_EOF_i;

	In_Ack							<= (In_Ack	'range => (Out_Ack	 and FSM_Dataflow_en)) and ChannelPointer;

	genMetaReverse_0 : if META_REV_BITS = 0 generate
		In_Meta_rev		<= (others => (others => '0'));
	end generate;
	genMetaReverse_1 : if META_REV_BITS > 0 generate
		signal Temp_Meta_rev : T_SLM(PORTS - 1 downto 0, META_REV_BITS - 1 downto 0)		:= (others => (others => 'Z'));
	begin
		genAssign : for i in 0 to PORTS - 1 generate
			signal row	: std_logic_vector(META_REV_BITS - 1 downto 0);
		begin
			row		<= Out_Meta_rev and (row'range => ChannelPointer(i));
			assign_row(Temp_Meta_rev, row, i);
		end generate;
		In_Meta_rev		<= Temp_Meta_rev;
	end generate;

end architecture;
