-- EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Thomas B. Preusser
--									Patrick Lehmann
--
-- Entity:					Prefix AND computation
--
-- Description:
-- -------------------------------------
--	Prefix AND computation:
--		y(i) <= '1' when x(i downto 0) = (i downto 0 => '1') else '0'
--	This implementation uses carry chains for wider implementations.
--
-- =============================================================================
-- Copyright 2007-2016 Technische Universität Dresden - Germany
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

library	ieee;
use			ieee.std_logic_1164.all;
use			ieee.numeric_std.all;

library UniSim;
use			UniSim.VComponents.all;


entity arith_prefix_and_xilinx is
	generic (
		N : positive
	);
	port (
		x : in	std_logic_vector(N-1 downto 0);
		y : out std_logic_vector(N-1 downto 0)
	);
end entity;


architecture rtl of arith_prefix_and_xilinx is
	signal c	: std_logic_vector(N-1 downto 0);
begin
	y(0) <= x(0);
	gen1: if N > 1 generate
		signal	p : unsigned(N-1 downto 1);
	begin
		p(1) <= x(0) and x(1);
		gen2: if N > 2 generate
			p(N-1 downto 2) <= unsigned(x(N-1 downto 2));
			c(0) <= '1';
			genChain: for i in 1 to N-1 generate
				mux : MUXCY
					port map (
						S	=> p(i),
						DI => '0',
						CI => c(i-1),
						O	=> c(i)
					);
				end generate genChain;
			y(N-1 downto 2) <= c(N-1 downto 2);
		end generate gen2;
		y(1) <= p(1);
	end generate gen1;
end architecture;
