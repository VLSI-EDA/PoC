-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- ============================================================================
-- Authors:					Patrick Lehmann
--
-- Testbench:				For PoC.io.iic.Controller
--
-- Description:
-- ------------------------------------
--	TODO
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

library	IEEE;
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;

library PoC;
use			PoC.utils.all;
use			PoC.vectors.all;
use			PoC.strings.all;
use			PoC.physical.all;
use			PoC.iic.all;
-- simulation only packages
use			PoC.sim_types.all;
use			PoC.simulation.all;
use			PoC.waveform.all;

library uvvm_util;
context	uvvm_util.uvvm_util_context;

library uvvm_vvc_framework;
use			uvvm_vvc_framework.ti_vvc_framework_support_pkg.all;

library bitvis_vip_i2c;
use			bitvis_vip_i2c.i2c_bfm_pkg.all;
use			bitvis_vip_i2c.vvc_methods_pkg.all;


entity iic_Controller_tb is
end entity;


architecture tb of iic_Controller_tb is
	-- UVVM configuration
  constant C_SCOPE              : string  := C_TB_SCOPE_DEFAULT;

	-- UVVM - Local procedures
	-- Log overload procedure for simplification
	procedure log(msg : string) is
	begin
		log(ID_SEQUENCER, msg, C_SCOPE);
	end;

begin
	-- Instantiate testbench wireing
	testharness : entity work.iic_Controller_th;

	sequencer: process
	begin
		----------------------------------------------------------------------------
		-- Initialize UVVM
		----------------------------------------------------------------------------
		-- Wait for UVVM to finish initialization
		await_uvvm_initialization(VOID);

		-- Print the configuration to the log
		report_global_ctrl(VOID);
		report_msg_id_panel(VOID);

		--enable_log_msg(ALL_MESSAGES);
		disable_log_msg(ALL_MESSAGES);
		enable_log_msg(ID_LOG_HDR);
		enable_log_msg(ID_SEQUENCER);
		enable_log_msg(ID_UVVM_SEND_CMD);

		-- disable_log_msg(I2C_VVCT, 1, ALL_MESSAGES);
		-- enable_log_msg(I2C_VVCT, 1, ID_BFM);
		-- enable_log_msg(I2C_VVCT, 1, ID_FINISH_OR_STOP);

		log(ID_LOG_HDR, "Starting simulation of TB for iic_Controller using VVCs", C_SCOPE);
		----------------------------------------------------------------------------
		i2c_slave_check(I2C_VVCT, 1, x"2B", "Expect data from master DUT");







		----------------------------------------------------------------------------
		-- Ending the simulation
		----------------------------------------------------------------------------
		wait for 1000 ns;             -- to allow some time for completion
		report_alert_counters(FINAL); -- Report final counters and print conclusion for simulation (Success/Fail)
		log(ID_LOG_HDR, "SIMULATION COMPLETED", C_SCOPE);

		-- Finish the simulation
		-- std.env.stop;
		wait;  -- to stop completely
	end process;
end architecture;
