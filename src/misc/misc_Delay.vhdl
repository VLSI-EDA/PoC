-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Entity:					TODO
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

library PoC;
use			PoC.utils.all;
use			PoC.vectors.all;


entity misc_Delay is
	generic (
		BITS					: positive;
		TAPS					: T_NATVEC					-- select one or multiple delay tap points
	);
	port (
		Clock					: in	std_logic;																					-- clock
		Reset					: in	std_logic		:= '0';																	-- reset; avoid reset to enable SRL16/SRL32 usage
		Enable				: in	std_logic		:= '1';																	-- enable
		DataIn				: in	std_logic_vector(BITS - 1 downto 0);								-- data to delay
		DataOut				: out	T_SLM(TAPS'length - 1 downto 0, BITS - 1 downto 0)	-- delayed ouputs, tapped at TAPS(i)
	);
end entity;


architecture rtl of misc_Delay is
	constant MAX_DELAY		: natural			:= imax(TAPS);

	type T_DELAY_VECTOR		is array (natural range <>) of std_logic_vector(BITS - 1 downto 0);

	signal Shifter_nxt		: T_DELAY_VECTOR(MAX_DELAY downto 0);
	signal Shifter_d			: T_DELAY_VECTOR(MAX_DELAY - 1 downto 0)									:= (others => (others => '0'));
	signal DataOut_i			: T_SLM(TAPS'length - 1 downto 0, BITS - 1 downto 0)	:= (others => (others => 'Z'));
begin

	Shifter_nxt		<= Shifter_d & DataIn;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Reset = '1') then
				Shifter_d		<= (others => (others => '0'));
			elsif (Enable = '1') then
				Shifter_d		<= Shifter_nxt(Shifter_d'range);
			end if;
		end if;
	end process;

	genTaps : for i in 0 to TAPS'length - 1 generate
		assign_row(DataOut_i, Shifter_nxt(TAPS(i)), i);
	end generate;

	DataOut		<= DataOut_i;
end;
