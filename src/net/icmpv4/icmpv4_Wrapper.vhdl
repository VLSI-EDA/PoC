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


entity icmpv4_Wrapper is
	generic (
		DEBUG																: boolean								:= FALSE;
		SOURCE_IPV4ADDRESS									: T_NET_IPV4_ADDRESS		:= C_NET_IPV4_ADDRESS_EMPTY
	);
	port (
		Clock																: in	std_logic;
		Reset																: in	std_logic;
		-- CSE interface
		Command															: in	T_NET_ICMPV4_COMMAND;
		Status															: out	T_NET_ICMPV4_STATUS;
		Error																: out	T_NET_ICMPV4_ERROR;
		-- Echo-Request destination address
		IPv4Address_rst											: out	std_logic;
		IPv4Address_nxt											: out	std_logic;
		IPv4Address_Data										: in	T_SLV_8;
		-- to IPv4 layer
		IP_TX_Valid													: out	std_logic;
		IP_TX_Data													: out	T_SLV_8;
		IP_TX_SOF														: out	std_logic;
		IP_TX_EOF														: out	std_logic;
		IP_TX_Ack														: in	std_logic;
		IP_TX_Meta_rst											: in	std_logic;
		IP_TX_Meta_SrcIPv4Address_nxt				: in	std_logic;
		IP_TX_Meta_SrcIPv4Address_Data			: out	T_SLV_8;
		IP_TX_Meta_DestIPv4Address_nxt			: in	std_logic;
		IP_TX_Meta_DestIPv4Address_Data			: out	T_SLV_8;
		IP_TX_Meta_Length										: out	T_SLV_16;
		-- from IPv4 layer
		IP_RX_Valid													: in	std_logic;
		IP_RX_Data													: in	T_SLV_8;
		IP_RX_SOF														: in	std_logic;
		IP_RX_EOF														: in	std_logic;
		IP_RX_Ack														: out	std_logic;
		IP_RX_Meta_rst											: out	std_logic;
		IP_RX_Meta_SrcMACAddress_nxt				: out	std_logic;
		IP_RX_Meta_SrcMACAddress_Data				: in	T_SLV_8;
		IP_RX_Meta_DestMACAddress_nxt				: out	std_logic;
		IP_RX_Meta_DestMACAddress_Data			: in	T_SLV_8;
--		IP_RX_Meta_EthType									: in	T_SLV_16;
		IP_RX_Meta_SrcIPv4Address_nxt				: out	std_logic;
		IP_RX_Meta_SrcIPv4Address_Data			: in	T_SLV_8;
		IP_RX_Meta_DestIPv4Address_nxt			: out	std_logic;
		IP_RX_Meta_DestIPv4Address_Data			: in	T_SLV_8;
--		IP_RX_Meta_TrafficClass							: in	T_SLV_8;
--		IP_RX_Meta_FlowLabel								: in	T_SLV_24;
		IP_RX_Meta_Length										: in	T_SLV_16
--		IP_RX_Meta_Protocol									: in	T_SLV_8
	);
end entity;


