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


entity ocram_tdp_tb is
end entity;

architecture tb of ocram_tdp_tb is
	constant CLOCK_FREQ							: FREQ					:= 100 MHz;

  -- clock
  signal clk			: std_logic;

  -- component generics
  -- Set to values used for synthesis when simulating a netlist.
  constant A_BITS : positive := 10;
  constant D_BITS : positive := 32;

  -- component ports
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
	signal rd_d1  : std_logic_vector(D_BITS-1 downto 0);
	signal rd_d2  : std_logic_vector(D_BITS-1 downto 0);

	-- Derived expected output on q1 / q2.
	signal exp_q1 : std_logic_vector(D_BITS-1 downto 0) := (others => '-');
	signal exp_q2 : std_logic_vector(D_BITS-1 downto 0) := (others => '-');

	-- Signaling between Stimuli and Checker process
	signal finished : boolean := false;

begin
	-- initialize global simulation status
	simInitialize;
	-- generate global testbench clock
	simGenerateClock(clk, CLOCK_FREQ);

	-- component instantiation
	DUT: entity poc.ocram_tdp
		generic map (
			A_BITS	 => A_BITS,
			D_BITS	 => D_BITS,
			FILENAME => "")
		port map (
			clk1 => clk,
			clk2 => clk,
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

  -- waveform generation
  Stimuli: process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Stimuli process");
  begin
    -- No operation on first rising clock edge
    ce1   <= '0';
    we1   <= '-';
    a1    <= (others => '-');
    d1    <= (others => '-');
    rd_d1 <= (others => '-');
    ce2   <= '0';
    we2   <= '-';
    a2    <= (others => '-');
    d2    <= (others => '-');
    rd_d2 <= (others => '-');

		-------------------------------------------------------------------------
		-- Write in 8 consecutive clock cycles on port 1, read one cycle later on
		-- port 2

		for i in 0 to 7 loop
			simWaitUntilRisingEdge(clk, 1);
			ce1		<= '1';
			we1		<= '1';
			a1		<= to_unsigned(i, a1'length);
			d1		<= std_logic_vector(to_unsigned(i, d1'length));
			rd_d1 <= std_logic_vector(to_unsigned(i, d1'length));

			-- read is delayed by one clock cycle
			ce2		<= ce1;
			we2   <= '0';
			a2		<= a1;
			rd_d2 <= d1;											-- data to be read
		end loop;

		simWaitUntilRisingEdge(clk, 1);
		ce1		<= '0';
		we1		<= '0';
		a1		<= (others => '-');
		rd_d1 <= (others => '-');

		-- last read is delayed by one clock cycle
		ce2		<= ce1;
    we2   <= '0';
		a2		<= a1;
		rd_d2 <= d1;												-- data to be read

		-------------------------------------------------------------------------
		-- Alternating write on port 1 / read on port 2
		for i in 8 to 15 loop
			simWaitUntilRisingEdge(clk, 1);
			ce1		<= not ce1;									-- write @ even addresses
			we1		<= '1';
			a1		<= to_unsigned(i, a1'length);
			d1		<= std_logic_vector(to_unsigned(i, d1'length));
			rd_d1 <= std_logic_vector(to_unsigned(i, d1'length));

			-- read is delayed by one clock cycle
			ce2		<= ce1;
			we2   <= '0';
			a2		<= a1;
			rd_d2 <= d1;											-- data to be read
		end loop;

		simWaitUntilRisingEdge(clk, 1);
		ce1		<= '0';
		we1		<= '0';
		a1		<= (others => '-');
		rd_d1 <= (others => '-');

		-- last read is delayed by one clock cycle
		ce2		<= ce1;
		we2   <= '0';
		a2		<= a1;
		rd_d2 <= d1;												-- data to be read

		simWaitUntilRisingEdge(clk, 1);
		ce2		<= '0';
		we2   <= '-';
		a2		<= (others => '-');
		rd_d2 <= (others => '-');

		-------------------------------------------------------------------------
		-- Write in 8 consecutive clock cycles on port 2, read one cycle later on
		-- port 1

		for i in 16 to 23 loop
			simWaitUntilRisingEdge(clk, 1);
			ce2		<= '1';
			we2		<= '1';
			a2		<= to_unsigned(i, a1'length);
			d2		<= std_logic_vector(to_unsigned(i, d1'length));
			rd_d2 <= std_logic_vector(to_unsigned(i, d1'length));

			-- read is delayed by one clock cycle
			ce1		<= ce2;
			we1   <= '0';
			a1		<= a2;
			rd_d1 <= d2;											-- data to be read
		end loop;

		simWaitUntilRisingEdge(clk, 1);
		ce2		<= '0';
		we2		<= '0';
		a2		<= (others => '-');
		rd_d2 <= (others => '-');

		-- last read is delayed by one clock cycle
		ce1		<= ce2;
    we1   <= '0';
		a1		<= a2;
		rd_d1 <= d2;												-- data to be read

		-------------------------------------------------------------------------
		-- Alternating write on port 2 / read on port 1
		for i in 24 to 31 loop
			simWaitUntilRisingEdge(clk, 1);
			ce2		<= not ce2;									-- write @ even addresses
			we2		<= '1';
			a2		<= to_unsigned(i, a1'length);
			d2		<= std_logic_vector(to_unsigned(i, d1'length));
			rd_d2 <= std_logic_vector(to_unsigned(i, d1'length));

			-- read is delayed by one clock cycle
			ce1		<= ce2;
			we1   <= '0';
			a1		<= a2;
			rd_d1 <= d2;											-- data to be read
		end loop;

		simWaitUntilRisingEdge(clk, 1);
		ce2		<= '0';
		we2		<= '0';
		a2		<= (others => '-');
		rd_d2 <= (others => '-');

		-- last read is delayed by one clock cycle
		ce1		<= ce2;
		we1   <= '0';
		a1		<= a2;
		rd_d1 <= d2;												-- data to be read

		simWaitUntilRisingEdge(clk, 1);
		ce1		<= '0';
		we1   <= '-';
		a1		<= (others => '-');
		rd_d1 <= (others => '-');

		-------------------------------------------------------------------------
		-- Finish
		finished <= true;

    -- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
  end process Stimuli;

	-- Also checks if old value is kept if ce1 = '0'
	exp_q1 <= rd_d1 when rising_edge(clk) and ce1 = '1';

	-- Also checks if old value is kept if ce2 = '0'
	exp_q2 <= rd_d2 when rising_edge(clk) and ce2 = '1';

  Checker: process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Checker process");
		variable i : integer;
  begin
		while not finished loop
			simWaitUntilRisingEdge(clk, 1);
			simAssertion(std_match(q1, exp_q1));
			simAssertion(std_match(q2, exp_q2));
		end loop;

    -- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
  end process Checker;

end architecture;
