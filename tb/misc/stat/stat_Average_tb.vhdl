-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Testbench:				for PoC.misc.stat.Average
--
-- Description:
-- ------------------------------------
--	TODO
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
use			poC.utils.all;
use			poC.vectors.all;
use			poC.physical.all;
-- simulation only packages
use			PoC.sim_types.all;
use			PoC.simulation.all;
use			PoC.waveform.all;


entity stat_Average_tb is
end entity;


architecture tb of stat_Average_tb is
	constant CLOCK_FREQ							: FREQ					:= 100 MHz;

  -- component generics
  constant VALUES : T_NATVEC := (
		113, 106, 126, 239, 146, 72, 51, 210, 44, 56, 10, 126, 7, 7, 22, 18,
		128, 217, 106, 210, 58, 71, 213, 206, 169, 213, 90, 27, 166, 159, 83, 116,
		246, 208, 105, 64, 112, 12, 110, 10, 5, 100, 12, 231, 191, 235, 27, 143,
		162, 178, 136, 149, 92, 221, 122, 44, 143, 169, 72, 182, 232, 26, 46, 135,
		223, 144, 129, 48, 148, 208, 156, 119, 109, 98, 207, 208, 62, 232, 17, 183,
		189, 197, 115, 237, 25, 183, 27, 27, 89, 64, 170, 192, 189, 177, 28, 228,
		56, 127, 10, 49, 108, 229, 244, 204, 25, 20, 42, 243, 16, 163, 232, 161,
		154, 139, 243, 38, 160, 59, 113, 42, 120, 104, 208, 87, 40, 213, 179, 181,
		73, 228, 155, 184, 224, 218, 77, 210, 202, 161, 215, 7, 143, 34, 13, 175,
		81, 12, 40, 53, 184, 240, 71, 247, 17, 218, 179, 7, 23, 159, 166, 61,
		90, 111, 172, 37, 11, 50, 186, 186, 64, 36, 85, 249, 93, 108, 148, 89,
		93, 35, 7, 30, 175, 129, 247, 83, 160, 157, 170, 9, 41, 73, 189, 45,
		244, 157, 166, 35, 111, 226, 167, 34, 76, 104, 239, 151, 157, 71, 156, 159,
		72, 93, 163, 237, 153, 139, 135, 211, 113, 92, 126, 103, 130, 180, 147, 240,
		96, 42, 7, 185, 191, 115, 227, 117, 118, 224, 204, 74, 140, 98, 176, 92,
		3, 13, 187, 198, 160, 201, 141, 108, 24, 205, 171, 22, 102, 66, 153, 146,
		206, 248, 58, 117, 67, 220, 217, 206, 115, 48, 122, 179, 184, 63, 74, 18,
		166, 37, 103, 119, 242, 198, 82, 144, 151, 149, 164, 235, 193, 207, 18, 55,
		74, 61, 118, 141, 42, 61, 28, 32, 46, 230, 85, 114, 82, 212, 173, 210,
		134, 156, 106, 67, 212, 36, 153, 10, 168, 164, 216, 168, 59, 231, 15, 157,
		33, 69, 107, 126, 195, 182, 225, 107, 12, 73, 76, 15, 116, 218, 64, 188,
		225, 203, 104, 40, 104, 200, 92, 40, 158, 110, 222, 128, 95, 110, 223, 64,
		218, 178, 84, 16, 108, 50, 18, 202, 180, 249, 58, 142, 210, 141, 144, 200,
		102, 30, 192, 106, 130, 224, 56, 82, 226, 69, 218, 88, 209, 100, 15, 152,
		100, 14, 46, 188, 136, 51, 83, 178, 188, 152, 110, 105, 145, 199, 80, 19,
		215, 25, 29, 67, 167, 119, 184, 243, 124, 5, 39, 41, 81, 179, 242, 83,
		236, 155, 45, 198, 97, 206, 67, 54, 197, 17, 168, 227, 117, 200, 186, 29,
		239, 201, 122, 187, 74, 197, 234, 230, 80, 53, 66, 133, 14, 44, 99, 11,
		160, 29, 118, 239, 157, 131, 172, 12, 207, 224, 119, 153, 201, 206, 128, 173,
		69, 12, 51, 129, 60, 57, 12, 42, 171, 64, 121, 46, 143, 184, 42, 156,
		167, 160, 70, 91, 85, 196, 122, 110, 32, 113, 229, 99, 81, 84, 32, 123,
		174, 142, 66, 5, 242, 220, 200, 105, 20, 79, 71, 95, 13, 128, 119, 26
	);

	type T_RESULT is record
		Minimum			: natural;
		Count				: positive;
	end record;

	type T_RESULT_VECTOR	is array(natural range <>) of T_RESULT;

	constant DATA_BITS		: positive				:= 8;
	constant COUNTER_BITS	: positive				:= 16;
	constant simTestID		: T_SIM_TEST_ID		:= simCreateTest("Test setup for DATA_BITS=" & integer'image(DATA_BITS) & "  COUNTER_BITS=" & INTEGER'image(COUNTER_BITS));

  -- component ports
  signal Clock		: std_logic;
  signal Reset		: std_logic;

  signal Enable		: std_logic		:= '0';
  signal DataIn		: std_logic_vector(DATA_BITS - 1 downto 0);

	signal Count		: std_logic_vector(COUNTER_BITS - 1 downto 0);
	signal Sum			: std_logic_vector(COUNTER_BITS - 1 downto 0);
	signal Average	: std_logic_vector(COUNTER_BITS - 1 downto 0);
	signal Valid		: std_logic;

