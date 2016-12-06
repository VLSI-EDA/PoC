-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Martin Zabel
--									Patrick Lehmann
--
-- Entity:				 	True dual-port memory with write-first behavior.
--
-- Description:
-- -------------------------------------
-- Inferring / instantiating true dual-port memory, with:
--
-- * single clock, clock enable,
-- * 2 read/write ports.
--
-- Command truth table:
--
-- == === === =====================================================
-- ce we1 we2 Command
-- == === === =====================================================
-- 0   X   X  No operation
-- 1   0   0  Read only from memory
-- 1   0   1  Read from memory on port 1, write to memory on port 2
-- 1   1   0  Write to memory on port 1, read from memory on port 2
-- 1   1   1  Write to memory on both ports
-- == === === =====================================================
--
-- Both reads and writes are synchronous to the clock.
--
-- The generalized behavior across Altera and Xilinx FPGAs since
-- Stratix/Cyclone and Spartan-3/Virtex-5, respectively, is as follows:
--
-- Same-Port Read-During-Write
--   When writing data through port 1, the read output of the same port
--   (``q1``) will output the new data (``d1``, in the following clock cycle)
--   which is aka. "write-first behavior".
--
--   Same applies to port 2.
--
-- Mixed-Port Read-During-Write
--   When reading at the write address, the read value will be the new data,
--   aka. "write-first behavior". Of course, the read is still synchronous,
--   i.e, the latency is still one clock cyle.
--
-- If a write is issued on both ports to the same address, then the output of
-- this unit and the content of the addressed memory cell are undefined.
--
-- For simulation, always our dedicated simulation model :ref:`IP:ocram_tdp_sim`
-- is used.
--
-- License:
-- =============================================================================
-- Copyright 2008-2016 Technische Universitaet Dresden - Germany
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
use			PoC.config.all;
use			PoC.utils.all;
use			PoC.strings.all;
use			PoC.vectors.all;
use			PoC.mem.all;


entity ocram_tdp_wf is
	generic (
		A_BITS		: positive;															-- number of address bits
		D_BITS		: positive;															-- number of data bits
		FILENAME	: string		:= ""												-- file-name for RAM initialization
	);
	port (
		clk : in	std_logic;															-- clock
		ce 	: in	std_logic;															-- clock-enable
		we1	: in	std_logic;															-- write-enable for 1st port
		we2	: in	std_logic;															-- write-enable for 2nd port
		a1	 : in	unsigned(A_BITS-1 downto 0);						-- address for 1st port
		a2	 : in	unsigned(A_BITS-1 downto 0);						-- address for 2nd port
		d1	 : in	std_logic_vector(D_BITS-1 downto 0);		-- write-data for 1st port
		d2	 : in	std_logic_vector(D_BITS-1 downto 0);		-- write-data for 2nd port
		q1	 : out std_logic_vector(D_BITS-1 downto 0);		-- read-data from 1st port
		q2	 : out std_logic_vector(D_BITS-1 downto 0) 		-- read-data from 2nd port
	);
end entity;


architecture rtl of ocram_tdp_wf is
	-- Two read/write ports are only supported in true-dual port block memories
	-- on FPGAs. But not all synthesis tools, do infer the required bypass logic
	-- as already shown for :ref:`IP:ocram_sdp_wf`.
	-- Thus, bypass logic has to be explicitly described to get the intended
	-- write-first behavior.

	signal wd1_r  : std_logic_vector(d1'range); -- write data from port 1
	signal wd2_r  : std_logic_vector(d2'range); -- write data from port 2
	signal fwd1_r : std_logic;                  -- forward write data from port 1 to port 2
	signal fwd2_r : std_logic;                  -- forward write data from port 2 to port 1
	signal ram_q1 : std_logic_vector(q1'range); -- RAM output, port 1
	signal ram_q2 : std_logic_vector(q2'range); -- RAM output, port 2

	-- Compares two addresses, returns 'X' if either ``a1`` or ``a2`` contains
	-- meta-values, otherwise returns '1' if ``a1 == a2`` is true else
	-- '0'. Returns 'X' even when the addresses contain '-' values, to signal an
	-- undefined outcome.
	function addr_equal(a1 : unsigned; a2 : unsigned) return X01 is
	begin
		-- synthesis translate_off
		if is_x(a1) or is_x(a2) then return 'X'; end if;
		-- synthesis translate_on
		if to_x01(std_logic_vector(a1)) = to_x01(std_logic_vector(a2)) then
			return '1';
		end if;
		return '0';
	end function;

begin
	process(clk)
		variable addr_eq : X01;
	begin
		if rising_edge(clk) then
			case to_x01(ce) is
				when '1' =>
					wd1_r   <= to_x01(d1);
					wd2_r   <= to_x01(d2);
					addr_eq := addr_equal(a1, a2);
					fwd1_r  <= addr_eq and we1;
					fwd2_r  <= addr_eq and we2;

				when '0' =>	null; -- keep previous state

				when others => -- X propagation in simulation
					wd1_r  <= (others => 'X');
					fwd1_r <= 'X';
					fwd2_r <= 'X';
			end case;

			if SIMULATION then
				if (fwd1_r and fwd2_r) = '1' then
					report "ERROR: both ports write to the same address." severity error;
				end if;
			end if;
		end if;
	end process;

	ram_tdp: entity work.ocram_tdp
		generic map (
			A_BITS   => A_BITS,
			D_BITS   => D_BITS,
			FILENAME => FILENAME)
		port map (
			clk1 => clk,
			clk2 => clk,
			ce1  => ce,
			ce2  => ce,
			we1  => we1,
			we2  => we2,
			a1   => a1,
			a2   => a2,
			d1   => d1,
			d2   => d2,
			q1   => ram_q1,
			q2   => ram_q2);

	with fwd1_r select q2 <=
		wd1_r            when '1',
		ram_q2           when '0',
		(others => 'X') when others; -- X propagation in simulation

	with fwd2_r select q1 <=
		wd2_r            when '1',
		ram_q1           when '0',
		(others => 'X') when others; -- X propagation in simulation

end architecture;
