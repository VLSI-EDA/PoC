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

	type T_IO_7SEGMENT_CHAR is (
		IO_7SEGMENT_CHAR_0, IO_7SEGMENT_CHAR_1, IO_7SEGMENT_CHAR_2, IO_7SEGMENT_CHAR_3,
		IO_7SEGMENT_CHAR_4, IO_7SEGMENT_CHAR_5, IO_7SEGMENT_CHAR_6, IO_7SEGMENT_CHAR_7,
		IO_7SEGMENT_CHAR_8, IO_7SEGMENT_CHAR_9, IO_7SEGMENT_CHAR_A, IO_7SEGMENT_CHAR_B,
		IO_7SEGMENT_CHAR_C, IO_7SEGMENT_CHAR_D, IO_7SEGMENT_CHAR_E, IO_7SEGMENT_CHAR_F,
		IO_7SEGMENT_CHAR_H, IO_7SEGMENT_CHAR_O, IO_7SEGMENT_CHAR_U, IO_7SEGMENT_CHAR_MINUS
	);
	
	type T_IO_7SEGMENT_CHAR_ENCODING is array(T_IO_7SEGMENT_CHAR) of STD_LOGIC_VECTOR(6 downto 0);
	
	--constant C_IO_7SEGMENT_CHAR_ENCODING		: T_IO_7SEGMENT_CHAR_ENCODING := (
		--IO_7SEGMENT_CHAR_0
		--IO_7SEGMENT_CHAR_1
		--IO_7SEGMENT_CHAR_2
		--IO_7SEGMENT_CHAR_3
		--IO_7SEGMENT_CHAR_4
		--IO_7SEGMENT_CHAR_5
		--IO_7SEGMENT_CHAR_6
		--IO_7SEGMENT_CHAR_7
		--IO_7SEGMENT_CHAR_8
		--IO_7SEGMENT_CHAR_9
		--IO_7SEGMENT_CHAR_A
		--IO_7SEGMENT_CHAR_B
		--IO_7SEGMENT_CHAR_C
		--IO_7SEGMENT_CHAR_D
		--IO_7SEGMENT_CHAR_E
		--IO_7SEGMENT_CHAR_F
		--IO_7SEGMENT_CHAR_H
		--IO_7SEGMENT_CHAR_O
		--IO_7SEGMENT_CHAR_U
		--IO_7SEGMENT_CHAR_MINUS
	--);

	function io_7SegmentDisplayEncoding(hex	: STD_LOGIC_VECTOR(3 downto 0); dot : STD_LOGIC := '0'; WITH_DOT : BOOLEAN := FALSE)	return STD_LOGIC_VECTOR;
	function io_7SegmentDisplayEncoding(digit	: T_BCD; dot : STD_LOGIC := '0'; WITH_DOT : BOOLEAN := FALSE)												return STD_LOGIC_VECTOR;
	
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

end package;


package body io is
	function io_7SegmentDisplayEncoding(hex	: STD_LOGIC_VECTOR(3 downto 0); dot : STD_LOGIC := '0'; WITH_DOT : BOOLEAN := FALSE) return STD_LOGIC_VECTOR is
		constant DOT_INDEX	: POSITIVE	:= ite(WITH_DOT, 7, 6);
		variable Result			: STD_LOGIC_VECTOR(ite(WITH_DOT, 7, 6) downto 0);
	begin
		Result(DOT_INDEX)		:= dot;
		case hex is							-- segments:			GFEDCBA			--	Segment Pos.
			when x"0" =>		Result(6 downto 0)	:= "0111111";		--		 AAA     
			when x"1" =>		Result(6 downto 0)	:= "0000110";		--		F   B    
			when x"2" =>		Result(6 downto 0)	:= "1011011";		--		F   B    
			when x"3" =>		Result(6 downto 0)	:= "1001111";		--		 GGG     
			when x"4" =>		Result(6 downto 0)	:= "1100110";		--		E   C    
			when x"5" =>		Result(6 downto 0)	:= "1101101";		--		E   C    
			when x"6" =>		Result(6 downto 0)	:= "1111101";		--		 DDD  DOT
			when x"7" =>		Result(6 downto 0)	:= "0000111";		--	
			when x"8" =>		Result(6 downto 0)	:= "1111111";		--	Index Pos.
			when x"9" =>		Result(6 downto 0)	:= "1101111";		--		 000   
			when x"A" =>		Result(6 downto 0)	:= "1110111";		--		5   1  
			when x"B" =>		Result(6 downto 0)	:= "1111100";		--		5   1  
			when x"C" =>		Result(6 downto 0)	:= "0111001";		--		 666   
			when x"D" =>		Result(6 downto 0)	:= "1011110";		--		4   2  
			when x"E" =>		Result(6 downto 0)	:= "1111001";		--		4   2  
			when x"F" =>		Result(6 downto 0)	:= "1110001";		--		 333  7
			when others =>	Result(6 downto 0)	:= "XXXXXXX";		--	
		end case;
		return Result;
	end function;

	function io_7SegmentDisplayEncoding(digit	: T_BCD; dot : STD_LOGIC := '0'; WITH_DOT : BOOLEAN := FALSE) return STD_LOGIC_VECTOR is
	begin
		return io_7SegmentDisplayEncoding(std_logic_vector(digit), dot, WITH_DOT);
	end function;
end package body;
