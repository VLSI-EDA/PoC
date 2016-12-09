-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Martin Zabel
--									Patrick Lehmann
--
-- Entity:					Chip-Specific DDR Input and Output Registers
--
-- Description:
-- -------------------------------------
-- Instantiates chip-specific :abbr:`DDR (Double Data Rate)` input and output
-- registers.
--
-- Both data ``DataOut_high/low`` as well as ``OutputEnable`` are sampled with
-- the ``rising_edge(Clock)`` from the on-chip logic. ``DataOut_high`` is brought
-- out with this rising edge. ``DataOut_low`` is brought out with the falling
-- edge.
--
-- ``OutputEnable`` (Tri-State) is high-active. It is automatically inverted if
-- necessary. Output is disabled after power-up.
--
-- Both data ``DataIn_high/low`` are synchronously outputted to the on-chip logic
-- with the rising edge of ``Clock``. ``DataIn_high`` is the value at the ``Pad``
-- sampled with the same rising edge. ``DataIn_low`` is the value sampled with
-- the falling edge directly before this rising edge. Thus sampling starts with
-- the falling edge of the clock as depicted in the following waveform.
--
-- .. wavedrom::
--
--    { signal: [
--      ['DataOut',
--        {name: 'ClockOut',        wave: 'LH.L.H.L.H.L.H.L.H.L.H.'},
--        {name: 'ClockOutEnable',  wave: '0..1...................'},
--        {name: 'OutputEnable',    wave: '0.......1.......0......'},
--        {name: 'DataOut_low',     wave: 'x.......2...4...x......', data: ['4',      '6'],      node: '........k...m...o..'},
--        {name: 'DataOut_high',    wave: 'x.......3...5...x......', data: ['5',      '7'],      node: '........l...n...p..'}
--        ],
--        {},
--        {name: 'Pad',             wave: 'x2.3.4.5.z...2.3.4.5.z.', data: ['0', '1', '2', '3', '4', '5', '6', '7'], node: '.a.b.c.d.....e.f.g.h.'},
--        {},
--      ['DataIn',
--        {name: 'ClockIn',         wave: 'L.H.L.H.L.H.L.H.L.H.L.H'},
--        {name: 'ClockInEnable',   wave: '01.......0.............'},
--        {name: 'DataIn_low',      wave: 'x.....2...4...z...2...4', data: ['0',      '2',      '4'],      node: '......u...w.......y..'},
--        {name: 'DataIn_high',     wave: 'x.....3...5...z...3...5', data: ['1',      '3',      '5'],      node: '......v...x.......z..'}
--      ]
--      ],
--      edge: ['a~>u', 'b~>v', 'c~>w', 'd~>x', 'k~>e', 'l~>f', 'm~>g', 'n~>h', 'e~>y', 'f~>z'],
--      foot: {
--        text: ['tspan',
--          ['tspan', {'font-weight': 'bold'}, 'PoC.io.ddrio.inout'],
--          ' -- DDR Data Input/Output sampled from pad.'
--        ]
--      }
--    }
--
-- ``Pad`` must be connected to a PAD because FPGAs only have these registers in
-- IOBs.
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


library	IEEE;
use			IEEE.std_logic_1164.all;

library	PoC;
use			PoC.utils.all;
use			PoC.config.all;
use			PoC.ddrio.all;


entity ddrio_inout is
	generic (
		BITS					: positive
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


architecture rtl of ddrio_inout is

begin
	assert ((VENDOR = VENDOR_ALTERA) or ((SIMULATION = TRUE) and (VENDOR = VENDOR_GENERIC)) or (VENDOR = VENDOR_XILINX))
		report "PoC.io.ddrio.inout is not implemented for given DEVICE."
		severity FAILURE;

	genXilinx : if VENDOR = VENDOR_XILINX generate
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

	genAltera : if VENDOR = VENDOR_ALTERA generate
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

	genGeneric : if SIMULATION  and (VENDOR = VENDOR_GENERIC) generate
		signal DataOut_high_d	: std_logic_vector(BITS - 1 downto 0);
		signal DataOut_low_d	: std_logic_vector(BITS - 1 downto 0);
		signal OutputEnable_d	: std_logic;
		signal Pad_o					: std_logic_vector(BITS - 1 downto 0);

		signal Pad_d_fe				: std_logic_vector(BITS - 1 downto 0);
		signal DataIn_high_d	: std_logic_vector(BITS - 1 downto 0);
		signal DataIn_low_d		: std_logic_vector(BITS - 1 downto 0);
	begin
		DataOut_high_d	<= DataOut_high		when rising_edge(ClockOut) and (ClockOutEnable = '1');
		DataOut_low_d		<= DataOut_low		when rising_edge(ClockOut) and (ClockOutEnable = '1');
		OutputEnable_d	<= OutputEnable		when rising_edge(ClockOut) and (ClockOutEnable = '1');

		process(ClockOut, OutputEnable_d, DataOut_high_d, DataOut_low_d)
			type T_MUX is array(bit) of std_logic_vector(BITS - 1 downto 0);
			variable MuxInput		: T_MUX;
		begin
			MuxInput('1')	:= DataOut_high_d;
			MuxInput('0')	:= DataOut_low_d;

			if (OutputEnable_d = '1') then
				Pad_o		<= MuxInput(to_bit(ClockOut));
			else
				Pad_o		<= (others => 'Z');
			end if;
		end process;

		Pad			<= Pad_o;

		Pad_d_fe				<= Pad			when falling_edge(ClockIn)	and (ClockInEnable = '1');
		DataIn_high_d		<= Pad			when rising_edge(ClockIn)		and (ClockInEnable = '1');
		DataIn_low_d		<= Pad_d_fe	when rising_edge(ClockIn)		and (ClockInEnable = '1');

		DataIn_high			<= DataIn_high_d;
		DataIn_low			<= DataIn_low_d;
	end generate;
end architecture;
