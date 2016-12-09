-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Entity:					Sorting Network: Streaming MergeSort
--
-- Description:
-- -------------------------------------
-- .. TODO:: No documentation available.
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
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
use			PoC.utils.all;
use			PoC.vectors.all;
use			PoC.components.all;


entity sortnet_MergeSort_Streamed is
	generic (
		FIFO_DEPTH	: positive		:= 32;
		KEY_BITS		: positive		:= 32;
		DATA_BITS		: positive		:= 32
	);
	port (
		Clock			: in	std_logic;
		Reset			: in	std_logic;

		Inverse		: in	std_logic			:= '0';

		In_Valid	: in	std_logic;
		In_Data		: in	std_logic_vector(DATA_BITS - 1 downto 0);
		In_SOF		: in	std_logic;
		In_IsKey	: in	std_logic;
		In_EOF		: in	std_logic;
		In_Ack		: out	std_logic;

		Out_Sync	: out	std_logic;
		Out_Valid	: out	std_logic;
		Out_Data	: out	std_logic_vector(DATA_BITS - 1 downto 0);
		Out_SOF		: out	std_logic;
		Out_IsKey	: out	std_logic;
		Out_EOF		: out	std_logic;
		Out_Ack		: in	std_logic
	);
end entity;


architecture rtl of sortnet_MergeSort_Streamed is

	constant DATA_SOF_BIT		: natural			:= DATA_BITS + 0;
	constant DATA_ISKEY_BIT	: natural			:= DATA_BITS + 1;
	constant DATA_EOF_BIT		: natural			:= DATA_BITS + 2;
	constant FIFO_BITS			: positive		:= DATA_BITS + 3;

	subtype	T_FIFO_DATA			is std_logic_vector(FIFO_BITS - 1 downto 0);

	signal FIFO_sel_r				: std_logic		:= '0';

	signal FIFO_0_put				: std_logic;
	signal FIFO_0_DataIn		: T_FIFO_DATA;
	signal FIFO_0_Full			: std_logic;
	signal FIFO_0_got				: std_logic;
	signal FIFO_0_DataOut		: T_FIFO_DATA;
	signal FIFO_0_Valid			: std_logic;

	signal FIFO_1_put				: std_logic;
	signal FIFO_1_DataIn		: T_FIFO_DATA;
	signal FIFO_1_Full			: std_logic;
	signal FIFO_1_got				: std_logic;
	signal FIFO_1_DataOut		: T_FIFO_DATA;
	signal FIFO_1_Valid			: std_logic;

	signal Greater					: std_logic;
	signal Switch_d					: std_logic;
	signal Switch_en				: std_logic;
	signal Switch_r					: std_logic		:= '0';
	signal Switch						: std_logic;

	type T_STATE is (ST_IDLE, ST_MERGE, ST_EMPTY_FIFO_0, ST_EMPTY_FIFO_1);
	signal State						: T_STATE			:= ST_IDLE;
	signal NextState				: T_STATE;

