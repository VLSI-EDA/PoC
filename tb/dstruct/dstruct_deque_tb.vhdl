-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- ============================================================================
-- Entity:      dstruct_deque_tb
--
-- Authors:     Jens Voss <jens.voss@mailbox.tu-dresden.de>
--
-- Description:
-- ------------
--   Testbench for dstruct_deque.
--
-- License:
-- ============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
--                     Chair for VLSI-Design, Diagnostics and Architecture
--
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

entity dstruct_deque_tb is
end entity;


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library PoC;
use PoC.dstruct.all;

architecture tb of dstruct_deque_tb is

  -- component generics
  constant MIN_DEPTH      : positive := 128;
  constant D_BITS         : positive := 16;

  -- Clock Control
  signal rst  : std_logic;
  signal clk  : std_logic := '1';
  signal done : std_logic := '0';
  constant clk_period : time := 20 ns;
  shared variable i,j,k : integer;

  -- local Signals

  -- PortA
  signal dinA : std_logic_vector(D_BITS-1 downto 0) := (others => '0');
  signal putA : std_logic := '0';
  signal gotA : std_logic := '0';
  signal doutA : std_logic_vector(D_BITS-1 downto 0);
  signal fullA : std_logic;
  signal validA : std_logic;


  -- Port B
  signal dinB : std_logic_vector(D_BITS-1 downto 0) := (others => '0');
  signal putB : std_logic := '0';
  signal gotB : std_logic := '0';
  signal doutB : std_logic_vector(D_BITS-1 downto 0);
  signal validB : std_logic;
  signal fullB : std_logic;

  -- shared signals
  signal valid : std_logic;
  signal full : std_logic;


begin
  -- clk generation
  clk <= not clk after clk_period/2 when done /= '1' else '0';

  -- component initialisation
DUT : dstruct_deque
generic map(
  D_BITS => D_BITS,
  MIN_DEPTH => MIN_DEPTH
)
port map(
  clk => clk,
  rst => rst,
  --PORT A
  dinA => dinA,
  putA => putA,
  gotA => gotA,
  doutA => doutA,
  validA => validA,
  fullA => fullA,
  --PORT B
  dinB => dinB,
  putB => putB,
  gotB => gotB,
  doutB => doutB,
  validB => validB,
  fullB => fullB
);

