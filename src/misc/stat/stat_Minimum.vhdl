-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Entity:					Counts the least significant data words
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


entity stat_Minimum is
	generic (
		DEPTH					: positive		:= 8;
		DATA_BITS			: positive		:= 16;
		COUNTER_BITS	: positive		:= 16
	);
	port (
		Clock					: in	std_logic;
		Reset					: in	std_logic;

		Enable				: in	std_logic;
		DataIn				: in	std_logic_vector(DATA_BITS - 1 downto 0);

		Valids				: out	std_logic_vector(DEPTH - 1 downto 0);
		Minimums			: out	T_SLM(DEPTH - 1 downto 0, DATA_BITS - 1 downto 0);
		Counts				: out	T_SLM(DEPTH - 1 downto 0, COUNTER_BITS - 1 downto 0)
	);
end entity;


architecture rtl of stat_Minimum is
	type T_TAG_MEMORY				is array(natural range <>) of unsigned(DATA_BITS - 1 downto 0);
	type T_COUNTER_MEMORY		is array(natural range <>) of unsigned(COUNTER_BITS - 1 downto 0);

	-- create matrix from vector-vector
	function to_slm(usv : T_TAG_MEMORY) return T_SLM is
		variable slm		: T_SLM(usv'range, DATA_BITS - 1 downto 0);
	begin
		for i in usv'range loop
			for j in DATA_BITS - 1 downto 0 loop
				slm(i, j)		:= usv(i)(j);
			end loop;
		end loop;
		return slm;
	end function;

	function to_slm(usv : T_COUNTER_MEMORY) return T_SLM is
		variable slm		: T_SLM(usv'range, COUNTER_BITS - 1 downto 0);
	begin
		for i in usv'range loop
			for j in COUNTER_BITS - 1 downto 0 loop
				slm(i, j)		:= usv(i)(j);
			end loop;
		end loop;
		return slm;
	end function;

	signal DataIn_us				: unsigned(DataIn'range);

	signal TagHit						: std_logic_vector(DEPTH - 1 downto 0);
	signal MinimumHit				: std_logic_vector(DEPTH - 1 downto 0);
	signal TagMemory				: T_TAG_MEMORY(DEPTH - 1 downto 0)			:= (others => (others => '1'));
	signal CounterMemory		: T_COUNTER_MEMORY(DEPTH - 1 downto 0)	:= (others => (others => '0'));
	signal MinimumIndex			: std_logic_vector(DEPTH - 1 downto 0)	:= '1' & (DEPTH - 2 downto 0 => '0');	--((DEPTH - 1) => '1', others => '0'); -- WORKAROUND: GHDL says  not static choice exclude others choice;  non-locally static choice for an aggregate is allowed only if only choice
	signal ValidMemory			: std_logic_vector(DEPTH - 1 downto 0)	:= (others => '0');

begin
	DataIn_us		<= unsigned(DataIn);

	genTagHit : for i in 0 to DEPTH - 1 generate
		TagHit(i)			<= to_sl(TagMemory(i) = DataIn_us);
		MinimumHit(i)	<= to_sl(TagMemory(i) > DataIn_us);
	end generate;

	process(Clock)
		variable TagHit_idx 			: natural;
	begin
		if rising_edge(Clock) then
			if (Reset = '1') then
				ValidMemory										<= (others => '0');
			elsif ((slv_nand(ValidMemory) and slv_nor(TagHit) and Enable) = '1') then
				for i in DEPTH - 1 downto 1 loop
					if (MinimumHit(i) = '1') then
						TagMemory(i)			<= TagMemory(i - 1);
						ValidMemory(i)		<= ValidMemory(i - 1);
						CounterMemory(i)	<= CounterMemory(i - 1);
					end if;
				end loop;
				for i in 0 to DEPTH - 1 loop
					if (MinimumHit(i) = '1') then
						TagMemory(i)			<= DataIn_us;
						ValidMemory(i)		<= '1';
						CounterMemory(i)	<= to_unsigned(1, COUNTER_BITS);
						exit;
					end if;
				end loop;
			elsif ((slv_or(MinimumHit) and slv_nor(TagHit) and Enable) = '1') then
				for i in DEPTH - 1 downto 1 loop
					if (MinimumHit(i) = '1') then
						TagMemory(i)			<= TagMemory(i - 1);
						ValidMemory(i)		<= ValidMemory(i - 1);
						CounterMemory(i)	<= CounterMemory(i - 1);
					end if;
				end loop;
				for i in 0 to DEPTH - 1 loop
					if (MinimumHit(i) = '1') then
						TagMemory(i)			<= DataIn_us;
						ValidMemory(i)		<= '1';
						CounterMemory(i)	<= to_unsigned(1, COUNTER_BITS);
						exit;
					end if;
				end loop;
			elsif ((slv_or(TagHit) and Enable)= '1') then
				TagHit_idx								:= to_index(onehot2bin(TagHit, 0));
				CounterMemory(TagHit_idx)	<= CounterMemory(TagHit_idx) + 1;
			end if;
		end if;
	end process;

	Valids		<= ValidMemory;
	Minimums	<= to_slm(TagMemory);
	Counts		<= to_slm(CounterMemory);

end architecture;