architecture rtl of icmpv4_Wrapper is
	attribute FSM_ENCODING						: string;

	type T_STATE		is (
		ST_IDLE,
			ST_SEND_ECHO_REQUEST,
				ST_SEND_ECHO_REQUEST_WAIT,
				ST_WAIT_FOR_ECHO_REPLY,
				ST_EVAL_ECHO_REPLY,
			ST_SEND_ECHO_REPLY,
				ST_SEND_ECHO_REPLY_WAIT,
				ST_SEND_ECHO_REPLY_FINISHED,
		ST_ERROR
	);

	signal FSM_State										: T_STATE											:= ST_IDLE;
	signal FSM_NextState								: T_STATE;
	attribute FSM_ENCODING of FSM_State	: signal is ite(DEBUG, "gray", ite((VENDOR = VENDOR_XILINX), "auto", "default"));

	signal FSM_TX_Command								: T_NET_ICMPV4_TX_COMMAND;
	signal TX_Status										: T_NET_ICMPV4_TX_STATUS;
	signal TX_Error											: T_NET_ICMPV4_TX_ERROR;

	signal FSM_RX_Command								: T_NET_ICMPV4_RX_COMMAND;
	signal RX_Status										: T_NET_ICMPV4_RX_STATUS;
	signal RX_Error											: T_NET_ICMPV4_RX_ERROR;

	signal TX_Meta_rst									: std_logic;
	signal TX_Meta_IPv4Address_nxt			: std_logic;
	signal FSM_TX_Meta_IPv4Address_Data	: T_SLV_8;
	signal FSM_TX_Meta_Type							: T_SLV_8;
	signal FSM_TX_Meta_Code							: T_SLV_8;
	signal FSM_TX_Meta_Identification		: T_SLV_16;
	signal FSM_TX_Meta_SequenceNumber		: T_SLV_16;
	signal TX_Meta_Payload_nxt					: std_logic;
	signal FSM_TX_Meta_Payload_last			: std_logic;
	signal FSM_TX_Meta_Payload_Data			: T_SLV_8;

	signal RX_Meta_rst											: std_logic;
	signal FSM_RX_Meta_rst									: std_logic;
	signal FSM_RX_Meta_SrcMACAddress_nxt		: std_logic;
	signal RX_Meta_SrcMACAddress_Data				: T_SLV_8;
	signal FSM_RX_Meta_DestMACAddress_nxt		: std_logic;
	signal RX_Meta_DestMACAddress_Data			: T_SLV_8;
	signal FSM_RX_Meta_SrcIPv4Address_nxt		: std_logic;
	signal RX_Meta_SrcIPv4Address_Data			: T_SLV_8;
	signal FSM_RX_Meta_DestIPv4Address_nxt	: std_logic;
	signal RX_Meta_DestIPv4Address_Data			: T_SLV_8;
	signal RX_Meta_Length										: T_SLV_16;
	signal RX_Meta_Type											: T_SLV_8;
	signal RX_Meta_Code											: T_SLV_8;
	signal RX_Meta_Identification						: T_SLV_16;
	signal RX_Meta_SequenceNumber						: T_SLV_16;
	signal FSM_RX_Meta_Payload_nxt					: std_logic;
	signal RX_Meta_Payload_last							: std_logic;
	signal RX_Meta_Payload_Data							: T_SLV_8;

