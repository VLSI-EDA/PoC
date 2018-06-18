-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:           Patrick Lehmann
--
-- Entity:           sync_Pulse_Altera
--
-- Description:
-- -------------------------------------
-- This is a multi-bit clock-domain-crossing circuit optimized for Altera FPGAs.
-- It synchronizes multiple pulsed bits into the clock-domain ``Clock``.
-- The clock-domain boundary crossing is done by two synchronizer D-FFs. All bits
-- are independent from each other. It generates 3 flip flops per input bit and
-- notifies Quartus, that these flip flops are synchronizer flip flops. If you
-- need a platform independent version of this synchronizer, please use
-- `PoC.misc.sync.Pulse`, which internally instantiates this module if an Altera
-- FPGA is detected.
--
-- .. ATTENTION::
--    Use this synchronizer for very short signals (pulse).
--
-- CONSTRAINTS:
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


entity sync_Pulse_Altera is
	generic (
		BITS          : positive            := 1;                       -- number of bit to be synchronized
		SYNC_DEPTH    : T_MISC_SYNC_DEPTH   := T_MISC_SYNC_DEPTH'low    -- generate SYNC_DEPTH many stages, at least 2
	);
	port (
		Clock         : in  std_logic;                                  -- <Clock>  output clock domain
		Input         : in  std_logic_vector(BITS - 1 downto 0);        -- @async:  input bits
		Output        : out std_logic_vector(BITS - 1 downto 0)         -- @Clock:  output bits
	);
end entity;


architecture rtl of sync_Pulse_Altera is
	attribute PRESERVE          : boolean;
	attribute ALTERA_ATTRIBUTE  : string;

	-- Apply a SDC constraint to meta stable flip flop
	attribute ALTERA_ATTRIBUTE of rtl        : architecture is "-name SDC_STATEMENT ""set_false_path -to [get_registers {*|sync_Pulse_Altera:*|\gen:*:Data_meta}] """;
begin
	gen : for i in 0 to BITS - 1 generate
		signal Data_async        : std_logic;
		signal Data_meta        : std_logic                                    := INIT(i);
		signal Data_sync        : std_logic_vector(SYNC_DEPTH - 1 downto 0)    := (others => INIT(i));

		-- preserve both registers (no optimization, shift register extraction, ...)
		attribute PRESERVE of Data_meta            : signal is TRUE;
		attribute PRESERVE of Data_sync            : signal is TRUE;
		-- Notify the synthesizer / timing analyzer to identity a synchronizer circuit
		attribute ALTERA_ATTRIBUTE of Data_meta    : signal is "-name SYNCHRONIZER_IDENTIFICATION ""FORCED IF ASYNCHRONOUS""";
	begin
		process(Input(i), Data_sync(Data_sync'high))
		begin
			if ((not Input(i) and Data_sync(Data_sync'high)) = '1') then
				Data_async <= '0';
			elsif rising_edge(Input) then
				Data_async <= '1';
			end if;
		end process;

		process(Clock)
		begin
			if rising_edge(Clock) then
				Data_meta <= Data_async;
				Data_sync <= Data_sync(Data_sync'high - 1 downto 0) & Data_meta;
			end if;
		end process;

		Output(i)    <= Data_sync(Data_sync'high);
	end generate;
end architecture;
