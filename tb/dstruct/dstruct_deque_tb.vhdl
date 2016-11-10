-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- ============================================================================
-- Authors:					Jens Voss
--
-- Testbench:				dstruct_deque_tb
--
-- Description:
-- ------------
--   Testbench for dstruct_deque.
--
-- License:
-- ============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
--                     Chair of VLSI-Design, Diagnostics and Architecture
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
use			PoC.physical.all;
use			PoC.dstruct.all;
-- simulation only packages
use     PoC.sim_types.all;
use     PoC.simulation.all;
use     PoC.waveform.all;

architecture tb of dstruct_deque_tb is

  -- component generics
  constant MIN_DEPTH : positive := 128;
  constant D_BITS    : positive := 16;

  -- Clock Control
	constant CLK_FREQ : FREQ := 50 MHz;
  signal clk  : std_logic;
  signal rst  : std_logic;

  -- local Signals

	-- PortA
	signal dinA		: std_logic_vector(D_BITS-1 downto 0);
	signal putA		: std_logic;
	signal gotA		: std_logic;
	signal doutA	: std_logic_vector(D_BITS-1 downto 0);
	signal fullA	: std_logic;
	signal validA : std_logic;

	-- Port B
	signal dinB		: std_logic_vector(D_BITS-1 downto 0);
	signal putB		: std_logic;
	signal gotB		: std_logic;
	signal doutB	: std_logic_vector(D_BITS-1 downto 0);
	signal validB : std_logic;
	signal fullB	: std_logic;

begin

	-- Simulation Setup
	simInitialize;
	simGenerateClock(clk, CLK_FREQ);

  -- DUT
  DUT : dstruct_deque
    generic map(
      D_BITS    => D_BITS,
      MIN_DEPTH => MIN_DEPTH
    )
    port map(
      clk    => clk,
      rst    => rst,
      --PORT A
      dinA   => dinA,
      putA   => putA,
      gotA   => gotA,
      doutA  => doutA,
      validA => validA,
      fullA  => fullA,
      --PORT B
      dinB   => dinB,
      putB   => putB,
      gotB   => gotB,
      doutB  => doutB,
      validB => validB,
      fullB  => fullB
    );

