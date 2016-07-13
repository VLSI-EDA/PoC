-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Paul Genssler
--
-- Entity:					byteSwapper
--
-- Description:				swaps the endian of the word, with enable signal
-- 
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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library poc;
use POC.utils.all;
use POC.vectors.all;

entity byteSwap is
	generic (
		bytes : positive := 4
	);
    Port ( enable : in  STD_LOGIC;
           i : in  STD_LOGIC_VECTOR (bytes*8-1 downto 0);
           o : out  STD_LOGIC_VECTOR (bytes*8-1 downto 0));
end byteSwap;

architecture Behavioral of byteSwap is
	signal i_slv : T_SLVV_8(3 downto 0);
	signal o_slv : T_SLVV_8(3 downto 0);
begin

	i_slv <= to_slvv_8(i);
	byte_swap_kombi : for i in 1 to bytes generate
	begin
		o_slv(i-1) <= i_slv(bytes-i);
	end generate byte_swap_kombi;
	
	o <= to_slv(o_slv) when enable = '1' else i;

end Behavioral;

