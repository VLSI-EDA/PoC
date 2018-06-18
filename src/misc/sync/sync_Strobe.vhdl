-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:         Patrick Lehmann
--                  Steffen Koehler
--
-- Entity:          Synchronizes a strobe signal across clock-domain boundaries
--
-- Description:
-- -------------------------------------
-- This module synchronizes multiple high-active bits from clock-domain
-- ``Clock1`` to clock-domain ``Clock2``. The clock-domain boundary crossing is
-- done by a T-FF, two synchronizer D-FFs and a reconstructive XOR. A busy
-- flag is additionally calculated and can be used to block new inputs. All
-- bits are independent from each other. Multiple consecutive strobes are
-- suppressed by a rising edge detection.
--
-- .. ATTENTION::
--    Use this synchronizer only for one-cycle high-active signals (strobes).
--
-- .. image:: /_static/misc/sync/sync_Strobe.*
--    :target: ../../../_static/misc/sync/sync_Strobe.svg
--
-- Constraints:
--   This module uses sub modules which need to be constrained. Please
--   attend to the notes of the instantiated sub modules.
--
-- License:
-- =============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany
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
use     IEEE.NUMERIC_STD.all;

library PoC;
use     PoC.sync.all;


entity sync_Strobe is
	generic (
		BITS                : positive            := 1;                       -- number of bit to be synchronized
		GATED_INPUT_BY_BUSY : boolean             := TRUE;                    -- use gated input (by busy signal)
		SYNC_DEPTH          : T_MISC_SYNC_DEPTH   := T_MISC_SYNC_DEPTH'low    -- generate SYNC_DEPTH many stages, at least 2
	);
	port (
		Clock1              : in  std_logic;                            -- <Clock>  input clock domain
		Clock2              : in  std_logic;                            -- <Clock>  output clock domain
		Input               : in  std_logic_vector(BITS - 1 downto 0);  -- @Clock1:  input bits
		Output              : out std_logic_vector(BITS - 1 downto 0);  -- @Clock2:  output bits
		Busy                : out  std_logic_vector(BITS - 1 downto 0)  -- @Clock1:  busy bits
	);
end entity;


architecture rtl of sync_Strobe is
	attribute SHREG_EXTRACT : string;

	signal syncClk1_In      : std_logic_vector(BITS - 1 downto 0);
	signal syncClk1_Out     : std_logic_vector(BITS - 1 downto 0);
	signal syncClk2_In      : std_logic_vector(BITS - 1 downto 0);
	signal syncClk2_Out     : std_logic_vector(BITS - 1 downto 0);

begin
	gen : for i in 0 to BITS - 1 generate
		signal D0             : std_logic      := '0';
		signal T1             : std_logic      := '0';
		signal D2             : std_logic      := '0';

		signal Changed_Clk1   : std_logic;
		signal Changed_Clk2   : std_logic;
		signal Busy_i         : std_logic;

		-- Prevent XST from translating two FFs into SRL plus FF
		attribute SHREG_EXTRACT of D0  : signal is "NO";
		attribute SHREG_EXTRACT of T1  : signal is "NO";
		attribute SHREG_EXTRACT of D2  : signal is "NO";

	begin
		process(Clock1)
		begin
			if rising_edge(Clock1) then
				-- input delay for rising edge detection
				D0    <= Input(i);

				-- T-FF to converts a strobe to a flag signal
				if GATED_INPUT_BY_BUSY then
					T1  <= (Changed_Clk1 and not Busy_i) xor T1;
				else
					T1  <= Changed_Clk1 xor T1;
				end if;
			end if;
		end process;

		-- D-FF for level change detection (both edges)
		D2  <= syncClk2_Out(i) when rising_edge(Clock2);

		-- assign syncClk*_In signals
		syncClk2_In(i)  <= T1;
		syncClk1_In(i)  <= syncClk2_Out(i);         -- D2

		Changed_Clk1    <= not D0 and Input(i);     -- rising edge detection
		Changed_Clk2    <= syncClk2_Out(i) xor D2;  -- level change detection; restore strobe signal from flag
		Busy_i          <= T1 xor syncClk1_Out(i);  -- calculate busy signal

		-- output signals
		Output(i)        <= Changed_Clk2;
		Busy(i)          <= Busy_i;
	end generate;

	syncClk2 : entity PoC.sync_Bits
		generic map (
			BITS        => BITS,          -- number of bit to be synchronized
			SYNC_DEPTH  => SYNC_DEPTH
		)
		port map (
			Clock       => Clock2,        -- <Clock>  output clock domain
			Input       => syncClk2_In,   -- @async:  input bits
			Output      => syncClk2_Out   -- @Clock:  output bits
		);

	syncClk1 : entity PoC.sync_Bits
		generic map (
			BITS        => BITS,          -- number of bit to be synchronized
			SYNC_DEPTH  => SYNC_DEPTH
		)
		port map (
			Clock       => Clock1,        -- <Clock>  output clock domain
			Input       => syncClk1_In,   -- @async:  input bits
			Output      => syncClk1_Out   -- @Clock:  output bits
		);
end architecture;
