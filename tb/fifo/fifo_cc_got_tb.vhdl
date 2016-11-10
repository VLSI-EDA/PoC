-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- ============================================================================
-- Authors:					Thomas B. Preusser
--
-- Testbench:				Testbench for a FIFO with Common Clock (cc) and Pipelined Interface
--
-- Description:
-- ------------------------------------
--		TODO
--
--
-- License:
-- ============================================================================
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
-- ============================================================================

library	IEEE;
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;

library	PoC;
use			PoC.utils.all;
use			PoC.physical.all;
-- simulation only packages
use			PoC.sim_types.all;
use			PoC.simulation.all;
use			PoC.waveform.all;


entity fifo_cc_got_tb is
end entity;


architecture tb of fifo_cc_got_tb is
	constant CLOCK_FREQ			: FREQ					:= 100 MHz;

  -- component generics
  constant D_BITS         : positive := 8;
  constant MIN_DEPTH      : positive := 30;
  constant ESTATE_WR_BITS : natural  := 2;
  constant FSTATE_RD_BITS : natural  := 2;

  -- Clock Control
  signal rst  : std_logic;
  signal clk  : std_logic;

begin
	-- initialize global simulation status
	simInitialize;
	-- generate global testbench clock
	simGenerateClock(clk,		CLOCK_FREQ);
	simGenerateWaveform(rst,	simGenerateWaveform_Reset(Pause => 10 ns, ResetPulse => 10 ns));

  genDUTs: for c in 0 to 7 generate
		constant DATA_REG   : boolean :=  c mod 2 > 0;
		constant STATE_REG  : boolean :=  c mod 4 > 1;
		constant OUTPUT_REG : boolean :=  c mod 8 > 3;

		constant simTestID	: T_SIM_TEST_ID			:= simCreateTest("Test setup for DATA_REG=" & boolean'image(DATA_REG) & " STATE_REG=" & BOOLEAN'image(STATE_REG) & " OUTPUT_REG=" & boolean'image(OUTPUT_REG));

    -- Local Component Ports
    signal put				: std_logic;
    signal din				: std_logic_vector(D_BITS-1 downto 0);
    signal full				: std_logic;
		signal estate_wr	: std_logic_vector(ESTATE_WR_BITS - 1 downto 0);
    signal got				: std_logic;
    signal dout				: std_logic_vector(D_BITS-1 downto 0);
    signal valid			: std_logic;
		signal fstate_rd	: std_logic_vector(FSTATE_RD_BITS - 1 downto 0);

  begin

    DUT : entity PoC.fifo_cc_got
      generic map (
        D_BITS         => D_BITS,
        MIN_DEPTH      => MIN_DEPTH,
        STATE_REG      => STATE_REG,
        DATA_REG       => DATA_REG,
        OUTPUT_REG     => OUTPUT_REG,
        ESTATE_WR_BITS => ESTATE_WR_BITS,
        FSTATE_RD_BITS => FSTATE_RD_BITS
      )
      port map (
        rst       => rst,
        clk       => clk,
        put       => put,
        din       => din,
        full      => full,
        estate_wr => estate_wr,
        got       => got,
        dout      => dout,
        valid     => valid,
        fstate_rd => fstate_rd
      );

    -- Writer
    procWriter : process
			constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess(simTestID, "Writer for DATA_REG=" & boolean'image(DATA_REG) & " STATE_REG=" & BOOLEAN'image(STATE_REG) & " OUTPUT_REG=" & boolean'image(OUTPUT_REG));
    begin
      din <= (others => '-');
      put <= '0';
      wait until rising_edge(clk) and rst = '0';

      for i in 0 to 2**(D_BITS-1)-1 loop
        din <= std_logic_vector(to_unsigned(i, D_BITS));
        put <= '1';
        wait until rising_edge(clk) and full = '0';
      end loop;

      for i in 2**(D_BITS-1) to 2**D_BITS-1 loop
        din <= (others => '-');
        put <= '0';
        wait until rising_edge(clk) and valid = '0';
        din <= std_logic_vector(to_unsigned(i, D_BITS));
        put <= '1';
        wait until rising_edge(clk);
      end loop;

      din <= (others => '-');
      put <= '0';

      -- This process is finished
			simDeactivateProcess(simProcessID);
			wait;  -- forever
    end process;

    -- Reader
		procReader : process
			constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess(simTestID, "Reader for DATA_REG=" & boolean'image(DATA_REG) & " STATE_REG=" & BOOLEAN'image(STATE_REG) & " OUTPUT_REG=" & boolean'image(OUTPUT_REG));
    begin
      got <= '0';
      for i in 0 to 2**D_BITS-1 loop
        wait until rising_edge(clk) and valid = '1';
				simAssertion((dout = std_logic_vector(to_unsigned(i, D_BITS))), "Output failure in configuration " & integer'image(c) & " @ Pos " & INTEGER'image(i));
        got <= '1';
        wait until rising_edge(clk);
        got <= '0';
        wait until rising_edge(clk);
      end loop;

      -- This process is finished
			simDeactivateProcess(simProcessID);
			simFinalizeTest(simTestID);
			wait;  -- forever
    end process;
  end generate genDUTs;
end architecture;
