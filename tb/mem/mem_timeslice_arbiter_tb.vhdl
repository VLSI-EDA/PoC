-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Martin Zabel
--
-- Testbench:			 	Testbench for mem_timeslice_arbiter.
--
-- Description:
-- -------------------------------------
--
-- License:
-- =============================================================================
-- Copyright 2020      Martin Zabel, Berlin, Germany
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

use			PoC.utils.all;

library test;

entity mem_timeslice_arbiter_tb is
end entity mem_timeslice_arbiter_tb;

architecture sim of mem_timeslice_arbiter_tb is
  constant PORTS           : positive := 8; -- Test 7 only valid if PORTS is a
																						-- power of 2.
  constant OUTSTANDING_REQ : positive := PORTS;

  signal clk         : std_logic;
  signal rst         : std_logic;
  signal sel_port_o  : integer range 0 to PORTS-1;
  signal mem_req_1   : std_logic_vector(PORTS-1 downto 0);
  signal mem_write_1 : std_logic_vector(PORTS-1 downto 0);
  signal mem_rdy_1   : std_logic_vector(PORTS-1 downto 0);
  signal mem_rstb_1  : std_logic_vector(PORTS-1 downto 0);
  signal mem_req_2   : std_logic;
  signal mem_write_2 : std_logic;
  signal mem_rdy_2   : std_logic;
  signal mem_rstb_2  : std_logic;
	
