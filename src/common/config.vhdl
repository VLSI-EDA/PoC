-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- ============================================================================
-- Package:					Global configuration settings.
--
-- Authors:					Thomas B. Preusser
--									Martin Zabel
--									Patrick Lehmann
--
-- Description:
-- ------------------------------------
--		This file evaluates the settings declared in the project specific package my_config.
--		See also template file my_config.vhdl.template.
--
-- License:
-- ============================================================================
-- Copyright 2007-2014 Technische Universitaet Dresden - Germany,
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

library	PoC;
use			PoC.my_config.all;
use			PoC.board.all;
use			PoC.utils.all;
use			PoC.strings.all;


package config is
	-- FPGA / Chip vendor
	-- ===========================================================================
	type vendor_t is (
		VENDOR_ALTERA,
		VENDOR_XILINX
--		VENDOR_LATTICE
	);

	-- Device
	-- ===========================================================================
	type device_t is (
		DEVICE_SPARTAN3, DEVICE_SPARTAN6,																		-- Xilinx.Spartan
		DEVICE_ZYNQ7,																												-- Xilinx.Zynq
		DEVICE_ARTIX7,																											-- Xilinx.Artix
		DEVICE_KINTEX7,																											-- Xilinx.Kintex
		DEVICE_VIRTEX5,	DEVICE_VIRTEX6, DEVICE_VIRTEX7,											-- Xilinx.Virtex

		DEVICE_CYCLONE1, DEVICE_CYCLONE2, DEVICE_CYCLONE3,									-- Altera.Cyclone
		DEVICE_STRATIX1, DEVICE_STRATIX2, DEVICE_STRATIX4, DEVICE_STRATIX5	-- Altera.Stratix
	);

	-- Device family
	-- ===========================================================================
	type T_DEVICE_FAMILY is (
		-- Xilinx
		DEVICE_FAMILY_SPARTAN,
		DEVICE_FAMILY_ZYNQ,
		DEVICE_FAMILY_ARTIX,
		DEVICE_FAMILY_KINTEX,
		DEVICE_FAMILY_VIRTEX,

		DEVICE_FAMILY_CYCLONE,
		DEVICE_FAMILY_STRATIX
	);

	type T_DEVICE_SUBTYPE is (
		DEVICE_SUBTYPE_NONE,
		-- Xilinx
		DEVICE_SUBTYPE_X,
		DEVICE_SUBTYPE_T,
		DEVICE_SUBTYPE_XT,
		DEVICE_SUBTYPE_HT,
		DEVICE_SUBTYPE_LX,
		DEVICE_SUBTYPE_SXT,
		DEVICE_SUBTYPE_LXT,
		DEVICE_SUBTYPE_TXT,
		DEVICE_SUBTYPE_FXT,
		DEVICE_SUBTYPE_CXT,
		DEVICE_SUBTYPE_HXT,
		-- Altera
		DEVICE_SUBTYPE_E,
		DEVICE_SUBTYPE_GS,
		DEVICE_SUBTYPE_GX,
		DEVICE_SUBTYPE_GT
	);

	-- Transceiver (sub-)type
	-- ===========================================================================
	type T_TRANSCEIVER is (
		TRANSCEIVER_GTP_DUAL,	TRANSCEIVER_GTPE1, TRANSCEIVER_GTPE2,					-- Xilinx GTP transceivers
		TRANSCEIVER_GTX,			TRANSCEIVER_GTXE1, TRANSCEIVER_GTXE2,					-- Xilinx GTX transceivers
		TRANSCEIVER_GTH,			TRANSCEIVER_GTHE1, TRANSCEIVER_GTHE2,					-- Xilinx GTH transceivers
		TRANSCEIVER_GTZ,																										-- Xilinx GTZ transceivers

		-- TODO: add Altera transceivers
		TRANSCEIVER_GXB,																										-- Altera GXB transceiver

		TRANSCEIVER_NONE
	);

	-- Properties of FPGA architecture
	-- ===========================================================================
	-- EXPERIMENTAL: applied consistent nameschema, prefixed members with 'Dev' -> subtype is a keyword
	type T_DEVICE_INFO is record
		Vendor						: vendor_t;
		Device						: device_t;
		DevFamily					: T_DEVICE_FAMILY;
		DevNumber					: natural;
		DevSubType				: T_DEVICE_SUBTYPE;
		DevSeries					: natural;
		
		TransceiverType		: T_TRANSCEIVER;
		LUT_FanIn					: positive;
	end record;


	-- QUESTION: replace archprops with DEVICE_INFO ?
	type archprops_t is record
		LUT_K						: positive;	-- LUT Fanin
	end record;

	-- Functions extracting device and architecture properties from "MY_DEVICE"
	-- which is declared in package "my_config".
	-- ===========================================================================
	function VENDOR(DeviceString : string := "None")						return vendor_t;
	function DEVICE(DeviceString : string := "None")						return device_t;
	function DEVICE_FAMILY(DeviceString : string := "None")			return T_DEVICE_FAMILY;
	function DEVICE_NUMBER(DeviceString : string := "None")			return natural;
	function DEVICE_SUBTYPE(DeviceString : string := "None")		return T_DEVICE_SUBTYPE;
	function DEVICE_SERIES(DeviceString : string := "None")			return natural;

	function TRANSCEIVER_TYPE(DeviceString : string := "None")	return T_TRANSCEIVER;
	function LUT_FANIN(DeviceString : string := "None")					return positive;

	function DEVICE_INFO(DeviceString : string := "None")				return T_DEVICE_INFO;

	function ARCH_PROPS return archprops_t;

	-- force FSM to predefined encoding in debug mode
	function getFSMEncoding_gray(debug : BOOLEAN) return STRING;
