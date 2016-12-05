-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Package:					VHDL package for component declarations, types and
--									functions associated to the PoC.io.iic namespace
--
-- Description:
-- -------------------------------------
--		For detailed documentation see below.
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany,
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
use			PoC.utils.all;
use			PoC.physical.all;
use			PoC.io.all;


package iic is
	type T_IO_IIC_SERIAL is record
		Clock : T_IO_TRISTATE;
		Data  : T_IO_TRISTATE;
	end record;

	type T_IO_IIC_SERIAL_PCB is record
		Clock : std_logic;
		Data  : std_logic;
	end record;

	type T_IO_IIC_SERIAL_VECTOR     is array(natural range <>) of T_IO_IIC_SERIAL;
	type T_IO_IIC_SERIAL_PCB_VECTOR is array(natural range <>) of T_IO_IIC_SERIAL_PCB;

	-- Drive std_logic values from Tri-State signals and in reverse.
	-- Use this procedure only in simulation
	procedure io_tristate_driver (
		signal pad  : inout T_IO_IIC_SERIAL_PCB;
		signal iot  : inout T_IO_IIC_SERIAL
	);

	-- IICBusController
	-- ==========================================================================================================================================================
	type T_IO_IIC_BUSMODE is (
		IO_IIC_BUSMODE_SMBUS,							--   100 kHz; additional timing restrictions
		IO_IIC_BUSMODE_STANDARDMODE,			--   100 kHz
		IO_IIC_BUSMODE_FASTMODE,					--   400 kHz
		IO_IIC_BUSMODE_FASTMODEPLUS,			-- 1.000 kHz
		IO_IIC_BUSMODE_HIGHSPEEDMODE,			-- 3.400 kHz
		IO_IIC_BUSMODE_ULTRAFASTMODE			-- 5.000 kHz; unidirectional
	);

	type T_IO_IICBUS_COMMAND is (
		IO_IICBUS_CMD_NONE,
		IO_IICBUS_CMD_SEND_START_CONDITION,
		IO_IICBUS_CMD_SEND_RESTART_CONDITION,
		IO_IICBUS_CMD_SEND_STOP_CONDITION,
		IO_IICBUS_CMD_SEND_LOW,
		IO_IICBUS_CMD_SEND_HIGH,
		IO_IICBUS_CMD_RECEIVE
	);

	type T_IO_IICBUS_STATUS is (
		IO_IICBUS_STATUS_RESETING,
		IO_IICBUS_STATUS_IDLE,
		IO_IICBUS_STATUS_SENDING,
		IO_IICBUS_STATUS_SEND_COMPLETE,
		IO_IICBUS_STATUS_RECEIVING,
		IO_IICBUS_STATUS_RECEIVED_START_CONDITION,
		IO_IICBUS_STATUS_RECEIVED_STOP_CONDITION,
		IO_IICBUS_STATUS_RECEIVED_LOW,
		IO_IICBUS_STATUS_RECEIVED_HIGH,
		IO_IICBUS_STATUS_ERROR,
		IO_IICBUS_STATUS_BUS_ERROR
	);

	-- IICController
	-- ==========================================================================================================================================================
	type T_IO_IIC_COMMAND is (
		IO_IIC_CMD_NONE,
		IO_IIC_CMD_QUICKCOMMAND_READ,	-- use this to check for an device address
		IO_IIC_CMD_QUICKCOMMAND_WRITE,
		IO_IIC_CMD_SEND_BYTES,
		IO_IIC_CMD_RECEIVE_BYTES,
		IO_IIC_CMD_PROCESS_CALL
	);

	type T_IO_IIC_STATUS is (
		IO_IIC_STATUS_IDLE,
		IO_IIC_STATUS_EXECUTING,
		IO_IIC_STATUS_EXECUTE_OK,
		IO_IIC_STATUS_EXECUTE_FAILED,
		IO_IIC_STATUS_SENDING,
		IO_IIC_STATUS_SEND_COMPLETE,
		IO_IIC_STATUS_RECEIVING,
		IO_IIC_STATUS_RECEIVE_COMPLETE,
		IO_IIC_STATUS_CALLING,
		IO_IIC_STATUS_CALL_COMPLETE,
		IO_IIC_STATUS_ERROR
	);

	type T_IO_IIC_ERROR is (
		IO_IIC_ERROR_NONE,
		IO_IIC_ERROR_ADDRESS_ERROR,
		IO_IIC_ERROR_ACK_ERROR,
		IO_IIC_ERROR_BUS_ERROR,
		IO_IIC_ERROR_FSM
	);

	type T_IO_IIC_COMMAND_VECTOR	is array(natural range <>) of T_IO_IIC_COMMAND;
	type T_IO_IIC_STATUS_VECTOR		is array(natural range <>) of T_IO_IIC_STATUS;
	type T_IO_IIC_ERROR_VECTOR		is array(natural range <>) of T_IO_IIC_ERROR;
end package;


package body iic is
	procedure io_tristate_driver (
		signal pad  : inout T_IO_IIC_SERIAL_PCB;
		signal iot  : inout T_IO_IIC_SERIAL
	) is
	begin
		pad.Clock   <= ite((iot.Clock.t = '1'), 'Z', iot.Clock.o);
		iot.Clock.i <= pad.Clock;
		iot.Clock.t <= 'Z';     -- drive all record members
		iot.Clock.o <= 'Z';     -- drive all record members
		pad.Data    <= ite((iot.Data.t = '1'), 'Z', iot.Data.o);
		iot.Data.i  <= pad.Data;
		iot.Data.t  <= 'Z';     -- drive all record members
		iot.Data.o  <= 'Z';     -- drive all record members
	end procedure;
end package body;
