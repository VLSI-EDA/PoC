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


entity FrameLoopback is
	generic (
		DATA_BW										: positive				:= 8;
		META_BW										: natural					:= 0
	);
	port (
		Clock											: in	std_logic;
		Reset											: in	std_logic;

		In_Valid									: in	std_logic;
		In_Data										: in	std_logic_vector(DATA_BW - 1 downto 0);
		In_Meta										: in	std_logic_vector(META_BW - 1 downto 0);
		In_SOF										: in	std_logic;
		In_EOF										: in	std_logic;
		In_Ack										: out	std_logic;


		Out_Valid									: out	std_logic;
		Out_Data									: out	std_logic_vector(DATA_BW - 1 downto 0);
		Out_Meta									: out	std_logic_vector(META_BW - 1 downto 0);
		Out_SOF										: out	std_logic;
		Out_EOF										: out	std_logic;
		Out_Ack										: in	std_logic
	);
end entity;


architecture rtl of FrameLoopback is
	constant META_STREAMID_SRC							: natural																						:= 0;
	constant META_STREAMID_DEST							: natural																						:= 1;
	constant META_STREAMID_type							: natural																						:= 2;
	constant META_STREAMS										: positive																					:= 3;		-- Source, Destination, Type

	signal Meta_rst													: std_logic;
	signal Meta_nxt													: std_logic_vector(META_STREAMS - 1 downto 0);

	signal Pipe_DataOut											: T_SLV_8;
	signal Pipe_MetaIn											: T_SLM(META_STREAMS - 1 downto 0, 31 downto 0)			:= (others => (others => 'Z'));
	signal Pipe_MetaOut											: T_SLM(META_STREAMS - 1 downto 0, 31 downto 0);
	signal Pipe_Meta_rst										: std_logic;
	signal Pipe_Meta_nxt										: std_logic_vector(META_STREAMS - 1 downto 0);

	signal Pipe_Meta_SrcMACAddress_Data			: std_logic_vector(TX_Funnel_SrcIPv6Address_Data'range);
	signal Pipe_Meta_DestMACAddress_Data		: std_logic_vector(TX_Funnel_DestIPv6Address_Data'range);
	signal Pipe_Meta_EthType								: std_logic_vector(TX_Funnel_Payload_Type'range);


begin
	assign_row(Pipe_MetaIn, TX_Meta_SrcIPv6Address_Data(I),		META_STREAMID_SRC,	0, '0');
	assign_row(Pipe_MetaIn, TX_Meta_DestIPv6Address_Data(I),	META_STREAMID_DEST, 0, '0');
	assign_row(Pipe_MetaIn, TX_Meta_Length(I),								META_STREAMID_LEN);

	TX_Meta_rst(I)									<= Meta_rst;
	TX_Meta_SrcIPv6Address_nxt(I)		<= Meta_nxt(META_STREAMID_SRC);
	TX_Meta_DestIPv6Address_nxt(I)	<= Meta_nxt(META_STREAMID_DEST);

	Pipe : entity PoC.stream_Buffer
		generic map (
			FRAMES												=> 2,
			DATA_BITS											=> 8,
			DATA_FIFO_DEPTH								=> 16,
			META_BITS											=> (META_STREAMID_SRC => 8,		META_STREAMID_DEST => 8,	META_STREAMID_LEN => 16),
			META_FIFO_DEPTH								=> (META_STREAMID_SRC => 16,	META_STREAMID_DEST => 16,	META_STREAMID_LEN => 1)
		)
		port map (
			Clock													=> Clock,
			Reset													=> Reset,

			In_Valid											=> TX_Valid(I),
			In_Data												=> TX_Data(I),
			In_SOF												=> TX_SOF(I),
			In_EOF												=> TX_EOF(I),
			In_Ack												=> TX_Ack	(I),
			In_Meta_rst										=> Meta_rst,
			In_Meta_nxt										=> Meta_nxt,
			In_Meta_Data									=> Pipe_MetaIn,

			Out_Valid											=> Funnel_In_Valid(I),
			Out_Data											=> Pipe_DataOut,
			Out_SOF												=> Funnel_In_SOF(I),
			Out_EOF												=> Funnel_In_EOF(I),
			Out_Ack												=> Funnel_In_Ack	(I),
			Out_Meta_rst									=> Pipe_Meta_rst,
			Out_Meta_nxt									=> Pipe_Meta_nxt,
			Out_Meta_Data									=> Pipe_MetaOut
		);

	-- unpack pipe metadata to signals
	Pipe_Meta_SrcIPv6Address_Data													<= get_row(Pipe_MetaOut, META_STREAMID_SRC,		8);
	Pipe_Meta_DestIPv6Address_Data												<= get_row(Pipe_MetaOut, META_STREAMID_DEST,	8);
	Pipe_Meta_Length																			<= get_row(Pipe_MetaOut, META_STREAMID_LEN);

	Pipe_Meta_rst																					<= Funnel_In_Meta_rev(I, META_RST_BIT);
	Pipe_Meta_nxt(META_STREAMID_SRC)											<= Funnel_In_Meta_rev(I, META_SRC_NXT_BIT);
	Pipe_Meta_nxt(META_STREAMID_DEST)											<= Funnel_In_Meta_rev(I, META_DEST_NXT_BIT);
	Pipe_Meta_nxt(META_STREAMID_LEN)											<= '0';

	-- pack metadata into 1 dim vector
	Funnel_MetaIn(Pipe_Meta_SrcIPv6Address_Data'range)		<= Pipe_Meta_SrcIPv6Address_Data;
	Funnel_MetaIn(Pipe_Meta_DestIPv6Address_Data'range)		<= Pipe_Meta_DestIPv6Address_Data;
	Funnel_MetaIn(Pipe_Meta_Length'range)									<= Pipe_Meta_Length;
	Funnel_MetaIn(Pipe_Meta_Payload_Type'range)						<= PACKET_typeS(I);

	-- assign vectors to matrix
	assign_row(Funnel_In_Data, Pipe_DataOut, I);
	assign_row(Funnel_In_Meta, Funnel_MetaIn, I);

end architecture;
