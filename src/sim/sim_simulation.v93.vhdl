-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
--									Thomas B. Preusser
-- 									Martin Zabel
--
-- Package:					Simulation constants, functions and utilities.
--
-- Description:
-- -------------------------------------
-- .. TODO:: No documentation available.
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
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;

library PoC;
use			PoC.sim_types.all;
use			PoC.sim_unprotected.all;


package simulation is
	-- mimic definition of VHDL-2008
	type TIME_VECTOR is array(natural range<>) of time;

	-- Testbench Status Management
	-- ===========================================================================
	-- alias simInitialize					is work.sim_unprotected.initialize[NATURAL, TIME];
	procedure simInitialize(MaxAssertFailures : natural := natural'high; MaxSimulationRuntime : TIME := TIME'high);
	alias simFinalize						is work.sim_unprotected.finalize[];

	alias simCreateTest					is work.sim_unprotected.createTest[string return T_SIM_TEST_ID];
	alias simFinalizeTest				is work.sim_unprotected.finalizeTest[T_SIM_TEST_ID];
	alias simRegisterProcess		is work.sim_unprotected.registerProcess[T_SIM_TEST_ID, string, boolean return T_SIM_PROCESS_ID];
	alias simRegisterProcess		is work.sim_unprotected.registerProcess[string, boolean return T_SIM_PROCESS_ID];
	alias simDeactivateProcess	is work.sim_unprotected.deactivateProcess[T_SIM_PROCESS_ID];

	procedure simStopAllClocks;
	--alias simStopAllClocks			is work.sim_unprotected.stopAllClocks[];
	alias simIsStopped					is work.sim_unprotected.isStopped[T_SIM_TEST_ID return boolean];
	alias simIsFinalized				is work.sim_unprotected.isFinalized[T_SIM_TEST_ID return boolean];
	alias simIsAllFinalized			is work.sim_unprotected.isAllFinalized [return boolean];

	alias simAssertion					is work.sim_unprotected.assertion[boolean, string];
  alias simFail								is work.sim_unprotected.fail[string];
	alias simWriteMessage				is work.sim_unprotected.writeMessage[string];

	-- checksum functions
	-- ===========================================================================
	-- TODO: move checksum functions here
end package;

package body simulation is
	procedure simInitialize(MaxAssertFailures : natural := natural'high; MaxSimulationRuntime : TIME := TIME'high) is
	begin
		work.sim_unprotected.initialize(MaxAssertFailures, MaxSimulationRuntime);
		if C_SIM_VERBOSE then		report "simInitialize:" severity NOTE;			end if;
		if (MaxSimulationRuntime /= time'high) then
			wait for MaxSimulationRuntime;
			report "simInitialize: TIMEOUT" severity ERROR;
			work.sim_unprotected.finalize;
		end if;
	end procedure;

	procedure simStopAllClocks is
	begin
		work.sim_unprotected.stopAllClocks;
	end procedure;
end package body;
