-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- ============================================================================
-- Authors:     Jens Voss
--
-- Entity:      dstruct_stack_tb
--
-- Description:
-- ------------
--   Testbench for dstruct_stack.
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

entity dstruct_stack_tb is
end entity;


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library PoC;
use PoC.physical.all;
use PoC.dstruct.all;
-- simulation only packages
use	PoC.sim_types.all;
use	PoC.simulation.all;
use	PoC.waveform.all;

architecture tb of dstruct_stack_tb is

  -- component generics
  constant MIN_DEPTH : positive :=  8;
  constant D_BITS    : positive := 16;

  -- Clock Control
	constant CLK_FREQ : FREQ := 50 MHz;

	signal clk  : std_logic;
  signal rst  : std_logic;

	-- DUT Connectivity
  -- inputs
  signal din : std_logic_vector(D_BITS-1 downto 0);
  signal put : std_logic;
  signal got : std_logic;

  -- outputs
  signal dout : std_logic_vector(D_BITS-1 downto 0);
  signal full : std_logic;
  signal valid : std_logic;
  signal empty : std_logic;

begin

	-- Simulation Setup
	simInitialize;
	simGenerateClock(clk, CLK_FREQ);

  -- DUT
  DUT : dstruct_stack
    generic map (
      D_BITS    => D_BITS,
      MIN_DEPTH => MIN_DEPTH
    )
    port map(
      clk   => clk,
      rst   => rst,
      din   => din,
      put   => put,
      full  => full,
      got   => got,
      dout  => dout,
      valid => valid
    );

  -- Stimuli
  process
    procedure checkTOS(constant EXPECT : in integer) is
		begin
			simAssertion(to_integer(unsigned(dout)) = EXPECT, "Wrong top of stack: "&
									 integer'image(to_integer(unsigned(dout)))&
									 " instead of "&integer'image(EXPECT));
		end procedure checkTOS;

    constant PID  : T_SIM_PROCESS_ID := simRegisterProcess("main");
    variable high : integer;
  begin

		-- Reset Sequence
		rst <= '1';
		wait until rising_edge(clk);
		rst <= '0';
		put <= '0';
		got <= '0';
		wait until falling_edge(clk);
		simAssertion(valid = '0', "valid != 0!");
		simAssertion(full = '0', "full != 0!");

		-- Fill stack with data
		put <= '1';
		din <= (others => '0');
		while full = '0' loop
			wait until falling_edge(clk);
			simAssertion(valid = '1', "valid != 1!");
			din <= std_logic_vector(unsigned(din)+1);
		end loop;
		high := to_integer(unsigned(din));

		-- One more, which should not be accepted!
		din <= (others => 'X');
    wait until falling_edge(clk);
		put <= '0';
    simAssertion(valid = '1', "valid != 1!");
    simAssertion(full = '1', "full != 1!");

		-- Idle
    wait until falling_edge(clk);
		checkTOS(high);

		-- Pop two (2) elements
		got <= '1';

    wait until falling_edge(clk);
		high := high - 1;
		simAssertion(full = '0', "full != 0");
		simAssertion(valid = '1', "valid != 1");
		checkTOS(high);

    wait until falling_edge(clk);
		high := high - 1;
		simAssertion(full = '0', "full != 0");
		simAssertion(valid = '1', "valid != 1");
		checkTOS(high);

		got <= '0';

		-- Push two (2) zeroes
		din <= (others => '0');
		put <= '1';
    wait until falling_edge(clk);
		simAssertion(full = '0', "full != 0");
		simAssertion(valid = '1', "valid != 1");
    wait until falling_edge(clk);
		simAssertion(full = '1', "full != 1");
		simAssertion(valid = '1', "valid != 1");

		-- One more, which should not be accepted!
		din <= (others => 'X');
    wait until falling_edge(clk);
		put <= '0';

		-- Pop two (2) zeroes
		got <= '1';

    simAssertion(valid = '1', "valid != 1!");
    simAssertion(full = '1', "full != 1!");
		checkTOS(0);
    wait until falling_edge(clk);

		simAssertion(valid = '1', "valid != 1");
		simAssertion(full = '0', "full != 0");
		checkTOS(0);
    wait until falling_edge(clk);

		-- Drain whole stack
		while valid = '1' loop
			simAssertion(full = '0', "full != 0");
			checkTOS(high);
			wait until falling_edge(clk);
			high := high - 1;
		end loop;
		simAssertion(high = -1, "Failed to drain stack.");
		got <= '0';

		simDeactivateProcess(PID);
		wait;	-- forever
	end process;

end tb;
