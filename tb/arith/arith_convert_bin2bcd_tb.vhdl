-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Testbench:				Converter Binary to BCD.
--
-- Description:
-- ------------------------------------
--		Automated testbench for PoC.arith_converter_bin2bcd
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
use			PoC.strings.all;
use			PoC.physical.all;
-- simulation only packages
use			PoC.sim_types.all;
use			PoC.simulation.all;
use			PoC.waveform.all;


entity arith_convert_bin2bcd_tb is
end entity;


architecture test of arith_convert_bin2bcd_tb is
	constant CLOCK_FREQ		: FREQ						:= 100 MHz;

	constant INPUT_1			: integer					:= 38442113;
	constant INPUT_2			: integer					:= 78734531;
	constant INPUT_3			: integer					:= 14902385;

	constant CONV1_BITS		: positive				:= 30;
	constant CONV1_DIGITS	: positive				:= 8;
	constant CONV2_BITS		: positive				:= 27;
	constant CONV2_DIGITS	: positive				:= 8;
	constant simTestID		: T_SIM_TEST_ID		:= simCreateTest("Test setup for CONV1_BITS=" & integer'image(CONV1_BITS) & "; INPUT_1=" & INTEGER'image(INPUT_1));


	signal Clock					: std_logic;
	signal Reset					: std_logic;

	signal Start					: std_logic		:= '0';

	signal Conv1_Binary			: std_logic_vector(CONV1_BITS - 1 downto 0);
	signal Conv1_BCDDigits	: T_BCD_VECTOR(CONV1_DIGITS - 1 downto 0);
	signal Conv1_Sign				: std_logic;
	signal Conv2_Binary			: std_logic_vector(CONV2_BITS - 1 downto 0);
	signal Conv2_BCDDigits	: T_BCD_VECTOR(CONV2_DIGITS - 1 downto 0);
	signal Conv2_Sign				: std_logic;

	function Check_Conv2(INPUT : integer; BITS : positive; DIGITS : positive; BCDDigits : T_BCD_VECTOR; Sign : std_logic) return boolean is
		variable nat : natural;
	begin
		if INPUT >= 2**(BITS-1) then
			nat := (-INPUT) mod 2**(BITS-1);
			if Sign /= '1' then
				return false;
			end if;
		else
			nat := INPUT;
			if Sign /= '0' then
				return false;
			end if;
		end if;

		return to_BCD_Vector(nat, DIGITS) = BCDDigits;
	end function;

begin
	-- initialize global simulation status
	simInitialize;
	-- generate global testbench clock and reset
	simGenerateClock(simTestID,			Clock, CLOCK_FREQ);
	simGenerateWaveform(simTestID,	Reset, simGenerateWaveform_Reset(Pause => 10 ns, ResetPulse => 10 ns));

	procStimuli : process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess(simTestID, "Stimuli for " & integer'image(CONV1_BITS) & " bits");
	begin
		simWaitUntilRisingEdge(Clock, 4);

		Start						<= '1';
		Conv1_Binary		<= to_slv(INPUT_1, CONV1_BITS);
		Conv2_Binary		<= to_slv(INPUT_1, CONV2_BITS);
		wait until rising_edge(Clock);

		Start						<= '0';
		wait until rising_edge(Clock);

		for i in 0 to (CONV1_BITS - 1) loop
			wait until rising_edge(Clock);
		end loop;

		simAssertion(to_BCD_Vector(INPUT_1, CONV1_DIGITS) = Conv1_BCDDigits, "Conv1_BCDDigits is wrong for INPUT_1.");
		simAssertion(Check_Conv2(INPUT_1, CONV2_BITS, CONV2_DIGITS, Conv2_BCDDigits, Conv2_Sign),
								 "Conv2_BCDDigits is wrong for INPUT_1.");

		----------------------------------------------------------

		Start						<= '1';
		Conv1_Binary		<= to_slv(INPUT_2, CONV1_BITS);
		Conv2_Binary		<= to_slv(INPUT_2, CONV2_BITS);
		wait until rising_edge(Clock);

		Start						<= '0';
		wait until rising_edge(Clock);

		for i in 0 to (CONV1_BITS - 1) loop
			wait until rising_edge(Clock);
		end loop;

		simAssertion(to_BCD_Vector(INPUT_2, CONV1_DIGITS) = Conv1_BCDDigits, "Conv1_BCDDigits is wrong for INPUT_2.");
		simAssertion(Check_Conv2(INPUT_2, CONV2_BITS, CONV2_DIGITS, Conv2_BCDDigits, Conv2_Sign),
								 "Conv2_BCDDigits is wrong for INPUT_2.");

		----------------------------------------------------------

		Start						<= '1';
		Conv1_Binary		<= to_slv(INPUT_3, CONV1_BITS);
		Conv2_Binary		<= to_slv(INPUT_3, CONV2_BITS);
		wait until rising_edge(Clock);

		Start						<= '0';
		wait until rising_edge(Clock);

		for i in 0 to (CONV1_BITS - 1) loop
			wait until rising_edge(Clock);
		end loop;

		simAssertion(to_BCD_Vector(INPUT_3, CONV1_DIGITS) = Conv1_BCDDigits, "Conv1_BCDDigits is wrong for INPUT_3.");
		simAssertion(Check_Conv2(INPUT_3, CONV2_BITS, CONV2_DIGITS, Conv2_BCDDigits, Conv2_Sign),
								 "Conv2_BCDDigits is wrong for INPUT_3.");

		----------------------------------------------------------

		-- This process is finished
		simDeactivateProcess(simProcessID);
		-- Report overall result
		simFinalize;
		wait;  -- forever
	end process;

	conv1 : entity PoC.arith_convert_bin2bcd
		generic map (
			BITS					=> CONV1_BITS,
			DIGITS				=> CONV1_DIGITS,
			RADIX					=> 8
		)
		port map (
			Clock					=> Clock,
			Reset					=> Reset,

			Start					=> Start,
			Busy					=> open,

			Binary				=> Conv1_Binary,
			IsSigned			=> '0',
			BCDDigits			=> Conv1_BCDDigits,
			Sign					=> Conv1_Sign
		);

	conv2 : entity PoC.arith_convert_bin2bcd
		generic map (
			BITS					=> CONV2_BITS,
			DIGITS				=> CONV2_DIGITS,
			RADIX					=> 2
		)
		port map (
			Clock					=> Clock,
			Reset					=> Reset,

			Start					=> Start,
			Busy					=> open,

			Binary				=> Conv2_Binary,
			IsSigned			=> '1',
			BCDDigits			=> Conv2_BCDDigits,
			Sign					=> Conv2_Sign
		);
end architecture;
