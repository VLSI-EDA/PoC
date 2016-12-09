-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Entity:					TODO
--
-- Description:
-- -------------------------------------
-- .. TODO:: No documentation available.
--
-- License:
-- =============================================================================
-- Copyright 2007-2014 Technische Universitaet Dresden - Germany
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

library PoC;
use			PoC.utils.all;


entity filter_mean is
	generic (
		TAPS						: positive				:= 4;				--
		INIT						: std_logic				:= '1';			--
		ADD_OUTPUT_REG	: boolean					:= FALSE		--
	);
	port (
		Clock						: in	std_logic;							-- clock
		DataIn					: in	std_logic;							-- data to filter
		DataOut					: out	std_logic								-- filtered signal
	);
end entity;


architecture rtl of filter_mean is
	signal Delays			: std_logic_vector(TAPS - 1 downto 0)		:= (others => INIT);
	signal FilterOut	: std_logic;

begin
	Delays					<= Delays(Delays'high - 1 downto 0) & DataIn when rising_edge(Clock);

	process(Delays)
		variable popcnt : natural range 0 to Delays'length;
	begin
		popcnt := 0;

		for I in Delays'range loop
			if (Delays(I) = '1') then
				popcnt	:= popcnt + 1;
			end if;
		end loop;

		FilterOut	<= to_sl(popcnt > (Delays'length - popcnt));
	end process;

	genOutReg0 : if not ADD_OUTPUT_REG generate
		DataOut				<= FilterOut;
	end generate;
	genOutReg1 : if ADD_OUTPUT_REG generate
		signal FilterOut_d	: std_logic	:= INIT;
	begin
		FilterOut_d		<= FilterOut when rising_edge(Clock);
		DataOut				<= FilterOut_d;
	end generate;
end;
