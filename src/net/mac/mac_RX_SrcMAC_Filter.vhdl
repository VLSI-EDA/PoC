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


entity mac_RX_SrcMAC_Filter is
	generic (
		DEBUG													: boolean													:= FALSE;
		MAC_ADDRESSES									: T_NET_MAC_ADDRESS_VECTOR				:= (0 => C_NET_MAC_ADDRESS_EMPTY);
		MAC_ADDRESSE_MASKS						: T_NET_MAC_ADDRESS_VECTOR				:= (0 => C_NET_MAC_MASK_DEFAULT)
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
		Out_Ack												: in	std_logic;
		Out_Meta_rst									: in	std_logic;
		Out_Meta_DestMACAddress_nxt		: in	std_logic;
		Out_Meta_DestMACAddress_Data	: out	T_SLV_8;
		Out_Meta_SrcMACAddress_nxt		: in	std_logic;
		Out_Meta_SrcMACAddress_Data		: out	T_SLV_8
	);
end entity;


architecture rtl of mac_RX_SrcMAC_Filter is
	attribute FSM_ENCODING					: string;

	constant PATTERN_COUNT					: positive																					:= MAC_ADDRESSES'length;
	constant MAC_ADDRESSES_I				: T_NET_MAC_ADDRESS_VECTOR(0 to PATTERN_COUNT - 1)	:= MAC_ADDRESSES;
	constant MAC_ADDRESSE_MASKS_I		: T_NET_MAC_ADDRESS_VECTOR(0 to PATTERN_COUNT - 1)	:= MAC_ADDRESSE_MASKS;

	type T_STATE is (
		ST_IDLE,
			ST_SRC_MAC_1,
			ST_SRC_MAC_2,
			ST_SRC_MAC_3,
			ST_SRC_MAC_4,
			ST_SRC_MAC_5,
			ST_PAYLOAD_1,
			ST_PAYLOAD_N,
		ST_DISCARD_FRAME
	);

	subtype T_MAC_BYTEINDEX	 is natural range 0 to 5;

	signal State												: T_STATE																	:= ST_IDLE;
	signal NextState										: T_STATE;
	attribute FSM_ENCODING of State			: signal is ite(DEBUG, "gray", ite((VENDOR = VENDOR_XILINX), "auto", "default"));

	signal In_Ack_i											: std_logic;
	signal Is_DataFlow									: std_logic;
	signal Is_SOF												: std_logic;
	signal Is_EOF												: std_logic;

	signal New_Valid_i									: std_logic;
	signal New_SOF_i										: std_logic;
	signal Out_Ack_i										: std_logic;

	signal MAC_ByteIndex								: T_MAC_BYTEINDEX;

	signal CompareRegister_rst					: std_logic;
	signal CompareRegister_init					: std_logic;
	signal CompareRegister_clear				: std_logic;
	signal CompareRegister_en						: std_logic;
	signal CompareRegister_d						: std_logic_vector(PATTERN_COUNT - 1 downto 0)		:= (others => '1');
	signal NoHits												: std_logic;

	signal SourceMACAddress_rst					: std_logic;
	signal SourceMACAddress_en					: std_logic;
	signal SourceMACAddress_sel					: T_MAC_BYTEINDEX;
	signal SourceMACAddress_d						: T_NET_MAC_ADDRESS																:= C_NET_MAC_ADDRESS_EMPTY;

	constant MAC_ADDRESS_LENGTH					: positive																				:= 6;			-- MAC -> 6 bytes
	constant READER_COUNTER_BITS				: positive																				:= log2ceilnz(MAC_ADDRESS_LENGTH);

	signal Reader_Counter_rst						: std_logic;
	signal Reader_Counter_en						: std_logic;
	signal Reader_Counter_us						: unsigned(READER_COUNTER_BITS - 1 downto 0)			:= (others => '0');

	signal Out_Meta_rst_i								: std_logic;
	signal Out_Meta_SrcMACAddress_nxt_i	: std_logic;

