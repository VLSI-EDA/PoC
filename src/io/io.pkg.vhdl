-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Package:					VHDL package for component declarations, types and
--									functions associated to the PoC.io namespace
--
-- Description:
-- -------------------------------------
--		For detailed documentation see below.
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

library IEEE;
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.NUMERIC_STD.all;

library PoC;
use			PoC.utils.all;
use			PoC.physical.all;


package io is
	-- Do not use this type for ``inout`` ports of synthesizable IP cores to drive
	-- values in both directions, see also
	-- :ref:`ISSUES:General:inout_records`.
	type T_IO_TRISTATE is record
		I			: std_logic;					-- input / from device to FPGA
		O			: std_logic;					-- output / from FPGA to device
		T			: std_logic;					-- output disable / tristate enable
	end record;

	type T_IO_LVDS is record
		P			: std_logic;
		N			: std_logic;
	end record;

	-- Do not use this type for ``inout`` ports of synthesizable IP cores to drive
	-- values in both directions, see also
	-- :ref:`ISSUES:General:inout_records`.
	type T_IO_TRISTATE_VECTOR	is array(natural range <>) of T_IO_TRISTATE;

	type T_IO_LVDS_VECTOR			is array(natural range <>) of T_IO_LVDS;

	type T_IO_DATARATE is (IO_DATARATE_SDR, IO_DATARATE_DDR, IO_DATARATE_QDR);

	-- Drive a std_logic_vector from a Tri-State bus and in reverse.
	-- Use this procedure only in simulation, see also
	-- :ref:`ISSUES:General:inout_records`.
	procedure io_tristate_driver (
		signal pad      : inout std_logic_vector;
		signal tristate : inout T_IO_TRISTATE_VECTOR
	);

	type T_IO_7SEGMENT_CHAR is (
		IO_7SEGMENT_CHAR_0, IO_7SEGMENT_CHAR_1, IO_7SEGMENT_CHAR_2, IO_7SEGMENT_CHAR_3,
		IO_7SEGMENT_CHAR_4, IO_7SEGMENT_CHAR_5, IO_7SEGMENT_CHAR_6, IO_7SEGMENT_CHAR_7,
		IO_7SEGMENT_CHAR_8, IO_7SEGMENT_CHAR_9, IO_7SEGMENT_CHAR_A, IO_7SEGMENT_CHAR_B,
		IO_7SEGMENT_CHAR_C, IO_7SEGMENT_CHAR_D, IO_7SEGMENT_CHAR_E, IO_7SEGMENT_CHAR_F,
		IO_7SEGMENT_CHAR_H, IO_7SEGMENT_CHAR_O, IO_7SEGMENT_CHAR_U, IO_7SEGMENT_CHAR_MINUS
	);

	type T_IO_7SEGMENT_CHAR_ENCODING is array(T_IO_7SEGMENT_CHAR) of std_logic_vector(6 downto 0);

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

	function io_7SegmentDisplayEncoding(hex	: std_logic_vector(3 downto 0); dot : std_logic := '0'; WITH_DOT : boolean := FALSE)	return std_logic_vector;
	function io_7SegmentDisplayEncoding(digit	: T_BCD; dot : std_logic := '0'; WITH_DOT : boolean := FALSE)												return std_logic_vector;


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
		IO_LCDBUS_STATUS_RESETTING,
		IO_LCDBUS_STATUS_IDLE,
		IO_LCDBUS_STATUS_READING,
		IO_LCDBUS_STATUS_READ_COMPLETE,
		IO_LCDBUS_STATUS_WRITING,
		IO_LCDBUS_STATUS_WRITE_COMPLETE,
		IO_LCDBUS_STATUS_ERROR
	);

  -- Component Declarations
  -- =========================================================================
  component io_FanControl
    generic (
      CLOCK_FREQ_MHZ	: real
    );
    port (
      Clock						: in	std_logic;
      Reset						: in	std_logic;

      Fan_PWM					: out	std_logic;
      Fan_Tacho				: in	std_logic;

      TachoFrequency	: out	std_logic_vector(15 downto 0)
    );
	end component;

end package;


package body io is
	procedure io_tristate_driver (
		signal pad      : inout std_logic_vector;
		signal tristate : inout T_IO_TRISTATE_VECTOR
	) is
	begin
		for k in pad'range loop
			pad(k)        <= ite((tristate(k).t = '1'), 'Z', tristate(k).o);
			tristate(k).i <= pad(k);
			-- As defined in IEEE Std. 1076-2008 para. 2.1.1.2: "a subprogram
			-- contains a driver for each formal signal parameter of mode out or
			-- inout". This driver will drive 'U' if the following 'Z' drivers are
			-- missed. Driving 'U' would lead to an effective value of 'U' which is
			-- not intended, see also :ref:`ISSUES:General:inout_records`.
			tristate(k).t <= 'Z';
			tristate(k).o <= 'Z';
		end loop;
	end procedure;

	function io_7SegmentDisplayEncoding(hex	: std_logic_vector(3 downto 0); dot : std_logic := '0'; WITH_DOT : boolean := FALSE) return std_logic_vector is
		constant DOT_INDEX	: positive	:= ite(WITH_DOT, 7, 6);
		variable Result			: std_logic_vector(ite(WITH_DOT, 7, 6) downto 0);
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

	function io_7SegmentDisplayEncoding(digit	: T_BCD; dot : std_logic := '0'; WITH_DOT : boolean := FALSE) return std_logic_vector is
	begin
		return io_7SegmentDisplayEncoding(std_logic_vector(digit), dot, WITH_DOT);
	end function;
end package body;
