-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Entity:				 	A generic buffer module for the PoC.Stream protocol.
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
-- WITHOUT WARRANTIES OR CONDITIONS of ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- =============================================================================

library IEEE;
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.NUMERIC_STD.all;

library PoC;
use			PoC.utils.all;
use			PoC.vectors.all;
use			PoC.strings.all;
use			PoC.stream.all;


entity stream_Source is
	generic (
		TESTCASES					: T_SIM_STREAM_FRAMEGROUP_VECTOR_8
	);
	port (
		Clock							: in	std_logic;
		Reset							: in	std_logic;
		-- Control interface
		Enable						: in	std_logic;
		-- OUT Port
		Out_Valid					: out	std_logic;
		Out_Data					: out	T_SLV_8;
		Out_SOF						: out	std_logic;
		Out_EOF						: out	std_logic;
		Out_Ack						: in	std_logic
	);
end entity;


architecture rtl of stream_Source is
	constant MAX_CYCLES											: natural																			:= 10 * 1000;
	constant MAX_ERRORS											: natural																			:=				50;

	-- dummy signals for iSIM
	signal FrameGroupNumber_us		: unsigned(log2ceilnz(TESTCASES'length) - 1 downto 0)		:= (others => '0');
begin

	process
		variable Cycles							: natural			:= 0;
		variable Errors							: natural			:= 0;

		variable FrameGroupNumber		: natural			:= 0;

		variable WordIndex					: natural			:= 0;
		variable CurFG							: T_SIM_STREAM_FRAMEGROUP_8;

	begin
		-- set interface to default values
		Out_Valid					<= '0';
		Out_Data					<= (others => 'U');
		Out_SOF						<= '0';
		Out_EOF						<= '0';

		-- wait for global enable signal
		wait until (Enable = '1');

		-- synchronize to clock
		wait until rising_edge(Clock);

		-- for each testcase in list
		for TestcaseIndex in 0 to TESTCASES'length - 1 loop
			-- initialize per loop
			Cycles	:= 0;
			Errors	:= 0;
			CurFG		:= TESTCASES(TestcaseIndex);

			-- continue with next frame if current is disabled
			assert FALSE report "active=" & to_string(CurFG.Active) severity WARNING;
			next when CurFG.Active = FALSE;

			-- write dummy signals for iSIM
			FrameGroupNumber			:= TestcaseIndex;
			FrameGroupNumber_us		<= to_unsigned(FrameGroupNumber, FrameGroupNumber_us'length);

			-- PrePause
			for i in 1 to CurFG.PrePause loop
				wait until rising_edge(Clock);
			end loop;

			WordIndex							:= 0;

			-- infinite loop
			loop
				-- check for to many simulation cycles
				assert (Cycles < MAX_CYCLES) report "MAX_CYCLES reached:  framegroup=" & integer'image(to_integer(FrameGroupNumber_us)) severity FAILURE;
--				assert (Errors < MAX_ERRORS) report "MAX_ERRORS reached" severity FAILURE;
				Cycles := Cycles + 1;

				wait until rising_edge(Clock);
				-- write frame data to interface
				Out_Valid					<= CurFG.Data(WordIndex).Valid;
				Out_Data					<= CurFG.Data(WordIndex).Data;
				Out_SOF						<= CurFG.Data(WordIndex).SOF;
				Out_EOF						<= CurFG.Data(WordIndex).EOF;

				wait until falling_edge(Clock);
				-- go to next word if interface counterpart has accepted the current word
				if (Out_Ack	 = '1') then
					WordIndex := WordIndex + 1;
				end if;

				-- check if framegroup end is reached => exit loop
				assert FALSE report "WordIndex=" & integer'image(WordIndex) severity WARNING;
				exit when ((WordIndex /= 0) and (CurFG.Data(WordIndex - 1).EOFG = TRUE));
			end loop;

			-- PostPause
			for i in 1 to CurFG.PostPause loop
				wait until rising_edge(Clock);
			end loop;

			assert FALSE report "new round" severity WARNING;
		end loop;

		-- set interface to default values
		wait until rising_edge(Clock);
		Out_Valid					<= '0';
		Out_Data					<= (others => 'U');
		Out_SOF						<= '0';
		Out_EOF						<= '0';
	end process;

end architecture;
