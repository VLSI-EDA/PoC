-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- =============================================================================
-- Authors:					Martin Zabel
--
-- Testbench:				On-Chip-RAM: Simple-Dual-Port (SDP) with write-first.
--
-- Description:
-- ------------------------------------
--		Automated testbench for PoC.mem.ocram.sdp_wf
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
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


entity ocram_sdp_wf_tb is
end entity;

architecture tb of ocram_sdp_wf_tb is
	constant CLOCK_FREQ							: FREQ					:= 100 MHz;

  -- component generics
  -- Set to values used for synthesis when simulating a netlist.
  constant A_BITS : positive := 8;
  constant D_BITS : positive := 16;

	-- component ports
	signal clk : std_logic;
	signal ce  : std_logic;
	signal we1 : std_logic;
	signal a1  : unsigned(A_BITS-1 downto 0);
	signal a2  : unsigned(A_BITS-1 downto 0);
	signal d1  : std_logic_vector(D_BITS-1 downto 0);
	signal q2  : std_logic_vector(D_BITS-1 downto 0);

	-- Expected read data, assign together with read command
	-- Set to '-'es when result doesn't care.
	-- Set to 'X'es when expecting unknown result due to mixed-port collision.
	signal rd_d2  : std_logic_vector(D_BITS-1 downto 0);

	-- Derived expected output on q2.
	signal exp_q2 : std_logic_vector(D_BITS-1 downto 0) := (others => '-');

	-- Signaling between Stimuli and Checker process
	signal finished1 : boolean := false;
	signal finished2 : boolean := false;