end config;

package body config is
	function getLocalDeviceString(DeviceString : string) return string is
	begin
		if (DeviceString /= "None") then
			return DeviceString;
		elsif (MY_DEVICE /= "None") then
			return MY_DEVICE;
		else
			return MY_DEVICE_STRING;
		end if;
	end function;

	function extractFirstNumber(str : STRING) return NATURAL is
		variable low			: integer					:= -1;
		variable high			: integer					:= -1;
	begin
		for i in str'low to str'high loop
			if chr_isDigit(str(i)) then
				low := i;
				exit;
			end if;
		end loop;
		-- abort if no digit can be found
		if (low = -1) then		return 0; end if;
		
		for i in (low + 1) to str'high loop
			if chr_isAlpha(str(i)) then
				high := i - 1;
				exit;
			end if;
		end loop;
		
		if (high = -1) then		return 0; end if;
		return to_natural_dec(str(low to high));			-- convert substring to a number
	end function;

	-- purpose: extract vendor from MY_DEVICE
	function VENDOR(DeviceString : string := "None") return vendor_t is
		constant MY_DEV	: string(1 to 15) := resize(getLocalDeviceString(DeviceString), 15);
		constant VEN		: string(1 to 2)  := MY_DEV(1 to 2);
	begin	-- VENDOR
		case VEN is
			when "XC"		=> return VENDOR_XILINX;
			when "EP"		=> return VENDOR_ALTERA;
			when others	=> report "Unknown vendor in MY_DEVICE = " & MY_DEV & "." severity failure;
										 -- return statement is explicitly missing otherwise XST won't stop
		end case;
	end VENDOR;

	-- purpose: extract device from MY_DEVICE
	function DEVICE(DeviceString : string := "None") return device_t is
		constant MY_DEV	: string(1 to 15)	:= resize(getLocalDeviceString(DeviceString), 15);
		constant VEN		: vendor_t				:= VENDOR(MY_DEV(1 to 2));
		constant DEV		: string(3 to  4)	:= MY_DEV(3 to 4);
	begin	-- DEVICE
		case VEN is
			when VENDOR_ALTERA =>
				case DEV is
					when "1C"	 => return DEVICE_CYCLONE1;
					when "2C"	 => return DEVICE_CYCLONE2;
					when "3C"	 => return DEVICE_CYCLONE3;
					when "1S"	 => return DEVICE_STRATIX1;
					when "2S"	 => return DEVICE_STRATIX2;
					when "4S"	 => return DEVICE_STRATIX4;
					when "5S"	 => return DEVICE_STRATIX5;
					when others => report "Unknown Altera device in MY_DEVICE = " & MY_DEV & "." severity failure;
				end case;

			when VENDOR_XILINX =>
				case DEV is
					when "7A"	 => return DEVICE_ARTIX7;
					when "7K"	 => return DEVICE_KINTEX7;
					when "3S"	 => return DEVICE_SPARTAN3;
					when "6S"	 => return DEVICE_SPARTAN6;
					when "5V"	 => return DEVICE_VIRTEX5;
					when "6V"	 => return DEVICE_VIRTEX6;
					when "7V"	 => return DEVICE_VIRTEX7;
					when "7Z"	 => return DEVICE_ZYNQ7;
					when others => report "Unknown Xilinx device in MY_DEVICE = " & MY_DEV & "." severity failure;
				end case;
				
			when others => report "Unknown vendor in MY_DEVICE = " & MY_DEV & "." severity failure;
										 -- return statement is explicitly missing otherwise XST won't stop
		end case;
	end DEVICE;

	-- purpose: extract device from MY_DEVICE
	function DEVICE_FAMILY(DeviceString : string := "None") return T_DEVICE_FAMILY is
		constant MY_DEV	: string(1 to 15)	:= resize(getLocalDeviceString(DeviceString), 15);
		constant VEN		: vendor_t				:= VENDOR(MY_DEV(1 to 2));
		constant FAM		: character				:= MY_DEV(4);
	begin	-- DEVICE
		case VEN is
			when VENDOR_ALTERA =>
				case FAM is
					when 'C'		=> return DEVICE_FAMILY_CYCLONE;
					when 'S'		=> return DEVICE_FAMILY_STRATIX;
					when others	=> report "Unknown Altera device family in MY_DEVICE = " & MY_DEV & "." severity failure;
				end case;

			when VENDOR_XILINX =>
				case FAM is
					when 'A'		=> return DEVICE_FAMILY_ARTIX;
					when 'K'		=> return DEVICE_FAMILY_KINTEX;
					when 'S'		=> return DEVICE_FAMILY_SPARTAN;
					when 'V'		=> return DEVICE_FAMILY_VIRTEX;
					when 'Z'		=> return DEVICE_FAMILY_ZYNQ;
					when others => report "Unknown Xilinx device family in MY_DEVICE = " & MY_DEV & "." severity failure;
				end case;
				
			when others => report "Unknown vendor in MY_DEVICE = " & MY_DEV & "." severity failure;
										 -- return statement is explicitly missing otherwise XST won't stop
		end case;
	end DEVICE_FAMILY;

	function DEVICE_SERIES(DeviceString : string := "None") return natural is
		constant MY_DEV : string		:= getLocalDeviceString(DeviceString);
		constant DEV		: device_t	:= DEVICE(MY_DEV);
	begin
		case DEV is
			when DEVICE_ARTIX7 | DEVICE_KINTEX7 | DEVICE_VIRTEX7 | DEVICE_ZYNQ7 =>	return 7;		-- all Xilinx ****7 devices share some common features: e.g. XADC
			when others =>																													return 0;
		end case;
	end function;

	function DEVICE_NUMBER(DeviceString : string := "None") return natural is
		constant MY_DEV		: string(1 to 15)	:= resize(getLocalDeviceString(DeviceString), 15);
		constant VEN			: vendor_t				:= VENDOR(MY_DEV(1 to 2));
	begin
		case VEN is
			when VENDOR_ALTERA =>		return extractFirstNumber(MY_DEV(5 to MY_DEV'high));
			when VENDOR_XILINX =>		return extractFirstNumber(MY_DEV(5 to MY_DEV'high));
			when others =>					report "Unknown vendor in MY_DEVICE = " & MY_DEV & "." severity failure;
															-- return statement is explicitly missing otherwise XST won't stop
		end case;
	end function;
	
	function DEVICE_SUBTYPE(DeviceString : string := "None") return t_device_subtype is
		constant MY_DEV		: string(1 to 15)	:= resize(getLocalDeviceString(DeviceString), 15);
		constant DEV			: device_t				:= DEVICE(MY_DEV);
		constant DEV_SUB	: string(1 to 2)	:= MY_DEV(5 to 6);																-- work around for GHDL
	begin
		case DEV is
			when DEVICE_CYCLONE1 | DEVICE_CYCLONE2 | DEVICE_CYCLONE3 =>				return DEVICE_SUBTYPE_NONE;		-- Altera Cyclon I, II, III devices have no subtype

			when DEVICE_STRATIX2 =>
				if		chr_isDigit(DEV_SUB(1)) then																								return DEVICE_SUBTYPE_NONE;
				elsif	(DEV_SUB = "GX") then																												return DEVICE_SUBTYPE_GX;
				else	report "Unknown Stratix II subtype: MY_DEVICE = " & MY_DEV & "." severity failure;
				end if;

			when DEVICE_STRATIX4 =>
				if		(DEV_SUB(1) = 'E') then																											return DEVICE_SUBTYPE_E;
				elsif	(DEV_SUB = "GX") then																												return DEVICE_SUBTYPE_GX;
--				elsif	(DEV_SUB = "GT") then																												return DEVICE_SUBTYPE_GT;
				else	report "Unknown Stratix II subtype: MY_DEVICE = " & MY_DEV & "." severity failure;
				end if;

			when DEVICE_SPARTAN3 => report "TODO: parse Spartan3 / Spartan3E / Spartan3AN device subtype." severity failure;

			when DEVICE_SPARTAN6 =>
				if		((DEV_SUB = "LX") and (not	str_find(MY_DEV(7 TO MY_DEV'high), 'T'))) then	return DEVICE_SUBTYPE_LX;
				elsif	((DEV_SUB = "LX") and (			str_find(MY_DEV(7 TO MY_DEV'high), 'T'))) then	return DEVICE_SUBTYPE_LXT;
				else	report "Unknown Virtex-5 subtype: MY_DEVICE = " & MY_DEV & "." severity failure;
				end if;
			
			when DEVICE_VIRTEX5 =>
				if		((DEV_SUB = "LX") and (not	str_find(MY_DEV(7 TO MY_DEV'high), 'T'))) then	return DEVICE_SUBTYPE_LX;
				elsif	((DEV_SUB = "LX") and (			str_find(MY_DEV(7 TO MY_DEV'high), 'T'))) then	return DEVICE_SUBTYPE_LXT;
				elsif	((DEV_SUB = "SX") and (			str_find(MY_DEV(7 TO MY_DEV'high), 'T'))) then	return DEVICE_SUBTYPE_SXT;
				elsif	((DEV_SUB = "TX") and (			str_find(MY_DEV(7 TO MY_DEV'high), 'T'))) then	return DEVICE_SUBTYPE_TXT;
				elsif	((DEV_SUB = "FX") and (			str_find(MY_DEV(7 TO MY_DEV'high), 'T'))) then	return DEVICE_SUBTYPE_FXT;
				else	report "Unknown Virtex-5 subtype: MY_DEVICE = " & MY_DEV & "." severity failure;
				end if;

			when DEVICE_VIRTEX6 =>
				if		((DEV_SUB = "LX") and (not	str_find(MY_DEV(7 TO MY_DEV'high), 'T'))) then	return DEVICE_SUBTYPE_LX;
				elsif	((DEV_SUB = "LX") and (			str_find(MY_DEV(7 TO MY_DEV'high), 'T'))) then	return DEVICE_SUBTYPE_LXT;
				elsif	((DEV_SUB = "SX") and (			str_find(MY_DEV(7 TO MY_DEV'high), 'T'))) then	return DEVICE_SUBTYPE_SXT;
				elsif	((DEV_SUB = "CX") and (			str_find(MY_DEV(7 TO MY_DEV'high), 'T'))) then	return DEVICE_SUBTYPE_CXT;
				elsif	((DEV_SUB = "HX") and (			str_find(MY_DEV(7 TO MY_DEV'high), 'T'))) then	return DEVICE_SUBTYPE_HXT;
				else	report "Unknown Virtex-6 subtype: MY_DEVICE = " & MY_DEV & "." severity failure;
				end if;

			when DEVICE_ARTIX7 =>
				if		(											(			str_find(MY_DEV(5 TO MY_DEV'high), 'T'))) then	return DEVICE_SUBTYPE_T;
				else	report "Unknown Artix-7 subtype: MY_DEVICE = " & MY_DEV & "." severity failure;
				end if;
				
			when DEVICE_KINTEX7 =>
				if		(											(			str_find(MY_DEV(5 TO MY_DEV'high), 'T'))) then	return DEVICE_SUBTYPE_T;
				else	report "Unknown Kintex-7 subtype: MY_DEVICE = " & MY_DEV & "." severity failure;
				end if;
				
			when DEVICE_VIRTEX7 =>
				if		(												(		str_find(MY_DEV(5 TO MY_DEV'high), 'T'))) then	return DEVICE_SUBTYPE_T;
				elsif	((DEV_SUB(1) = 'X') and (		str_find(MY_DEV(6 TO MY_DEV'high), 'T'))) then	return DEVICE_SUBTYPE_XT;
				elsif	((DEV_SUB(1) = 'H') and (		str_find(MY_DEV(6 TO MY_DEV'high), 'T'))) then	return DEVICE_SUBTYPE_HT;
				else	report "Unknown Virtex-7 subtype: MY_DEVICE = " & MY_DEV & "." severity failure;
				end if;

			when others => report "Transceiver type is unknown for the given device." severity failure;
									-- return statement is explicitly missing otherwise XST won't stop
		end case;

	end function;

	function LUT_FANIN(DeviceString : string := "None") return positive is
		constant MY_DEV : string		:= getLocalDeviceString(DeviceString);
		constant DEV		: device_t	:= DEVICE(MY_DEV);
	begin
		case DEV is
			when DEVICE_CYCLONE1 | DEVICE_CYCLONE2 | DEVICE_CYCLONE3 =>			return 4;
			when DEVICE_STRATIX1 | DEVICE_STRATIX2 =>												return 4;
			when DEVICE_STRATIX4 | DEVICE_STRATIX5 =>												return 6;

			when DEVICE_SPARTAN3 =>																					return 4;
			when DEVICE_SPARTAN6 =>																					return 6;
			when DEVICE_ARTIX7 =>																						return 6;
			when DEVICE_KINTEX7 =>																					return 6;
			when DEVICE_VIRTEX5 | DEVICE_VIRTEX6 | DEVICE_VIRTEX7 => 				return 6;
			when DEVICE_ZYNQ7 =>																						return 6;

			when others => report "LUT fan-in is unknown for the given device." severity failure;
									-- return statement is explicitly missing otherwise XST won't stop
		end case;
	end function;

	function TRANSCEIVER_TYPE(DeviceString : string := "None") return T_TRANSCEIVER is
		constant MY_DEV		: string(1 to 15)		:= resize(getLocalDeviceString(DeviceString), 15);
		constant DEV			: device_t					:= DEVICE(MY_DEV);
		constant DEV_NUM	: natural						:= DEVICE_NUMBER(MY_DEV);
		constant DEV_SUB	: t_device_subtype	:= DEVICE_SUBTYPE(MY_DEV);
	begin
		case DEV is
			when DEVICE_CYCLONE1 | DEVICE_CYCLONE2 | DEVICE_CYCLONE3 =>				return TRANSCEIVER_NONE;		-- Altera Cyclon I, II, III devices have no transceivers

			when DEVICE_SPARTAN3 =>						return TRANSCEIVER_NONE;		-- Xilinx Spartan3 devices have no transceivers

			when DEVICE_SPARTAN6 =>
				case DEV_SUB is
					when DEVICE_SUBTYPE_LX =>			return TRANSCEIVER_NONE;
					when DEVICE_SUBTYPE_LXT =>		return TRANSCEIVER_GTPE1;
					when others =>								report "Unknown Spartan-6 subtype: " & t_device_subtype'image(DEV_SUB) severity failure;
				end case;
			
			when DEVICE_VIRTEX5 =>
				case DEV_SUB is
					when DEVICE_SUBTYPE_LX =>			return TRANSCEIVER_NONE;
					when DEVICE_SUBTYPE_SXT =>		return TRANSCEIVER_GTP_DUAL;
					when DEVICE_SUBTYPE_LXT =>		return TRANSCEIVER_GTP_DUAL;
					when DEVICE_SUBTYPE_TXT =>		return TRANSCEIVER_GTX;
					when DEVICE_SUBTYPE_FXT =>		return TRANSCEIVER_GTX;
					when others =>								report "Unknown Virtex-5 subtype: " & t_device_subtype'image(DEV_SUB) severity failure;
				end case;

			when DEVICE_VIRTEX6 =>
				case DEV_SUB is
					when DEVICE_SUBTYPE_LX =>			return TRANSCEIVER_NONE;
					when DEVICE_SUBTYPE_SXT =>		return TRANSCEIVER_GTXE1;
					when DEVICE_SUBTYPE_LXT =>		return TRANSCEIVER_GTXE1;
					when DEVICE_SUBTYPE_HXT =>		return TRANSCEIVER_GTXE1;
					when others =>								report "Unknown Virtex-6 subtype: " & t_device_subtype'image(DEV_SUB) severity failure;
				end case;
				
			when DEVICE_ARTIX7 =>							return TRANSCEIVER_GTPE2;
			when DEVICE_KINTEX7 =>						return TRANSCEIVER_GTXE2;
			when DEVICE_VIRTEX7 =>
				case DEV_SUB is
					when DEVICE_SUBTYPE_T =>			return TRANSCEIVER_GTXE2;
					when DEVICE_SUBTYPE_XT =>
						if (DEV_NUM = 485) then			return TRANSCEIVER_GTXE2;
						else												return TRANSCEIVER_GTHE2;
						end if;
					when DEVICE_SUBTYPE_HT =>			return TRANSCEIVER_GTHE2;
					when others =>								report "Unknown Virtex-7 subtype: " & t_device_subtype'image(DEV_SUB) severity failure;
				end case;
				
			when DEVICE_STRATIX2 => return TRANSCEIVER_GXB;
			when DEVICE_STRATIX4 => return TRANSCEIVER_GXB;
				
			when others => report "Unknown device." severity failure;
									-- return statement is explicitly missing otherwise XST won't stop
		end case;
	end function;

	-- purpose: extract architecture properties from DEVICE
	function DEVICE_INFO(DeviceString : string := "None") return T_DEVICE_INFO is
		variable Result					: T_DEVICE_INFO;
	begin
		Result.Vendor						:= VENDOR(DeviceString);
		Result.Device						:= DEVICE(DeviceString);
		Result.DevFamily				:= DEVICE_FAMILY(DeviceString);
		Result.DevNumber				:= DEVICE_NUMBER(DeviceString);
		Result.DevSubType				:= DEVICE_SUBTYPE(DeviceString);
		Result.DevSeries				:= DEVICE_SERIES(DeviceString);
		Result.TransceiverType	:= TRANSCEIVER_TYPE(DeviceString);
		Result.LUT_FanIn				:= LUT_FANIN(DeviceString);
		
		return Result;
	end function;
	
	function ARCH_PROPS return archprops_t is
		variable result : archprops_t;
	begin
		result.LUT_K					:= LUT_FANIN;

		return	result;
	end function;

	-- force FSM to predefined encoding in debug mode
	function getFSMEncoding_gray(debug : BOOLEAN) return STRING is
	begin
		if (debug = true) then
			return "gray";
		else
			case VENDOR is
				when VENDOR_XILINX =>		return "auto";
				when VENDOR_ALTERA =>		return "default";
				when others =>					report "Unknown vendor ." severity failure;
																-- return statement is explicitly missing otherwise XST won't stop
			end case;
		end if;
	end function;
end config;
