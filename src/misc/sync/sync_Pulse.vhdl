-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:         Patrick Lehmann
--
-- Entity:          Synchronizes a very short pulse across clock-domain boundaries
--
-- Description:
-- -------------------------------------
-- This module synchronizes multiple pulsed bits into the clock-domain ``Clock``.
-- The clock-domain boundary crossing is done by two synchronizer D-FFs. All bits
-- are independent from each other. If a known vendor like Altera or Xilinx are
-- recognized, a vendor specific implementation is chosen.
--
-- .. ATTENTION::
--    Use this synchronizer for very short signals (pulse).
--
-- Constraints:
--   General:
--     Please add constraints for meta stability to all '_meta' signals and
--     timing ignore constraints to all '_async' signals.
--
--   Xilinx:
--     In case of a Xilinx device, this module will instantiate the optimized
--     module PoC.xil.sync.Pulse. Please attend to the notes of sync_Bits.vhdl.
--
--   Altera sdc file:
--     TODO
--
-- SeeAlso:
-- :doc:`PoC.misc.sync.Bits </IPCores/misc/sync/sync_Bits>`
--   For a common 2 D-FF synchronizer for *flag*-signals.
-- :doc:`PoC.misc.sync.Reset </IPCores/misc/sync/sync_Reset>`
--   For a special 2 D-FF synchronizer for *reset*-signals.
-- :doc:`PoC.misc.sync.Strobe </IPCores/misc/sync/sync_Strobe>`
--   For a synchronizer for *strobe*-signals.
-- :doc:`PoC.misc.sync.Vector </IPCores/misc/sync/sync_Vector>`
--   For a multiple bits capable synchronizer.
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


entity sync_Pulse is
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


architecture rtl of sync_Pulse is
	constant DEV_INFO : T_DEVICE_INFO        := DEVICE_INFO;
begin
	genGeneric : if ((DEV_INFO.Vendor /= VENDOR_ALTERA) and (DEV_INFO.Vendor /= VENDOR_XILINX)) generate
		attribute ASYNC_REG              : string;
		attribute SHREG_EXTRACT          : string;
	begin
		gen : for i in 0 to BITS - 1 generate
			signal Data_async              : std_logic;
			signal Data_meta              : std_logic                                    := INIT_I(i);
			signal Data_sync              : std_logic_vector(SYNC_DEPTH - 1 downto 1)    := (others => INIT_I(i));

			-- Mark register DataSync_async's input as asynchronous and ignore timings (TIG)
			attribute ASYNC_REG      of Data_meta  : signal is "TRUE";

			-- Prevent XST from translating two FFs into SRL plus FF
			attribute SHREG_EXTRACT of Data_meta  : signal is "NO";
			attribute SHREG_EXTRACT of Data_sync  : signal is "NO";

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
					Data_meta    <= Data_async;
					Data_sync    <= Data_sync(Data_sync'high - 1 downto 1) & Data_meta;
				end if;
			end process;

			Output(i)  <= Data_sync(Data_sync'high);
		end generate;
	end generate;

	-- use dedicated and optimized 1+2 D-FF synchronizer for Altera FPGAs
	genAltera : if (DEV_INFO.Vendor = VENDOR_ALTERA) generate
		sync : sync_Pulse_Altera
			generic map (
				BITS        => BITS,
				SYNC_DEPTH  => SYNC_DEPTH
			)
			port map (
				Clock      => Clock,
				Input      => Input,
				Output    => Output
			);
	end generate;

	-- use dedicated and optimized 1+2 D-FF synchronizer for Xilinx FPGAs
	genXilinx : if (DEV_INFO.Vendor = VENDOR_XILINX) generate
		sync : sync_Pulse_Xilinx
			generic map (
				BITS        => BITS,
				SYNC_DEPTH  => SYNC_DEPTH
			)
			port map (
				Clock      => Clock,
				Input      => Input,
				Output    => Output
			);
	end generate;
end architecture;
