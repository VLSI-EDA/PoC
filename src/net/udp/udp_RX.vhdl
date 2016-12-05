-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Entity:				 	TODO
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
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
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
use			PoC.net.all;


entity udp_RX is
	generic (
		DEBUG														: boolean						:= FALSE;
		IP_VERSION											: positive					:= 6
	);
	port (
		Clock														: in	std_logic;								--
		Reset														: in	std_logic;								--
		-- STATUS port
		Error														: out	std_logic;
		-- IN port
		In_Valid												: in	std_logic;
		In_Data													: in	T_SLV_8;
		In_SOF													: in	std_logic;
		In_EOF													: in	std_logic;
		In_Ack													: out	std_logic;
		In_Meta_rst											: out	std_logic;
		In_Meta_SrcMACAddress_nxt				: out	std_logic;
		In_Meta_SrcMACAddress_Data			: in	T_SLV_8;
		In_Meta_DestMACAddress_nxt			: out	std_logic;
		In_Meta_DestMACAddress_Data			: in	T_SLV_8;
		In_Meta_EthType									: in	T_SLV_16;
		In_Meta_SrcIPAddress_nxt				: out	std_logic;
		In_Meta_SrcIPAddress_Data				: in	T_SLV_8;
		In_Meta_DestIPAddress_nxt				: out	std_logic;
		In_Meta_DestIPAddress_Data			: in	T_SLV_8;
--		In_Meta_TrafficClass						: in	T_SLV_8;
--		In_Meta_FlowLabel								: in	T_SLV_24;
		In_Meta_Length									: in	T_SLV_16;
		In_Meta_Protocol								: in	T_SLV_8;
		-- OUT port
		Out_Valid												: out	std_logic;
		Out_Data												: out	T_SLV_8;
		Out_SOF													: out	std_logic;
		Out_EOF													: out	std_logic;
		Out_Ack													: in	std_logic;
		Out_Meta_rst										: in	std_logic;
		Out_Meta_SrcMACAddress_nxt			: in	std_logic;
		Out_Meta_SrcMACAddress_Data			: out	T_SLV_8;
		Out_Meta_DestMACAddress_nxt			: in	std_logic;
		Out_Meta_DestMACAddress_Data		: out	T_SLV_8;
		Out_Meta_EthType								: out	T_SLV_16;
		Out_Meta_SrcIPAddress_nxt				: in	std_logic;
		Out_Meta_SrcIPAddress_Data			: out	T_SLV_8;
		Out_Meta_DestIPAddress_nxt			: in	std_logic;
		Out_Meta_DestIPAddress_Data			: out	T_SLV_8;
--		Out_Meta_TrafficClass						: out	T_SLV_8;
--		Out_Meta_FlowLabel							: out	T_SLV_24;
		Out_Meta_Length									: out	T_SLV_16;
		Out_Meta_Protocol								: out	T_SLV_8;
		Out_Meta_SrcPort								: out	T_SLV_16;
		Out_Meta_DestPort								: out	T_SLV_16
	);
end entity;


-- Endianess: big-endian
-- Alignment: 1 byte
--
--								Byte 0													Byte 1														Byte 2													Byte 3
--	+================================+================================+================================+================================+
--	| SourcePort 							 																				| DestinationPort																									|
--	+--------------------------------+--------------------------------+--------------------------------+--------------------------------+
--	| PayloadLength																										| Checksum																												|
--	+================================+================================+================================+================================+
--	| Payload																																																														|
--	~                                ~                                ~                                ~                                ~
--	|																																																																		|
--	~                                ~                                ~                                ~                                ~
--	|																																																																		|
--	~                                ~                                ~                                ~                                ~
--	|																																																																		|
--	+================================+================================+================================+================================+


-- UDP pseudo header for IPv4
--
--								Byte 0													Byte 1														Byte 2													Byte 3
--	+================================+================================+================================+================================+
--	| SourceAddress 							 																																																			|
--	+--------------------------------+--------------------------------+--------------------------------+--------------------------------+
--	| DestinationAddress																																																								|
--	+--------------------------------+--------------------------------+--------------------------------+--------------------------------+
--	| 0x00 							 						 | Protocol												| Length																													|
--	+================================+================================+================================+================================+
--	| UDP header (see above)																																																						|
--	~                                ~                                ~                                ~                                ~
--	|																																																																		|
--	+================================+================================+================================+================================+
--	| Payload																																																														|
--	~                                ~                                ~                                ~                                ~
--	|																																																																		|
--	+================================+================================+================================+================================+


