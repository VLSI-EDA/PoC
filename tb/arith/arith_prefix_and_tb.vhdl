-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- =============================================================================
-- Authors:					Thomas B. Preusser
--									Patrick Lehmann
-- 
-- Testbench:				Testbench for arith_prefix_and.
-- 
-- Description:
-- ------------------------------------
--		Automated testbench for PoC.arith.prefix_and
--
-- License:
-- =============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany
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

entity arith_prefix_and_tb is
end arith_prefix_and_tb;

library	IEEE;
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;

library PoC;
use			PoC.simulation.ALL;


architecture tb of arith_prefix_and_tb is
  -- component generics
  constant N : positive := 8;

  -- component ports
  signal x : std_logic_vector(N-1 downto 0);
  signal y : std_logic_vector(N-1 downto 0);

begin  -- tb

  -- component instantiation
  DUT: entity PoC.arith_prefix_and
    generic map (
      N => N
    )
    port map (
      x => x,
      y => y
    );

  -- Stimuli
  process
  begin
		-- Exhaustive Testing
    for i in NATURAL range 0 to 2**N-1 loop
      x <= std_logic_vector(to_unsigned(i, N));
      wait for 10 ns;
      for j in 0 to N-1 loop
				tbAssert((y(j) = '1') = (x(j downto 0) = (j downto 0 => '1')),
								 "Wrong result for "&integer'image(i)&" / "&integer'image(j));
			end loop;
    end loop;

		-- Report overall result
		tbPrintResult;

    wait;  -- forever
  end process;

end tb;
