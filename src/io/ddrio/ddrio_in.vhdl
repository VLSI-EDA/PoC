-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Martin Zabel
--									Patrick Lehmann
--
-- Entity:					Chip-Specific DDR Input Registers
--
-- Description:
-- -------------------------------------
-- Instantiates chip-specific DDR input registers.
--
-- Both data "DataIn_high/low" are synchronously outputted to the on-chip logic
-- with the rising edge of "Clock". "DataIn_high" is the value at the "Pad"
-- sampled with the same rising edge. "DataIn_low" is the value sampled with
-- the falling edge directly before this rising edge. Thus sampling starts with
-- the falling edge of the clock as depicted in the following waveform.
--              __      ____      ____      __
-- Clock          |____|    |____|    |____|
-- Pad          < 0 >< 1 >< 2 >< 3 >< 4 >< 5 >
-- DataIn_low      ... >< 0      >< 2      ><
-- DataIn_high     ... >< 1      >< 3      ><
--
-- < i > is the value of the i-th data bit on the line.
--
-- After power-up, the output ports "DataIn_high" and "DataIn_low" both equal
-- INIT_VALUE.
--
-- "Pad" must be connected to a PAD because FPGAs only have these registers in
-- IOBs.
--
-- License:
-- =============================================================================
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
-- =============================================================================


library	IEEE;
use			IEEE.std_logic_1164.all;

library	PoC;
use			PoC.config.all;
use			PoC.utils.all;
use			PoC.ddrio.all;


entity ddrio_in is
	generic (
		BITS					: POSITIVE;
		INIT_VALUE		: BIT_VECTOR	:= x"FFFFFFFF"
	);
	port (
		Clock					: in		STD_LOGIC;
		ClockEnable		: in		STD_LOGIC;
		DataIn_high		: out		STD_LOGIC_VECTOR(BITS - 1 downto 0);
		DataIn_low		: out		STD_LOGIC_VECTOR(BITS - 1 downto 0);
		Pad						: in		STD_LOGIC_VECTOR(BITS - 1 downto 0)
		);
end entity;


architecture rtl of ddrio_in is

begin
	assert ((VENDOR = VENDOR_ALTERA) or ((SIMULATION = TRUE) and (VENDOR = VENDOR_GENERIC)) or (VENDOR = VENDOR_XILINX))
		report "PoC.io.ddrio.in is not implemented for given DEVICE."
		severity FAILURE;

	genXilinx : if (VENDOR = VENDOR_XILINX) generate
		i : ddrio_in_xilinx
			generic map (
				BITS				=> BITS,
				INIT_VALUE	=> INIT_VALUE
			)
			port map (
				Clock				=> Clock,
				ClockEnable	=> ClockEnable,
				DataIn_high	=> DataIn_high,
				DataIn_low	=> DataIn_low,
				Pad					=> Pad
			);
	end generate;

	genAltera : if (VENDOR = VENDOR_ALTERA) generate
		i : ddrio_in_altera
			generic map (
				BITS				=> BITS,
				INIT_VALUE	=> INIT_VALUE
			)
			port map (
				Clock				=> Clock,
				ClockEnable	=> ClockEnable,
				DataIn_high	=> DataIn_high,
				DataIn_low	=> DataIn_low,
				Pad					=> Pad
			);
	end generate;

	genGeneric : if ((SIMULATION = TRUE) and (VENDOR = VENDOR_GENERIC)) generate
		signal Pad_d_fe				: STD_LOGIC_VECTOR(BITS - 1 downto 0) := to_stdlogicvector(INIT_VALUE);
		signal DataIn_high_d	: STD_LOGIC_VECTOR(BITS - 1 downto 0) := to_stdlogicvector(INIT_VALUE);
		signal DataIn_low_d		: STD_LOGIC_VECTOR(BITS - 1 downto 0) := to_stdlogicvector(INIT_VALUE);
	begin
		Pad_d_fe				<= Pad			when falling_edge(Clock)	and (ClockEnable = '1');
		DataIn_high_d		<= Pad			when rising_edge(Clock)		and (ClockEnable = '1');
		DataIn_low_d		<= Pad_d_fe	when rising_edge(Clock)		and (ClockEnable = '1');

		DataIn_high			<= DataIn_high_d;
		DataIn_low			<= DataIn_low_d;
	end generate;
end architecture;
