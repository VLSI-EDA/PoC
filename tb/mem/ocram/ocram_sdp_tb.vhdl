-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- =============================================================================
-- Authors:					Martin Zabel
--
-- Testbench:				On-Chip-RAM: Simple-Dual-Port (SDP).
--
-- Description:
-- ------------------------------------
--		Automated testbench for PoC.mem.ocram.sdp
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
use			IEEE.numeric_std.all;

library PoC;
use			PoC.utils.all;
use			PoC.physical.all;
-- simulation only packages
use			PoC.sim_types.all;
use			PoC.simulation.all;
use			PoC.waveform.all;


entity ocram_sdp_tb is
end entity;

architecture tb of ocram_sdp_tb is
	constant CLOCK_FREQ							: FREQ					:= 100 MHz;

  -- component generics
  -- Set to values used for synthesis when simulating a netlist.
  constant A_BITS : positive := 10;
  constant D_BITS : positive := 32;

  -- component ports
  signal rce  : std_logic;
  signal wce  : std_logic;
  signal we   : std_logic;
  signal ra   : unsigned(A_BITS-1 downto 0);
  signal wa   : unsigned(A_BITS-1 downto 0);
  signal d    : std_logic_vector(D_BITS-1 downto 0);
  signal q    : std_logic_vector(D_BITS-1 downto 0);

  -- clock
  signal clk			: std_logic;

begin
	-- initialize global simulation status
	simInitialize;
	-- generate global testbench clock
	simGenerateClock(clk, CLOCK_FREQ);

	-- component instantiation
	UUT: entity PoC.ocram_sdp
		generic map(
			A_BITS	=> A_BITS,
			D_BITS	=> D_BITS
		)
		port map (
			rclk	=> clk,
			rce		=> rce,
			wclk	=> clk,
			wce		=> wce,
			we		=> we,
			ra		=> ra,
			wa		=> wa,
			d			=> d,
			q			=> q
		);

  -- waveform generation
  WaveGen_Proc: process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Stimuli process");
  begin
    -- insert signal assignments here
    ra  <= (others => '0');
    wa  <= (others => '0');
    rce <= '0';
    wce <= '0';
    we  <= '0';
    simWaitUntilRisingEdge(clk, 2);

    wait until falling_edge(clk);

    d   <= x"11111111";
    we  <= '1';
    wce <= '1';
    rce <= '0';
    wait until falling_edge(clk);

    we  <= '0';
    wce <= '1';
    rce <= '1';                         -- normal read after write
    wait until falling_edge(clk);
		simAssertion((q = x"11111111"), "Wrong read data1");

    d   <= x"22222222";
    we  <= '1';
    wce <= '1';
    rce <= '1';                         -- read-during-write on opposite port
    wait until falling_edge(clk);

    we  <= '0';
    wce <= '1';
    rce <= '1';                         -- read again
    wait until falling_edge(clk);
		simAssertion((q = x"22222222"), "Wrong read data1");

    d   <= x"33333333";
    we  <= '1';                         -- write new value
    wce <= '1';
    rce <= '0';                         -- no read
    wait until falling_edge(clk);
		simAssertion((q = x"22222222"), "Wrong read data1");

    we  <= '0';                         -- no write
    wce <= '1';
    rce <= '0';                         -- no read
    wait until falling_edge(clk);
		simAssertion((q = x"22222222"), "Wrong read data1");

    d   <= x"44444444";
    we  <= '1';
    wce <= '1';
    rce <= '1';                         -- read-during-write on opposite port
    wait until falling_edge(clk);

    d   <= x"55555555";
    we  <= '1';
    wce <= '0';                         -- write clock disabled
    rce <= '1';                         -- should be normal read
    wait until falling_edge(clk);
		simAssertion((q = x"44444444"), "Wrong read data1");

    we  <= '0';
    wce <= '0';
    rce <= '0';

    -- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
  end process WaveGen_Proc;
end architecture;
