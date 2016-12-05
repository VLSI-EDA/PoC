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


entity icmpv4_TX is
	generic (
		DEBUG													: boolean											:= FALSE;
		SOURCE_IPV4ADDRESS						: T_NET_IPV4_ADDRESS					:= C_NET_IPV4_ADDRESS_EMPTY
	);
	port (
		Clock													: in	std_logic;																	--
		Reset													: in	std_logic;																	--
		-- CSE interface
		Command												: in	T_NET_ICMPV4_TX_COMMAND;
		Status												: out	T_NET_ICMPV4_TX_STATUS;
		Error													: out	T_NET_ICMPV4_TX_ERROR;
		-- OUT port
		Out_Valid											: out	std_logic;
		Out_Data											: out	T_SLV_8;
		Out_SOF												: out	std_logic;
		Out_EOF												: out	std_logic;
		Out_Ack												: in	std_logic;
		Out_Meta_rst									: in	std_logic;
		Out_Meta_SrcIPv4Address_nxt		: in	std_logic;
		Out_Meta_SrcIPv4Address_Data	: out	T_SLV_8;
		Out_Meta_DestIPv4Address_nxt	: in	std_logic;
		Out_Meta_DestIPv4Address_Data	: out	T_SLV_8;
		Out_Meta_Length								: out	T_SLV_16;
		-- IN port
		In_Meta_rst										: out	std_logic;
		In_Meta_IPv4Address_nxt				: out	std_logic;
		In_Meta_IPv4Address_Data			: in	T_SLV_8;
		In_Meta_Type									: in	T_SLV_8;
		In_Meta_Code									: in	T_SLV_8;
		In_Meta_Identification				: in	T_SLV_16;
		In_Meta_SequenceNumber				: in	T_SLV_16;
		In_Meta_Payload_nxt						: out	std_logic;
		In_Meta_Payload_last					: in	std_logic;
		In_Meta_Payload_Data					: in	T_SLV_8
	);
end entity;


