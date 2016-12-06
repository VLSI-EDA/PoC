-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Martin Zabel
--
-- Entity:				 	Simple dual-port memory with write-first behavior.
--
-- Description:
-- -------------------------------------
-- Inferring / instantiating simple dual-port memory, with:
--
-- * single clock, clock enable,
-- * 1 read port plus 1 write port.
--
-- Command truth table:
--
-- == == ===============================
-- ce we Command
-- == == ===============================
-- 0   X   No operation
-- 1   0   Read only from memory
-- 1   1   Read from and Write to memory
-- == == ===============================
--
-- Both reading and writing are synchronous to the rising-edge of the clock.
-- Thus, when reading, the memory data will be outputted after the
-- clock edge, i.e, in the following clock cycle.
--
-- Mixed-Port Read-During-Write
--   When reading at the write address, the read value will be the new data,
--   aka. "write-first behavior". Of course, the read is still synchronous,
--   i.e, the latency is still one clock cyle.
--
-- License:
-- =============================================================================
-- Copyright 2008-2015 Technische Universitaet Dresden - Germany
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

library	ieee;
use			ieee.std_logic_1164.all;
use			ieee.numeric_std.all;

entity ocram_sdp_wf is
	generic (
		A_BITS		: positive;                           -- number of address bits
		D_BITS		: positive;                           -- number of data bits
		FILENAME	: string		:= ""                     -- file-name for RAM initialization
	);
	port (
		clk : in  std_logic;                            -- clock
		ce  : in  std_logic;                            -- clock-enable
		we  : in  std_logic;                            -- write enable
		ra  : in  unsigned(A_BITS-1 downto 0);          -- read address
		wa  : in  unsigned(A_BITS-1 downto 0);          -- write address
		d   : in  std_logic_vector(D_BITS-1 downto 0);  -- data in
		q   : out std_logic_vector(D_BITS-1 downto 0)   -- data out
	);
end entity;


architecture rtl of ocram_sdp_wf is
	-- Implementation Notes:
	-- ---------------------
	--
	-- I have also checked a modified version of the unit `ocram_sp` with just a
	-- single clock and an asynchronous read like::
	--
	--   process(clk)
	--   begin
	--     if rising_edge(clk) then
	--       if ce = '1' then
	--         ra_r <= ra;
	--       end if;
	--     end if;
	--   end process;
	--
	--   q <= ram(to_integer(ra_r));
	--
	-- But the result from various FPGA synthesis tools was as follows:
	--
	-- * Altera Quartus 13.0: adds proper bypass-logic as expected.
	--
	-- * Lattice Synthesis Engine: adds proper bypass-logic, but there was an
	--   unneccessary multiplexer for the read address to mimic the read enable.
	--
	-- * XST 14.7: RAM is mapped to Block-RAM which has not the desired
	--   read-during-write behavior and also no bypass logic is added. XST adds
	--   also an unneccessary multiplexer for the read address to mimic the read
	--   enable.
	--
	--   Enforcing distributed RAM gives the desired behavior when synthesizing
	--   just this unit. But synthesis has failed in complex projects when
	--   KEEP_HIERARCHY was set to NO.
	--
	-- * Vivado 2016.2: RAM is mapped to Block-RAM which has not the desired
	--   read-during-write behavior and also no bypass logic is added. Vivado
	--   adds also an unneccessary multiplexer for the read address to mimic the
	--   read enable.
	--
	--   Enforcing distributed RAM gives the desired behavior when synthesizing
	--   just this unit. Synthesis results have not yet been checked for larger
	--   designs.
	--
	-- Thus, the solution below is to explictly implement the bypass logic.


	signal wd_r  : std_logic_vector(d'range); -- write data
	signal fwd_r : std_logic;                 -- forward write data
	signal ram_q : std_logic_vector(q'range); -- RAM output

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
	begin
		if rising_edge(clk) then
			case to_x01(ce) is
				when '1' =>
					wd_r  <= to_x01(d);
					fwd_r <= addr_equal(ra, wa) and we;

				when '0' =>	null; -- keep previous state

				when others => -- X propagation in simulation
					wd_r  <= (others => 'X');
					fwd_r <= 'X';
			end case;
		end if;
	end process;

	ram_sdp: entity work.ocram_sdp
		generic map (
			A_BITS   => A_BITS,
			D_BITS   => D_BITS,
			FILENAME => FILENAME)
		port map (
			rclk => clk,
			rce  => ce,
			wclk => clk,
			wce  => ce,
			we   => we,
			ra   => ra,
			wa   => wa,
			d    => d,
			q    => ram_q);

	with fwd_r select q <=
		wd_r            when '1',
		ram_q           when '0',
		(others => 'X') when others; -- X propagation in simulation

end architecture;
