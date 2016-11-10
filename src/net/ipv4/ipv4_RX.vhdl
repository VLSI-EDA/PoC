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


entity ipv4_RX is
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
		Out_Meta_SrcIPv4Address_nxt			: in	std_logic;
		Out_Meta_SrcIPv4Address_Data		: out	T_SLV_8;
		Out_Meta_DestIPv4Address_nxt		: in	std_logic;
		Out_Meta_DestIPv4Address_Data		: out	T_SLV_8;
		Out_Meta_Length									: out	T_SLV_16;
		Out_Meta_Protocol								: out	T_SLV_8
	);
end entity;


architecture rtl of ipv4_RX is
	attribute FSM_ENCODING						: string;

	type T_STATE is (
		ST_IDLE,
																		ST_RECEIVE_TYPE_OF_SERVICE,		ST_RECEIVE_TOTAL_LENGTH_0,		ST_RECEIVE_TOTAL_LENGTH_1,
			ST_RECEIVE_IDENTIFICATION_0,	ST_RECEIVE_IDENTIFICATION_1,	ST_RECEIVE_FLAGS,							ST_RECEIVE_FRAGMENT_OFFSET_1,
			ST_RECEIVE_TIME_TO_LIVE,			ST_RECEIVE_PROTOCOL,					ST_RECEIVE_HEADER_CHECKSUM_0,	ST_RECEIVE_HEADER_CHECKSUM_1,
			ST_RECEIVE_SOURCE_ADDRESS,
			ST_RECEIVE_DESTINATION_ADDRESS,
--			ST_RECEIVE_OPTIONS,
			ST_RECEIVE_DATA_1,						ST_RECEIVE_DATA_N,
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

	subtype T_IPV4_BYTEINDEX	 						is natural range 0 to 3;
	signal IP_ByteIndex										: T_IPV4_BYTEINDEX;

	signal Register_rst										: std_logic;

	-- IPv4 Basic Header
	signal HeaderLength_en								: std_logic;
	signal TypeOfService_en								: std_logic;
	signal TotalLength_en0								: std_logic;
	signal TotalLength_en1								: std_logic;
--	signal Identification_en0							: STD_LOGIC;
--	signal Identification_en1							: STD_LOGIC;
	signal Flags_en												: std_logic;
--	signal FragmentOffset_en0							: STD_LOGIC;
--	signal FragmentOffset_en1							: STD_LOGIC;
	signal TimeToLive_en									: std_logic;
	signal Protocol_en										: std_logic;
	signal HeaderChecksum_en0							: std_logic;
	signal HeaderChecksum_en1							: std_logic;
	signal SourceIPv4Address_en						: std_logic;
	signal DestIPv4Address_en							: std_logic;

	signal HeaderLength_d									: T_SLV_4													:= (others => '0');
	signal TypeOfService_d								: T_SLV_8													:= (others => '0');
	signal TotalLength_d									: T_SLV_16												:= (others => '0');
--	signal Identification_d								: T_SLV_16												:= (others => '0');
	signal Flag_DontFragment_d						: std_logic												:= '0';
	signal Flag_MoreFragmenta_d						: std_logic												:= '0';
--	signal FragmentOffset_d								: STD_LOGIC_VECTOR(12 downto 0)		:= (others => '0');
	signal TimeToLive_d										: T_SLV_8													:= (others => '0');
	signal Protocol_d											: T_SLV_8													:= (others => '0');
	signal HeaderChecksum_d								: T_SLV_16												:= (others => '0');
	signal SourceIPv4Address_d						: T_NET_IPV4_ADDRESS							:= (others => (others => '0'));
	signal DestIPv4Address_d							: T_NET_IPV4_ADDRESS							:= (others => (others => '0'));

	constant IPV4_ADDRESS_LENGTH					: positive												:= 4;			-- IPv4 -> 4 bytes
	constant IPV4_ADDRESS_READER_BITS			: positive												:= log2ceilnz(IPV4_ADDRESS_LENGTH);

	signal IPv4SeqCounter_rst							: std_logic;
	signal IPv4SeqCounter_en							: std_logic;
	signal IPv4SeqCounter_us							: unsigned(IPV4_ADDRESS_READER_BITS - 1 downto 0)		:= to_unsigned(IPV4_ADDRESS_LENGTH - 1, IPV4_ADDRESS_READER_BITS);

	signal SrcIPv4Address_Reader_rst			: std_logic;
	signal SrcIPv4Address_Reader_en				: std_logic;
	signal SrcIPv4Address_Reader_us				: unsigned(IPV4_ADDRESS_READER_BITS - 1 downto 0)		:= to_unsigned(IPV4_ADDRESS_LENGTH - 1, IPV4_ADDRESS_READER_BITS);
	signal DestIPv4Address_Reader_rst			: std_logic;
	signal DestIPv4Address_Reader_en			: std_logic;
	signal DestIPv4Address_Reader_us			: unsigned(IPV4_ADDRESS_READER_BITS - 1 downto 0)		:= to_unsigned(IPV4_ADDRESS_LENGTH - 1, IPV4_ADDRESS_READER_BITS);

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

	process(State, Is_DataFlow, Is_SOF, Is_EOF, In_Valid, In_Data, In_EOF, IPv4SeqCounter_us, Out_Ack)
	begin
		NextState									<= State;

		Error											<= '0';

		In_Ack_i									<= '0';
		Out_Valid_i								<= '0';
		Out_SOF_i									<= '0';
		Out_EOF_i									<= In_EOF;

		IPv4SeqCounter_rst				<= '0';
		IPv4SeqCounter_en					<= '0';

		-- IPv4 Basic Header
		Register_rst							<= '0';
		HeaderLength_en						<= '0';
		TypeOfService_en					<= '0';
		TotalLength_en0						<= '0';
		TotalLength_en1						<= '0';
--		Identification_en0				<= '0';
--		Identification_en1				<= '0';
		Flags_en									<= '0';
--		FragmentOffset_en0				<= '0';
--		FragmentOffset_en1				<= '0';
		TimeToLive_en							<= '0';
		Protocol_en								<= '0';
		HeaderChecksum_en0				<= '0';
		HeaderChecksum_en1				<= '0';
		SourceIPv4Address_en			<= '0';
		DestIPv4Address_en				<= '0';

		case State is
			when ST_IDLE =>
				if (Is_SOF = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
						if (In_Data(3 downto 0) = x"4") then
							HeaderLength_en			<= '1';
							NextState						<= ST_RECEIVE_TYPE_OF_SERVICE;
						else
							NextState						<= ST_DISCARD_FRAME;
						end if;
					else  -- EOF
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_TYPE_OF_SERVICE =>
				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
						TypeOfService_en			<= '1';
						NextState							<= ST_RECEIVE_TOTAL_LENGTH_0;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_TOTAL_LENGTH_0 =>
				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
						TotalLength_en0				<= '1';
						NextState							<= ST_RECEIVE_TOTAL_LENGTH_1;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_TOTAL_LENGTH_1 =>
				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
						TotalLength_en1				<= '1';
						NextState							<= ST_RECEIVE_IDENTIFICATION_0;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_IDENTIFICATION_0 =>
				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
--						Identification_en0		<= '1';
						NextState							<= ST_RECEIVE_IDENTIFICATION_1;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_IDENTIFICATION_1 =>
				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
--						Identification_en1		<= '1';
						NextState							<= ST_RECEIVE_FLAGS;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_FLAGS =>
				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
						Flags_en							<= '1';
--						FragmentOffset_en0		<= '1';
						NextState							<= ST_RECEIVE_FRAGMENT_OFFSET_1;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_FRAGMENT_OFFSET_1 =>
				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
--						FragmentOffset_en1		<= '1';
						NextState							<= ST_RECEIVE_TIME_TO_LIVE;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_TIME_TO_LIVE =>
				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
						TimeToLive_en					<= '1';
						NextState							<= ST_RECEIVE_PROTOCOL;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_PROTOCOL =>
				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
						Protocol_en						<= '1';
						NextState							<= ST_RECEIVE_HEADER_CHECKSUM_0;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_HEADER_CHECKSUM_0 =>
				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
						HeaderChecksum_en0		<= '1';
						NextState							<= ST_RECEIVE_HEADER_CHECKSUM_1;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_HEADER_CHECKSUM_1 =>
				IPv4SeqCounter_rst				<= '1';

				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					if (Is_EOF = '0') then
						HeaderChecksum_en1		<= '1';
						NextState							<= ST_RECEIVE_SOURCE_ADDRESS;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_SOURCE_ADDRESS =>
				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					SourceIPv4Address_en		<= '1';
					IPv4SeqCounter_en				<= '1';

					if (Is_EOF = '0') then
						if (IPv4SeqCounter_us = 0) then
							IPv4SeqCounter_rst	<= '1';
							NextState						<= ST_RECEIVE_DESTINATION_ADDRESS;
						end if;
					else
						NextState							<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_DESTINATION_ADDRESS =>
				if (In_Valid = '1') then
					In_Ack_i								<= '1';

					DestIPv4Address_en			<= '1';
					IPv4SeqCounter_en				<= '1';

					if (Is_EOF = '0') then
						if (IPv4SeqCounter_us = 0) then
							IPv4SeqCounter_rst	<= '1';
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
				HeaderLength_d						<= (others => '0');
				TypeOfService_d						<= (others => '0');
				TotalLength_d							<= (others => '0');
--				Identification_d					<= (others => '0');
				Flag_DontFragment_d				<= '0';
				Flag_MoreFragmenta_d			<= '0';
--				FragmentOffset_d					<= (others => '0');
				TimeToLive_d							<= (others => '0');
				Protocol_d								<= (others => '0');
				HeaderChecksum_d					<= (others => '0');
				SourceIPv4Address_d				<= (others => (others => '0'));
				DestIPv4Address_d					<= (others => (others => '0'));
			else
				if (HeaderLength_en = '1') then
					HeaderLength_d									<= In_Data(3 downto 0);
				end if;

				if (TypeOfService_en = '1') then
					TypeOfService_d									<= In_Data;
				end if;

				if (TotalLength_en0 = '1') then
					TotalLength_d(15 downto 8)			<= In_Data;
				end if;
				if (TotalLength_en1 = '1') then
					TotalLength_d(7 downto 0)				<= In_Data;
				end if;

--				if (Identification_en0 = '1') then
--					Identification_d(15 downto 8)		<= In_Data;
--				end if;
--				if (Identification_en1 = '1') then
--					Identification_d(7 downto 0)		<= In_Data;
--				end if;

				if (Flags_en = '1') then
					Flag_DontFragment_d							<= In_Data(6);
					Flag_MoreFragmenta_d						<= In_Data(5);
				end if;

--				if (FragmentOffset_en0 = '1') then
--					FragmentOffset_d(12 downto 8)		<= In_Data(4 downto 0);
--				end if;
--				if (FragmentOffset_en1 = '1') then
--					FragmentOffset_d(7 downto 0)		<= In_Data;
--				end if;

				if (TimeToLive_en = '1') then
					TimeToLive_d										<= In_Data;
				end if;

				if (Protocol_en = '1') then
					Protocol_d											<= In_Data;
				end if;

				if (HeaderChecksum_en0 = '1') then
					HeaderChecksum_d(15 downto 8)		<= In_Data;
				end if;
				if (HeaderChecksum_en1 = '1') then
					HeaderChecksum_d(7 downto 0)		<= In_Data;
				end if;

				if (SourceIPv4Address_en = '1') then
					SourceIPv4Address_d(to_integer(IPv4SeqCounter_us))	<= In_Data;
				end if;

				if (DestIPv4Address_en = '1') then
					DestIPv4Address_d(to_integer(IPv4SeqCounter_us))		<= In_Data;
				end if;
			end if;
		end if;
	end process;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if ((Reset or IPv4SeqCounter_rst) = '1') then
				IPv4SeqCounter_us				<= to_unsigned(IPV4_ADDRESS_LENGTH - 1, IPV4_ADDRESS_READER_BITS);
			elsif (IPv4SeqCounter_en = '1') then
				IPv4SeqCounter_us				<= IPv4SeqCounter_us - 1;
			end if;
		end if;
	end process;

	SrcIPv4Address_Reader_rst		<= Out_Meta_rst;
	SrcIPv4Address_Reader_en		<= Out_Meta_SrcIPv4Address_nxt;
	DestIPv4Address_Reader_rst	<= Out_Meta_rst;
	DestIPv4Address_Reader_en		<= Out_Meta_DestIPv4Address_nxt;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if ((Reset or SrcIPv4Address_Reader_rst) = '1') then
				SrcIPv4Address_Reader_us		<= to_unsigned(IPV4_ADDRESS_LENGTH - 1, IPV4_ADDRESS_READER_BITS);
			elsif (SrcIPv4Address_Reader_en = '1') then
				SrcIPv4Address_Reader_us		<= SrcIPv4Address_Reader_us - 1;
			end if;
		end if;
	end process;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if ((Reset or DestIPv4Address_Reader_rst) = '1') then
				DestIPv4Address_Reader_us		<= to_unsigned(IPV4_ADDRESS_LENGTH - 1, IPV4_ADDRESS_READER_BITS);
			elsif (DestIPv4Address_Reader_en = '1') then
				DestIPv4Address_Reader_us		<= DestIPv4Address_Reader_us - 1;
			end if;
		end if;
	end process;

	In_Meta_rst												<= Out_Meta_rst;
	In_Meta_SrcMACAddress_nxt					<= Out_Meta_SrcMACAddress_nxt;
	In_Meta_DestMACAddress_nxt				<= Out_Meta_DestMACAddress_nxt;

	Out_Valid													<= Out_Valid_i;
	Out_Data													<= In_Data;
	Out_SOF														<= Out_SOF_i;
	Out_EOF														<= Out_EOF_i;
	Out_Meta_SrcMACAddress_Data				<= In_Meta_SrcMACAddress_Data;
	Out_Meta_DestMACAddress_Data			<= In_Meta_DestMACAddress_Data;
	Out_Meta_EthType									<= In_Meta_EthType;
	Out_Meta_SrcIPv4Address_Data			<= SourceIPv4Address_d(to_integer(SrcIPv4Address_Reader_us));
	Out_Meta_DestIPv4Address_Data			<= DestIPv4Address_d(to_integer(DestIPv4Address_Reader_us));
	Out_Meta_Length										<= TotalLength_d;
	Out_Meta_Protocol									<= Protocol_d;

end architecture;
