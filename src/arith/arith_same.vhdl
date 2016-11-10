-- EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Thomas B. Preusser
--
-- Entity:					This module detects whether all bit positions of a std_logic_vector have the same value.
--
-- Description:
-- -------------------------------------
-- This circuit may, for instance, be used to detect the first sign change
-- and, thus, the range of a two's complement number.
--
-- These components may be chained by using the output of the predecessor as
-- guard input. This chaining allows to have intermediate results available
-- while still ensuring the use of a fast carry chain on supporting FPGA
-- architectures. When chaining, make sure to overlap both vector slices by one
-- bit position as to avoid an undetected sign change between the slices.
--
-- License:
-- =============================================================================
-- Copyright 2007-2015 Technische Universität Dresden - Germany,
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

library IEEE;
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;

library poc;
use			poc.config.all;
use			PoC.utils.all;
use			PoC.arith.all;


entity arith_same is
	generic (
		N : positive														 -- Input width
	);
	port (
		g : in	std_logic := '1';								-- Guard Input (!g => !y)
		x : in	std_logic_vector(N-1 downto 0);	-- Input Vector
		y : out std_logic												-- All-same Output
	);
end entity;


architecture rtl of arith_same is
	constant DEV_INFO	: T_DEVICE_INFO		:= DEVICE_INFO;

	constant K : positive := DEV_INFO.LUT_FanIn;			-- LUT Fanin
	constant M : positive := (N-2+1/N)/(K-1) + 1;			-- Required Stage Count
	signal	 p : std_logic_vector(M-1 downto 0);			-- Stage Propagates

begin

	-- Compute Propagates in LUT Stages
	genCC: for i in 0 to M-1 generate
		-- Relevant Vector Slice
		constant LO : natural :=						i	 *(K-1);
		constant HI : natural := imin(N-1, (i+1)*(K-1));
	begin
		p(i) <= '1' when x(HI downto LO) = (HI downto LO => '0') else
						'1' when x(HI downto LO) = (HI downto LO => '1') else
						'0';
	end generate;

	-- Compute Equivalence in Carry Chain
	genXLXn: if DEV_INFO.Vendor /= VENDOR_XILINX generate
		signal	 s : std_logic_vector(M downto 0);
	begin
		-- Infere Carry Chain from Addition
		s <= std_logic_vector(unsigned('0' & p) + (0 to 0 => g));
		y <= s(M);
	end generate genXLXn;

	genXLXy: if DEV_INFO.Vendor = VENDOR_XILINX generate
		i: arith_inc_ovcy_xilinx
			generic map (
				N => M
			)
			port map (
				p => p,
				g => g,
				v => y
			);
	end generate genXLXy;
end architecture;