begin
-- =============================================================================
-- ICMPv4 FSM
-- =============================================================================
	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Reset = '1') then
				FSM_State			<= ST_IDLE;
			else
				FSM_State			<= FSM_NextState;
			end if;
		end if;
	end process;

	process(FSM_State,
					Command,
					TX_Status, TX_Error, TX_Meta_Payload_nxt,
					RX_Status, RX_Error, RX_Meta_Identification, RX_Meta_SequenceNumber, RX_Meta_Payload_Data, RX_Meta_Payload_last)
	begin
		FSM_NextState											<= FSM_State;

		Status														<= NET_ICMPV4_STATUS_IDLE;
		Error															<= NET_ICMPV4_ERROR_NONE;

		FSM_TX_Command										<= NET_ICMPV4_TX_CMD_NONE;
		FSM_RX_Command										<= NET_ICMPV4_RX_CMD_NONE;

		FSM_TX_Meta_Type									<= C_NET_ICMPV4_TYPE_EMPTY;
		FSM_TX_Meta_Code									<= C_NET_ICMPV4_CODE_EMPTY;
		FSM_TX_Meta_Identification				<= x"0000";
		FSM_TX_Meta_SequenceNumber				<= x"0000";
		FSM_TX_Meta_Payload_last					<= RX_Meta_Payload_last;
		FSM_TX_Meta_Payload_Data					<= RX_Meta_Payload_Data;

		FSM_RX_Meta_rst										<= '0';
		FSM_RX_Meta_SrcMACAddress_nxt			<= '0';
		FSM_RX_Meta_DestMACAddress_nxt		<= '0';
		FSM_RX_Meta_SrcIPv4Address_nxt		<= '0';
		FSM_RX_Meta_DestIPv4Address_nxt		<= '0';
		FSM_RX_Meta_Payload_nxt						<= '0';

		case FSM_State is
			when ST_IDLE =>
				case Command is
					when NET_ICMPV4_CMD_NONE =>													null;
					when NET_ICMPV4_CMD_ECHO_REQUEST =>									FSM_NextState		<= ST_SEND_ECHO_REQUEST;
					when others =>																			FSM_NextState		<= ST_ERROR;
				end case;

				case RX_Status is
					when NET_ICMPV4_RX_STATUS_IDLE =>										null;
					when NET_ICMPV4_RX_STATUS_RECEIVED_ECHO_REQUEST =>	FSM_NextState		<= ST_SEND_ECHO_REPLY;
					when others =>																			FSM_NextState		<= ST_ERROR;
				end case;

			-- ======================================================================
			when ST_SEND_ECHO_REQUEST =>
				FSM_TX_Command								<= NET_ICMPV4_TX_CMD_ECHO_REQUEST;

				IPv4Address_rst								<= TX_Meta_rst;
				IPv4Address_nxt								<= TX_Meta_IPv4Address_nxt;

				FSM_TX_Meta_IPv4Address_Data	<= IPv4Address_Data;
				FSM_TX_Meta_Type							<= C_NET_ICMPV4_TYPE_ECHO_REQUEST;
				FSM_TX_Meta_Code							<= C_NET_ICMPV4_CODE_ECHO_REQUEST;
				FSM_TX_Meta_Identification		<= x"C0FE";
				FSM_TX_Meta_SequenceNumber		<= x"BEAF";

				FSM_NextState									<= ST_SEND_ECHO_REQUEST_WAIT;

			when ST_SEND_ECHO_REQUEST_WAIT =>
				IPv4Address_rst								<= TX_Meta_rst;
				IPv4Address_nxt								<= TX_Meta_IPv4Address_nxt;

				FSM_TX_Meta_IPv4Address_Data	<= IPv4Address_Data;
				FSM_TX_Meta_Type							<= C_NET_ICMPV4_TYPE_ECHO_REQUEST;
				FSM_TX_Meta_Code							<= C_NET_ICMPV4_CODE_ECHO_REQUEST;
				FSM_TX_Meta_Identification		<= x"C0FE";
				FSM_TX_Meta_SequenceNumber		<= x"BEAF";

				case TX_Status is
					when NET_ICMPV4_TX_STATUS_IDLE =>										null;
					when NET_ICMPV4_TX_STATUS_SENDING =>								null;
					when NET_ICMPV4_TX_STATUS_SEND_COMPLETE =>					FSM_NextState		<= ST_WAIT_FOR_ECHO_REPLY;
					when NET_ICMPV4_TX_STATUS_ERROR =>									FSM_NextState		<= ST_ERROR;
					when others =>																			FSM_NextState		<= ST_ERROR;
				end case;

			when ST_WAIT_FOR_ECHO_REPLY =>
				case RX_Status is
					when NET_ICMPV4_RX_STATUS_IDLE =>										null;
					when NET_ICMPV4_RX_STATUS_RECEIVING =>							null;
					when NET_ICMPV4_RX_STATUS_RECEIVED_ECHO_REPLY =>		FSM_NextState		<= ST_EVAL_ECHO_REPLY;
					when NET_ICMPV4_RX_STATUS_ERROR =>									FSM_NextState		<= ST_ERROR;
					when others =>																			FSM_NextState		<= ST_ERROR;
				end case;

			when ST_EVAL_ECHO_REPLY =>

				if (TRUE) then
					FSM_NextState								<= ST_IDLE;
				else
					FSM_NextState								<= ST_ERROR;
				end if;

			-- ======================================================================
			when ST_SEND_ECHO_REPLY =>
				FSM_TX_Command								<= NET_ICMPV4_TX_CMD_ECHO_REPLY;

				FSM_RX_Meta_rst									<= TX_Meta_rst;
				FSM_RX_Meta_SrcIPv4Address_nxt	<= TX_Meta_IPv4Address_nxt;

				FSM_TX_Meta_IPv4Address_Data		<= RX_Meta_SrcIPv4Address_Data;
				FSM_TX_Meta_Type								<= C_NET_ICMPV4_TYPE_ECHO_REPLY;
				FSM_TX_Meta_Code								<= C_NET_ICMPV4_CODE_ECHO_REPLY;
				FSM_TX_Meta_Identification			<= RX_Meta_Identification;
				FSM_TX_Meta_SequenceNumber			<= RX_Meta_SequenceNumber;
				FSM_RX_Meta_Payload_nxt					<= TX_Meta_Payload_nxt;

				FSM_NextState										<= ST_SEND_ECHO_REPLY;

			when ST_SEND_ECHO_REPLY_WAIT =>
				FSM_RX_Meta_rst									<= TX_Meta_rst;
				FSM_RX_Meta_SrcIPv4Address_nxt	<= TX_Meta_IPv4Address_nxt;

				FSM_TX_Meta_IPv4Address_Data		<= RX_Meta_SrcIPv4Address_Data;
				FSM_TX_Meta_Type								<= C_NET_ICMPV4_TYPE_ECHO_REPLY;
				FSM_TX_Meta_Code								<= C_NET_ICMPV4_CODE_ECHO_REPLY;
				FSM_TX_Meta_Identification			<= RX_Meta_Identification;
				FSM_TX_Meta_SequenceNumber			<= RX_Meta_SequenceNumber;

				case TX_Status is
					when NET_ICMPV4_TX_STATUS_IDLE =>						null;
					when NET_ICMPV4_TX_STATUS_SENDING =>				null;
					when NET_ICMPV4_TX_STATUS_SEND_COMPLETE =>	FSM_NextState		<= ST_SEND_ECHO_REPLY_FINISHED;
					when NET_ICMPV4_TX_STATUS_ERROR =>					FSM_NextState		<= ST_ERROR;
					when others =>															FSM_NextState		<= ST_ERROR;
				end case;

			when ST_SEND_ECHO_REPLY_FINISHED =>
				Status												<= NET_ICMPV4_STATUS_IDLE;

				FSM_RX_Command								<= NET_ICMPV4_RX_CMD_CLEAR;

				FSM_NextState									<= ST_IDLE;

			-- ======================================================================
			when ST_ERROR =>
				Status												<= NET_ICMPV4_STATUS_ERROR;
				Error													<= NET_ICMPV4_ERROR_FSM;
				FSM_NextState									<= ST_IDLE;

		end case;
	end process;

