-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Entity:				 	Generic AMBA AXI4 bus description
--
-- Description:
-- -------------------------------------
-- This package implements a generic AMBA AXI4 description for:
--
-- * AXI4 Lite
--
-- License:
-- =============================================================================
-- Copyright 2017-2018 Patrick Lehmann - Bötzingen, Germany
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
use     IEEE.std_logic_1164.all;
use     IEEE.numeric_std.all;


package AXI4 is
  subtype  T_AXI4_Response is std_logic_vector(1 downto 0);
	constant AXI4_RESPONSE_OKAY         : T_AXI4_Response := "00";
	constant AXI4_RESPONSE_EX_OKAY      : T_AXI4_Response := "01";
	constant AXI4_RESPONSE_SLAVE_ERROR  : T_AXI4_Response := "10";
	constant AXI4_RESPONSE_DECODE_ERROR : T_AXI4_Response := "11";
	constant AXI4_RESPONSE_INIT         : T_AXI4_Response := "ZZ";

  subtype T_AXI4_Protect is std_logic_vector(2 downto 0);
  -- Bit 0: 0 Unprivileged access   1 Privileged access
  -- Bit 1: 0 Secure access         1 Non-secure access
  -- Bit 2: 0 Data access           1 Instruction access
  constant AXI4_PROTECT_INIT : T_AXI4_Protect := "ZZZ"; 

	-- AXI4-Lite - Write Address Channel
  type T_AXI4Lite_WriteAddress_Bus is record
		AWValid     : std_logic; 
		AWReady     : std_logic;
		AWAddr      : unsigned; 
		AWProt      : T_AXI4_Protect;
	end record; 

	function Initialize_AXI4Lite_WriteAddress_Bus(AddressBits : natural) return T_AXI4Lite_WriteAddress_Bus;

	-- AXI4-Lite - Write Data Channel
	type T_AXI4Lite_WriteData_Bus is record
		WValid      : std_logic;
		WReady      : std_logic;
		WData       : std_logic_vector;
		WStrb       : std_logic_vector;
	end record;

	function Initialize_AXI4Lite_WriteData_Bus(DataBits : natural) return T_AXI4Lite_WriteData_Bus;

	-- AXI4-Lite - Write Response Channel
	type T_AXI4Lite_WriteResponse_Bus is record
		BValid      : std_logic;
		BReady      : std_logic;
		BResp       : T_AXI4_Response; 
	end record; 

	function Initialize_AXI4Lite_WriteResponse_Bus return T_AXI4Lite_WriteResponse_Bus;

	-- AXI4-Lite - Read Address Channel
	type T_AXI4Lite_ReadAddress_Bus is record
		ARValid     : std_logic;
		ARReady     : std_logic;
		ARAddr      : unsigned;
		ARProt      : T_AXI4_Protect;
	end record;

	function Initialize_AXI4Lite_ReadAddress_Bus(AddressBits : natural) return T_AXI4Lite_ReadAddress_Bus;

	-- AXI4-Lite - Read Data Channel
	type T_AXI4Lite_ReadData_Bus is record
		RValid      : std_logic;
		RReady      : std_logic;
		RData       : std_logic_vector;
		RResp       : T_AXI4_Response;
	end record;

	function Initialize_AXI4Lite_ReadData_Bus(DataBits : natural ) return T_AXI4Lite_ReadData_Bus;


	type T_AXI4Lite_Bus is record
		WriteAddress   : T_AXI4Lite_WriteAddress_Bus;
		WriteData      : T_AXI4Lite_WriteData_Bus;
		WriteResponse  : T_AXI4Lite_WriteResponse_Bus;
		ReadAddress    : T_AXI4Lite_ReadAddress_Bus;
		ReadData       : T_AXI4Lite_ReadData_Bus;
	end record;
	
	function Initialize_AXI4Lite_Bus(AddressBits : natural; DataBits : natural) return T_AXI4Lite_Bus;
end package;


package body AXI4 is 
  function Initialize_AXI4Lite_WriteAddress_Bus(AddressBits : natural) return T_AXI4Lite_WriteAddress_Bus is
  begin
    return (
      AWValid => 'Z',
      AWReady => 'Z',
      AWAddr  => (AddressBits-1 downto 0 => 'Z'), 
      AWProt  => AXI4_PROTECT_INIT
    );
  end function;

  function Initialize_AXI4Lite_WriteData_Bus(DataBits : natural) return T_AXI4Lite_WriteData_Bus is
  begin
    return (
      WValid  => 'Z',
      WReady  => 'Z',
      WData   => (DataBits - 1 downto 0 => 'Z'),
      WStrb   => ((DataBits / 8) - 1 downto 0 => 'Z') 
    );
  end function;

  function Initialize_AXI4Lite_WriteResponse_Bus return T_AXI4Lite_WriteResponse_Bus is
  begin
    return (
      BValid  => 'Z',
      BReady  => 'Z',
      BResp   => AXI4_RESPONSE_INIT  
    );
  end function;

  function Initialize_AXI4Lite_ReadAddress_Bus(AddressBits : natural) return T_AXI4Lite_ReadAddress_Bus is
  begin
    return (
      ARValid => 'Z',
      ARReady => 'Z',
      ARAddr  => (AddressBits - 1 downto 0 => 'Z'),
      ARProt  => AXI4_PROTECT_INIT
    );
  end function;

  function Initialize_AXI4Lite_ReadData_Bus(DataBits : natural) return T_AXI4Lite_ReadData_Bus is
  begin
    return (
      RValid  => 'Z',
      RReady  => 'Z',
      RData   => (DataBits - 1 downto 0 => 'Z'),
      RResp   => AXI4_RESPONSE_INIT
    );
  end function;
  
  function Initialize_AXI4Lite_Bus(AddressBits : natural; DataBits : natural) return T_AXI4Lite_Bus is
  begin
    return ( 
      WriteAddress  => Initialize_AXI4Lite_WriteAddress_Bus(AddressBits),
      WriteData     => Initialize_AXI4Lite_WriteData_Bus(DataBits),
      WriteResponse => Initialize_AXI4Lite_WriteResponse_Bus,
      ReadAddress   => Initialize_AXI4Lite_ReadAddress_Bus(AddressBits),
      ReadData      => Initialize_AXI4Lite_ReadData_Bus(DataBits)
    );
  end function; 
end package body;
