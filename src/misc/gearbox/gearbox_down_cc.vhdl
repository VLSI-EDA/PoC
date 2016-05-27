-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- ============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Module:				 	A downscaling gearbox module with a common clock (cc) interface.
--
-- Description:
-- ------------------------------------
--	This module provides a downscaling gearbox with a common clock (cc)
--	interface. It perfoems a 'word' to 'byte' splitting. The default order is
--	LITTLE_ENDIAN (starting at byte(0)). Input "In_Data" and output "Out_Data"
--	are of the same clock domain "Clock". Optional input and output registers
--	can be added by enabling (ADD_***PUT_REGISTERS = TRUE).
--
-- License:
-- ============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany
--										 Chair for VLSI-Design, Diagnostics and Architecture
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
-- ============================================================================

library IEEE;
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;

library PoC;
use			PoC.math.all;
use			PoC.utils.all;
use			PoC.vectors.all;
use			PoC.components.all;


entity gearbox_down_cc is
	generic (
		INPUT_BITS						: POSITIVE	:= 32;
		OUTPUT_BITS						: POSITIVE	:= 24;
		META_BITS							: NATURAL		:= 0;
		ADD_INPUT_REGISTERS		: BOOLEAN		:= FALSE;
		ADD_OUTPUT_REGISTERS	: BOOLEAN		:= FALSE
	);
	port (
		Clock				: in	STD_LOGIC;

		In_Sync			: in	STD_LOGIC;
		In_Valid		: in	STD_LOGIC;
		In_Next			: out	STD_LOGIC;
		In_Data			: in	STD_LOGIC_VECTOR(INPUT_BITS - 1 downto 0);
		In_Meta			: in	STD_LOGIC_VECTOR(META_BITS - 1 downto 0);

		Out_Sync		: out	STD_LOGIC;
		Out_Valid		: out	STD_LOGIC;
		Out_Data		: out	STD_LOGIC_VECTOR(OUTPUT_BITS - 1 downto 0);
		Out_Meta		: out	STD_LOGIC_VECTOR(META_BITS - 1 downto 0);
		Out_First		: out	STD_LOGIC;
		Out_Last		: out	STD_LOGIC
	);
end entity;


