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
--	Both data "DataOut_high/low" as well as "OutputEnable" are sampled with
--	the rising_edge(Clock) from the on-chip logic. "DataOut_high" is brought
--	out with this rising edge. "DataOut_low" is brought out with the falling
--	edge.
--	
--	"OutputEnable" (Tri-State) is high-active. It is automatically inverted if
--	necessary. Output is disabled after power-up.
--	
--	Both data "DataIn_high/low" are synchronously outputted to the on-chip logic
--  with the rising edge of "Clock". "DataIn_high" is the value at the "Pad" 
--  sampled with the same rising edge. "DataIn_low" is the value sampled with 
--  the falling edge directly before this rising edge. Thus sampling starts with
--  the falling edge of the clock as depicted in the following waveform.
--               __      ____      ____      __
--  Clock          |____|    |____|    |____|
--  Pad          < 0 >< 1 >< 2 >< 3 >< 4 >< 5 >
--  DataIn_low      ... >< 0      >< 2      ><
--  DataIn_high     ... >< 1      >< 3      ><
--
--	< i > is the value of the i-th data bit on the line.
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


entity ddrio_inout is
	generic (
		BITS					: POSITIVE
	);
	port (
		ClockOut				: in		STD_LOGIC;
		ClockOutEnable	: in		STD_LOGIC;
		OutputEnable		: in		STD_LOGIC;		
		DataOut_high		: in		STD_LOGIC_VECTOR(BITS - 1 downto 0);
		DataOut_low			: in		STD_LOGIC_VECTOR(BITS - 1 downto 0);
		
		ClockIn					: in		STD_LOGIC;
		ClockInEnable		: in		STD_LOGIC;
		DataIn_high			: out		STD_LOGIC_VECTOR(BITS - 1 downto 0);
		DataIn_low			: out		STD_LOGIC_VECTOR(BITS - 1 downto 0);
		
		Pad							: inout	STD_LOGIC_VECTOR(BITS - 1 downto 0)
	);
end entity;


architecture rtl of ddrio_inout is
  
begin
	assert (VENDOR = VENDOR_XILINX) or (VENDOR = VENDOR_ALTERA)
		report "PoC.io.ddrio.inout is not implemented for given DEVICE."
		severity FAILURE;
	
	genXilinx : if (VENDOR = VENDOR_XILINX) generate
		inst : ddrio_inout_xilinx
			generic map (
				BITS						=> BITS
			)
			port map (
				ClockOut				=> ClockOut,
				ClockOutEnable	=> ClockOutEnable,
				OutputEnable		=> OutputEnable,
				DataOut_high		=> DataOut_high,
				DataOut_low			=> DataOut_low,
				ClockIn					=> ClockIn,
				ClockInEnable		=> ClockInEnable,
				DataIn_high			=> DataIn_high,
				DataIn_low			=> DataIn_low,
				Pad							=> Pad
			);
	end generate;

	genAltera : if (VENDOR = VENDOR_ALTERA) generate
		inst : ddrio_inout_altera
			generic map (
				BITS						=> BITS
			)
			port map (
				ClockOut				=> ClockOut,
				ClockOutEnable	=> ClockOutEnable,
				OutputEnable		=> OutputEnable,
				DataOut_high		=> DataOut_high,
				DataOut_low			=> DataOut_low,
				ClockIn					=> ClockIn,
				ClockInEnable		=> ClockInEnable,
				DataIn_high			=> DataIn_high,
				DataIn_low			=> DataIn_low,
				Pad							=> Pad
			);
	end generate;
end architecture;
