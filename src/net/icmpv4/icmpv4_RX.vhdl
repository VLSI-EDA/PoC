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


entity icmpv4_RX is
	generic (
		DEBUG													: boolean											:= FALSE
	);
	port (
		Clock													: in	std_logic;																	--
		Reset													: in	std_logic;																	--
		-- CSE interface
		Command												: in	T_NET_ICMPV4_RX_COMMAND;
		Status												: out	T_NET_ICMPV4_RX_STATUS;
		Error													: out	T_NET_ICMPV4_RX_ERROR;
		-- IN port
		In_Valid											: in	std_logic;
		In_Data												: in	T_SLV_8;
		In_SOF												: in	std_logic;
		In_EOF												: in	std_logic;
		In_Ack												: out	std_logic;
		In_Meta_rst										: out	std_logic;
		In_Meta_SrcMACAddress_nxt			: out	std_logic;
		In_Meta_SrcMACAddress_Data		: in	T_SLV_8;
		In_Meta_DestMACAddress_nxt		: out	std_logic;
		In_Meta_DestMACAddress_Data		: in	T_SLV_8;
		In_Meta_SrcIPv4Address_nxt		: out	std_logic;
		In_Meta_SrcIPv4Address_Data		: in	T_SLV_8;
		In_Meta_DestIPv4Address_nxt		: out	std_logic;
		In_Meta_DestIPv4Address_Data	: in	T_SLV_8;
		In_Meta_Length								: in	T_SLV_16;
		-- OUT Port
		Out_Meta_rst									: in	std_logic;
		Out_Meta_SrcMACAddress_nxt		: in	std_logic;
		Out_Meta_SrcMACAddress_Data		: out	T_SLV_8;
		Out_Meta_DestMACAddress_nxt		: in	std_logic;
		Out_Meta_DestMACAddress_Data	: out	T_SLV_8;
		Out_Meta_SrcIPv4Address_nxt		: in	std_logic;
		Out_Meta_SrcIPv4Address_Data	: out	T_SLV_8;
		Out_Meta_DestIPv4Address_nxt	: in	std_logic;
		Out_Meta_DestIPv4Address_Data	: out	T_SLV_8;
		Out_Meta_Length								: out	T_SLV_16;
		Out_Meta_Type									: out	T_SLV_8;
		Out_Meta_Code									: out	T_SLV_8;
		Out_Meta_Identification				: out	T_SLV_16;
		Out_Meta_SequenceNumber				: out	T_SLV_16;
		Out_Meta_Payload_nxt					: in	std_logic;
		Out_Meta_Payload_last					: out	std_logic;
		Out_Meta_Payload_Data					: out	T_SLV_8
	);
end entity;


architecture rtl of icmpv4_RX is
	attribute FSM_ENCODING						: string;

	type T_STATE		is (
		ST_IDLE,
			ST_RECEIVE_ECHO_CODE,
				ST_RECEIVE_ECHO_CHECKSUM_0,
				ST_RECEIVE_ECHO_CHECKSUM_1,
				ST_RECEIVE_ECHO_IDENTIFIER_0,
				ST_RECEIVE_ECHO_IDENTIFIER_1,
				ST_RECEIVE_ECHO_SEQ_NUMBER_0,
				ST_RECEIVE_ECHO_SEQ_NUMBER_1,
				ST_RECEIVE_ECHO_DATA,
				ST_RECEIVE_ECHO_COMPLETE,
		ST_DISCARD_FRAME,
		ST_ERROR
	);

	signal State													: T_STATE											:= ST_IDLE;
	signal NextState											: T_STATE;
	attribute FSM_ENCODING of State				: signal is ite(DEBUG, "gray", ite((VENDOR = VENDOR_XILINX), "auto", "default"));

	signal Register_rst										: std_logic;

	-- UDP header fields
	signal Type_en												: std_logic;
	signal Code_en												: std_logic;
	signal Checksum_en0										: std_logic;
	signal Checksum_en1										: std_logic;
	signal Identification_en0							: std_logic;
	signal Identification_en1							: std_logic;
	signal SequenceNumber_en0							: std_logic;
	signal SequenceNumber_en1							: std_logic;

	signal Type_d													: T_SLV_8											:= (others => '0');
	signal Code_d													: T_SLV_8											:= (others => '0');
	signal Checksum_d											: T_SLV_16										:= (others => '0');
	signal Identification_d								: T_SLV_16										:= (others => '0');
	signal SequenceNumber_d								: T_SLV_16										:= (others => '0');

	signal MetaFIFO_put										: std_logic;
	signal MetaFIFO_DataIn								: std_logic_vector(8 downto 0);
	signal MetaFIFO_Full									: std_logic;
	signal MetaFIFO_Commit								: std_logic;
	signal MetaFIFO_Rollback							: std_logic;
