-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Authors:				 	Patrick Lehmann
-- 
-- Module:				 	Debounce module for BITS many unreliable input pins
--
-- Description:
-- ------------------------------------
--		This module debounces several input pins. Each wire (pin) is feed through
--		a PoC.io.GlitchFilter. An optional two FF input synchronizes can be added.
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
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.NUMERIC_STD.all;

library PoC;
use			PoC.utils.all;
use			PoC.physical.all;


entity io_Debounce is
  generic (
		CLOCK_FREQ							: FREQ				:= 100.0 MHz;
		DEBOUNCE_TIME						: TIME				:= 5.0 ms;
		BITS										: POSITIVE		:= 1;
		ADD_INPUT_SYNCHRONIZER	: BOOLEAN			:= TRUE
	);
  port (
		Clock		: in	STD_LOGIC;
		Input		: in	STD_LOGIC_VECTOR(BITS - 1 downto 0);
		Output	: out	STD_LOGIC_VECTOR(BITS - 1 downto 0)
	);
end;


architecture rtl of io_Debounce is
	signal Input_sync					: STD_LOGIC_VECTOR(Input'range);

begin
	-- input synchronization
	genNoSync : if (ADD_INPUT_SYNCHRONIZER = FALSE) generate
		Input_sync	<= Input;
	end generate;	
	genSync : if (ADD_INPUT_SYNCHRONIZER = TRUE) generate
		sync : entity PoC.sync_Flag
			generic map (
				BITS		=> BITS
			)
			port map (
				Clock		=> Clock,				-- Clock to be synchronized to
				Input		=> Input,				-- Data to be synchronized
				Output	=> Input_sync		-- synchronised data
			);
	end generate;

	-- glitch filter
	genGF : for i in 0 to BITS - 1 generate
		constant SPIKE_SUPPRESSION_CYCLES		: NATURAL		:= TimingToCycles(DEBOUNCE_TIME, CLOCK_FREQ);
	begin
		GF : entity PoC.io_GlitchFilter
			generic map (
				HIGH_SPIKE_SUPPRESSION_CYCLES		=> SPIKE_SUPPRESSION_CYCLES,
				LOW_SPIKE_SUPPRESSION_CYCLES		=> SPIKE_SUPPRESSION_CYCLES
			)
			port map (
				Clock		=> Clock,
				Input		=> Input_sync(i),
				Output	=> Output(i)
			);
	end generate;
end;