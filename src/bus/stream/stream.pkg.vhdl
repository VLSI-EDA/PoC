-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Package:				 	VHDL package for component declarations, types and functions
--									associated to the PoC.bus.stream namespace
--
-- Description:
-- -------------------------------------
-- .. TODO:: No documentation available.
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
-- WITHOUT WARRANTIES OR CONDITIONS of ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- =============================================================================

library IEEE;
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.NUMERIC_STD.all;

library PoC;
use			PoC.utils.all;
use			PoC.vectors.all;
use			PoC.strings.all;


package stream is
	-- single dataword for TestRAM
	type T_SIM_STREAM_WORD_8 is record
		Valid			: std_logic;
		Data			: T_SLV_8;
		SOF				: std_logic;
		EOF				: std_logic;
		Ready			: std_logic;
		EOFG			: boolean;
	end record;

	type T_SIM_STREAM_WORD_32 is record
		Valid			: std_logic;
		Data			: T_SLV_32;
		SOF				: std_logic;
		EOF				: std_logic;
		Ready			: std_logic;
		EOFG			: boolean;
	end record;

	-- define array indices
	constant C_SIM_STREAM_MAX_PATTERN_COUNT			: positive			:= 128;-- * 1024;				-- max data size per testcase
	constant C_SIM_STREAM_MAX_FRAMEGROUP_COUNT	: positive			:= 8;

	constant C_SIM_STREAM_WORD_INDEX_BW					: positive			:= log2ceilnz(C_SIM_STREAM_MAX_PATTERN_COUNT);
	constant C_SIM_STREAM_FRAMEGROUP_INDEX_BW		: positive			:= log2ceilnz(C_SIM_STREAM_MAX_FRAMEGROUP_COUNT);

	subtype T_SIM_STREAM_WORD_INDEX					is integer range 0 to C_SIM_STREAM_MAX_PATTERN_COUNT - 1;
	subtype T_SIM_STREAM_FRAMEGROUP_INDEX		is integer range 0 to C_SIM_STREAM_MAX_FRAMEGROUP_COUNT - 1;

	subtype T_SIM_DELAY											is T_UINT_16;
	type		T_SIM_DELAY_VECTOR							is array (natural range <>) of T_SIM_DELAY;

	-- define array of datawords
	type		T_SIM_STREAM_WORD_VECTOR_8			is array (natural range <>) of T_SIM_STREAM_WORD_8;
	type		T_SIM_STREAM_WORD_VECTOR_32			is array (natural range <>) of T_SIM_STREAM_WORD_32;

	-- define link layer directions
	type		T_SIM_STREAM_DIRECTION					is (Send, RECEIVE);

	-- define framegroup information
	type T_SIM_STREAM_FRAMEGROUP_8 is record
		Active					: boolean;
		Name						: string(1 to 64);
		PrePause				: natural;
		PostPause				: natural;
		DataCount				: T_SIM_STREAM_WORD_INDEX;
		Data						: T_SIM_STREAM_WORD_VECTOR_8(0 to C_SIM_STREAM_MAX_PATTERN_COUNT - 1);
	end record;

	type T_SIM_STREAM_FRAMEGROUP_32 is record
		Active					: boolean;
		Name						: string(1 to 64);
		PrePause				: natural;
		PostPause				: natural;
		DataCount				: T_SIM_STREAM_WORD_INDEX;
		Data						: T_SIM_STREAM_WORD_VECTOR_32(T_SIM_STREAM_WORD_INDEX);
	end record;

	-- define array of framegroups
	type T_SIM_STREAM_FRAMEGROUP_VECTOR_8			is array (natural range <>) of T_SIM_STREAM_FRAMEGROUP_8;
	type T_SIM_STREAM_FRAMEGROUP_VECTOR_32		is array (natural range <>) of T_SIM_STREAM_FRAMEGROUP_32;

	-- define constants (stored in RAMB36's parity-bits)
	constant C_SIM_STREAM_WORD_8_EMPTY			: T_SIM_STREAM_WORD_8		:= (Valid => '0', Data => (others => 'U'),	SOF => '0', EOF	=> '0', Ready => '0', EOFG => FALSE);
	constant C_SIM_STREAM_WORD_32_EMPTY			: T_SIM_STREAM_WORD_32	:= (Valid => '0', Data => (others => 'U'),	SOF => '0', EOF	=> '0', Ready => '0', EOFG => FALSE);
	constant C_SIM_STREAM_WORD_8_INVALID		: T_SIM_STREAM_WORD_8		:= (Valid	=> '0', Data => (others => 'U'),	SOF => '0', EOF	=> '0', Ready => '0', EOFG => FALSE);
	constant C_SIM_STREAM_WORD_32_INVALID		: T_SIM_STREAM_WORD_32	:= (Valid	=> '0', Data => (others => 'U'),	SOF => '0', EOF	=> '0', Ready => '0', EOFG => FALSE);
	constant C_SIM_STREAM_WORD_8_ZERO				: T_SIM_STREAM_WORD_8		:= (Valid	=> '1', Data => (others => 'Z'),	SOF => '0', EOF	=> '0', Ready => '0', EOFG => FALSE);
	constant C_SIM_STREAM_WORD_32_ZERO			: T_SIM_STREAM_WORD_32	:= (Valid	=> '1', Data => (others => 'Z'),	SOF => '0', EOF	=> '0', Ready => '0', EOFG => FALSE);
	constant C_SIM_STREAM_WORD_8_UNDEF			: T_SIM_STREAM_WORD_8		:= (Valid	=> '1', Data => (others => 'U'),	SOF => '0', EOF	=> '0', Ready => '0', EOFG => FALSE);
	constant C_SIM_STREAM_WORD_32_UNDEF			: T_SIM_STREAM_WORD_32	:= (Valid	=> '1', Data => (others => 'U'),	SOF => '0', EOF	=> '0', Ready => '0', EOFG => FALSE);

	constant C_SIM_STREAM_FRAMEGROUP_8_EMPTY	: T_SIM_STREAM_FRAMEGROUP_8		:= (
		Active						=> FALSE,
		Name							=> (others => C_POC_NUL),
		PrePause					=> 0,
		PostPause					=> 0,
		DataCount					=> 0,
		Data							=> (others => C_SIM_STREAM_WORD_8_EMPTY)
	);
	constant C_SIM_STREAM_FRAMEGROUP_32_EMPTY	: T_SIM_STREAM_FRAMEGROUP_32	:= (
		Active						=> FALSE,
		Name							=> (others => C_POC_NUL),
		PrePause					=> 0,
		PostPause					=> 0,
		DataCount					=> 0,
		Data							=> (others => C_SIM_STREAM_WORD_32_EMPTY)
	);

	function CountPatterns(Data : T_SIM_STREAM_WORD_VECTOR_8)		return natural;
	function CountPatterns(Data : T_SIM_STREAM_WORD_VECTOR_32)	return natural;

	function dat(slv		: T_SLV_8)										return T_SIM_STREAM_WORD_8;
	function dat(slvv		: T_SLVV_8) 									return T_SIM_STREAM_WORD_VECTOR_8;
	function dat(slv		: T_SLV_32)										return T_SIM_STREAM_WORD_32;
	function dat(slvv		: T_SLVV_32)									return T_SIM_STREAM_WORD_VECTOR_32;
	function sof(slv		: T_SLV_8)										return T_SIM_STREAM_WORD_8;
	function sof(slvv		: T_SLVV_8) 									return T_SIM_STREAM_WORD_VECTOR_8;
	function sof(slv		: T_SLV_32)										return T_SIM_STREAM_WORD_32;
	function sof(slvv		: T_SLVV_32)									return T_SIM_STREAM_WORD_VECTOR_32;
	function eof(slv		: T_SLV_8)										return T_SIM_STREAM_WORD_8;
	function eof(slvv		: T_SLVV_8) 									return T_SIM_STREAM_WORD_VECTOR_8;
	function eof(slv		: T_SLV_32)										return T_SIM_STREAM_WORD_32;
	function eof(slvv		: T_SLVV_32)									return T_SIM_STREAM_WORD_VECTOR_32;
	function eof(stmw		: T_SIM_STREAM_WORD_8)				return T_SIM_STREAM_WORD_8;
	function eof(stmwv	: T_SIM_STREAM_WORD_VECTOR_8)	return T_SIM_STREAM_WORD_VECTOR_8;
	function eof(stmw		: T_SIM_STREAM_WORD_32)				return T_SIM_STREAM_WORD_32;
	function eofg(stmw	: T_SIM_STREAM_WORD_8)				return T_SIM_STREAM_WORD_8;
	function eofg(stmwv	: T_SIM_STREAM_WORD_VECTOR_8)	return T_SIM_STREAM_WORD_VECTOR_8;
	function eofg(stmw	: T_SIM_STREAM_WORD_32)				return T_SIM_STREAM_WORD_32;

	function to_string(stmw : T_SIM_STREAM_WORD_8)		return string;
	function to_string(stmw : T_SIM_STREAM_WORD_32)		return string;

	-- checksum functions
	-- ================================================================
	function sim_CRC8(words		: T_SIM_STREAM_WORD_VECTOR_8) return std_logic_vector;
--	function sim_CRC16(words	: T_SIM_STREAM_WORD_VECTOR_8) return STD_LOGIC_VECTOR;
end;


package body stream is
function CountPatterns(Data : T_SIM_STREAM_WORD_VECTOR_8) return natural is
	begin
		for i in 0 to Data'length - 1 loop
			if (Data(i).EOFG = TRUE) then
				return i + 1;
			end if;
		end loop;

		return 0;
	end;

	function CountPatterns(Data : T_SIM_STREAM_WORD_VECTOR_32) return natural is
	begin
		for i in 0 to Data'length - 1 loop
			if (Data(i).EOFG = TRUE) then
				return i + 1;
			end if;
		end loop;

		return 0;
	end;

	function dat(slv : T_SLV_8) return T_SIM_STREAM_WORD_8 is
		variable result : T_SIM_STREAM_WORD_8;
	begin
		result := (Valid => '1', Data	=> slv,	SOF	=> '0',	EOF	=> '0', Ready => '-', EOFG => FALSE);
		report "dat: " & to_string(result) severity NOTE;
		return result;
	end;

	function dat(slvv : T_SLVV_8) return T_SIM_STREAM_WORD_VECTOR_8 is
		variable result			: T_SIM_STREAM_WORD_VECTOR_8(slvv'range);
	begin
		for i in slvv'range loop
			result(i)		:= dat(slvv(i));
		end loop;

		return result;
	end;

	function dat(slv : T_SLV_32) return T_SIM_STREAM_WORD_32 is
		variable result : T_SIM_STREAM_WORD_32;
	begin
		result := (Valid => '1', Data	=> slv,	SOF	=> '0',	EOF	=> '0', Ready => '-', EOFG => FALSE);
		report "dat: " & to_string(result) severity NOTE;
		return result;
	end;

	function dat(slvv : T_SLVV_32) return T_SIM_STREAM_WORD_VECTOR_32 is
		variable result			: T_SIM_STREAM_WORD_VECTOR_32(slvv'range);
	begin
		for i in slvv'range loop
			result(i)		:= dat(slvv(i));
		end loop;

		return result;
	end;

	function sof(slv : T_SLV_8) return T_SIM_STREAM_WORD_8 is
		variable result : T_SIM_STREAM_WORD_8;
	begin
		result := (Valid => '1', Data	=> slv,	SOF	=> '1',	EOF	=> '0', Ready => '-', EOFG => FALSE);
		report "sof: " & to_string(result) severity NOTE;
		return result;
	end;

	function sof(slvv : T_SLVV_8) return T_SIM_STREAM_WORD_VECTOR_8 is
		variable result			: T_SIM_STREAM_WORD_VECTOR_8(slvv'range);
	begin
		result(slvv'low)		:= sof(slvv(slvv'low));
		for i in slvv'low + 1 to slvv'high loop
			result(i)		:= dat(slvv(i));
		end loop;
		return result;
	end;

	function sof(slv : T_SLV_32) return T_SIM_STREAM_WORD_32 is
		variable result : T_SIM_STREAM_WORD_32;
	begin
		result := (Valid => '1', Data	=> slv,	SOF	=> '1',	EOF	=> '0', Ready => '-', EOFG => FALSE);
		report "sof: " & to_string(result) severity NOTE;
		return result;
	end;

	function sof(slvv : T_SLVV_32) return T_SIM_STREAM_WORD_VECTOR_32 is
		variable result			: T_SIM_STREAM_WORD_VECTOR_32(slvv'range);
	begin
		result(slvv'low)		:= sof(slvv(slvv'low));
		for i in slvv'low + 1 to slvv'high loop
			result(i)		:= dat(slvv(i));
		end loop;
		return result;
	end;

	function eof(slv : T_SLV_8) return T_SIM_STREAM_WORD_8 is
		variable result : T_SIM_STREAM_WORD_8;
	begin
		result := (Valid => '1', Data	=> slv,	SOF	=> '0',	EOF	=> '1', Ready => '-', EOFG => FALSE);
		report "eof: " & to_string(result) severity NOTE;
		return result;
	end;

	function eof(slvv : T_SLVV_8) return T_SIM_STREAM_WORD_VECTOR_8 is
		variable result			: T_SIM_STREAM_WORD_VECTOR_8(slvv'range);
	begin
		for i in slvv'low to slvv'high - 1 loop
			result(i)		:= dat(slvv(i));
		end loop;
		result(slvv'high)		:= eof(slvv(slvv'high));
		return result;
	end;

	function eof(slv : T_SLV_32) return T_SIM_STREAM_WORD_32 is
		variable result : T_SIM_STREAM_WORD_32;
	begin
		result := (Valid => '1', Data	=> slv,	SOF	=> '0',	EOF	=> '1', Ready => '-', EOFG => FALSE);
		report "eof: " & to_string(result) severity NOTE;
		return result;
	end;

	function eof(slvv : T_SLVV_32) return T_SIM_STREAM_WORD_VECTOR_32 is
		variable result			: T_SIM_STREAM_WORD_VECTOR_32(slvv'range);
	begin
		for i in slvv'low to slvv'high - 1 loop
			result(i)		:= dat(slvv(i));
		end loop;
		result(slvv'high)		:= eof(slvv(slvv'high));
		return result;
	end;

	function eof(stmw : T_SIM_STREAM_WORD_8) return T_SIM_STREAM_WORD_8 is
	begin
		return T_SIM_STREAM_WORD_8'(
			Valid		=> stmw.Valid,
			Data		=> stmw.Data,
			SOF			=> stmw.SOF,
			EOF			=> '1',
			Ready		=> '-',
			EOFG		=> stmw.EOFG);
	end function;

	function eof(stmw : T_SIM_STREAM_WORD_32) return T_SIM_STREAM_WORD_32 is
	begin
		return T_SIM_STREAM_WORD_32'(
			Valid		=> stmw.Valid,
			Data		=> stmw.Data,
			SOF			=> stmw.SOF,
			EOF			=> '1',
			Ready		=> '-',
			EOFG		=> stmw.EOFG);
	end function;

	function eof(stmwv : T_SIM_STREAM_WORD_VECTOR_8) return T_SIM_STREAM_WORD_VECTOR_8 is
		variable result			: T_SIM_STREAM_WORD_VECTOR_8(stmwv'range);
	begin
		for i in stmwv'low to stmwv'high - 1 loop
			result(i)		:= stmwv(i);
		end loop;
		result(stmwv'high)		:= eof(stmwv(stmwv'high));

		return result;
	end;

	function eofg(stmw : T_SIM_STREAM_WORD_8) return T_SIM_STREAM_WORD_8 is
	begin
		return T_SIM_STREAM_WORD_8'(
			Valid		=> stmw.Valid,
			Data		=> stmw.Data,
			SOF			=> stmw.SOF,
			EOF			=> stmw.EOF,
			Ready		=> stmw.Ready,
			EOFG		=> TRUE);
	end function;

	function eofg(stmw : T_SIM_STREAM_WORD_32) return T_SIM_STREAM_WORD_32 is
	begin
		return T_SIM_STREAM_WORD_32'(
			Valid		=> stmw.Valid,
			Data		=> stmw.Data,
			SOF			=> stmw.SOF,
			EOF			=> stmw.EOF,
			Ready		=> stmw.Ready,
			EOFG		=> TRUE);
	end function;

	function eofg(stmwv : T_SIM_STREAM_WORD_VECTOR_8) return T_SIM_STREAM_WORD_VECTOR_8 is
		variable result			: T_SIM_STREAM_WORD_VECTOR_8(stmwv'range);
	begin
		for i in stmwv'low to stmwv'high - 1 loop
			result(i)		:= stmwv(i);
		end loop;
		result(stmwv'high)		:= eofg(stmwv(stmwv'high));

		return result;
	end;

	function to_flag1_string(stmw : T_SIM_STREAM_WORD_8) return string is
		variable flag : std_logic_vector(2 downto 0)	:= to_sl(stmw.EOFG) & stmw.EOF & stmw.SOF;
	begin
		case flag is
			when "000" =>		return "";
			when "001" =>		return "SOF";
			when "010" =>		return "EOF";
			when "011" =>		return "SOF+EOF";
			when "100" =>		return "*";
			when "101" =>		return "SOF*";
			when "110" =>		return "EOF*";
			when "111" =>		return "SOF+EOF*";
			when others =>	return "ERROR";
		end case;
	end function;

	function to_flag1_string(stmw : T_SIM_STREAM_WORD_32) return string is
		variable flag : std_logic_vector(2 downto 0)	:= to_sl(stmw.EOFG) & stmw.EOF & stmw.SOF;
	begin
		case flag is
			when "000" =>		return "";
			when "001" =>		return "SOF";
			when "010" =>		return "EOF";
			when "011" =>		return "SOF+EOF";
			when "100" =>		return "*";
			when "101" =>		return "SOF*";
			when "110" =>		return "EOF*";
			when "111" =>		return "SOF+EOF*";
			when others =>	return "ERROR";
		end case;
	end function;

	function to_flag2_string(stmw : T_SIM_STREAM_WORD_8) return string is
		variable flag : std_logic_vector(1 downto 0)	:= stmw.Ready & stmw.Valid;
	begin
		case flag is
			when "00" =>		return "  ";
			when "01" =>		return " V";
			when "10" =>		return "R ";
			when "11" =>		return "RV";
			when "-0" =>		return "- ";
			when "-1" =>		return "-V";
			when others =>	return "??";
		end case;
	end function;

	function to_flag2_string(stmw : T_SIM_STREAM_WORD_32) return string is
		variable flag : std_logic_vector(1 downto 0)	:= stmw.Ready & stmw.Valid;
	begin
		case flag is
			when "00" =>		return "  ";
			when "01" =>		return " V";
			when "10" =>		return "R ";
			when "11" =>		return "RV";
			when "-0" =>		return "- ";
			when "-1" =>		return "-V";
			when others =>	return "??";
		end case;
	end function;

	function to_string(stmw : T_SIM_STREAM_WORD_8) return string is
	begin
		return to_flag2_string(stmw) & " 0x" & to_string(stmw.Data, 'h') & " " & to_flag1_string(stmw);
	end function;

	function to_string(stmw : T_SIM_STREAM_WORD_32) return string is
	begin
		return to_flag2_string(stmw) & " 0x" & to_string(stmw.Data, 'h') & " " & to_flag1_string(stmw);
	end function;

	-- checksum functions
	-- ================================================================
