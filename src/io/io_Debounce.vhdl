-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Patrick Lehmann
--									Thomas B. Preusser
--
-- Entity:				 	Debounce module for BITS many bouncing input pins.
--
-- Description:
-- -------------------------------------
-- This module debounces several input pins preventing input changes
-- following a previous one within the configured ``BOUNCE_TIME`` to pass.
-- Internally, the forwarded state is locked for, at least, this ``BOUNCE_TIME``.
-- As the backing timer is restarted on every input fluctuation, the next
-- passing input update must have seen a stabilized input.
--
-- The parameter ``COMMON_LOCK`` uses a single internal timer for all processed
-- inputs. Thus, all inputs must stabilize before any one may pass changed.
-- This option is usually fully acceptable for user inputs such as push buttons.
--
-- The parameter ``ADD_INPUT_SYNCHRONIZERS`` triggers the optional instantiation
-- of a two-FF input synchronizer on each input bit.
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
use			IEEE.numeric_std.all;

library PoC;
use			PoC.utils.all;
use			PoC.physical.all;


entity io_Debounce is
  generic (
    CLOCK_FREQ 							: FREQ;
    BOUNCE_TIME							: time;
    BITS                    : positive := 1;
		INIT										: std_logic_vector		:= x"00000000";	-- initial state of Output
    ADD_INPUT_SYNCHRONIZERS : boolean  := true;
    COMMON_LOCK             : boolean  := false
  );
  port (
    Clock		: in	std_logic;
		Reset		: in	std_logic							:= '0';
    Input		: in	std_logic_vector(BITS-1 downto 0);
    Output	: out	std_logic_vector(BITS-1 downto 0) := resize(descend(INIT), BITS)
  );
end entity;


architecture rtl of io_Debounce is
	-- Number of required locking cycles
	constant LOCK_COUNT_X : integer := TimingToCycles(BOUNCE_TIME, CLOCK_FREQ) - 1;

	-- Input Refinements
  signal sync		: std_logic_vector(Input'range);										-- Synchronized
  signal prev		: std_logic_vector(Input'range) := (others => '0');	-- Delayed
	signal active	: std_logic_vector(Input'range);										-- Allow Output Updates

begin
  -----------------------------------------------------------------------------
  -- Input Synchronization
  genNoSync: if not ADD_INPUT_SYNCHRONIZERS generate
    sync <= Input;
  end generate;
  genSync: if ADD_INPUT_SYNCHRONIZERS generate
    sync_i : entity PoC.sync_Bits
      generic map (
        BITS => BITS,
				INIT => INIT
      )
      port map (
        Clock  => Clock,  	-- Clock to be synchronized to
        Input  => Input,  	-- Data to be synchronized
        Output => sync  		-- synchronised data
      );
  end generate;

	-----------------------------------------------------------------------------
	-- Bounce Filter
	process(Clock)
	begin
		if rising_edge(Clock) then
			prev <= sync;
			if (Reset = '1') then
				Output <= sync;
			else
				for i in Output'range loop
					if active(i) = '1' then
						Output(i) <= sync(i);
					end if;
				end loop;
			end if;
		end if;
	end process;

	genNoLock: if LOCK_COUNT_X <= 0 generate
		active <= (others => '1');
	end generate genNoLock;
	genLock: if LOCK_COUNT_X > 0 generate
		constant LOCKS	: positive := ite(COMMON_LOCK, 1, BITS);

		signal toggle		: std_logic_vector(LOCKS-1 downto 0);
		signal locked		: std_logic_vector(LOCKS-1 downto 0);
	begin

    genOneLock: if COMMON_LOCK generate
      toggle(0) <= '1' when prev /= sync else '0';
      active    <= (others => not locked(0));
    end generate genOneLock;
    genManyLocks: if not COMMON_LOCK generate
      toggle <= prev xor sync;
      active <= not locked;
    end generate genManyLocks;

		genLocks: for i in 0 to LOCKS-1 generate
			signal Lock : signed(log2ceil(LOCK_COUNT_X+1) downto 0) := (others => '0');
		begin
			process(Clock)
			begin
				if rising_edge(Clock) then
					if (Reset = '1') then
						Lock <= (others => '0');
					else
						if toggle(i) = '1' then
							Lock <= to_signed(-LOCK_COUNT_X, Lock'length);
						elsif locked(i) = '1' then
							Lock <= Lock + 1;
						end if;
					end if;
				end if;
			end process;
			locked(i) <= Lock(Lock'left);
		end generate genLocks;
	end generate genLock;

end;