begin  -- architecture sim

	uut: entity PoC.mem_timeslice_arbiter
    generic map (
      PORTS           => PORTS,
      OUTSTANDING_REQ => OUTSTANDING_REQ)
    port map (
      clk         => clk,
      rst         => rst,
      sel_port_o  => sel_port_o,
      mem_req_1   => mem_req_1,
      mem_write_1 => mem_write_1,
      mem_rdy_1   => mem_rdy_1,
      mem_rstb_1  => mem_rstb_1,
      mem_req_2   => mem_req_2,
      mem_write_2 => mem_write_2,
      mem_rdy_2   => mem_rdy_2,
      mem_rstb_2  => mem_rstb_2);
	
	-- initialize global simulation status
	simInitialize;
	-- generate global testbench clocks
	simGenerateClock(clk, 100 MHz);

  Stimuli : process
    constant simProcessID : T_SIM_PROCESS_ID := simRegisterProcess("Stimuli process");
  begin
    -- 0) Reset
    -- ========
    rst <= '1';
    wait until rising_edge(clk);
    rst  <= '0';

		
    -- 1) Right side ready, no request on left side
    -- ============================================
		mem_req_1 <= (others => '0');
		mem_write_1 <= (others => '-');
		mem_rdy_2 <= '1';
		mem_rstb_2 <= '0';

		for cycle in 0 to PORTS-1 loop
			-- Check combinatorial outputs
			wait for 1 ns;
			simAssertion(sel_port_o = cycle, "1) Wrong port selected in cycle " & integer'image(cycle) & ": " & integer'image(sel_port_o));
			simAssertion(mem_req_2 = '0', "1) No request must be forwarded in cycle " & integer'image(cycle) & "!");
			simAssertion(mem_rstb_1 = (mem_rstb_1'range => '0'), "1) No port must be read-strobed!");
			for i in 0 to PORTS-1 loop
				if i = cycle then
					simAssertion(mem_rdy_1(i) = '1', "1) Port " & integer'image(i) & " must be ready in cycle " & integer'image(cycle) & "!");
				else
					simAssertion(mem_rdy_1(i) = '0', "1) Port " & integer'image(i) & " must not be ready in cycle " & integer'image(cycle) & "!");
				end if;
			end loop;
			-- Check registered outputs
			wait until rising_edge(clk);
		end loop;

		
    -- 2) Right side not ready, no request on left side
    -- ================================================
		mem_req_1 <= (others => '0');
		mem_write_1 <= (others => '-');
		mem_rdy_2 <= '0';
		mem_rstb_2 <= '0';

		-- As mem_rdy_2 = '0', port selection does not change.
		for cycle in 0 to PORTS-1 loop
			-- Check combinatorial outputs
			wait for 1 ns;
			simAssertion(sel_port_o = 0, "2) Wrong port selected in cycle " & integer'image(cycle) & ": " & integer'image(sel_port_o));
			simAssertion(mem_rdy_1 = (mem_rdy_1'range => '0'), "2) No port must be ready!");
			simAssertion(mem_rstb_1 = (mem_rstb_1'range => '0'), "2) No port must be read-strobed!");
			-- Check registered outputs
			wait until rising_edge(clk);
		end loop;

		
    -- 3) Right side ready, write requests only on left side
    -- =====================================================
		mem_req_1 <= (others => '1');
		mem_write_1 <= (others => '1');
		mem_rdy_2 <= '1';
		mem_rstb_2 <= '0';

		for cycle in 0 to PORTS-1 loop
			-- Check combinatorial outputs
			wait for 1 ns;
			simAssertion(sel_port_o = cycle, "3) Wrong port selected in cycle " & integer'image(cycle) & ": " & integer'image(sel_port_o));
			simAssertion(mem_req_2 = '1', "3) Request must be forwarded!");
			simAssertion(mem_write_2 = '1', "3) Write request must be forwarded!");
			simAssertion(mem_rstb_1 = (mem_rstb_1'range => '0'), "3) No port must be read-strobed!");
			for i in 0 to PORTS-1 loop
				if i = cycle then
					simAssertion(mem_rdy_1(i) = '1', "3) Port " & integer'image(i) & " must be ready in cycle " & integer'image(cycle) & "!");
				else
					simAssertion(mem_rdy_1(i) = '0', "3) Port " & integer'image(i) & " must not be ready in cycle " & integer'image(cycle) & "!");
				end if;
			end loop;
			-- Check registered outputs
			wait until rising_edge(clk);
		end loop;


    -- 4) Right side ready, read requests only on left side
    -- =====================================================
		mem_req_1 <= (others => '1');
		mem_write_1 <= (others => '0');
		mem_rdy_2 <= '1';
		mem_rstb_2 <= '0';

		for cycle in 0 to PORTS-1 loop
			-- Check combinatorial outputs
			wait for 1 ns;
			simAssertion(sel_port_o = cycle, "4) Wrong port selected in cycle " & integer'image(cycle) & ": " & integer'image(sel_port_o));
			simAssertion(mem_req_2 = '1', "4) Request must be forwarded!");
			simAssertion(mem_write_2 = '0', "4) Read request must be forwarded!");
			simAssertion(mem_rstb_1 = (mem_rstb_1'range => '0'), "4) No port must be read-strobed yet!");
			for i in 0 to PORTS-1 loop
				if i = cycle then
					simAssertion(mem_rdy_1(i) = '1', "4) Port " & integer'image(i) & " must be ready in cycle " & integer'image(cycle) & "!");
				else
					simAssertion(mem_rdy_1(i) = '0', "4) Port " & integer'image(i) & " must not be ready in cycle " & integer'image(cycle) & "!");
				end if;
			end loop;
			-- Check registered outputs
			wait until rising_edge(clk);
		end loop;

		-- Issue read replys.
		mem_req_1 <= (others => '0');
		mem_rstb_2 <= '1';
		for cycle in 0 to PORTS-1 loop
			-- Check combinatorial outputs
			wait for 1 ns;
			simAssertion(mem_req_2 = '0', "4) No request to forward in reply-cycle " & integer'image(cycle) & "!");
			for i in 0 to PORTS-1 loop
				if i = cycle then
					simAssertion(mem_rstb_1(i) = '1', "4) Port " & integer'image(i) & " must be read-strobed in cycle " & integer'image(cycle) & "!");
				else
					simAssertion(mem_rstb_1(i) = '0', "4) Port " & integer'image(i) & " must not be read-strobed in cycle " & integer'image(cycle) & "!");
				end if;
			end loop;
			-- Check registered outputs
			wait until rising_edge(clk);
		end loop;

		
    -- 5) Right side ready, write requests on odd ports only
    -- =====================================================
		mem_req_1 <= (others => '0');
		mem_write_1 <= (others => '-');
		for i in 0 to PORTS-1 loop
			if i mod 2 = 1 then
				mem_req_1(i) <= '1';
				mem_write_1(i) <= '1';
			end if;
		end loop;
		mem_rdy_2 <= '1';
		mem_rstb_2 <= '0';

		for cycle in 0 to PORTS-1 loop
			-- Check combinatorial outputs
			wait for 1 ns;
			simAssertion(sel_port_o = cycle, "5) Wrong port selected in cycle " & integer'image(cycle) & ": " & integer'image(sel_port_o));
			if cycle mod 2 = 1 then
				simAssertion(mem_req_2 = '1', "5) Request must be forwarded!");
				simAssertion(mem_write_2 = '1', "5) Write request must be forwarded!");
			else
				simAssertion(mem_req_2 = '0', "5) No request to forward!");
			end if;
			simAssertion(mem_rstb_1 = (mem_rstb_1'range => '0'), "5) No port must be read-strobed!");
			for i in 0 to PORTS-1 loop
				if i = cycle then
					simAssertion(mem_rdy_1(i) = '1', "5) Port " & integer'image(i) & " must be ready in cycle " & integer'image(cycle) & "!");
				else
					simAssertion(mem_rdy_1(i) = '0', "5) Port " & integer'image(i) & " must not be ready in cycle " & integer'image(cycle) & "!");
				end if;
			end loop;
			-- Check registered outputs
			wait until rising_edge(clk);
		end loop;


    -- 6) Right side ready, read requests on even ports only
    -- =====================================================
		mem_req_1 <= (others => '0');
		mem_write_1 <= (others => '-');
		for i in 0 to PORTS-1 loop
			if i mod 2 = 0 then
				mem_req_1(i) <= '1';
				mem_write_1(i) <= '0';
			end if;
		end loop;
		mem_rdy_2 <= '1';
		mem_rstb_2 <= '0';

		for cycle in 0 to PORTS-1 loop
			-- Check combinatorial outputs
			wait for 1 ns;
			simAssertion(sel_port_o = cycle, "6) Wrong port selected in cycle " & integer'image(cycle) & ": " & integer'image(sel_port_o));
			if cycle mod 2 = 0 then
				simAssertion(mem_req_2 = '1', "6) Request must be forwarded!");
				simAssertion(mem_write_2 = '0', "6) Read request must be forwarded!");
			else
				simAssertion(mem_req_2 = '0', "6) No request to forward!");
			end if;
			simAssertion(mem_rstb_1 = (mem_rstb_1'range => '0'), "6) No port must be read-strobed yet!");
			for i in 0 to PORTS-1 loop
				if i = cycle then
					simAssertion(mem_rdy_1(i) = '1', "6) Port " & integer'image(i) & " must be ready in cycle " & integer'image(cycle) & "!");
				else
					simAssertion(mem_rdy_1(i) = '0', "6) Port " & integer'image(i) & " must not be ready in cycle " & integer'image(cycle) & "!");
				end if;
			end loop;
			-- Check registered outputs
			wait until rising_edge(clk);
		end loop;

		-- Issue read replys.
		mem_req_1 <= (others => '0');
		for cycle in 0 to PORTS-1 loop
			if cycle mod 2 = 0 then
				mem_rstb_2 <= '1';
			else
				mem_rstb_2 <= '0';
			end if;
				
			-- Check combinatorial outputs
			wait for 1 ns;
			simAssertion(mem_req_2 = '0', "6) No request must be forwarded in reply-cycle " & integer'image(cycle) & "!");
			for i in 0 to PORTS-1 loop
				if (i = cycle) and (cycle mod 2 = 0) then
					simAssertion(mem_rstb_1(i) = '1', "6) Port " & integer'image(i) & " must be read-strobed in cycle " & integer'image(cycle) & "!");
				else
					simAssertion(mem_rstb_1(i) = '0', "6) Port " & integer'image(i) & " must not be read-strobed in cycle " & integer'image(cycle) & "!");
				end if;
			end loop;
			-- Check registered outputs
			wait until rising_edge(clk);
		end loop;


    -- 7) Right side ready, too much read requests on left side
    -- ========================================================
		mem_req_1 <= (others => '1');
		mem_write_1 <= (others => '0');
		mem_rdy_2 <= '1';
		mem_rstb_2 <= '0';

		for cycle in 0 to PORTS-1 loop
			-- Check combinatorial outputs
			wait for 1 ns;
			simAssertion(sel_port_o = cycle, "7) Wrong port selected in cycle " & integer'image(cycle) & ": " & integer'image(sel_port_o));
			simAssertion(mem_req_2 = '1', "7) Request must be forwarded!");
			simAssertion(mem_write_2 = '0', "7) Read request must be forwarded!");
			simAssertion(mem_rstb_1 = (mem_rstb_1'range => '0'), "7) No port must be read-strobed yet!");
			for i in 0 to PORTS-1 loop
				if i = cycle then
					simAssertion(mem_rdy_1(i) = '1', "7) Port " & integer'image(i) & " must be ready in cycle " & integer'image(cycle) & "!");
				else
					simAssertion(mem_rdy_1(i) = '0', "7) Port " & integer'image(i) & " must not be ready in cycle " & integer'image(cycle) & "!");
				end if;
			end loop;
			-- Check registered outputs
			wait until rising_edge(clk);
		end loop;

		-- Further read-requests should be ignored due to outstanding read-replys
		for cycle in 0 to PORTS-1 loop
			-- Check combinatorial outputs
			wait for 1 ns;
			simAssertion(sel_port_o = cycle, "7) Wrong port selected in cycle " & integer'image(cycle) & ": " & integer'image(sel_port_o));
			simAssertion(mem_req_2 = '0', "7) No request must be forwarded!");
			simAssertion(mem_rdy_1 = (mem_rdy_1'range => '0'), "No port must be ready.");
			simAssertion(mem_rstb_1 = (mem_rstb_1'range => '0'), "7) No port must be read-strobed yet!");
			-- Check registered outputs
			wait until rising_edge(clk);
		end loop;

		-- Issue read replys.
		mem_req_1 <= (others => '0');
		mem_rstb_2 <= '1';
		for cycle in 0 to PORTS-1 loop
			-- Check combinatorial outputs
			wait for 1 ns;
			simAssertion(mem_req_2 = '0', "7) No request to forward in reply-cycle " & integer'image(cycle) & "!");
			for i in 0 to PORTS-1 loop
				if i = cycle then
					simAssertion(mem_rstb_1(i) = '1', "7) Port " & integer'image(i) & " must be read-strobed in cycle " & integer'image(cycle) & "!");
				else
					simAssertion(mem_rstb_1(i) = '0', "7) Port " & integer'image(i) & " must not be read-strobed in cycle " & integer'image(cycle) & "!");
				end if;
			end loop;
			-- Check registered outputs
			wait until rising_edge(clk);
		end loop;
		
		-- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
	end process;

end architecture sim;
