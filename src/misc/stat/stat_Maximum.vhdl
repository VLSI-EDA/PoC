-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Module:					Counts the most significant data words
--
-- Description:
-- ------------------------------------
--		TODO
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
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
-- =============================================================================

library	IEEE;
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;

library	PoC;
use			PoC.utils.all;
use			PoC.vectors.all;


entity stat_Maximum is
	generic (
		DEPTH					: POSITIVE		:= 8;
		DATA_BITS			: POSITIVE		:= 16;
		COUNTER_BITS	: POSITIVE		:= 16
	);
	port (
		Clock					: in	STD_LOGIC;
		Reset					: in	STD_LOGIC;

		Enable				: in	STD_LOGIC;
		DataIn				: in	STD_LOGIC_VECTOR(DATA_BITS - 1 downto 0);

		Valids				: out	STD_LOGIC_VECTOR(DEPTH - 1 downto 0);
		Maximums			: out	T_SLM(DEPTH - 1 downto 0, DATA_BITS - 1 downto 0);
		Counts				: out	T_SLM(DEPTH - 1 downto 0, COUNTER_BITS - 1 downto 0)
	);
end entity;


architecture rtl of stat_Maximum is
	type T_TAG_MEMORY				is array(NATURAL range <>) of UNSIGNED(DATA_BITS - 1 downto 0);
	type T_COUNTER_MEMORY		is array(NATURAL range <>) of UNSIGNED(COUNTER_BITS - 1 downto 0);

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

	signal DataIn_us				: UNSIGNED(DataIn'range);

	signal TagHit						: STD_LOGIC_VECTOR(DEPTH - 1 downto 0);
	signal MaximumHit				: STD_LOGIC_VECTOR(DEPTH - 1 downto 0);
	signal TagMemory				: T_TAG_MEMORY(DEPTH - 1 downto 0)			:= (others => (others => '0'));
	signal CounterMemory		: T_COUNTER_MEMORY(DEPTH - 1 downto 0)	:= (others => (others => '0'));
	signal MaximumIndex			: STD_LOGIC_VECTOR(DEPTH - 1 downto 0)	:= '1' & (DEPTH - 2 downto 0 => '0');	--((DEPTH - 1) => '1', others => '0'); -- WORKAROUND: GHDL says  not static choice exclude others choice;  non-locally static choice for an aggregate is allowed only if only choice
	signal ValidMemory			: STD_LOGIC_VECTOR(DEPTH - 1 downto 0)	:= (others => '0');

begin
	DataIn_us		<= unsigned(DataIn);

	genTagHit : for i in 0 to DEPTH - 1 generate
		TagHit(i)			<= to_sl(TagMemory(i) = DataIn_us);
		MaximumHit(i)	<= to_sl(TagMemory(i) < DataIn_us);
	end generate;

	process(Clock)
		variable TagHit_idx 			: NATURAL;
	begin
		if rising_edge(Clock) then
			if (Reset = '1') then
				ValidMemory										<= (others => '0');
			elsif ((slv_nand(ValidMemory) and slv_nor(TagHit) and Enable) = '1') then
				for i in DEPTH - 1 downto 1 loop
					if (MaximumHit(i) = '1') then
						TagMemory(i)			<= TagMemory(i - 1);
						ValidMemory(i)		<= ValidMemory(i - 1);
						CounterMemory(i)	<= CounterMemory(i - 1);
					end if;
				end loop;
				for i in 0 to DEPTH - 1 loop
					if (MaximumHit(i) = '1') then
						TagMemory(i)			<= DataIn_us;
						ValidMemory(i)		<= '1';
						CounterMemory(i)	<= to_unsigned(1, COUNTER_BITS);
						exit;
					end if;
				end loop;
			elsif ((slv_or(MaximumHit) and slv_nor(TagHit) and Enable) = '1') then
				for i in DEPTH - 1 downto 1 loop
					if (MaximumHit(i) = '1') then
						TagMemory(i)			<= TagMemory(i - 1);
						ValidMemory(i)		<= ValidMemory(i - 1);
						CounterMemory(i)	<= CounterMemory(i - 1);
					end if;
				end loop;
				for i in 0 to DEPTH - 1 loop
					if (MaximumHit(i) = '1') then
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
	Maximums	<= to_slm(TagMemory);
	Counts		<= to_slm(CounterMemory);

end architecture;
