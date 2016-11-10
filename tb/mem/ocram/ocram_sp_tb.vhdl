-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Martin Zabel
--									Patrick Lehmann
--
-- Testbench:			 	Testbench for ocram_sp.
--
-- Description:
-- -------------------------------------
--
-- License:
-- =============================================================================
-- Copyright 2016-2016 Technische Universitaet Dresden - Germany
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library PoC;
use 		PoC.physical.all;
-- simulation specific packages
use			PoC.sim_types.all;
use			PoC.simulation.all;
use			PoC.waveform.all;

entity ocram_sp_tb is
end entity ocram_sp_tb;

architecture sim of ocram_sp_tb is
	constant A_BITS : positive := 8;
	constant D_BITS : positive := A_BITS; -- for test pattern

	signal clk : std_logic := '1';
	signal ce	 : std_logic;
	signal we	 : std_logic;
	signal a	 : unsigned(A_BITS-1 downto 0);
	signal d	 : std_logic_vector(D_BITS-1 downto 0);
	signal q	 : std_logic_vector(D_BITS-1 downto 0);

begin  -- architecture sim

	uut: entity PoC.ocram_sp
		generic map (
			A_BITS	 => A_BITS,
			D_BITS	 => D_BITS,
			FILENAME => "")
		port map (
			clk => clk,
			ce	=> ce,
			we	=> we,
			a		=> a,
			d		=> d,
			q		=> q);

	-- initialize global simulation status
	simInitialize;
	-- generate global testbench clock
	simGenerateClock(clk, 100 MHz);

	Stimuli: process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Stimuli process");
	begin
		-- 1) Fill memory and check read-during-write behavior
		-- ===================================================
		ce <= '1';
		we <= '1';
		a <= to_unsigned(0, a'length);
		d <= std_logic_vector(to_unsigned(0, a'length));
		wait until rising_edge(clk);

		for addr in 1 to 2**A_BITS-1 loop
			ce <= '1';
			we <= '1';
			a <= to_unsigned(addr, a'length);
			d <= std_logic_vector(to_unsigned(addr, a'length));
			wait until rising_edge(clk);
			-- At this clock edge, we can check the result of the preceding access.
			-- Check read-during write behavior.
			simAssertion(q = std_logic_vector(to_unsigned(addr-1, a'length)),
									 "Wrong read data during write to address:" & integer'image(addr-1));
		end loop;  -- i

		ce <= '0';
		we <= '-';
		wait until rising_edge(clk);
		-- At this clock edge, we can check the result of the last access.
		-- Check read-during write behavior.
		simAssertion(q = std_logic_vector(to_unsigned(2**A_BITS-1, a'length)),
								 "Wrong read data during write to address:" & integer'image(2**A_BITS-1));

		-- 2) Read back
		-- ============
		ce <= '1';
		we <= '0';
		a <= to_unsigned(0, a'length);
		wait until rising_edge(clk);

		for addr in 1 to 2**A_BITS-1 loop
			ce <= '1';
			we <= '0';
			a <= to_unsigned(addr, a'length);
			d <= (others => '-');
			wait until rising_edge(clk);
			-- At this clock edge, we can check the result of the preceding access.
			simAssertion(q = std_logic_vector(to_unsigned(addr-1, a'length)),
									 "Wrong read data from address:" & integer'image(addr-1));
		end loop;  -- i

		ce <= '0';
		we <= '-';
		wait until rising_edge(clk);
		-- At this clock edge, we can check the result of the last access.
		simAssertion(q = std_logic_vector(to_unsigned(2**A_BITS-1, a'length)),
								 "Wrong read data from address:" & integer'image(2**A_BITS-1));

		-- 3) Read back in reverse order
		-- =============================
		ce <= '1';
		we <= '0';
		a <= to_unsigned(2**A_BITS-1, a'length);
		wait until rising_edge(clk);

		for addr in 2**A_BITS-2 downto 0 loop
			ce <= '1';
			we <= '0';
			a <= to_unsigned(addr, a'length);
			d <= (others => '-');
			wait until rising_edge(clk);
			-- At this clock edge, we can check the result of the preceding access.
			simAssertion(q = std_logic_vector(to_unsigned(addr+1, a'length)),
									 "Wrong read data from address:" & integer'image(addr-1));
		end loop;  -- i

		ce <= '0';
		we <= '-';
		wait until rising_edge(clk);
		-- At this clock edge, we can check the result of the last access.
		simAssertion(q = std_logic_vector(to_unsigned(0, a'length)),
								 "Wrong read data from address:" & integer'image(0));


		-- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
	end process;

end architecture sim;
