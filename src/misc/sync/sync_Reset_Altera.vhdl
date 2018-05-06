-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:           Patrick Lehmann
--
-- Entity:           sync_Reset_Altera
--
-- Description:
-- -------------------------------------
-- This is the Altera specific implementation of the entity
-- `PoC.misc.sync.Reset`. See the description there on how to use this.
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
--                     Chair of VLSI-Design, Diagnostics and Architecture
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- =============================================================================

library IEEE;
use     IEEE.STD_LOGIC_1164.all;

library PoC;
use     PoC.sync.all;


entity sync_Reset_Altera is
	generic (
		SYNC_DEPTH    : T_MISC_SYNC_DEPTH   := T_MISC_SYNC_DEPTH'low    -- generate SYNC_DEPTH many stages, at least 2
	);
	port (
		Clock         : in  std_logic;                                  -- <Clock>  output clock domain
		Input         : in  std_logic;                                  -- @async:  reset input
		Output        : out std_logic                                   -- @Clock:  reset output
	);
end entity;


architecture rtl of sync_Reset_Altera is
	attribute ALTERA_ATTRIBUTE  : string;
	attribute preserve          : boolean;

	signal Data_async           : std_logic;
	signal Data_meta            : std_logic                                  := '1';
	signal Data_sync            : std_logic_vector(SYNC_DEPTH - 1 downto 0)  := (others => '1');

	-- Apply a SDC constraint to meta stable flip flop
	--attribute ALTERA_ATTRIBUTE of rtl          : architecture is "-name SDC_STATEMENT ""set_false_path -to *|sync_Reset_Altera:*|Data_meta """;
	-- Notity the synthesizer / timing analyzer to identity a synchronizer circuit
	attribute ALTERA_ATTRIBUTE of Data_meta    : signal is "-name SYNCHRONIZER_IDENTIFICATION ""FORCED IF ASYNCHRONOUS""";
	-- preserve both registers (no optimization, shift register extraction, ...)
	attribute preserve of Data_meta            : signal is TRUE;
	attribute preserve of Data_sync            : signal is TRUE;
begin
	Data_async  <= '0';

	process(Clock, Input)
	begin
		if (Input = '1') then
			Data_meta <= '1';
			Data_sync <= (others => '1');
		elsif rising_edge(Clock) then
			Data_meta <= Data_async;
			Data_sync <= Data_sync(Data_sync'high - 1 downto 0) & Data_meta;
		end if;
	end process;

	Output    <= Data_sync(Data_sync'high);
end architecture;
