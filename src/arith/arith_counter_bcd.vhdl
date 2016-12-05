-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Martin Zabel
--									Thomas B. Preusser
--
-- Entity:				 	BCD counter.
--
-- Description:
-- -------------------------------------
-- Counter with output in binary coded decimal (BCD). The number of BCD digits
-- is configurable by ``DIGITS``.
--
-- All control signals (reset ``rst``, increment ``inc``) are high-active and
-- synchronous to clock ``clk``. The output ``val`` is the current counter
-- state. Groups of 4 bit represent one BCD digit. The lowest significant digit
-- is specified by ``val(3 downto 0)``.
--
-- .. TODO::
--
--    * implement a ``dec`` input for decrementing
--    * implement a ``load`` input to load a value
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


entity arith_counter_bcd is
	generic (
		DIGITS : positive														-- Number of BCD digits
	);
	port (
		clk : in	std_logic;
		rst : in	std_logic;												-- Reset to 0
		inc : in	std_logic;												-- Increment
		val : out T_BCD_VECTOR(DIGITS-1 downto 0) 	-- Value output
	);
end entity;


architecture rtl of arith_counter_bcd is
  -- c(i) = carry-in of stage 'i'
  signal p : unsigned(DIGITS-1 downto 0);  -- Stage Overflows=Propagates
  signal c : unsigned(DIGITS   downto 0);  -- Inter-Stage Carries
begin
	-- Compute Carries using standard addition
  c <= ('0'&p) xor (('0'&p) + 1);

	-- Generate for each BCD stage
	gDigit : for i in 0 to DIGITS-1 generate
		signal cnt_r : T_BCD := x"0";	 -- Counter Digit of this Stage
	begin
		p(i) <= cnt_r(3) and cnt_r(0); -- Local Overflow at digit 9
		process(clk)
		begin
			if rising_edge(clk) then
				if rst = '1' then
					cnt_r <= (others => '0');
				elsif (inc and c(i)) = '1' then  -- short critical path for 'inc'
					if p(i) = '1' then -- our counter reached last digit
						cnt_r <= x"0";
					else
						cnt_r <= T_BCD(unsigned(cnt_r) + 1);
					end if;
				end if;
			end if;
		end process;

		-- Digit Output
		val(i) <= cnt_r;
	end generate gDigit;
end architecture;
