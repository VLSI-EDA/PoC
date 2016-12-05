-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Entity:				 	Digilent Peripherial Module: USB-UART (Pmod_USBUART)
--
-- Description:
-- -------------------------------------
-- This module abstracts a FTDI FT232R USB-UART bridge by instantiating a
-- :doc:`PoC.io.uart.fifo <../uart/uart_fifo>`. The FT232R supports up to
-- 3 MBaud. A synchronous FIFO interface with a 32 words buffer is provided.
-- Hardware flow control (RTS_CTS) is enabled.
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
use			PoC.physical.all;
use			PoC.uart.all;


entity pmod_USBUART is
	generic (
		CLOCK_FREQ		: FREQ		:= 100 MHz;
		BAUDRATE			: BAUD		:= 115200 Bd
	);
	port (
		Clock			: in	std_logic;
		Reset			: in	std_logic;

		TX_put		: in	std_logic;
		TX_Data		: in	std_logic_vector(7 downto 0);
		TX_Full		: out	std_logic;

		RX_Valid	: out	std_logic;
		RX_Data		: out	std_logic_vector(7 downto 0);
		RX_got		: in	std_logic;

		UART_TX		: out	std_logic;
		UART_RX		: in	std_logic;
		UART_RTS	: out	std_logic;
		UART_CTS	: in	std_logic
	);
end entity;


architecture rtl of pmod_USBUART is

begin
	UART : entity PoC.uart_fifo
		generic map (
			CLOCK_FREQ							=> CLOCK_FREQ,
			BAUDRATE								=> BAUDRATE,
			ADD_INPUT_SYNCHRONIZERS	=> TRUE,

			TX_MIN_DEPTH						=> 32,
			TX_ESTATE_BITS					=> 0,
			RX_MIN_DEPTH						=> 32,
			RX_FSTATE_BITS					=> 0,

			FLOWCONTROL							=> UART_FLOWCONTROL_RTS_CTS
		)
		port map (
			Clock			=> Clock,
			Reset			=> Reset,

			TX_put		=> TX_put,
			TX_Data		=> TX_Data,
			TX_Full		=> TX_Full,

			RX_Valid	=> RX_Valid,
			RX_Data		=> RX_Data,
			RX_got		=> RX_got,

			UART_TX		=> UART_TX,
			UART_RX		=> UART_RX,
			UART_RTS	=> UART_RTS,
			UART_CTS	=> UART_CTS
		);
end architecture;
