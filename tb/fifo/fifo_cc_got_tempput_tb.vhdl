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

library	PoC;
use			PoC.utils.all;
use			PoC.physical.all;
-- simulation only packages
use			PoC.sim_types.all;
use			PoC.simulation.all;
use			PoC.waveform.all;


entity fifo_cc_got_tempput_tb is
end entity;


architecture tb of fifo_cc_got_tempput_tb is
	constant CLOCK_FREQ			: FREQ					:= 100 MHz;

  -- component generics
  constant D_BITS         : positive := 8;
  constant MIN_DEPTH      : positive := 8;
  constant ESTATE_WR_BITS : natural  := 2;
  constant FSTATE_RD_BITS : natural  := 2;

  constant ISPEC : string := "C C Cccccpppp pppp c ccc pp         Cppppp ppp rp RpC";
  constant OSPEC : string := "ggg                      gggggggg  ggg G           G";

  -- Sequence Generator
  constant GEN : bit_vector       := "100110001";
  constant ORG : std_logic_vector :=  "00000001";

  -- Clock Control
  signal rst  : std_logic;
  signal clk  : std_logic;

begin
	-- initialize global simulation status
	simInitialize;
	-- generate global testbench clock
	simGenerateClock(clk, CLOCK_FREQ);
	simGenerateWaveform(rst,	simGenerateWaveform_Reset(Pause => 10 ns, ResetPulse => 10 ns));

  genTests: for c in 0 to 7 generate
		constant DATA_REG   : boolean :=  c mod 2 > 0;
		constant STATE_REG  : boolean :=  c mod 4 > 1;
		constant OUTPUT_REG : boolean :=  c mod 8 > 3;

		constant simTestID	: T_SIM_TEST_ID			:= simCreateTest("Test setup for DATA_REG=" & boolean'image(DATA_REG) & " STATE_REG=" & BOOLEAN'image(STATE_REG) & " OUTPUT_REG=" & boolean'image(OUTPUT_REG));

    signal put  : std_logic;
    signal putx : std_logic;
    signal di   : std_logic_vector(D_BITS-1 downto 0);
    signal ful  : std_logic;

    signal commit   : std_logic;
    signal rollback : std_logic;

    signal got  : std_logic;
    signal gotx : std_logic;
    signal do   : std_logic_vector(D_BITS-1 downto 0);
    signal dox  : std_logic_vector(D_BITS-1 downto 0);
    signal vld  : std_logic;

  begin

    putx <= put and not ful;
    geni : entity PoC.comm_scramble
      generic map (
        GEN  => GEN,
        BITS => D_BITS
      )
      port map (
        clk  => clk,
        set  => rst,
        din  => ORG,
        step => putx,
        mask => di
      );

		-- Writer
    procWriter : process
			constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess(simTestID, "Writer for DATA_REG=" & boolean'image(DATA_REG) & " STATE_REG=" & BOOLEAN'image(STATE_REG) & " OUTPUT_REG=" & boolean'image(OUTPUT_REG));
    begin
      wait until rising_edge(clk);

      for i in ISPEC'range loop
        put      <= '0';
        commit   <= '0';
        rollback <= '0';
        case ISPEC(i) is
          when ' ' =>
            wait until rising_edge(clk);

          when 'p' =>
            put    <= '1';
            wait until rising_edge(clk) and ful = '0';

          when 'c' =>
            commit <= '1';
            wait until rising_edge(clk);

          when 'C' =>
            put    <= '1';
            commit <= '1';
            wait until rising_edge(clk) and ful = '0';

          when 'r' =>
            rollback <= '1';
            wait until rising_edge(clk);

          when 'R' =>
            put      <= '1';
            rollback <= '1';
            wait until rising_edge(clk) and ful = '0';

         when others =>
            report "Illegal ISPEC." severity failure;
        end case;
      end loop;
      put    <= '0';
      commit <= '0';

      -- This process is finished
			simDeactivateProcess(simProcessID);
			wait;  -- forever
    end process;

    DUT : entity PoC.fifo_cc_got_tempput
      generic map (
        D_BITS         => D_BITS,
        MIN_DEPTH      => MIN_DEPTH,
        DATA_REG       => DATA_REG,
        STATE_REG      => STATE_REG,
        OUTPUT_REG     => OUTPUT_REG,
        ESTATE_WR_BITS => ESTATE_WR_BITS,
        FSTATE_RD_BITS => FSTATE_RD_BITS
      )
      port map (
        rst       => rst,
        clk       => clk,

        put       => put,
        din       => di,
        full      => ful,
        estate_wr => open,
        commit    => commit,
        rollback  => rollback,

        got       => got,
        dout      => do,
        valid     => vld,
        fstate_rd => open
      );

		-- Reader
		procReader : process
			constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess(simTestID, "Reader for DATA_REG=" & boolean'image(DATA_REG) & " STATE_REG=" & BOOLEAN'image(STATE_REG) & " OUTPUT_REG=" & boolean'image(OUTPUT_REG));
    begin
      for i in OSPEC'range loop
        case OSPEC(i) is
          when ' ' =>
            got <= '0';
            wait until rising_edge(clk);

          when 'g' =>
            got <= '1';
            wait until rising_edge(clk) and vld = '1';
						simAssertion((do = dox), "Test #" & integer'image(c) & ": Output Mismatch.");

          when 'G' =>
            got <= '1';
            wait until rising_edge(clk) and vld = '1';
						simAssertion((do /= dox), "Output Mismatch.");

          when others =>
            report "Illegal ISPEC." severity failure;
        end case;
      end loop;

      -- This process is finished
			simDeactivateProcess(simProcessID);
			wait;  -- forever
    end process;

    gotx <= got and vld;
    geno : entity PoC.comm_scramble
      generic map (
        GEN  => GEN,
        BITS => D_BITS
      )
      port map (
        clk  => clk,
        set  => rst,
        din  => ORG,
        step => gotx,
        mask => dox
      );

  end generate;
end architecture;
