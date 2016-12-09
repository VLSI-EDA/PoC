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


entity arp_UniCast_Responder is
	generic (
		ALLOWED_PROTOCOL_IPV4					: boolean												:= TRUE;
		ALLOWED_PROTOCOL_IPV6					: boolean												:= FALSE
	);
	port (
		Clock													: in	std_logic;																	--
		Reset													: in	std_logic;																	--

		SendResponse									: in	std_logic;
		Complete											: out	std_logic;

		Address_rst										: out	std_logic;
		SenderMACAddress_nxt					: out	std_logic;
		SenderMACAddress_Data					: in	T_SLV_8;
		SenderIPv4Address_nxt					: out	std_logic;
		SenderIPv4Address_Data				: in	T_SLV_8;
		TargetMACAddress_nxt					: out	std_logic;
		TargetMACAddress_Data					: in	T_SLV_8;
		TargetIPv4Address_nxt					: out	std_logic;
		TargetIPv4Address_Data				: in	T_SLV_8;

		TX_Valid											: out	std_logic;
		TX_Data												: out	T_SLV_8;
		TX_SOF												: out	std_logic;
		TX_EOF												: out	std_logic;
		TX_Ack												: in	std_logic;
		TX_Meta_DestMACAddress_rst		: in	std_logic;
		TX_Meta_DestMACAddress_nxt		: in	std_logic;
		TX_Meta_DestMACAddress_Data		: out	T_SLV_8
	);
end entity;


architecture rtl of arp_UniCast_Responder is
	attribute FSM_ENCODING						: string;

	type T_STATE		is (
		ST_IDLE,
			ST_SEND_HARDWARE_TYPE_0,	ST_SEND_HARDWARE_TYPE_1,
			ST_SEND_PROTOCOL_TYPE_0,	ST_SEND_PROTOCOL_TYPE_1,
			ST_SEND_HARDWARE_ADDRESS_LENGTH, ST_SEND_PROTOCOL_ADDRESS_LENGTH,
			ST_SEND_OPERATION_0,			ST_SEND_OPERATION_1,
			ST_SEND_SENDER_MAC,				ST_SEND_SENDER_IP,
			ST_SEND_TARGET_MAC,				ST_SEND_TARGET_IP,
		ST_COMPLETE
	);

	signal State													: T_STATE																												:= ST_IDLE;
	signal NextState											: T_STATE;
	attribute FSM_ENCODING of State				: signal is "gray";

	constant HARDWARE_ADDRESS_LENGTH			: positive																											:= 6;			-- MAC -> 6 bytes
	constant PROTOCOL_IPV4_ADDRESS_LENGTH	: positive																											:= 4;			-- IPv4 -> 4 bytes
	constant PROTOCOL_IPV6_ADDRESS_LENGTH	: positive																											:= 16;		-- IPv6 -> 16 bytes
	constant PROTOCOL_ADDRESS_LENGTH			: positive																											:= ite((ALLOWED_PROTOCOL_IPV6 = FALSE), PROTOCOL_IPV4_ADDRESS_LENGTH, PROTOCOL_IPV6_ADDRESS_LENGTH);		-- IPv4 -> 4 bytes; IPv6 -> 16 bytes

	signal IsIPv4_l												: std_logic;
	signal IsIPv6_l												: std_logic;

	constant READER_COUNTER_BITS					: positive																											:= log2ceilnz(imax(HARDWARE_ADDRESS_LENGTH, PROTOCOL_ADDRESS_LENGTH));
	signal Reader_Counter_rst							: std_logic;
	signal Reader_Counter_en							: std_logic;
	signal Reader_Counter_us							: unsigned(READER_COUNTER_BITS - 1 downto 0)										:= (others => '0');