--	-- Private function to_01 copied from GlobalTypes
--	function to_01(slv : STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR is
--	begin
--	  return  to_stdlogicvector(to_bitvector(slv));
--	end;

	function sim_CRC8(words : T_SIM_STREAM_WORD_VECTOR_8) return std_logic_vector is
		constant CRC8_INIT					: T_SLV_8					:= x"FF";
		constant CRC8_POLYNOMIAL		: T_SLV_8					:= x"31";			-- 0x131

		variable CRC8_Value					: T_SLV_8					:= CRC8_INIT;

--		variable Pattern						: T_DATAFifO_PATTERN;
		variable Word								: unsigned(T_SLV_8'range);
	begin
		report "Computing CRC8 for Words " & to_string(words'low) & " to " & to_string(words'high) severity NOTE;

		for i in words'range loop
			if (words(i).Valid = '1') then
				Word	:= to_01(unsigned(words(i).Data));

--					assert (J > 9) report str_merge("  Word: 0x", hstr(Word), "    CRC16_Value: 0x", hstr(CRC16_Value)) severity NOTE;

				for j in Word'range loop
						CRC8_Value := (CRC8_Value(CRC8_Value'high - 1 downto 0) & '0') xor (CRC8_POLYNOMIAL and (CRC8_POLYNOMIAL'range => (Word(j) xor CRC8_Value(CRC8_Value'high))));
				end loop;
			end if;

			exit when (words(i).EOFG = TRUE);
		end loop;

		report "  CRC8: 0x" & to_string(CRC8_Value, 'h') severity NOTE;

		return CRC8_Value;
	end;

--	function sim_CRC16(words : T_SIM_STREAM_WORD_VECTOR_8) return STD_LOGIC_VECTOR is
--		constant CRC16_INIT					: T_SLV_16					:= x"FFFF";
--		constant CRC16_POLYNOMIAL		: T_SLV_16					:= x"8005";			-- 0x18005
--
--		variable CRC16_Value				: T_SLV_16					:= CRC16_INIT;
--
--		variable Pattern						: T_DATAFifO_PATTERN;
--		variable Word								: T_SLV_32;
--	begin
--		report str_merge("Computing CRC16 for Frames ", str(Frames'low), " to ", str(Frames'high)) severity NOTE;
--
--		for i in Frames'range loop
--			NEXT when (NOT ((Frames(i).Direction	= DEV_HOST) AND (Frames(i).DataFifOPatterns(0).Data(7 downto 0) = x"46")));
--
----			report Frames(i).Name severity NOTE;
--
--			for j in 1 to Frames(i).Count - 1 loop
--				Pattern		:= Frames(i).DataFifOPatterns(J);
--
--				if (Pattern.Valid = '1') then
--					Word	:= to_01(Pattern.Data);
--
----					assert (J > 9) report str_merge("  Word: 0x", hstr(Word), "    CRC16_Value: 0x", hstr(CRC16_Value)) severity NOTE;
--
--					for k in Word'range loop
--						CRC16_Value := (CRC16_Value(CRC16_Value'high - 1 downto 0) & '0') XOR (CRC16_POLYNOMIAL AND (CRC16_POLYNOMIAL'range => (Word(K) XOR CRC16_Value(CRC16_Value'high))));
--					end loop;
--				end if;
--
--				EXIT when (Pattern.EOTP = TRUE);
--			end loop;
--		end loop;
--
--		report str_merge("  CRC16: 0x", hstr(CRC16_Value)) severity NOTE;
--
--		return CRC16_Value;
--	end;
end package body;