-- Stimuli
process begin
  rst <= '1';
  wait for clk_period*3;
  rst <= '0';
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '0' report "validA != 0!" severity error;
  assert fullB = '0' report "fullA != 0!" severity error;
  assert validB = '0' report "validA != 0!" severity error;

  -- fill stack with data
  report "test: fill whole deque but 2 spots";
  i := 1;
  j := 0;
  while i < (MIN_DEPTH/2) loop
  --for i in 0 to (MIN_DEPTH-2)/2 loop
    putA <= '1';
    dinA <= std_logic_vector(to_unsigned(j, D_BITS));
    wait for clk_period;
    putA <= '0';
    dinA <= (others => '0');
    wait for clk_period;
    assert fullA = '0' report "fullA != 0!" severity error;
    assert validA = '1' report "validA != 1!" severity error;
    assert fullB = '0' report "fullB != 0!" severity error;
    if (i = 1) then
      assert validB = '0' report "validB != 0!" severity error;
    else
      assert validB = '1' report "validB != 1!" severity error;
    end if;
    putB <= '1';
    dinB <= std_logic_vector(to_unsigned(j+1, D_BITS));
    wait for clk_period;
    putB <= '0';
    dinB <= std_logic_vector(to_unsigned(0, D_BITS));
    wait for clk_period;
    assert fullA = '0' report "fullA != 0!" severity error;
    assert validA = '1' report "validA != 1!" severity error;
    assert fullB = '0' report "fullB != 0!" severity error;
    assert validB = '1' report "validB != 1!" severity error;
    i := i +1;
    j := j +2;
  end loop;
  wait for clk_period;

  -- push A and push B
  report "test: 1. push to A and push to B";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  wait for clk_period;
  assert fullA = '1' report "fullA != 1!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  -- push to full deque
  report "test: push to full deque";
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(3, D_BITS));
  wait for clk_period;
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  wait for clk_period;
  assert fullA = '1' report "fullA != 1!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(4, D_BITS));
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  wait for clk_period;
  assert fullA = '1' report "fullA != 1!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;

  -- pop A
  report "test: 1. pop A";
  wait for clk_period*5;
  gotA <= '1';
  wait for clk_period;
  gotA <= '0';
  assert fullA = '1' report "fullA != 1!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;

  -- pop whole Deque from B
  report "test: pop whole deque";
  i := MIN_DEPTH - 1;
  j := MIN_DEPTH - 1;
  k := 0;
  while i > 1 loop
    gotB <= '1';
    wait for clk_period;
    gotB <= '0';
    wait for clk_period;
    if (i > MIN_DEPTH/2) then
      assert doutB = std_logic_vector(to_unsigned(j-2, D_BITS)) report "doutB !=j-2" severity error;
      j := j - 2;
    elsif (i = MIN_DEPTH/2) then
      assert doutB = std_logic_vector(to_unsigned(j-1, D_BITS)) report "doutB !=j-2" severity error;
    else
      assert doutB = std_logic_vector(to_unsigned(k+2, D_BITS)) report "doutB !=k" severity error;
      k := k + 2;
    end if;
    if i /= 2 then
      assert fullA = '0' report "fullA != 0!" severity error;
      assert validA = '1' report "validA != 1!" severity error;
      assert fullB = '0' report "fullB != 0!" severity error;
      assert validB = '1' report "validB != 1!" severity error;
    else
      assert fullA = '0' report "fullA != 0!" severity error;
      assert validA = '1' report "validA != 1!" severity error;
      assert fullB = '0' report "fullB != 0!" severity error;
      assert validB = '0' report "validB != 0!" severity error;
    end if;
    i := i - 1;
  end loop;
  wait for clk_period;

  -- read last spot
  report "test: read last spot";
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  wait for clk_period;
  gotA <= '1';
  gotB <= '1';
  wait for clk_period;
  gotA <= '0';
  gotB <= '0';
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '0' report "validA != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(7, D_BITS));
  wait for clk_period;
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  wait for clk_period;
  assert doutB = std_logic_vector(to_unsigned(7, D_BITS)) report "doutB !=x07" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  wait for clk_period;
  gotA <= '1';
  gotB <= '1';
  wait for clk_period;
  gotA <= '0';
  gotB <= '0';
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '0' report "validA != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  wait for clk_period;

  -- write last spot
  report "test: write last spot";
  i := 1;
  j := 0;
  while i < (MIN_DEPTH/2) loop
  --for i in 0 to (MIN_DEPTH-2)/2 loop
    putA <= '1';
    dinA <= std_logic_vector(to_unsigned(j, D_BITS));
    wait for clk_period;
    putA <= '0';
    dinA <= std_logic_vector(to_unsigned(0, D_BITS));
    wait for clk_period;
    assert fullA = '0' report "fullA != 0!" severity error;
    assert validA = '1' report "validA != 1!" severity error;
    assert fullB = '0' report "fullB != 0!" severity error;
    if (i = 1) then
      assert validB = '0' report "validB != 0!" severity error;
    else
      assert validB = '1' report "validB != 1!" severity error;
    end if;
    putB <= '1';
    dinB <= std_logic_vector(to_unsigned(j+1, D_BITS));
    wait for clk_period;
    putB <= '0';
    dinB <= std_logic_vector(to_unsigned(0, D_BITS));
    wait for clk_period;
    assert fullA = '0' report "fullA != 0!" severity error;
    assert validA = '1' report "validA != 1!" severity error;
    assert validB = '1' report "validB != 1!" severity error;
    assert fullB = '0' report "fullB != 0!" severity error;
    i := i +1;
    j := j +2;
  end loop;
  wait for clk_period;
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(3, D_BITS));
  wait for clk_period;
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  putB <= '1';
  putA <= '1';
  dinB <= std_logic_vector(to_unsigned(10, D_BITS));
  dinA <= std_logic_vector(to_unsigned(12, D_BITS));
  wait for clk_period;
  putB <= '0';
  putA <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  wait for clk_period;
  assert fullA = '1' report "fullA != 1!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  wait for clk_period;
  gotB <= '1';
  wait for clk_period;
  gotB <= '0';
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  putB <= '1';
  putA <= '1';
  dinB <= std_logic_vector(to_unsigned(10, D_BITS));
  dinA <= std_logic_vector(to_unsigned(12, D_BITS));
  wait for clk_period;
  putB <= '0';
  putA <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  wait for clk_period;
  assert fullA = '1' report "fullA != 1!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  wait for clk_period;
  gotA <= '1';
  wait for clk_period;
  gotA <= '0';
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  assert doutA = std_logic_vector(to_unsigned(12, D_BITS)) report "doutA !=x0C" severity error;
  wait for clk_period;
  gotA <= '1';
  wait for clk_period;
  gotA <= '0';
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)) report "doutA != MIN_DEPTH-4" severity error;
  wait for clk_period*2;

  -- reset deque
  report "reset deque";
  rst <= '1';
  wait for clk_period*3;
  rst <= '0';
  wait for clk_period;

  -- Testcases for gotA/B and writeA/B parallel
  -- 1) starting with an empty deque
  -- 2) deque holds one valid element before operaton is executed
  -- 3) more than one valid element
  -- 4) one spot left
  -- 5) deque is full

  -- Operation: writeA and gotA
  report "test: 1. writeA and gotA";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
  gotA <= '1';
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '0' report "validA != 0!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;

  report "test: 2. writeA and gotA";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(152, D_BITS)); --x"98";
  gotA <= '1';
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutA = std_logic_vector(to_unsigned(152, D_BITS)) report "doutA != 0x98" severity error;

  report "test: 2. writeA and gotA, pop last element";
  wait for clk_period;
  gotA <= '1';
  wait for clk_period;
  gotA <= '0';
  assert doutA = std_logic_vector(to_unsigned(152, D_BITS)) report "doutA != 0x98" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '0' report "validA != 0!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;

  report "test: 3. writeA and gotA";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutB != MIN_DEPTH-1" severity error;
  wait for clk_period;
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(86, D_BITS)); --0x56
  gotA <= '1';
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutA = std_logic_vector(to_unsigned(86, D_BITS)) report "doutA != 0x56" severity error;

  -- reset deque and refill deque
  report "reset deque and refill deque";
  rst <= '1';
  wait for clk_period*3;
  rst <= '0';
  wait for clk_period;
  -- refill deque
  i := 1;
  j := 0;
  while i < (MIN_DEPTH/2) loop
    putA <= '1';
    dinA <= std_logic_vector(to_unsigned(j, D_BITS));
    putB <= '1';
    dinB <= std_logic_vector(to_unsigned(j+1, D_BITS));
    wait for clk_period;
    putB <= '0';
    dinB <= std_logic_vector(to_unsigned(0, D_BITS));
    putA <= '0';
    dinA <= std_logic_vector(to_unsigned(0, D_BITS));
    wait for clk_period;
    i := i +1;
    j := j +2;
  end loop;
  wait for clk_period;

  -- 2 spots free
  -- stackpointerA at adr 0
  -- stackpointerB at adr MIN_DEPTH-1
  -- push one element to A to have only one spot left
  dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
  putA <= '1';
  wait for clk_period;
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  putA <= '0';
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)) report "doutA != MIN_DEPTH-4" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;

  report "test: 4. writeA and gotA";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(222, D_BITS));--x"DE";
  gotA <= '1';
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  assert doutA = std_logic_vector(to_unsigned(222, D_BITS)) report "doutA != 0xDE" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;

  -- push one element to A to fill whole deque
  dinA <= std_logic_vector(to_unsigned(175, D_BITS));--x"AF";
  putA <= '1';
  wait for clk_period;
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  putA <= '0';
  assert doutA = std_logic_vector(to_unsigned(222, D_BITS)) report "doutA != 0xDE" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  wait for clk_period;
  assert doutA = std_logic_vector(to_unsigned(175, D_BITS)) report "doutA != 0xAF" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert fullA = '1' report "fullA != 1!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;

  wait for clk_period;

  report "test: 5. writeA and gotA";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(203, D_BITS));--x"CB";
  gotA <= '1';
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  assert doutA = std_logic_vector(to_unsigned(175, D_BITS)) report "doutA != 0xAF" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert fullA = '1' report "fullA != 1!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  assert doutA = std_logic_vector(to_unsigned(222, D_BITS)) report "doutA != 0xDE" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;

  -- reset deque
  report "reset deque";
  rst <= '1';
  wait for clk_period*3;
  rst <= '0';
  wait for clk_period;

  -- Operation: writeB and gotB;
  report "test: 1. writeB and gotB";
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
  gotB <= '1';
  wait for clk_period;
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  gotB <= '0';
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '0' report "validA != 0!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutB != MIN_DEPTH-2" severity error;

  report "test: 2. writeB and gotB";
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(152, D_BITS));--x"98";
  gotB <= '1';
  wait for clk_period;
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  gotB <= '0';
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutB != MIN_DEPTH-2" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutB = std_logic_vector(to_unsigned(152, D_BITS)) report "doutB != 0x98" severity error;

  report "test: 2. writeB and gotB, pop last element";
  wait for clk_period;
  gotB <= '1';
  wait for clk_period;
  gotB <= '0';
  assert doutB = std_logic_vector(to_unsigned(152, D_BITS)) report "doutB != 0x98" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  gotA <= '1';
  wait for clk_period;
  gotA <= '0';
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '0' report "validA != 0!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;


  report "test: 3. writeB and gotB";
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
  wait for clk_period;
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutB != MIN_DEPTH-2" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutA != MIN_DEPTH-1" severity error;
  wait for clk_period;
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(86, D_BITS));--x"56";
  gotB <= '1';
  wait for clk_period;
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  gotB <= '0';
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutB != MIN_DEPTH-2" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutB = std_logic_vector(to_unsigned(86, D_BITS)) report "doutB != 0x56" severity error;

  -- reset deque and refill deque
  report "reset deque and refill deque";
  rst <= '1';
  wait for clk_period*3;
  rst <= '0';
  wait for clk_period;
  -- refill deque
  i := 1;
  j := 0;
  while i < (MIN_DEPTH/2) loop
    putA <= '1';
    dinA <= std_logic_vector(to_unsigned(j, D_BITS));
    putB <= '1';
    dinB <= std_logic_vector(to_unsigned(j+1, D_BITS));
    wait for clk_period;
    putB <= '0';
    dinB <= std_logic_vector(to_unsigned(0, D_BITS));
    putA <= '0';
    dinA <= (others => '0');
    wait for clk_period;
    i := i +1;
    j := j +2;
  end loop;
  wait for clk_period;

  -- 2 spots free
  -- stackpointerA at adr 0
  -- stackpointerB at adr MIN_DEPTH-1
  -- push one element to B to have only one spot left
  dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
  putB <= '1';
  wait for clk_period;
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  putB <= '0';
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)) report "doutA != MIN_DEPTH-4" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)) report "doutA != MIN_DEPTH-4" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutB != MIN_DEPTH-1" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;

  report "test: 4. writeB and gotB";
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(222, D_BITS));--x"DE";
  gotB <= '1';
  wait for clk_period;
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  gotB <= '0';
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)) report "doutA != MIN_DEPTH-4" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutB != MIN_DEPTH-1" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)) report "doutA != MIN_DEPTH-4" severity error;

  -- push one element to A to fill whole deque
  dinB <= std_logic_vector(to_unsigned(175, D_BITS));--x"AF";
  putB <= '1';
  wait for clk_period;
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  putB <= '0';
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)) report "doutA != MIN_DEPTH-4" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert doutB = std_logic_vector(to_unsigned(175, D_BITS)) report "doutB != 0xAF" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)) report "doutA != MIN_DEPTH-4" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  wait for clk_period;
  dinA <= std_logic_vector(to_unsigned(191, D_BITS));--x"BF";
  putA <= '1';
  wait for clk_period;
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  putA <= '0';
  wait for clk_period;
  assert fullA = '1' report "fullA != 1!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;

  report "test: 5. writeB and gotB";
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(203, D_BITS));--x"CB";
  gotB <= '1';
  wait for clk_period;
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  gotB <= '0';
  assert doutB = std_logic_vector(to_unsigned(175, D_BITS)) report "doutB != 0xAF" severity error;
  assert doutA = std_logic_vector(to_unsigned(191, D_BITS)) report "doutA != 0xBF" severity error;
  assert fullA = '1' report "fullA != 1!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert doutA = std_logic_vector(to_unsigned(191, D_BITS)) report "doutA != 0xBF" severity error;


  -- reset deque
  report "reset deque";
  rst <= '1';
  wait for clk_period*3;
  rst <= '0';
  wait for clk_period;

  -- Operation: writeB and gotA
  report "test: 1. writeB and gotA";
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
  gotA <= '1';
  wait for clk_period;
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '0' report "validA != 0!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutB != MIN_DEPTH-2" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;

  report "test: 2. writeB and gotA";
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(152, D_BITS));--x"98";
  gotA <= '1';
  wait for clk_period;
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutB != MIN_DEPTH-2" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutB = std_logic_vector(to_unsigned(152, D_BITS)) report "doutB != 0x98" severity error;
  assert doutA = std_logic_vector(to_unsigned(152, D_BITS)) report "doutA != 0x98" severity error;

  report "test: 2. writeB and gotA, pop last element";
  wait for clk_period;
  gotA <= '1';
  wait for clk_period;
  gotA <= '0';
  assert doutB = std_logic_vector(to_unsigned(152, D_BITS)) report "doutB != 0x98" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '0' report "validA != 0!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;

  report "test: 3. writeB and gotA";
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
  wait for clk_period;
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutB != MIN_DEPTH-2" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutA != MIN_DEPTH-1" severity error;
  wait for clk_period;
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(86, D_BITS));--x"56";
  gotA <= '1';
  wait for clk_period;
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutB != MIN_DEPTH-2" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutA != MIN_DEPTH-1" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutB = std_logic_vector(to_unsigned(86, D_BITS)) report "doutB != 0x56" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;

  -- reset deque and refill deque
  report "reset deque and refill deque";
  rst <= '1';
  wait for clk_period*3;
  rst <= '0';
  wait for clk_period;
  -- refill deque
  i := 1;
  j := 0;
  while i < (MIN_DEPTH/2) loop
    putA <= '1';
    dinA <= std_logic_vector(to_unsigned(j, D_BITS));
    putB <= '1';
    dinB <= std_logic_vector(to_unsigned(j+1, D_BITS));
    wait for clk_period;
    putB <= '0';
    dinB <= std_logic_vector(to_unsigned(0, D_BITS));
    putA <= '0';
    dinA <= (others => '0');
    wait for clk_period;
    i := i +1;
    j := j +2;
  end loop;
  wait for clk_period;

  -- 2 spots free
  -- stackpointerA at adr 0
  -- stackpointerB at adr MIN_DEPTH-1
  -- push one element to B to have only one spot left
  dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
  putB <= '1';
  wait for clk_period;
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  putB <= '0';
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)) report "doutA != MIN_DEPTH-4" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)) report "doutA != MIN_DEPTH-4" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutB != MIN_DEPTH-1" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;

  report "test: 4. writeB and gotA";
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(222, D_BITS));--x"DE";
  gotA <= '1';
  wait for clk_period;
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)) report "doutA != MIN_DEPTH-4" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutB != MIN_DEPTH-1" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutB != MIN_DEPTH-1" severity error;
  if (MIN_DEPTH > 4) then
    assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-6, D_BITS)) report "doutA != MIN_DEPTH-6" severity error;
  else
    assert doutA = std_logic_vector(to_unsigned(1, D_BITS)) report "doutA != 0x01" severity error;
  end if;

  -- push one element to A to fill whole deque
  dinB <= std_logic_vector(to_unsigned(175, D_BITS));--x"AF";
  putB <= '1';
  wait for clk_period;
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  putB <= '0';
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutB != MIN_DEPTH-1" severity error;
  if (MIN_DEPTH > 4) then
    assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-6, D_BITS)) report "doutA != MIN_DEPTH-6" severity error;
  else
    assert doutA = std_logic_vector(to_unsigned(1, D_BITS)) report "doutA != 0x01" severity error;
  end if;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  dinA <= std_logic_vector(to_unsigned(205, D_BITS));--x"CD";
  putA <= '1';
  wait for clk_period;
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  putA <= '0';
  wait for clk_period;
  assert fullA = '1' report "fullA != 1!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  assert doutB = std_logic_vector(to_unsigned(175, D_BITS)) report "doutB != 0xAF" severity error;
  assert doutA = std_logic_vector(to_unsigned(205, D_BITS)) report "doutA != 0xCD" severity error;
  wait for clk_period;

  report "test: 5. writeB and gotA";
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(203, D_BITS));--x"CB";
  gotA <= '1';
  wait for clk_period;
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  assert fullA = '1' report "fullA != 1!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  assert doutA = std_logic_vector(to_unsigned(205, D_BITS)) report "doutA != 0xCD" severity error;
  assert doutB = std_logic_vector(to_unsigned(175, D_BITS)) report "doutB != 0xAF" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  assert doutB = std_logic_vector(to_unsigned(175, D_BITS)) report "doutB != 0xAF" severity error;
  if (MIN_DEPTH > 4) then
    assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-6, D_BITS)) report "doutA != MIN_DEPTH-6" severity error;
  else
    assert doutA = std_logic_vector(to_unsigned(1, D_BITS)); report "doutA != 0x01" severity error;
  end if;

  -- reset deque
  report "reset deque";
  rst <= '1';
  wait for clk_period*3;
  rst <= '0';
  wait for clk_period;

  -- operation: writeA and gotB
  report "test: 1. writeA and gotB";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
  gotB <= '1';
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  gotB <= '0';
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '0' report "validA != 0!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutB != MIN_DEPTH-2" severity error;

  report "test: 2. writeA and gotB";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(152, D_BITS));--x"98";
  gotB <= '1';
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  gotB <= '0';
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutB != MIN_DEPTH-2" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutA = std_logic_vector(to_unsigned(152, D_BITS)) report "doutA != 0x98" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutB != MIN_DEPTH-2" severity error;

  report "test: 2. writeA and gotB, pop last element";
  wait for clk_period;
  gotA <= '1';
  wait for clk_period;
  gotA <= '0';
  assert doutA = std_logic_vector(to_unsigned(152, D_BITS)) report "doutB != 0x98" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  gotA <= '1';
  wait for clk_period;
  gotA <= '0';
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '0' report "validA != 0!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;

  report "test: 3. writeA and gotB";
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
  wait for clk_period;
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutB != MIN_DEPTH-2" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutA != MIN_DEPTH-1" severity error;
  wait for clk_period;
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(86, D_BITS)); --x"56"
  gotB <= '1';
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  gotB <= '0';
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutB != MIN_DEPTH-2" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutA != MIN_DEPTH-1" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutA = std_logic_vector(to_unsigned(86, D_BITS)) report "doutB != 0x56" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutB != MIN_DEPTH-1" severity error;

  -- reset deque and refill deque
  report "reset deque and refill deque";
  rst <= '1';
  wait for clk_period*3;
  rst <= '0';
  wait for clk_period;
  -- refill deque
  i := 1;
  j := 0;
  while i < (MIN_DEPTH/2) loop
    putA <= '1';
    dinA <= std_logic_vector(to_unsigned(j, D_BITS));
    putB <= '1';
    dinB <= std_logic_vector(to_unsigned(j+1, D_BITS));
    wait for clk_period;
    putB <= '0';
    dinB <= std_logic_vector(to_unsigned(0, D_BITS));
    putA <= '0';
    dinA <= (others => '0');
    wait for clk_period;
    i := i +1;
    j := j +2;
  end loop;
  wait for clk_period;

  -- 2 spots free
  -- stackpointerA at adr 0
  -- stackpointerB at adr MIN_DEPTH-1
  -- push one element to A to have only one spot left
  dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
  putA <= '1';
  wait for clk_period;
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  putA <= '0';
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)) report "doutA != MIN_DEPTH-4" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-1" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;

  report "test: 4. writeA and gotB";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(222, D_BITS));--x"DE";
  gotB <= '1';
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  gotB <= '0';
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  assert doutA = std_logic_vector(to_unsigned(222, D_BITS)) report "doutA != 0xDE" severity error;
  if (MIN_DEPTH > 4) then
    assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-5, D_BITS)) report "doutB != MIN_DEPTH-5" severity error;
  else
    assert doutB = std_logic_vector(to_unsigned(0, D_BITS)) report "doutB != 0x00" severity error;
  end if;

  -- push one element to A to fill whole deque
  dinA <= std_logic_vector(to_unsigned(175, D_BITS));--x"AF";
  putA <= '1';
  wait for clk_period;
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  putA <= '0';
  assert doutA = std_logic_vector(to_unsigned(222, D_BITS)) report "doutA != 0xDE" severity error;
  if (MIN_DEPTH > 4) then
    assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-5, D_BITS)) report "doutB != MIN_DEPTH-5" severity error;
  else
    assert doutB = std_logic_vector(to_unsigned(0, D_BITS)) report "doutB != 0x00" severity error;
  end if;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  wait for clk_period;
  assert doutA = std_logic_vector(to_unsigned(175, D_BITS)) report "doutA != 0xAF" severity error;
  if (MIN_DEPTH > 4) then
    assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-5, D_BITS)) report "doutB != MIN_DEPTH-5" severity error;
  else
    assert doutB = std_logic_vector(to_unsigned(0, D_BITS)) report "doutB != 0x00" severity error;
  end if;
  assert fullA = '1' report "fullA != 1!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  wait for clk_period;

  report "test: 5. writeA and gotB";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(203, D_BITS));--x"CB";
  gotB <= '1';
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  gotB <= '0';
  assert doutA = std_logic_vector(to_unsigned(175, D_BITS)) report "doutB != 0xAF" severity error;
  if (MIN_DEPTH > 4) then
    assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-5, D_BITS)) report "doutB != MIN_DEPTH-5" severity error;
  else
    assert doutB = std_logic_vector(to_unsigned(0, D_BITS)) report "doutB != 0x00" severity error;
  end if;
  assert fullA = '1' report "fullA != 1!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  assert doutA = std_logic_vector(to_unsigned(175, D_BITS)) report "doutA != 0xAF" severity error;
  if (MIN_DEPTH > 4) then
    assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-7, D_BITS)) report "doutB != MIN_DEPTH-7" severity error;
  else
    assert doutB = std_logic_vector(to_unsigned(2, D_BITS)) report "doutB != 0x02" severity error;
  end if;

  -- reset deque
  report "reset deque";
  rst <= '1';
  wait for clk_period*3;
  rst <= '0';
  wait for clk_period;

  -- Operation: writeB and gotB and gotA
  report "test: 1. writeB and gotB and gotA";
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
  gotA <= '1';
  gotB <= '1';
  wait for clk_period;
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  gotB <= '0';
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '0' report "validA != 0!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutB != MIN_DEPTH-2" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;

  report "test: 2. writeB and gotB and gotA";
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(152, D_BITS));--x"98";
  gotA <= '1';
  gotB <= '1';
  wait for clk_period;
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  gotB <= '0';
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutB != MIN_DEPTH-2" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutB = std_logic_vector(to_unsigned(152, D_BITS)) report "doutB != 0x98" severity error;
  assert doutA = std_logic_vector(to_unsigned(152, D_BITS)) report "doutA != 0x98" severity error;


  report "test: 2. writeB and gotB and gotA, pop last element";
  wait for clk_period;
  gotA <= '1';
  wait for clk_period;
  gotA <= '0';
  assert doutB = std_logic_vector(to_unsigned(152, D_BITS)) report "doutB != 0x98" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '0' report "validA != 0!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;

  report "test: 3. writeB and gotB and gotA";
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
  wait for clk_period;
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutB != MIN_DEPTH-2" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutA != MIN_DEPTH-1" severity error;
  wait for clk_period;
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(86, D_BITS));--x"56";
  gotA <= '1';
  gotB <= '1';
  wait for clk_period;
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  gotB <= '0';
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutB != MIN_DEPTH-2" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutA != MIN_DEPTH-1" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutB = std_logic_vector(to_unsigned(86, D_BITS)) report "doutB != 0x56" severity error;
  assert doutA = std_logic_vector(to_unsigned(86, D_BITS)) report "doutA != 0x56" severity error;

  -- reset deque and refill deque
  report "reset deque and refill deque";
  rst <= '1';
  wait for clk_period*3;
  rst <= '0';
  wait for clk_period;
  -- refill deque
  i := 1;
  j := 0;
  while i < (MIN_DEPTH/2) loop
    putA <= '1';
    dinA <= std_logic_vector(to_unsigned(j, D_BITS));
    putB <= '1';
    dinB <= std_logic_vector(to_unsigned(j+1, D_BITS));
    wait for clk_period;
    putB <= '0';
    dinB <= std_logic_vector(to_unsigned(0, D_BITS));
    putA <= '0';
    dinA <= (others => '0');
    wait for clk_period;
    i := i +1;
    j := j +2;
  end loop;
  wait for clk_period;

  -- 2 spots free
  -- stackpointerA at adr 0
  -- stackpointerB at adr MIN_DEPTH-1
  -- push one element to B to have only one spot left
  dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
  putB <= '1';
  wait for clk_period;
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  putB <= '0';
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)) report "doutA != MIN_DEPTH-4" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)) report "doutA != MIN_DEPTH-4" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutB != MIN_DEPTH-1" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;

  report "test: 4. writeB and gotB and gotA";
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(222, D_BITS));--x"DE";
  gotA <= '1';
  gotB <= '1';
  wait for clk_period;
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  gotB <= '0';
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)) report "doutA != MIN_DEPTH-4" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutB != MIN_DEPTH-1" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  if (MIN_DEPTH > 4) then
    assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-6, D_BITS)) report "doutA != MIN_DEPTH-6" severity error;
    assert validB = '1' report "validB != 1!" severity error;
  else
    assert doutA = std_logic_vector(to_unsigned(1, D_BITS)) report "doutA != 0x01" severity error;
    assert validB = '0' report "validB != 0!" severity error;
  end if;

  -- push one element to A and B to fill whole deque
  dinB <= std_logic_vector(to_unsigned(175, D_BITS));--x"AF";
  dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS));
  putB <= '1';
  putA <= '1';
  wait for clk_period;
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  putB <= '0';
  putA <= '0';
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  if (MIN_DEPTH > 4) then
    assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-6, D_BITS)) report "doutA != MIN_DEPTH-6" severity error;
    assert validB = '1' report "validB != 1!" severity error;
  else
    assert doutA = std_logic_vector(to_unsigned(1, D_BITS)) report "doutA != 0x01" severity error;
    assert validB = '0' report "validB != 0!" severity error;
  end if;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert doutB = std_logic_vector(to_unsigned(175, D_BITS)) report "doutB != 0xAF" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)) report "doutA != MIN_DEPTH-4" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  wait for clk_period;
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(171, D_BITS));--x"AB";
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  wait for clk_period;
  assert doutB = std_logic_vector(to_unsigned(175, D_BITS)) report "doutB != 0xAF" severity error;
  assert doutA = std_logic_vector(to_unsigned(171, D_BITS)) report "doutA != 0xAB" severity error;
  assert fullA = '1' report "fullA != 1!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;


  report "test: 5. writeB and gotB and gotA";
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(203, D_BITS));--x"CB";
  gotA <= '1';
  gotB <= '1';
  wait for clk_period;
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  gotB <= '0';
  assert doutB = std_logic_vector(to_unsigned(175, D_BITS)) report "doutB != 0xAF" severity error;
  assert doutA = std_logic_vector(to_unsigned(171, D_BITS)) report "doutA != 0xAB" severity error;
  assert fullA = '1' report "fullA != 1!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)) report "doutA != MIN_DEPTH-4" severity error;

  -- reset deque
  report "reset deque";
  rst <= '1';
  wait for clk_period*3;
  rst <= '0';
  wait for clk_period;

  -- Operation: writeA and gotA and gotB
  report "test: 1. writeA and gotB and gotA";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
  gotA <= '1';
  gotB <= '1';
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  gotB <= '0';
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '0' report "validA != 0!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  wait for clk_period;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutB != MIN_DEPTH-2" severity error;

  report "test: 2. writeA and gotB and gotA";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(152, D_BITS));--x"98";
  gotA <= '1';
  gotB <= '1';
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  gotB <= '0';
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutB != MIN_DEPTH-2" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutA = std_logic_vector(to_unsigned(152, D_BITS)) report "doutA != 0x98" severity error;
  assert doutB = std_logic_vector(to_unsigned(152, D_BITS)) report "doutB != 0x98" severity error;

  report "test: 2. writeA and gotB and gotA, pop last element";
  wait for clk_period;
  gotA <= '1';
  wait for clk_period;
  gotA <= '0';
  assert doutA = std_logic_vector(to_unsigned(152, D_BITS)) report "doutA != 0x98" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '0' report "validA != 0!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;

  report "test: 3. writeA and gotB and gotA";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  putB <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutB != MIN_DEPTH-1" severity error;
  wait for clk_period;
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(86, D_BITS));--x"56";
  gotA <= '1';
  gotB <= '1';
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  gotB <= '0';
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutB != MIN_DEPTH-1" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutA = std_logic_vector(to_unsigned(86, D_BITS)) report "doutA != 0x56" severity error;
  assert doutB = std_logic_vector(to_unsigned(86, D_BITS)) report "doutB != 0x56" severity error;

  -- reset deque and refill deque
  report "reset deque and refill deque";
  rst <= '1';
  wait for clk_period*3;
  rst <= '0';
  wait for clk_period;
  -- refill deque
  i := 1;
  j := 0;
  while i < (MIN_DEPTH/2) loop
    putA <= '1';
    dinA <= std_logic_vector(to_unsigned(j, D_BITS));
    putB <= '1';
    dinB <= std_logic_vector(to_unsigned(j+1, D_BITS));
    wait for clk_period;
    putB <= '0';
    dinB <= std_logic_vector(to_unsigned(0, D_BITS));
    putA <= '0';
    dinA <= (others => '0');
    wait for clk_period;
    i := i +1;
    j := j +2;
  end loop;
  wait for clk_period;

  -- 2 spots free
  -- stackpointerA at adr 0
  -- stackpointerB at adr MIN_DEPTH-1
  -- push one element to B to have only one spot left
  dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
  putA <= '1';
  wait for clk_period;
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  putA <= '0';
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)) report "doutA != MIN_DEPTH-4" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;

  report "test: 4. writeA and gotB and gotA";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(222, D_BITS));--x"DE";
  gotA <= '1';
  gotB <= '1';
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  gotB <= '0';
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutA = std_logic_vector(to_unsigned(222, D_BITS)) report "doutB != 0xDE" severity error;
  if (MIN_DEPTH > 4) then
    assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-5, D_BITS)) report "doutA != MIN_DEPTH-5" severity error;
  else
    assert doutB = std_logic_vector(to_unsigned(0, D_BITS)) report "doutB != 0x00" severity error;
  end if;

  -- push one element to A and B to fill whole deque
  dinA <= std_logic_vector(to_unsigned(175, D_BITS));--x"AF";
  dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS));
  putB <= '1';
  putA <= '1';
  wait for clk_period;
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  putB <= '0';
  putA <= '0';
  assert doutA = std_logic_vector(to_unsigned(222, D_BITS)) report "doutA != 0xDE" severity error;
  if (MIN_DEPTH > 4) then
    assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-5, D_BITS)) report "doutB != MIN_DEPTH-5" severity error;
  else
    assert doutB = std_logic_vector(to_unsigned(0, D_BITS)) report "doutB != 0x00" severity error;
  end if;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert doutA = std_logic_vector(to_unsigned(175, D_BITS)) report "doutA != 0xAF" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert fullA = '1' report "fullA != 1!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  wait for clk_period;

  report "test: 5. writeA and gotB and gotA";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(203, D_BITS));--x"CB";
  gotA <= '1';
  gotB <= '1';
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  gotB <= '0';
  assert doutA = std_logic_vector(to_unsigned(175, D_BITS)) report "doutB != 0xAF" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutA != MIN_DEPTH-3" severity error;
  assert fullA = '1' report "fullA != 1!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutA = std_logic_vector(to_unsigned(222, D_BITS)) report "doutB != 0xDE" severity error;
  if (MIN_DEPTH > 4) then
    assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-5, D_BITS)) report "doutB != MIN_DEPTH-5" severity error;
  else
    assert doutB = std_logic_vector(to_unsigned(222, D_BITS)) report "doutB != 0x00" severity error;
  end if;

  -- reset deque
  report "reset deque";
  rst <= '1';
  wait for clk_period*3;
  rst <= '0';
  wait for clk_period;

  -- Operation writeA and gotA and writeB
  report "test: 1. writeA and gota and writeB";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
  gotA <= '1';
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '0' report "validA != 0!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutB != MIN_DEPTH-1" severity error;

  report "test: 2. writeA and gota and writeB";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(152, D_BITS));--x"98"
  dinB <= std_logic_vector(to_unsigned(144, D_BITS));--x"90";
  gotA <= '1';
  putB <= '1';
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutB != MIN_DEPTH-1" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  if (MIN_DEPTH > 4) then
    assert fullB = '0' report "fullB != 0!" severity error;
  else
    assert fullB = '1' report "fullB != 1!" severity error;
  end if;
  assert doutA = std_logic_vector(to_unsigned(152, D_BITS)) report "doutA != 0x98" severity error;
  assert doutB = std_logic_vector(to_unsigned(144, D_BITS)) report "doutB != 0x90" severity error;


  report "test: 2.writeA and gota and writeB, pop last element";
  wait for clk_period;
  gotB <= '1';
  wait for clk_period;
  gotB <= '0';
  assert doutB = std_logic_vector(to_unsigned(144, D_BITS)) report "doutB != 0x90" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  if (MIN_DEPTH > 4) then
    assert fullB = '0' report "fullB != 0!" severity error;
  else
    assert fullB = '1' report "fullB != 1!" severity error;
  end if;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutB != MIN_DEPTH-1" severity error;


  report "test: 3. writeA and gota and writeB";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(86, D_BITS));--x"56";
  gotA <= '1';
  putB <= '1';
  dinB <=std_logic_vector(to_unsigned(38, D_BITS));-- x"26";
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  assert doutA = std_logic_vector(to_unsigned(152, D_BITS)) report "doutA != 0x98" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutB != MIN_DEPTH-1" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  if (MIN_DEPTH > 4) then
    assert fullB = '0' report "fullB != 0!" severity error;
  else
    assert fullB = '1' report "fullB != 1!" severity error;
  end if;
  assert doutA = std_logic_vector(to_unsigned(86, D_BITS)) report "doutA != 0x56" severity error;
  assert doutB = std_logic_vector(to_unsigned(38, D_BITS)) report "doutB != 0x26" severity error;

  -- reset deque and refill deque
  report "reset deque and refill deque";
  rst <= '1';
  wait for clk_period*3;
  rst <= '0';
  wait for clk_period;
  -- refill deque
  i := 1;
  j := 0;
  while i < (MIN_DEPTH/2) loop
    putA <= '1';
    dinA <= std_logic_vector(to_unsigned(j, D_BITS));
    putB <= '1';
    dinB <= std_logic_vector(to_unsigned(j+1, D_BITS));
    wait for clk_period;
    putB <= '0';
    dinB <= std_logic_vector(to_unsigned(0, D_BITS));
    putA <= '0';
    dinA <= (others => '0');
    wait for clk_period;
    i := i +1;
    j := j +2;
  end loop;
  wait for clk_period;

  -- 2 spots free
  -- stackpointerA at adr 0
  -- stackpointerB at adr MIN_DEPTH-1
  -- push one element to B to have only one spot left
  dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
  putA <= '1';
  wait for clk_period;
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  putA <= '0';
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)) report "doutA != MIN_DEPTH-4" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;

  report "test: 4. writeA and gota and writeB";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(222, D_BITS));--x"DE";
  gotA <= '1';
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(66, D_BITS));--x"42";
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  putB <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  wait for clk_period;
  assert doutA = std_logic_vector(to_unsigned(222, D_BITS)) report "doutA != 0xDE" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  wait for clk_period;
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(250, D_BITS));--x"FA";
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  wait for clk_period;
  assert fullA = '1' report "fullA != 1!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  assert doutA = std_logic_vector(to_unsigned(250, D_BITS)) report "doutA != 0xFA" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;

  report "test: 5. writeA and gota and writeB";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(203, D_BITS));--x"CB";
  gotA <= '1';
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(174, D_BITS));--x"AE";
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  assert fullA = '1' report "fullA != 1!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  assert doutA = std_logic_vector(to_unsigned(250, D_BITS)) report "doutA != 0xFA" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  assert doutA = std_logic_vector(to_unsigned(222, D_BITS)) report "doutA != 0xDE" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;


  -- reset deque
  report "reset deque";
  rst <= '1';
  wait for clk_period*3;
  rst <= '0';
  wait for clk_period;

  -- Operation: writeB and gotB and writeA

  report "test: 1. writeB and gotB and writeA";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
  gotB <= '1';
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  gotB <= '0';
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '0' report "validA != 0!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutB != MIN_DEPTH-1" severity error;

  report "test: 2. writeB and gotB and writeA";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(152, D_BITS));--x"98";
  dinB <= std_logic_vector(to_unsigned(144, D_BITS));--x"90";
  gotB <= '1';
  putB <= '1';
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  gotB <= '0';
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutB != MIN_DEPTH-1" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  if (MIN_DEPTH > 4) then
    assert fullB = '0' report "fullB != 0!" severity error;
  else
    assert fullB = '1' report "fullB != 1!" severity error;
  end if;
  assert doutA = std_logic_vector(to_unsigned(152, D_BITS)) report "doutA != 0x98" severity error;
  assert doutB = std_logic_vector(to_unsigned(144, D_BITS)) report "doutB != 0x90" severity error;


  report "test: 2. writeB and gotB and writeA, pop last element";
  wait for clk_period;
  gotA <= '1';
  wait for clk_period;
  gotA <= '0';
  assert doutA = std_logic_vector(to_unsigned(152, D_BITS)) report "doutA != 0x98" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;

  report "test: 3. writeB and gotB and writeA";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(86, D_BITS));
  gotB <= '1';
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(38, D_BITS));
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  gotB <= '0';
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  assert doutB = std_logic_vector(to_unsigned(144, D_BITS)) report "doutA != 0x90" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  if (MIN_DEPTH > 4) then
    assert fullB = '0' report "fullB != 0!" severity error;
  else
    assert fullB = '1' report "fullB != 1!" severity error;
  end if;
  assert doutA = std_logic_vector(to_unsigned(86, D_BITS)) report "doutA != 0x56" severity error;
  assert doutB = std_logic_vector(to_unsigned(38, D_BITS)) report "doutB != 0x26" severity error;

  -- reset deque and refill deque
  report "reset deque and refill deque";
  rst <= '1';
  wait for clk_period*3;
  rst <= '0';
  wait for clk_period;
  -- refill deque
  i := 1;
  j := 0;
  while i < (MIN_DEPTH/2) loop
    putA <= '1';
    dinA <= std_logic_vector(to_unsigned(j, D_BITS));
    putB <= '1';
    dinB <= std_logic_vector(to_unsigned(j+1, D_BITS));
    wait for clk_period;
    putB <= '0';
    dinB <= std_logic_vector(to_unsigned(0, D_BITS));
    putA <= '0';
    dinA <= (others => '0');
    wait for clk_period;
    i := i +1;
    j := j +2;
  end loop;
  wait for clk_period;

  -- 2 spots free
  -- stackpointerA at adr 0
  -- stackpointerB at adr MIN_DEPTH-1
  -- push one element to B to have only one spot left
  dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
  putB <= '1';
  wait for clk_period;
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  putB <= '0';
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)) report "doutA != MIN_DEPTH-4" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutB != MIN_DEPTH-1" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;

  report "test: 4. writeB and gotB and writeA";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(222, D_BITS));--x"DE";
  gotB <= '1';
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(66, D_BITS));--x"42";
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  gotB <= '0';
  putB <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)) report "doutA != MIN_DEPTH-4" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutB != MIN_DEPTH-1" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  wait for clk_period;
  assert doutA = std_logic_vector(to_unsigned(222, D_BITS)) report "doutA != 0xDE" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-1" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;

  report "test: 5. writeB and gotB and writeA";
  dinA <= std_logic_vector(to_unsigned(255, D_BITS));--x"FF";
  putA <= '1';
  wait for clk_period;
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  putA <= '0';
  wait for clk_period;
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(203, D_BITS));--x"CB";
  gotB <= '1';
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(174, D_BITS));--x"AE";
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  gotB <= '0';
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  assert doutA = std_logic_vector(to_unsigned(255, D_BITS)) report "doutA != 0xFF" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert fullA = '1' report "fullA != 1!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  if (MIN_DEPTH > 4) then
    assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-5, D_BITS)) report "doutB != MIN_DEPTH-5" severity error;
  else
    assert doutB = std_logic_vector(to_unsigned(0, D_BITS)) report "doutB != 0x00" severity error;
  end if;
  assert doutA = std_logic_vector(to_unsigned(255, D_BITS)) report "doutA != 0xFF" severity error;

  -- reset deque
  report "reset deque";
  rst <= '1';
  wait for clk_period*3;
  rst <= '0';
  wait for clk_period;

  -- Operation: writeA and gotA and writeB and gotB
  report "test: 1. writeA and gotA and writeB and gotB";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
  gotA <= '1';
  gotB <= '1';
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  gotB <= '0';
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '0' report "validA != 0!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutB != MIN_DEPTH-1" severity error;

  report "test: 2. writeA and gotA and writeB and gotB, pop last element";
  wait for clk_period;
  gotA <= '1';
  wait for clk_period;
  gotA <= '0';
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;

  report "test: 2. writeA and gotA and writeB and gotB";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(152, D_BITS));--x"98";
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(133, D_BITS));--x"85";
  gotA <= '1';
  gotB <= '1';
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  gotB <= '0';
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutA != MIN_DEPTH-1" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)) report "doutB != MIN_DEPTH-1" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '0' report "validB != 0!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutA = std_logic_vector(to_unsigned(152, D_BITS)) report "doutA != 0x98" severity error;
  assert doutB = std_logic_vector(to_unsigned(133, D_BITS)) report "doutB != 0x85" severity error;

  report "test: 3. writeA and gotA and writeB and gotB";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(86, D_BITS));--x"56";
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(101, D_BITS));--x"65";
  gotA <= '1';
  gotB <= '1';
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  gotB <= '0';
  assert doutA = std_logic_vector(to_unsigned(152, D_BITS)) report "doutA != 0x98" severity error;
  assert doutB = std_logic_vector(to_unsigned(133, D_BITS)) report "doutB != 0x85" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutA = std_logic_vector(to_unsigned(86, D_BITS)) report "doutA != 0x56" severity error;
  assert doutB = std_logic_vector(to_unsigned(101, D_BITS)) report "doutB != 0x65" severity error;

  -- reset deque and refill deque
  report "reset deque and refill deque";
  rst <= '1';
  wait for clk_period*3;
  rst <= '0';
  wait for clk_period;
  -- refill deque
  i := 1;
  j := 0;
  while i < (MIN_DEPTH/2) loop
    putA <= '1';
    dinA <= std_logic_vector(to_unsigned(j, D_BITS));
    putB <= '1';
    dinB <= std_logic_vector(to_unsigned(j+1, D_BITS));
    wait for clk_period;
    putB <= '0';
    dinB <= std_logic_vector(to_unsigned(0, D_BITS));
    putA <= '0';
    dinA <= (others => '0');
    wait for clk_period;
    i := i +1;
    j := j +2;
  end loop;
  wait for clk_period;

  -- 2 spots free
  -- stackpointerA at adr 0
  -- stackpointerB at adr MIN_DEPTH-1
  -- push one element to B to have only one spot left
  dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
  putA <= '1';
  wait for clk_period;
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  putA <= '0';
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)) report "doutA != MIN_DEPTH-4" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;

  report "test: 4. writeA and gotA and writeB and gotB";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(222, D_BITS));--x"DE";
  putB <= '1';
  dinB <= std_logic_vector(to_unsigned(239, D_BITS));--x"EF";
  gotA <= '1';
  gotB <= '1';
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  gotB <= '0';
  assert doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)) report "doutA != MIN_DEPTH-2" severity error;
  assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)) report "doutB != MIN_DEPTH-3" severity error;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 1!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutA = std_logic_vector(to_unsigned(222, D_BITS)) report "doutA != 0xDE" severity error;
  if (MIN_DEPTH > 4) then
    assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-5, D_BITS)) report "doutB != MIN_DEPTH-5" severity error;
  else
    assert doutB = std_logic_vector(to_unsigned(0, D_BITS)) report "doutB != 0x00" severity error;
  end if;

  -- push one element to A and B to fill whole deque
  dinA <= std_logic_vector(to_unsigned(175, D_BITS));--x"AF";
  putA <= '1';
  dinB <= std_logic_vector(to_unsigned(189, D_BITS));--x"BD";
  putB <= '1';
  wait for clk_period;
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  putA <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  putB <= '0';
  assert doutA = std_logic_vector(to_unsigned(222, D_BITS)) report "doutA != 0xDE" severity error;
  if (MIN_DEPTH > 4) then
    assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-5, D_BITS)) report "doutB != MIN_DEPTH-5" severity error;
  else
    assert doutB = std_logic_vector(to_unsigned(0, D_BITS)) report "doutB != 0x00" severity error;
  end if;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  wait for clk_period;
  assert doutA = std_logic_vector(to_unsigned(175, D_BITS)) report "doutA != 0xAF" severity error;
  assert doutB = std_logic_vector(to_unsigned(189, D_BITS)) report "doutB != 0xBD" severity error;
  assert fullA = '1' report "fullA != 1!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 0!" severity error;
  wait for clk_period;

  report "test: 5. writeA and gotA and writeB and gotB";
  putA <= '1';
  dinA <= std_logic_vector(to_unsigned(203, D_BITS));--x"CB";
  putB <= '1';
  dinA <= std_logic_vector(to_unsigned(188, D_BITS));--x"BC";
  gotA <= '1';
  gotB <= '1';
  wait for clk_period;
  putA <= '0';
  dinA <= std_logic_vector(to_unsigned(0, D_BITS));
  putB <= '0';
  dinB <= std_logic_vector(to_unsigned(0, D_BITS));
  gotA <= '0';
  gotB <= '0';
  assert doutA = std_logic_vector(to_unsigned(175, D_BITS)) report "doutA != 0xAF" severity error;
  assert doutB = std_logic_vector(to_unsigned(189, D_BITS)) report "doutB != 0xBD" severity error;
  assert fullA = '1' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '1' report "fullB != 0!" severity error;
  wait for clk_period;
  assert fullA = '0' report "fullA != 0!" severity error;
  assert validA = '1' report "validA != 1!" severity error;
  assert validB = '1' report "validB != 1!" severity error;
  assert fullB = '0' report "fullB != 0!" severity error;
  assert doutA = std_logic_vector(to_unsigned(222, D_BITS)) report "doutB != 0xDE" severity error;
  if (MIN_DEPTH > 4) then
    assert doutB = std_logic_vector(to_unsigned(MIN_DEPTH-5, D_BITS)) report "doutB != MIN_DEPTH-5" severity error;
  else
    assert doutB = std_logic_vector(to_unsigned(0, D_BITS)); report "doutB != 0x00" severity error;
  end if;

  -- reset deque
  report "reset deque";
  rst <= '1';
  wait for clk_period*3;
  rst <= '0';
  wait for clk_period;


  wait for clk_period*5;
  report "TB finished!" severity note;
  -- finished
  done <= '1';
  wait;
end process;

end architecture;
