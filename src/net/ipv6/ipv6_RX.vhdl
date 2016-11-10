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


entity ipv6_RX is
	generic (
		DEBUG														: boolean							:= FALSE
	);
	port (
		Clock														: in	std_logic;									--
		Reset														: in	std_logic;									--
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
		Out_Meta_SrcIPv6Address_nxt			: in	std_logic;
		Out_Meta_SrcIPv6Address_Data		: out	T_SLV_8;
		Out_Meta_DestIPv6Address_nxt		: in	std_logic;
		Out_Meta_DestIPv6Address_Data		: out	T_SLV_8;
		Out_Meta_TrafficClass						: out	T_SLV_8;
		Out_Meta_FlowLabel							: out	T_SLV_24;	--STD_LOGIC_VECTOR(19 downto 0);
		Out_Meta_Length									: out	T_SLV_16;
		Out_Meta_NextHeader							: out	T_SLV_8
	);
end entity;


architecture rtl of ipv6_RX is
	attribute FSM_ENCODING						: string;

	subtype T_BYTEINDEX								is natural range 0 to 1;
	subtype T_IPV6_BYTEINDEX	 				is natural range 0 to 15;

	type T_STATE is (
		ST_IDLE,
			ST_RECEIVE_TRAFFIC_CLASS,
			ST_RECEIVE_FLOW_LABEL_1,	ST_RECEIVE_FLOW_LABEL_2,
			ST_RECEIVE_LENGTH_0,			ST_RECEIVE_LENGTH_1,
			ST_RECEIVE_NEXT_HEADER,		ST_RECEIVE_HOP_LIMIT,
			ST_RECEIVE_SOURCE_ADDRESS,
			ST_RECEIVE_DESTINATION_ADDRESS,

			ST_RECEIVE_DATA_1, ST_RECEIVE_DATA_N,
		ST_DISCARD_FRAME,
		ST_ERROR
	);

	signal State													: T_STATE											:= ST_IDLE;
	signal NextState											: T_STATE;
	attribute FSM_ENCODING of State				: signal is ite(DEBUG, "gray", ite((VENDOR = VENDOR_XILINX), "auto", "default"));

	signal In_Ack_i												: std_logic;
	signal Is_DataFlow										: std_logic;
	signal Is_SOF													: std_logic;
	signal Is_EOF													: std_logic;

	signal Out_Valid_i										: std_logic;
	signal Out_SOF_i											: std_logic;
	signal Out_EOF_i											: std_logic;

	subtype T_IP_BYTEINDEX								is natural range 0 to 15;
	signal IP_ByteIndex										: T_IP_BYTEINDEX;

	signal Register_rst										: std_logic;

	-- IPv6 basic header fields
	signal TrafficClass_en0								: std_logic;
	signal TrafficClass_en1								: std_logic;
	signal FlowLabel_en0									: std_logic;
	signal FlowLabel_en1									: std_logic;
	signal FlowLabel_en2									: std_logic;
	signal Length_en0											: std_logic;
	signal Length_en1											: std_logic;
	signal NextHeader_en									: std_logic;
	signal HopLimit_en										: std_logic;
	signal SourceIPv6Address_en						: std_logic;
	signal DestIPv6Address_en							: std_logic;

	signal TrafficClass_d									: T_SLV_8													:= (others => '0');
	signal FlowLabel_d										: std_logic_vector(19 downto 0)		:= (others => '0');
	signal Length_d												: T_SLV_16												:= (others => '0');
	signal NextHeader_d										: T_SLV_8													:= (others => '0');
	signal HopLimit_d											: T_SLV_8													:= (others => '0');
	signal SourceIPv6Address_d						: T_NET_IPV6_ADDRESS							:= (others => (others => '0'));
	signal DestIPv6Address_d							: T_NET_IPV6_ADDRESS							:= (others => (others => '0'));

	constant IPV6_ADDRESS_LENGTH					: positive												:= 16;			-- IPv6 -> 16 bytes
	constant IPV6_ADDRESS_READER_BITS			: positive												:= log2ceilnz(IPV6_ADDRESS_LENGTH);

	signal IPv6SeqCounter_rst							: std_logic;
	signal IPv6SeqCounter_en							: std_logic;
	signal IPv6SeqCounter_us							: unsigned(IPV6_ADDRESS_READER_BITS - 1 downto 0)		:= to_unsigned(IPV6_ADDRESS_LENGTH - 1, IPV6_ADDRESS_READER_BITS);

	signal SrcIPv6Address_Reader_rst			: std_logic;
	signal SrcIPv6Address_Reader_en				: std_logic;
	signal SrcIPv6Address_Reader_us				: unsigned(IPV6_ADDRESS_READER_BITS - 1 downto 0)		:= to_unsigned(IPV6_ADDRESS_LENGTH - 1, IPV6_ADDRESS_READER_BITS);
	signal DestIPv6Address_Reader_rst			: std_logic;
	signal DestIPv6Address_Reader_en			: std_logic;
	signal DestIPv6Address_Reader_us			: unsigned(IPV6_ADDRESS_READER_BITS - 1 downto 0)		:= to_unsigned(IPV6_ADDRESS_LENGTH - 1, IPV6_ADDRESS_READER_BITS);

	-- ExtensionHeader: Fragmentation