begin
	-- initialize global simulation status
	simInitialize;

	-- generate global testbench clock
	simGenerateClock(clk, CLOCK_FREQ);

	-- component instantiation
	UUT: entity poc.ocram_sdp_wf
		generic map (
			A_BITS	 => A_BITS,
			D_BITS	 => D_BITS,
			FILENAME => "")
		port map (
			clk => clk,
			ce  => ce,
			we  => we1,
			wa  => a1,
			ra  => a2,
			d   => d1,
			q   => q2);

	-- NOTE: Clock enable is controlled by Stimuli1. It must be '1' for all
	-- test pattern which do not read and write at the same time.

	-- Input stimuli for Port 1 (Write)
	-- ===========================================================================
	Stimuli1: process
		constant simProcessID : T_SIM_PROCESS_ID := simRegisterProcess("Stimuli1");
	begin
		-- No operation on first rising clock edge
		ce    <= '0';
		we1   <= '-';
		a1    <= (others => '-');
		d1    <= (others => '-');

		-- Write in 8 consecutive clock cycles on port 1, read one cycle later on
		-- port 2
		-------------------------------------------------------------------------
		for i in 0 to 7 loop
			simWaitUntilRisingEdge(clk, 1);
			ce    <= '1';
			we1		<= '1';
			a1		<= to_unsigned(i, A_BITS);
			d1		<= std_logic_vector(to_unsigned(i, D_BITS));
		end loop;

		simWaitUntilRisingEdge(clk, 1);
		-- last read on port 2 here
		ce    <= '1';
		we1		<= '0';
		a1		<= (others => '-');
		d1    <= (others => '-');

		-- Alternating write on port 1 / read on port 2
		-------------------------------------------------------------------------
		for i in 8 to 15 loop
			simWaitUntilRisingEdge(clk, 1);
			ce    <= '1';
			we1		<= not we1;
			a1		<= to_unsigned(i, A_BITS);
			d1		<= std_logic_vector(to_unsigned(i, D_BITS));
		end loop;

		simWaitUntilRisingEdge(clk, 1);
		-- last read on port 2 here
		ce    <= '1';
		we1		<= '0';
		a1		<= (others => '-');
		d1    <= (others => '-');

		-- Read in 8 consecutive clock cycles on port 2, write one cycle later on
		-- port 1
		-------------------------------------------------------------------------
		simWaitUntilRisingEdge(clk, 1);
		-- first read on port 2 here
		ce    <= '1';
		we1		<= '0';
		a1		<= (others => '-');
		d1    <= (others => '-');

		for i in 16 to 23 loop
			simWaitUntilRisingEdge(clk, 1);
			ce    <= '1';
			we1		<= '1';
			a1		<= to_unsigned(i, A_BITS);
			d1		<= std_logic_vector(to_unsigned(i, D_BITS));
		end loop;

		-- Read and write in 8 consecutive clock cycles at the same address
		-------------------------------------------------------------------------
		for i in 64 to 71 loop
			simWaitUntilRisingEdge(clk, 1);
			ce    <= '1';
			we1		<= '1';
			a1		<= to_unsigned(i, A_BITS);
			d1		<= std_logic_vector(to_unsigned(i, D_BITS));
		end loop;

		-- Read and write 8 times at the same address every second clock cycle
		-------------------------------------------------------------------------
		for i in 72 to 87 loop
			simWaitUntilRisingEdge(clk, 1);
			ce    <= not ce;
			we1		<= '1';
			a1		<= to_unsigned(i, A_BITS);
			d1		<= std_logic_vector(to_unsigned(i, D_BITS));
		end loop;

		-------------------------------------------------------------------------
		-- Finish
		simWaitUntilRisingEdge(clk, 1);
		ce    <= '0';
		we1   <= '-';
		a1		<= (others => '-');
		d1    <= (others => '-');

		-- This process is finished
		finished1 <= true;
		simDeactivateProcess(simProcessID);
		wait;  -- forever
	end process Stimuli1;

	-- Input stimuli for Port 2 (Read)
	-- ===========================================================================
	Stimuli2: process
		constant simProcessID : T_SIM_PROCESS_ID := simRegisterProcess("Stimuli2");
		variable re2 : boolean;
	begin
		-- No operation on first rising clock edge
		a2    <= (others => '-');
		rd_d2 <= (others => '-');

		-- Write in 8 consecutive clock cycles on port 1, read one cycle later on
		-- port 2
		-------------------------------------------------------------------------
		simWaitUntilRisingEdge(clk, 1);
		-- first write on port 1 here
		a2		<= (others => '-');
		rd_d2 <= (others => '-');

		for i in 0 to 7 loop
			simWaitUntilRisingEdge(clk, 1);
			a2		<= to_unsigned(i, A_BITS);
			rd_d2 <= std_logic_vector(to_unsigned(i, D_BITS));
		end loop;

		-- Alternating write on port 1 / read on port 2
		-------------------------------------------------------------------------
		simWaitUntilRisingEdge(clk, 1);
		-- first write on port 1 here
		re2   := false;
		a2		<= (others => '-');
		rd_d2 <= (others => '-');

		for i in 8 to 15 loop
			simWaitUntilRisingEdge(clk, 1);
			re2   := not re2; -- only compare read result every second cycle
			a2		<= to_unsigned(i, A_BITS);
			if re2 then
				rd_d2 <= std_logic_vector(to_unsigned(i, D_BITS));
			else
				rd_d2 <= (others => '-');
			end if;
		end loop;

		-- Read in 8 consecutive clock cycles on port 2, write one cycle later on
		-- port 1
		-------------------------------------------------------------------------
		for i in 16 to 23 loop
			simWaitUntilRisingEdge(clk, 1);
			a2		<= to_unsigned(i, A_BITS);
			rd_d2 <= (others => 'U'); -- memory not yet initialized
		end loop;

		simWaitUntilRisingEdge(clk, 1);
		-- last write on port 1 here
		a2		<= (others => '-');
		rd_d2 <= (others => '-');

		-- Read and write in 8 consecutive clock cycles at the same address
		-------------------------------------------------------------------------
		for i in 64 to 71 loop
			simWaitUntilRisingEdge(clk, 1);
			a2		<= to_unsigned(i, A_BITS);
			rd_d2	<= std_logic_vector(to_unsigned(i, D_BITS));
		end loop;

		-- Read and write 8 times at the same address every second clock cycle
		-------------------------------------------------------------------------
		for i in 72 to 87 loop
			simWaitUntilRisingEdge(clk, 1);
			a2		<= to_unsigned(i, A_BITS);
			rd_d2	<= std_logic_vector(to_unsigned(i, D_BITS));
		end loop;

		-------------------------------------------------------------------------
		-- Finish
		simWaitUntilRisingEdge(clk, 1);
		a2		<= (others => '-');
		rd_d2 <= (others => '-');

		-- This process is finished
		finished2 <= true;
		simDeactivateProcess(simProcessID);
		wait;  -- forever
	end process Stimuli2;

	-- Checker
	-- ===========================================================================

	-- Also checks if old value is kept if ce  = '0'
	exp_q2 <= rd_d2 when rising_edge(clk) and ce = '1';

	Checker2: process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Checker2");
		variable i : integer;
	begin
		while not finished2 loop
			simWaitUntilRisingEdge(clk, 1);
			simAssertion((q2 = exp_q2) or -- also matches 'X'es
									 std_match(q2, exp_q2)); -- also matches '-'es
		end loop;

		-- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
	end process Checker2;

end architecture;
