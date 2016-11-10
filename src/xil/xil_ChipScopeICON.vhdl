-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Entity:				 	Generic Xilinx ChipScope ICON wrapper
--
-- Description:
-- -------------------------------------
-- This module wraps 15 ChipScope ICON IP core netlists generated from ChipScope
-- ICON xco files. The generic parameter ``PORTS`` selects the apropriate ICON
-- instance with 1 to 15 ICON ``ControlBus`` ports. Each ``ControlBus`` port is
-- of type ``T_XIL_CHIPSCOPE_CONTROL`` and of mode ``inout``.
--
-- .. rubric:: Compile required CoreGenerator IP Cores to Netlists with PoC
--
-- Please use the provided Xilinx ISE compile command ``ise`` in PoC to recreate
-- the needed source and netlist files on your local machine.
--
-- .. code-block:: PowerShell
--
--    cd PoCRoot
--    .\poc.ps1 ise PoC.xil.ChipScopeICON --board=KC705
--
-- SeeAlso:
-- :doc:`Using PoC -> Synthesis </UsingPoC/Synthesis>`
--   For how to run synthesis with PoC and CoreGenerator.
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
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
use			IEEE.STD_LOGIC_1164.all;

library PoC;
use			PoC.xil.all;


entity xil_ChipScopeICON is
	generic (
		PORTS				: positive
	);
  port (
		ControlBus	: inout	T_XIL_CHIPSCOPE_CONTROL_VECTOR(PORTS - 1 downto 0)
	);
end entity;


