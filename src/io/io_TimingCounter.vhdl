-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Entity:				 	optimized down-counter to control timings for low speed signals
--
-- Description:
-- -------------------------------------
-- This down-counter can be configured with a ``TIMING_TABLE`` (a ROM), from which
-- the initial counter value is loaded. The table index can be selected by
-- ``Slot``. ``Timeout`` is a registered output. Up to 16 values fit into one ROM
-- consisting of ``log2ceilnz(imax(TIMING_TABLE)) + 1`` 6-input LUTs.
--
-- License:
-- =============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany
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
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.NUMERIC_STD.all;

library PoC;
use			PoC.my_config.all;
use			PoC.utils.all;


entity io_TimingCounter is
  generic (
	  TIMING_TABLE	: T_NATVEC																					-- timing table
	);
  port (
	  Clock					: in	std_logic;																		-- clock
		Enable				: in	std_logic;																		-- enable counter
		Load					: in	std_logic;																		-- load Timing Value from TIMING_TABLE selected by slot
		Slot					: in	natural range 0 to (TIMING_TABLE'length - 1);	--
		Timeout				: out std_logic																			-- timing reached
	);
end entity;


architecture rtl of io_TimingCounter is
	function transform(vec : T_NATVEC) return T_INTVEC is
    variable Result : T_INTVEC(vec'range);
  begin
		assert (not MY_VERBOSE) report "TIMING_TABLE (transformed):" severity NOTE;
    for i in vec'range loop
			Result(i)	 := vec(i) - 1;
			assert (not MY_VERBOSE) report "  " & integer'image(i) & " - " & INTEGER'image(Result(i)) severity NOTE;
		end loop;
		return Result;
  end;

	constant TIMING_TABLE2	: T_INTVEC		:= transform(TIMING_TABLE);
	constant TIMING_MAX			: natural			:= imax(TIMING_TABLE2);
	constant COUNTER_BITS		: natural			:= log2ceilnz(TIMING_MAX + 1);

	signal Counter_s				: signed(COUNTER_BITS downto 0)		:= to_signed(TIMING_TABLE2(0), COUNTER_BITS + 1);

begin
	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Load = '1') then
				Counter_s		<= to_signed(TIMING_TABLE2(Slot), Counter_s'length);
			elsif ((Enable = '1') and (Counter_s(Counter_s'high) = '0')) then
				Counter_s	<= Counter_s - 1;
			end if;
		end if;
	end process;

	Timeout <= Counter_s(Counter_s'high);
end;
