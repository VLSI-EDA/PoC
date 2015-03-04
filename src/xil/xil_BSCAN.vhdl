-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Authors:					Patrick Lehmann
-- 
-- Module:					JTAG / Boundary Scan wrapper
--
-- Description:
-- ------------------------------------
--		This module wraps Xilinx "Boundary Scan" (JTAG) primitives in a generic module.
--		Supported devices:
--			- Spartan-6
--			- Virtex-6
--			- Series-7
--		
--
-- License:
-- ============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany,
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
-- ============================================================================

library IEEE;
use			IEEE.STD_LOGIC_1164.ALL;
use			IEEE.NUMERIC_STD.ALL;

library UniSim;
use			UniSim.vComponents.all;

library PoC;
use			PoC.config.all;


entity xil_BSCAN is
	generic (
		JTAG_CHAIN					: NATURAL;
		DISABLE_JTAG				: BOOLEAN			:= FALSE
	);
	port (
		Reset								: out	STD_LOGIC;
		RunTest							: out	STD_LOGIC;
		Sel									: out	STD_LOGIC;
		Capture							: out	STD_LOGIC;
		drck								: out	STD_LOGIC;
		Shift								: out	STD_LOGIC;
		Test_Clock					: out	STD_LOGIC;
		Test_DataIn					: out	STD_LOGIC;
		Test_DataOut				: in	STD_LOGIC;
		Test_ModeSelect			: out	STD_LOGIC;
		Update							: out	STD_LOGIC
	);
end;


architecture rtl of xil_BSCAN is
begin
	genSpartan6 : if (DEVICE = DEVICE_SPARTAN6) generate
	begin
		bscan : BSCAN_SPARTAN6
			generic map (
				JTAG_CHAIN	=> JTAG_CHAIN
			)
			port map (
				CAPTURE		=> Capture,
				DRCK			=> drck,
				RESET			=> Reset,
				RUNTEST		=> RunTest,
				SEL				=> Sel,
				SHIFT			=> Shift,
				TCK				=> Test_Clock,
				TDI				=> Test_DataIn,
				TMS				=> Test_ModeSelect,
				UPDATE		=> Update,
				TDO				=> Test_DataOut
			);
	end generate;
	
	genVirtex6 : if (DEVICE = DEVICE_VIRTEX6) generate
	begin
		bscan : BSCAN_VIRTEX6
			generic map (
				JTAG_CHAIN		=> JTAG_CHAIN,
				DISABLE_JTAG	=> DISABLE_JTAG
			)
			port map (
				CAPTURE		=> Capture,
				DRCK			=> drck,
				RESET			=> Reset,
				RUNTEST		=> RunTest,
				SEL				=> Sel,
				SHIFT			=> Shift,
				TCK				=> Test_Clock,
				TDI				=> Test_DataIn,
				TMS				=> Test_ModeSelect,
				UPDATE		=> Update,
				TDO				=> Test_DataOut
			);
	end generate;
	
	genSeries7 : if (DEVICE_SERIES = 7) generate
	begin
		bscan : BSCANE2
			generic map (
				JTAG_CHAIN		=> JTAG_CHAIN,
				DISABLE_JTAG	=> BOOLEAN'image(DISABLE_JTAG)
			)
			port map (
				CAPTURE		=> Capture,
				DRCK			=> drck,
				RESET			=> Reset,
				RUNTEST		=> RunTest,
				SEL				=> Sel,
				SHIFT			=> Shift,
				TCK				=> Test_Clock,
				TDI				=> Test_DataIn,
				TMS				=> Test_ModeSelect,
				UPDATE		=> Update,
				TDO				=> Test_DataOut
			);
	end generate;
  end;
	