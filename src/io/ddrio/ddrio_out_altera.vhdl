-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Martin Zabel
--									Patrick Lehmann
--
-- Entity:					Instantiates Chip-Specific DDR Output Registers for Altera FPGAs.
--
-- Description:
-- -------------------------------------
--	See PoC.io.ddrio.out for interface description.
--
-- License:
-- =============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany,
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

library	IEEE;
use			IEEE.std_logic_1164.all;

library	Altera_mf;
use			Altera_mf.Altera_MF_Components.all;

library poc;
use poc.utils.all;

entity ddrio_out_altera is
	generic (
		NO_OUTPUT_ENABLE		: boolean			:= false;
		BITS								: positive;
		INIT_VALUE					: bit_vector	:= x"FFFFFFFF"
	);
	port (
		Clock					: in	std_logic;
		ClockEnable		: in	std_logic;
		OutputEnable	: in	std_logic;
		DataOut_high	: in	std_logic_vector(BITS - 1 downto 0);
		DataOut_low		: in	std_logic_vector(BITS - 1 downto 0);
		Pad						: out	std_logic_vector(BITS - 1 downto 0)
	);
end entity;


architecture rtl of ddrio_out_altera is
	signal oe : std_logic;
begin
	-- The real output enable;
	oe <= '1' when NO_OUTPUT_ENABLE else OutputEnable;

	-- One instantiation for each output pin is required to support different
	-- initialization values. Note, that POWER_UP_HIGH controls both output data
	-- and output enable registers. INIT_VALUE is only relevant if
	-- NO_OUTPUT_ENABLE = true.
	gen : for i in 0 to BITS - 1 generate
	begin
		off : altddio_out
			generic map (
				OE_REG 				=> ite(NO_OUTPUT_ENABLE, "UNREGISTERED", "REGISTERED"),
				POWER_UP_HIGH	=> ite(NO_OUTPUT_ENABLE,
														 ite(INIT_VALUE(i) = '1', "ON", "OFF"),
														 "OFF"),
				WIDTH					=> 1
			)
			port map (
				outclock		=> Clock,
				outclocken	=> ClockEnable,
				oe					=> oe,
				datain_h(0)	=> DataOut_high(i),
				datain_l(0)	=> DataOut_low(i),
				dataout(0)	=> Pad(i)
			);
	end generate;

end architecture;