begin
	-- initialize global simulation status
	simInitialize;
	-- generate global testbench clock
	simGenerateClock(simTestID,			Clock,	CLOCK_FREQ);
	simGenerateWaveform(simTestID,	Reset,	simGenerateWaveform_Reset(Pause =>  5 ns, ResetPulse => 10 ns));
	simGenerateWaveform(simTestID,	Enable,	simGenerateWaveform_Reset(Pause => 25 ns, ResetPulse => (VALUES'length * 10 ns)));

  -- component instantiation
  UUT: entity PoC.stat_Average
    generic map (
			DATA_BITS			=> DATA_BITS,
			COUNTER_BITS	=> COUNTER_BITS
    )
    port map (
      Clock			=> Clock,
      Reset			=> Reset,

			Enable		=> Enable,
			DataIn		=> DataIn,

			Count			=> Count,
			Sum				=> Sum,
			Average		=> Average,
			Valid			=> Valid
    );

	procStimuli : process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess(simTestID, "Generator and Checker");
		variable ExpectedCnt	: natural;
		variable ExpectedSum	: natural;
		variable ExpectedAvg	: natural;
	begin
		DataIn		<= (others => '0');
		wait until (Enable = '1') and falling_edge(Clock);

		for i in VALUES'range loop
			--Enable	<= to_sl(VALUES(i) /= 35);
			DataIn	<= to_slv(VALUES(i), DataIn'length);
			wait until falling_edge(Clock);
		end loop;

		wait until (Valid = '0') and rising_edge(Clock);

		ExpectedCnt := VALUES'length;
		ExpectedSum := isum(VALUES);
		ExpectedAvg := ExpectedSum / ExpectedCnt;

		simAssertion((unsigned(Count) = ExpectedCnt), "Count mismatch. Count=" & integer'image(to_integer(unsigned(Count))) & "  Expected=" & INTEGER'image(ExpectedCnt));
		simAssertion((unsigned(Sum) = ExpectedSum), "Sum mismatch. Sum=" & integer'image(to_integer(unsigned(Sum))) & "  Expected=" & INTEGER'image(ExpectedSum));
		simAssertion((unsigned(Average) = ExpectedAvg), "Average mismatch. Average=" & integer'image(to_integer(unsigned(Average))) & "  Expected=" & INTEGER'image(ExpectedAvg));

		-- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
	end process;

end architecture;
