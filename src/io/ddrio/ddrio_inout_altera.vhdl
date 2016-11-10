-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Martin Zabel
--									Patrick Lehmann
--
-- Entity:					Instantiates Chip-Specific DDR Input/Output Registers for Xilinx FPGAs.
--
-- Description:
-- -------------------------------------
--	See PoC.io.ddrio.inout for interface description.
--
-- License:
-- =============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany,
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

library	Altera_mf;
use			Altera_mf.Altera_MF_Components.all;


entity ddrio_inout_altera is
	generic (
		BITS						: positive
	);
	port (
		ClockOut				: in		std_logic;
		ClockOutEnable	: in		std_logic;
		OutputEnable		: in		std_logic;
		DataOut_high		: in		std_logic_vector(BITS - 1 downto 0);
		DataOut_low			: in		std_logic_vector(BITS - 1 downto 0);

		ClockIn					: in		std_logic;
		ClockInEnable		: in		std_logic;
		DataIn_high			: out		std_logic_vector(BITS - 1 downto 0);
		DataIn_low			: out		std_logic_vector(BITS - 1 downto 0);

		Pad							: inout	std_logic_vector(BITS - 1 downto 0)
	);
end entity;


architecture rtl of ddrio_inout_altera is

begin
	-- Generic POWER_UP_HIGH must be left "OFF" to disable output after power-up.
	-- In consequence data input register power-up low.
	ioff : altddio_bidir
		generic map (
			OE_REG 			=> "REGISTERED",
			WIDTH				=> BITS
		)
		port map (
			outclock		=> ClockOut,
			outclocken	=> ClockOutEnable,
			oe					=> OutputEnable,
			datain_h		=> DataOut_high,
			datain_l		=> DataOut_low,

			inclock			=> ClockIn,
			inclocken		=> ClockInEnable,
			dataout_h		=> DataIn_high,
			dataout_l		=> DataIn_low,

			padio				=> Pad
		);
end architecture;