architecture rtl of gearbox_down_cc is
	constant C_VERBOSE				: BOOLEAN			:= FALSE;		--POC_VERBOSE;

	constant BITS_PER_CHUNK		: POSITIVE		:= greatestCommonDivisor(INPUT_BITS, OUTPUT_BITS);
	constant INPUT_CHUNKS			: POSITIVE		:= INPUT_BITS / BITS_PER_CHUNK;
	constant OUTPUT_CHUNKS		: POSITIVE		:= OUTPUT_BITS / BITS_PER_CHUNK;

	subtype T_CHUNK					is STD_LOGIC_VECTOR(BITS_PER_CHUNK - 1 downto 0);
	type T_CHUNK_VECTOR			is array(NATURAL range <>) of T_CHUNK;

	subtype T_MUX_INDEX			is INTEGER range 0 to INPUT_CHUNKS - 1;
	type T_MUX_INPUT is record
		Index			: T_MUX_INDEX;
		UseBuffer	: BOOLEAN;
	end record;

	type T_MUX_INPUT_LIST		is array(NATURAL range <>) of T_MUX_INPUT;
	type T_MUX_INPUT_STRUCT is record
		List		: T_MUX_INPUT_LIST(0 to OUTPUT_CHUNKS - 1);
		Reg_en	: STD_LOGIC;
		Nxt			: STD_LOGIC;
		First		: STD_LOGIC;
		Last		: STD_LOGIC;
	end record;
	type T_MUX_DESCRIPTIONS		is array(NATURAL range <>) of T_MUX_INPUT_STRUCT;

	function genMuxDescription return T_MUX_DESCRIPTIONS is
		variable DESC				: T_MUX_DESCRIPTIONS(0 to INPUT_CHUNKS - 1);
		variable UseBuffer	: BOOLEAN;
		variable k					: T_MUX_INDEX;
	begin
		if (C_VERBOSE = TRUE) then		report "genMuxDescription: IC=" & INTEGER'image(INPUT_CHUNKS) severity NOTE;		end if;

		k := INPUT_CHUNKS - 1;
		for i in 0 to INPUT_CHUNKS - 1 loop
			if (C_VERBOSE = TRUE) then		report "  i: " & INTEGER'image(i) & "  List:" severity NOTE;		end if;
			UseBuffer					:= TRUE;
			for j in 0 to OUTPUT_CHUNKS - 1 loop
				k													:= (k + 1) mod INPUT_CHUNKS;
				UseBuffer									:= UseBuffer and (k /= 0);
				DESC(i).List(j).Index			:= k;
				DESC(i).List(j).UseBuffer	:= UseBuffer;

				if (C_VERBOSE = TRUE) then		report "    j= " & INTEGER'image(j) & "  k=" & INTEGER'image(DESC(i).List(j).Index) severity NOTE;		end if;
			end loop;
			DESC(i).Reg_en		:= to_sl(not UseBuffer);
			DESC(i).Nxt				:= to_sl(k + OUTPUT_CHUNKS >= INPUT_CHUNKS);
			DESC(i).First			:= to_sl(i = 0);
			DESC(i).Last			:= to_sl(i = INPUT_CHUNKS - 1);

			if (C_VERBOSE = TRUE) then		report "    en=" & STD_LOGIC'image(DESC(i).Reg_en) & "  nxt=" & STD_LOGIC'image(DESC(i).Nxt) severity NOTE;		end if;
		end loop;
		return DESC;
	end function;

	constant MUX_INPUT_TRANSLATION		: T_MUX_DESCRIPTIONS		:= genMuxDescription;

	-- create vector-vector from vector (4 bit)
	function to_chunkv(slv : STD_LOGIC_VECTOR) return T_CHUNK_VECTOR is
		constant CHUNKS		: POSITIVE		:= slv'length / BITS_PER_CHUNK;
		variable Result		: T_CHUNK_VECTOR(CHUNKS - 1 downto 0);
	begin
		if ((slv'length mod BITS_PER_CHUNK) /= 0) then	report "to_chunkv: width mismatch - slv'length is no multiple of BITS_PER_CHUNK (slv'length=" & INTEGER'image(slv'length) & "; BITS_PER_CHUNK=" & INTEGER'image(BITS_PER_CHUNK) & ")" severity FAILURE;	end if;

		for i in 0 to CHUNKS - 1 loop
			Result(i)	:= slv(slv'low + ((i + 1) * BITS_PER_CHUNK) - 1 downto slv'low + (i * BITS_PER_CHUNK));
		end loop;
		return Result;
	end function;

	-- convert vector-vector to flatten vector
	function to_slv(slvv : T_CHUNK_VECTOR) return STD_LOGIC_VECTOR is
		variable slv			: STD_LOGIC_VECTOR((slvv'length * BITS_PER_CHUNK) - 1 downto 0);
	begin
		for i in slvv'range loop
			slv(((i + 1) * BITS_PER_CHUNK) - 1 downto (i * BITS_PER_CHUNK))		:= slvv(i);
		end loop;
		return slv;
	end function;

	signal In_Sync_d					: STD_LOGIC																					:= '0';
	signal In_Data_d					:	STD_LOGIC_VECTOR(INPUT_BITS - 1 downto 0)					:= (others => '0');
	signal In_Meta_d					:	STD_LOGIC_VECTOR(META_BITS - 1 downto 0)					:= (others => '0');
	signal In_Valid_d					: STD_LOGIC																					:= '0';

	signal MuxSelect_rst			: STD_LOGIC;
	signal MuxSelect_en				: STD_LOGIC;
	signal MuxSelect_us				: UNSIGNED(log2ceilnz(INPUT_CHUNKS) - 1 downto 0)	:= (others => '0');
	signal MuxSelect_ov				: STD_LOGIC;

	signal Nxt								: STD_LOGIC;
	signal AutoIncrement			: STD_LOGIC;

	signal GearBoxInput				: T_CHUNK_VECTOR(INPUT_CHUNKS - 1 downto 0);
	signal GearBoxBuffer_en		: STD_LOGIC;
	signal GearBoxBuffer			: T_CHUNK_VECTOR(INPUT_CHUNKS - 1 downto 1)				:= (others => (others => '0'));
	signal GearBoxOutput			: T_CHUNK_VECTOR(OUTPUT_CHUNKS - 1 downto 0);

	signal SyncOut						: STD_LOGIC;
	signal ValidOut						: STD_LOGIC;
	signal DataOut						:	STD_LOGIC_VECTOR(OUTPUT_BITS - 1 downto 0);
	signal MetaOut						:	STD_LOGIC_VECTOR(META_BITS - 1 downto 0);
	signal FirstOut						: STD_LOGIC;
	signal LastOut						: STD_LOGIC;

	signal Out_Sync_d					: STD_LOGIC																					:= '0';
	signal Out_Valid_d				: STD_LOGIC																					:= '0';
	signal Out_Data_d					:	STD_LOGIC_VECTOR(OUTPUT_BITS - 1 downto 0)				:= (others => '0');
	signal Out_Meta_d					:	STD_LOGIC_VECTOR(META_BITS - 1 downto 0)					:= (others => '0');
	signal Out_First_d				: STD_LOGIC																					:= '0';
	signal Out_Last_d					: STD_LOGIC																					:= '0';

begin
	assert (not C_VERBOSE)
		report "gearbox_down_cc:" & CR &
					 "  INPUT_BITS=" & INTEGER'image(INPUT_BITS) &
					 "  OUTPUT_BITS=" & INTEGER'image(OUTPUT_BITS) &
					 "  INPUT_CHUNKS=" & INTEGER'image(INPUT_CHUNKS) &
					 "  OUTPUT_CHUNKS=" & INTEGER'image(OUTPUT_CHUNKS) &
					 "  BITS_PER_CHUNK=" & INTEGER'image(BITS_PER_CHUNK)
		severity NOTE;
	assert (INPUT_BITS > OUTPUT_BITS)	report "OUTPUT_BITS must be less than INPUT_BITS, otherwise it's no down-sizing gearbox." severity FAILURE;

	In_Sync_d		<= In_Sync;--	when registered(Clock, ADD_INPUT_REGISTERS);
	In_Valid_d	<= In_Valid	when registered(Clock, ADD_INPUT_REGISTERS);
	In_Data_d		<= In_Data	when registered(Clock, ADD_INPUT_REGISTERS);
	In_Meta_d		<= In_Meta	when registered(Clock, ADD_INPUT_REGISTERS);

	GearBoxInput			<= to_chunkv(In_Data_d(INPUT_BITS - 1 downto 0));
	GearBoxBuffer_en	<= MUX_INPUT_TRANSLATION(to_index(MuxSelect_us, INPUT_CHUNKS)).Reg_en and In_Valid_d;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if (GearBoxBuffer_en = '1') then
				GearBoxBuffer		<= to_chunkv(In_Data_d(INPUT_BITS - 1 downto BITS_PER_CHUNK));
			end if;
		end if;
	end process;

	MuxSelect_rst		<= In_Sync_d or MuxSelect_ov;
	MuxSelect_en		<= In_Valid_d or MuxSelect_ov or AutoIncrement;
	MuxSelect_us		<= upcounter_next(cnt => MuxSelect_us, rst => MuxSelect_rst, en => MuxSelect_en) when rising_edge(Clock);
	MuxSelect_ov		<= upcounter_equal(cnt => MuxSelect_us, value => (INPUT_CHUNKS - 1));

	Nxt							<= MUX_INPUT_TRANSLATION(to_index(MuxSelect_us, INPUT_CHUNKS)).Nxt;
	AutoIncrement		<= not Nxt;

	In_Next					<= Nxt;

	-- generate gearbox multiplexer structure
	genMux : for j in 0 to OUTPUT_CHUNKS - 1 generate
		signal MuxInput		: T_CHUNK_VECTOR(INPUT_CHUNKS - 1 downto 0);
	begin
		genMuxInputs : for i in 0 to INPUT_CHUNKS - 1 generate
			assert (not C_VERBOSE)
				report "i= " & INTEGER'image(i) & " " &
							 "j= " & INTEGER'image(j) & " " &
							 "-> idx= " & INTEGER'image(MUX_INPUT_TRANSLATION(i).List(j).Index) & " " &
							 "-> useBuffer= " & BOOLEAN'image(MUX_INPUT_TRANSLATION(i).List(j).UseBuffer) & " " &
							 "-> Nxt= " & STD_LOGIC'image(MUX_INPUT_TRANSLATION(i).Nxt)
				severity NOTE;

			connectToInput : if (MUX_INPUT_TRANSLATION(i).List(j).UseBuffer = FALSE) generate
				MuxInput(i)	<= GearBoxInput(MUX_INPUT_TRANSLATION(i).List(j).Index);
			end generate;
			connectToBuffer : if (MUX_INPUT_TRANSLATION(i).List(j).UseBuffer = TRUE) generate
				MuxInput(i)	<= GearBoxBuffer(MUX_INPUT_TRANSLATION(i).List(j).Index);
			end generate;
		end generate;

		GearBoxOutput(j)	<= MuxInput(to_index(MuxSelect_us, INPUT_CHUNKS));
	end generate;

	SyncOut			<= MuxSelect_ov;
	ValidOut		<= In_Valid_d or MuxSelect_ov or AutoIncrement;
	DataOut			<= to_slv(GearBoxOutput);
	FirstOut		<= MUX_INPUT_TRANSLATION(to_index(MuxSelect_us, INPUT_CHUNKS)).First;
	LastOut			<= MUX_INPUT_TRANSLATION(to_index(MuxSelect_us, INPUT_CHUNKS)).Last;

	Out_Sync_d	<= SyncOut	when registered(Clock, ADD_OUTPUT_REGISTERS);
	Out_Valid_d	<= ValidOut	when registered(Clock, ADD_OUTPUT_REGISTERS);
	Out_Data_d	<= DataOut	when registered(Clock, ADD_OUTPUT_REGISTERS);
	Out_Meta_d	<= MetaOut	when registered(Clock, ADD_OUTPUT_REGISTERS);
	Out_First_d	<= FirstOut	when registered(Clock, ADD_OUTPUT_REGISTERS);
	Out_Last_d	<= LastOut	when registered(Clock, ADD_OUTPUT_REGISTERS);

	Out_Sync		<= Out_Sync_d;
	Out_Valid		<= Out_Valid_d;
	Out_Data		<= Out_Data_d;
	Out_Meta		<= Out_Meta_d;
	Out_First		<= Out_First_d;
	Out_Last		<= Out_Last_d;
end architecture;
