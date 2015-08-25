-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Testbench:				testbench for sine wave LUT
--
-- Description:
-- ------------------------------------
--		TODO
-- 
-- License:
-- =============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany
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

library IEEE;
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.NUMERIC_STD.all;

library PoC;
use			PoC.utils.all;
use			PoC.strings.all;


entity lut_Sine_tb is
end;


architecture test of lut_Sine_tb is 
	constant CLOCK_1_PERIOD		: TIME								:= 10 ns;
	
	signal Clock1							: STD_LOGIC						:= '1';
	signal sim_Stop						: STD_LOGIC						:= '0';
	
	signal lut_in							: STD_LOGIC_VECTOR(7 downto 0)	:= (others => '0');
	signal lut_Q1_in					: STD_LOGIC_VECTOR(7 downto 0);
	signal lut_Q1_out					: STD_LOGIC_VECTOR(7 downto 0);
	signal lut_Q2_in					: STD_LOGIC_VECTOR(7 downto 0);
	signal lut_Q2_out					: STD_LOGIC_VECTOR(7 downto 0);
	signal lut_Q3_in					: STD_LOGIC_VECTOR(7 downto 0);
	signal lut_Q3_out					: STD_LOGIC_VECTOR(7 downto 0);
	signal lut_Q4_in					: STD_LOGIC_VECTOR(7 downto 0);
	signal lut_Q4_out					: STD_LOGIC_VECTOR(7 downto 0);
	
begin

	ClockProcess1 : process(Clock1)
  begin
		Clock1 <= (Clock1 xnor sim_Stop) after CLOCK_1_PERIOD / 2;
  end process;
	
	process
	begin
		wait for 4 * CLOCK_1_PERIOD;
		
		for i in 0 to 1024 loop
			lut_in	<= to_slv(i, lut_in'length);
			wait for CLOCK_1_PERIOD;
		end loop;
		
		wait for 4 * CLOCK_1_PERIOD;
		sim_Stop	<= '1';
		
		wait;
	end process;
	
	lut_Q1_in	<= lut_in;
	lut_Q2_in	<= lut_in;
	lut_Q3_in	<= lut_in;
	lut_Q4_in	<= lut_in;
	
	lutQ1 : entity PoC.lut_Sine
		generic map (
			REG_OUTPUT			=> TRUE,
			MAX_AMPLITUDE		=> 127,
			POINTS					=> 256,
			OFFSET_DEG			=> 0.0,
			QUARTERS				=> 1
		)                             
		port map (                    
			Clock			=> Clock1,			-- 
			Input			=> lut_Q1_in,		-- 
			Output		=> lut_Q1_out		-- 
		);
	
	lutQ2 : entity PoC.lut_Sine
		generic map (
			REG_OUTPUT			=> TRUE,
			MAX_AMPLITUDE		=> 127,
			POINTS					=> 256,
			OFFSET_DEG			=> 0.0,
			QUARTERS				=> 2
		)                             
		port map (                    
			Clock			=> Clock1,			-- 
			Input			=> lut_Q2_in,		-- 
			Output		=> lut_Q2_out		-- 
		);
	
	lutQ3 : entity PoC.lut_Sine
		generic map (
			REG_OUTPUT			=> TRUE,
			MAX_AMPLITUDE		=> 127,
			POINTS					=> 256,
			OFFSET_DEG			=> 0.0,
			QUARTERS				=> 4
		)                             
		port map (                    
			Clock			=> Clock1,			-- 
			Input			=> lut_Q3_in,		-- 
			Output		=> lut_Q3_out		-- 
		);
	
	lutQ4 : entity PoC.lut_Sine
		generic map (
			REG_OUTPUT			=> TRUE,
			MAX_AMPLITUDE		=> 127,
			POINTS					=> 256,
			OFFSET_DEG			=> 45.0,
			QUARTERS				=> 4
		)                             
		port map (                    
			Clock			=> Clock1,			-- 
			Input			=> lut_Q4_in,		-- 
			Output		=> lut_Q4_out		-- 
		);
end;