-- UDP pseudo header for IPv6
--
--								Byte 0													Byte 1														Byte 2													Byte 3
--	+================================+================================+================================+================================+
--	| SourceAddress 							 																																																			|
--	~                                ~                                ~                                ~                                ~
--	|																																																																		|
--	+--------------------------------+--------------------------------+--------------------------------+--------------------------------+
--	| DestinationAddress																																																								|
--	~                                ~                                ~                                ~                                ~
--	|																																																																		|
--	+--------------------------------+--------------------------------+--------------------------------+--------------------------------+
--	| Length																																																														|
--	+--------------------------------+--------------------------------+--------------------------------+--------------------------------+
--	| 0x000000																																												 | NextHeader											|
--	+================================+================================+================================+================================+
--	| UDP header (see above)																																																						|
--	~                                ~                                ~                                ~                                ~
--	|																																																																		|
--	+================================+================================+================================+================================+
--	| Payload																																																														|
--	~                                ~                                ~                                ~                                ~
--	|																																																																		|
--	+================================+================================+================================+================================+


architecture rtl of udp_RX is
	attribute FSM_ENCODING						: string;

	type T_STATE is (
		ST_IDLE,
			ST_RECEIVE_SOURCE_PORT_1,
			ST_RECEIVE_DEST_PORT_0,		ST_RECEIVE_DEST_PORT_1,
			ST_RECEIVE_LENGTH_0,			ST_RECEIVE_LENGTH_1,
			ST_RECEIVE_CHECKSUM_0,		ST_RECEIVE_CHECKSUM_1,
			ST_RECEIVE_DATA_1,				ST_RECEIVE_DATA_N,
		ST_DISCARD_FRAME,
		ST_ERROR
	);

	signal State													: T_STATE				:= ST_IDLE;
	signal NextState											: T_STATE;
	attribute FSM_ENCODING of State				: signal is ite(DEBUG, "gray", ite((VENDOR = VENDOR_XILINX), "auto", "default"));

	signal In_Ack_i											: std_logic;
	signal Is_DataFlow										: std_logic;
	signal Is_SOF													: std_logic;
	signal Is_EOF													: std_logic;

	signal Out_Valid_i										: std_logic;
	signal Out_SOF_i											: std_logic;
	signal Out_EOF_i											: std_logic;

	signal Register_rst										: std_logic;

	-- UDP header fields
	signal SourcePort_en0									: std_logic;
	signal SourcePort_en1									: std_logic;
	signal DestinationPort_en0						: std_logic;
	signal DestinationPort_en1						: std_logic;
	signal Length_en0											: std_logic;
	signal Length_en1											: std_logic;

	signal SourcePort_d										: T_SLV_16			:= (others => '0');
	signal DestinationPort_d							: T_SLV_16			:= (others => '0');
	signal Length_d												: T_SLV_16			:= (others => '0');

