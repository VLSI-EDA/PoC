-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Entity:				 	Glitch Filter
--
-- Description:
-- -------------------------------------
-- This module filters glitches on a wire. The high and low spike suppression
-- cycle counts can be configured.
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
-- use			PoC.io.all;


entity io_GlitchFilter is
  generic (
		HIGH_SPIKE_SUPPRESSION_CYCLES			: natural				:= 5;
		LOW_SPIKE_SUPPRESSION_CYCLES			: natural				:= 5
	);
  port (
		Clock		: in	std_logic;
		Input		: in	std_logic;
		Output	: out std_logic
	);
end entity;


architecture rtl of io_GlitchFilter is
	-- Timing table ID
	constant TTID_HIGH_SPIKE				: natural		:= 0;
	constant TTID_LOW_SPIKE					: natural		:= 1;

	-- Timing table
	constant TIMING_TABLE						: T_NATVEC	:= (
		TTID_HIGH_SPIKE			=> HIGH_SPIKE_SUPPRESSION_CYCLES,
		TTID_LOW_SPIKE			=> LOW_SPIKE_SUPPRESSION_CYCLES
	);

	signal State										: std_logic												:= '0';
	signal NextState								: std_logic;

	signal TC_en										: std_logic;
	signal TC_Load									: std_logic;
	signal TC_Slot									: natural;
	signal TC_Timeout								: std_logic;

begin
	assert FALSE
		report "GlitchFilter: " &
					 "HighSpikeSuppressionCycles="	& integer'image(TIMING_TABLE(TTID_HIGH_SPIKE))	& "  " &
					 "LowSpikeSuppressionCycles="		& integer'image(TIMING_TABLE(TTID_LOW_SPIKE))		& "  "
		severity NOTE;

	process(Clock)
	begin
		if rising_edge(Clock) then
			State		<= NextState;
		end if;
	end process;

	process(State, Input, TC_Timeout)
	begin
		NextState		<= State;

		TC_en				<= '0';
		TC_Load			<= '0';
		TC_Slot			<= 0;

		case State is
			when '0' =>
				TC_Slot			<= TTID_HIGH_SPIKE;

				if (Input = '1') then
					TC_en			<= '1';
				else
					TC_Load		<= '1';
				end if;

				if ((Input and TC_Timeout) = '1') then
					NextState	<= '1';
				end if;

			when '1' =>
				TC_Slot			<= TTID_LOW_SPIKE;

				if (Input = '0') then
					TC_en			<= '1';
				else
					TC_Load		<= '1';
				end if;

				if ((not Input and TC_Timeout) = '1') then
					NextState	<= '0';
				end if;

			when others =>
				null;

		end case;
	end process;

	TC : entity PoC.io_TimingCounter
		generic map (
			TIMING_TABLE				=> TIMING_TABLE										-- timing table
		)
		port map (
			Clock								=> Clock,													-- clock
			Enable							=> TC_en,													-- enable counter
			Load								=> TC_Load,												-- load Timing Value from TIMING_TABLE selected by slot
			Slot								=> TC_Slot,												--
			Timeout							=> TC_Timeout											-- timing reached
		);

	Output <= State;
end architecture;