-- =============================================================================
-- TX Path
-- =============================================================================
	TX : entity PoC.icmpv4_TX
		generic map (
			DEBUG								=> DEBUG,
			SOURCE_IPV4ADDRESS						=> SOURCE_IPV4ADDRESS
		)
		port map (
			Clock													=> Clock,
			Reset													=> Reset,

			Command												=> FSM_TX_Command,
			Status												=> TX_Status,
			Error													=> TX_Error,

			Out_Valid											=> IP_TX_Valid,
			Out_Data											=> IP_TX_Data,
			Out_SOF												=> IP_TX_SOF,
			Out_EOF												=> IP_TX_EOF,
			Out_Ack												=> IP_TX_Ack,
			Out_Meta_rst									=> IP_TX_Meta_rst,
			Out_Meta_SrcIPv4Address_nxt		=> IP_TX_Meta_SrcIPv4Address_nxt,
			Out_Meta_SrcIPv4Address_Data	=> IP_TX_Meta_SrcIPv4Address_Data,
			Out_Meta_DestIPv4Address_nxt	=> IP_TX_Meta_DestIPv4Address_nxt,
			Out_Meta_DestIPv4Address_Data	=> IP_TX_Meta_DestIPv4Address_Data,
			Out_Meta_Length								=> IP_TX_Meta_Length,

			In_Meta_rst										=> TX_Meta_rst,
			In_Meta_IPv4Address_nxt				=> TX_Meta_IPv4Address_nxt,
			In_Meta_IPv4Address_Data			=> FSM_TX_Meta_IPv4Address_Data,
			In_Meta_Type									=> FSM_TX_Meta_Type,
			In_Meta_Code									=> FSM_TX_Meta_Code,
			In_Meta_Identification				=> FSM_TX_Meta_Identification,
			In_Meta_SequenceNumber				=> FSM_TX_Meta_SequenceNumber,
			In_Meta_Payload_nxt						=> TX_Meta_Payload_nxt,
			In_Meta_Payload_last					=> FSM_TX_Meta_Payload_last,
			In_Meta_Payload_Data					=> FSM_TX_Meta_Payload_Data
    );

