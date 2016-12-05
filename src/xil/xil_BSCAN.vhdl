-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Entity:					JTAG / Boundary Scan wrapper
--
-- Description:
-- -------------------------------------
-- This module wraps Xilinx "Boundary Scan" (JTAG) primitives in a generic
-- module. |br|
-- Supported devices are:
--  * Spartan-3, Spartan-6
--  * Virtex-5, Virtex-6
--  * Series-7 (Artix-7, Kintex-7, Virtex-7, Zynq-7000)
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany,
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

library UniSim;
use			UniSim.vComponents.all;

library PoC;
use			PoC.config.all;


entity xil_BSCAN is
	generic (
		JTAG_CHAIN					: natural;
		DISABLE_JTAG				: boolean			:= FALSE
	);
	port (
		Reset								: out	std_logic;
		RunTest							: out	std_logic;
		Sel									: out	std_logic;
		Capture							: out	std_logic;
		drck								: out	std_logic;
		Shift								: out	std_logic;
		Test_Clock					: out	std_logic;
		Test_DataIn					: out	std_logic;
		Test_DataOut				: in	std_logic;
		Test_ModeSelect			: out	std_logic;
		Update							: out	std_logic
	);
end entity;


architecture rtl of xil_BSCAN is
	constant DEV_INFO		: T_DEVICE_INFO	:= DEVICE_INFO;
begin
	genSpartan3 : if (DEV_INFO.Device = DEVICE_SPARTAN3) generate
		signal drck_i		: std_logic_vector(1 downto 0);
		signal sel_i		: std_logic_vector(1 downto 0);
		signal tdo_i		: std_logic_vector(1 downto 0);
	begin
		drck		<= drck_i(JTAG_CHAIN - 1);
		Sel			<= sel_i(JTAG_CHAIN - 1);
		tdo_i		<= (others => Test_DataOut);

		bscan : BSCAN_SPARTAN3
			port map (
				CAPTURE	=> Capture,				-- CAPTURE output from TAP controller
				DRCK1		=> drck_i(0),			-- Data register output for USER1 functions
				DRCK2		=> drck_i(1),			-- Data register output for USER2 functions
				RESET		=> Reset,					-- Reset output from TAP controller
				SEL1		=> sel_i(0),			-- USER1 active output
				SEL2		=> sel_i(1),			-- USER2 active output
				SHIFT		=> Shift,					-- SHIFT output from TAP controller
				TDI			=> Test_DataIn,		-- TDI output from TAP controller
				UPDATE	=> Update,				-- UPDATE output from TAP controller
				TDO1		=> tdo_i(0),			-- Data input for USER1 function
				TDO2		=> tdo_i(1)				-- Data input for USER2 function
			);
	end generate;

	genSpartan6 : if (DEV_INFO.Device = DEVICE_SPARTAN6) generate
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

	genVirtex5 : if (DEV_INFO.Device = DEVICE_VIRTEX5) generate
	begin
		bscan : BSCAN_VIRTEX5
			generic map (
				JTAG_CHAIN		=> JTAG_CHAIN			-- value for USER command; possible values: 1..4
			)
			port map (
				CAPTURE	=> Capture,				-- CAPTURE output from TAP controller
				DRCK		=> drck,					-- Data register output for USER functions
				RESET		=> Reset,					-- Reset output from TAP controller
				SEL			=> Sel,						-- USER active output
				SHIFT		=> Shift,					-- SHIFT output from TAP controller
				TDI			=> Test_DataIn,		-- TDI output from TAP controller
				UPDATE	=> Update,				-- UPDATE output from TAP controller
				TDO			=> Test_DataOut		-- Data input for USER function
			);
	end generate;

	genVirtex6 : if (DEV_INFO.Device = DEVICE_VIRTEX6) generate
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

	genSeries7 : if (DEV_INFO.DevSeries = DEVICE_SERIES_7_SERIES) generate
	begin
		bscan : BSCANE2
			generic map (
				JTAG_CHAIN		=> JTAG_CHAIN,
				DISABLE_JTAG	=> boolean'image(DISABLE_JTAG)
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
end architecture;