--	signal FragmentOffset_en0							: STD_LOGIC;
--	signal FragmentOffset_en1							: STD_LOGIC;

--	signal FragmentOffset_d								: STD_LOGIC_VECTOR(12 downto 0)		:= (others => '0');

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

	process(State, Is_DataFlow, Is_SOF, Is_EOF, In_Valid, In_Data, In_EOF, Out_Ack, IPv6SeqCounter_us)
	begin
		NextState									<= State;

		Error											<= '0';

		In_Ack_i								<= '0';
		Out_Valid_i								<= '0';
		Out_SOF_i									<= '0';
		Out_EOF_i									<= '0';

		-- IPv6 basic header fields
		Register_rst							<= '0';
		TrafficClass_en0					<= '0';
		TrafficClass_en1					<= '0';
		FlowLabel_en0							<= '0';
		FlowLabel_en1							<= '0';
		FlowLabel_en2							<= '0';
		Length_en0								<= '0';
		Length_en1								<= '0';
		NextHeader_en							<= '0';
		HopLimit_en								<= '0';
		SourceIPv6Address_en			<= '0';
		DestIPv6Address_en				<= '0';

		IPv6SeqCounter_rst				<= '0';
		IPv6SeqCounter_en					<= '0';

		-- ExtensionHeader: Fragmentation
