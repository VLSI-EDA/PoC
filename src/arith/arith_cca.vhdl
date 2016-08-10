-- ===================================================================================
-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- =============================================================================
-- Description: Carry-Compact Adder for Xilinx Virtex-5 architectures and newer.
--
--   A carry-compact adder (CCA) utilizes the fast carry chain of contemporary
--   FPGA devices to implement a fast and even compacted binary word addition.
--   For wide operands, it accounts for the delay encountered even on this fast
--   signal path and uses the associated time to perform a significantly
--   shorter but effective LUT-based parallel computation that reduces the
--   length of the internal ripple-carry adder without affecting the critical
--   path length.
--   The compaction performed by the CCA is performed hierarchical on
--   potentially multiple levels. The number of levels may be restricted by the
--   optional generic parameter X. A linear compaction on a single level may
--   be of special interest as it typically does not increase the LUT demand
--   in comparison to a standard RCA implementation.
--   The parameter L is architecture-dependent and estimates the delay of a LUT
--   stage in terms of carry-chain hops. It is a tuning parameter. Values
--   around 20 are a good starting point.
--
--   For a detailed description see:    http://dx.doi.org/10.1109/ARITH.2011.22
--
--      Preusser, T.B.; Zabel, M.; Spallek, R.G.:
--      "Accelerating Computations on FPGA Carry Chains by Operand Compaction",
--      20th IEEE Symposium on Computer Arithmetic (ARITH), 2011.
--
-- Author:      Thomas B. Preusser
-- ================================================================================
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
-- ===================================================================================

library IEEE;
use IEEE.std_logic_1164.all;

entity arith_cca is
  generic(
    N : positive;          -- bit width
    L : natural;           -- CC length equivalent per LUT stage
    X : natural := 0       -- max expansion depth; default: zero (0) - unlimited
  );
  port(
    a : in  std_logic_vector(N-1 downto 0);
    b : in  std_logic_vector(N-1 downto 0);
    c : in  std_logic := '0';
    s : out std_logic_vector(N-1 downto 0)
  );
end arith_cca;


library IEEE;
use IEEE.numeric_std.all;

architecture rtl of arith_cca is

  type tLevel is record
                   base : natural;
                   core : integer;
                   done : natural;
                 end record tLevel;
  type tLevels is array(natural range<>) of tLevel;

  function compact return tLevels is
    variable res : tLevels(0 to 31);
    variable base, core, done : integer;
  begin
    base := 0;
    core := (N-L)/2;
    done := N-2*core;
    for i in res'range loop
      res(i) := (base, core, done);
      if core <= 0 then
        for j in 0 to i loop
          report integer'image(j)&": ("&integer'image(res(j).base)&", "&integer'image(res(j).core)&", "&integer'image(res(j).done)&")" severity note;
        end loop;  -- j
        return  res(0 to i);
      end if;
      base := base + 2*core;
      done := done + (core-2*(core/2)+L);
      core := core/2 - L;
      if i+1 = X and core > 0 then
        done := done + 2*core;
        core := 0;
      end if;
    end loop;
  end function compact;
  constant LEVELS : tLevels := compact;
  constant CCA : boolean := LEVELS'length > 1;

begin
  genRCA: if not CCA generate
    assert false
      report "Using standard RCA for small "&integer'image(N)&"-bit adder."
      severity note;
    s <= std_logic_vector(unsigned(a)+unsigned(b)+(0 to 0 => c));
  end generate;

  genCCA: if CCA generate
    constant WI : positive := LEVELS(LEVELS'high).base;
    constant WC : positive := LEVELS(LEVELS'high).done + LEVELS'high*L + 2*LEVELS(LEVELS'high).core;

    signal ai, bi, si : std_logic_vector(WI-1 downto 0);
    signal ac, bc, sc : unsigned(WC-1 downto 0);
  begin

    -- Feed operands into compaction tree except for a prefix of L bits
    -- to hide expansion delay of lower-order bits
    blkFeed: block is
      constant DONE : natural := LEVELS(0).done;
    begin
      -- alias most-significant prefix of ports and compacted operation
      genPre: if DONE > 0 generate
        ac(WC-1 downto WC-DONE) <= unsigned(a(N-1 downto N-DONE));
        bc(WC-1 downto WC-DONE) <= unsigned(b(N-1 downto N-DONE));
        s(N-1 downto N-DONE) <= std_logic_vector(sc(WC-1 downto WC-DONE));
      end generate genPre;

      -- copy compaction region
      ai(N-DONE-1 downto 0) <= a(N-DONE-1 downto 0);
      bi(N-DONE-1 downto 0) <= b(N-DONE-1 downto 0);
      s(N-DONE-1 downto 0) <= si(N-DONE-1 downto 0);
    end block blkFeed;

    -- Build the compaction tree
    genCompact: for i in 1 to LEVELS'high generate
      constant PAIRS : positive := LEVELS(i-1).core;

      constant BASE : natural := LEVELS(i).base;
      constant CORE : integer := LEVELS(i).core;
      constant DONE : natural := LEVELS(i).done;

    begin
      genPairs: for j in 0 to PAIRS-1 generate
        signal b1, b0, a1, a0 : std_logic;
        signal ss             : std_logic;
      begin
        -- Compaction ------

        -- Simplify Names
        b1 <= bi(BASE-2*(PAIRS-j)+1);
        b0 <= bi(BASE-2*(PAIRS-j)+0);
        a1 <= ai(BASE-2*(PAIRS-j)+1);
        a0 <= ai(BASE-2*(PAIRS-j)+0);

        genLast: if CORE <= 0 or j < L or L+2*CORE <= j generate
          signal aa, bb : std_logic;
        begin
          aa <= (b1 and a1) or (b1 and a0) or (a1 and a0);
          bb <= (b1 and a1) or (b1 and b0) or (a1 and b0);

          genSuf: if CORE <= 0 or j < L generate
            ac((i-1)*L+j) <= aa;
            bc((i-1)*L+j) <= bb;
            ss <= sc((i-1)*L+j);
          end generate genSuf;
          genPre: if CORE > 0 and L+2*CORE <= j generate
            ac(j-L-2*CORE+(WC-DONE)) <= aa;
            bc(j-L-2*CORE+(WC-DONE)) <= bb;
            ss <= sc(j-L-2*CORE+(WC-DONE));
          end generate genPre;
        end generate genLast;

        genCore: if CORE > 0 and L <= j and j < L+2*CORE generate
          ss <= si(BASE-L+j);
          ai(BASE-L+j) <= (b1 and a1) or ((b1 xor a1) and a0);
          bi(BASE-L+j) <= (b1 and a1) or ((b1 xor a1) and b0);
        end generate genCore;

        -- Expansion ------
          si(BASE-2*(PAIRS-j)+0) <= (b0 xor a0) xor (ss xor ((b1 xor a1) and (b0 xor a0)));
          si(BASE-2*(PAIRS-j)+1) <= (b1 xor a1) xor ((b0 and a0) or ((b0 xor a0) and (ss xor ((b1 xor a1) and (b0 xor a0)))));
      end generate genPairs;
    end generate genCompact;
    sc <= ac + bc + (0 to 0 => c);
  end generate genCCA;

end rtl;
