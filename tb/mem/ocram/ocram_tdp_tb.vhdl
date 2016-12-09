-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- =============================================================================
-- Authors:					Martin Zabel
--
-- Testbench:				On-Chip-RAM: True Dual-Port (TDP).
--
-- Description:
-- ------------------------------------
--		Automated testbench for PoC.mem.ocram.tdp
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


entity ocram_tdp_tb is
end entity;

architecture tb of ocram_tdp_tb is
	constant CLOCK_FREQ							: FREQ					:= 100 MHz;

  -- component generics
  -- Set to values used for synthesis when simulating a netlist.
  constant A_BITS : positive := 8;
  constant D_BITS : positive := 16;

	-- test configurations
  type T_TEST_CONFIG is record
    phase1 : T_PHASE; -- phase of clk1
    phase2 : T_PHASE; -- phase of clk2
  end record;

	type T_TEST_CONFIG_VEC is array (natural range<>) of T_TEST_CONFIG;

	-- phase = 0 means 360 degrees
	constant TEST_CONFIGS : T_TEST_CONFIG_VEC := (
		0 => (phase1 =>  180 deg, phase2 => 180 deg), -- clocks in-phase (including delta cyle)
		1 => (phase1 =>  180 deg, phase2 =>  90 deg), -- provoke mixed-port read-during-write
		2 => (phase1 =>  90 deg, phase2 => 180 deg)   -- dito
	);