begin

	In_Ack				<= In_Ack_i;
	Is_DataFlow		<= In_Valid and In_Ack_i;
	Is_SOF				<= In_Valid and In_SOF;
	Is_EOF				<= In_Valid and In_EOF;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Reset = '1') then
				State			<= ST_IDLE;
			else
				State			<= NextState;
			end if;
		end if;
	end process;

	process(State, Is_DataFlow, Is_SOF, Is_EOF, In_Valid, In_Data, In_EOF, Out_Ack)
	begin
		NextState											<= State;
		Error													<= '0';

		In_Ack_i											<= '0';
		Out_Valid_i										<= '0';
		Out_SOF_i											<= '0';
		Out_EOF_i											<= '0';

		-- UDP header fields
		Register_rst									<= '0';
		SourcePort_en0								<= '0';
		SourcePort_en1								<= '0';
		DestinationPort_en0						<= '0';
		DestinationPort_en1						<= '0';
		Length_en0										<= '0';
		Length_en1										<= '0';

		case State is
			when ST_IDLE =>
				if (Is_SOF = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
						SourcePort_en0				<= '1';
						NextState							<= ST_RECEIVE_SOURCE_PORT_1;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_SOURCE_PORT_1 =>
				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
						SourcePort_en1				<= '1';
						NextState							<= ST_RECEIVE_DEST_PORT_0;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_DEST_PORT_0 =>
				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
						DestinationPort_en0		<= '1';
						NextState							<= ST_RECEIVE_DEST_PORT_1;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_DEST_PORT_1 =>
				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
						DestinationPort_en1		<= '1';
						NextState							<= ST_RECEIVE_LENGTH_0;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_LENGTH_0 =>
				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
						Length_en0						<= '1';
						NextState							<= ST_RECEIVE_LENGTH_1;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_LENGTH_1 =>
				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
						Length_en1						<= '1';
						NextState							<= ST_RECEIVE_CHECKSUM_0;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_CHECKSUM_0 =>
				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
						NextState							<= ST_RECEIVE_CHECKSUM_1;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_CHECKSUM_1 =>
				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
						NextState							<= ST_RECEIVE_DATA_1;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_DATA_1 =>
				In_Ack_i									<= Out_Ack;
				Out_Valid_i								<= In_Valid;
				Out_SOF_i									<= '1';
				Out_EOF_i									<= In_EOF;

				if (Is_DataFlow = '1') then
					if (Is_EOF = '0') then
						NextState							<= ST_RECEIVE_DATA_N;
					else
						NextState							<= ST_IDLE;
					end if;
				end if;

			when ST_RECEIVE_DATA_N =>
				In_Ack_i									<= Out_Ack;
				Out_Valid_i								<= In_Valid;
				Out_EOF_i									<= In_EOF;

				if (Is_EOF = '1') then
					NextState								<= ST_IDLE;
				end if;

			-- TODO: if no checksum is set in IPv6 mode
			when ST_DISCARD_FRAME =>
				In_Ack_i									<= '1';

				if (Is_EOF = '1') then
					NextState								<= ST_ERROR;
				end if;

			when ST_ERROR =>
				Error											<= '1';
				NextState									<= ST_IDLE;

		end case;
	end process;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if ((Reset or Register_rst) = '1') then
				SourcePort_d												<= (others => '0');
				DestinationPort_d										<= (others => '0');
				Length_d														<= (others => '0');
			else
				if (SourcePort_en0 = '1') then
					SourcePort_d(7 downto 0)					<= In_Data;
				end if;
				if (SourcePort_en1 = '1') then
					SourcePort_d(15 downto 8)					<= In_Data;
				end if;

				if (DestinationPort_en0 = '1') then
					DestinationPort_d(7 downto 0)			<= In_Data;
				end if;
				if (DestinationPort_en1 = '1') then
					DestinationPort_d(15 downto 8)		<= In_Data;
				end if;

				if (Length_en0 = '1') then
					Length_d(7 downto 0)							<= In_Data;
				end if;
				if (Length_en1 = '1') then
					Length_d(15 downto 8)							<= In_Data;
				end if;
			end if;
		end if;
	end process;

	In_Meta_rst												<= Out_Meta_rst;
	In_Meta_SrcMACAddress_nxt					<= Out_Meta_SrcMACAddress_nxt;
	In_Meta_DestMACAddress_nxt				<= Out_Meta_DestMACAddress_nxt;
	In_Meta_SrcIPAddress_nxt					<= Out_Meta_SrcIPAddress_nxt;
	In_Meta_DestIPAddress_nxt					<= Out_Meta_DestIPAddress_nxt;

	Out_Valid													<= Out_Valid_i;
	Out_Data													<= In_Data;
	Out_SOF														<= Out_SOF_i;
	Out_EOF														<= Out_EOF_i;
	Out_Meta_SrcMACAddress_Data				<= In_Meta_SrcMACAddress_Data;
	Out_Meta_DestMACAddress_Data			<= In_Meta_DestMACAddress_Data;
	Out_Meta_EthType									<= In_Meta_EthType;
	Out_Meta_SrcIPAddress_Data				<= In_Meta_SrcIPAddress_Data;
	Out_Meta_DestIPAddress_Data				<= In_Meta_DestIPAddress_Data;
--	Out_Meta_TrafficClass							<= In_Meta_TrafficClass;
--	Out_Meta_FlowLabel								<= In_Meta_FlowLabel;
	Out_Meta_Length										<= Length_d;
	Out_Meta_Protocol									<= In_Meta_Protocol;
	Out_Meta_SrcPort									<= SourcePort_d;
	Out_Meta_DestPort									<= DestinationPort_d;

end architecture;
