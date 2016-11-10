-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Entity:					Sorting Network: Data structure transformation
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


entity sortnet_Transform is
	generic (
		ROWS				: positive		:= 16;
		COLUMNS			: positive		:= 4;
		DATA_BITS		: positive		:= 8
	);
	port (
		Clock			: in	std_logic;
		Reset			: in	std_logic;

		In_Valid	: in	std_logic;
		In_Data		: in	T_SLM(ROWS - 1 downto 0, DATA_BITS - 1 downto 0);
		In_SOF		: in	std_logic;
		In_EOF		: in	std_logic;

		Out_Valid	: out	std_logic;
		Out_Data	: out	T_SLM(COLUMNS - 1 downto 0, DATA_BITS - 1 downto 0);
		Out_SOF		: out	std_logic;
		Out_EOF		: out	std_logic
	);
end entity;


architecture rtl of sortnet_Transform is

	subtype	T_DATA					is std_logic_vector(DATA_BITS - 1 downto 0);
	type		T_DATA_VECTOR		is array(natural range <>) of T_DATA;
	type		T_DATA_MATRIX		is array(natural range <>) of T_DATA_VECTOR(ROWS - 1 downto 0);

	function to_dv(slm : T_SLM) return T_DATA_VECTOR is
		variable Result	: T_DATA_VECTOR(slm'range(1));
	begin
		for i in slm'range(1) loop
			for j in slm'high(2) downto slm'low(2) loop
				Result(i)(j)	:= slm(i, j);
			end loop;
		end loop;
		return Result;
	end function;

	signal DataIn				: T_DATA_VECTOR(ROWS - 1 downto 0);

	signal ColumnWriter_rst		: std_logic;
	signal ColumnWriter_us		: unsigned(log2ceilnz(COLUMNS) - 1 downto 0)	:= (others => '0');
	signal ColumnWriter_ov		: std_logic;

	signal InputBuffer				: T_DATA_MATRIX(COLUMNS - 1 downto 0)					:= (others => (others => (others => '0')));

	signal RowReader_en_r			: std_logic																		:= '0';

	signal RowReader_rst			: std_logic;
	signal RowReader_en				: std_logic;
	signal RowReader_us				: unsigned(log2ceilnz(ROWS) - 1 downto 0)			:= (others => '0');
	signal RowReader_ov				: std_logic;
begin

	DataIn	<= to_dv(In_Data);

	ColumnWriter_rst	<= ColumnWriter_ov and In_Valid;	-- or In_Sync;
	ColumnWriter_us		<= upcounter_next(cnt => ColumnWriter_us, rst => ColumnWriter_rst, en => In_Valid) when rising_edge(Clock);
	ColumnWriter_ov		<= upcounter_equal(cnt => ColumnWriter_us, value => COLUMNS - 1);

	process(Clock)
	begin
		if rising_edge(Clock) then
			if (In_Valid = '1') then
				for i in 0 to ROWS - 1 loop
					InputBuffer(to_index(ColumnWriter_us, COLUMNS - 1))(i)	<= DataIn(i);
				end loop;
			end if;
		end if;
	end process;

	RowReader_en_r	<= ffrs(q => RowReader_en_r, set => (ColumnWriter_ov and In_Valid), rst => RowReader_ov) when rising_edge(Clock);

	RowReader_rst		<= ColumnWriter_ov and RowReader_ov;	-- or In_Sync;
	RowReader_en		<= RowReader_en_r;
	RowReader_us		<= upcounter_next(cnt => RowReader_us, rst => RowReader_rst, en => RowReader_en) when rising_edge(Clock);
	RowReader_ov		<= upcounter_equal(cnt => RowReader_us, value => ROWS - 1);

	process(InputBuffer, RowReader_us)
	begin
		for i in 0 to COLUMNS - 1 loop
			for j in 0 to DATA_BITS - 1 loop
				Out_Data(i, j)		<= InputBuffer(i)(to_index(RowReader_us, ROWS - 1))(j);
			end loop;
		end loop;
	end process;

	Out_Valid		<= RowReader_en;
	Out_SOF			<= to_sl(RowReader_us = 0);
	Out_EOF			<= RowReader_ov;

end architecture;