begin

	FIFO_sel_r		<= fftre(q => FIFO_sel_r, t => In_EOF, en => In_Valid, rst => Reset) when rising_edge(Clock);

	FIFO_0_put										<= In_Valid and not FIFO_sel_r;
	FIFO_0_DataIn(In_Data'range)	<= In_Data;
	FIFO_0_DataIn(DATA_SOF_BIT)		<= In_SOF;
	FIFO_0_DataIn(DATA_ISKEY_BIT)	<= In_IsKey;
	FIFO_0_DataIn(DATA_EOF_BIT)		<= In_EOF;

	FIFO_1_put										<= In_Valid and FIFO_sel_r;
	FIFO_1_DataIn(In_Data'range)	<= In_Data;
	FIFO_1_DataIn(DATA_SOF_BIT)		<= In_SOF;
	FIFO_1_DataIn(DATA_ISKEY_BIT)	<= In_IsKey;
	FIFO_1_DataIn(DATA_EOF_BIT)		<= In_EOF;

	In_Ack	<= not mux(FIFO_sel_r, FIFO_0_Full, FIFO_1_Full);

	FIFO_0 : entity PoC.fifo_cc_got
		generic map (
			D_BITS							=> FIFO_BITS,					-- Data Width
			MIN_DEPTH						=> FIFO_DEPTH,				-- Minimum FIFO Depth
			DATA_REG						=> FALSE,							-- Store Data Content in Registers
			STATE_REG						=> FALSE,							-- Registered Full/Empty Indicators
			OUTPUT_REG					=> FALSE							-- Registered FIFO Output
		)
		port map (
			-- Global Reset and Clock
			clk									=> Clock,
			rst									=> Reset,
			-- Writing Interface
			put									=> FIFO_0_put,
			din									=> FIFO_0_DataIn,
			full								=> FIFO_0_Full,
			-- Reading Interface
			got									=> FIFO_0_got,
			dout								=> FIFO_0_DataOut,
			valid								=> FIFO_0_Valid
		);

	FIFO_1 : entity PoC.fifo_cc_got
		generic map (
			D_BITS							=> FIFO_BITS,					-- Data Width
			MIN_DEPTH						=> FIFO_DEPTH,				-- Minimum FIFO Depth
			DATA_REG						=> FALSE,							-- Store Data Content in Registers
			STATE_REG						=> FALSE,							-- Registered Full/Empty Indicators
			OUTPUT_REG					=> FALSE							-- Registered FIFO Output
		)
		port map (
			-- Global Reset and Clock
			clk									=> Clock,
			rst									=> Reset,
			-- Writing Interface
			put									=> FIFO_1_put,
			din									=> FIFO_1_DataIn,
			full								=> FIFO_1_Full,
			-- Reading Interface
			got									=> FIFO_1_got,
			dout								=> FIFO_1_DataOut,
			valid								=> FIFO_1_Valid
		);

	-- assert (((FIFO_0_DataOut(DATA_ISKEY_BIT) /= FIFO_1_DataOut(DATA_ISKEY_BIT)) and (FIFO_0_Valid = '1') and (FIFO_1_Valid = '1')) = FALSE) report "Both FIFOs must have a IsKey mark at the same position." severity ERROR;

	Greater			<= to_sl(unsigned(FIFO_0_DataOut(KEY_BITS - 1 downto 0)) > unsigned(FIFO_1_DataOut(KEY_BITS - 1 downto 0)));
	Switch_d		<= Greater xor Inverse;
	Switch_r		<= ffdre(q => Switch_r, d => Switch_d, en => Switch_en) when rising_edge(Clock);
	Switch			<= mux(Switch_en, Switch_r, Switch_d);


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

	process(State, FIFO_0_Valid, FIFO_0_DataOut, FIFO_1_Valid, FIFO_1_DataOut, Switch, Out_Ack)
		variable IsKey				: std_logic;
		variable FIFO_0_SOF		: std_logic;
		variable FIFO_0_EOF		: std_logic;
		variable FIFO_1_SOF		: std_logic;
		variable FIFO_1_EOF		: std_logic;
	begin
		IsKey					:= FIFO_0_DataOut(DATA_ISKEY_BIT);
		FIFO_0_SOF		:= FIFO_0_DataOut(DATA_SOF_BIT);
		FIFO_0_EOF		:= FIFO_0_DataOut(DATA_EOF_BIT);
		FIFO_1_SOF		:= FIFO_1_DataOut(DATA_SOF_BIT);
		FIFO_1_EOF		:= FIFO_1_DataOut(DATA_EOF_BIT);

		NextState			<= State;

		FIFO_0_got		<= '0';
		FIFO_1_got		<= '0';

		Switch_en			<= '0';

		Out_Valid			<= '0';
		Out_IsKey			<= IsKey;
		Out_Data			<= FIFO_0_DataOut(DATA_BITS - 1 downto 0);
		Out_SOF				<= '0';
		Out_EOF				<= '0';

		case State is
			when ST_IDLE =>
				if ((FIFO_0_Valid and FIFO_1_Valid) = '1') then
					if ((FIFO_0_SOF and FIFO_1_SOF) = '1') then
						Switch_en			<= IsKey;
						Out_Valid			<= '1';
						Out_SOF				<= '1';

						if (Switch = '0') then
							FIFO_0_got	<= Out_Ack;
							Out_Data		<= FIFO_0_DataOut(DATA_BITS - 1 downto 0);
						else
							FIFO_1_got	<= Out_Ack;
							Out_Data		<= FIFO_1_DataOut(DATA_BITS - 1 downto 0);
						end if;

						NextState			<= ST_MERGE;
					else
						FIFO_0_got		<= not FIFO_0_SOF;
						FIFO_1_got		<= not FIFO_1_SOF;
					end if;
				elsif (FIFO_0_Valid = '1') then
					FIFO_0_got			<= not FIFO_0_SOF;
				elsif (FIFO_1_Valid = '1') then
					FIFO_1_got			<= not FIFO_1_SOF;
				end if;

			when ST_MERGE =>
				if ((FIFO_0_Valid and FIFO_1_Valid) = '1') then
					Switch_en				<= IsKey;

					Out_Valid				<= '1';
					if (Switch = '0') then
						FIFO_0_got		<= Out_Ack;
						Out_Data			<= FIFO_0_DataOut(DATA_BITS - 1 downto 0);
					else
						FIFO_1_got		<= Out_Ack;
						Out_Data			<= FIFO_1_DataOut(DATA_BITS - 1 downto 0);
					end if;

					if (FIFO_0_EOF = '1') then
						NextState			<= ST_EMPTY_FIFO_1;
					elsif (FIFO_1_EOF = '1') then
						NextState			<= ST_EMPTY_FIFO_0;
					end if;
				end if;

			when ST_EMPTY_FIFO_0 =>
				if (FIFO_0_Valid = '1') then
					FIFO_0_got			<= Out_Ack;
					Switch_en				<= IsKey;

					Out_Valid				<= '1';
					Out_Data				<= FIFO_0_DataOut(DATA_BITS - 1 downto 0);

					if (FIFO_0_EOF = '1') then
						Out_EOF				<= '1';
						NextState			<= ST_IDLE;
					end if;
				end if;

			when ST_EMPTY_FIFO_1 =>
				if (FIFO_1_Valid = '1') then
					FIFO_1_got			<= Out_Ack;
					Switch_en				<= IsKey;

					Out_Valid				<= '1';
					Out_Data				<= FIFO_1_DataOut(DATA_BITS - 1 downto 0);

					if (FIFO_1_EOF = '1') then
						Out_EOF				<= '1';
						NextState			<= ST_IDLE;
					end if;
				end if;

		end case;
	end process;

end architecture;
