-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Entity:					Carry-chain abstraction for increment by one operations
--
-- Description:
-- -------------------------------------
-- This is a generic carry-chain abstraction for increment by one operations.
--
-- Y <= X + (0...0) & Cin
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
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;

library	PoC;
use			PoC.config.all;
use			PoC.utils.all;
use			PoC.arith.all;


entity arith_carrychain_inc is
	generic (
		BITS			: positive
	);
	port (
		X		: in	std_logic_vector(BITS - 1 downto 0);
		CIn	: in	std_logic															:= '1';
		Y		: out	std_logic_vector(BITS - 1 downto 0)
	);
end entity;


architecture rtl of arith_carrychain_inc is
	-- Force Carry-chain use for pointer increments on Xilinx architectures
  constant XILINX_FORCE_CARRYCHAIN		: boolean		:= (not SIMULATION) and (VENDOR = VENDOR_XILINX) and (BITS > 4);

begin
	genGeneric : if not XILINX_FORCE_CARRYCHAIN generate
		signal Cin_vec : unsigned(0 downto 0);
	begin
		Cin_vec(0) <= Cin; -- WORKAROUND: for GHDL
		Y <= std_logic_vector(unsigned(X) + Cin_vec);
	end generate;

	genXilinx : if XILINX_FORCE_CARRYCHAIN generate
		inc : arith_carrychain_inc_xilinx
			generic map (
				BITS		=> BITS
			)
			port map (
				X				=> X,
				CIn			=> CIn,
				Y				=> Y
			);
	end generate;
end architecture;