begin
	assert FALSE report "RX_SrcMAC_Filter:  patterns=" & integer'image(PATTERN_COUNT)			severity NOTE;

	In_Ack				<= In_Ack_i;
	Is_DataFlow		<= In_Valid and In_Ack_i;
	Is_SOF				<= In_Valid and In_SOF;
	Is_EOF				<= In_Valid and In_EOF;


	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Reset = '1') then
				State		<= ST_IDLE;
			else
				State		<= NextState;
			end if;
		end if;
	end process;

	process(State, Is_DataFlow, Is_SOF, Is_EOF, In_Valid, NoHits, Out_Ack_i)
	begin
		NextState										<= State;

		In_Ack_i										<= '0';

		New_Valid_i									<= '0';
		New_SOF_i										<= '0';

		CompareRegister_en					<= '0';
		CompareRegister_rst					<= '0';
		CompareRegister_init				<= Is_SOF;
		CompareRegister_clear				<= Is_EOF;

		SourceMACAddress_rst				<= Is_EOF;
		SourceMACAddress_en					<= Is_SOF;

		MAC_ByteIndex								<= 0;

		case State is
			when ST_IDLE =>
				MAC_ByteIndex						<= 5;

				if (Is_SOF = '1') then
					In_Ack_i							<= '1';

					if (Is_EOF = '0') then
						NextState						<= ST_SRC_MAC_1;
					else
						NextState						<= ST_IDLE;
					end if;
				end if;

			when ST_SRC_MAC_1 =>
				MAC_ByteIndex						<= 4;
				CompareRegister_en			<= In_Valid;
				SourceMACAddress_en			<= In_Valid;

				if (In_Valid = '1') then
					In_Ack_i							<= '1';

					if (Is_EOF = '0') then
						NextState						<= ST_SRC_MAC_2;
					else
						NextState						<= ST_IDLE;
					end if;
				end if;

			when ST_SRC_MAC_2 =>
				MAC_ByteIndex						<= 3;
				CompareRegister_en			<= In_Valid;
				SourceMACAddress_en			<= In_Valid;

				if (In_Valid = '1') then
					In_Ack_i							<= '1';

					if (Is_EOF = '0') then
						NextState						<= ST_SRC_MAC_3;
					else
						NextState						<= ST_IDLE;
					end if;
				end if;

			when ST_SRC_MAC_3 =>
				MAC_ByteIndex						<= 2;
				CompareRegister_en			<= In_Valid;
				SourceMACAddress_en			<= In_Valid;

				if (In_Valid = '1') then
					In_Ack_i							<= '1';

					if (Is_EOF = '0') then
						NextState						<= ST_SRC_MAC_4;
					else
						NextState						<= ST_IDLE;
					end if;
				end if;

			when ST_SRC_MAC_4 =>
				MAC_ByteIndex						<= 1;
				CompareRegister_en			<= In_Valid;
				SourceMACAddress_en			<= In_Valid;

				if (In_Valid = '1') then
					In_Ack_i							<= '1';

					if (Is_EOF = '0') then
						NextState						<= ST_SRC_MAC_5;
					else
						NextState						<= ST_IDLE;
					end if;
				end if;

			when ST_SRC_MAC_5 =>
				MAC_ByteIndex						<= 0;
				CompareRegister_en			<= In_Valid;
				SourceMACAddress_en			<= In_Valid;

				if (In_Valid = '1') then
					In_Ack_i							<= '1';

					if (Is_EOF = '0') then
						NextState						<= ST_PAYLOAD_1;
					else
						NextState						<= ST_IDLE;
					end if;
				end if;

			when ST_PAYLOAD_1 =>
				if (NoHits = '1') then
					if (Is_EOF = '0') then
						In_Ack_i						<= '1';
						NextState						<= ST_DISCARD_FRAME;
					else
						NextState						<= ST_IDLE;
					end if;
				else
					In_Ack_i							<= Out_Ack_i;
					New_Valid_i						<= In_Valid;
					New_SOF_i							<= '1';

					if (Is_DataFlow = '1') then
						if (Is_EOF = '0') then
							NextState					<= ST_PAYLOAD_N;
						else
							NextState					<= ST_IDLE;
						end if;
					end if;
				end if;

			when ST_PAYLOAD_N =>
				In_Ack_i								<= Out_Ack_i;
				New_Valid_i							<= In_Valid;

				if ((Is_DataFlow and Is_EOF) = '1') then
					NextState							<= ST_IDLE;
				end if;

			when ST_DISCARD_FRAME =>
				In_Ack_i								<= '1';

				if ((Is_DataFlow and Is_EOF) = '1') then
					NextState							<= ST_IDLE;
				end if;

		end case;
	end process;


	gen0 : for i in 0 to PATTERN_COUNT - 1 generate
		signal Hit								: std_logic;
	begin
		Hit <= to_sl((In_Data and MAC_ADDRESSE_MASKS_I(i)(MAC_ByteIndex)) = (MAC_ADDRESSES_I(i)(MAC_ByteIndex) and MAC_ADDRESSE_MASKS_I(i)(MAC_ByteIndex)));

		process(Clock)
		begin
			if rising_edge(Clock) then
				if ((Reset or CompareRegister_rst) = '1') then
					CompareRegister_d(i)			<= '0';
				elsif (CompareRegister_init	= '1') then
					CompareRegister_d(i)			<= Hit;
				elsif (CompareRegister_clear	= '1') then
					CompareRegister_d(i)			<= '0';
				elsif (CompareRegister_en  = '1') then
					CompareRegister_d(i)			<= CompareRegister_d(i) and Hit;
				end if;
			end if;
		end process;
	end generate;

	NoHits										<= slv_nor(CompareRegister_d);

	SourceMACAddress_sel			<= MAC_ByteIndex;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if ((Reset or SourceMACAddress_rst) = '1') then
				SourceMACAddress_d												<= C_NET_MAC_ADDRESS_EMPTY;
			elsif (SourceMACAddress_en = '1') then
				SourceMACAddress_d(SourceMACAddress_sel)	<= In_Data;
			end if;
		end if;
	end process;

	Reader_Counter_rst	<= Out_Meta_rst_i;
	Reader_Counter_en		<= Out_Meta_SrcMACAddress_nxt_i;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if ((Reset or Reader_Counter_rst) = '1') then
				Reader_Counter_us				<= to_unsigned(T_MAC_BYTEINDEX'high, Reader_Counter_us'length);
			elsif (Reader_Counter_en = '1') then
				Reader_Counter_us				<= Reader_Counter_us - 1;
			end if;
		end if;
	end process;

	Out_Valid											<= New_Valid_i;
	Out_Data											<= In_Data;
	Out_SOF												<= New_SOF_i;
	Out_EOF												<= In_EOF;
	Out_Ack_i											<= Out_Ack;

	-- Meta: rst
	Out_Meta_rst_i								<= Out_Meta_rst;
	In_Meta_rst										<= Out_Meta_rst_i;

	-- Meta: DestMACAddress
	In_Meta_DestMACAddress_nxt		<= Out_Meta_DestMACAddress_nxt;
	Out_Meta_DestMACAddress_Data	<= In_Meta_DestMACAddress_Data;

	-- Meta: SrcMACAddress
	Out_Meta_SrcMACAddress_nxt_i	<= Out_Meta_SrcMACAddress_nxt;
	Out_Meta_SrcMACAddress_Data		<= SourceMACAddress_d(to_index(Reader_Counter_us, SourceMACAddress_d'high));

end architecture;
