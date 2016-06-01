-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- ===========================================================================
-- Module:				 	Poc.arith_counter_free
--
-- Authors:				 	Thomas B. Preusser
--
-- Description:
-- ------------
--		Implements a free-running counter that generates a strobe signal
--    every DIVIDER-th cycle the increment input was asserted.
--    There is deliberately no output or specification of the counter
--    value so as to allow an implementation to optimize as much as
--    possible.
--    The implementation guarantees a strobe output directly from a
--    register. It is asserted exactly for one clock after DIVIDER cycles
--    of an asserted increment input have been observed.
--
-- License:
-- ===========================================================================
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
-- ===========================================================================

library	IEEE;
use			IEEE.std_logic_1164.all;

entity arith_counter_free is
	generic (
		DIVIDER : positive
	);
	port (
		-- Global Control
		clk : in	std_logic;
		rst : in	std_logic;

		inc : in  std_logic;
    stb : out std_logic  								-- End-of-Period Strobe
  );
end arith_counter_free;


library IEEE;
use IEEE.numeric_std.all;

library PoC;
use PoC.utils.all;

architecture rtl of arith_counter_free is
begin

	genNoDiv: if DIVIDER = 1 generate
		process(clk)
		begin
			if rising_edge(clk) then
				stb <= inc;
			end if;
		end process;
	end generate genNoDiv;
	genDoDiv: if DIVIDER > 1 generate
		-- Note: For DIVIDER=2**K+1, this could be marginally reduced to log2ceil(DIVIDER-1)
		--       if it was known that the increment input inc would never be deasserted.
		constant N : natural := log2ceil(DIVIDER);
		signal Cnt : unsigned(N downto 0) := (others => '0');

		signal cin : unsigned(0 downto 0);
	begin
		cin(0) <= not inc;
		process(clk)
		begin
			if rising_edge(clk) then
				if rst = '1' then
					Cnt <= to_unsigned(DIVIDER-2, N+1);
				else
					Cnt <= Cnt + ite(Cnt(N) = '0', (Cnt'range => '1'), to_unsigned(DIVIDER-1, N+1)) + cin;
				end if;
			end if;
		end process;
		stb <= Cnt(N);
	end generate genDoDiv;

end rtl;
