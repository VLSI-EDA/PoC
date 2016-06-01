-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- ============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Module:				 	Generic arbiter
--
-- Description:
-- ------------------------------------
--		This module implements a generic arbiter. It currently support the
--		following arbitration strategies:
--			- Round Robin (RR)
--
-- License:
-- ============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany
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
-- ============================================================================

library IEEE;
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.NUMERIC_STD.all;

library PoC;
use			PoC.utils.all;


entity bus_Arbiter is
	generic (
		STRATEGY									: STRING										:= "RR";			-- RR, LOT
		PORTS											: POSITIVE									:= 1;
		WEIGHTS										: T_INTVEC									:= (0 => 1);
		OUTPUT_REG								: BOOLEAN										:= TRUE
	);
	port (
		Clock											: in	STD_LOGIC;
		Reset											: in	STD_LOGIC;

		Arbitrate									: in	STD_LOGIC;
		Request_Vector						: in	STD_LOGIC_VECTOR(PORTS - 1 downto 0);

		Arbitrated								: out	STD_LOGIC;
		Grant_Vector							: out	STD_LOGIC_VECTOR(PORTS - 1 downto 0);
		Grant_Index								: out	STD_LOGIC_VECTOR(log2ceilnz(PORTS) - 1 downto 0)
	);
end;


architecture rtl of bus_Arbiter is
	attribute KEEP										: BOOLEAN;
	attribute FSM_ENCODING						: STRING;

begin

	-- Assert STRATEGY for known strings
	-- ==========================================================================================================================================================
	assert ((STRATEGY = "RR") OR (STRATEGY = "LOT"))
		report "Unknown arbiter strategy." severity FAILURE;

	-- Round Robin Arbiter
	-- ==========================================================================================================================================================
	genRR : if (STRATEGY = "RR") generate
		signal RequestLeft								: UNSIGNED(PORTS - 1 downto 0);
		signal SelectLeft									: UNSIGNED(PORTS - 1 downto 0);
		signal SelectRight								: UNSIGNED(PORTS - 1 downto 0);

		signal ChannelPointer_en					: STD_LOGIC;
		signal ChannelPointer							: STD_LOGIC_VECTOR(PORTS - 1 downto 0);
		signal ChannelPointer_d						: STD_LOGIC_VECTOR(PORTS - 1 downto 0)								:= to_slv(1, PORTS);
		signal ChannelPointer_nxt					: STD_LOGIC_VECTOR(PORTS - 1 downto 0);

	begin

		ChannelPointer_en		<= Arbitrate;

		RequestLeft					<= (not ((unsigned(ChannelPointer_d) - 1) or unsigned(ChannelPointer_d))) and unsigned(Request_Vector);
		SelectLeft					<= (unsigned(not RequestLeft) + 1)		and RequestLeft;
		SelectRight					<= (unsigned(not Request_Vector) + 1)	and unsigned(Request_Vector);
		ChannelPointer_nxt	<= std_logic_vector(ite((RequestLeft = (RequestLeft'range => '0')), SelectRight, SelectLeft));

		-- generate ChannelPointer register and unregistered outputs
		genREG0 : if (OUTPUT_REG = FALSE) generate
			process(Clock)
			begin
				if rising_edge(Clock) then
					if (Reset = '1') then
						ChannelPointer_d		<= to_slv(1, PORTS);
					elsif (ChannelPointer_en = '1') then
						ChannelPointer_d		<= ChannelPointer_nxt;
					end if;
				end if;
			end process;

			Arbitrated				<= Arbitrate;
			Grant_Vector			<= ChannelPointer_nxt;
			Grant_Index				<= std_logic_vector(onehot2bin(ChannelPointer_nxt));
		end generate;

		-- generate ChannelPointer register and registered outputs
		genREG1 : if (OUTPUT_REG = TRUE) generate
			signal ChannelPointer_bin_d				: STD_LOGIC_VECTOR(log2ceilnz(PORTS) - 1 downto 0)		:= to_slv(0, log2ceilnz(PORTS) - 1);
		begin
			process(Clock)
			begin
				if rising_edge(Clock) then
					if (Reset = '1') then
						ChannelPointer_d			<= to_slv(1, PORTS);
						ChannelPointer_bin_d	<= to_slv(0, log2ceilnz(PORTS) - 1);
					elsif (ChannelPointer_en = '1') then
						ChannelPointer_d			<= ChannelPointer_nxt;
						ChannelPointer_bin_d	<= std_logic_vector(onehot2bin(ChannelPointer_nxt));
					end if;
				end if;
			end process;

			Arbitrated				<= Arbitrate when rising_edge(Clock);
			Grant_Vector			<= ChannelPointer_d;
			Grant_Index				<= ChannelPointer_bin_d;
		end generate;
	end generate;

	-- Lottery Arbiter
	-- ==========================================================================================================================================================
--	genLOT : if (STRATEGY = "RR") generate
--	begin
--
--	end generate;
end architecture;