begin
	-- initialize global simulation status
	simInitialize;

	gTest: for test in TEST_CONFIGS'range generate
		constant CLOCK1_PHASE : T_PHASE := TEST_CONFIGS(test).phase1;
		constant CLOCK2_PHASE : T_PHASE := TEST_CONFIGS(test).phase2;

		constant simTestID : T_SIM_TEST_ID := simCreateTest("Phase1="&integer'image(CLOCK1_PHASE / 1 deg)&
																												" Phase2="&integer'image(CLOCK2_PHASE / 1 deg));

		-- component ports
		signal clk1			: std_logic;
		signal clk2			: std_logic;
		signal ce1	: std_logic;
		signal ce2	: std_logic;
		signal we1	: std_logic;
		signal we2	: std_logic;
		signal a1		: unsigned(A_BITS-1 downto 0);
		signal a2		: unsigned(A_BITS-1 downto 0);
		signal d1		: std_logic_vector(D_BITS-1 downto 0);
		signal d2		: std_logic_vector(D_BITS-1 downto 0);
		signal q1		: std_logic_vector(D_BITS-1 downto 0);
		signal q2		: std_logic_vector(D_BITS-1 downto 0);

		-- Expected read data, assign together with read command
		-- Set to '-'es when result doesn't care.
		-- Set to 'X'es when expecting unknown result due to mixed-port collision.
		signal rd_d1  : std_logic_vector(D_BITS-1 downto 0);
		signal rd_d2  : std_logic_vector(D_BITS-1 downto 0);

		-- Derived expected output on q1 / q2.
		signal exp_q1 : std_logic_vector(D_BITS-1 downto 0) := (others => '-');
		signal exp_q2 : std_logic_vector(D_BITS-1 downto 0) := (others => '-');

		-- Signaling between Stimuli and Checker process
		signal finished1 : boolean := false;
		signal finished2 : boolean := false;

	begin
		-- generate global testbench clock
		simGenerateClock(simTestID, clk1, CLOCK_FREQ, CLOCK1_PHASE);
		simGenerateClock(simTestID, clk2, CLOCK_FREQ, CLOCK2_PHASE);

		-- component instantiation
		UUT: entity poc.ocram_tdp
			generic map (
				A_BITS	 => A_BITS,
				D_BITS	 => D_BITS,
				FILENAME => "")
			port map (
				clk1 => clk1,
				clk2 => clk2,
				ce1	 => ce1,
				ce2	 => ce2,
				we1	 => we1,
				we2	 => we2,
				a1	 => a1,
				a2	 => a2,
				d1	 => d1,
				d2	 => d2,
				q1	 => q1,
				q2	 => q2);

		-- Input stimuli for Port 1
		-- ===========================================================================
		Stimuli1: process
			constant simProcessID : T_SIM_PROCESS_ID := simRegisterProcess(simTestID, "TestID "&integer'image(simTestID)&", Stimuli1");
		begin
			-- No operation on first rising clock edge
			ce1   <= '0';
			we1   <= '-';
			a1    <= (others => '-');
			d1    <= (others => '-');
			rd_d1 <= (others => '-');

			-- Write in 8 consecutive clock cycles on port 1, read one cycle later on
			-- port 2
			-------------------------------------------------------------------------
			for i in 0 to 7 loop
				simWaitUntilRisingEdge(clk1, 1);
				ce1		<= '1';
				we1		<= '1';
				a1		<= to_unsigned(i, A_BITS);
				d1		<= std_logic_vector(to_unsigned(i, D_BITS));
				rd_d1 <= std_logic_vector(to_unsigned(i, D_BITS));
			end loop;

			simWaitUntilRisingEdge(clk1, 1);
			-- last read on port 2 here
			ce1		<= '0';
			we1		<= '0';
			a1		<= (others => '-');
			d1    <= (others => '-');
			rd_d1 <= (others => '-');

			-- Alternating write on port 1 / read on port 2
			-------------------------------------------------------------------------
			for i in 8 to 15 loop
				simWaitUntilRisingEdge(clk1, 1);
				ce1		<= not ce1;									-- write @ even addresses
				we1		<= '1';
				a1		<= to_unsigned(i, A_BITS);
				d1		<= std_logic_vector(to_unsigned(i, D_BITS));
				rd_d1 <= std_logic_vector(to_unsigned(i, D_BITS));
			end loop;

			simWaitUntilRisingEdge(clk1, 1);
			-- last read on port 2 here
			ce1		<= '0';
			we1		<= '0';
			a1		<= (others => '-');
			d1    <= (others => '-');
			rd_d1 <= (others => '-');

			-- Write in 8 consecutive clock cycles on port 2, read one cycle later on
			-- port 1
			-------------------------------------------------------------------------
			simWaitUntilRisingEdge(clk1, 1);
			-- first write on port 2 here
			ce1		<= '0';
			we1   <= '-';
			a1		<= (others => '-');
			d1    <= (others => '-');
			rd_d1 <= (others => '-');

			for i in 16 to 23 loop
				simWaitUntilRisingEdge(clk1, 1);
				ce1		<= '1';
				we1   <= '0';
				a1		<= to_unsigned(i, A_BITS);
				d1    <= (others => '-');
				if CLOCK1_PHASE >= CLOCK2_PHASE then
					-- read succeeds either if clocks are in phase or read clock is
					-- behind write clock
					rd_d1 <= std_logic_vector(to_unsigned(i, D_BITS));
				else
					-- read-during-write at same address
					rd_d1 <= (others => 'X');
				end if;
			end loop;

			-- Alternating write on port 2 / read on port 1
			-------------------------------------------------------------------------
			simWaitUntilRisingEdge(clk1, 1);
			-- first write on port 2 here
			ce1		<= '0';
			we1   <= '-';
			a1		<= (others => '-');
			d1    <= (others => '-');
			rd_d1 <= (others => '-');

			for i in 24 to 31 loop
				simWaitUntilRisingEdge(clk1, 1);
				ce1		<= not ce1;
				we1   <= '0';
				a1		<= to_unsigned(i, A_BITS);
				d1    <= (others => '-');
				if CLOCK1_PHASE >= CLOCK2_PHASE then
					-- read succeeds either if clocks are in phase or read clock is
					-- behind write clock
					rd_d1 <= std_logic_vector(to_unsigned(i, D_BITS));
				else
					-- read-during-write at same address
					rd_d1 <= (others => 'X');
				end if;
			end loop;

			-------------------------------------------------------------------------
			-- Alternate between write on port 1 and write on port 2 to the same
			-- address. Data is read again from memory after all writes.
			for i in 32 to 39 loop
				simWaitUntilRisingEdge(clk1, 1);
				ce1		<= '1';
				we1		<= '1';
				a1		<= to_unsigned(i, A_BITS);
				d1		<= std_logic_vector(to_unsigned(i, D_BITS));
				rd_d1 <= std_logic_vector(to_unsigned(i, D_BITS));

				simWaitUntilRisingEdge(clk1, 1);
				-- write on port 2
				ce1		<= '0';
				we1   <= '-';
				a1		<= (others => '-');
				d1    <= (others => '-');
				rd_d1 <= (others => '-');
			end loop;

			for i in 32 to 39 loop
				simWaitUntilRisingEdge(clk1, 1);
				ce1		<= '1';
				we1		<= '0';
				a1		<= to_unsigned(i, A_BITS);
				d1		<= std_logic_vector(to_unsigned(i, D_BITS));
				if CLOCK2_PHASE >= CLOCK1_PHASE then
					-- write succeeds either if clocks are in phase or if clock of second
					-- write is behind clock of first write
					rd_d1 <= std_logic_vector(to_unsigned(i, D_BITS));
				else
					-- write-during-write at same address
					rd_d1 <= (others => 'X');
				end if;
			end loop;

			-------------------------------------------------------------------------
			-- Alternate between write on port 2 and write on port 1 to the same
			-- address. Data is read again from memory after all writes.
			for i in 40 to 47 loop
				simWaitUntilRisingEdge(clk1, 1);
				-- write on port 2
				ce1		<= '0';
				we1   <= '-';
				a1		<= (others => '-');
				d1    <= (others => '-');
				rd_d1 <= (others => '-');

				simWaitUntilRisingEdge(clk1, 1);
				ce1		<= '1';
				we1		<= '1';
				a1		<= to_unsigned(i, A_BITS);
				d1		<= std_logic_vector(to_unsigned(i, D_BITS));
				rd_d1 <= std_logic_vector(to_unsigned(i, D_BITS));
			end loop;

			for i in 40 to 47 loop
				simWaitUntilRisingEdge(clk1, 1);
				ce1		<= '1';
				we1		<= '0';
				a1		<= to_unsigned(i, A_BITS);
				d1		<= std_logic_vector(to_unsigned(i, D_BITS));
				if CLOCK1_PHASE >= CLOCK2_PHASE then
					-- write succeeds either if clocks are in phase or if clock of second
					-- write is behind clock of first write
					rd_d1 <= std_logic_vector(to_unsigned(i, D_BITS));
				else
					-- write-during-write at same address
					rd_d1 <= (others => 'X');
				end if;
			end loop;

			-- Read in 8 consecutive clock cycles on port 1, write one cycle later on
			-- port 2
			-------------------------------------------------------------------------
			for i in 48 to 55 loop
				simWaitUntilRisingEdge(clk1, 1);
				ce1		<= '1';
				we1		<= '0';
				a1		<= to_unsigned(i, A_BITS);
				d1		<= (others => '-');
				if CLOCK1_PHASE <= CLOCK2_PHASE then
					-- read succeeds if clocks are in phase or if read clock is before
					-- write clock
					rd_d1 <= (others => 'U'); -- memory not yet initialized
				else
					-- write-during-read at same address
					rd_d1 <= (others => 'X');
				end if;
			end loop;

			simWaitUntilRisingEdge(clk1, 1);
			-- last write on port 2 here
			ce1		<= '0';
			we1		<= '0';
			a1		<= (others => '-');
			d1    <= (others => '-');
			rd_d1 <= (others => '-');

			-- Read in 8 consecutive clock cycles on port 2, write one cycle later on
			-- port 1
			-------------------------------------------------------------------------
			simWaitUntilRisingEdge(clk1, 1);
			-- first read on port 2 here
			ce1		<= '0';
			we1		<= '0';
			a1		<= (others => '-');
			d1    <= (others => '-');
			rd_d1 <= (others => '-');

			for i in 56 to 63 loop
				simWaitUntilRisingEdge(clk1, 1);
				ce1		<= '1';
				we1		<= '1';
				a1		<= to_unsigned(i, A_BITS);
				d1		<= std_logic_vector(to_unsigned(i, D_BITS));
				rd_d1 <= std_logic_vector(to_unsigned(i, D_BITS));
			end loop;

			-------------------------------------------------------------------------
			-- Finish
			simWaitUntilRisingEdge(clk1, 1);
			ce1		<= '0';
			we1   <= '-';
			a1		<= (others => '-');
			d1    <= (others => '-');
			rd_d1 <= (others => '-');

			-- This process is finished
			finished1 <= true;
			simDeactivateProcess(simProcessID);
			wait;  -- forever
		end process Stimuli1;

		-- Input stimuli for Port 2
		-- ===========================================================================
		Stimuli2: process
			constant simProcessID : T_SIM_PROCESS_ID := simRegisterProcess(simTestID, "TestID "&integer'image(simTestID)&", Stimuli2");
		begin
			-- No operation on first rising clock edge
			ce2   <= '0';
			we2   <= '-';
			a2    <= (others => '-');
			d2    <= (others => '-');
			rd_d2 <= (others => '-');

			-- Write in 8 consecutive clock cycles on port 1, read one cycle later on
			-- port 2
			-------------------------------------------------------------------------
			simWaitUntilRisingEdge(clk2, 1);
			-- first write on port 1 here
			ce2		<= '0';
			we2   <= '-';
			a2		<= (others => '-');
			d2    <= (others => '-');
			rd_d2 <= (others => '-');

			for i in 0 to 7 loop
				simWaitUntilRisingEdge(clk2, 1);
				ce2		<= '1';
				we2   <= '0';
				a2		<= to_unsigned(i, A_BITS);
				d2    <= (others => '-');
				if CLOCK2_PHASE >= CLOCK1_PHASE then
					-- read succeeds either if clocks are in phase or read clock is
					-- behind write clock
					rd_d2 <= std_logic_vector(to_unsigned(i, D_BITS));
				else
					-- read-during-write at same address
					rd_d2 <= (others => 'X');
				end if;
			end loop;

			-- Alternating write on port 1 / read on port 2
			-------------------------------------------------------------------------
			simWaitUntilRisingEdge(clk2, 1);
			-- first write on port 1 here
			ce2		<= '0';
			we2   <= '-';
			a2		<= (others => '-');
			d2    <= (others => '-');
			rd_d2 <= (others => '-');

			for i in 8 to 15 loop
				simWaitUntilRisingEdge(clk2, 1);
				ce2		<= not ce2;
				we2   <= '0';
				a2		<= to_unsigned(i, A_BITS);
				d2    <= (others => '-');
				if CLOCK2_PHASE >= CLOCK1_PHASE then
					-- read succeeds either if clocks are in phase or read clock is
					-- behind write clock
					rd_d2 <= std_logic_vector(to_unsigned(i, D_BITS));
				else
					-- read-during-write at same address
					rd_d2 <= (others => 'X');
				end if;
			end loop;

			-- Write in 8 consecutive clock cycles on port 2, read one cycle later on
			-- port 1
			-------------------------------------------------------------------------
			for i in 16 to 23 loop
				simWaitUntilRisingEdge(clk2, 1);
				ce2		<= '1';
				we2		<= '1';
				a2		<= to_unsigned(i, A_BITS);
				d2		<= std_logic_vector(to_unsigned(i, D_BITS));
				rd_d2 <= std_logic_vector(to_unsigned(i, D_BITS));
			end loop;

			simWaitUntilRisingEdge(clk2, 1);
			-- last read on port 1 here
			ce2		<= '0';
			we2		<= '0';
			a2		<= (others => '-');
			d2    <= (others => '-');
			rd_d2 <= (others => '-');

			-------------------------------------------------------------------------
			-- Alternating write on port 2 / read on port 1
			for i in 24 to 31 loop
				simWaitUntilRisingEdge(clk2, 1);
				ce2		<= not ce2;									-- write @ even addresses
				we2		<= '1';
				a2		<= to_unsigned(i, A_BITS);
				d2		<= std_logic_vector(to_unsigned(i, D_BITS));
				rd_d2 <= std_logic_vector(to_unsigned(i, D_BITS));
			end loop;

			simWaitUntilRisingEdge(clk2, 1);
			-- last read on port 1 here
			ce2		<= '0';
			we2		<= '0';
			a2		<= (others => '-');
			d2    <= (others => '-');
			rd_d2 <= (others => '-');

			-------------------------------------------------------------------------
			-- Alternate between write on port 1 and write on port 2 to the same
			-- address. Data is read again from memory after all writes.
			for i in 32 to 39 loop
				simWaitUntilRisingEdge(clk2, 1);
				-- write on port 1
				ce2		<= '0';
				we2   <= '-';
				a2		<= (others => '-');
				d2    <= (others => '-');
				rd_d2 <= (others => '-');

				simWaitUntilRisingEdge(clk2, 1);
				ce2		<= '1';
				we2		<= '1';
				a2		<= to_unsigned(i, A_BITS);
				d2		<= std_logic_vector(to_unsigned(i, D_BITS));
				rd_d2 <= std_logic_vector(to_unsigned(i, D_BITS));
			end loop;

			for i in 32 to 39 loop
				simWaitUntilRisingEdge(clk2, 1);
				ce2		<= '1';
				we2		<= '0';
				a2		<= to_unsigned(i, A_BITS);
				d2		<= std_logic_vector(to_unsigned(i, D_BITS));
				if CLOCK2_PHASE >= CLOCK1_PHASE then
					-- write succeeds either if clocks are in phase or if clock of second
					-- write is behind clock of first write
					rd_d2 <= std_logic_vector(to_unsigned(i, D_BITS));
				else
					-- write-during-write at same address
					rd_d2 <= (others => 'X');
				end if;
			end loop;

			-------------------------------------------------------------------------
			-- Alternate between write on port 2 and write on port 1 to the same
			-- address. Data is read again from memory after all writes.
			for i in 40 to 47 loop
				simWaitUntilRisingEdge(clk2, 1);
				ce2		<= '1';
				we2		<= '1';
				a2		<= to_unsigned(i, A_BITS);
				d2		<= std_logic_vector(to_unsigned(i, D_BITS));
				rd_d2 <= std_logic_vector(to_unsigned(i, D_BITS));

				simWaitUntilRisingEdge(clk2, 1);
				-- write on port 1
				ce2		<= '0';
				we2   <= '-';
				a2		<= (others => '-');
				d2    <= (others => '-');
				rd_d2 <= (others => '-');
			end loop;

			for i in 40 to 47 loop
				simWaitUntilRisingEdge(clk2, 1);
				ce2		<= '1';
				we2		<= '0';
				a2		<= to_unsigned(i, A_BITS);
				d2		<= std_logic_vector(to_unsigned(i, D_BITS));
				if CLOCK1_PHASE >= CLOCK2_PHASE then
					-- write succeeds either if clocks are in phase or if clock of second
					-- write is behind clock of first write
					rd_d2 <= std_logic_vector(to_unsigned(i, D_BITS));
				else
					-- write-during-write at same address
					rd_d2 <= (others => 'X');
				end if;
			end loop;

			-- Read in 8 consecutive clock cycles on port 1, write one cycle later on
			-- port 2
			-------------------------------------------------------------------------
			simWaitUntilRisingEdge(clk2, 1);
			-- first read on port 1 here
			ce2		<= '0';
			we2		<= '0';
			a2		<= (others => '-');
			d2    <= (others => '-');
			rd_d2 <= (others => '-');

			for i in 48 to 55 loop
				simWaitUntilRisingEdge(clk2, 1);
				ce2		<= '1';
				we2		<= '1';
				a2		<= to_unsigned(i, A_BITS);
				d2		<= std_logic_vector(to_unsigned(i, D_BITS));
				rd_d2 <= std_logic_vector(to_unsigned(i, D_BITS));
			end loop;

			-- Read in 8 consecutive clock cycles on port 2, write one cycle later on
			-- port 1
			-------------------------------------------------------------------------
			for i in 56 to 63 loop
				simWaitUntilRisingEdge(clk2, 1);
				ce2		<= '1';
				we2		<= '0';
				a2		<= to_unsigned(i, A_BITS);
				d2		<= (others => '-');
				if CLOCK2_PHASE <= CLOCK1_PHASE then
					-- read succeeds if clocks are in phase or if read clock is before
					-- write clock
					rd_d2 <= (others => 'U'); -- memory not yet initialized
				else
					-- write-during-read at same address
					rd_d2 <= (others => 'X');
				end if;
			end loop;

			simWaitUntilRisingEdge(clk2, 1);
			-- last write on port 1 here
			ce2		<= '0';
			we2		<= '0';
			a2		<= (others => '-');
			d2    <= (others => '-');
			rd_d2 <= (others => '-');

			-------------------------------------------------------------------------
			-- Finish
			simWaitUntilRisingEdge(clk2, 1);
			ce2		<= '0';
			we2		<= '-';
			a2		<= (others => '-');
			d2    <= (others => '-');
			rd_d2 <= (others => '-');

			-- This process is finished
			finished2 <= true;
			simDeactivateProcess(simProcessID);
			wait;  -- forever
		end process Stimuli2;

		-- Checker
		-- ===========================================================================

		-- Also checks if old value is kept if ce1 = '0'
		exp_q1 <= rd_d1 when rising_edge(clk1) and ce1 = '1';

		-- Also checks if old value is kept if ce2 = '0'
		exp_q2 <= rd_d2 when rising_edge(clk2) and ce2 = '1';

		Checker1: process
			constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess(simTestID, "TestID "&integer'image(simTestID)&", Checker1");
			variable i : integer;
		begin
			while not finished1 loop
				simWaitUntilRisingEdge(clk1, 1);
				simAssertion((q1 = exp_q1) or -- also matches 'X'es
										 std_match(q1, exp_q1)); -- also matches '-'es
			end loop;

			-- This process is finished
			simDeactivateProcess(simProcessID);
			wait;  -- forever
		end process Checker1;

		Checker2: process
			constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess(simTestID, "TestID "&integer'image(simTestID)&", Checker2");
			variable i : integer;
		begin
			while not finished2 loop
				simWaitUntilRisingEdge(clk2, 1);
				simAssertion((q2 = exp_q2) or -- also matches 'X'es
										 std_match(q2, exp_q2)); -- also matches '-'es
			end loop;

			-- This process is finished
			simDeactivateProcess(simProcessID);
			wait;  -- forever
		end process Checker2;
	end generate gTest;

end architecture;
