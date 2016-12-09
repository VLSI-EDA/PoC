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
--	This is a Xilinx specific carry-chain abstraction for increment by one
--	operations.
--
--	Y <= X + (0...0) & Cin
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

library	Unisim;
use			Unisim.VComponents.all;


entity arith_carrychain_inc_xilinx is
	generic (
		BITS			: positive
	);
	port (
		X		: in	std_logic_vector(BITS - 1 downto 0);
		CIn	: in	std_logic															:= '1';
		Y		: out	std_logic_vector(BITS - 1 downto 0)
	);
end entity;


architecture rtl of arith_carrychain_inc_xilinx is
	signal ci		: std_logic_vector(BITS downto 0);
	signal co		: std_logic_vector(BITS downto 0);

begin
	ci(0) <= CIn;
	genBits : for i in 0 to BITS - 1 generate
		cc_mux : MUXCY
			port map (
				O  => ci(i + 1),
				CI => ci(i),
				DI => '0',
				S  => X(i)
			);
		cc_xor : XORCY
			port map (
				O  => Y(i),
				CI => ci(i),
				LI => X(i)
			);
	end generate;
 end architecture;

