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


entity mac_TX_DestMAC_Prepender is
	generic (
		DEBUG													: boolean													:= FALSE
	);
	port (
		Clock													: in	std_logic;
		Reset													: in	std_logic;

		In_Valid											: in	std_logic;
		In_Data												: in	T_SLV_8;
		In_SOF												: in	std_logic;
		In_EOF												: in	std_logic;
		In_Ack												: out	std_logic;
		In_Meta_rst										: out	std_logic;
		In_Meta_DestMACAddress_nxt		: out	std_logic;
		In_Meta_DestMACAddress_Data		: in	T_SLV_8;

		Out_Valid											: out	std_logic;
		Out_Data											: out	T_SLV_8;
		Out_SOF												: out	std_logic;
		Out_EOF												: out	std_logic;
		Out_Ack												: in	std_logic
	);
end entity;


architecture rtl of mac_TX_DestMAC_Prepender is
	attribute FSM_ENCODING					: string;

	type T_STATE is (
		ST_IDLE,
			ST_PREPEND_DEST_MAC_1,
			ST_PREPEND_DEST_MAC_2,
			ST_PREPEND_DEST_MAC_3,
			ST_PREPEND_DEST_MAC_4,
			ST_PREPEND_DEST_MAC_5,
			ST_PAYLOAD
	);

	signal State										: T_STATE							:= ST_IDLE;
	signal NextState								: T_STATE;
	attribute FSM_ENCODING of State	: signal is ite(DEBUG, "gray", ite((VENDOR = VENDOR_XILINX), "auto", "default"));

	signal Is_DataFlow							: std_logic;
	signal Is_SOF										: std_logic;
	signal Is_EOF										: std_logic;

begin

	Is_DataFlow		<= In_Valid and Out_Ack;
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

	process(State, In_Valid, In_Data, In_EOF, Is_DataFlow, Is_SOF, Is_EOF, Out_Ack, In_Meta_DestMACAddress_Data)
	begin
		NextState										<= State;

		Out_Valid										<= '0';
		Out_Data										<= In_Data;
		Out_SOF											<= '0';
		Out_EOF											<= '0';

		In_Ack											<= '0';
		In_Meta_rst									<= '0';
--		In_Meta_DestMACAddress_rev	<= '1';					-- read destination MAC address in Big-Endian order
		In_Meta_DestMACAddress_nxt	<= '0';

		case State is
			when ST_IDLE =>
				In_Meta_rst											<= '1';
				Out_Data												<= In_Meta_DestMACAddress_Data;

				if (Is_SOF = '1') then
					In_Meta_rst										<= '0';
					In_Meta_DestMACAddress_nxt		<= Out_Ack;

					Out_Valid											<= '1';
					Out_SOF												<= '1';

					if (Out_Ack	 = '1') then
						NextState										<= ST_PREPEND_DEST_MAC_1;
					end if;
				end if;

			when ST_PREPEND_DEST_MAC_1 =>
				In_Meta_DestMACAddress_nxt			<= Out_Ack;

				Out_Valid												<= '1';
				Out_Data												<= In_Meta_DestMACAddress_Data;

				if (Out_Ack	 = '1') then
					NextState											<= ST_PREPEND_DEST_MAC_2;
				end if;

			when ST_PREPEND_DEST_MAC_2 =>
				In_Meta_DestMACAddress_nxt			<= Out_Ack;

				Out_Valid												<= '1';
				Out_Data												<= In_Meta_DestMACAddress_Data;

				if (Out_Ack	 = '1') then
					NextState											<= ST_PREPEND_DEST_MAC_3;
				end if;

			when ST_PREPEND_DEST_MAC_3 =>
				In_Meta_DestMACAddress_nxt			<= Out_Ack;

				Out_Valid												<= '1';
				Out_Data												<= In_Meta_DestMACAddress_Data;

				if (Out_Ack	 = '1') then
					NextState											<= ST_PREPEND_DEST_MAC_4;
				end if;

			when ST_PREPEND_DEST_MAC_4 =>
				In_Meta_DestMACAddress_nxt			<= Out_Ack;

				Out_Valid												<= '1';
				Out_Data												<= In_Meta_DestMACAddress_Data;

				if (Out_Ack	 = '1') then
					NextState											<= ST_PREPEND_DEST_MAC_5;
				end if;

			when ST_PREPEND_DEST_MAC_5 =>
				In_Meta_DestMACAddress_nxt			<= Out_Ack;

				Out_Valid												<= '1';
				Out_Data												<= In_Meta_DestMACAddress_Data;

				if (Out_Ack	 = '1') then
					NextState											<= ST_PAYLOAD;
				end if;

			when ST_PAYLOAD =>
				In_Ack													<= Out_Ack;

				Out_Valid												<= In_Valid;
				Out_EOF													<= In_EOF;

				if ((Is_DataFlow and Is_EOF) = '1') then
					NextState											<= ST_IDLE;
				end if;

		end case;
	end process;

end architecture;
