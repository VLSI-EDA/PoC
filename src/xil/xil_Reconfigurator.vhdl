-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Entity:				 	Reconfiguration engine for DRP enabled Xilinx primtives
--
-- Description:
-- -------------------------------------
-- Many complex primitives in a Xilinx device offer a Dynamic Reconfiguration
-- Port (DRP) to reconfigure a primitive at runtime without reconfiguring the
-- whole FPGA.
--
-- This module is a DRP master that can be pre-configured at compile time with
-- different configuration sets. The configuration sets are mapped into a ROM.
-- The user can select a stored configuration with ``ConfigSelect``. Sending a
-- strobe to ``Reconfig`` will start the reconfiguration process. The operation
-- completes with another strobe on ``ReconfigDone``.
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
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
use			PoC.config.all;
use			PoC.utils.all;
use			PoC.vectors.all;
use			PoC.physical.all;
use			PoC.xil.all;


entity xil_Reconfigurator is
	generic (
		DEBUG						: boolean										:= FALSE;																				--
		CLOCK_FREQ			: FREQ											:= 100 MHz;																			--
		CONFIG_ROM			: in	T_XIL_DRP_CONFIG_ROM	:= (0 downto 0 => C_XIL_DRP_CONFIG_SET_EMPTY)		--
	);
	port (
		Clock						: in	std_logic;
		Reset						: in	std_logic;

		Reconfig				: in	std_logic;																														--
		ReconfigDone		: out	std_logic;																														--
		ConfigSelect		: in	std_logic_vector(log2ceilnz(CONFIG_ROM'length) - 1 downto 0);					--

		DRP_en					: out	std_logic;																														--
		DRP_Address			: out	T_XIL_DRP_ADDRESS;																										--
		DRP_we					: out	std_logic;																														--
		DRP_DataIn			: in	T_XIL_DRP_DATA;																												--
		DRP_DataOut			: out	T_XIL_DRP_DATA;																												--
		DRP_Ack					: in	std_logic																															--
	);
end entity;


architecture rtl of xil_Reconfigurator is
	attribute KEEP								: boolean;
	attribute FSM_ENCODING				: string;
	attribute signal_ENCODING			: string;

	type T_STATE is (
		ST_IDLE,
		ST_READ_BEGIN,	ST_READ_WAIT,
		ST_WRITE_BEGIN,	ST_WRITE_WAIT,
		ST_DONE
	);

	-- DualConfiguration - Statemachine
	signal State											: T_STATE																:= ST_IDLE;
	signal NextState									: T_STATE;
	attribute FSM_ENCODING	of State	: signal is ite(DEBUG, "gray", "speed1");

	signal DataBuffer_en							: std_logic;
	signal DataBuffer_d								: T_XIL_DRP_DATA												:= (others => '0');

	signal ROM_Entry									: T_XIL_DRP_CONFIG;
	signal ROM_LastConfigWord					: std_logic;

	signal ConfigSelect_d 						: std_logic_vector(ConfigSelect'range);

	constant CONFIGINDEX_BITS					: positive															:= log2ceilnz(CONFIG_ROM'length);
	signal ConfigIndex_rst						: std_logic;
	signal ConfigIndex_en							: std_logic;
	signal ConfigIndex_us							: unsigned(CONFIGINDEX_BITS - 1 downto 0);

	attribute KEEP of ROM_LastConfigWord	: signal is DEBUG;

begin
	-- configuration ROM
	blkCONFIG_ROM : block
		signal SetIndex 						: integer range 0 to CONFIG_ROM'high;
		signal RowIndex 						: T_XIL_DRP_CONFIG_INDEX;

		attribute KEEP of SetIndex	: signal is DEBUG;
		attribute KEEP of RowIndex	: signal is DEBUG;
	begin
		SetIndex							<= to_index(ConfigSelect_d, CONFIG_ROM'high);
		RowIndex							<= to_index(ConfigIndex_us, T_XIL_DRP_CONFIG_INDEX'high);
		ROM_Entry							<= CONFIG_ROM(SetIndex).Configs(RowIndex);
		ROM_LastConfigWord		<= to_sl(RowIndex = CONFIG_ROM(SetIndex).LastIndex);
	end block;

	-- configuration index counter
	process(Clock)
	begin
		if rising_edge(Clock) then
			if (ConfigIndex_rst = '1') then
				ConfigIndex_us		<= (others => '0');
				ConfigSelect_d		<= ConfigSelect;
			elsif (ConfigIndex_en = '1') then
				ConfigIndex_us		<= ConfigIndex_us + 1;
			end if;
		end if;
	end process;

	-- data buffer for DRP configuration words
	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Reset = '1') then
				DataBuffer_d	<= (others => '0');
			elsif (DataBuffer_en = '1') then
				DataBuffer_d	<= ((DRP_DataIn			and not ROM_Entry.Mask) or
													(ROM_Entry.Data	and			ROM_Entry.Mask));
			end if;
		end if;
	end process;

	-- assign DRP signals
	DRP_Address						<= ROM_Entry.Address;
	DRP_DataOut						<= DataBuffer_d;

	-- DRP read-modify-write statemachine
	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Reset = '1') then
				State			<= ST_IDLE;
			else
				State			<= NextState;
			end if;
		end if;
	end process;

	process(State, Reconfig, ROM_LastConfigWord, DRP_Ack	)
	begin
		NextState								<= State;

		ReconfigDone						<= '0';

		-- Dynamic Reconfiguration Port
		DRP_en									<= '0';
		DRP_we									<= '0';

		-- internal modules
		ConfigIndex_rst					<= '0';
		ConfigIndex_en					<= '0';
		DataBuffer_en						<= '0';

		case State is
			when ST_IDLE =>
				if (Reconfig = '1') then
					ConfigIndex_rst		<= '1';
					NextState					<= ST_READ_BEGIN;
				end if;

			when ST_READ_BEGIN =>
				DRP_en							<= '1';
				DRP_we							<= '0';
				NextState						<= ST_READ_WAIT;

			when ST_READ_WAIT =>
				if (DRP_Ack = '1') then
					DataBuffer_en			<= '1';
					NextState					<= ST_WRITE_BEGIN;
				end if;

			when ST_WRITE_BEGIN =>
				DRP_en							<= '1';
				DRP_we							<= '1';
				NextState						<= ST_WRITE_WAIT;

			when ST_WRITE_WAIT =>
				if (DRP_Ack = '1') then
					if (ROM_LastConfigWord = '1') then
						NextState				<= ST_DONE;
					else
						ConfigIndex_en	<= '1';
						NextState				<= ST_READ_BEGIN;
					end if;
				end if;

			when ST_DONE =>
				ReconfigDone				<= '1';
				NextState						<= ST_IDLE;

		end case;
	end process;
end architecture;
