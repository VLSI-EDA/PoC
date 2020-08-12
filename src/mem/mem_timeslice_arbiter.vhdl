-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Martin Zabel
--
-- Entity:					Timeslice-Arbiter for PoC.Mem interface
--
-- Description:
-- -------------------------------------
-- Timeslice-based arbitration for :ref:`PoC.Mem <INT:PoC.Mem>`
-- interface.
--
-- Configuration
-- *************
--
-- +-----------------+-------------------------------------------------+
-- | Parameter       | Description                                     |
-- +=================+=================================================+
-- | PORTS           | Number of ports to arbitrate.                   |
-- +-----------------+-------------------------------------------------+
-- | OUTSTANDING_REQ | Minimum number of outstanding requests.         |
-- +-----------------+-------------------------------------------------+
--
--
-- Inputs & Outputs:
-- *****************
--
--        +------------------------------+
--        |                              |
--     -->| clk                          |
--     -->| rst                          |   
--        |                              |
--     <--| sel_port                     |
--        |                              |
--     -->| mem_req_1          mem_req_2 |-->
--     -->| mem_write_1      mem_write_2 |-->
--     <--| mem_rdy_1          mem_rdy_2 |<--
--        |                              |
--     <--| mem_rstb_1        mem_rstb_2 |<--
--        |                              |
--        +------------------------------+
--
--
--  The read/write request of the PoC.Mem interface is transfered from the
--  left side (1) to the right side (2). The read reply is transfered from the
--  right side (2) to the left side (1).
--
--
--  The bus multiplexer for ``mem_addr``, ``mem_wdata`` and ``mem_wmask`` must
--  be placed outside because VHDL does not support ports of type array of
--  std_logic_vector where the size of the std_logic_vector is variable. The
--  currently selected port is shown by output ``sel_port``.
--
--  The bus demultiplexer for mem_rdata is just wiring. Only one ``mem_rstb_1``
--  is active at the same time.
--
--
-- Operation
-- *********
--
-- All ports are assigned a fixed timeslice of same size.
--
-- See also :ref:`PoC.Mem <INT:PoC.Mem>` interface.
--
-- Synchronous resets are used.
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
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library poc;

use poc.utils.all;

entity mem_timeslice_arbiter is

  generic (
    PORTS           : positive;
    OUTSTANDING_REQ : positive);    

  port (
    clk      : in std_logic;
    rst      : in std_logic;

		sel_port_o : out integer range 0 to PORTS-1;

		-- Left side (1)
    mem_req_1   : in  std_logic_vector(PORTS-1 downto 0);
    mem_write_1 : in  std_logic_vector(PORTS-1 downto 0);
    mem_rdy_1   : out std_logic_vector(PORTS-1 downto 0);
    mem_rstb_1  : out std_logic_vector(PORTS-1 downto 0);

		-- Right side (2)
    mem_req_2   : out std_logic;
    mem_write_2 : out std_logic;
    mem_rdy_2   : in  std_logic;
    mem_rstb_2  : in  std_logic);

end mem_timeslice_arbiter;

architecture rtl of mem_timeslice_arbiter is

	-- Width of tag stored in FIFO.
	constant TAG_BITS : natural := log2ceil(PORTS);
	
	-- Selected Port, encoded one-hot and binary
	signal sel_onehot_r : std_logic_vector(PORTS-1 downto 0);
	signal sel_bin_r    : unsigned(log2ceil(PORTS)-1 downto 0);
	signal sel_port     : integer range 0 to PORTS-1;

	-- FIFO Control
  signal fifo_put  : std_logic;
  signal fifo_din  : std_logic_vector(TAG_BITS-1 downto 0);
  signal fifo_full : std_logic;
  signal fifo_got  : std_logic;
  signal fifo_dout : std_logic_vector(TAG_BITS-1 downto 0);

begin  -- rtl

  tag_fifo : entity PoC.fifo_cc_got
    generic map (
      D_BITS    => TAG_BITS,
      DATA_REG  => true,
      STATE_REG => true,
      MIN_DEPTH => OUTSTANDING_REQ)
    port map (
      rst   => rst,
      clk   => clk,
      put   => fifo_put,
      din   => fifo_din,
      full  => fifo_full,
      got   => fifo_got,
      dout  => fifo_dout,
      valid => open);

	arbitration : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				-- Select port 0 after reset
				sel_onehot_r <= (0 => '1', others => '0');
				sel_bin_r    <= (others => '0');
			elsif mem_rdy_2 = '1' then
				-- Select next port with each clock cycle, but only if right side is ready.
				-- This is to ensure, that the "free" bandwidth is distributed equally across
				-- the ports.
				sel_onehot_r <= sel_onehot_r(sel_onehot_r'left-1 downto 0) &
												sel_onehot_r(sel_onehot_r'left);
				if sel_bin_r = PORTS-1 then
					sel_bin_r <= (others => '0');
				else
					sel_bin_r <= sel_bin_r + 1;
				end if;
			end if;
		end if;
	end process arbitration;

  -- The currently selected port.
  sel_port 	<= to_integer(sel_bin_r);
  sel_port_o <= sel_port;

	-- Store only tags for read-requests in FIFO. fifo_full already checked
	-- within FIFO.
	fifo_put <= mem_rdy_2 and mem_req_1(sel_port) and not mem_write_1(sel_port);
	fifo_din <= std_logic_vector(sel_bin_r);

	-- Signal ready if port is selected and FIFO is not full on read-requests
	ready: process(mem_rdy_2, fifo_full, sel_port)
	begin
		mem_rdy_1 <= (others => '0'); -- default
		mem_rdy_1(sel_port) <= mem_rdy_2 and not fifo_full;
	end process;

  -- Delegate requests, but only if FIFO is not full. See also mem_rdy_1 above;
  mem_req_2   <= mem_req_1(sel_port) and not fifo_full;
  mem_write_2 <= mem_write_1(sel_port);

	-- Signal reply on port indicated by current FIFO output value.
	-- FIFO output value is always valid.
	reply: process(fifo_dout, mem_rstb_2)
	begin
		mem_rstb_1 <= (others => '0'); -- default
		mem_rstb_1(to_integer(unsigned(fifo_dout))) <= mem_rstb_2;
	end process reply;

	-- Remove FIFO entry after reply was forwarded.
	fifo_got <= mem_rstb_2;
	
end rtl;
