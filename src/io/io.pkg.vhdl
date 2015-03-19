-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Authors:					Patrick Lehmann
-- 
-- Package:					VHDL package for component declarations, types and
--									functions associated to the PoC.io namespace
--
-- Description:
-- ------------------------------------
--		For detailed documentation see below.
--
-- License:
-- ============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany,
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
use			PoC.my_config.all;
use			PoC.utils.all;
use			PoC.physical.all;


package io is
	-- not yet supported by Xilinx ISE Simulator - the subsignal I (with reverse direction) is always 'U'
	-- so use this record only in pure synthesis environments
	type T_IO_TRISTATE is record
		I			: STD_LOGIC;					-- input / from device to FPGA
		O			: STD_LOGIC;					-- output / from FPGA to device
		T			: STD_LOGIC;					-- output disable / tristate enable
	end record;

	type T_IO_LVDS is record
		P			: STD_LOGIC;
		N			: STD_LOGIC;
	end record;

	type T_IO_TRISTATE_VECTOR	is array(NATURAL range <>) of T_IO_TRISTATE;
	type T_IO_LVDS_VECTOR			is array(NATURAL range <>) of T_IO_LVDS;


	function io_7SegmentDisplayEncoding(hex	: STD_LOGIC_VECTOR(3 downto 0); dot : STD_LOGIC := '0') return STD_LOGIC_VECTOR;
	function io_7SegmentDisplayEncoding(digit	: T_BCD; dot : STD_LOGIC := '0') return STD_LOGIC_VECTOR;
	
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
	
	type T_IO_IIC_COMMAND_VECTOR	is array(NATURAL range <>) of T_IO_IIC_COMMAND;
	type T_IO_IIC_STATUS_VECTOR		is array(NATURAL range <>) of T_IO_IIC_STATUS;
	type T_IO_IIC_ERROR_VECTOR		is array(NATURAL range <>) of T_IO_IIC_ERROR;
	
	
	
	-- MDIOController
	-- ==========================================================================================================================================================
	type T_IO_MDIO_MDIOCONTROLLER_COMMAND is (
		IO_MDIO_MDIOC_CMD_NONE,
		IO_MDIO_MDIOC_CMD_CHECK_ADDRESS,
		IO_MDIO_MDIOC_CMD_READ,
		IO_MDIO_MDIOC_CMD_WRITE,
		IO_MDIO_MDIOC_CMD_ABORT
	);
	
	type T_IO_MDIO_MDIOCONTROLLER_STATUS is (
		IO_MDIO_MDIOC_STATUS_IDLE,
		IO_MDIO_MDIOC_STATUS_CHECKING,
		IO_MDIO_MDIOC_STATUS_CHECK_OK,
		IO_MDIO_MDIOC_STATUS_CHECK_FAILED,
		IO_MDIO_MDIOC_STATUS_READING,
		IO_MDIO_MDIOC_STATUS_READ_COMPLETE,
		IO_MDIO_MDIOC_STATUS_WRITING,
		IO_MDIO_MDIOC_STATUS_WRITE_COMPLETE,
		IO_MDIO_MDIOC_STATUS_ERROR
	);
	
	type T_IO_MDIO_MDIOCONTROLLER_ERROR is (
		IO_MDIO_MDIOC_ERROR_NONE,
		IO_MDIO_MDIOC_ERROR_ADDRESS_NOT_FOUND,
		IO_MDIO_MDIOC_ERROR_FSM
	);
	
	type T_IO_LCDBUS_COMMAND is (
		IO_LCDBUS_CMD_NONE,
		IO_LCDBUS_CMD_READ,
		IO_LCDBUS_CMD_WRITE
	);
	
	type T_IO_LCDBUS_STATUS is (
		IO_LCDBUS_STATUS_IDLE,
		IO_LCDBUS_STATUS_READING,
		IO_LCDBUS_STATUS_WRITING,
		IO_LCDBUS_STATUS_ERROR
	);
	
	-- Subnamespace PoC.io.uart
  -- =========================================================================
	constant C_UART_TYPICAL_BAUDRATES		: T_BAUDVEC		:= (
		 0 =>		 300 Bd,	 1 =>		 600 Bd,	 2 =>		1200 Bd,	 3 =>		1800 Bd,	 4 =>		2400 Bd,
		 5 =>		4000 Bd,	 6 =>		4800 Bd,	 7 =>		7200 Bd,	 8 =>		9600 Bd,	 9 =>	 14400 Bd,
		10 =>	 16000 Bd,	11 =>	 19200 Bd,	12 =>	 28800 Bd,	13 =>	 38400 BD,	14 =>	 51200 Bd,
		15 =>	 56000 Bd,	16 =>	 57600 Bd,	17 =>	 64000 Bd,	18 =>	 76800 Bd,	19 =>	115200 Bd,
		20 =>	128000 Bd,	21 =>	153600 Bd,	22 =>	230400 Bd,	23 =>	250000 Bd,	24 =>	256000 BD,
		25 =>	460800 Bd,	26 =>	500000 Bd,	27 =>	576000 Bd,	28 =>	921600 Bd
	);
	
	function uart_IsTypicalBaudRate(br : BAUD) return BOOLEAN;

  -- Component Declarations
  -- =========================================================================
  component io_FanControl
    generic (
      CLOCK_FREQ_MHZ	: real
    );
    port (
      Clock						: in	STD_LOGIC;
      Reset						: in	STD_LOGIC;

      Fan_PWM					: out	STD_LOGIC;
      Fan_Tacho				: in	STD_LOGIC;

      TachoFrequency	: out	STD_LOGIC_VECTOR(15 downto 0)
    );
	end component;