--	signal MetaFIFO_Valid									: STD_LOGIC;
	signal MetaFIFO_DataOut								: std_logic_vector(8 downto 0);
	signal MetaFIFO_got										: std_logic;

begin

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

	process(State, Command, In_Valid, In_Data, In_SOF, In_EOF, Out_Meta_rst, Out_Meta_Payload_nxt)
	begin
		NextState													<= State;

		Status														<= NET_ICMPV4_RX_STATUS_IDLE;
		Error															<= NET_ICMPV4_RX_ERROR_NONE;

		In_Ack														<= '0';
		In_Meta_rst												<= '0';
		In_Meta_SrcMACAddress_nxt					<= '0';
		In_Meta_DestMACAddress_nxt				<= '0';
		In_Meta_SrcIPv4Address_nxt				<= '0';
		In_Meta_DestIPv4Address_nxt				<= '0';

		Register_rst											<= to_sl(Command = NET_ICMPV4_RX_CMD_CLEAR);
		Type_en														<= '0';
		Code_en														<= '0';
		Checksum_en0											<= '0';
		Checksum_en1											<= '0';
		Identification_en0								<= '0';
		Identification_en1								<= '0';
		SequenceNumber_en0								<= '0';
		SequenceNumber_en1								<= '0';

		MetaFIFO_put											<= '0';
		MetaFIFO_DataIn(In_Data'range)		<= In_Data;
		MetaFIFO_DataIn(In_Data'length)		<= In_EOF;
		MetaFIFO_got											<= '0';
		MetaFIFO_Commit										<= '0';
		MetaFIFO_Rollback									<= '0';

		case State is
			when ST_IDLE =>
				if ((In_Valid and In_SOF) = '1') then
					In_Ack											<= '1';

					if (In_EOF = '0') then
						Type_en										<= '1';

						if (In_Data = C_NET_ICMPV4_TYPE_ECHO_REPLY) then
							NextState								<= ST_RECEIVE_ECHO_CODE;
						elsif (In_Data = C_NET_ICMPV4_TYPE_ECHO_REQUEST) then
							NextState								<= ST_RECEIVE_ECHO_CODE;
						else
							NextState								<= ST_DISCARD_FRAME;
						end if;
					else
						NextState									<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_ECHO_CODE =>
				Status												<= NET_ICMPV4_RX_STATUS_RECEIVING;

				if (In_Valid = '1') then
					In_Ack											<= '1';

					if (In_EOF = '0') then
						Code_en										<= '1';

						if (In_Data = C_NET_ICMPV4_CODE_ECHO_REPLY) then
							NextState								<= ST_RECEIVE_ECHO_CHECKSUM_0;
						elsif (In_Data = C_NET_ICMPV4_CODE_ECHO_REQUEST) then
							NextState								<= ST_RECEIVE_ECHO_CHECKSUM_0;
						else
							NextState								<= ST_DISCARD_FRAME;
						end if;
					else
						NextState									<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_ECHO_CHECKSUM_0 =>
				Status												<= NET_ICMPV4_RX_STATUS_RECEIVING;

				if (In_Valid = '1') then
					In_Ack											<= '1';

					if (In_EOF = '0') then
						Checksum_en0							<= '1';
						NextState									<= ST_RECEIVE_ECHO_CHECKSUM_1;
					else
						NextState									<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_ECHO_CHECKSUM_1 =>
				Status												<= NET_ICMPV4_RX_STATUS_RECEIVING;

				if (In_Valid = '1') then
					In_Ack											<= '1';

					if (In_EOF = '0') then
						Checksum_en1							<= '1';
						NextState									<= ST_RECEIVE_ECHO_IDENTIFIER_0;
					else
						NextState									<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_ECHO_IDENTIFIER_0 =>
				Status												<= NET_ICMPV4_RX_STATUS_RECEIVING;

				if (In_Valid = '1') then
					In_Ack											<= '1';

					if (In_EOF = '0') then
						Identification_en0				<= '1';
						NextState									<= ST_RECEIVE_ECHO_IDENTIFIER_1;
					else
						NextState									<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_ECHO_IDENTIFIER_1 =>
				Status												<= NET_ICMPV4_RX_STATUS_RECEIVING;

				if (In_Valid = '1') then
					In_Ack											<= '1';

					if (In_EOF = '0') then
						Identification_en1				<= '1';
						NextState									<= ST_RECEIVE_ECHO_SEQ_NUMBER_0;
					else
						NextState									<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_ECHO_SEQ_NUMBER_0 =>
				Status												<= NET_ICMPV4_RX_STATUS_RECEIVING;

				if (In_Valid = '1') then
					In_Ack											<= '1';

					if (In_EOF = '0') then
						SequenceNumber_en0				<= '1';
						NextState									<= ST_RECEIVE_ECHO_SEQ_NUMBER_1;
					else
						NextState									<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_ECHO_SEQ_NUMBER_1 =>
				Status												<= NET_ICMPV4_RX_STATUS_RECEIVING;

				if (In_Valid = '1') then
					In_Ack											<= '1';

					if (In_EOF = '0') then
						SequenceNumber_en1				<= '1';
						NextState									<= ST_RECEIVE_ECHO_DATA;
					else
						NextState									<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_ECHO_DATA =>
				Status												<= NET_ICMPV4_RX_STATUS_RECEIVING;

				if (In_Valid = '1') then
					In_Ack											<= '1';

					MetaFIFO_put								<= '1';

					if (In_EOF = '1') then
						MetaFIFO_Commit						<= '1';
						NextState									<= ST_RECEIVE_ECHO_COMPLETE;
					end if;
				end if;

			when ST_RECEIVE_ECHO_COMPLETE =>
				if (Code_d = C_NET_ICMPV4_TYPE_ECHO_REPLY) then
					Status											<= NET_ICMPV4_RX_STATUS_RECEIVED_ECHO_REPLY;
				elsif (Code_d = C_NET_ICMPV4_TYPE_ECHO_REQUEST) then
					Status											<= NET_ICMPV4_RX_STATUS_RECEIVED_ECHO_REQUEST;
				end if;

				In_Meta_SrcMACAddress_nxt			<= Out_Meta_SrcMACAddress_nxt;
				In_Meta_DestMACAddress_nxt		<= Out_Meta_DestMACAddress_nxt;
				In_Meta_SrcIPv4Address_nxt		<= Out_Meta_SrcIPv4Address_nxt;
				In_Meta_DestIPv4Address_nxt		<= Out_Meta_DestIPv4Address_nxt;

				MetaFIFO_got									<= Out_Meta_Payload_nxt;
				MetaFIFO_Rollback							<= Out_Meta_rst;

				if (Command = NET_ICMPV4_RX_CMD_CLEAR) then
					NextState										<= ST_IDLE;
				end if;

			when ST_DISCARD_FRAME =>
				In_Ack												<= '1';

				if ((In_Valid and In_EOF) = '1') then
					NextState										<= ST_ERROR;
				end if;

			when ST_ERROR =>
				Status												<= NET_ICMPV4_RX_STATUS_ERROR;
				Error													<= NET_ICMPV4_RX_ERROR_FSM;

				NextState											<= ST_IDLE;

		end case;
	end process;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if ((Reset or Register_rst) = '1') then
				Type_d															<= (others => '0');
				Code_d															<= (others => '0');
				Checksum_d													<= (others => '0');
				Identification_d										<= (others => '0');
				SequenceNumber_d										<= (others => '0');
			else
				if (Type_en = '1') then
					Type_d														<= In_Data;
				end if;
				if (Code_en = '1') then
					Code_d														<= In_Data;
				end if;

				if (Checksum_en0 = '1') then
					Checksum_d(7 downto 0)						<= In_Data;
				end if;
				if (Checksum_en1 = '1') then
					Checksum_d(15 downto 8)						<= In_Data;
				end if;

				if (Identification_en0 = '1') then
					Identification_d(7 downto 0)			<= In_Data;
				end if;
				if (Identification_en1 = '1') then
					Identification_d(15 downto 8)			<= In_Data;
				end if;

				if (SequenceNumber_en1 = '1') then
					SequenceNumber_d(7 downto 0)			<= In_Data;
				end if;
				if (SequenceNumber_en1 = '1') then
					SequenceNumber_d(15 downto 8)			<= In_Data;
				end if;
			end if;
		end if;
	end process;

	-- FIXME: monitor MetaFIFO_Full signal

	PayloadFIFO : entity PoC.fifo_cc_got_tempgot
		generic map (
			D_BITS							=> MetaFIFO_DataIn'length,	-- Data Width
			MIN_DEPTH						=> 64,											-- Minimum FIFO Depth
			DATA_REG						=> TRUE,										-- Store Data Content in Registers
			STATE_REG						=> FALSE,										-- Registered Full/Empty Indicators
			OUTPUT_REG					=> FALSE,										-- Registered FIFO Output
			ESTATE_WR_BITS			=> 0,												-- Empty State Bits
			FSTATE_RD_BITS			=> 0												-- Full State Bits
		)
		port map (
			-- Global Reset and Clock
			clk									=> Clock,
			rst									=> Reset,

			-- Writing Interface
			put									=> MetaFIFO_put,
			din									=> MetaFIFO_DataIn,
			full								=> MetaFIFO_Full,
			estate_wr						=> open,

			-- Reading Interface
			got									=> MetaFIFO_got,
			dout								=> MetaFIFO_DataOut,
			valid								=> open,	--MetaFIFO_Valid,
			fstate_rd						=> open,

			commit							=> MetaFIFO_Commit,
			rollback						=> MetaFIFO_Rollback
		);

	Out_Meta_SrcMACAddress_Data			<= In_Meta_SrcMACAddress_Data;
	Out_Meta_DestMACAddress_Data		<= In_Meta_DestMACAddress_Data;
	Out_Meta_SrcIPv4Address_Data		<= In_Meta_SrcIPv4Address_Data;
	Out_Meta_DestIPv4Address_Data		<= In_Meta_DestIPv4Address_Data;
	Out_Meta_Length									<= In_Meta_Length;
	Out_Meta_Type										<= Type_d;
	Out_Meta_Code										<= Code_d;
	Out_Meta_Identification					<= Identification_d;
	Out_Meta_SequenceNumber					<= SequenceNumber_d;
	Out_Meta_Payload_last						<= MetaFIFO_DataOut(Out_Meta_Payload_Data'length);
	Out_Meta_Payload_Data						<= MetaFIFO_DataOut(Out_Meta_Payload_Data'range);
end architecture;
