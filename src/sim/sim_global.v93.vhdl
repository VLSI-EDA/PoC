-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Package:					Global simulation constants and shared varibales.
--
-- Description:
-- -------------------------------------
-- .. TODO:: No documentation available.
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
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
-- =============================================================================

library PoC;
use			PoC.utils.all;
use			PoC.sim_types.all;


package sim_global is
	-- The default global status objects.
	-- ===========================================================================
	shared variable globalSim_StateIsInitialized		: BOOLEAN																	:= FALSE;
	shared variable globalSim_StateIsFinalized			: BOOLEAN																	:= FALSE;

	shared variable globalSim_MaxAssertFailures			: NATURAL																	:= NATURAL'high;
	shared variable globalSim_MaxSimulationRuntime	: TIME																		:= TIME'high;

	-- Internal state variable to log a failure condition for final reporting.
	-- Once de-asserted, this variable will never return to a value of true.
	shared variable globalSim_Passed								: BOOLEAN																	:= TRUE;
	shared variable globalSim_AssertCount						: NATURAL																	:= 0;
	shared variable globalSim_FailedAssertCount			: NATURAL																	:= 0;

	-- Clock Management
	shared variable globalSim_MainProcessEnables		: T_SIM_BOOLVEC(T_SIM_TEST_ID)						:= (others => TRUE);
	shared variable globalSim_MainClockEnables			: T_SIM_BOOLVEC(T_SIM_TEST_ID)						:= (others => TRUE);

	-- Process Management
	shared variable globalSim_ProcessCount					: NATURAL																	:= 0;
	shared variable globalSim_ActiveProcessCount		: NATURAL																	:= 0;
	shared variable globalSim_Processes							: T_SIM_PROCESS_VECTOR(T_SIM_PROCESS_ID);

	-- Test Management
	shared variable globalSim_TestCount							: NATURAL																	:= 0;
	shared variable globalSim_ActiveTestCount				: NATURAL																	:= 0;
	shared variable globalSim_Tests									: T_SIM_TEST_VECTOR(T_SIM_TEST_ID);

end package;
