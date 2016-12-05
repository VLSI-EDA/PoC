-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Entity:					Computes the overall average value of all data words
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
use     PoC.arith.all;


entity stat_Average is
	generic (
		DATA_BITS			: positive		:= 8;
		COUNTER_BITS	: positive		:= 16
	);
	port (
		Clock					: in	std_logic;
		Reset					: in	std_logic;

		Enable				: in	std_logic;
		DataIn				: in	std_logic_vector(DATA_BITS - 1 downto 0);

		Count					: out	std_logic_vector(COUNTER_BITS - 1 downto 0);
		Sum						: out	std_logic_vector(COUNTER_BITS - 1 downto 0);
		Average				: out	std_logic_vector(COUNTER_BITS - 1 downto 0);
		Valid					: out	std_logic
	);
end entity;


architecture rtl of stat_Average is
	signal DataIn_us	: unsigned(DataIn'range);

	signal Counter_i	: std_logic_vector(COUNTER_BITS - 1 downto 0);
	signal Counter_us	: unsigned(COUNTER_BITS - 1 downto 0)						:= (others => '0');

	signal Sum_i			: std_logic_vector(COUNTER_BITS - 1 downto 0);
	signal Sum_us			: unsigned(COUNTER_BITS - 1 downto 0)						:= (others => '0');

	signal Quotient		: std_logic_vector(COUNTER_BITS - 1 downto 0);
	signal Valid_i		: std_logic;

	type T_SUM_VECTOR		is array(natural range <>) of std_logic_vector(COUNTER_BITS - 1 downto 0);
	type T_COUNT_VECTOR	is array(natural range <>) of std_logic_vector(COUNTER_BITS - 1 downto 0);

	constant DELAY		: positive		:= COUNTER_BITS - 1;

	signal Count_d		: T_COUNT_VECTOR(DELAY downto 0)		:= (others => (others => '0'));
	signal Sum_d			: T_SUM_VECTOR(DELAY downto 0)			:= (others => (others => '0'));
--	signal Valid_d		: STD_LOGIC_VECTOR(DELAY downto 0)	:= (others => '0');

begin
	DataIn_us		<= unsigned(DataIn);

	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Reset = '1') then
				Counter_us		<= (others => '0');
				Sum_us				<= (others => '0');
			elsif (Enable = '1') then
				Counter_us		<= Counter_us + 1;
				Sum_us				<= Sum_us + resize(DataIn_us, Sum_us'length);
			end if;
		end if;
	end process;

	Counter_i	<= std_logic_vector(Counter_us);
	Sum_i			<= std_logic_vector(Sum_us);

  div : entity PoC.arith_div
    generic map (
      A_BITS             => COUNTER_BITS,
      D_BITS             => COUNTER_BITS,
      PIPELINED          => true
    )
    port map (
      clk =>		Clock,
      rst =>		Reset,

      start =>	Enable,
      ready =>	Valid_i,

      A =>			Sum_i,
      D =>			Counter_i,
      Q =>			Quotient,
      R =>			open,
      Z =>			open
    );

	Count_d		<= Count_d(Count_d'high - 1 downto 0) & Counter_i	when rising_edge(Clock);
	Sum_d			<= Sum_d(Sum_d'high - 1 downto 0) & Sum_i					when rising_edge(Clock);
--	Valid_d		<= Valid_d(Valid_d'high - 1 downto 0) & Enable		when rising_edge(Clock);

	Count			<= Count_d(Count_d'high);
	Sum				<= Sum_d(Sum_d'high);
	Average		<= Quotient;
	Valid			<= Valid_i;	--_d(Valid_d'high);
end architecture;
