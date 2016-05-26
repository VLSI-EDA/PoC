-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- ============================================================================
-- Authors:					Martin Zabel
--									Patrick Lehmann
--
-- Module:					Instantiates Chip-Specific DDR Output Registers for Xilinx FPGAs.
--
-- Description:
-- ------------------------------------
--	See PoC.io.ddrio.out for interface description.
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
use			IEEE.std_logic_1164.ALL;

library	UniSim;
use			UniSim.vComponents.all;


entity ddrio_out_xilinx is
	generic (
		NO_OUTPUT_ENABLE		: BOOLEAN			:= false;
		BITS								: POSITIVE;
		INIT_VALUE					: BIT_VECTOR	:= x"FFFFFFFF"
	);
	port (
		Clock					: in	STD_LOGIC;
		ClockEnable		: in	STD_LOGIC;
		OutputEnable	: in	STD_LOGIC;
		DataOut_high	: in	STD_LOGIC_VECTOR(BITS - 1 downto 0);
		DataOut_low		: in	STD_LOGIC_VECTOR(BITS - 1 downto 0);
		Pad						: out	STD_LOGIC_VECTOR(BITS - 1 downto 0)
	);
end entity;


architecture rtl of ddrio_out_xilinx is

begin
	gen : for i in 0 to BITS - 1 generate
		signal o : std_logic;
	begin
		off : ODDR
			generic map(
				DDR_CLK_EDGE	=> "SAME_EDGE",
				INIT					=> INIT_VALUE(i),
				SRTYPE				=> "SYNC"
			)
			port map (
				Q		=> o,
				C		=> Clock,
				CE	=> ClockEnable,
				D1	=> DataOut_high(i),
				D2	=> DataOut_low(i),
				R		=> '0',
				S		=> '0'
			);

		genOE : if not NO_OUTPUT_ENABLE generate
			signal oe_n : std_logic;
			signal t    : std_logic;
		 begin
			oe_n <= not OutputEnable;

			tff : ODDR
				generic map(
					DDR_CLK_EDGE	=> "SAME_EDGE",
					INIT					=> '1',
					SRTYPE				=> "SYNC"
				)
				port map (
					Q		=> t,
					C		=> Clock,
					CE	=> ClockEnable,
					D1	=> oe_n,
					D2	=> oe_n,
					R		=> '0',
					S		=> '0'
				);

			Pad(i) <= o when t = '0' else 'Z';  -- 't' is low-active!
		end generate genOE;

		genNoOE : if NO_OUTPUT_ENABLE generate
			Pad(i) <= o;
		end generate genNoOE;
	end generate;
end architecture;