--		FragmentOffset_en0				<= '0';
--		FragmentOffset_en1				<= '0';

		case State is
			when ST_IDLE =>
				if (Is_SOF = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
						if (In_Data(3 downto 0) = x"6") then
							TrafficClass_en0		<= '1';
							NextState						<= ST_RECEIVE_TRAFFIC_CLASS;
						else
							NextState						<= ST_DISCARD_FRAME;
						end if;
					else  -- EOF
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_TRAFFIC_CLASS =>
				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
						TrafficClass_en1			<= '1';
						FlowLabel_en0					<= '1';
						NextState							<= ST_RECEIVE_FLOW_LABEL_1;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_FLOW_LABEL_1 =>
				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
						FlowLabel_en1					<= '1';
						NextState							<= ST_RECEIVE_FLOW_LABEL_2;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_FLOW_LABEL_2 =>
				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
						FlowLabel_en2					<= '1';
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
						NextState							<= ST_RECEIVE_NEXT_HEADER;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_NEXT_HEADER =>
				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
						NextHeader_en					<= '1';
						NextState							<= ST_RECEIVE_HOP_LIMIT;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_HOP_LIMIT =>
				IPv6SeqCounter_rst				<= '1';

				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
						HopLimit_en						<= '1';
						NextState							<= ST_RECEIVE_SOURCE_ADDRESS;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_SOURCE_ADDRESS =>
				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					SourceIPv6Address_en		<= '1';
					IPv6SeqCounter_en				<= '1';

					if (Is_EOF = '0') then
						if (IPv6SeqCounter_us = 0) then
							IPv6SeqCounter_rst	<= '1';
							NextState						<= ST_RECEIVE_DESTINATION_ADDRESS;
						end if;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_DESTINATION_ADDRESS =>
				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					DestIPv6Address_en			<= '1';
					IPv6SeqCounter_en				<= '1';

					if (Is_EOF = '0') then
						if (IPv6SeqCounter_us = 0) then
							IPv6SeqCounter_rst	<= '1';
							NextState						<= ST_RECEIVE_DATA_1;
						end if;
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
				TrafficClass_d						<= (others => '0');
				FlowLabel_d								<= (others => '0');
				Length_d									<= (others => '0');
				NextHeader_d							<= (others => '0');
				HopLimit_d								<= (others => '0');
			else
				if (TrafficClass_en0 = '1') then
					TrafficClass_d(7 downto 4)			<= In_Data(7 downto 4);
				end if;
				if (TrafficClass_en1 = '1') then
					TrafficClass_d(3 downto 0)			<= In_Data(3 downto 0);
				end if;

				if (FlowLabel_en0 = '1') then
					FlowLabel_d(19 downto 16)				<= In_Data(7 downto 4);
				end if;
				if (FlowLabel_en1 = '1') then
					FlowLabel_d(15 downto 8)				<= In_Data;
				end if;
				if (FlowLabel_en2 = '1') then
					FlowLabel_d(7 downto 0)					<= In_Data;
				end if;

				if (Length_en0 = '1') then
					Length_d(15 downto 8)						<= In_Data;
				end if;
				if (Length_en1 = '1') then
					Length_d(7 downto 0)						<= In_Data;
				end if;

				if (NextHeader_en = '1') then
					NextHeader_d										<= In_Data;
				end if;

				if (HopLimit_en = '1') then
					HopLimit_d											<= In_Data;
				end if;

				if (SourceIPv6Address_en = '1') then
					SourceIPv6Address_d(to_integer(IPv6SeqCounter_us))	<= In_Data;
				end if;

				if (DestIPv6Address_en = '1') then
					DestIPv6Address_d(to_integer(IPv6SeqCounter_us))		<= In_Data;
				end if;
			end if;
		end if;
	end process;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if ((Reset or IPv6SeqCounter_rst) = '1') then
				IPv6SeqCounter_us			<= to_unsigned(IPV6_ADDRESS_LENGTH - 1, IPV6_ADDRESS_READER_BITS);
			elsif (IPv6SeqCounter_en = '1') then
				IPv6SeqCounter_us			<= IPv6SeqCounter_us - 1;
			end if;
		end if;
	end process;

	SrcIPv6Address_Reader_rst		<= Out_Meta_rst;
	SrcIPv6Address_Reader_en		<= Out_Meta_SrcIPv6Address_nxt;
	DestIPv6Address_Reader_rst	<= Out_Meta_rst;
	DestIPv6Address_Reader_en		<= Out_Meta_DestIPv6Address_nxt;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if ((Reset or SrcIPv6Address_Reader_rst) = '1') then
				SrcIPv6Address_Reader_us		<= to_unsigned(IPV6_ADDRESS_LENGTH - 1, IPV6_ADDRESS_READER_BITS);
			elsif (SrcIPv6Address_Reader_en = '1') then
				SrcIPv6Address_Reader_us		<= SrcIPv6Address_Reader_us - 1;
			end if;
		end if;
	end process;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if ((Reset or DestIPv6Address_Reader_rst) = '1') then
				DestIPv6Address_Reader_us		<= to_unsigned(IPV6_ADDRESS_LENGTH - 1, IPV6_ADDRESS_READER_BITS);
			elsif (DestIPv6Address_Reader_en = '1') then
				DestIPv6Address_Reader_us		<= DestIPv6Address_Reader_us - 1;
			end if;
		end if;
	end process;

	In_Meta_rst												<= 'X';		-- FIXME:
	In_Meta_SrcMACAddress_nxt					<= Out_Meta_SrcMACAddress_nxt;
	In_Meta_DestMACAddress_nxt				<= Out_Meta_DestMACAddress_nxt;

	Out_Valid													<= Out_Valid_i;
	Out_Data													<= In_Data;
	Out_SOF														<= Out_SOF_i;
	Out_EOF														<= Out_EOF_i;
	Out_Meta_SrcMACAddress_Data				<= In_Meta_SrcMACAddress_Data;
	Out_Meta_DestMACAddress_Data			<= In_Meta_DestMACAddress_Data;
	Out_Meta_EthType									<= In_Meta_EthType;
	Out_Meta_SrcIPv6Address_Data			<= SourceIPv6Address_d(to_integer(SrcIPv6Address_Reader_us));
	Out_Meta_DestIPv6Address_Data			<= DestIPv6Address_d(to_integer(DestIPv6Address_Reader_us));
	Out_Meta_TrafficClass							<= TrafficClass_d;
	Out_Meta_FlowLabel								<= "----" & FlowLabel_d;
	Out_Meta_Length										<= Length_d;
	Out_Meta_NextHeader								<= NextHeader_d;

end architecture;
