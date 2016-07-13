-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Paul Genssler
--
-- Entity:					bitSwapper
--
-- Description:				swaps the bits in each of the 4 bytes, with enable signal
-- 
--	in:  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31
-- out:  7  6  5  4  3  2  1  0 15 14 13 12 11 10  9  8 23 22 21 20 19 18 17 16 31 30 29 28 27 26 25 24
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany,
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
-- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library poc;
use POC.utils.all;
use POC.vectors.all;

entity bitSwapper is
	port  (
		en	: in	std_logic;
		i	: in	std_logic_vector(31 downto 0);
		o	: out	std_logic_vector(31 downto 0)		
	);
end bitSwapper;

architecture arch of bitSwapper is
	signal in_data_slvv			: T_SLVV_8(3 downto 0);
	signal in_data_slvv_rev		: T_SLVV_8 (3 downto 0);
begin
	in_data_slvv <= to_slvv_8(i);

	reverse_per_byte:
	for i in in_data_slvv'range generate
		begin
			in_data_slvv_rev(i) <= reverse(in_data_slvv(i));
	end generate;

	o <= to_slv(in_data_slvv_rev) when en = '1' else i;
end arch;