end io;


package body io is
	function io_7SegmentDisplayEncoding(hex	: STD_LOGIC_VECTOR(3 downto 0); dot : STD_LOGIC := '0') return STD_LOGIC_VECTOR is
		variable Result		: STD_LOGIC_VECTOR(7 downto 0);
	begin
		Result(7)		:= dot;
		case hex is							-- segments:			GFEDCBA
			when x"0" =>		Result(6 downto 0)	:= "0111111";
			when x"1" =>		Result(6 downto 0)	:= "0000110";
			when x"2" =>		Result(6 downto 0)	:= "1011011";
			when x"3" =>		Result(6 downto 0)	:= "1001111";
			when x"4" =>		Result(6 downto 0)	:= "1100110";
			when x"5" =>		Result(6 downto 0)	:= "1101101";
			when x"6" =>		Result(6 downto 0)	:= "1111101";
			when x"7" =>		Result(6 downto 0)	:= "0000111";
			when x"8" =>		Result(6 downto 0)	:= "1111111";
			when x"9" =>		Result(6 downto 0)	:= "1101111";
			when x"A" =>		Result(6 downto 0)	:= "1110111";
			when x"B" =>		Result(6 downto 0)	:= "1111100";
			when x"C" =>		Result(6 downto 0)	:= "0111001";
			when x"D" =>		Result(6 downto 0)	:= "1011110";
			when x"E" =>		Result(6 downto 0)	:= "1111001";
			when x"F" =>		Result(6 downto 0)	:= "1110001";
			when others =>	Result(6 downto 0)	:= "XXXXXXX";
		end case;
		return Result;
	end function;
	
	function io_7SegmentDisplayEncoding(digit	: T_BCD; dot : STD_LOGIC := '0') return STD_LOGIC_VECTOR is
	begin
		return io_7SegmentDisplayEncoding(std_logic_vector(digit), dot);
	end function;

	function uart_IsTypicalBaudRate(br : BAUD) return BOOLEAN is
	begin
		for i in C_UART_TYPICAL_BAUDRATES'range loop
			next when (br /= C_UART_TYPICAL_BAUDRATES(i));
			return TRUE;
		end loop;
		return FALSE;
	end function;
end package body;
