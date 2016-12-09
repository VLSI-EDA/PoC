-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:         Patrick Lehmann
--
-- Testbench:       A parser for VCD files.
--
-- Description:
-- -------------------------------------
--
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
--                     Chair of VLSI-Design, Diagnostics and Architecture
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
--
library IEEE;
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.STD_LOGIC_TEXTIO.all;
use			IEEE.NUMERIC_STD.all;
use			STD.TEXTIO.all;

library PoC;
use			PoC.my_project.all;
use			PoC.strings.all;
use			PoC.physical.all;
-- simulation only packages
use			PoC.sim_types.all;
use			PoC.simulation.all;
use			PoC.waveform.all;
use			PoC.sim_VCDParser.all;


entity sim_VCDParser_tb is
end entity;


architecture tb of sim_VCDParser_tb is
	constant CLOCK_FREQ		: FREQ								:= 100 MHz;

	constant simTestID		: T_SIM_TEST_ID				:= simCreateTest("Testing the VCD parser.");

	signal Clock					: std_logic						:= '1';
	signal Reset					: std_logic						:= '0';

	signal valid					: std_logic;
	signal sof						: std_logic;
	signal eof						: std_logic;
	signal data						: std_logic_vector(7 downto 0);
	signal ack						: std_logic;

begin
	-- initialize global simulation status
	simInitialize;
	-- generate global testbench clock and reset
	simGenerateClock(simTestID,			Clock, CLOCK_FREQ);

	VCDProcess: process
		constant simProcessID		: T_SIM_PROCESS_ID := simRegisterProcess(simTestID, "VCD reader process");

		file			VCDFile				: TEXT;
		variable	VCDLine				: T_VCDLINE;

		variable	VCDTime				: integer;
		variable	VCDTime_nx		: integer;

	begin
		Reset								<= '0';
		simWaitUntilRisingEdge(Clock, 2);

		Reset								<= '1';
		simWaitUntilRisingEdge(Clock, 1);

		Reset								<= '0';
		simWaitUntilRisingEdge(Clock, 2);

		-- open *.vcd file and read header
		file_open(VCDFile, MY_PROJECT_DIR & "tb/sim/sim_VCDParser_tb.vcd", READ_MODE);
		VCD_ReadHeader(VCDFile, VCDLine);

		-- read initial stimuli values
		-- ==============================================================
		VCDTime		:= to_natural_dec(VCDLine(2 to str_length(VCDLine)));
		if (VCDTime = -1) then
			assert (FALSE) report "no positive after #-symbol!" & VCDLine severity FAILURE;
		elsif (VCDTime /= 0) then
			assert (FALSE) report  "no initial stimuli" severity FAILURE;
		end if;

		-- read waveform stimuli
		-- ==============================================================
		loop0 : while (not endfile(VCDFile)) loop
			loop1 : while (not endfile(VCDFile)) loop
				VCD_ReadLine(VCDFile, VCDLine);

				exit loop0 when endfile(VCDFile);
				exit loop1 when (VCDLine(1) = '#');

				if (VCDLine(1) = 'b') then
					-- add binary vectors here
					VCD_Read_StdLogicVector(VCDLine, data, "n3", '0');
				else
					-- add single bit signals here
					VCD_Read_StdLogic(VCDLine, valid,	"n4");
					VCD_Read_StdLogic(VCDLine, sof,		"n1");
					VCD_Read_StdLogic(VCDLine, eof,		"n2");
					VCD_Read_StdLogic(VCDLine, ack,		"n0");
				end if;
			end loop;

			VCDTime_nx	:= to_natural_dec(VCDLine(2 to str_length(VCDLine)));
			simWaitUntilRisingEdge(Clock, (VCDTime_nx - VCDTime));
			VCDTime			:= VCDTime_nx;
		end loop;	-- WHILE TRUE

		-- ==============================================================
		-- close *.vcd-file
		file_close(VCDFile);

		assert FALSE report "End of VCD file." severity WARNING;

		-- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
	end process;
end architecture;
