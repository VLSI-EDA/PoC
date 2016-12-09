-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Testbench:				for PoC.misc.stat.Histogram
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
use			IEEE.math_real.all;

library	PoC;
use			poC.utils.all;
use			poC.strings.all;
use			poC.vectors.all;
use			poC.physical.all;
-- simulation only packages
use			PoC.sim_types.all;
use			PoC.sim_random.all;
use			PoC.simulation.all;
use			PoC.waveform.all;

use			PoC.sim_global.all;
use			PoC.FileIO.all;

entity stat_Histogram_tb is
end entity;


architecture tb of stat_Histogram_tb is
	constant CLOCK_FREQ					: FREQ			:= 100 MHz;

	constant GNUPLOT_DATA_FILE	: string		:= "stat_Histogram.dat";

  -- component generics
	constant DATA_BITS		: positive				:= 8;
	constant COUNTER_BITS	: positive				:= 8;
	constant simTestID		: T_SIM_TEST_ID		:= simCreateTest("Test setup for DATA_BITS=" & integer'image(DATA_BITS));

	constant RESULT				: T_INTVEC				:= (0 to (2**DATA_BITS - 1) => 3);
	constant SIM_COUNT		: positive				:= 10;

  -- component ports
  signal Clock					: std_logic;
  signal Reset					: std_logic;

  signal Enable					: std_logic;
  signal DataIn					: std_logic_vector(DATA_BITS - 1 downto 0);

	signal Histogram			: T_SLM(2**DATA_BITS - 1 downto 0, COUNTER_BITS - 1 downto 0);
	signal Histogram_slvv	: T_SLVV_8(2**DATA_BITS - 1 downto 0);

begin
	-- initialize global simulation status
	simInitialize;

	-- generate global testbench clock
	simGenerateClock(simTestID,			Clock,	CLOCK_FREQ);
	simGenerateWaveform(simTestID,	Reset,	simGenerateWaveform_Reset(Pause =>  5 ns, ResetPulse => 10 ns));
	simGenerateWaveform(simTestID,	Enable,	simGenerateWaveform_Reset(Pause => 25 ns, ResetPulse => ((1024 * SIM_COUNT) * 10 ns)));	-- (VALUES'length * 10 ns)));

  -- component instantiation
  UUT: entity PoC.stat_Histogram
    generic map (
			DATA_BITS			=> DATA_BITS,
			COUNTER_BITS	=> COUNTER_BITS
    )
    port map (
      Clock					=> Clock,
      Reset					=> Reset,

			Enable				=> Enable,
			DataIn				=> DataIn,

			Histogram			=> Histogram
    );

	Histogram_slvv	<= to_slvv_8(Histogram);

	procStimuli : process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess(simTestID, "Generator and Checker");
		variable RandomValue_real	: REAL;
		variable RandomValue_int	: integer;
		variable good							: boolean;

		constant StandardDeviation	: REAL	:= 0.8;
		constant Mean								: REAL	:= 0.0;
		constant Span								: REAL	:= 5.0;
		constant LowerBound					: REAL	:= -(Span / 2.0) + Mean;
		constant UpperBound					: REAL	:= +(Span / 2.0) + Mean;
		constant Scaler							: REAL	:= (2.0 ** DATA_BITS) / Span;
		constant Move								: REAL	:= 2.0 ** (DATA_BITS - 1);

		variable random  : T_RANDOM;
		variable logfile : T_LOGFILE;
	begin
		random.setSeed;
		logfile.OpenFile(GNUPLOT_DATA_FILE);

		DataIn		<= (others => '0');
		wait until (Enable = '1') and falling_edge(Clock);

		for i in 0 to SIM_COUNT-1 loop
			-- if (i mod 5 = 0) then
				-- report "i=" & INTEGER'image(i) severity NOTE;
			-- end if;
			for j in 0 to 1023 loop

				-- uniform distribution
				RandomValue_int		:= random.getUniformDistributedValue(0, 2**DATA_BITS - 1);
				DataIn						<= to_slv(RandomValue_int, DATA_BITS);

				wait until falling_edge(Clock);
			end loop;
		end loop;

		logfile.PrintLine("# stat_Histogram_tb.vhdl");
		logfile.PrintLine("# plot '" & GNUPLOT_DATA_FILE & "' using 1:2 with boxes, '" & GNUPLOT_DATA_FILE & "' using (1):2:(255) smooth unique with xerrorbar");

		-- test result after all cycles
		good := TRUE;
		for i in Histogram_slvv'range loop
			logfile.PrintLine(raw_format_nat_dec(i) & " " & raw_format_nat_dec(to_integer(unsigned(Histogram_slvv(i)))));
		end loop;

		-- TODO: how to assert a histogram?
		-- simAssertion(good, "Test failed.");

		-- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
	end process;

end architecture;
