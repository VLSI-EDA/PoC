-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- =============================================================================
-- Testbench:				Testing the physical package.
--
-- Authors:					Thomas B. Preusser
--									Patrick Lehmann
--
-- Description:
-- ------------------------------------
--		TODO
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

entity physical_tb is
end;


library	PoC;
use PoC.physical.all;

-- simulation only packages
use PoC.sim_types.all;
use PoC.simulation.all;

architecture tb of physical_tb is
	constant simTestID : T_SIM_TEST_ID := simCreateTest("Physical types test.");
begin
	simInitialize;

	process
		constant simProcessID : T_SIM_PROCESS_ID := simRegisterProcess(simTestID, "");

		variable t : time;
		variable f : FREQ;
	begin
		t := 20 ns;
		simAssertion(integer(10.0 * to_real(t, 1 ns))  = 200, "Failed stripping of time unit.");
		f := 1.0 / t;
		simAssertion(integer(10.0 * to_real(f, 1 MHz)) = 500, "Failed stripping of FREQ unit.");

		simAssertion(integer(10.0 * t*f) = 10, "Failed cycle computation.");
		simAssertion(integer(10.0 * f*t) = 10, "Failed cycle computation.");

		simDeactivateProcess(simProcessID);
		wait;   --forever
	end process;

end;
