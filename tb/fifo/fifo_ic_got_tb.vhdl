-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- =============================================================================
-- Authors:					Thomas B. Preusser
--
-- Testbench:				Testbench for a FIFO with independent clocks
--
-- Description:
-- ------------------------------------
--		TODO
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
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

library	IEEE;
use			IEEE.std_logic_1164.all;

library	PoC;
use			PoC.utils.all;
use			PoC.physical.all;
-- simulation only packages
use			PoC.sim_types.all;
use			PoC.simulation.all;
use			PoC.waveform.all;


entity fifo_ic_got_tb is
end entity;


architecture tb of fifo_ic_got_tb is
	constant CLOCK_FREQ			: FREQ					:= 100 MHz;

  -- FIFO Parameters
  constant D_BITS         : positive := 9;
  constant MIN_DEPTH      : positive := 8;
  constant OUTPUT_REG     : boolean  := true;
  constant ESTATE_WR_BITS : natural  := 2;
  constant FSTATE_RD_BITS : natural  := 2;

  -- Sequence Generator
  constant GEN : bit_vector       := "100110001";
  constant ORG : std_logic_vector :=  "00000001";

  -- Clock Generation and Reset
  signal rst  : std_logic;
  signal clk0 : std_logic;
  signal clk1 : std_logic;
  signal clk2 : std_logic;
  signal done : std_logic := '0';

  -- clk0 -> clk1 Transfer
  signal di0  : std_logic_vector(D_BITS-1 downto 0);
  signal put0 : std_logic;
  signal ful0 : std_logic;

  signal do1  : std_logic_vector(D_BITS-1 downto 0);
  signal vld1 : std_logic;
  signal got1 : std_logic;

  -- clk1 -> clk2 Transfer
  signal di1  : std_logic_vector(D_BITS-1 downto 0);
  signal put1 : std_logic;
  signal ful1 : std_logic;

  signal do2  : std_logic_vector(D_BITS-1 downto 0);
  signal vld2 : std_logic;
  signal got2 : std_logic;

  signal dat2 : std_logic_vector(D_BITS-1 downto 0);

begin
	-- initialize global simulation status
	simInitialize;
	-- generate global testbench clock
	simGenerateClock(clk0, 14 ns);
	simGenerateClock(clk1, 24 ns);
	simGenerateClock(clk2, 10 ns);
	simGenerateWaveform(rst,	simGenerateWaveform_Reset(Pause => 0 ns, ResetPulse => 30 ns));

  -----------------------------------------------------------------------------
  -- Initial Generator
  gen0 : entity PoC.comm_scramble
    generic map (
      GEN  => GEN,
      BITS => D_BITS
    )
    port map (
      clk  => clk0,
      set  => rst,
      din  => ORG,
      step => put0,
      mask => di0
    );

  -- Writer
	procWriter : process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Writer");

    variable cnt : natural := 0;
  begin
    put0 <= '0';
    wait until rst = '0' and rising_edge(clk0);

    -- Slow Input Phase
    while cnt < 2*MIN_DEPTH loop
      wait until falling_edge(clk0);
      if ful0 = '0' and vld1 = '0' then
        put0 <= '1';
        cnt := cnt + 1;
      else
        put0 <= '0';
      end if;
    end loop;

    -- Fast Input Phase
    while cnt < 4*MIN_DEPTH loop
      wait until falling_edge(clk0);
      if ful0 = '0' then
        put0 <= '1';
        cnt := cnt + 1;
      else
        put0 <= '0';
      end if;
    end loop;

    -- Let it drain
    wait until falling_edge(clk0);
    put0 <= '0';

    -- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
  end process;

  fifo0_1 : entity PoC.fifo_ic_got
    generic map (
      D_BITS         => D_BITS,
      MIN_DEPTH      => MIN_DEPTH,
      OUTPUT_REG     => OUTPUT_REG,
      ESTATE_WR_BITS => ESTATE_WR_BITS,
      FSTATE_RD_BITS => FSTATE_RD_BITS
    )
    port map (
      clk_wr    => clk0,
      rst_wr    => rst,
      put       => put0,
      din       => di0,
      full      => ful0,
      estate_wr => open,

      clk_rd    => clk1,
      rst_rd    => rst,
      got       => got1,
      valid     => vld1,
      dout      => do1,
      fstate_rd => open
    );

  -----------------------------------------------------------------------------
  -- Intermediate Checker
  gen1 : entity PoC.comm_scramble
    generic map (
      GEN  => GEN,
      BITS => D_BITS
    )
    port map (
      clk  => clk1,
      set  => rst,
      din  => ORG,
      step => put1,
      mask => di1
    );
  got1 <= vld1 and not ful1;
  put1 <= got1;

	-- Pass-thru checker
	procChecker : process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Pass-thru checker");

    variable cnt : natural := 0;
  begin
    -- Pass-thru Checking
		while cnt < 4*MIN_DEPTH loop
			wait until rising_edge(clk1);
			simAssertion(((rst = '1') or (put1 = '0') or (do1 = di1)), "Mismatch in clk1.");
			if put1 = '1' then
				cnt := cnt + 1;
			end if;
		end loop;

    -- This process is finished
		simDeactivateProcess(simProcessID);
		wait;
  end process;

  fifo1_2 : entity PoC.fifo_ic_got
    generic map (
      DATA_REG       => true,
      D_BITS         => D_BITS,
      MIN_DEPTH      => MIN_DEPTH,
      ESTATE_WR_BITS => ESTATE_WR_BITS,
      FSTATE_RD_BITS => FSTATE_RD_BITS
    )
    port map (
      clk_wr    => clk1,
      rst_wr    => rst,
      put       => put1,
      din       => di1,
      full      => ful1,
      estate_wr => open,

      clk_rd    => clk2,
      rst_rd    => rst,
      got       => got2,
      valid     => vld2,
      dout      => do2,
      fstate_rd => open
    );

  -----------------------------------------------------------------------------
  -- Final Checker
  gen2 : entity PoC.comm_scramble
    generic map (
      GEN  => GEN,
      BITS => D_BITS
    )
    port map (
      clk  => clk2,
      set  => rst,
      din  => ORG,
      step => got2,
      mask => dat2
    );

	-- Reader
	procReader : process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Reader");

    variable cnt : natural := 0;
    variable del : natural := 0;
  begin
    -- Final Checking
		while cnt < 4*MIN_DEPTH loop
			wait until rising_edge(clk2);
			got2 <= '0';
			if vld2 = '1' then
				del := del + 1;
				if del = 3 then
					got2 <= '1';
					simAssertion((dat2 = do2), "Mismatch in clk2.");
					cnt := cnt + 1;
					del := 0;
				end if;
			end if;
		end loop;

		-- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
  end process;

end architecture;
