-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Entity:					Universal Barrel-Shifter
--
-- Description:
-- -------------------------------------
-- This Barrel-Shifter supports:
--
-- * shifting and rotating
-- * right and left operations
-- * arithmetic and logic mode (only valid for shift operations)
--
-- This is equivalent to the CPU instructions: SLL, SLA, SRL, SRA, RL, RR
--
-- License:
-- =============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany,
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


entity arith_shifter_barrel is
	generic (
		BITS				: positive		:= 32
	);
  port (
		Input						: in	std_logic_vector(BITS - 1 downto 0);
		ShiftAmount			: in	std_logic_vector(log2ceilnz(BITS) - 1 downto 0);
		ShiftRotate			: in	std_logic;
		LeftRight				: in	std_logic;
		ArithmeticLogic	: in	std_logic;
		Output					: out	std_logic_vector(BITS - 1 downto 0)
	);
end entity;


architecture rtl of arith_shifter_barrel is
	constant STAGES		: positive		:= log2ceilnz(BITS);

	subtype	T_INTERMEDIATE_RESULT is std_logic_vector(BITS - 1 downto 0);
	type		T_INTERMEDIATE_VECTOR is array (natural range <>) of T_INTERMEDIATE_RESULT;

	signal IntermediateResults	: T_INTERMEDIATE_VECTOR(STAGES downto 0);

begin
	IntermediateResults(0)	<= Input;
	Output									<= IntermediateResults(STAGES);

	genStage : for i in 0 to STAGES - 1 generate
		process(IntermediateResults(i), ShiftRotate, LeftRight, ArithmeticLogic, ShiftAmount)
		begin
			if (ShiftAmount(i) = '0') then
				IntermediateResults(i + 1) <= IntermediateResults(i);																																														-- NOP
			else
				if (ShiftRotate = '0') then
					if (LeftRight = '0') then
						IntermediateResults(i + 1) <= IntermediateResults(i)((BITS - 2**i - 1) downto 0) & ((2**i - 1) downto 0 => '0');														-- SLA, SLL
					else
						if (ArithmeticLogic = '0') then
							IntermediateResults(i + 1) <= ((2**i - 1) downto 0 => IntermediateResults(i)(BITS - 1)) & IntermediateResults(i)(BITS - 1 downto 2**i);		-- SRA
						else
							IntermediateResults(i + 1) <= ((2**i - 1) downto 0 => '0') & IntermediateResults(i)(BITS - 1 downto 2**i);																-- SRL
						end if;
					end if;
				else
					if (LeftRight = '0') then
						IntermediateResults(i + 1) <= IntermediateResults(i)((BITS - 2**i - 1) downto 0) & IntermediateResults(i)(BITS - 1 downto (BITS - 2**i));		-- RL
					else
						IntermediateResults(i + 1) <= IntermediateResults(i)((2**i - 1) downto 0) & IntermediateResults(i)(BITS - 1 downto 2**i);						-- RR
					end if;
				end if;
			end if;
		end process;
	end generate;
end;