architecture rtl of xil_ChipScopeICON is
begin
	assert (PORTS < 16) report "To many ICON CONTROL ports." severity failure;

	genICON1 : if PORTS = 1 generate
		ICON : entity PoC.xil_ChipScopeICON_1
			port map (
				CONTROL0		=> ControlBus(0)
			);
	end generate;

	genICON2 : if PORTS = 2 generate
		ICON : entity PoC.xil_ChipScopeICON_2
			port map (
				CONTROL0		=> ControlBus(0),
				CONTROL1		=> ControlBus(1)
			);
	end generate;

	genICON3 : if PORTS = 3 generate
		ICON : entity PoC.xil_ChipScopeICON_3
			port map (
				CONTROL0		=> ControlBus(0),
				CONTROL1		=> ControlBus(1),
				CONTROL2		=> ControlBus(2)
			);
	end generate;

	genICON4 : if PORTS = 4 generate
		ICON : entity PoC.xil_ChipScopeICON_4
			port map (
				CONTROL0		=> ControlBus(0),
				CONTROL1		=> ControlBus(1),
				CONTROL2		=> ControlBus(2),
				CONTROL3		=> ControlBus(3)
			);
	end generate;

	genICON5 : if PORTS = 5 generate
		ICON : entity PoC.xil_ChipScopeICON_5
			port map (
				CONTROL0		=> ControlBus(0),
				CONTROL1		=> ControlBus(1),
				CONTROL2		=> ControlBus(2),
				CONTROL3		=> ControlBus(3),
				CONTROL4		=> ControlBus(4)
			);
	end generate;

	genICON6 : if PORTS = 6 generate
		ICON : entity PoC.xil_ChipScopeICON_6
			port map (
				CONTROL0		=> ControlBus(0),
				CONTROL1		=> ControlBus(1),
				CONTROL2		=> ControlBus(2),
				CONTROL3		=> ControlBus(3),
				CONTROL4		=> ControlBus(4),
				CONTROL5		=> ControlBus(5)
			);
	end generate;

	genICON7 : if PORTS = 7 generate
		ICON : entity PoC.xil_ChipScopeICON_7
			port map (
				CONTROL0		=> ControlBus(0),
				CONTROL1		=> ControlBus(1),
				CONTROL2		=> ControlBus(2),
				CONTROL3		=> ControlBus(3),
				CONTROL4		=> ControlBus(4),
				CONTROL5		=> ControlBus(5),
				CONTROL6		=> ControlBus(6)
			);
	end generate;

	genICON8 : if PORTS = 8 generate
		ICON : entity PoC.xil_ChipScopeICON_8
			port map (
				CONTROL0		=> ControlBus(0),
				CONTROL1		=> ControlBus(1),
				CONTROL2		=> ControlBus(2),
				CONTROL3		=> ControlBus(3),
				CONTROL4		=> ControlBus(4),
				CONTROL5		=> ControlBus(5),
				CONTROL6		=> ControlBus(6),
				CONTROL7		=> ControlBus(7)
			);
	end generate;

	genICON9 : if PORTS = 9 generate
		ICON : entity PoC.xil_ChipScopeICON_9
			port map (
				CONTROL0		=> ControlBus(0),
				CONTROL1		=> ControlBus(1),
				CONTROL2		=> ControlBus(2),
				CONTROL3		=> ControlBus(3),
				CONTROL4		=> ControlBus(4),
				CONTROL5		=> ControlBus(5),
				CONTROL6		=> ControlBus(6),
				CONTROL7		=> ControlBus(7),
				CONTROL8		=> ControlBus(8)
			);
	end generate;

	genICON10 : if PORTS = 10 generate
		ICON : entity PoC.xil_ChipScopeICON_10
			port map (
				CONTROL0		=> ControlBus(0),
				CONTROL1		=> ControlBus(1),
				CONTROL2		=> ControlBus(2),
				CONTROL3		=> ControlBus(3),
				CONTROL4		=> ControlBus(4),
				CONTROL5		=> ControlBus(5),
				CONTROL6		=> ControlBus(6),
				CONTROL7		=> ControlBus(7),
				CONTROL8		=> ControlBus(8),
				CONTROL9		=> ControlBus(9)
			);
	end generate;

	genICON11 : if PORTS = 11 generate
		ICON : entity PoC.xil_ChipScopeICON_11
			port map (
				CONTROL0		=> ControlBus(0),
				CONTROL1		=> ControlBus(1),
				CONTROL2		=> ControlBus(2),
				CONTROL3		=> ControlBus(3),
				CONTROL4		=> ControlBus(4),
				CONTROL5		=> ControlBus(5),
				CONTROL6		=> ControlBus(6),
				CONTROL7		=> ControlBus(7),
				CONTROL8		=> ControlBus(8),
				CONTROL9		=> ControlBus(9),
				CONTROL10		=> ControlBus(10)
			);
	end generate;

	genICON12 : if PORTS = 12 generate
		ICON : entity PoC.xil_ChipScopeICON_12
			port map (
				CONTROL0		=> ControlBus(0),
				CONTROL1		=> ControlBus(1),
				CONTROL2		=> ControlBus(2),
				CONTROL3		=> ControlBus(3),
				CONTROL4		=> ControlBus(4),
				CONTROL5		=> ControlBus(5),
				CONTROL6		=> ControlBus(6),
				CONTROL7		=> ControlBus(7),
				CONTROL8		=> ControlBus(8),
				CONTROL9		=> ControlBus(9),
				CONTROL10		=> ControlBus(10),
				CONTROL11		=> ControlBus(11)
			);
	end generate;

	genICON13 : if PORTS = 13 generate
		ICON : entity PoC.xil_ChipScopeICON_13
			port map (
				CONTROL0		=> ControlBus(0),
				CONTROL1		=> ControlBus(1),
				CONTROL2		=> ControlBus(2),
				CONTROL3		=> ControlBus(3),
				CONTROL4		=> ControlBus(4),
				CONTROL5		=> ControlBus(5),
				CONTROL6		=> ControlBus(6),
				CONTROL7		=> ControlBus(7),
				CONTROL8		=> ControlBus(8),
				CONTROL9		=> ControlBus(9),
				CONTROL10		=> ControlBus(10),
				CONTROL11		=> ControlBus(11),
				CONTROL12		=> ControlBus(12)
			);
	end generate;

	genICON14 : if PORTS = 14 generate
		ICON : entity PoC.xil_ChipScopeICON_14
			port map (
				CONTROL0		=> ControlBus(0),
				CONTROL1		=> ControlBus(1),
				CONTROL2		=> ControlBus(2),
				CONTROL3		=> ControlBus(3),
				CONTROL4		=> ControlBus(4),
				CONTROL5		=> ControlBus(5),
				CONTROL6		=> ControlBus(6),
				CONTROL7		=> ControlBus(7),
				CONTROL8		=> ControlBus(8),
				CONTROL9		=> ControlBus(9),
				CONTROL10		=> ControlBus(10),
				CONTROL11		=> ControlBus(11),
				CONTROL12		=> ControlBus(12),
				CONTROL13		=> ControlBus(13)
			);
	end generate;

	genICON15 : if PORTS = 15 generate
		ICON : entity PoC.xil_ChipScopeICON_15
			port map (
				CONTROL0		=> ControlBus(0),
				CONTROL1		=> ControlBus(1),
				CONTROL2		=> ControlBus(2),
				CONTROL3		=> ControlBus(3),
				CONTROL4		=> ControlBus(4),
				CONTROL5		=> ControlBus(5),
				CONTROL6		=> ControlBus(6),
				CONTROL7		=> ControlBus(7),
				CONTROL8		=> ControlBus(8),
				CONTROL9		=> ControlBus(9),
				CONTROL10		=> ControlBus(10),
				CONTROL11		=> ControlBus(11),
				CONTROL12		=> ControlBus(12),
				CONTROL13		=> ControlBus(13),
				CONTROL14		=> ControlBus(14)
			);
	end generate;
end architecture;
