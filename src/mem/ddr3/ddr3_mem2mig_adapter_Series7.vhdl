-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- =============================================================================
-- Authors:					Martin Zabel
--
-- Module:					Adapter for the Xilinx MIG IP core on 7-Series FPGAs.
--
-- Description:
-- ------------------------------------
-- Adapter between the :ref:`PoC.Mem <INT:PoC.Mem>` interface and the
-- application interface ("app") of the Xilinx MIG IP core for 7-Series	FPGAs.
--
-- Simplifies the application interface ("app") of the Xilinx MIG IP core.
-- The PoC.Mem interface provides single-cycle fully pipelined read/write access
-- to the memory. All accesses are word-aligned. Always all bytes of a word are
-- written to the memory. More details can be found
-- :ref:`here <INT:PoC.Mem>`.
--
-- Generic parameters:
--
-- * D_BITS: Data bus width of the PoC.Mem and "app" interface. Also size of one
--   word in bits.
--
-- * DQ_BITS: Size of data bus between memory controller and external memory
--   (DIMM, SoDIMM).
--
-- * MEM_A_BITS: Address bus width of the PoC.Mem interface.
--
-- * APP_A_BTIS: Address bus width of the "app" interface.
--
-- Containts only combinational logic.
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library poc;
use poc.utils.all;

entity ddr3_mem2mig_adapter_Series7 is

	generic (
		D_BITS		 : positive;
		DQ_BITS		 : positive;
		MEM_A_BITS : positive;
		APP_A_BITS : positive
	);

	port (
		-- PoC.Mem interface
		mem_req   : in  std_logic;
		mem_write : in  std_logic;
		mem_addr  : in  unsigned(MEM_A_BITS-1 downto 0);
		mem_wdata : in  std_logic_vector(D_BITS-1 downto 0);
		mem_wmask : in  std_logic_vector(D_BITS/8-1 downto 0) := (others => '0');
		mem_rdy   : out std_logic;
		mem_rstb  : out std_logic;
		mem_rdata : out std_logic_vector(D_BITS-1 downto 0);

		-- Xilinx MIG IP Core interface
		init_calib_complete : in	std_logic;
		app_rd_data					: in	std_logic_vector((D_BITS)-1 downto 0);
		app_rd_data_end			: in	std_logic;
		app_rd_data_valid		: in	std_logic;
		app_rdy							: in	std_logic;
		app_wdf_rdy					: in	std_logic;
		app_addr						: out std_logic_vector(APP_A_BITS-1 downto 0);
		app_cmd							: out std_logic_vector(2 downto 0);
		app_en							: out std_logic;
		app_wdf_data				: out std_logic_vector((D_BITS)-1 downto 0);
		app_wdf_end					: out std_logic;
		app_wdf_mask				: out std_logic_vector((D_BITS)/8-1 downto 0);
		app_wdf_wren				: out std_logic
	);

end entity ddr3_mem2mig_adapter_Series7;

architecture rtl of ddr3_mem2mig_adapter_Series7 is
	-- The smallest addressable unit of the "app" interface has DQ_BITS bits.
	-- The smallest addressable unit of the "mem" interface has D_BITS  bits.
	-- The burst length is then D_BITS / DQ_BITS.
	constant BL      : positive := D_BITS / DQ_BITS;
	constant BL_BITS : natural  := log2ceil(BL);

	signal mem_rdy_i : std_logic;

begin  -- architecture rtl

	-- command & FIFO control
	mem_rdy_i <= init_calib_complete and app_rdy and app_wdf_rdy;
	mem_rdy   <= mem_rdy_i;

	app_en			 <= mem_rdy_i and mem_req;
	app_wdf_wren <= mem_rdy_i and mem_req and mem_write;
	app_wdf_end	 <= mem_rdy_i and mem_req and mem_write;	-- 1 "mem" word / burst
	app_cmd			 <= "00" & (not mem_write);

	-- address
	process (mem_addr) is
	begin  -- process
		app_addr <= (others => '0');
		app_addr(MEM_A_BITS+BL_BITS-1 downto BL_BITS) <= std_logic_vector(mem_addr);
	end process;

	-- write data & mask
	app_wdf_data <= mem_wdata;
	app_wdf_mask <= mem_wmask;

	-- read reply
	mem_rstb	<= app_rd_data_valid;
	mem_rdata <= app_rd_data;

end architecture rtl;