-- =============================================================================
-- RX Path
-- =============================================================================
	RX : entity PoC.icmpv4_RX
		generic map (
			DEBUG								=> DEBUG
		)
		port map (
			Clock													=> Clock,
			Reset													=> Reset,

			Command												=> FSM_RX_Command,
			Status												=> RX_Status,
			Error													=> RX_Error,

			In_Valid											=> IP_RX_Valid,
			In_Data												=> IP_RX_Data,
			In_SOF												=> IP_RX_SOF,
			In_EOF												=> IP_RX_EOF,
			In_Ack												=> IP_RX_Ack,
			In_Meta_rst										=> IP_RX_Meta_rst,
			In_Meta_SrcMACAddress_nxt			=> IP_RX_Meta_SrcMACAddress_nxt,
			In_Meta_SrcMACAddress_Data		=> IP_RX_Meta_SrcMACAddress_Data,
			In_Meta_DestMACAddress_nxt		=> IP_RX_Meta_DestMACAddress_nxt,
			In_Meta_DestMACAddress_Data		=> IP_RX_Meta_DestMACAddress_Data,
			In_Meta_SrcIPv4Address_nxt		=> IP_RX_Meta_SrcIPv4Address_nxt,
			In_Meta_SrcIPv4Address_Data		=> IP_RX_Meta_SrcIPv4Address_Data,
			In_Meta_DestIPv4Address_nxt		=> IP_RX_Meta_DestIPv4Address_nxt,
			In_Meta_DestIPv4Address_Data	=> IP_RX_Meta_DestIPv4Address_Data,
			In_Meta_Length								=> IP_RX_Meta_Length,

			Out_Meta_rst									=> FSM_RX_Meta_rst,
			Out_Meta_SrcMACAddress_nxt		=> FSM_RX_Meta_SrcMACAddress_nxt,
			Out_Meta_SrcMACAddress_Data		=> RX_Meta_SrcMACAddress_Data,
			Out_Meta_DestMACAddress_nxt		=> FSM_RX_Meta_DestMACAddress_nxt,
			Out_Meta_DestMACAddress_Data	=> RX_Meta_DestMACAddress_Data,
			Out_Meta_SrcIPv4Address_nxt		=> FSM_RX_Meta_SrcIPv4Address_nxt,
			Out_Meta_SrcIPv4Address_Data	=> RX_Meta_SrcIPv4Address_Data,
			Out_Meta_DestIPv4Address_nxt	=> FSM_RX_Meta_DestIPv4Address_nxt,
			Out_Meta_DestIPv4Address_Data	=> RX_Meta_DestIPv4Address_Data,
			Out_Meta_Length								=> RX_Meta_Length,
			Out_Meta_Type									=> RX_Meta_Type,
			Out_Meta_Code									=> RX_Meta_Code,
			Out_Meta_Identification				=> RX_Meta_Identification,
			Out_Meta_SequenceNumber				=> RX_Meta_SequenceNumber,
			Out_Meta_Payload_nxt					=> FSM_RX_Meta_Payload_nxt,
			Out_Meta_Payload_last					=> RX_Meta_Payload_last,
			Out_Meta_Payload_Data					=> RX_Meta_Payload_Data
		);
end architecture;
