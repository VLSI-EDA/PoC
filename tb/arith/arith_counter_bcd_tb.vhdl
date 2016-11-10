-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- ============================================================================
-- Authors:				 	Martin Zabel
--									Thomas B. Preusser
--
-- Module:				 	arith_counter_bcd_tb
--
-- Description:
-- ------------------------------------
-- Testbench for arith_counter_bcd
--
-- License:
-- ============================================================================
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
-- ============================================================================

library	ieee;
use			ieee.std_logic_1164.all;
use			ieee.numeric_std.all;

library	PoC;
use			PoC.utils.all;
use			PoC.strings.all;
use			PoC.physical.all;
-- simulation only packages
use			PoC.sim_types.all;
use			PoC.simulation.all;
use			PoC.waveform.all;


entity arith_counter_bcd_tb is
end entity;


architecture rtl of arith_counter_bcd_tb is
	constant CLOCK_FREQ				: FREQ			:= 100 MHz;
	constant TEST_PARAMETERS	: T_INTVEC	:= (3, 4);

	signal Clock							: std_logic;

begin
	-- initialize global simulation status
	simInitialize(MaxAssertFailures => 20);
	-- generate global testbench clock and reset
	simGenerateClock(Clock, CLOCK_FREQ);

	genTests : for i in TEST_PARAMETERS'range generate
		constant DIGITS			: positive				:= TEST_PARAMETERS(i);
		constant simTestID	: T_SIM_TEST_ID		:= simCreateTest("Test setup for DIGITS=" & integer'image(DIGITS));

		signal Reset				: std_logic;
		signal inc					: std_logic;
		signal Value				: T_BCD_VECTOR(DIGITS - 1 downto 0);
	begin
		-- simGenerateWaveform(simTestID,	Reset, simGenerateWaveform_Reset(Pause => 10 ns, ResetPulse => 10 ns));

		procGenerator : process
			constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess(simTestID, "Generator for " & integer'image(DIGITS) & " digits");
		begin
			Reset		<= '0';
			inc			<= '0';

			wait until falling_edge(Clock);
			Reset		<= '1';
			inc			<= '0';

			wait until falling_edge(Clock);
			Reset		<= '1';
			inc			<= '1';

			wait until falling_edge(Clock);
			Reset		<= '0';
			inc			<= '0';

			for i in 0 to 10**DIGITS - 1 loop
				wait until falling_edge(Clock);
				inc			<= '1';

				wait until falling_edge(Clock);
				inc			<= '0';
			end loop;

			wait until falling_edge(Clock);
			inc			<= '1';

			simWaitUntilFallingEdge(Clock, 4);
			Reset		<= '1';
			inc			<= '0';

			wait until falling_edge(Clock);
			Reset		<= '0';
			inc			<= '0';

			-- This process is finished
			simDeactivateProcess(simProcessID);
			wait;  -- forever
		end process;

		UUT: entity poc.arith_counter_bcd
			generic map (
				DIGITS => DIGITS
			)
			port map (
				clk => Clock,
				rst => Reset,
				inc => inc,
				val => Value
			);

		procChecker : process
			constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess(simTestID, "Checker for " & integer'image(DIGITS) & " digits");
			variable Expected			: T_BCD_VECTOR(DIGITS - 1 downto 0);
		begin
			wait until rising_edge(Clock);
			wait until rising_edge(Clock);
			Expected	:= to_BCD_Vector(0, DIGITS);
			simAssertion((Value = Expected), "Test " & integer'image(simTestID) & ": Wrong initial state. Value=" & to_string(Value) & "  Expected=" & to_string(Expected));

			wait until rising_edge(Clock);
			simAssertion((Value = Expected), "Test " & integer'image(simTestID) & ": Wrong initial state. Value=" & to_string(Value) & "  Expected=" & to_string(Expected));

			wait until rising_edge(Clock);
			for i in 1 to 10**DIGITS - 1 loop
				Expected	:= to_BCD_Vector(i, DIGITS);
				wait until rising_edge(Clock);
				simAssertion((Value = Expected), "Test " & integer'image(simTestID) & ": Must be incremented to state " & to_string(Expected) & "  Value=" & to_string(Value));
				wait until rising_edge(Clock);
				simAssertion((Value = Expected), "Test " & integer'image(simTestID) & ": Must keep the state " & to_string(Expected) & "  Value=" & to_string(Value));
			end loop;

			wait until rising_edge(Clock);
			simAssertion(Value = (DIGITS - 1 downto 0 => x"0"), "Test " & integer'image(simTestID) & ": Should be wrapped to 0000.");

			simWaitUntilRisingEdge(Clock, 5);

			wait until rising_edge(Clock);
			simAssertion(Value = (DIGITS - 1 downto 0 => x"0"), "Test " & integer'image(simTestID) & ": Should be resetted again.");

			-- This process is finished
			simDeactivateProcess(simProcessID);
			wait;  -- forever
		end process;
	end generate;
end architecture;
