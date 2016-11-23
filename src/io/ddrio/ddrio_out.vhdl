-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Martin Zabel
--									Patrick Lehmann
--
-- Entity:					Chip-Specific DDR Output Registers
--
-- Description:
-- -------------------------------------
-- Instantiates chip-specific :abbr:`DDR (Double Data Rate)` output registers.
--
-- Both data ``DataOut_high/low`` as well as ``OutputEnable`` are sampled with
-- the ``rising_edge(Clock)`` from the on-chip logic. ``DataOut_high`` is brought
-- out with this rising edge. ``DataOut_low`` is brought out with the falling
-- edge.
--
-- ``OutputEnable`` (Tri-State) is high-active. It is automatically inverted if
-- necessary. If an output enable is not required, you may save some logic by
-- setting ``NO_OUTPUT_ENABLE = true``.
--
-- If ``NO_OUTPUT_ENABLE = false`` then output is disabled after power-up.
-- If ``NO_OUTPUT_ENABLE = true`` then output after power-up equals ``INIT_VALUE``.
--
-- .. wavedrom::
--
--    { signal: [
--      ['DataOut',
--        {name: 'ClockOut',        wave: 'L.H.L.H.L.H.L.H.'},
--        {name: 'ClockOutEnable',  wave: '01...........0..'},
--        {name: 'OutputEnable',    wave: '01.......0......'},
--        {name: 'DataOut_low',     wave: 'x2...4...x......', data: ['0',      '2'],      node: '.k...m'},
--        {name: 'DataOut_high',    wave: 'x3...5...x......', data: ['1',      '3'],      node: '.l...n'}
--        ],
--        {},
--        {name: 'Pad',             wave: 'x.....2.3.4.5.z.', data: ['0', '1', '2', '3'], node: '......a.b.c.d.'},
--      ],
--      edge: ['k~>a', 'l~>b', 'm~>c', 'n~>d'],
--      foot: {
--        text: ['tspan',
--          ['tspan', {'font-weight': 'bold'}, 'PoC.io.ddrio.out'],
--          ' -- DDR Data Output sampled from pad.'
--        ]
--      }
--    }
--
-- ``Pad`` must be connected to a PAD because FPGAs only have these registers in
-- IOBs.
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


library	IEEE;
use			IEEE.std_logic_1164.all;

library	PoC;
use			PoC.config.all;
use			PoC.utils.all;
use			PoC.ddrio.all;


entity ddrio_out is
	generic (
		NO_OUTPUT_ENABLE		: boolean			:= false;
		BITS								: positive;
		INIT_VALUE					: bit_vector	:= x"FFFFFFFF"
	);
	port (
		Clock					: in	std_logic;
		ClockEnable		: in	std_logic := '1';
		OutputEnable	: in	std_logic := '1';
		DataOut_high	: in	std_logic_vector(BITS - 1 downto 0);
		DataOut_low		: in	std_logic_vector(BITS - 1 downto 0);
		Pad						: out	std_logic_vector(BITS - 1 downto 0)
	);
end entity;


architecture rtl of ddrio_out is

begin
	assert ((VENDOR = VENDOR_ALTERA) or ((SIMULATION = TRUE) and (VENDOR = VENDOR_GENERIC)) or (VENDOR = VENDOR_XILINX))
		report "PoC.io.ddrio.out is not implemented for given DEVICE."
		severity FAILURE;

	genXilinx : if VENDOR = VENDOR_XILINX generate
		i : ddrio_out_xilinx
			generic map (
				NO_OUTPUT_ENABLE	=> NO_OUTPUT_ENABLE,
				BITS							=> BITS,
				INIT_VALUE				=> INIT_VALUE
			)
			port map (
				Clock					=> Clock,
				ClockEnable		=> ClockEnable,
				OutputEnable	=> OutputEnable,
				DataOut_high	=> DataOut_high,
				DataOut_low		=> DataOut_low,
				Pad						=> Pad
			);
	end generate;

	genAltera : if VENDOR = VENDOR_ALTERA generate
		i : ddrio_out_altera
			generic map (
				NO_OUTPUT_ENABLE	=> NO_OUTPUT_ENABLE,
				BITS							=> BITS,
				INIT_VALUE				=> INIT_VALUE
			)
			port map (
				Clock					=> Clock,
				ClockEnable		=> ClockEnable,
				OutputEnable	=> OutputEnable,
				DataOut_high	=> DataOut_high,
				DataOut_low		=> DataOut_low,
				Pad						=> Pad
			);
	end generate;

	genGeneric : if SIMULATION  and (VENDOR = VENDOR_GENERIC) generate
		signal DataOut_high_d	: std_logic_vector(BITS - 1 downto 0) := to_stdlogicvector(INIT_VALUE);
		signal DataOut_low_d	: std_logic_vector(BITS - 1 downto 0) := to_stdlogicvector(INIT_VALUE);
		signal OutputEnable_d	: std_logic;
		signal Pad_o					: std_logic_vector(BITS - 1 downto 0) := to_stdlogicvector(INIT_VALUE);
	begin
		DataOut_high_d	<= DataOut_high		when rising_edge(Clock) and (ClockEnable = '1');
		DataOut_low_d		<= DataOut_low		when rising_edge(Clock) and (ClockEnable = '1');
		OutputEnable_d	<= OutputEnable		when rising_edge(Clock) and (ClockEnable = '1');

		process(Clock, OutputEnable_d, DataOut_high_d, DataOut_low_d)
			type T_MUX is array(bit) of std_logic_vector(BITS - 1 downto 0);
			variable MuxInput		: T_MUX;
		begin
			MuxInput('1')	:= DataOut_high_d;
			MuxInput('0')	:= DataOut_low_d;

			if (OutputEnable_d = '1') or NO_OUTPUT_ENABLE then
				Pad_o		<= MuxInput(to_bit(Clock));
			else
				Pad_o		<= (others => 'Z');
			end if;
		end process;

		Pad			<= Pad_o;
	end generate;
end architecture;