architecture rtl of icmpv4_TX is
	attribute FSM_ENCODING						: string;

	type T_STATE		is (
		ST_IDLE,
			ST_SEND_ECHO_type,
				ST_SEND_ECHO_CODE,
				ST_SEND_ECHOREQUEST_CHECKSUM_0,
				ST_SEND_ECHOREQUEST_CHECKSUM_1,
				ST_SEND_ECHOREQUEST_IDENTIFIER_0,
				ST_SEND_ECHOREQUEST_IDENTIFIER_1,
				ST_SEND_ECHOREQUEST_SEQUENCENUMBER_0,
				ST_SEND_ECHOREQUEST_SEQUENCENUMBER_1,
				ST_SEND_ECHOREQUEST_DATA,
				ST_SEND_ECHOREPLY_DATA,
		ST_COMPLETE
	);

	signal State													: T_STATE													:= ST_IDLE;
	signal NextState											: T_STATE;
	attribute FSM_ENCODING of State				: signal is ite(DEBUG, "gray", ite((VENDOR = VENDOR_XILINX), "auto", "default"));

	signal Checksum												: T_SLV_16;

	constant PAYLOAD											: std_logic_vector(255 downto 0)	:= x"00010203" & x"04050607" & x"08090A0B" & x"0C0D0E0F" & x"10111213" & x"14151617" & x"18191A1B" & x"1C1D1E1F";
	constant PAYLOAD_ROM									: T_SLVV_8												:= to_slvv_8(PAYLOAD);

	signal PayloadROM_Reader_nxt					: std_logic;
	signal PayloadROM_Reader_ov						: std_logic;
	signal PayloadROM_Reader_us						: unsigned(log2ceilnz(PAYLOAD_ROM'length) - 1 downto 0)			:= (others => '0');
	signal PayloadROM_Data								: T_SLV_8;

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

	process(State, Command, Out_Ack, PayloadROM_Reader_ov, PayloadROM_Data)
	begin
		NextState													<= State;

		Status														<= NET_ICMPV4_TX_STATUS_IDLE;
		Error															<= NET_ICMPV4_TX_ERROR_NONE;

		Out_Valid													<= '0';
		Out_Data													<= (others => '0');
		Out_SOF														<= '0';
		Out_EOF														<= '0';
		Out_Meta_Length										<= (others => '0');

		PayloadROM_Reader_nxt							<= '0';

		case State is
			when ST_IDLE =>
				case Command is
					when NET_ICMPV4_TX_CMD_NONE =>
						null;

					when NET_ICMPV4_TX_CMD_ECHO_REQUEST =>
						-- TODO: check if Type equal to Command
						NextState									<= ST_SEND_ECHO_type;

					when NET_ICMPV4_TX_CMD_ECHO_REPLY =>
						-- TODO: check if Type equal to Command
						NextState									<= ST_SEND_ECHO_type;

				end case;

			when ST_SEND_ECHO_type =>
				Status												<= NET_ICMPV4_TX_STATUS_SENDING;

				Out_Valid											<= '1';
				Out_Data											<= In_Meta_Type;
				Out_SOF												<= '1';

				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_ECHO_CODE;
				end if;

			when ST_SEND_ECHO_CODE =>
				Status												<= NET_ICMPV4_TX_STATUS_SENDING;

				Out_Valid											<= '1';
				Out_Data											<= In_Meta_Code;

				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_ECHOREQUEST_CHECKSUM_0;
				end if;

			when ST_SEND_ECHOREQUEST_CHECKSUM_0 =>
				Status												<= NET_ICMPV4_TX_STATUS_SENDING;

				Out_Valid											<= '1';
				Out_Data											<= Checksum(15 downto 8);

				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_ECHOREQUEST_CHECKSUM_1;
				end if;

			when ST_SEND_ECHOREQUEST_CHECKSUM_1 =>
				Status												<= NET_ICMPV4_TX_STATUS_SENDING;

				Out_Valid											<= '1';
				Out_Data											<= Checksum(7 downto 0);

				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_ECHOREQUEST_IDENTIFIER_0;
				end if;

			when ST_SEND_ECHOREQUEST_IDENTIFIER_0 =>
				Status												<= NET_ICMPV4_TX_STATUS_SENDING;

				Out_Valid											<= '1';
				Out_Data											<= In_Meta_Identification(15 downto 8);

				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_ECHOREQUEST_IDENTIFIER_1;
				end if;

			when ST_SEND_ECHOREQUEST_IDENTIFIER_1 =>
				Status												<= NET_ICMPV4_TX_STATUS_SENDING;

				Out_Valid											<= '1';
				Out_Data											<= In_Meta_Identification(7 downto 0);

				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_ECHOREQUEST_SEQUENCENUMBER_0;
				end if;

			when ST_SEND_ECHOREQUEST_SEQUENCENUMBER_0 =>
				Status												<= NET_ICMPV4_TX_STATUS_SENDING;

				Out_Valid											<= '1';
				Out_Data											<= In_Meta_SequenceNumber(15 downto 8);

				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_ECHOREQUEST_SEQUENCENUMBER_1;
				end if;

			when ST_SEND_ECHOREQUEST_SEQUENCENUMBER_1 =>
				Status												<= NET_ICMPV4_TX_STATUS_SENDING;

				Out_Valid											<= '1';
				Out_Data											<= In_Meta_SequenceNumber(7 downto 0);

				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_ECHOREQUEST_DATA;
				end if;

			when ST_SEND_ECHOREQUEST_DATA =>
				Status												<= NET_ICMPV4_TX_STATUS_SENDING;

				Out_Valid											<= '1';
				Out_Data											<= PayloadROM_Data;

				PayloadROM_Reader_nxt					<= '1';

				if (Out_Ack	 = '1') then
					if (PayloadROM_Reader_ov = '1') then
						Out_EOF										<= '1';
						NextState									<= ST_COMPLETE;
					end if;
				end if;

			when ST_SEND_ECHOREPLY_DATA =>
				Status												<= NET_ICMPV4_TX_STATUS_SENDING;

				Out_Valid											<= '1';
				Out_Data											<= In_Meta_Payload_Data;

				In_Meta_Payload_nxt						<= '1';

				if (Out_Ack	 = '1') then
					if (In_Meta_Payload_last = '1') then
						Out_EOF											<= '1';

						NextState										<= ST_COMPLETE;
					end if;
				end if;

			when ST_COMPLETE =>
				Status												<= NET_ICMPV4_TX_STATUS_SEND_COMPLETE;

				NextState											<= ST_IDLE;

		end case;
	end process;


	Checksum			<= x"0000";


	SourceIPv4Seq : entity PoC.misc_Sequencer
		generic map (
			INPUT_BITS						=> 32,
			OUTPUT_BITS						=> 8,
			REGISTERED						=> FALSE
		)
		port map (
			Clock									=> Clock,
			Reset									=> Reset,

			Input									=> to_slv(SOURCE_IPV4ADDRESS),
			rst										=> Out_Meta_rst,
			rev										=> '1',
			nxt										=> Out_Meta_SrcIPv4Address_nxt,
			Output								=> Out_Meta_SrcIPv4Address_Data
		);

	process(Clock)
	begin
		if rising_edge(Clock) then
			if (PayloadROM_Reader_nxt = '0') then
				PayloadROM_Reader_us	<= (others => '0');
			else
				PayloadROM_Reader_us	<= PayloadROM_Reader_us + 1;
			end if;
		end if;
	end process;

	PayloadROM_Reader_ov						<= to_sl(PayloadROM_Reader_us = (PAYLOAD_ROM'length - 1));
	PayloadROM_Data									<= PAYLOAD_ROM(to_integer(PayloadROM_Reader_us));

	In_Meta_IPv4Address_nxt					<= Out_Meta_DestIPv4Address_nxt;
	Out_Meta_DestIPv4Address_Data		<= In_Meta_IPv4Address_Data;
end architecture;
