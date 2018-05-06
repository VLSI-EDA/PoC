-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Entity:				 	VHDL package for component declarations, types and functions
--									associated to the PoC.xil namespace
--
-- Description:
-- -------------------------------------
--		This package declares types and components for
--			- Xilinx ChipScope Pro IPCores (ICON, ILA, VIO)
--			- Xilinx Dynamic Reconfiguration Port (DRP) related types
--			- SystemMonitor for FPGA core temperature measurement and fan control
--				(see PoC.io.FanControl)
--			- Component declarations for Xilinx related modules
--
-- License:
-- =============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany
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

library PoC;
use			PoC.utils.all;
use			PoC.vectors.all;


package xil is
	-- ChipScope
	-- ==========================================================================
	subtype	T_XIL_CHIPSCOPE_CONTROL					is std_logic_vector(35 downto 0);
	type		T_XIL_CHIPSCOPE_CONTROL_VECTOR	is array (natural range <>) of T_XIL_CHIPSCOPE_CONTROL;

	-- Dynamic Reconfiguration Port (DRP)
	-- ==========================================================================
	subtype T_XIL_DRP_ADDRESS								is T_SLV_16;
	subtype T_XIL_DRP_DATA									is T_SLV_16;

	type		T_XIL_DRP_ADDRESS_VECTOR				is array (natural range <>) of T_XIL_DRP_ADDRESS;
	type		T_XIL_DRP_DATA_VECTOR						is array (natural range <>) of T_XIL_DRP_DATA;

	type T_XIL_DRP_BUS_IN is record
		Clock					: std_logic;
		Enable				: std_logic;
		ReadWrite			: std_logic;
		Address				: T_XIL_DRP_ADDRESS;
		Data					: T_XIL_DRP_DATA;
	end record;

	constant C_XIL_DRP_BUS_IN_EMPTY : T_XIL_DRP_BUS_IN := (
		Clock			=> '0',
		Enable		=> '0',
		ReadWrite => '0',
		Address		=> (others => '0'),
		Data			=> (others => '0'));

	type T_XIL_DRP_BUS_OUT is record
		Data					: T_XIL_DRP_DATA;
		Ack						: std_logic;
	end record;

	constant C_XIL_DRP_BUS_OUT_EMPTY : T_XIL_DRP_BUS_OUT := (
		Ack				=> '0',
		Data			=> (others => '0'));

	type T_XIL_DRP_CONFIG is record
		Address														: T_XIL_DRP_ADDRESS;
		Mask															: T_XIL_DRP_DATA;
		Data															: T_XIL_DRP_DATA;
	end record;

	-- define array indices
	constant C_XIL_DRP_MAX_CONFIG_COUNT	: positive	:= 8;

	subtype T_XIL_DRP_CONFIG_INDEX			is integer range 0 to C_XIL_DRP_MAX_CONFIG_COUNT - 1;
	type		T_XIL_DRP_CONFIG_VECTOR			is array (natural range <>) of T_XIL_DRP_CONFIG;

	type T_XIL_DRP_CONFIG_SET is record
		Configs														: T_XIL_DRP_CONFIG_VECTOR(T_XIL_DRP_CONFIG_INDEX);
		LastIndex													: T_XIL_DRP_CONFIG_INDEX;
	end record;

	type T_XIL_DRP_CONFIG_ROM						is array (natural range <>) of T_XIL_DRP_CONFIG_SET;

	constant C_XIL_DRP_CONFIG_EMPTY			: T_XIL_DRP_CONFIG				:= (
		Address =>	(others => '0'),
		Data =>			(others => '0'),
		Mask =>			(others => '0')
	);

	constant C_XIL_DRP_CONFIG_SET_EMPTY	: T_XIL_DRP_CONFIG_SET		:= (
		Configs		=> (others => C_XIL_DRP_CONFIG_EMPTY),
		LastIndex	=> 0
	);

	component xil_ChipScopeICON is
		generic (
			PORTS				: positive
		);
		port (
			ControlBus	: inout	T_XIL_CHIPSCOPE_CONTROL_VECTOR(PORTS - 1 downto 0)
		);
	end component;

	component xil_SystemMonitor is
		port (
			Reset						: in	std_logic;				-- Reset signal for the System Monitor control logic

			Alarm_UserTemp	: out	std_logic;				-- Temperature-sensor alarm output
			Alarm_OverTemp	: out	std_logic;				-- Over-Temperature alarm output
			Alarm						: out	std_logic;				-- OR'ed output of all the alarms
			VP							: in	std_logic;				-- Dedicated analog input pair
			VN							: in	std_logic
		);
	end component;
end package;
