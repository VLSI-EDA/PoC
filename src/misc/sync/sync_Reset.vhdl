-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:         Patrick Lehmann
--
-- Entity:          Synchronizes a reset signal across clock-domain boundaries
--
-- Description:
-- -------------------------------------
-- This module synchronizes an asynchronous reset signal to the clock
-- ``Clock``. The ``Input`` can be asserted and de-asserted at any time.
-- The ``Output`` is asserted asynchronously and de-asserted synchronously
-- to the clock.
--
-- .. ATTENTION::
--    Use this synchronizer only to asynchronously reset your design.
--    The 'Output' should be feed by global buffer to the destination FFs, so
--    that, it reaches their reset inputs within one clock cycle.
--
-- Constraints:
--   General:
--     Please add constraints for meta stability to all '_meta' signals and
--     timing ignore constraints to all '_async' signals.
--
--   Xilinx:
--     In case of a Xilinx device, this module will instantiate the optimized
--     module xil_SyncReset. Please attend to the notes of xil_SyncReset.
--
--   Altera sdc file:
--     TODO
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
use     PoC.config.all;
use     PoC.utils.all;
use     PoC.sync.all;


entity sync_Reset is
	generic (
		SYNC_DEPTH    : T_MISC_SYNC_DEPTH   := T_MISC_SYNC_DEPTH'low    -- generate SYNC_DEPTH many stages, at least 2
	);
	port (
		Clock         : in  std_logic;                                  -- <Clock>  output clock domain
		Input         : in  std_logic;                                  -- @async:  reset input
		Output        : out std_logic                                   -- @Clock:  reset output
	);
end entity;


architecture rtl of sync_Reset is
begin
	genGeneric : if (VENDOR /= VENDOR_ALTERA) and (VENDOR /= VENDOR_XILINX) generate
		attribute ASYNC_REG                    : string;
		attribute SHREG_EXTRACT                : string;

		signal Data_async                      : std_logic;
		signal Data_meta                      : std_logic    := '1';
		signal Data_sync                      : std_logic_vector(SYNC_DEPTH - 1 downto 0)    := (others => '1');

		-- Mark registers as asynchronous
		attribute ASYNC_REG      of Data_meta  : signal is "TRUE";
		attribute ASYNC_REG      of Data_sync  : signal is "TRUE";

		-- Prevent XST from translating two FFs into SRL plus FF
		attribute SHREG_EXTRACT of Data_meta  : signal is "NO";
		attribute SHREG_EXTRACT of Data_sync  : signal is "NO";

	begin
		Data_async  <= Input;

		process(Clock, Data_async)
		begin
			if (Data_async = '1') then
				Data_meta    <= '1';
				Data_sync    <= (others => '1');
			elsif rising_edge(Clock) then
				Data_meta    <= '0';
				Data_sync    <= Data_sync(Data_sync'high - 1 downto 0) & Data_meta;
			end if;
		end process;

		Output    <= Data_sync(Data_sync'high);
	end generate;

	-- use dedicated and optimized 2 D-FF synchronizer for Altera FPGAs
	genAltera : if VENDOR = VENDOR_ALTERA generate
		sync : sync_Reset_Altera
			generic map (
				SYNC_DEPTH  => SYNC_DEPTH
			)
			port map (
				Clock       => Clock,
				Input       => Input,
				Output      => Output
			);
	end generate;

	-- use dedicated and optimized 2 D-FF synchronizer for Xilinx FPGAs
	genXilinx : if VENDOR = VENDOR_XILINX generate
		sync : sync_Reset_Xilinx
			generic map (
				SYNC_DEPTH  => SYNC_DEPTH
			)
			port map (
				Clock       => Clock,
				Input       => Input,
				Output      => Output
			);
	end generate;
end architecture;
