-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Authors:					Martin Zabel
--									Patrick Lehmann
-- 
-- Module:					Chip-Specific DDR Input and Output Registers
--
-- Description:
-- ------------------------------------
--	Instantiates chip-specific DDR input and output registers.
--	
--	"OutputEnable" (Tri-State) is high-active. It is automatically inverted if
--	necessary. If an output enable is not required, you may save some logic by
--	setting NO_OUTPUT_ENABLE = true. However, "OutputEnable" must be set to '1'.
--	
--	Both data "DataOut_high/low" as well as "OutputEnable" are sampled with
--	the rising_edge(Clock) from the on-chip logic. "DataOut_high" is brought
--	out with this rising edge. "DataOut_low" is brought out with the falling
--	edge.
--	
--	"Pad" must be connected to a PAD because FPGAs only have these registers in
--	IOBs.
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


library	IEEE;
use			IEEE.std_logic_1164.all;

library	PoC;
use			PoC.config.all;
use			PoC.ddrio.all;


entity ddrio_out is
	generic (
		NO_OUTPUT_ENABLE		: BOOLEAN			:= false;
		BITS								: POSITIVE;
		INIT_VALUE_OUT			: BIT_VECTOR	:= "1";
		INIT_VALUE_IN_HIGH	: BIT_VECTOR	:= "1";
		INIT_VALUE_IN_LOW		: BIT_VECTOR	:= "1"
	);
	port (
		Clock					: in		STD_LOGIC;
		ClockEnable		: in		STD_LOGIC;
		OutputEnable	: in		STD_LOGIC;		
		DataOut_high	: in		STD_LOGIC_VECTOR(BITS - 1 downto 0);
		DataOut_low		: in		STD_LOGIC_VECTOR(BITS - 1 downto 0);
		DataIn_high		: out		STD_LOGIC_VECTOR(BITS - 1 downto 0);
		DataIn_low		: out		STD_LOGIC_VECTOR(BITS - 1 downto 0);
		Pad						: inout	STD_LOGIC_VECTOR(BITS - 1 downto 0)
	);
end entity;


architecture rtl of ddrio_out is
  
begin
	assert (VENDOR = VENDOR_XILINX) or (VENDOR = VENDOR_ALTERA)
		report "PoC.io.ddrio.inout is not implemented for given DEVICE."
		severity FAILURE;
	
	genXilinx : if (VENDOR = VENDOR_XILINX) generate
		inst : ddrio_inout_xilinx
			generic map (
				NO_OUTPUT_ENABLE		=> NO_OUTPUT_ENABLE,
				BITS								=> BITS,
				INIT_VALUE_OUT			=> INIT_VALUE_OUT,
				INIT_VALUE_IN_HIGH	=> INIT_VALUE_IN_HIGH,
				INIT_VALUE_IN_LOW		=> INIT_VALUE_IN_LOW
			)
			port map (
				Clock					=> Clock,
				ClockEnable		=> ClockEnable,
				OutputEnable	=> OutputEnable,
				DataOut_high	=> DataOut_high,
				DataOut_low		=> DataOut_low,
				DataIn_high		=> DataIn_high,
				DataIn_low		=> DataIn_low,
				Pad						=> Pad
			);
	end generate;

	genAltera : if (VENDOR = VENDOR_ALTERA) generate
		inst : ddrio_inout_altera
			generic map (
				BITS								=> BITS
			)
			port map (
				Clock					=> Clock,
				ClockEnable		=> ClockEnable,
				OutputEnable	=> OutputEnable,
				DataOut_high	=> DataOut_high,
				DataOut_low		=> DataOut_low,
				DataIn_high		=> DataIn_high,
				DataIn_low		=> DataIn_low,
				Pad						=> Pad
			);
	end generate;
end architecture;
