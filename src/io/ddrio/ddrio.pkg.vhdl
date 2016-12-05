-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Martin Zabel
--									Patrick Lehmann
--
-- Package:					VHDL package for component declarations, types and
--									functions associated to the PoC.io.ddrio namespace
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

library	IEEE;
use			IEEE.std_logic_1164.all;


package ddrio is
	component ddrio_in is
		generic (
			BITS					: positive;
			INIT_VALUE		: bit_vector	:= x"FFFFFFFF"
		);
		port (
			Clock				: in		std_logic;
			ClockEnable : in		std_logic;
			DataIn_high : out		std_logic_vector(BITS - 1 downto 0);
			DataIn_low	: out		std_logic_vector(BITS - 1 downto 0);
			Pad					: in 		std_logic_vector(BITS - 1 downto 0));
	end component;

	component ddrio_inout is
		generic (
			BITS 					 : positive);
		port (
			ClockOut			 : in		 std_logic;
			ClockOutEnable : in		 std_logic;
			OutputEnable	 : in		 std_logic;
			DataOut_high	 : in		 std_logic_vector(BITS - 1 downto 0);
			DataOut_low		 : in		 std_logic_vector(BITS - 1 downto 0);
			ClockIn				 : in		 std_logic;
			ClockInEnable	 : in		 std_logic;
			DataIn_high		 : out	 std_logic_vector(BITS - 1 downto 0);
			DataIn_low		 : out	 std_logic_vector(BITS - 1 downto 0);
			Pad						 : inout std_logic_vector(BITS - 1 downto 0));
	end component;

	component ddrio_out is
		generic (
			NO_OUTPUT_ENABLE		: boolean			:= false;
			BITS								: positive;
			INIT_VALUE					: bit_vector	:= x"FFFFFFFF"
		);
		port (
			Clock				 : in	 std_logic;
			ClockEnable	 : in	 std_logic;
			OutputEnable : in	 std_logic;
			DataOut_high : in	 std_logic_vector(BITS - 1 downto 0);
			DataOut_low	 : in	 std_logic_vector(BITS - 1 downto 0);
			Pad					 : out std_logic_vector(BITS - 1 downto 0)
		);
	end component;

	-- Vendor specific modules ----------------------------------------------

	component ddrio_in_altera is
		generic (
			BITS					: positive;
			INIT_VALUE		: bit_vector	:= x"FFFFFFFF"
		);
		port (
			Clock				: in		std_logic;
			ClockEnable : in		std_logic;
			DataIn_high : out		std_logic_vector(BITS - 1 downto 0);
			DataIn_low	: out		std_logic_vector(BITS - 1 downto 0);
			Pad					: in 		std_logic_vector(BITS - 1 downto 0));
	end component;

	component ddrio_in_xilinx is
		generic (
			BITS					: positive;
			INIT_VALUE		: bit_vector	:= x"FFFFFFFF"
		);
		port (
			Clock				: in		std_logic;
			ClockEnable : in		std_logic;
			DataIn_high : out		std_logic_vector(BITS - 1 downto 0);
			DataIn_low	: out		std_logic_vector(BITS - 1 downto 0);
			Pad					: in 		std_logic_vector(BITS - 1 downto 0));
	end component;

	component ddrio_inout_altera is
		generic (
			BITS 					 : positive);
		port (
			ClockOut			 : in		 std_logic;
			ClockOutEnable : in		 std_logic;
			OutputEnable	 : in		 std_logic;
			DataOut_high	 : in		 std_logic_vector(BITS - 1 downto 0);
			DataOut_low		 : in		 std_logic_vector(BITS - 1 downto 0);
			ClockIn				 : in		 std_logic;
			ClockInEnable	 : in		 std_logic;
			DataIn_high		 : out	 std_logic_vector(BITS - 1 downto 0);
			DataIn_low		 : out	 std_logic_vector(BITS - 1 downto 0);
			Pad						 : inout std_logic_vector(BITS - 1 downto 0));
	end component;

	component ddrio_inout_xilinx is
		generic (
			BITS 					 : positive);
		port (
			ClockOut			 : in		 std_logic;
			ClockOutEnable : in		 std_logic;
			OutputEnable	 : in		 std_logic;
			DataOut_high	 : in		 std_logic_vector(BITS - 1 downto 0);
			DataOut_low		 : in		 std_logic_vector(BITS - 1 downto 0);
			ClockIn				 : in		 std_logic;
			ClockInEnable	 : in		 std_logic;
			DataIn_high		 : out	 std_logic_vector(BITS - 1 downto 0);
			DataIn_low		 : out	 std_logic_vector(BITS - 1 downto 0);
			Pad						 : inout std_logic_vector(BITS - 1 downto 0));
	end component;

	component ddrio_out_altera is
		generic (
			NO_OUTPUT_ENABLE		: boolean			:= false;
			BITS								: positive;
			INIT_VALUE					: bit_vector	:= x"FFFFFFFF"
		);
		port (
			Clock				 : in	 std_logic;
			ClockEnable	 : in	 std_logic;
			OutputEnable : in	 std_logic;
			DataOut_high : in	 std_logic_vector(BITS - 1 downto 0);
			DataOut_low	 : in	 std_logic_vector(BITS - 1 downto 0);
			Pad					 : out std_logic_vector(BITS - 1 downto 0)
		);
	end component;

	component ddrio_out_xilinx is
		generic (
			NO_OUTPUT_ENABLE		: boolean			:= false;
			BITS								: positive;
			INIT_VALUE					: bit_vector	:= x"FFFFFFFF"
		);
		port (
			Clock				 : in	 std_logic;
			ClockEnable	 : in	 std_logic;
			OutputEnable : in	 std_logic;
			DataOut_high : in	 std_logic_vector(BITS - 1 downto 0);
			DataOut_low	 : in	 std_logic_vector(BITS - 1 downto 0);
			Pad					 : out std_logic_vector(BITS - 1 downto 0)
		);
	end component;

end package;