begin

	IsIPv4_l		<= '1';
	IsIPv6_l		<= '0';

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
					SendResponse,
					IsIPv4_l, IsIPv6_l,
					TX_Ack, TX_Meta_DestMACAddress_rst, TX_Meta_DestMACAddress_nxt,
					SenderMACAddress_Data, SenderIPv4Address_Data, TargetMACAddress_Data, TargetIPv4Address_Data,
					Reader_Counter_us)
	begin
		NextState											<= State;

		Complete											<= '0';

		TX_Valid											<= '0';
		TX_Data												<= (others => '0');
		TX_SOF												<= '0';
		TX_EOF												<= '0';
		TX_Meta_DestMACAddress_Data		<= TargetMACAddress_Data;

		Address_rst										<= '0';
		SenderMACAddress_nxt					<= '0';
		SenderIPv4Address_nxt					<= '0';
		TargetMACAddress_nxt					<= '0';
		TargetIPv4Address_nxt					<= '0';

		Reader_Counter_rst						<= '0';
		Reader_Counter_en							<= '0';

		case State is
			when ST_IDLE =>
				if (SendResponse = '1') then
					Address_rst							<= '1';
					NextState								<= ST_SEND_HARDWARE_TYPE_0;
				end if;

			when ST_SEND_HARDWARE_TYPE_0 =>
				TX_Valid									<= '1';
				TX_Data										<= x"00";
				TX_SOF										<= '1';

				Address_rst								<= TX_Meta_DestMACAddress_rst;
				TargetMACAddress_nxt			<= TX_Meta_DestMACAddress_nxt;

				if (TX_Ack	 = '1') then
					NextState								<= ST_SEND_HARDWARE_TYPE_1;
				end if;

			when ST_SEND_HARDWARE_TYPE_1 =>
				TX_Valid									<= '1';
				TX_Data										<= x"01";

				if (TX_Ack	 = '1') then
					NextState								<= ST_SEND_PROTOCOL_TYPE_0;
				end if;

			when ST_SEND_PROTOCOL_TYPE_0 =>
				TX_Valid									<= '1';

				if (IsIPv4_l = '1') then
					TX_Data									<= x"08";
				elsif (IsIPv6_l = '1') then
					TX_Data									<= x"86";
				end if;

				if (TX_Ack	 = '1') then
					NextState								<= ST_SEND_PROTOCOL_TYPE_1;
				end if;

			when ST_SEND_PROTOCOL_TYPE_1 =>
				TX_Valid									<= '1';

				if (IsIPv4_l = '1') then
					TX_Data									<= x"00";
				elsif (IsIPv6_l = '1') then
					TX_Data									<= x"DD";
				end if;

				if (TX_Ack	 = '1') then
					NextState								<= ST_SEND_HARDWARE_ADDRESS_LENGTH;
				end if;

			when ST_SEND_HARDWARE_ADDRESS_LENGTH =>
				TX_Valid									<= '1';
				TX_Data										<= x"06";

				if (TX_Ack	 = '1') then
					NextState								<= ST_SEND_PROTOCOL_ADDRESS_LENGTH;
				end if;

			when ST_SEND_PROTOCOL_ADDRESS_LENGTH =>
				TX_Valid									<= '1';

				if (IsIPv4_l = '1') then
					TX_Data									<= x"04";
				elsif (IsIPv6_l = '1') then
					TX_Data									<= x"10";
				end if;

				if (TX_Ack	 = '1') then
					NextState								<= ST_SEND_OPERATION_0;
				end if;

			when ST_SEND_OPERATION_0 =>
				TX_Valid									<= '1';
				TX_Data										<= x"00";

				if (TX_Ack	 = '1') then
					NextState								<= ST_SEND_OPERATION_1;
				end if;

			when ST_SEND_OPERATION_1 =>
				TX_Valid									<= '1';
				TX_Data										<= x"02";

				Address_rst								<= '1';

				if (TX_Ack	 = '1') then
					NextState								<= ST_SEND_SENDER_MAC;
				end if;

			when ST_SEND_SENDER_MAC =>
				TX_Valid									<= '1';
				TX_Data										<= SenderMACAddress_Data;

				if (TX_Ack	 = '1') then
					SenderMACAddress_nxt		<= '1';
					Reader_Counter_en				<= '1';

					if (Reader_Counter_us = (HARDWARE_ADDRESS_LENGTH - 1)) then
						Reader_Counter_rst		<= '1';
						NextState							<= ST_SEND_SENDER_IP;
					end if;
				end if;

			when ST_SEND_SENDER_IP =>
				TX_Valid									<= '1';
				TX_Data										<= SenderIPv4Address_Data;

				if (TX_Ack	 = '1') then
					SenderIPv4Address_nxt		<= '1';
					Reader_Counter_en				<= '1';

					if ((IsIPv4_l = '1') and (Reader_Counter_us = (PROTOCOL_IPV4_ADDRESS_LENGTH - 1))) then
						Reader_Counter_rst		<= '1';
						NextState							<= ST_SEND_TARGET_MAC;
					elsif ((IsIPv6_l = '1') and (Reader_Counter_us = (PROTOCOL_IPV6_ADDRESS_LENGTH - 1))) then
						Reader_Counter_rst		<= '1';
						NextState							<= ST_SEND_TARGET_MAC;
					end if;
				end if;

			when ST_SEND_TARGET_MAC =>
				TX_Valid									<= '1';
				TX_Data										<= TargetMACAddress_Data;

				if (TX_Ack	 = '1') then
					TargetMACAddress_nxt		<= '1';
					Reader_Counter_en				<= '1';

					if (Reader_Counter_us = (HARDWARE_ADDRESS_LENGTH - 1)) then
						Reader_Counter_rst		<= '1';
						NextState							<= ST_SEND_TARGET_IP;
					end if;
				end if;

			when ST_SEND_TARGET_IP =>
				TX_Valid									<= '1';
				TX_Data										<= TargetIPv4Address_Data;

				if (TX_Ack	 = '1') then
					TargetIPv4Address_nxt		<= '1';
					Reader_Counter_en				<= '1';

					if ((IsIPv4_l = '1') and (Reader_Counter_us = (PROTOCOL_IPV4_ADDRESS_LENGTH - 1))) then
						TX_EOF								<= '1';
						Reader_Counter_rst		<= '1';
						NextState							<= ST_COMPLETE;
					elsif ((IsIPv6_l = '1') and (Reader_Counter_us = (PROTOCOL_IPV6_ADDRESS_LENGTH - 1))) then
						TX_EOF								<= '1';
						Reader_Counter_rst		<= '1';
						NextState							<= ST_COMPLETE;
					end if;
				end if;

			when ST_COMPLETE =>
				Complete									<= '1';
				NextState									<= ST_IDLE;

		end case;
	end process;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if ((Reset or Reader_Counter_rst) = '1') then
				Reader_Counter_us					<= (others => '0');
			elsif (Reader_Counter_en = '1') then
				Reader_Counter_us					<= Reader_Counter_us + 1;
			end if;
		end if;
	end process;

end architecture;
