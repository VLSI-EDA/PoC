-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Module:				 	arith_counter_bcd_tb
--
-- Authors:				 	Martin Zabel
--									Thomas B. Preusser
-- 
-- Description:
-- ------------------------------------
-- Testbench for arith_counter_bcd
-- 
-- License:
-- ============================================================================
-- Copyright 2007-2014 Technische Universitaet Dresden - Germany
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
-- ============================================================================

library	ieee;
use			ieee.std_logic_1164.all;
use			ieee.numeric_std.all;

library poc;
use poc.utils.all;
use poc.simulation.all;

entity arith_counter_bcd_tb is
end arith_counter_bcd_tb;


architecture rtl of arith_counter_bcd_tb is
	constant DIGITS : positive := 4;
	signal clk : std_logic;
	signal rst : std_logic;
	signal inc : std_logic;
	signal val : T_BCD_VECTOR(DIGITS-1 downto 0);

	constant clk_period : time := 10 ns;
begin
	DUT: entity poc.arith_counter_bcd
		generic map (
			DIGITS => DIGITS)
		port map (
			clk => clk,
			rst => rst,
			inc => inc,
			val => val);

	process
		procedure cycle is -- inspired by Thomas B. Preusser
		begin
			clk <= '0';
			wait for clk_period/2;
			clk <= '1';
			wait for clk_period/2;
		end cycle;
		
	begin
		-- initial half cycle so that rising edges are at multiples of clk_period
		clk <= '1'; wait for clk_period/2;
		
		rst <= '1';
		inc <= '0';
		cycle;
		tbAssert(val = (x"0", x"0", x"0", x"0"), "Wrong initial state.");
		
		rst <= '1';
		inc <= '1';
		cycle;
		tbAssert(val = (x"0", x"0", x"0", x"0"), "Wrong initial state.");

		-- d3..d0 denote the new counter state after increment
		rst <= '0';
		for d3 in 0 to 9 loop
			for d2 in 0 to 9 loop
				for d1 in 0 to 9 loop
					for d0 in 0 to 9 loop
						if d3 /= 0 or d2 /= 0 or d1 /= 0 or d0 /= 0 then
							--increment
							inc <= '1';
							cycle;
							tbAssert(val = (t_BCD(to_unsigned(d3,4)),
															t_BCD(to_unsigned(d2,4)),
															t_BCD(to_unsigned(d1,4)),
															t_BCD(to_unsigned(d0,4))),
											 "Must be incremented to state "&
											 integer'image(d3)&
											 integer'image(d2)&
											 integer'image(d1)&
											 integer'image(d0)&".");
						end if;
		
						-- keep state
						inc <= '0';
						cycle;
						tbAssert(val = (t_BCD(to_unsigned(d3,4)),
														t_BCD(to_unsigned(d2,4)),
														t_BCD(to_unsigned(d1,4)),
														t_BCD(to_unsigned(d0,4))),
										 "Must keep in state "&
										 integer'image(d3)&
										 integer'image(d2)&
										 integer'image(d1)&
										 integer'image(d0)&".");
					end loop;
				end loop;
			end loop;
		end loop;

		inc <= '1';
		cycle;
		tbAssert(val = (x"0", x"0", x"0", x"0"), "Should be wrapped to 0000.");
		
		inc <= '1';
		cycle;
		inc <= '1';
		cycle;
		inc <= '1';
		cycle;
		inc <= '1';
		rst <= '1';
		cycle;
		tbAssert(val = (x"0", x"0", x"0", x"0"), "Should be resetted again.");

		tbPrintResult;
		wait;
	end process;
end rtl;
