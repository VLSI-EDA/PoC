-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Authors:					Thomas B. Preusser
--									Martin Zabel
--									Patrick Lehmann
--
-- Package:					String related functions and types
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
-- =============================================================================

library	IEEE;
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;
use			IEEE.math_real.all;

library	PoC;
use			PoC.utils.all;


package strings is
	-- Type declarations
	-- ===========================================================================
	subtype T_RAWCHAR				is STD_LOGIC_VECTOR(7 downto 0);
	type		T_RAWSTRING			is array (NATURAL range <>) of T_RAWCHAR;
	
	-- testing area:
	-- ===========================================================================
	function to_IPStyle(str : STRING)			return T_IPSTYLE;

	-- to_char
	function to_char(value : STD_LOGIC)		return CHARACTER;
	function to_char(value : NATURAL)			return CHARACTER;
	function to_char(rawchar : T_RAWCHAR) return CHARACTER;	

	-- chr_is* function
	function chr_isDigit(chr : character)					return boolean;
	function chr_isLowerHexDigit(chr : character)	return boolean;
	function chr_isUpperHexDigit(chr : character)	return boolean;
	function chr_isHexDigit(chr : character)			return boolean;
	function chr_isLowerAlpha(chr : character)		return boolean;
	function chr_isUpperAlpha(chr : character)		return boolean;
	function chr_isAlpha(chr : character)					return boolean;
	
	-- raw_format_* functions
	function raw_format_bool_bin(value : BOOLEAN)				return STRING;
	function raw_format_bool_chr(value : BOOLEAN)				return STRING;
	function raw_format_bool_str(value : BOOLEAN)				return STRING;
	function raw_format_slv_bin(slv : STD_LOGIC_VECTOR)	return STRING;
	function raw_format_slv_oct(slv : STD_LOGIC_VECTOR)	return STRING;
	function raw_format_slv_hex(slv : STD_LOGIC_VECTOR)	return STRING;
	function raw_format_nat_bin(value : NATURAL)				return STRING;
	function raw_format_nat_oct(value : NATURAL)				return STRING;
	function raw_format_nat_dec(value : NATURAL)				return STRING;
	function raw_format_nat_hex(value : NATURAL)				return STRING;
	
	-- str_format_* functions
	function str_format(value : REAL; precision : NATURAL := 3) return STRING;
	
	-- to_string
	function to_string(value : BOOLEAN) return STRING;	
	function to_string(value : INTEGER; base : POSITIVE := 10) return STRING;
	function to_string(slv : STD_LOGIC_VECTOR; format : CHARACTER; length : NATURAL := 0; fill : CHARACTER := '0') return STRING;
	function to_string(rawstring : T_RAWSTRING) return STRING;

	-- to_slv
	function to_slv(rawstring : T_RAWSTRING) return STD_LOGIC_VECTOR;

	-- to_digit*
	function to_digit_bin(chr : character) return integer;
	function to_digit_oct(chr : character) return integer;
	function to_digit_dec(chr : character) return integer;
	function to_digit_hex(chr : character) return integer;
	function to_digit(chr : character; base : character := 'd') return integer;

	-- to_natural*
	function to_natural_bin(str : STRING) return INTEGER;
	function to_natural_oct(str : STRING) return INTEGER;
	function to_natural_dec(str : STRING) return INTEGER;
	function to_natural_hex(str : STRING) return INTEGER;
	function to_natural(str : STRING; base : CHARACTER := 'd') return INTEGER;
	
	-- to_raw*
	function to_RawChar(char : character) return T_RAWCHAR;
	function to_RawString(str : string)		return T_RAWSTRING;
	
	-- resize
	function resize(str : STRING; size : POSITIVE; FillChar : CHARACTER := NUL) return STRING;
	function resize(rawstr : T_RAWSTRING; size : POSITIVE; FillChar : T_RAWCHAR := x"00") return T_RAWSTRING;

	-- Character functions
	function chr_to_lower(chr : character) return character;
	function chr_to_upper(chr : character) return character;
	
	-- String functions
	function str_length(str : STRING)									return NATURAL;
	function str_equal(str1 : STRING; str2 : STRING)	return BOOLEAN;
	function str_match(str1 : STRING; str2 : STRING)	return BOOLEAN;
	function str_imatch(str1 : STRING; str2 : STRING)	return BOOLEAN;
	function str_pos(str : STRING; chr : CHARACTER; start : NATURAL := 0)	return INTEGER;
	function str_pos(str : STRING; search : STRING; start : NATURAL := 0)	return INTEGER;
	function str_find(str : STRING; chr : CHARACTER)	return BOOLEAN;
	function str_find(str : STRING; search : STRING)	return BOOLEAN;
	function str_replace(str : STRING; search : STRING; replace : STRING) return STRING;
	function str_trim(str : STRING)											return STRING;
	function str_ltrim(str : STRING; char : CHARACTER)	return STRING;
	function str_to_lower(str : STRING)									return STRING;
	function str_to_upper(str : STRING)									return STRING;
	function str_substr(str : STRING; start : INTEGER := 0; length : INTEGER := 0) return STRING;

