-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Entity:					Creates a histogram of all input data
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

library	IEEE;
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;

library	PoC;
use			PoC.utils.all;
use			PoC.vectors.all;


entity stat_Histogram is
	generic (
		DATA_BITS			: positive		:= 16;
		COUNTER_BITS	: positive		:= 16
	);
	port (
		Clock					: in	std_logic;
		Reset					: in	std_logic;

		Enable				: in	std_logic;
		DataIn				: in	std_logic_vector(DATA_BITS - 1 downto 0);

		Histogram			: out	T_SLM(2**DATA_BITS - 1 downto 0, COUNTER_BITS - 1 downto 0)
	);
end entity;


architecture rtl of stat_Histogram is
	type T_HISTOGRAM_MEMORY		is array(natural range <>) of unsigned(COUNTER_BITS downto 0);

	-- create matrix from vector-vector
	function to_slm(usv : T_HISTOGRAM_MEMORY) return T_SLM is
		variable slm		: T_SLM(usv'range, COUNTER_BITS - 1 downto 0);
	begin
		for i in usv'range loop
			if (usv(i)(COUNTER_BITS) = '0') then
				for j in COUNTER_BITS - 1 downto 0 loop
					slm(i, j)		:= usv(i)(j);
				end loop;
			else
				for j in COUNTER_BITS - 1 downto 0 loop
					slm(i, j)		:= '1';
				end loop;
			end if;
		end loop;
		return slm;
	end function;

	signal HistogramMemory		: T_HISTOGRAM_MEMORY(2**DATA_BITS - 1 downto 0)	:= (others => (others => '0'));

begin
	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Reset = '1') then
				HistogramMemory				<= (others => (others => '0'));
			elsif ((Enable = '1') and (HistogramMemory(to_index(DataIn))(COUNTER_BITS) = '0')) then
				HistogramMemory(to_index(DataIn))	<= HistogramMemory(to_index(DataIn)) + 1;
			end if;
		end if;
	end process;

	Histogram	<= to_slm(HistogramMemory);
end architecture;