-- Stimuli
	process
		procedure cycle(constant n : in positive := 1) is
		begin
			for i in 1 to n loop
				wait until rising_edge(clk);
			end loop;
		end;

		constant PID		 : T_SIM_PROCESS_ID := simRegisterProcess("main");
		variable i, j, k : integer;
	begin
		rst <= '1';
		cycle;

		rst	 <= '0';
		putA <= '0';
		gotA <= '0';
		putB <= '0';
		gotB <= '0';
		cycle;

		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '0', "validA != 0!");
		simAssertion(fullB = '0', "fullA != 0!");
		simAssertion(validB = '0', "validA != 0!");

		-- fill stack with data
		i := 1;
		j := 0;
		while i < (MIN_DEPTH/2) loop
			--for i in 0 to (MIN_DEPTH-2)/2 loop
			putA <= '1';
			dinA <= std_logic_vector(to_unsigned(j, D_BITS));
			cycle;
			putA <= '0';
			dinA <= (others => '0');
			cycle;
			simAssertion(fullA = '0', "fullA != 0!");
			simAssertion(validA = '1', "validA != 1!");
			simAssertion(fullB = '0', "fullB != 0!");
			if i = 1 then
				simAssertion(validB = '0', "validB != 0!");
			else
				simAssertion(validB = '1', "validB != 1!");
			end if;
			putB <= '1';
			dinB <= std_logic_vector(to_unsigned(j+1, D_BITS));
			cycle;
			putB <= '0';
			dinB <= std_logic_vector(to_unsigned(0, D_BITS));
			cycle;
			simAssertion(fullA = '0', "fullA != 0!");
			simAssertion(validA = '1', "validA != 1!");
			simAssertion(fullB = '0', "fullB != 0!");
			simAssertion(validB = '1', "validB != 1!");
			i := i +1;
			j := j +2;
		end loop;
		cycle;

		-- push A and push B
		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		cycle;
		simAssertion(fullA = '1', "fullA != 1!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		simAssertion(validB = '1', "validB != 1!");
		-- push to full deque
		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(3, D_BITS));
		cycle;
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		cycle;
		simAssertion(fullA = '1', "fullA != 1!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		simAssertion(validB = '1', "validB != 1!");
		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(4, D_BITS));
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		cycle;
		simAssertion(fullA = '1', "fullA != 1!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		simAssertion(validB = '1', "validB != 1!");

		-- pop A
		cycle(5);
		gotA <= '1';
		cycle;
		gotA <= '0';
		simAssertion(fullA = '1', "fullA != 1!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		simAssertion(validB = '1', "validB != 1!");

		-- pop whole Deque from B
		i := MIN_DEPTH - 1;
		j := MIN_DEPTH - 1;
		k := 0;
		while i > 1 loop
			gotB <= '1';
			cycle;
			gotB <= '0';
			cycle;
			if i > MIN_DEPTH/2 then
				simAssertion(doutB = std_logic_vector(to_unsigned(j-2, D_BITS)), "doutB !=j-2");
				j := j - 2;
			elsif i = MIN_DEPTH/2 then
				simAssertion(doutB = std_logic_vector(to_unsigned(j-1, D_BITS)), "doutB !=j-2");
			else
				simAssertion(doutB = std_logic_vector(to_unsigned(k+2, D_BITS)), "doutB !=k");
				k := k + 2;
			end if;
			if i /= 2 then
				simAssertion(fullA = '0', "fullA != 0!");
				simAssertion(validA = '1', "validA != 1!");
				simAssertion(fullB = '0', "fullB != 0!");
				simAssertion(validB = '1', "validB != 1!");
			else
				simAssertion(fullA = '0', "fullA != 0!");
				simAssertion(validA = '1', "validA != 1!");
				simAssertion(fullB = '0', "fullB != 0!");
				simAssertion(validB = '0', "validB != 0!");
			end if;
			i := i - 1;
		end loop;
		cycle;

		-- read last spot
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(validB = '0', "validB != 0!");
		cycle;
		gotA <= '1';
		gotB <= '1';
		cycle;
		gotA <= '0';
		gotB <= '0';
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '0', "validA != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(validB = '0', "validB != 0!");
		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(7, D_BITS));
		cycle;
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		cycle;
		simAssertion(doutB = std_logic_vector(to_unsigned(7, D_BITS)), "doutB !=x07");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '0', "validA != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(validB = '0', "validB != 0!");
		cycle;
		simAssertion(validA = '1', "validA != 1!");
		gotA <= '1';
		gotB <= '1';
		cycle;
		gotA <= '0';
		gotB <= '0';
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '0', "validA != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(validB = '0', "validB != 0!");
		cycle;

		-- write last spot
		i := 1;
		j := 0;
		while i < (MIN_DEPTH/2) loop
			--for i in 0 to (MIN_DEPTH-2)/2 loop
			putA <= '1';
			dinA <= std_logic_vector(to_unsigned(j, D_BITS));
			cycle;
			putA <= '0';
			dinA <= std_logic_vector(to_unsigned(0, D_BITS));
			cycle;
			simAssertion(fullA = '0', "fullA != 0!");
			simAssertion(validA = '1', "validA != 1!");
			simAssertion(fullB = '0', "fullB != 0!");
			if i = 1 then
				simAssertion(validB = '0', "validB != 0!");
			else
				simAssertion(validB = '1', "validB != 1!");
			end if;
			putB <= '1';
			dinB <= std_logic_vector(to_unsigned(j+1, D_BITS));
			cycle;
			putB <= '0';
			dinB <= std_logic_vector(to_unsigned(0, D_BITS));
			cycle;
			simAssertion(fullA = '0', "fullA != 0!");
			simAssertion(validA = '1', "validA != 1!");
			simAssertion(validB = '1', "validB != 1!");
			simAssertion(fullB = '0', "fullB != 0!");
			i := i +1;
			j := j +2;
		end loop;
		cycle;
		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(3, D_BITS));
		cycle;
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		putB <= '1';
		putA <= '1';
		dinB <= std_logic_vector(to_unsigned(10, D_BITS));
		dinA <= std_logic_vector(to_unsigned(12, D_BITS));
		cycle;
		putB <= '0';
		putA <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		cycle;
		simAssertion(fullA = '1', "fullA != 1!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		cycle;
		gotB <= '1';
		cycle;
		gotB <= '0';
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		putB <= '1';
		putA <= '1';
		dinB <= std_logic_vector(to_unsigned(10, D_BITS));
		dinA <= std_logic_vector(to_unsigned(12, D_BITS));
		cycle;
		putB <= '0';
		putA <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		cycle;
		simAssertion(fullA = '1', "fullA != 1!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		cycle;
		gotA <= '1';
		cycle;
		gotA <= '0';
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		simAssertion(doutA = std_logic_vector(to_unsigned(12, D_BITS)), "doutA !=x0C");
		cycle;
		gotA <= '1';
		cycle;
		gotA <= '0';
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)), "doutA != MIN_DEPTH-4");
		cycle(2);

		-- reset deque
		rst <= '1';
		cycle;
		rst <= '0';
		cycle;

		-- Testcases for gotA/B and writeA/B parallel
		-- 1) starting with an empty deque
		-- 2) deque holds one valid element before operaton is executed
		-- 3) more than one valid element
		-- 4) one spot left
		-- 5) deque is full

		-- Operation: writeA and gotA
		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
		gotA <= '1';
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '0', "validA != 0!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");

		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(152, D_BITS)); --x"98";
		gotA <= '1';
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutA = std_logic_vector(to_unsigned(152, D_BITS)), "doutA != 0x98");

		cycle;
		gotA <= '1';
		cycle;
		gotA <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(152, D_BITS)), "doutA != 0x98");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '0', "validA != 0!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");

		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutB != MIN_DEPTH-1");
		cycle;
		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(86, D_BITS)); --0x56
		gotA <= '1';
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutA = std_logic_vector(to_unsigned(86, D_BITS)), "doutA != 0x56");

		-- reset deque and refill deque
		rst <= '1';
		cycle;
		rst <= '0';
		cycle;
		-- refill deque
		i := 1;
		j := 0;
		while i < (MIN_DEPTH/2) loop
			putA <= '1';
			dinA <= std_logic_vector(to_unsigned(j, D_BITS));
			putB <= '1';
			dinB <= std_logic_vector(to_unsigned(j+1, D_BITS));
			cycle;
			putB <= '0';
			dinB <= std_logic_vector(to_unsigned(0, D_BITS));
			putA <= '0';
			dinA <= std_logic_vector(to_unsigned(0, D_BITS));
			cycle;
			i := i +1;
			j := j +2;
		end loop;
		cycle;

		-- 2 spots free
		-- stackpointerA at adr 0
		-- stackpointerB at adr MIN_DEPTH-1
		-- push one element to A to have only one spot left
		dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
		putA <= '1';
		cycle;
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		putA <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)), "doutA != MIN_DEPTH-4");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");

		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(222, D_BITS));--x"DE";
		gotA <= '1';
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1");
		simAssertion(fullB = '1', "fullB != 1!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		simAssertion(doutA = std_logic_vector(to_unsigned(222, D_BITS)), "doutA != 0xDE");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");

		-- push one element to A to fill whole deque
		dinA <= std_logic_vector(to_unsigned(175, D_BITS));--x"AF";
		putA <= '1';
		cycle;
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		putA <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(222, D_BITS)), "doutA != 0xDE");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		cycle;
		simAssertion(doutA = std_logic_vector(to_unsigned(175, D_BITS)), "doutA != 0xAF");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(fullA = '1', "fullA != 1!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");

		cycle;

		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(203, D_BITS));--x"CB";
		gotA <= '1';
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(175, D_BITS)), "doutA != 0xAF");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(fullA = '1', "fullA != 1!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		simAssertion(doutA = std_logic_vector(to_unsigned(222, D_BITS)), "doutA != 0xDE");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");

		-- reset deque
		rst <= '1';
		cycle;
		rst <= '0';
		cycle;

		-- Operation: writeB and gotB;
		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
		gotB <= '1';
		cycle;
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		gotB <= '0';
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '0', "validA != 0!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '0', "validA != 1!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutB != MIN_DEPTH-2");
		cycle;
		simAssertion(validA = '1', "validA != 1!");

		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(152, D_BITS));--x"98";
		gotB <= '1';
		cycle;
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		gotB <= '0';
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutB != MIN_DEPTH-2");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutB = std_logic_vector(to_unsigned(152, D_BITS)), "doutB != 0x98");

		cycle;
		gotB <= '1';
		cycle;
		gotB <= '0';
		simAssertion(doutB = std_logic_vector(to_unsigned(152, D_BITS)), "doutB != 0x98");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		gotA <= '1';
		cycle;
		gotA <= '0';
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '0', "validA != 0!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");


		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
		cycle;
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutB != MIN_DEPTH-2");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutA != MIN_DEPTH-1");
		cycle;
		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(86, D_BITS));--x"56";
		gotB <= '1';
		cycle;
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		gotB <= '0';
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutB != MIN_DEPTH-2");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutB = std_logic_vector(to_unsigned(86, D_BITS)), "doutB != 0x56");

		-- reset deque and refill deque
		rst <= '1';
		cycle;
		rst <= '0';
		cycle;
		-- refill deque
		i := 1;
		j := 0;
		while i < (MIN_DEPTH/2) loop
			putA <= '1';
			dinA <= std_logic_vector(to_unsigned(j, D_BITS));
			putB <= '1';
			dinB <= std_logic_vector(to_unsigned(j+1, D_BITS));
			cycle;
			putB <= '0';
			dinB <= std_logic_vector(to_unsigned(0, D_BITS));
			putA <= '0';
			dinA <= (others => '0');
			cycle;
			i := i +1;
			j := j +2;
		end loop;
		cycle;

		-- 2 spots free
		-- stackpointerA at adr 0
		-- stackpointerB at adr MIN_DEPTH-1
		-- push one element to B to have only one spot left
		dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
		putB <= '1';
		cycle;
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		putB <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)), "doutA != MIN_DEPTH-4");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)), "doutA != MIN_DEPTH-4");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutB != MIN_DEPTH-1");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");

		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(222, D_BITS));--x"DE";
		gotB <= '1';
		cycle;
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		gotB <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)), "doutA != MIN_DEPTH-4");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutB != MIN_DEPTH-1");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)), "doutA != MIN_DEPTH-4");

		-- push one element to A to fill whole deque
		dinB <= std_logic_vector(to_unsigned(175, D_BITS));--x"AF";
		putB <= '1';
		cycle;
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		putB <= '0';
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)), "doutA != MIN_DEPTH-4");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(doutB = std_logic_vector(to_unsigned(175, D_BITS)), "doutB != 0xAF");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)), "doutA != MIN_DEPTH-4");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		cycle;
		dinA <= std_logic_vector(to_unsigned(191, D_BITS));--x"BF";
		putA <= '1';
		cycle;
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		putA <= '0';
		cycle;
		simAssertion(fullA = '1', "fullA != 1!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");

		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(203, D_BITS));--x"CB";
		gotB <= '1';
		cycle;
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		gotB <= '0';
		simAssertion(doutB = std_logic_vector(to_unsigned(175, D_BITS)), "doutB != 0xAF");
		simAssertion(doutA = std_logic_vector(to_unsigned(191, D_BITS)), "doutA != 0xBF");
		simAssertion(fullA = '1', "fullA != 1!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(doutA = std_logic_vector(to_unsigned(191, D_BITS)), "doutA != 0xBF");


		-- reset deque
		rst <= '1';
		cycle;
		rst <= '0';
		cycle;

		-- Operation: writeB and gotA
		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
		gotA <= '1';
		cycle;
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '0', "validA != 0!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '0', "validA != 1!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutB != MIN_DEPTH-2");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		cycle;
		simAssertion(validA = '1', "validA != 1!");

		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(152, D_BITS));--x"98";
		gotA <= '1';
		cycle;
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutB != MIN_DEPTH-2");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '0', "validA != 1!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutB = std_logic_vector(to_unsigned(152, D_BITS)), "doutB != 0x98");
		simAssertion(doutA = std_logic_vector(to_unsigned(152, D_BITS)), "doutA != 0x98");
		cycle;
		simAssertion(validA = '1', "validA != 1!");

		cycle;
		gotA <= '1';
		cycle;
		gotA <= '0';
		simAssertion(doutB = std_logic_vector(to_unsigned(152, D_BITS)), "doutB != 0x98");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '0', "validA != 0!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");

		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
		cycle;
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutB != MIN_DEPTH-2");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutA != MIN_DEPTH-1");
		cycle;
		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(86, D_BITS));--x"56";
		gotA <= '1';
		cycle;
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutB != MIN_DEPTH-2");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutA != MIN_DEPTH-1");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutB = std_logic_vector(to_unsigned(86, D_BITS)), "doutB != 0x56");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");

		-- reset deque and refill deque
		rst <= '1';
		cycle;
		rst <= '0';
		cycle;
		-- refill deque
		i := 1;
		j := 0;
		while i < (MIN_DEPTH/2) loop
			putA <= '1';
			dinA <= std_logic_vector(to_unsigned(j, D_BITS));
			putB <= '1';
			dinB <= std_logic_vector(to_unsigned(j+1, D_BITS));
			cycle;
			putB <= '0';
			dinB <= std_logic_vector(to_unsigned(0, D_BITS));
			putA <= '0';
			dinA <= (others => '0');
			cycle;
			i := i +1;
			j := j +2;
		end loop;
		cycle;

		-- 2 spots free
		-- stackpointerA at adr 0
		-- stackpointerB at adr MIN_DEPTH-1
		-- push one element to B to have only one spot left
		dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
		putB <= '1';
		cycle;
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		putB <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)), "doutA != MIN_DEPTH-4");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)), "doutA != MIN_DEPTH-4");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutB != MIN_DEPTH-1");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");

		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(222, D_BITS));--x"DE";
		gotA <= '1';
		cycle;
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)), "doutA != MIN_DEPTH-4");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutB != MIN_DEPTH-1");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutB != MIN_DEPTH-1");
		if MIN_DEPTH > 4 then
			simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-6, D_BITS)), "doutA != MIN_DEPTH-6");
		else
			simAssertion(doutA = std_logic_vector(to_unsigned(1, D_BITS)), "doutA != 0x01");
		end if;

		-- push one element to A to fill whole deque
		dinB <= std_logic_vector(to_unsigned(175, D_BITS));--x"AF";
		putB <= '1';
		cycle;
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		putB <= '0';
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutB != MIN_DEPTH-1");
		if MIN_DEPTH > 4 then
			simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-6, D_BITS)), "doutA != MIN_DEPTH-6");
		else
			simAssertion(doutA = std_logic_vector(to_unsigned(1, D_BITS)), "doutA != 0x01");
		end if;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		dinA <= std_logic_vector(to_unsigned(205, D_BITS));--x"CD";
		putA <= '1';
		cycle;
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		putA <= '0';
		cycle;
		simAssertion(fullA = '1', "fullA != 1!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		simAssertion(doutB = std_logic_vector(to_unsigned(175, D_BITS)), "doutB != 0xAF");
		simAssertion(doutA = std_logic_vector(to_unsigned(205, D_BITS)), "doutA != 0xCD");
		cycle;

		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(203, D_BITS));--x"CB";
		gotA <= '1';
		cycle;
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		simAssertion(fullA = '1', "fullA != 1!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		simAssertion(doutA = std_logic_vector(to_unsigned(205, D_BITS)), "doutA != 0xCD");
		simAssertion(doutB = std_logic_vector(to_unsigned(175, D_BITS)), "doutB != 0xAF");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		simAssertion(doutB = std_logic_vector(to_unsigned(175, D_BITS)), "doutB != 0xAF");
		if MIN_DEPTH > 4 then
			simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-6, D_BITS)), "doutA != MIN_DEPTH-6");
		else
			simAssertion(doutA = std_logic_vector(to_unsigned(1, D_BITS)), "doutA != 0x01");
		end if;

		-- reset deque
		rst <= '1';
		cycle;
		rst <= '0';
		cycle;

		-- operation: writeA and gotB
		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
		gotB <= '1';
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		gotB <= '0';
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '0', "validA != 0!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutB != MIN_DEPTH-2");

		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(152, D_BITS));--x"98";
		gotB <= '1';
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		gotB <= '0';
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutB != MIN_DEPTH-2");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutA = std_logic_vector(to_unsigned(152, D_BITS)), "doutA != 0x98");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutB != MIN_DEPTH-2");

		cycle;
		gotA <= '1';
		cycle;
		gotA <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(152, D_BITS)), "doutB != 0x98");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		gotA <= '1';
		cycle;
		gotA <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '0', "validA != 0!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");

		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
		cycle;
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutB != MIN_DEPTH-2");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutA != MIN_DEPTH-1");
		cycle;
		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(86, D_BITS)); --x"56"
		gotB <= '1';
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		gotB <= '0';
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutB != MIN_DEPTH-2");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutA != MIN_DEPTH-1");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutA = std_logic_vector(to_unsigned(86, D_BITS)), "doutB != 0x56");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutB != MIN_DEPTH-1");

		-- reset deque and refill deque
		rst <= '1';
		cycle;
		rst <= '0';
		cycle;
		-- refill deque
		i := 1;
		j := 0;
		while i < (MIN_DEPTH/2) loop
			putA <= '1';
			dinA <= std_logic_vector(to_unsigned(j, D_BITS));
			putB <= '1';
			dinB <= std_logic_vector(to_unsigned(j+1, D_BITS));
			cycle;
			putB <= '0';
			dinB <= std_logic_vector(to_unsigned(0, D_BITS));
			putA <= '0';
			dinA <= (others => '0');
			cycle;
			i := i +1;
			j := j +2;
		end loop;
		cycle;

		-- 2 spots free
		-- stackpointerA at adr 0
		-- stackpointerB at adr MIN_DEPTH-1
		-- push one element to A to have only one spot left
		dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
		putA <= '1';
		cycle;
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		putA <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)), "doutA != MIN_DEPTH-4");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-1");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");

		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(222, D_BITS));--x"DE";
		gotB <= '1';
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		gotB <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		simAssertion(doutA = std_logic_vector(to_unsigned(222, D_BITS)), "doutA != 0xDE");
		if MIN_DEPTH > 4 then
			simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-5, D_BITS)), "doutB != MIN_DEPTH-5");
		else
			simAssertion(doutB = std_logic_vector(to_unsigned(0, D_BITS)), "doutB != 0x00");
		end if;

		-- push one element to A to fill whole deque
		dinA <= std_logic_vector(to_unsigned(175, D_BITS));--x"AF";
		putA <= '1';
		cycle;
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		putA <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(222, D_BITS)), "doutA != 0xDE");
		if MIN_DEPTH > 4 then
			simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-5, D_BITS)), "doutB != MIN_DEPTH-5");
		else
			simAssertion(doutB = std_logic_vector(to_unsigned(0, D_BITS)), "doutB != 0x00");
		end if;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		cycle;
		simAssertion(doutA = std_logic_vector(to_unsigned(175, D_BITS)), "doutA != 0xAF");
		if MIN_DEPTH > 4 then
			simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-5, D_BITS)), "doutB != MIN_DEPTH-5");
		else
			simAssertion(doutB = std_logic_vector(to_unsigned(0, D_BITS)), "doutB != 0x00");
		end if;
		simAssertion(fullA = '1', "fullA != 1!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		cycle;

		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(203, D_BITS));--x"CB";
		gotB <= '1';
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		gotB <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(175, D_BITS)), "doutB != 0xAF");
		if MIN_DEPTH > 4 then
			simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-5, D_BITS)), "doutB != MIN_DEPTH-5");
		else
			simAssertion(doutB = std_logic_vector(to_unsigned(0, D_BITS)), "doutB != 0x00");
		end if;
		simAssertion(fullA = '1', "fullA != 1!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		simAssertion(doutA = std_logic_vector(to_unsigned(175, D_BITS)), "doutA != 0xAF");
		if MIN_DEPTH > 4 then
			simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-7, D_BITS)), "doutB != MIN_DEPTH-7");
		else
			simAssertion(doutB = std_logic_vector(to_unsigned(2, D_BITS)), "doutB != 0x02");
		end if;

		-- reset deque
		rst <= '1';
		cycle;
		rst <= '0';
		cycle;

		-- Operation: writeB and gotB and gotA
		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
		gotA <= '1';
		gotB <= '1';
		cycle;
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		gotB <= '0';
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '0', "validA != 0!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '0', "validA != 1!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutB != MIN_DEPTH-2");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		cycle;
		simAssertion(validA = '1', "validA != 1!");

		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(152, D_BITS));--x"98";
		gotA <= '1';
		gotB <= '1';
		cycle;
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		gotB <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutB != MIN_DEPTH-2");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '0', "validA != 1!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutB = std_logic_vector(to_unsigned(152, D_BITS)), "doutB != 0x98");
		simAssertion(doutA = std_logic_vector(to_unsigned(152, D_BITS)), "doutA != 0x98");
		cycle;
		simAssertion(validA = '1', "validA != 1!");


		cycle;
		gotA <= '1';
		cycle;
		gotA <= '0';
		simAssertion(doutB = std_logic_vector(to_unsigned(152, D_BITS)), "doutB != 0x98");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '0', "validA != 0!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");

		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
		cycle;
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutB != MIN_DEPTH-2");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutA != MIN_DEPTH-1");
		cycle;
		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(86, D_BITS));--x"56";
		gotA <= '1';
		gotB <= '1';
		cycle;
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		gotB <= '0';
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutB != MIN_DEPTH-2");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutA != MIN_DEPTH-1");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutB = std_logic_vector(to_unsigned(86, D_BITS)), "doutB != 0x56");
		simAssertion(doutA = std_logic_vector(to_unsigned(86, D_BITS)), "doutA != 0x56");

		-- reset deque and refill deque
		rst <= '1';
		cycle;
		rst <= '0';
		cycle;
		-- refill deque
		i := 1;
		j := 0;
		while i < (MIN_DEPTH/2) loop
			putA <= '1';
			dinA <= std_logic_vector(to_unsigned(j, D_BITS));
			putB <= '1';
			dinB <= std_logic_vector(to_unsigned(j+1, D_BITS));
			cycle;
			putB <= '0';
			dinB <= std_logic_vector(to_unsigned(0, D_BITS));
			putA <= '0';
			dinA <= (others => '0');
			cycle;
			i := i +1;
			j := j +2;
		end loop;
		cycle;

		-- 2 spots free
		-- stackpointerA at adr 0
		-- stackpointerB at adr MIN_DEPTH-1
		-- push one element to B to have only one spot left
		dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
		putB <= '1';
		cycle;
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		putB <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)), "doutA != MIN_DEPTH-4");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)), "doutA != MIN_DEPTH-4");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutB != MIN_DEPTH-1");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");

		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(222, D_BITS));--x"DE";
		gotA <= '1';
		gotB <= '1';
		cycle;
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		gotB <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)), "doutA != MIN_DEPTH-4");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutB != MIN_DEPTH-1");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		if MIN_DEPTH > 4 then
			simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-6, D_BITS)), "doutA != MIN_DEPTH-6");
			simAssertion(validB = '1', "validB != 1!");
		else
			simAssertion(doutA = std_logic_vector(to_unsigned(1, D_BITS)), "doutA != 0x01");
			simAssertion(validB = '0', "validB != 0!");
		end if;

		-- push one element to A and B to fill whole deque
		dinB <= std_logic_vector(to_unsigned(175, D_BITS));--x"AF";
		dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS));
		putB <= '1';
		putA <= '1';
		cycle;
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		putB <= '0';
		putA <= '0';
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		if MIN_DEPTH > 4 then
			simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-6, D_BITS)), "doutA != MIN_DEPTH-6");
			simAssertion(validB = '1', "validB != 1!");
		else
			simAssertion(doutA = std_logic_vector(to_unsigned(1, D_BITS)), "doutA != 0x01");
			simAssertion(validB = '0', "validB != 0!");
		end if;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(doutB = std_logic_vector(to_unsigned(175, D_BITS)), "doutB != 0xAF");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)), "doutA != MIN_DEPTH-4");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		cycle;
		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(171, D_BITS));--x"AB";
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		cycle;
		simAssertion(doutB = std_logic_vector(to_unsigned(175, D_BITS)), "doutB != 0xAF");
		simAssertion(doutA = std_logic_vector(to_unsigned(171, D_BITS)), "doutA != 0xAB");
		simAssertion(fullA = '1', "fullA != 1!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");


		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(203, D_BITS));--x"CB";
		gotA <= '1';
		gotB <= '1';
		cycle;
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		gotB <= '0';
		simAssertion(doutB = std_logic_vector(to_unsigned(175, D_BITS)), "doutB != 0xAF");
		simAssertion(doutA = std_logic_vector(to_unsigned(171, D_BITS)), "doutA != 0xAB");
		simAssertion(fullA = '1', "fullA != 1!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)), "doutA != MIN_DEPTH-4");

		-- reset deque
		rst <= '1';
		cycle;
		rst <= '0';
		cycle;

		-- Operation: writeA and gotA and gotB
		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
		gotA <= '1';
		gotB <= '1';
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		gotB <= '0';
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '0', "validA != 0!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		cycle;
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutB != MIN_DEPTH-2");

		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(152, D_BITS));--x"98";
		gotA <= '1';
		gotB <= '1';
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		gotB <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutB != MIN_DEPTH-2");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutA = std_logic_vector(to_unsigned(152, D_BITS)), "doutA != 0x98");
		simAssertion(doutB = std_logic_vector(to_unsigned(152, D_BITS)), "doutB != 0x98");

		cycle;
		gotA <= '1';
		cycle;
		gotA <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(152, D_BITS)), "doutA != 0x98");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '0', "validA != 0!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");

		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		putB <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutB != MIN_DEPTH-1");
		cycle;
		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(86, D_BITS));--x"56";
		gotA <= '1';
		gotB <= '1';
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		gotB <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutB != MIN_DEPTH-1");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutA = std_logic_vector(to_unsigned(86, D_BITS)), "doutA != 0x56");
		simAssertion(doutB = std_logic_vector(to_unsigned(86, D_BITS)), "doutB != 0x56");

		-- reset deque and refill deque
		rst <= '1';
		cycle;
		rst <= '0';
		cycle;
		-- refill deque
		i := 1;
		j := 0;
		while i < (MIN_DEPTH/2) loop
			putA <= '1';
			dinA <= std_logic_vector(to_unsigned(j, D_BITS));
			putB <= '1';
			dinB <= std_logic_vector(to_unsigned(j+1, D_BITS));
			cycle;
			putB <= '0';
			dinB <= std_logic_vector(to_unsigned(0, D_BITS));
			putA <= '0';
			dinA <= (others => '0');
			cycle;
			i := i +1;
			j := j +2;
		end loop;
		cycle;

		-- 2 spots free
		-- stackpointerA at adr 0
		-- stackpointerB at adr MIN_DEPTH-1
		-- push one element to B to have only one spot left
		dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
		putA <= '1';
		cycle;
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		putA <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)), "doutA != MIN_DEPTH-4");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");

		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(222, D_BITS));--x"DE";
		gotA <= '1';
		gotB <= '1';
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		gotB <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutA = std_logic_vector(to_unsigned(222, D_BITS)), "doutB != 0xDE");
		if MIN_DEPTH > 4 then
			simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-5, D_BITS)), "doutA != MIN_DEPTH-5");
		else
			simAssertion(doutB = std_logic_vector(to_unsigned(0, D_BITS)), "doutB != 0x00");
		end if;

		-- push one element to A and B to fill whole deque
		dinA <= std_logic_vector(to_unsigned(175, D_BITS));--x"AF";
		dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS));
		putB <= '1';
		putA <= '1';
		cycle;
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		putB <= '0';
		putA <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(222, D_BITS)), "doutA != 0xDE");
		if MIN_DEPTH > 4 then
			simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-5, D_BITS)), "doutB != MIN_DEPTH-5");
		else
			simAssertion(doutB = std_logic_vector(to_unsigned(0, D_BITS)), "doutB != 0x00");
		end if;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(doutA = std_logic_vector(to_unsigned(175, D_BITS)), "doutA != 0xAF");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(fullA = '1', "fullA != 1!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		cycle;

		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(203, D_BITS));--x"CB";
		gotA <= '1';
		gotB <= '1';
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		gotB <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(175, D_BITS)), "doutB != 0xAF");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutA != MIN_DEPTH-3");
		simAssertion(fullA = '1', "fullA != 1!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutA = std_logic_vector(to_unsigned(222, D_BITS)), "doutB != 0xDE");
		if MIN_DEPTH > 4 then
			simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-5, D_BITS)), "doutB != MIN_DEPTH-5");
		else
			simAssertion(doutB = std_logic_vector(to_unsigned(0, D_BITS)), "doutB != 0x00");
		end if;

		-- reset deque
		rst <= '1';
		cycle;
		rst <= '0';
		cycle;

		-- Operation writeA and gotA and writeB
		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
		gotA <= '1';
		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '0', "validA != 0!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutB != MIN_DEPTH-1");

		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(152, D_BITS));--x"98"
		dinB <= std_logic_vector(to_unsigned(144, D_BITS));--x"90";
		gotA <= '1';
		putB <= '1';
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutB != MIN_DEPTH-1");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		if MIN_DEPTH > 4 then
			simAssertion(fullB = '0', "fullB != 0!");
		else
			simAssertion(fullB = '1', "fullB != 1!");
		end if;
		simAssertion(doutA = std_logic_vector(to_unsigned(152, D_BITS)), "doutA != 0x98");
		simAssertion(doutB = std_logic_vector(to_unsigned(144, D_BITS)), "doutB != 0x90");


		cycle;
		gotB <= '1';
		cycle;
		gotB <= '0';
		simAssertion(doutB = std_logic_vector(to_unsigned(144, D_BITS)), "doutB != 0x90");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		if MIN_DEPTH > 4 then
			simAssertion(fullB = '0', "fullB != 0!");
		else
			simAssertion(fullB = '1', "fullB != 1!");
		end if;
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutB != MIN_DEPTH-1");


		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(86, D_BITS));--x"56";
		gotA <= '1';
		putB <= '1';
		dinB <=std_logic_vector(to_unsigned(38, D_BITS));-- x"26";
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		simAssertion(doutA = std_logic_vector(to_unsigned(152, D_BITS)), "doutA != 0x98");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutB != MIN_DEPTH-1");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		if MIN_DEPTH > 4 then
			simAssertion(fullB = '0', "fullB != 0!");
		else
			simAssertion(fullB = '1', "fullB != 1!");
		end if;
		simAssertion(doutA = std_logic_vector(to_unsigned(86, D_BITS)), "doutA != 0x56");
		simAssertion(doutB = std_logic_vector(to_unsigned(38, D_BITS)), "doutB != 0x26");

		-- reset deque and refill deque
		rst <= '1';
		cycle;
		rst <= '0';
		cycle;
		-- refill deque
		i := 1;
		j := 0;
		while i < (MIN_DEPTH/2) loop
			putA <= '1';
			dinA <= std_logic_vector(to_unsigned(j, D_BITS));
			putB <= '1';
			dinB <= std_logic_vector(to_unsigned(j+1, D_BITS));
			cycle;
			putB <= '0';
			dinB <= std_logic_vector(to_unsigned(0, D_BITS));
			putA <= '0';
			dinA <= (others => '0');
			cycle;
			i := i +1;
			j := j +2;
		end loop;
		cycle;

		-- 2 spots free
		-- stackpointerA at adr 0
		-- stackpointerB at adr MIN_DEPTH-1
		-- push one element to B to have only one spot left
		dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
		putA <= '1';
		cycle;
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		putA <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)), "doutA != MIN_DEPTH-4");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");

		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(222, D_BITS));--x"DE";
		gotA <= '1';
		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(66, D_BITS));--x"42";
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		putB <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		cycle;
		simAssertion(doutA = std_logic_vector(to_unsigned(222, D_BITS)), "doutA != 0xDE");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		cycle;
		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(250, D_BITS));--x"FA";
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		cycle;
		simAssertion(fullA = '1', "fullA != 1!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		simAssertion(doutA = std_logic_vector(to_unsigned(250, D_BITS)), "doutA != 0xFA");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");

		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(203, D_BITS));--x"CB";
		gotA <= '1';
		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(174, D_BITS));--x"AE";
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		simAssertion(fullA = '1', "fullA != 1!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		simAssertion(doutA = std_logic_vector(to_unsigned(250, D_BITS)), "doutA != 0xFA");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		simAssertion(doutA = std_logic_vector(to_unsigned(222, D_BITS)), "doutA != 0xDE");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");


		-- reset deque
		rst <= '1';
		cycle;
		rst <= '0';
		cycle;

		-- Operation: writeB and gotB and writeA

		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
		gotB <= '1';
		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		gotB <= '0';
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '0', "validA != 0!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutB != MIN_DEPTH-1");

		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(152, D_BITS));--x"98";
		dinB <= std_logic_vector(to_unsigned(144, D_BITS));--x"90";
		gotB <= '1';
		putB <= '1';
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		gotB <= '0';
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutB != MIN_DEPTH-1");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		if MIN_DEPTH > 4 then
			simAssertion(fullB = '0', "fullB != 0!");
		else
			simAssertion(fullB = '1', "fullB != 1!");
		end if;
		simAssertion(doutA = std_logic_vector(to_unsigned(152, D_BITS)), "doutA != 0x98");
		simAssertion(doutB = std_logic_vector(to_unsigned(144, D_BITS)), "doutB != 0x90");


		cycle;
		gotA <= '1';
		cycle;
		gotA <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(152, D_BITS)), "doutA != 0x98");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");

		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(86, D_BITS));
		gotB <= '1';
		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(38, D_BITS));
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		gotB <= '0';
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		simAssertion(doutB = std_logic_vector(to_unsigned(144, D_BITS)), "doutA != 0x90");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		if MIN_DEPTH > 4 then
			simAssertion(fullB = '0', "fullB != 0!");
		else
			simAssertion(fullB = '1', "fullB != 1!");
		end if;
		simAssertion(doutA = std_logic_vector(to_unsigned(86, D_BITS)), "doutA != 0x56");
		simAssertion(doutB = std_logic_vector(to_unsigned(38, D_BITS)), "doutB != 0x26");

		-- reset deque and refill deque
		rst <= '1';
		cycle;
		rst <= '0';
		cycle;
		-- refill deque
		i := 1;
		j := 0;
		while i < (MIN_DEPTH/2) loop
			putA <= '1';
			dinA <= std_logic_vector(to_unsigned(j, D_BITS));
			putB <= '1';
			dinB <= std_logic_vector(to_unsigned(j+1, D_BITS));
			cycle;
			putB <= '0';
			dinB <= std_logic_vector(to_unsigned(0, D_BITS));
			putA <= '0';
			dinA <= (others => '0');
			cycle;
			i := i +1;
			j := j +2;
		end loop;
		cycle;

		-- 2 spots free
		-- stackpointerA at adr 0
		-- stackpointerB at adr MIN_DEPTH-1
		-- push one element to B to have only one spot left
		dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
		putB <= '1';
		cycle;
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		putB <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)), "doutA != MIN_DEPTH-4");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutB != MIN_DEPTH-1");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");

		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(222, D_BITS));--x"DE";
		gotB <= '1';
		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(66, D_BITS));--x"42";
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		gotB <= '0';
		putB <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)), "doutA != MIN_DEPTH-4");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutB != MIN_DEPTH-1");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		cycle;
		simAssertion(doutA = std_logic_vector(to_unsigned(222, D_BITS)), "doutA != 0xDE");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-1");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");

		dinA <= std_logic_vector(to_unsigned(255, D_BITS));--x"FF";
		putA <= '1';
		cycle;
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		putA <= '0';
		cycle;
		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(203, D_BITS));--x"CB";
		gotB <= '1';
		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(174, D_BITS));--x"AE";
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		gotB <= '0';
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		simAssertion(doutA = std_logic_vector(to_unsigned(255, D_BITS)), "doutA != 0xFF");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(fullA = '1', "fullA != 1!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		if MIN_DEPTH > 4 then
			simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-5, D_BITS)), "doutB != MIN_DEPTH-5");
		else
			simAssertion(doutB = std_logic_vector(to_unsigned(0, D_BITS)), "doutB != 0x00");
		end if;
		simAssertion(doutA = std_logic_vector(to_unsigned(255, D_BITS)), "doutA != 0xFF");

		-- reset deque
		rst <= '1';
		cycle;
		rst <= '0';
		cycle;

		-- Operation: writeA and gotA and writeB and gotB
		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS));
		gotA <= '1';
		gotB <= '1';
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		gotB <= '0';
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '0', "validA != 0!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutB != MIN_DEPTH-1");

		cycle;
		gotA <= '1';
		cycle;
		gotA <= '0';
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");

		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(152, D_BITS));--x"98";
		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(133, D_BITS));--x"85";
		gotA <= '1';
		gotB <= '1';
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		gotB <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutA != MIN_DEPTH-1");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-1, D_BITS)), "doutB != MIN_DEPTH-1");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '0', "validB != 0!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutA = std_logic_vector(to_unsigned(152, D_BITS)), "doutA != 0x98");
		simAssertion(doutB = std_logic_vector(to_unsigned(133, D_BITS)), "doutB != 0x85");

		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(86, D_BITS));--x"56";
		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(101, D_BITS));--x"65";
		gotA <= '1';
		gotB <= '1';
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		gotB <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(152, D_BITS)), "doutA != 0x98");
		simAssertion(doutB = std_logic_vector(to_unsigned(133, D_BITS)), "doutB != 0x85");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutA = std_logic_vector(to_unsigned(86, D_BITS)), "doutA != 0x56");
		simAssertion(doutB = std_logic_vector(to_unsigned(101, D_BITS)), "doutB != 0x65");

		-- reset deque and refill deque
		rst <= '1';
		cycle;
		rst <= '0';
		cycle;
		-- refill deque
		i := 1;
		j := 0;
		while i < (MIN_DEPTH/2) loop
			putA <= '1';
			dinA <= std_logic_vector(to_unsigned(j, D_BITS));
			putB <= '1';
			dinB <= std_logic_vector(to_unsigned(j+1, D_BITS));
			cycle;
			putB <= '0';
			dinB <= std_logic_vector(to_unsigned(0, D_BITS));
			putA <= '0';
			dinA <= (others => '0');
			cycle;
			i := i +1;
			j := j +2;
		end loop;
		cycle;

		-- 2 spots free
		-- stackpointerA at adr 0
		-- stackpointerB at adr MIN_DEPTH-1
		-- push one element to B to have only one spot left
		dinA <= std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS));
		putA <= '1';
		cycle;
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		putA <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-4, D_BITS)), "doutA != MIN_DEPTH-4");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");

		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(222, D_BITS));--x"DE";
		putB <= '1';
		dinB <= std_logic_vector(to_unsigned(239, D_BITS));--x"EF";
		gotA <= '1';
		gotB <= '1';
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		gotB <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(MIN_DEPTH-2, D_BITS)), "doutA != MIN_DEPTH-2");
		simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-3, D_BITS)), "doutB != MIN_DEPTH-3");
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 1!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutA = std_logic_vector(to_unsigned(222, D_BITS)), "doutA != 0xDE");
		if MIN_DEPTH > 4 then
			simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-5, D_BITS)), "doutB != MIN_DEPTH-5");
		else
			simAssertion(doutB = std_logic_vector(to_unsigned(0, D_BITS)), "doutB != 0x00");
		end if;

		-- push one element to A and B to fill whole deque
		dinA <= std_logic_vector(to_unsigned(175, D_BITS));--x"AF";
		putA <= '1';
		dinB <= std_logic_vector(to_unsigned(189, D_BITS));--x"BD";
		putB <= '1';
		cycle;
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		putA <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		putB <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(222, D_BITS)), "doutA != 0xDE");
		if MIN_DEPTH > 4 then
			simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-5, D_BITS)), "doutB != MIN_DEPTH-5");
		else
			simAssertion(doutB = std_logic_vector(to_unsigned(0, D_BITS)), "doutB != 0x00");
		end if;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		cycle;
		simAssertion(doutA = std_logic_vector(to_unsigned(175, D_BITS)), "doutA != 0xAF");
		simAssertion(doutB = std_logic_vector(to_unsigned(189, D_BITS)), "doutB != 0xBD");
		simAssertion(fullA = '1', "fullA != 1!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 0!");
		cycle;

		putA <= '1';
		dinA <= std_logic_vector(to_unsigned(203, D_BITS));--x"CB";
		putB <= '1';
		dinA <= std_logic_vector(to_unsigned(188, D_BITS));--x"BC";
		gotA <= '1';
		gotB <= '1';
		cycle;
		putA <= '0';
		dinA <= std_logic_vector(to_unsigned(0, D_BITS));
		putB <= '0';
		dinB <= std_logic_vector(to_unsigned(0, D_BITS));
		gotA <= '0';
		gotB <= '0';
		simAssertion(doutA = std_logic_vector(to_unsigned(175, D_BITS)), "doutA != 0xAF");
		simAssertion(doutB = std_logic_vector(to_unsigned(189, D_BITS)), "doutB != 0xBD");
		simAssertion(fullA = '1', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '1', "fullB != 0!");
		cycle;
		simAssertion(fullA = '0', "fullA != 0!");
		simAssertion(validA = '1', "validA != 1!");
		simAssertion(validB = '1', "validB != 1!");
		simAssertion(fullB = '0', "fullB != 0!");
		simAssertion(doutA = std_logic_vector(to_unsigned(222, D_BITS)), "doutB != 0xDE");
		if MIN_DEPTH > 4 then
			simAssertion(doutB = std_logic_vector(to_unsigned(MIN_DEPTH-5, D_BITS)), "doutB != MIN_DEPTH-5");
		else
			simAssertion(doutB = std_logic_vector(to_unsigned(0, D_BITS)), "doutB != 0x00");
		end if;

		simDeactivateProcess(PID);
		wait;   -- forever
	end process;

end architecture;