end package;


package body strings is

	-- 
	function to_IPStyle(str : STRING) return T_IPSTYLE is
	begin
		for i in T_IPSTYLE'pos(T_IPSTYLE'low) to T_IPSTYLE'pos(T_IPSTYLE'high) loop
			if str_imatch(str, T_IPSTYLE'image(T_IPSTYLE'val(I))) then
				return T_IPSTYLE'val(i);
			end if;
		end loop;
		
		report "Unknown IPStyle: '" & str & "'" severity FAILURE;
	end function;

	-- to_char
	-- ===========================================================================
	function to_char(value : STD_LOGIC) return CHARACTER is
	begin
		case value IS
			when 'U' =>			return 'U';
			when 'X' =>			return 'X';
			when '0' =>			return '0';
			when '1' =>			return '1';
			when 'Z' =>			return 'Z';
			when 'W' =>			return 'W';
			when 'L' =>			return 'L';
			when 'H' =>			return 'H';
			when '-' =>			return '-';
			when others =>	return 'X';
		end case;
	end function;

	-- TODO: rename to to_HexDigit(..) ?
	function to_char(value : natural) return character is
	  constant  HEX : string := "0123456789ABCDEF";
	begin
		return  ite(value < 16, HEX(value+1), 'X');
	end function;

	function to_char(rawchar : T_RAWCHAR) return CHARACTER is
	begin
		return CHARACTER'val(to_integer(unsigned(rawchar)));
	end function;

		-- chr_is* function
	function chr_isDigit(chr : character) return boolean is
	begin
		return (character'pos('0') <= character'pos(chr)) and (character'pos(chr) <= character'pos('9'));
	end function;
	
	function chr_isLowerHexDigit(chr : character) return boolean is
	begin
		return (character'pos('a') <= character'pos(chr)) and (character'pos(chr) <= character'pos('f'));
	end function;
	
	function chr_isUpperHexDigit(chr : character) return boolean is
	begin
		return (character'pos('A') <= character'pos(chr)) and (character'pos(chr) <= character'pos('F'));
	end function;

	function chr_isHexDigit(chr : character) return boolean is
	begin
		return chr_isDigit(chr) or chr_isLowerHexDigit(chr) or chr_isUpperHexDigit(chr);
	end function;

	function chr_isLowerAlpha(chr : character) return boolean is
	begin
		return (character'pos('a') <= character'pos(chr)) and (character'pos(chr) <= character'pos('z'));
	end function;
	
	function chr_isUpperAlpha(chr : character) return boolean is
	begin
		return (character'pos('A') <= character'pos(chr)) and (character'pos(chr) <= character'pos('Z'));
	end function;

	function chr_isAlpha(chr : character) return boolean is
	begin
		return chr_isLowerAlpha(chr) or chr_isUpperAlpha(chr);
	end function;
	
	-- str_format_* functions
	-- ===========================================================================
	function raw_format_bool_bin(value : BOOLEAN) return STRING is
	begin
		return ite(value, "1", "0");
	end function;
	
	function raw_format_bool_chr(value : BOOLEAN) return STRING is
	begin
		return ite(value, "T", "F");
	end function;
	
	function raw_format_bool_str(value : BOOLEAN) return STRING is
	begin
		return str_to_upper(boolean'image(value));
	end function;
	
	function raw_format_slv_bin(slv : STD_LOGIC_VECTOR) return STRING is
		variable Value				: STD_LOGIC_VECTOR(slv'length - 1 downto 0);
		variable Result				: STRING(1 to slv'length);
		variable j						: NATURAL;
	begin
		-- convert input slv to a downto ranged vector and normalize range to slv'low = 0
		Value := movez(ite(slv'ascending, descend(slv), slv));
		
		-- convert each bit to a character
		J				:= 0;
		for i in Result'reverse_range loop
			Result(i)	:= to_char(Value(j));
			j					:= j + 1;
		end loop;
		
		return Result;
	end function;
	
	function raw_format_slv_oct(slv : STD_LOGIC_VECTOR) return STRING is
		variable Value				: STD_LOGIC_VECTOR(slv'length - 1 downto 0);
		variable Digit				: STD_LOGIC_VECTOR(2 downto 0);
		variable Result				: STRING(1 to div_ceil(slv'length, 3));
		variable j						: NATURAL;
	begin
		-- convert input slv to a downto ranged vector; normalize range to slv'low = 0 and resize it to a multiple of 3
		Value := resize(movez(ite(slv'ascending, descend(slv), slv)), (Result'length * 3));
		
		-- convert 3 bit to a character
		j				:= 0;
		for i in Result'reverse_range loop
			Digit			:= Value((j * 3) + 2 downto (j * 3));
			Result(i)	:= to_char(to_integer(unsigned(Digit)));
			j					:= j + 1;
		end loop;
		
		return Result;
	end function;
	
	function raw_format_slv_hex(slv : STD_LOGIC_VECTOR) return STRING is
		variable Value				: STD_LOGIC_VECTOR(4*div_ceil(slv'length, 4) - 1 downto 0);
		variable Digit				: STD_LOGIC_VECTOR(3 downto 0);
		variable Result				: STRING(1 to div_ceil(slv'length, 4));
		variable j						: NATURAL;
	begin
		Value := resize(slv, Value'length);
		j			:= 0;
		for i in Result'reverse_range loop
			Digit			:= Value((j * 4) + 3 downto (j * 4));
			Result(i)	:= to_char(to_integer(unsigned(Digit)));
			j					:= j + 1;
		end loop;
		
		return Result;
	end function;

	function raw_format_nat_bin(value : NATURAL) return STRING is
	begin
		return raw_format_slv_bin(to_slv(value, log2ceilnz(value+1)));
	end function;
	
	function raw_format_nat_oct(value : NATURAL) return STRING is
	begin
		return raw_format_slv_oct(to_slv(value, log2ceilnz(value+1)));
	end function;
	
	function raw_format_nat_dec(value : NATURAL) return STRING is
	begin
		return INTEGER'image(value);
	end function;
	
	function raw_format_nat_hex(value : NATURAL) return STRING is
	begin
		return raw_format_slv_hex(to_slv(value, log2ceilnz(value+1)));
	end function;
	
	-- str_format_* functions
	-- ===========================================================================
	function str_format(value : REAL; precision : NATURAL := 3) return STRING is
		constant s		: REAL			:= sign(value);
		constant int	: INTEGER		:= integer(floor(value * s));
		constant frac	: INTEGER		:= integer(floor(((value * s) - real(int)) * 10.0**precision));
		constant res	: STRING		:= raw_format_nat_dec(int) & "." & raw_format_nat_dec(frac);
	begin
		if (POC_VERBOSE = TRUE) then
			report "str_format:" & CR &
						 "  value:" & REAL'image(value) & CR &
						 "  int = " & INTEGER'image(int) & CR &
						 "  frac = " & INTEGER'image(frac)
			severity note;
		end if;
		return ite((s	< 0.0), "-" & res, res);
	end function;
	
	-- to_string
	-- ===========================================================================
	function to_string(value : boolean) return string is
	begin
		return raw_format_bool_str(value);
	end function;

	function to_string(value : INTEGER; base : POSITIVE := 10) return STRING is
		constant absValue		: NATURAL								:= abs(value);
		constant len		 		: POSITIVE							:= log10ceilnz(absValue);
		variable power			: POSITIVE							:= 1;
		variable Result			: STRING(1 TO len);

	begin
		if (base = 10) then
			return INTEGER'image(value);
		else
			for i in len downto 1 loop
				Result(i)		:= to_char(absValue / power MOD base);
				power				:= power * base;
			end loop;

			if (value < 0) then
				return '-' & Result;
			else
				return Result;
			end if;
		end if;
	end function;

	-- TODO: rename to slv_format(..) ?
	function to_string(slv : STD_LOGIC_VECTOR; format : CHARACTER; length : NATURAL := 0; fill : CHARACTER := '0') return STRING is
		constant int					: INTEGER				:= ite((slv'length <= 31), to_integer(unsigned(resize(slv, 31))), 0);
		constant str					: STRING				:= INTEGER'image(int);
		constant bin_len			: POSITIVE			:= slv'length;
		constant dec_len			: POSITIVE			:= str'length;--log10ceilnz(int);
		constant hex_len			: POSITIVE			:= ite(((bin_len MOD 4) = 0), (bin_len / 4), (bin_len / 4) + 1);
		constant len					: NATURAL				:= ite((format = 'b'), bin_len,
																						 ite((format = 'd'), dec_len,
																						 ite((format = 'h'), hex_len, 0)));
		
		variable j						: NATURAL				:= 0;
		variable Result				: STRING(1 to ite((length = 0), len, imax(len, length)))	:= (others => fill);
		
	begin
		if (format = 'b') then
			for i in Result'reverse_range loop
				Result(i)		:= to_char(slv(j));
				j						:= j + 1;
			end loop;
		elsif (format = 'd') then
			Result(Result'length - str'length + 1 to Result'high)	:= str;
		elsif (format = 'h') then
			for i in Result'reverse_range loop
				Result(i)		:= to_char(to_integer(unsigned(slv((j * 4) + 3 downto (j * 4)))));
				j						:= j + 1;
			end loop;
		else
			report "unknown format" severity FAILURE;
		end if;
		
		return Result;
	end function;

	function to_string(rawstring : T_RAWSTRING) return STRING is
		variable str		: STRING(1 to rawstring'length);
	begin
		for i in rawstring'low to rawstring'high loop
			str(I - rawstring'low + 1)	:= to_char(rawstring(I));
		end loop;
	
		return str;
	end function;

	-- to_slv
	-- ===========================================================================
	function to_slv(rawstring : T_RAWSTRING) return STD_LOGIC_VECTOR is
		variable result : STD_LOGIC_VECTOR((rawstring'length * 8) - 1 downto 0);
	begin
		for i in rawstring'range loop
			result(((i - rawstring'low) * 8) + 7 downto (i - rawstring'low) * 8)	:= rawstring(i);
		end loop;
		return result;
	end function;
	
	-- to_*
	-- ===========================================================================
	function to_digit_bin(chr : character) return integer is
	begin
		case chr is
			when '0' =>			return 0;
			when '1' =>			return 1;
			when others =>	return -1;
		end case;
	end function;
	
	function to_digit_oct(chr : character) return integer is
		variable dec : integer;
	begin
		dec := to_digit_dec(chr);
		return ite((dec < 8), dec, -1);
	end function;
	
	function to_digit_dec(chr : character) return integer is
	begin
		if chr_isDigit(chr) then
			return character'pos(chr) - character'pos('0');
		else
			return -1;
		end if;
	end function;
	
	function to_digit_hex(chr : character) return integer is
	begin
		if chr_isDigit(chr) then						return character'pos(chr) - character'pos('0');
		elsif chr_isLowerHexDigit(chr) then	return character'pos(chr) - character'pos('a') + 10;
		elsif chr_isUpperHexDigit(chr) then	return character'pos(chr) - character'pos('A') + 10;
		else																return -1;
		end if;
	end function;
	
	function to_digit(chr : character; base : character := 'd') return integer is
	begin
		case base is
			when 'b' =>			return to_digit_bin(chr);
			when 'o' =>			return to_digit_oct(chr);
			when 'd' =>			return to_digit_dec(chr);
			when 'h' =>			return to_digit_hex(chr);
			when others =>	report "Unknown base character: " & base & "." severity failure;
											-- return statement is explicitly missing otherwise XST won't stop
		end case;
	end function;

	function to_natural_bin(str : STRING) return INTEGER is
		variable Result			: NATURAL;
		variable Digit			: INTEGER;
	begin
		for i in str'range loop
			Digit	:= to_digit_bin(str(I));
			if (Digit /= -1) then
				Result	:= Result * 2 + Digit;
			else
				return -1;
			end if;
		end loop;
				
		return Result;
	end function;

	function to_natural_oct(str : STRING) return INTEGER is
		variable Result			: NATURAL;
		variable Digit			: INTEGER;
	begin
		for i in str'range loop
			Digit	:= to_digit_oct(str(I));
			if (Digit /= -1) then
				Result	:= Result * 8 + Digit;
			else
				return -1;
			end if;
		end loop;
				
		return Result;
	end function;

	function to_natural_dec(str : STRING) return INTEGER is
		variable Result			: NATURAL;
		variable Digit			: INTEGER;
	begin
		for i in str'range loop
			Digit	:= to_digit_dec(str(I));
			if (Digit /= -1) then
				Result	:= Result * 10 + Digit;
			else
				return -1;
			end if;
		end loop;
				
		return Result;
--		return INTEGER'value(str);			-- 'value(...) is not supported by Vivado Synth 2014.1
	end function;

	function to_natural_hex(str : STRING) return INTEGER is
		variable Result			: NATURAL;
		variable Digit			: INTEGER;
	begin
		for i in str'range loop
			Digit	:= to_digit_hex(str(I));
			if (Digit /= -1) then
				Result	:= Result * 16 + Digit;
			else
				return -1;
			end if;
		end loop;
				
		return Result;
	end function;

	function to_natural(str : STRING; base : CHARACTER := 'd') return INTEGER is
	begin
		case base is
			when 'b' =>			return to_natural_bin(str);
			when 'o' =>			return to_natural_oct(str);
			when 'd' =>			return to_natural_dec(str);
			when 'h' =>			return to_natural_hex(str);
			when others =>	report "unknown base" severity ERROR;
		end case;
	end function;

	-- to_raw*
	-- ===========================================================================
	function to_RawChar(char : character) return t_rawchar is
	begin
		return std_logic_vector(to_unsigned(character'pos(char), t_rawchar'length));
	end function;

	function to_RawString(str : STRING) return T_RAWSTRING is
		variable rawstr			: T_RAWSTRING(0 to str'length - 1);
	begin
		for i in str'low to str'high loop
			rawstr(i - str'low)	:= to_RawChar(str(i));
		end loop;
		return rawstr;
	end function;

	-- resize
	-- ===========================================================================
	function resize(str : STRING; size : POSITIVE; FillChar : CHARACTER := NUL) return STRING is
		constant MaxLength	: NATURAL								:= imin(size, str'length);
		variable Result			: STRING(1 to size)			:= (others => FillChar);
	begin
		--report "resize: str='" & str & "' size=" & INTEGER'image(size) severity note;
		if (MaxLength > 0) then
			Result(1 to MaxLength) := str(str'low to str'low + MaxLength - 1);
		end if;
		return Result;
	end function;

	function resize(rawstr : T_RAWSTRING; size : POSITIVE; FillChar : T_RAWCHAR := x"00") return T_RAWSTRING is
		constant MaxLength	: POSITIVE																					:= imin(size, rawstr'length);
		variable Result			: T_RAWSTRING(rawstr'low to rawstr'low + size - 1)	:= (others => FillChar);
	begin
		Result(rawstr'low to rawstr'low + MaxLength - 1) := rawstr(rawstr'low to rawstr'low + MaxLength - 1);
		return Result;
	end function;

	-- Character functions
	-- ===========================================================================
	function chr_to_lower(chr : character) return character is
	begin
		if chr_isUpperAlpha(chr) then
			return character'val(character'pos(chr) - character'pos('A') + character'pos('a'));
		else
			return chr;
		end if;
	end function;
	
	function chr_to_upper(chr : character) return character is
	begin
		if chr_isLowerAlpha(chr) then
			return character'val(character'pos(chr) - character'pos('a') + character'pos('A'));
		else
			return chr;
		end if;	
	end function;
	
	-- String functions
	-- ===========================================================================
	function str_length(str : STRING) return NATURAL is
	begin
		for i in str'range loop
			if (str(i) = NUL) then
				return i - str'low;
			end if;
		end loop;
		return str'length;
	end function;
	
	function str_equal(str1 : STRING; str2 : STRING) return BOOLEAN is
	begin
		if str1'length /= str2'length then
			return FALSE;
		else
			return (str1 = str2);
		end if;
	end function;

	function str_match(str1 : STRING; str2 : STRING) return BOOLEAN is
		constant len1 : NATURAL := str_length(str1);
	begin
		if (len1 /= str_length(str2)) then
			return FALSE;
		else
			return (resize(str1, len1) = resize(str2, len1));
		end if;
	end function;

	function str_imatch(str1 : STRING; str2 : STRING) return BOOLEAN is
		constant len1 : NATURAL := str_length(str1);
	begin
		if (len1 /= str_length(str2)) then
			return FALSE;
		else
			return (str_to_lower(resize(str1, len1)) = str_to_lower(resize(str2, len1)));
		end if;
	end function;

	function str_pos(str : STRING; chr : CHARACTER; start : NATURAL := 0) return INTEGER is
	begin
		for i in imax(str'low, start) to str'high loop
			exit when (str(i) = NUL);
			if (str(i) = chr) then
				return i;
			end if;
		end loop;
		return -1;
	end function;
	
	function str_pos(str : STRING; search : STRING; start : NATURAL := 0) return INTEGER is
	begin
		for i in imax(str'low, start) to (str'high - search'length + 1) loop
			exit when (str(i) = NUL);
			if (str(i to i + search'length - 1) = search) then
				return i;
			end if;
		end loop;
		return -1;
	end function;
	
--	function str_pos(str1 : STRING; str2 : STRING) return INTEGER is
--		variable PrefixTable	: T_INTVEC(0 to str2'length);
--		variable j						: INTEGER;
--	begin
--		-- construct prefix table for KMP algorithm
--		j								:= -1;
--		PrefixTable(0)	:= -1;
--		for i in str2'range loop
--			while ((j >= 0) and str2(j + 1) /= str2(i)) loop
--				j		:= PrefixTable(j);
--			end loop;
--		
--			j										:= j + 1;
--			PrefixTable(i - 1)	:= j + 1;
--		end loop;
--		
--		-- search pattern str2 in text str1
--		j := 0;
--		for i in str1'range loop
--			while ((j >= 0) and str1(i) /= str2(j + 1)) loop
--				j		:= PrefixTable(j);
--			end loop;
--		
--			j := j + 1;
--			if ((j + 1) = str2'high) then
--				return i - str2'length + 1;
--			end if;
--		end loop;
--
--		return -1;
--	end function;
	
	function str_find(str : STRING; chr : CHARACTER) return boolean is
	begin
		return (str_pos(str, chr) > 0);
	end function;
	
	function str_find(str : STRING; search : STRING) return boolean is
	begin
		return (str_pos(str, search) > 0);
	end function;
	
	function str_replace(str : STRING; search : STRING; replace : STRING) return STRING is
		variable pos		: INTEGER;
	begin
		pos := str_pos(str, search);
--		report "str_replace: pos=" & INTEGER'image(pos) severity note;
		if (pos > 0) then
			if (pos = 1) then
				return replace & str(search'length + 1 to str'length);
			elsif (pos = str'length - search'length + 1) then
				return str(1 to str'length - search'length) & replace;
			else
				return str(1 to pos - 1) & replace & str(pos + search'length to str'length);
			end if;
		else
			return str;
		end if;
	end function;
	
	function str_trim(str : STRING) return STRING is
	begin
		for i in str'range loop
			if (str(i) = NUL) then
				return str(str'low to i - 1);
			end if;
		end loop;
		return str;
	end function;
	
	function str_ltrim(str : STRING; char : CHARACTER) return STRING is
	begin
		for i in str'range loop
			report "str_ltrim: i=" & INTEGER'image(i) severity note;
			if (str(i) /= char) then
				return str(i to str'high);
			end if;
		end loop;
		return "";
	end function;
	
	function str_to_lower(str : STRING) return STRING is
		variable temp		: STRING(str'range);
	begin
		for i in str'range loop
			temp(I)	:= chr_to_lower(str(I));
		end loop;
		return temp;
	end function;
	
	function str_to_upper(str : STRING) return STRING is
		variable temp		: STRING(str'range);
	begin
		for i in str'range loop
			temp(I)	:= chr_to_upper(str(I));
		end loop;
		return temp;
	end function;

	-- examples:
	--							  123456789ABC
	-- input string: "Hello World."
	--	low=1; high=12; length=12
	--
	--	str_substr("Hello World.",	0,	0)	=> "Hello World."		- copy all
	--	str_substr("Hello World.",	7,	0)	=> "World."					- copy from pos 7 to end of string
	--	str_substr("Hello World.",	7,	5)	=> "World"					- copy from pos 7 for 5 characters
	--	str_substr("Hello World.",	0, -7)	=> "Hello World."		- copy all until character 8 from right boundary
	
	function str_substr(str : STRING; start : INTEGER := 0; length : INTEGER := 0) return STRING is
		variable StartOfString		: positive;
		variable EndOfString			: positive;
	begin
		if (start < 0) then			-- start is negative -> start substring at right string boundary
			StartOfString		:= str'high + start + 1;
		elsif (start = 0) then	-- start is zero -> start substring at left string boundary
			StartOfString		:= str'low;
		else 										-- start is positive -> start substring at left string boundary + offset
			StartOfString		:= start;
		end if;

		if (length < 0) then		-- length is negative -> end substring at length'th character before right string boundary
			EndOfString			:= str'high + length;
		elsif (length = 0) then	-- length is zero -> end substring at right string boundary
			EndOfString			:= str'high;
		else										-- length is positive -> end substring at StartOfString + length
			EndOfString			:= StartOfString + length - 1;
		end if;
		
		if (StartOfString < str'low) then			report "StartOfString is out of str's range. (str=" & str & ")" severity error;		end if;
		if (EndOfString < str'high) then			report "EndOfString is out of str's range. (str=" & str & ")" severity error;			end if;
		
		return str(StartOfString to EndOfString);
	end function;
	
end package body;
