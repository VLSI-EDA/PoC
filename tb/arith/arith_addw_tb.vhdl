-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Entity:      arith_addw_tb
--
-- Authors:     Thomas B. Preusser <thomas.preusser@utexas.edu>
--
-- Description:
-- ------------
--   Testbench for arith_addw.
--
-- License:
-- ============================================================================
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--              http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- ============================================================================
entity arith_addw_tb is
end entity arith_addw_tb;


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library PoC;
use PoC.arith.all;
use PoC.simulation.all;

architecture tb of arith_addw_tb is

  -- component generics
  constant N : positive := 9;
  constant K : positive := 2;

	subtype tArch_test is tArch;
	subtype tSkip_test is tSkipping;
	
  -- component ports
  subtype word is std_logic_vector(N-1 downto 0);
  type word_vector is array(tArch_test, tSkip_test, boolean) of word;
  type carry_vector is array(tArch_test, tSkip_test, boolean) of std_logic;

  signal a, b : word;
  signal cin  : std_logic;
  signal s    : word_vector;
  signal cout : carry_vector;

begin

  -- DUTs
  genArchs: for i in tArch_test generate
    genSkips: for j in tSkip_test generate
      genIncl: for p in false to true generate
        DUT : arith_addw
          generic map (
            N           => N,
            K           => K,
            ARCH        => i,
            SKIPPING    => j,
            P_INCLUSIVE => p
          )
          port map (
            a    => a,
            b    => b,
            cin  => cin,
            s    => s(i, j, p),
            cout => cout(i, j, p)
          );
      end generate genIncl;
    end generate;
  end generate;

  -- Stimuli
  process
  begin
    for i in natural range 0 to 2**N-1 loop
      a <= std_logic_vector(to_unsigned(i, N));
      for j in natural range 0 to 2**N-1 loop
        b <= std_logic_vector(to_unsigned(j, N));

        cin <= '0';
        wait for 5 ns;
        for arch in tArch_test loop
					for skip in tSkip_test loop
						for incl in boolean loop
							tbAssert((i+j) mod 2**(N+1) = to_integer(unsigned(cout(arch, skip, incl) & s(arch, skip, incl))),
								  "Output Error["&tArch'image(arch)&','&tSkipping'image(skip)&','&boolean'image(incl)&"]: "&
								  integer'image(i)&'+'&integer'image(j)&" != "&
								  integer'image(to_integer(unsigned(cout(arch, skip, incl) & s(arch, skip, incl)))));
						end loop;
					end loop;
        end loop;
        
        cin <= '1';
        wait for 5 ns;
        for arch in tArch_test loop
					for skip in tSkip_test loop
						for incl in boolean loop
							tbAssert((i+j+1) mod 2**(N+1) = to_integer(unsigned(cout(arch, skip, incl) & s(arch, skip, incl))),
								  "Output Error["&tArch'image(arch)&','&tSkipping'image(skip)&','&boolean'image(incl)&"]: "&
								  integer'image(i)&'+'&integer'image(j)&"+1 != "&
								  integer'image(to_integer(unsigned(cout(arch, skip, incl) & s(arch, skip, incl)))));
						end loop;
					end loop;
        end loop;

      end loop;  -- j
    end loop;  -- i
    tbPrintResult;
    wait;                               -- forever
  end process;

end architecture tb;
