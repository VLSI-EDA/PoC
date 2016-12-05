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


entity udp_TX is
	generic (
		DEBUG												: boolean						:= FALSE;
		IP_VERSION									: positive					:= 6
	);
	port (
		Clock												: in	std_logic;									--
		Reset												: in	std_logic;									--
		-- IN port
		In_Valid										: in	std_logic;
		In_Data											: in	T_SLV_8;
		In_SOF											: in	std_logic;
		In_EOF											: in	std_logic;
		In_Ack											: out	std_logic;
		In_Meta_rst									: out	std_logic;
		In_Meta_SrcIPAddress_nxt		: out	std_logic;
		In_Meta_SrcIPAddress_Data		: in	T_SLV_8;
		In_Meta_DestIPAddress_nxt		: out	std_logic;
		In_Meta_DestIPAddress_Data	: in	T_SLV_8;
		In_Meta_SrcPort							: in	T_SLV_16;
		In_Meta_DestPort						: in	T_SLV_16;
		In_Meta_Length							: in	T_SLV_16;
		In_Meta_Checksum						: in	T_SLV_16;
		-- OUT port
		Out_Valid										: out	std_logic;
		Out_Data										: out	T_SLV_8;
		Out_SOF											: out	std_logic;
		Out_EOF											: out	std_logic;
		Out_Ack											: in	std_logic;
		Out_Meta_rst								: in	std_logic;
		Out_Meta_SrcIPAddress_nxt		: in	std_logic;
		Out_Meta_SrcIPAddress_Data	: out	T_SLV_8;
		Out_Meta_DestIPAddress_nxt	: in	std_logic;
		Out_Meta_DestIPAddress_Data	: out	T_SLV_8;
		Out_Meta_Length							: out	T_SLV_16
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

architecture rtl of udp_TX is
	attribute FSM_ENCODING						: string;

	type T_STATE is (
		ST_IDLE,
			ST_CHECKSUMV4_IPV4_ADDRESSES,
				ST_CHECKSUMV4_LENGTH_UDP_TYPE_0,	ST_CHECKSUMV4_LENGTH_UDP_TYPE_1,
				ST_CHECKSUMV4_PORT_NUMBER_0,			ST_CHECKSUMV4_PORT_NUMBER_1,
				ST_CHECKSUMV4_CHECKSUM_LENGTH_0,	ST_CHECKSUMV4_CHECKSUM_LENGTH_1,
			ST_CHECKSUMV6_IPV6_ADDRESSES,
				ST_CHECKSUMV6_LENGTH_UDP_TYPE_0,	ST_CHECKSUMV6_LENGTH_UDP_TYPE_1,
				ST_CHECKSUMV6_PORT_NUMBER_0,			ST_CHECKSUMV6_PORT_NUMBER_1,
				ST_CHECKSUMV6_CHECKSUM_LENGTH_0,	ST_CHECKSUMV6_CHECKSUM_LENGTH_1,
			ST_CARRY_0,  ST_CARRY_1,
			ST_SEND_SOURCE_PORT_0,
			ST_SEND_SOURCE_PORT_1,
			ST_SEND_DEST_PORT_0,	ST_SEND_DEST_PORT_1,
			ST_SEND_LENGTH_0,			ST_SEND_LENGTH_1,
			ST_SEND_CHECKSUM_0,		ST_SEND_CHECKSUM_1,
			ST_SEND_DATA,
		ST_ERROR
	);

	signal State											: T_STATE											:= ST_IDLE;
	signal NextState									: T_STATE;
	attribute FSM_ENCODING of State		: signal is ite(DEBUG, "gray", ite((VENDOR = VENDOR_XILINX), "auto", "default"));

	signal In_Ack_i										: std_logic;

	signal UpperLayerPacketLength			: std_logic_vector(15 downto 0);

	signal IPSeqCounter_rst						: std_logic;
	signal IPSeqCounter_en						: std_logic;
	signal IPSeqCounter_us						: unsigned(3 downto 0)									:= (others => '0');

	signal Checksum_rst								: std_logic;
	signal Checksum_en								: std_logic;
	signal Checksum_Addend0_us				: unsigned(T_SLV_8'range);
	signal Checksum_Addend1_us				: unsigned(T_SLV_8'range);
	signal Checksum0_nxt0_us					: unsigned(T_SLV_8'high + 1 downto 0);
	signal Checksum0_nxt1_us					: unsigned(T_SLV_8'high + 1 downto 0);
	signal Checksum0_d_us							: unsigned(T_SLV_8'high downto 0)				:= (others => '0');
	signal Checksum0_cy								: unsigned(T_SLV_2'range);
	signal Checksum1_nxt_us						: unsigned(T_SLV_8'range);
	signal Checksum1_d_us							: unsigned(T_SLV_8'range)								:= (others => '0');
	signal Checksum0_cy0							: std_logic;
	signal Checksum0_cy0_d						: std_logic															:= '0';
	signal Checksum0_cy1							: std_logic;
	signal Checksum0_cy1_d						: std_logic															:= '0';

	signal Checksum_i									: T_SLV_16;
	signal Checksum										: T_SLV_16;
	signal Checksum_mux_rst						: std_logic;
	signal Checksum_mux_set						: std_logic;
	signal Checksum_mux_r							: std_logic															:= '0';

begin
	assert ((IP_VERSION = 6) or (IP_VERSION = 4)) report "Internet Protocol Version not supported." severity ERROR;

	UpperLayerPacketLength		<= std_logic_vector(unsigned(In_Meta_Length) + 8);

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

	process(State,
					In_Valid, In_SOF, In_EOF, In_Data,
					Out_Ack, Out_Meta_rst,
					Out_Meta_SrcIPAddress_nxt,	In_Meta_SrcIPAddress_Data,
					Out_Meta_DestIPAddress_nxt, In_Meta_DestIPAddress_Data,
					In_Meta_SrcPort, In_Meta_DestPort, In_Meta_Checksum,
					IPSeqCounter_us, Checksum0_cy, Checksum,
					UpperLayerPacketLength)
	begin
		NextState										<= State;

		In_Ack_i										<= '0';

		Out_Valid										<= '0';
		Out_Data										<= In_Data;
		Out_SOF											<= '0';
		Out_EOF											<= '0';

		In_Meta_rst									<= '0';
		In_Meta_SrcIPAddress_nxt		<= Out_Meta_SrcIPAddress_nxt;
		In_Meta_DestIPAddress_nxt		<= Out_Meta_DestIPAddress_nxt;

		Out_Meta_SrcIPAddress_Data	<= In_Meta_SrcIPAddress_Data;
		Out_Meta_DestIPAddress_Data	<= In_Meta_DestIPAddress_Data;

		IPSeqCounter_rst						<= '0';
		IPSeqCounter_en							<= '0';

		Checksum_rst								<= '0';
		Checksum_en									<= '0';
		Checksum_Addend0_us					<= (others => '0');
		Checksum_Addend1_us					<= (others => '0');
		Checksum_mux_rst						<= '0';
		Checksum_mux_set						<= '0';

		case State is
			when ST_IDLE =>
				In_Meta_rst							<= '1';

				IPSeqCounter_rst				<= '1';
				Checksum_rst						<= '1';

				if ((In_Valid and In_SOF) = '1') then
					if (IP_VERSION = 4) then
						NextState						<= ST_CHECKSUMV4_IPV4_ADDRESSES;
					elsif (IP_VERSION = 6) then
						NextState						<= ST_CHECKSUMV6_IPV6_ADDRESSES;
					else
						NextState						<= ST_ERROR;
					end if;
				end if;

			-- calculate checksum for IPv4 pseudo header
			-- ----------------------------------------------------------------------
			when ST_CHECKSUMV4_IPV4_ADDRESSES =>
				In_Meta_SrcIPAddress_nxt	<= '1';
				In_Meta_DestIPAddress_nxt	<= '1';

				IPSeqCounter_en						<= '1';
				Checksum_en								<= '1';
				Checksum_Addend0_us				<= unsigned(In_Meta_SrcIPAddress_Data);
				Checksum_Addend1_us				<= unsigned(In_Meta_DestIPAddress_Data);

				if (IPSeqCounter_us = 3) then
					NextState								<= ST_CHECKSUMV4_LENGTH_UDP_TYPE_0;
				end if;

			when ST_CHECKSUMV4_LENGTH_UDP_TYPE_0 =>
				Checksum_en								<= '1';
				Checksum_Addend0_us				<= unsigned(UpperLayerPacketLength(15 downto 8));
				Checksum_Addend1_us				<= (others => '0');

				NextState									<= ST_CHECKSUMV4_LENGTH_UDP_TYPE_1;

			when ST_CHECKSUMV4_LENGTH_UDP_TYPE_1 =>
				Checksum_en								<= '1';
				Checksum_Addend0_us				<= unsigned(UpperLayerPacketLength(7 downto 0));
				Checksum_Addend1_us				<= unsigned(C_NET_IP_PROTOCOL_UDP);

				NextState									<= ST_CHECKSUMV4_PORT_NUMBER_0;

			when ST_CHECKSUMV4_PORT_NUMBER_0 =>
				Checksum_en								<= '1';
				Checksum_Addend0_us				<= unsigned(In_Meta_SrcPort(15 downto 8));
				Checksum_Addend1_us				<= unsigned(In_Meta_DestPort(15 downto 8));

				NextState									<= ST_CHECKSUMV4_PORT_NUMBER_1;

			when ST_CHECKSUMV4_PORT_NUMBER_1 =>
				Checksum_en								<= '1';
				Checksum_Addend0_us				<= unsigned(In_Meta_SrcPort(7 downto 0));
				Checksum_Addend1_us				<= unsigned(In_Meta_DestPort(7 downto 0));

				NextState									<= ST_CHECKSUMV4_CHECKSUM_LENGTH_0;

			when ST_CHECKSUMV4_CHECKSUM_LENGTH_0 =>
				Checksum_en								<= '1';
				Checksum_Addend0_us				<= unsigned(UpperLayerPacketLength(15 downto 8));
				Checksum_Addend1_us				<= unsigned(In_Meta_Checksum(15 downto 8));

				NextState									<= ST_CHECKSUMV4_CHECKSUM_LENGTH_1;

			when ST_CHECKSUMV4_CHECKSUM_LENGTH_1 =>
				Checksum_en								<= '1';
				Checksum_Addend0_us				<= unsigned(UpperLayerPacketLength(7 downto 0));
				Checksum_Addend1_us				<= unsigned(In_Meta_Checksum(7 downto 0));

				if (Checksum0_cy = "00") then
					NextState								<= ST_SEND_SOURCE_PORT_0;
				else
					NextState								<= ST_CARRY_0;
				end if;

			-- calculate checksum for IPv6 pseudo header
			-- ----------------------------------------------------------------------
			when ST_CHECKSUMV6_IPV6_ADDRESSES =>
				In_Meta_SrcIPAddress_nxt	<= '1';
				In_Meta_DestIPAddress_nxt	<= '1';

				IPSeqCounter_en						<= '1';
				Checksum_en								<= '1';
				Checksum_Addend0_us				<= unsigned(In_Meta_SrcIPAddress_Data);
				Checksum_Addend1_us				<= unsigned(In_Meta_DestIPAddress_Data);

				if (IPSeqCounter_us = 15) then
					NextState								<= ST_CHECKSUMV6_LENGTH_UDP_TYPE_0;
				end if;

			when ST_CHECKSUMV6_LENGTH_UDP_TYPE_0 =>
				Checksum_en								<= '1';
				Checksum_Addend0_us				<= unsigned(UpperLayerPacketLength(15 downto 8));
				Checksum_Addend1_us				<= (others => '0');

				NextState									<= ST_CHECKSUMV6_LENGTH_UDP_TYPE_1;

			when ST_CHECKSUMV6_LENGTH_UDP_TYPE_1 =>
				Checksum_en								<= '1';
				Checksum_Addend0_us				<= unsigned(UpperLayerPacketLength(7 downto 0));
				Checksum_Addend1_us				<= unsigned(C_NET_IP_PROTOCOL_UDP);

				NextState									<= ST_CHECKSUMV6_PORT_NUMBER_0;

			when ST_CHECKSUMV6_PORT_NUMBER_0 =>
				Checksum_en								<= '1';
				Checksum_Addend0_us				<= unsigned(In_Meta_SrcPort(15 downto 8));
				Checksum_Addend1_us				<= unsigned(In_Meta_DestPort(15 downto 8));

				NextState									<= ST_CHECKSUMV6_PORT_NUMBER_1;

			when ST_CHECKSUMV6_PORT_NUMBER_1 =>
				Checksum_en								<= '1';
				Checksum_Addend0_us				<= unsigned(In_Meta_SrcPort(7 downto 0));
				Checksum_Addend1_us				<= unsigned(In_Meta_DestPort(7 downto 0));

				NextState									<= ST_CHECKSUMV6_CHECKSUM_LENGTH_0;

			when ST_CHECKSUMV6_CHECKSUM_LENGTH_0 =>
				Checksum_en								<= '1';
				Checksum_Addend0_us				<= unsigned(UpperLayerPacketLength(15 downto 8));
				Checksum_Addend1_us				<= unsigned(In_Meta_Checksum(15 downto 8));

				NextState									<= ST_CHECKSUMV6_CHECKSUM_LENGTH_1;

			when ST_CHECKSUMV6_CHECKSUM_LENGTH_1 =>
				Checksum_en								<= '1';
				Checksum_Addend0_us				<= unsigned(UpperLayerPacketLength(7 downto 0));
				Checksum_Addend1_us				<= unsigned(In_Meta_Checksum(7 downto 0));

				if (Checksum0_cy = "00") then
					NextState								<= ST_SEND_SOURCE_PORT_0;
				else
					NextState								<= ST_CARRY_0;
				end if;

			-- circulate carry bit
			-- ----------------------------------------------------------------------
			when ST_CARRY_0 =>
				In_Meta_rst								<= Out_Meta_rst;

				Checksum_en								<= '1';
				Checksum_mux_set					<= '1';

				if (Checksum0_cy = "00") then
					NextState								<= ST_SEND_SOURCE_PORT_0;
				else
					NextState								<= ST_CARRY_1;
				end if;

			when ST_CARRY_1 =>
				In_Meta_rst								<= Out_Meta_rst;

				Checksum_en								<= '1';
				Checksum_mux_rst					<= '1';

				NextState									<= ST_SEND_SOURCE_PORT_0;

			-- assamble header
			-- ----------------------------------------------------------------------
			when ST_SEND_SOURCE_PORT_0 =>
				Out_Valid									<= '1';
				Out_Data									<= In_Meta_SrcPort(15 downto 8);
				Out_SOF										<= '1';

				In_Meta_rst								<= Out_Meta_rst;

				if (Out_Ack	 = '1') then
					NextState								<= ST_SEND_SOURCE_PORT_1;
				end if;

			when ST_SEND_SOURCE_PORT_1 =>
				Out_Valid									<= '1';
				Out_Data									<= In_Meta_SrcPort(7 downto 0);

				if (Out_Ack	 = '1') then
					NextState								<= ST_SEND_DEST_PORT_0;
				end if;

			when ST_SEND_DEST_PORT_0 =>
				Out_Valid									<= '1';
				Out_Data									<= In_Meta_DestPort(15 downto 8);

				if (Out_Ack	 = '1') then
					NextState								<= ST_SEND_DEST_PORT_1;
				end if;

			when ST_SEND_DEST_PORT_1 =>
				Out_Valid									<= '1';
				Out_Data									<= In_Meta_DestPort(7 downto 0);

				if (Out_Ack	 = '1') then
					NextState								<= ST_SEND_LENGTH_0;
				end if;

			when ST_SEND_LENGTH_0 =>
				Out_Valid									<= '1';
				Out_Data									<= UpperLayerPacketLength(15 downto 8);

				if (Out_Ack	 = '1') then
					NextState								<= ST_SEND_LENGTH_1;
				end if;

			when ST_SEND_LENGTH_1 =>
				Out_Valid									<= '1';
				Out_Data									<= UpperLayerPacketLength(7 downto 0);

				if (Out_Ack	 = '1') then
					NextState								<= ST_SEND_CHECKSUM_0;
				end if;

			when ST_SEND_CHECKSUM_0 =>
				Out_Valid									<= '1';
				Out_Data									<= Checksum(15 downto 8);

				if (Out_Ack	 = '1') then
					NextState								<= ST_SEND_CHECKSUM_1;
				end if;

			when ST_SEND_CHECKSUM_1 =>
				Out_Valid									<= '1';
				Out_Data									<= Checksum(7 downto 0);

				if (Out_Ack	 = '1') then
					NextState								<= ST_SEND_DATA;
				end if;

			when ST_SEND_DATA =>
				Out_Valid									<= In_Valid;
				Out_Data									<= In_Data;
				Out_EOF										<= In_EOF;
				In_Ack_i									<= Out_Ack;

				if ((In_EOF and Out_Ack) = '1') then
					NextState								<= ST_IDLE;
				end if;

			when ST_ERROR =>
				null;

		end case;
	end process;

	-- IPSeqCounter
	process(Clock)
	begin
		if rising_edge(Clock) then
			if ((Reset or IPSeqCounter_rst) = '1') then
				IPSeqCounter_us			<= to_unsigned(0, IPSeqCounter_us'length);
			elsif (IPSeqCounter_en = '1') then
				IPSeqCounter_us			<= IPSeqCounter_us + 1;
			end if;
		end if;
	end process;

	Checksum0_nxt0_us		<= ("0" & Checksum1_d_us)
													+ ("0" & Checksum_Addend0_us)
													+ ((Checksum_Addend0_us'range => '0') & Checksum0_cy0_d);
	Checksum0_nxt1_us		<= ("0" & Checksum0_nxt0_us(Checksum0_nxt0_us'high - 1 downto 0))
													+ ("0" & Checksum_Addend1_us)
													+ ((Checksum_Addend1_us'range => '0') & Checksum0_cy1_d);
	Checksum1_nxt_us		<= Checksum0_d_us(Checksum1_d_us'range);

	Checksum0_cy0				<= Checksum0_nxt0_us(Checksum0_nxt0_us'high);
	Checksum0_cy1				<= Checksum0_nxt1_us(Checksum0_nxt1_us'high);
	Checksum0_cy				<= Checksum0_cy1 & Checksum0_cy0;


	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Checksum_rst = '1') then
				Checksum0_d_us		<= (others => '0');
				Checksum1_d_us		<= (others => '0');
			elsif (Checksum_en = '1') then
				Checksum0_d_us		<= Checksum0_nxt1_us(Checksum0_nxt1_us'high - 1 downto 0);
				Checksum1_d_us		<= Checksum1_nxt_us;

				Checksum0_cy0_d		<= Checksum0_cy0;
				Checksum0_cy1_d		<= Checksum0_cy1;
			end if;
		end if;
	end process;

	Checksum_i		<= not (std_logic_vector(Checksum0_nxt1_us(Checksum0_nxt1_us'high - 1 downto 0)) & std_logic_vector(Checksum1_nxt_us));
	Checksum			<= ite((Checksum_mux_r = '0'), Checksum_i, swap(Checksum_i, 8));

	process(Clock)
	begin
		if rising_edge(Clock) then
			if ((Reset or Checksum_mux_rst) = '1') then
				Checksum_mux_r		<= '0';
			elsif (Checksum_mux_set = '1') then
				Checksum_mux_r		<= '1';
			end if;
		end if;
	end process;

	In_Ack						<= In_Ack_i;
	Out_Meta_Length		<= UpperLayerPacketLength;

end architecture;
