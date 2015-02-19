-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Package:					Common functions and types
--
-- Authors:					Thomas B. Preusser
--									Martin Zabel
--									Patrick Lehmann
--
-- Description:
-- ------------------------------------
--		For detailed documentation see below.
--
-- License:
-- ============================================================================
-- Copyright 2007-2014 Technische Universitaet Dresden - Germany
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

library	IEEE;
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;

library	PoC;
use			PoC.utils.all;
use			PoC.strings.all;


package vectors is
	-- ==========================================================================
	-- Type declarations
	-- ==========================================================================
	-- STD_LOGIC_VECTORs
	SUBTYPE T_SLV_2							IS STD_LOGIC_VECTOR(1 DOWNTO 0);
	SUBTYPE T_SLV_3							IS STD_LOGIC_VECTOR(2 DOWNTO 0);
	SUBTYPE T_SLV_4							IS STD_LOGIC_VECTOR(3 DOWNTO 0);
	SUBTYPE T_SLV_8							IS STD_LOGIC_VECTOR(7 DOWNTO 0);
	SUBTYPE T_SLV_12						IS STD_LOGIC_VECTOR(11 DOWNTO 0);
	SUBTYPE T_SLV_16						IS STD_LOGIC_VECTOR(15 DOWNTO 0);
	SUBTYPE T_SLV_24						IS STD_LOGIC_VECTOR(23 DOWNTO 0);
	SUBTYPE T_SLV_32						IS STD_LOGIC_VECTOR(31 DOWNTO 0);
	SUBTYPE T_SLV_48						IS STD_LOGIC_VECTOR(47 DOWNTO 0);
	SUBTYPE T_SLV_64						IS STD_LOGIC_VECTOR(63 DOWNTO 0);
	SUBTYPE T_SLV_96						IS STD_LOGIC_VECTOR(95 DOWNTO 0);
	SUBTYPE T_SLV_128						IS STD_LOGIC_VECTOR(127 DOWNTO 0);
	SUBTYPE T_SLV_256						IS STD_LOGIC_VECTOR(255 DOWNTO 0);
	SUBTYPE T_SLV_512						IS STD_LOGIC_VECTOR(511 DOWNTO 0);
	
	-- STD_LOGIC_VECTOR_VECTORs
	--	TYPE		T_SLVV							IS ARRAY(NATURAL RANGE <>) OF STD_LOGIC_VECTOR;					-- VHDL 2008 syntax - not yet supported by Xilinx
	TYPE		T_SLVV_2						IS ARRAY(NATURAL RANGE <>) OF T_SLV_2;
	TYPE		T_SLVV_3						IS ARRAY(NATURAL RANGE <>) OF T_SLV_3;
	TYPE		T_SLVV_4						IS ARRAY(NATURAL RANGE <>) OF T_SLV_4;
	TYPE		T_SLVV_8						IS ARRAY(NATURAL RANGE <>) OF T_SLV_8;
	TYPE		T_SLVV_12						IS ARRAY(NATURAL RANGE <>) OF T_SLV_12;
	TYPE		T_SLVV_16						IS ARRAY(NATURAL RANGE <>) OF T_SLV_16;
	TYPE		T_SLVV_24						IS ARRAY(NATURAL RANGE <>) OF T_SLV_24;
	TYPE		T_SLVV_32						IS ARRAY(NATURAL RANGE <>) OF T_SLV_32;
	TYPE		T_SLVV_48						IS ARRAY(NATURAL RANGE <>) OF T_SLV_48;
	TYPE		T_SLVV_64						IS ARRAY(NATURAL RANGE <>) OF T_SLV_64;
	TYPE		T_SLVV_128					IS ARRAY(NATURAL RANGE <>) OF T_SLV_128;
	TYPE		T_SLVV_256					IS ARRAY(NATURAL RANGE <>) OF T_SLV_256;
	TYPE		T_SLVV_512					IS ARRAY(NATURAL RANGE <>) OF T_SLV_512;

	-- STD_LOGIC_MATRIXs
	TYPE		T_SLM								IS ARRAY(NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC;
	-- ATTENTION:
	-- 1.	you MUST initialize your matrix signal with 'Z' to get correct simulation results (iSIM, vSIM, ghdl/gtkwave)
	--		Example: SIGNAL myMatrix	: T_SLM(3 DOWNTO 0, 7 DOWNTO 0)			:= (OTHERS => (OTHERS => 'Z'));
	-- 2.	Xilinx iSIM work-around: DON'T use myMatrix'range(n) for n >= 2
	--		because: myMatrix'range(2) returns always myMatrix'range(1);	tested with ISE/iSIM 14.2
	-- USAGE NOTES:
	--	dimmension 1 => rows			- e.g. Words
	--	dimmension 2 => columns		- e.g. Bits/Bytes in a word


  -- ==========================================================================
  -- Function declarations
  -- ==========================================================================
  -- slicing boundary calulations
  FUNCTION low (lenvec : T_POSVEC; index : NATURAL) RETURN NATURAL;
  FUNCTION high(lenvec : T_POSVEC; index : NATURAL) RETURN NATURAL;

	-- Assign procedures: assign_*
	PROCEDURE assign_row(SIGNAL slm : OUT T_SLM; slv : STD_LOGIC_VECTOR; CONSTANT RowIndex : NATURAL);																	-- assign vector to complete row
	PROCEDURE assign_row(SIGNAL slm : OUT T_SLM; slv : STD_LOGIC_VECTOR; CONSTANT RowIndex : NATURAL; Position : NATURAL);							-- assign short vector to row starting at position
	PROCEDURE assign_row(SIGNAL slm : OUT T_SLM; slv : STD_LOGIC_VECTOR; CONSTANT RowIndex : NATURAL; High : NATURAL; Low : NATURAL);		-- assign short vector to row in range high:low
	PROCEDURE assign_col(SIGNAL slm : OUT T_SLM; slv : STD_LOGIC_VECTOR; CONSTANT ColIndex : NATURAL);																	-- assign vector to complete column
	-- ATTENTION:	see T_SLM definition for further details and work-arounds

	-- Matrix to matrix conversion: slm_slice*
	FUNCTION slm_slice(slm : T_SLM; RowIndex : NATURAL; ColIndex : NATURAL; Height : NATURAL; Width : NATURAL) RETURN T_SLM;						-- get submatrix in boundingbox RowIndex,ColIndex,Height,Width
	FUNCTION slm_slice_cols(slm : T_SLM; High : NATURAL; Low : NATURAL) RETURN T_SLM;																										-- get submatrix / all columns in ColIndex range high:low

	-- Matrix to vector conversion: get_*
	FUNCTION get_col(slm : T_SLM; ColIndex : NATURAL) RETURN STD_LOGIC_VECTOR;																	-- get a matrix column
	FUNCTION get_row(slm : T_SLM; RowIndex : NATURAL)	RETURN STD_LOGIC_VECTOR;																	-- get a matrix row
	FUNCTION get_row(slm : T_SLM; RowIndex : NATURAL; Length : POSITIVE)	RETURN STD_LOGIC_VECTOR;							-- get a matrix row of defined length [length - 1 downto 0]
	FUNCTION get_row(slm : T_SLM; RowIndex : NATURAL; High : NATURAL; Low : NATURAL) RETURN STD_LOGIC_VECTOR;		-- get a sub vector of a matrix row at high:low

	-- Convert to vector: to_slv
	FUNCTION to_slv(slvv : T_SLVV_8)										RETURN STD_LOGIC_VECTOR;					-- convert vector-vector to flatten vector
	
	-- Convert flat vector to avector-vector: to_slvv_*
	FUNCTION to_slvv_4(slv : STD_LOGIC_VECTOR)		RETURN T_SLVV_4;												-- 
	FUNCTION to_slvv_8(slv : STD_LOGIC_VECTOR)		RETURN T_SLVV_8;												-- 
	FUNCTION to_slvv_12(slv : STD_LOGIC_VECTOR)		RETURN T_SLVV_12;												-- 
	FUNCTION to_slvv_16(slv : STD_LOGIC_VECTOR)		RETURN T_SLVV_16;												-- 
	FUNCTION to_slvv_32(slv : STD_LOGIC_VECTOR)		RETURN T_SLVV_32;												-- 
	FUNCTION to_slvv_64(slv : STD_LOGIC_VECTOR)		RETURN T_SLVV_64;												-- 
	FUNCTION to_slvv_128(slv : STD_LOGIC_VECTOR)	RETURN T_SLVV_128;											-- 
	FUNCTION to_slvv_256(slv : STD_LOGIC_VECTOR)	RETURN T_SLVV_256;											-- 
	FUNCTION to_slvv_512(slv : STD_LOGIC_VECTOR)	RETURN T_SLVV_512;											-- 

	-- Convert matrix to avector-vector: to_slvv_*
	FUNCTION to_slvv_4(slm : T_SLM)		RETURN T_SLVV_4;																		-- 
	FUNCTION to_slvv_8(slm : T_SLM)		RETURN T_SLVV_8;																		-- 
	FUNCTION to_slvv_12(slm : T_SLM)	RETURN T_SLVV_12;																		-- 
	FUNCTION to_slvv_16(slm : T_SLM)	RETURN T_SLVV_16;																		-- 
	FUNCTION to_slvv_32(slm : T_SLM)	RETURN T_SLVV_32;																		-- 
	FUNCTION to_slvv_64(slm : T_SLM)	RETURN T_SLVV_64;																		-- 
	FUNCTION to_slvv_128(slm : T_SLM)	RETURN T_SLVV_128;																	-- 
	FUNCTION to_slvv_256(slm : T_SLM)	RETURN T_SLVV_256;																	-- 
	FUNCTION to_slvv_512(slm : T_SLM)	RETURN T_SLVV_512;																	-- 
	
	-- Convert vector-vector to matrix: to_slm
	FUNCTION to_slm(slvv : T_SLVV_4) RETURN T_SLM;																				-- create matrix from vector-vector
	FUNCTION to_slm(slvv : T_SLVV_8) RETURN T_SLM;																				-- create matrix from vector-vector
	FUNCTION to_slm(slvv : T_SLVV_12) RETURN T_SLM;																				-- create matrix from vector-vector
	FUNCTION to_slm(slvv : T_SLVV_16) RETURN T_SLM;																				-- create matrix from vector-vector
	FUNCTION to_slm(slvv : T_SLVV_32) RETURN T_SLM;																				-- create matrix from vector-vector
	FUNCTION to_slm(slvv : T_SLVV_48) RETURN T_SLM;																				-- create matrix from vector-vector
	FUNCTION to_slm(slvv : T_SLVV_64) RETURN T_SLM;																				-- create matrix from vector-vector
	FUNCTION to_slm(slvv : T_SLVV_128) RETURN T_SLM;																			-- create matrix from vector-vector
	FUNCTION to_slm(slvv : T_SLVV_256) RETURN T_SLM;																			-- create matrix from vector-vector
	FUNCTION to_slm(slvv : T_SLVV_512) RETURN T_SLM;																			-- create matrix from vector-vector

	-- Change vector direction
	FUNCTION dir(slvv : T_SLVV_8)			RETURN T_SLVV_8;
	
	-- Reverse vector elements
	FUNCTION rev(slvv : T_SLVV_4)			RETURN T_SLVV_4;
	FUNCTION rev(slvv : T_SLVV_8)			RETURN T_SLVV_8;
	FUNCTION rev(slvv : T_SLVV_12)		RETURN T_SLVV_12;
	FUNCTION rev(slvv : T_SLVV_16)		RETURN T_SLVV_16;
	FUNCTION rev(slvv : T_SLVV_32)		RETURN T_SLVV_32;
	FUNCTION rev(slvv : T_SLVV_64)		RETURN T_SLVV_64;
	FUNCTION rev(slvv : T_SLVV_128)		RETURN T_SLVV_128;
	FUNCTION rev(slvv : T_SLVV_256)		RETURN T_SLVV_256;
	FUNCTION rev(slvv : T_SLVV_512)		RETURN T_SLVV_512;
	
	-- TODO:
	FUNCTION resize(slm : T_SLM; size : POSITIVE) RETURN T_SLM;

	-- to_string
	FUNCTION to_string(slvv : T_SLVV_8; sep : CHARACTER := ':') RETURN STRING;
end package vectors;


package body vectors is
	-- slicing boundary calulations
	-- ==========================================================================
	FUNCTION low(lenvec : T_POSVEC; index : NATURAL) RETURN NATURAL IS
		VARIABLE pos		: NATURAL		:= 0;
	BEGIN
		FOR I IN lenvec'low TO index - 1 LOOP
			pos := pos + lenvec(I);
		END LOOP;
		RETURN pos;
	END FUNCTION;
	
	FUNCTION high(lenvec : T_POSVEC; index : NATURAL) RETURN NATURAL IS
		VARIABLE pos		: NATURAL		:= 0;
	BEGIN
		FOR I IN lenvec'low TO index LOOP
			pos := pos + lenvec(I);
		END LOOP;
		RETURN pos - 1;
	END FUNCTION;

	-- Assign procedures: assign_*
	-- ==========================================================================
	PROCEDURE assign_row(SIGNAL slm : OUT T_SLM; slv : STD_LOGIC_VECTOR; CONSTANT RowIndex : NATURAL) IS
		VARIABLE temp : STD_LOGIC_VECTOR(slm'high(2) DOWNTO slm'low(2));					-- Xilinx iSIM work-around, because 'range(2) evaluates to 'range(1); tested with ISE/iSIM 14.2
	BEGIN
		temp := slv;
		FOR I IN temp'range LOOP
			slm(RowIndex, I)  <= temp(I);
		END LOOP;
	END PROCEDURE;
	
	PROCEDURE assign_row(SIGNAL slm : OUT T_SLM; slv : STD_LOGIC_VECTOR; CONSTANT RowIndex : NATURAL; Position : NATURAL) IS
		VARIABLE temp : STD_LOGIC_VECTOR(Position + slv'length - 1 DOWNTO Position);
	BEGIN
		temp := slv;
		FOR I IN temp'range LOOP
			slm(RowIndex, I)  <= temp(I);
		END LOOP;
	END PROCEDURE;
	
	PROCEDURE assign_row(SIGNAL slm : OUT T_SLM; slv : STD_LOGIC_VECTOR; CONSTANT RowIndex : NATURAL; High : NATURAL; Low : NATURAL) IS
		VARIABLE temp : STD_LOGIC_VECTOR(High DOWNTO Low);
	BEGIN
		temp := slv;
		FOR I IN temp'range LOOP
			slm(RowIndex, I)  <= temp(I);
		END LOOP;
	END PROCEDURE;
	
	PROCEDURE assign_col(SIGNAL slm : OUT T_SLM; slv : STD_LOGIC_VECTOR; CONSTANT ColIndex : NATURAL) IS
		VARIABLE temp : STD_LOGIC_VECTOR(slm'range(1));
	BEGIN
		temp := slv;
		FOR I IN temp'range LOOP
			slm(I, ColIndex)  <= temp(I);
		END LOOP;
	END PROCEDURE;

	-- Matrix to matrix conversion: slm_slice*
	-- ==========================================================================
	FUNCTION slm_slice(slm : T_SLM; RowIndex : NATURAL; ColIndex : NATURAL; Height : NATURAL; Width : NATURAL) RETURN T_SLM IS
		VARIABLE Result		: T_SLM(Height - 1 DOWNTO 0, Width - 1 DOWNTO 0)		:= (OTHERS => (OTHERS => '0'));
	BEGIN
		FOR I IN 0 TO Height - 1 LOOP
			FOR J IN 0 TO Width - 1 LOOP
				Result(I, J)		:= slm(RowIndex + I, ColIndex + J);
			END LOOP;
		END LOOP;
		RETURN Result;
	END FUNCTION;

	FUNCTION slm_slice_cols(slm : T_SLM; High : NATURAL; Low : NATURAL) RETURN T_SLM IS
		VARIABLE Result		: T_SLM(slm'range(1), High - Low DOWNTO 0)		:= (OTHERS => (OTHERS => '0'));
	BEGIN
		FOR I IN slm'range(1) LOOP
			FOR J IN 0 TO High - Low LOOP
				Result(I, J)		:= slm(I, low + J);
			END LOOP;
		END LOOP;
		RETURN Result;
	END FUNCTION;

	-- Matrix to vector conversion: get_*
	-- ==========================================================================
	-- get a matrix column
	FUNCTION get_col(slm : T_SLM; ColIndex : NATURAL) RETURN STD_LOGIC_VECTOR IS
		VARIABLE slv		: STD_LOGIC_VECTOR(slm'range(1));
	BEGIN
		FOR I IN slm'range(1) LOOP
			slv(I)	:= slm(I, ColIndex);
		END LOOP;
		RETURN slv;
	END FUNCTION;
	
	-- get a matrix row
	FUNCTION get_row(slm : T_SLM; RowIndex : NATURAL) RETURN STD_LOGIC_VECTOR IS
		VARIABLE slv		: STD_LOGIC_VECTOR(slm'high(2) DOWNTO slm'low(2));			-- Xilinx iSIM work-around, because 'range(2) = 'range(1); tested with ISE/iSIM 14.2
	BEGIN
		FOR I IN slv'range LOOP
			slv(I)	:= slm(RowIndex, I);
		END LOOP;
		RETURN slv;
	END FUNCTION;
	
	-- get a matrix row of defined length [length - 1 downto 0]
	FUNCTION get_row(slm : T_SLM; RowIndex : NATURAL; Length : POSITIVE) RETURN STD_LOGIC_VECTOR IS
	BEGIN
		RETURN get_row(slm, RowIndex, (Length - 1), 0);
	END FUNCTION;

	-- get a sub vector of a matrix row at high:low
	FUNCTION get_row(slm : T_SLM; RowIndex : NATURAL; High : NATURAL; Low : NATURAL) RETURN STD_LOGIC_VECTOR IS
		VARIABLE slv		: STD_LOGIC_VECTOR(High DOWNTO Low);			-- Xilinx iSIM work-around, because 'range(2) = 'range(1); tested with ISE/iSIM 14.2
	BEGIN
		FOR I IN slv'range LOOP
			slv(I)	:= slm(RowIndex, I);
		END LOOP;
		RETURN slv;
	END FUNCTION;

	-- Convert to vector: to_slv
	-- ==========================================================================
	-- convert vector-vector to flatten vector
	FUNCTION to_slv(slvv : T_SLVV_8) RETURN STD_LOGIC_VECTOR IS
		VARIABLE slv			: STD_LOGIC_VECTOR((slvv'length * 8) - 1 DOWNTO 0);
	BEGIN
		FOR I IN slvv'range LOOP
			slv((I * 8) + 7 DOWNTO (I * 8))		:= slvv(I);
		END LOOP;
		RETURN slv;
	END FUNCTION;
	
	-- Convert flat vector to a vector-vector: to_slvv_*
	-- ==========================================================================
	-- create vector-vector from vector (4 bit)
	FUNCTION to_slvv_4(slv : STD_LOGIC_VECTOR) RETURN T_SLVV_4 IS
		VARIABLE Result		: T_SLVV_4((slv'length / 4) - 1 DOWNTO 0);
	BEGIN
		IF ((slv'length MOD 4) /= 0) THEN	REPORT "to_slvv_4: width mismatch - slv'length is no multiple of 4 (slv'length=" & INTEGER'image(slv'length) & ")" SEVERITY FAILURE;	END IF;
		
		FOR I IN Result'range LOOP
			Result(I)	:= slv((I * 4) + 3 DOWNTO (I * 4));
		END LOOP;
		RETURN Result;
	END FUNCTION;
	
	-- create vector-vector from vector (8 bit)
	FUNCTION to_slvv_8(slv : STD_LOGIC_VECTOR) RETURN T_SLVV_8 IS
		VARIABLE Result		: T_SLVV_8((slv'length / 8) - 1 DOWNTO 0);
	BEGIN
		IF ((slv'length MOD 8) /= 0) THEN	REPORT "to_slvv_8: width mismatch - slv'length is no multiple of 8 (slv'length=" & INTEGER'image(slv'length) & ")" SEVERITY FAILURE;	END IF;
		
		FOR I IN Result'range LOOP
			Result(I)	:= slv((I * 8) + 7 DOWNTO (I * 8));
		END LOOP;
		RETURN Result;
	END FUNCTION;
	
	-- create vector-vector from vector (12 bit)
	FUNCTION to_slvv_12(slv : STD_LOGIC_VECTOR) RETURN T_SLVV_12 IS
		VARIABLE Result		: T_SLVV_12((slv'length / 12) - 1 DOWNTO 0);
	BEGIN
		IF ((slv'length MOD 12) /= 0) THEN	REPORT "to_slvv_12: width mismatch - slv'length is no multiple of 12 (slv'length=" & INTEGER'image(slv'length) & ")" SEVERITY FAILURE;	END IF;
		
		FOR I IN Result'range LOOP
			Result(I)	:= slv((I * 12) + 11 DOWNTO (I * 12));
		END LOOP;
		RETURN Result;
	END FUNCTION;
	
	-- create vector-vector from vector (16 bit)
	FUNCTION to_slvv_16(slv : STD_LOGIC_VECTOR) RETURN T_SLVV_16 IS
		VARIABLE Result		: T_SLVV_16((slv'length / 16) - 1 DOWNTO 0);
	BEGIN
		IF ((slv'length MOD 16) /= 0) THEN	REPORT "to_slvv_16: width mismatch - slv'length is no multiple of 16 (slv'length=" & INTEGER'image(slv'length) & ")" SEVERITY FAILURE;	END IF;
		
		FOR I IN Result'range LOOP
			Result(I)	:= slv((I * 16) + 15 DOWNTO (I * 16));
		END LOOP;
		RETURN Result;
	END FUNCTION;
	
	-- create vector-vector from vector (32 bit)
	FUNCTION to_slvv_32(slv : STD_LOGIC_VECTOR) RETURN T_SLVV_32 IS
		VARIABLE Result		: T_SLVV_32((slv'length / 32) - 1 DOWNTO 0);
	BEGIN
		IF ((slv'length MOD 32) /= 0) THEN	REPORT "to_slvv_32: width mismatch - slv'length is no multiple of 32 (slv'length=" & INTEGER'image(slv'length) & ")" SEVERITY FAILURE;	END IF;
		
		FOR I IN Result'range LOOP
			Result(I)	:= slv((I * 32) + 31 DOWNTO (I * 32));
		END LOOP;
		RETURN Result;
	END FUNCTION;

	-- create vector-vector from vector (64 bit)
	FUNCTION to_slvv_64(slv : STD_LOGIC_VECTOR) RETURN T_SLVV_64 IS
		VARIABLE Result		: T_SLVV_64((slv'length / 64) - 1 DOWNTO 0);
	BEGIN
		IF ((slv'length MOD 64) /= 0) THEN	REPORT "to_slvv_64: width mismatch - slv'length is no multiple of 64 (slv'length=" & INTEGER'image(slv'length) & ")" SEVERITY FAILURE;	END IF;
		
		FOR I IN Result'range LOOP
			Result(I)	:= slv((I * 64) + 63 DOWNTO (I * 64));
		END LOOP;
		RETURN Result;
	END FUNCTION;
	
	-- create vector-vector from vector (128 bit)
	FUNCTION to_slvv_128(slv : STD_LOGIC_VECTOR) RETURN T_SLVV_128 IS
		VARIABLE Result		: T_SLVV_128((slv'length / 128) - 1 DOWNTO 0);
	BEGIN
		IF ((slv'length MOD 128) /= 0) THEN	REPORT "to_slvv_128: width mismatch - slv'length is no multiple of 128 (slv'length=" & INTEGER'image(slv'length) & ")" SEVERITY FAILURE;	END IF;
		
		FOR I IN Result'range LOOP
			Result(I)	:= slv((I * 128) + 127 DOWNTO (I * 128));
		END LOOP;
		RETURN Result;
	END FUNCTION;
	
	-- create vector-vector from vector (256 bit)
	FUNCTION to_slvv_256(slv : STD_LOGIC_VECTOR) RETURN T_SLVV_256 IS
		VARIABLE Result		: T_SLVV_256((slv'length / 256) - 1 DOWNTO 0);
	BEGIN
		IF ((slv'length MOD 256) /= 0) THEN	REPORT "to_slvv_256: width mismatch - slv'length is no multiple of 256 (slv'length=" & INTEGER'image(slv'length) & ")" SEVERITY FAILURE;	END IF;
		
		FOR I IN Result'range LOOP
			Result(I)	:= slv((I * 256) + 255 DOWNTO (I * 256));
		END LOOP;
		RETURN Result;
	END FUNCTION;
	
	-- create vector-vector from vector (512 bit)
	FUNCTION to_slvv_512(slv : STD_LOGIC_VECTOR) RETURN T_SLVV_512 IS
		VARIABLE Result		: T_SLVV_512((slv'length / 512) - 1 DOWNTO 0);
	BEGIN
		IF ((slv'length MOD 512) /= 0) THEN	REPORT "to_slvv_512: width mismatch - slv'length is no multiple of 512 (slv'length=" & INTEGER'image(slv'length) & ")" SEVERITY FAILURE;	END IF;
		
		FOR I IN Result'range LOOP
			Result(I)	:= slv((I * 512) + 511 DOWNTO (I * 512));
		END LOOP;
		RETURN Result;
	END FUNCTION;

	-- Convert matrix to avector-vector: to_slvv_*
	-- ==========================================================================
	-- create vector-vector from matrix (4 bit)
	FUNCTION to_slvv_4(slm : T_SLM) RETURN T_SLVV_4 IS
		VARIABLE Result		: T_SLVV_4(slm'range(1));
	BEGIN
		IF (slm'length(2) /= 4) THEN	REPORT "to_slvv_4: type mismatch - slm'length(2)=" & INTEGER'image(slm'length(2)) SEVERITY FAILURE;	END IF;
		
		FOR I IN slm'range(1) LOOP
			Result(I)	:= get_row(slm, I);
		END LOOP;
		RETURN Result;
	END FUNCTION;
	
	-- create vector-vector from matrix (8 bit)
	FUNCTION to_slvv_8(slm : T_SLM) RETURN T_SLVV_8 IS
		VARIABLE Result		: T_SLVV_8(slm'range(1));
	BEGIN
		IF (slm'length(2) /= 8) THEN	REPORT "to_slvv_8: type mismatch - slm'length(2)=" & INTEGER'image(slm'length(2)) SEVERITY FAILURE;	END IF;
		
		FOR I IN slm'range(1) LOOP
			Result(I)	:= get_row(slm, I);
		END LOOP;
		RETURN Result;
	END FUNCTION;
	
	-- create vector-vector from matrix (12 bit)
	FUNCTION to_slvv_12(slm : T_SLM) RETURN T_SLVV_12 IS
		VARIABLE Result		: T_SLVV_12(slm'range(1));
	BEGIN
		IF (slm'length(2) /= 12) THEN	REPORT "to_slvv_12: type mismatch - slm'length(2)=" & INTEGER'image(slm'length(2)) SEVERITY FAILURE;	END IF;
		
		FOR I IN slm'range(1) LOOP
			Result(I)	:= get_row(slm, I);
		END LOOP;
		RETURN Result;
	END FUNCTION;
	
	-- create vector-vector from matrix (16 bit)
	FUNCTION to_slvv_16(slm : T_SLM) RETURN T_SLVV_16 IS
		VARIABLE Result		: T_SLVV_16(slm'range(1));
	BEGIN
		IF (slm'length(2) /= 16) THEN	REPORT "to_slvv_16: type mismatch - slm'length(2)=" & INTEGER'image(slm'length(2)) SEVERITY FAILURE;	END IF;
		
		FOR I IN slm'range(1) LOOP
			Result(I)	:= get_row(slm, I);
		END LOOP;
		RETURN Result;
	END FUNCTION;
	
	-- create vector-vector from matrix (32 bit)
	FUNCTION to_slvv_32(slm : T_SLM) RETURN T_SLVV_32 IS
		VARIABLE Result		: T_SLVV_32(slm'range(1));
	BEGIN
		IF (slm'length(2) /= 32) THEN	REPORT "to_slvv_32: type mismatch - slm'length(2)=" & INTEGER'image(slm'length(2)) SEVERITY FAILURE;	END IF;
		
		FOR I IN slm'range(1) LOOP
			Result(I)	:= get_row(slm, I);
		END LOOP;
		RETURN Result;
	END FUNCTION;

	-- create vector-vector from matrix (64 bit)
	FUNCTION to_slvv_64(slm : T_SLM) RETURN T_SLVV_64 IS
		VARIABLE Result		: T_SLVV_64(slm'range(1));
	BEGIN
		IF (slm'length(2) /= 64) THEN	REPORT "to_slvv_64: type mismatch - slm'length(2)=" & INTEGER'image(slm'length(2)) SEVERITY FAILURE;	END IF;
		
		FOR I IN slm'range(1) LOOP
			Result(I)	:= get_row(slm, I);
		END LOOP;
		RETURN Result;
	END FUNCTION;
	
	-- create vector-vector from matrix (128 bit)
	FUNCTION to_slvv_128(slm : T_SLM) RETURN T_SLVV_128 IS
		VARIABLE Result		: T_SLVV_128(slm'range(1));
	BEGIN
		IF (slm'length(2) /= 128) THEN	REPORT "to_slvv_128: type mismatch - slm'length(2)=" & INTEGER'image(slm'length(2)) SEVERITY FAILURE;	END IF;
		
		FOR I IN slm'range(1) LOOP
			Result(I)	:= get_row(slm, I);
		END LOOP;
		RETURN Result;
	END FUNCTION;
	
	-- create vector-vector from matrix (256 bit)
	FUNCTION to_slvv_256(slm : T_SLM) RETURN T_SLVV_256 IS
		VARIABLE Result		: T_SLVV_256(slm'range);
	BEGIN
		IF (slm'length(2) /= 256) THEN	REPORT "to_slvv_256: type mismatch - slm'length(2)=" & INTEGER'image(slm'length(2)) SEVERITY FAILURE;	END IF;
		
		FOR I IN slm'range LOOP
			Result(I)	:= get_row(slm, I);
		END LOOP;
		RETURN Result;
	END FUNCTION;
	
	-- create vector-vector from matrix (512 bit)
	FUNCTION to_slvv_512(slm : T_SLM) RETURN T_SLVV_512 IS
		VARIABLE Result		: T_SLVV_512(slm'range(1));
	BEGIN
		IF (slm'length(2) /= 512) THEN	REPORT "to_slvv_512: type mismatch - slm'length(2)=" & INTEGER'image(slm'length(2)) SEVERITY FAILURE;	END IF;
		
		FOR I IN slm'range(1) LOOP
			Result(I)	:= get_row(slm, I);
		END LOOP;
		RETURN Result;
	END FUNCTION;
	
	-- Convert vector-vector to matrix: to_slm
	-- ==========================================================================
	-- create matrix from vector-vector
	FUNCTION to_slm(slvv : T_SLVV_4) RETURN T_SLM IS
		VARIABLE slm		: T_SLM(slvv'range, 3 DOWNTO 0);
	BEGIN
		FOR I IN slvv'range LOOP
			FOR J IN T_SLV_4'range LOOP
				slm(I, J)		:= slvv(I)(J);
			END LOOP;
		END LOOP;
		RETURN slm;
	END FUNCTION;
	
	FUNCTION to_slm(slvv : T_SLVV_8) RETURN T_SLM IS
--		VARIABLE test		: STD_LOGIC_VECTOR(T_SLV_8'range);
--		VARIABLE slm		: T_SLM(slvv'range, test'range);				-- BUG: iSIM 14.5 cascaded 'range accesses let iSIM break down 
--		VARIABLE slm		: T_SLM(slvv'range, T_SLV_8'range);			-- BUG: iSIM 14.5 allocates 9 bits in dimmension 2
		VARIABLE slm		: T_SLM(slvv'range, 7 DOWNTO 0);
	BEGIN
--		REPORT "slvv:    slvv.length=" & INTEGER'image(slvv'length) &			"  slm.dim0.length=" & INTEGER'image(slm'length(1)) & "  slm.dim1.length=" & INTEGER'image(slm'length(2)) SEVERITY NOTE;
--		REPORT "T_SLV_8:     .length=" & INTEGER'image(T_SLV_8'length) &	"  .high=" & INTEGER'image(T_SLV_8'high) &	"  .low=" & INTEGER'image(T_SLV_8'low)	SEVERITY NOTE;
--		REPORT "test:    test.length=" & INTEGER'image(test'length) &			"  .high=" & INTEGER'image(test'high) &			"  .low=" & INTEGER'image(test'low)			SEVERITY NOTE;
		FOR I IN slvv'range LOOP
			FOR J IN T_SLV_8'range LOOP
				slm(I, J)		:= slvv(I)(J);
			END LOOP;
		END LOOP;
		RETURN slm;
	END FUNCTION;
	
	FUNCTION to_slm(slvv : T_SLVV_12) RETURN T_SLM IS
		VARIABLE slm		: T_SLM(slvv'range, 11 DOWNTO 0);
	BEGIN
		FOR I IN slvv'range LOOP
			FOR J IN T_SLV_12'range LOOP
				slm(I, J)		:= slvv(I)(J);
			END LOOP;
		END LOOP;
		RETURN slm;
	END FUNCTION;
	
	FUNCTION to_slm(slvv : T_SLVV_16) RETURN T_SLM IS
		VARIABLE slm		: T_SLM(slvv'range, 15 DOWNTO 0);
	BEGIN
		FOR I IN slvv'range LOOP
			FOR J IN T_SLV_16'range LOOP
				slm(I, J)		:= slvv(I)(J);
			END LOOP;
		END LOOP;
		RETURN slm;
	END FUNCTION;
	
	FUNCTION to_slm(slvv : T_SLVV_32) RETURN T_SLM IS
		VARIABLE slm		: T_SLM(slvv'range, 31 DOWNTO 0);
	BEGIN
		FOR I IN slvv'range LOOP
			FOR J IN T_SLV_32'range LOOP
				slm(I, J)		:= slvv(I)(J);
			END LOOP;
		END LOOP;
		RETURN slm;
	END FUNCTION;
	
	FUNCTION to_slm(slvv : T_SLVV_48) RETURN T_SLM IS
		VARIABLE slm		: T_SLM(slvv'range, 47 DOWNTO 0);
	BEGIN
		FOR I IN slvv'range LOOP
			FOR J IN T_SLV_48'range LOOP
				slm(I, J)		:= slvv(I)(J);
			END LOOP;
		END LOOP;
		RETURN slm;
	END FUNCTION;
	
	FUNCTION to_slm(slvv : T_SLVV_64) RETURN T_SLM IS
		VARIABLE slm		: T_SLM(slvv'range, 63 DOWNTO 0);
	BEGIN
		FOR I IN slvv'range LOOP
			FOR J IN T_SLV_64'range LOOP
				slm(I, J)		:= slvv(I)(J);
			END LOOP;
		END LOOP;
		RETURN slm;
	END FUNCTION;
	
	FUNCTION to_slm(slvv : T_SLVV_128) RETURN T_SLM IS
		VARIABLE slm		: T_SLM(slvv'range, 127 DOWNTO 0);
	BEGIN
		FOR I IN slvv'range LOOP
			FOR J IN T_SLV_128'range LOOP
				slm(I, J)		:= slvv(I)(J);
			END LOOP;
		END LOOP;
		RETURN slm;
	END FUNCTION;
	
	FUNCTION to_slm(slvv : T_SLVV_256) RETURN T_SLM IS
		VARIABLE slm		: T_SLM(slvv'range, 255 DOWNTO 0);
	BEGIN
		FOR I IN slvv'range LOOP
			FOR J IN T_SLV_256'range LOOP
				slm(I, J)		:= slvv(I)(J);
			END LOOP;
		END LOOP;
		RETURN slm;
	END FUNCTION;
	
	FUNCTION to_slm(slvv : T_SLVV_512) RETURN T_SLM IS
		VARIABLE slm		: T_SLM(slvv'range, 511 DOWNTO 0);
	BEGIN
		FOR I IN slvv'range LOOP
			FOR J IN T_SLV_512'range LOOP
				slm(I, J)		:= slvv(I)(J);
			END LOOP;
		END LOOP;
		RETURN slm;
	END FUNCTION;

	-- Change vector direction
	-- ==========================================================================
	FUNCTION dir(slvv : T_SLVV_8) RETURN T_SLVV_8 IS
		VARIABLE Result : T_SLVV_8(slvv'reverse_range);
	BEGIN
		Result := slvv;
		RETURN Result;
	END FUNCTION;
	
	-- Reverse vector elements
	FUNCTION rev(slvv : T_SLVV_4) RETURN T_SLVV_4 IS
		VARIABLE Result : T_SLVV_4(slvv'range);
	BEGIN
		FOR I IN slvv'low TO slvv'high LOOP
			Result(slvv'high - I) := slvv(I);
		END LOOP;
		RETURN Result;
	END FUNCTION;

	FUNCTION rev(slvv : T_SLVV_8) RETURN T_SLVV_8 IS
		VARIABLE Result : T_SLVV_8(slvv'range);
	BEGIN
		FOR I IN slvv'low TO slvv'high LOOP
			Result(slvv'high - I) := slvv(I);
		END LOOP;
		RETURN Result;
	END FUNCTION;
	
	FUNCTION rev(slvv : T_SLVV_12) RETURN T_SLVV_12 IS
		VARIABLE Result : T_SLVV_12(slvv'range);
	BEGIN
		FOR I IN slvv'low TO slvv'high LOOP
			Result(slvv'high - I) := slvv(I);
		END LOOP;
		RETURN Result;
	END FUNCTION;
	
	FUNCTION rev(slvv : T_SLVV_16) RETURN T_SLVV_16 IS
		VARIABLE Result : T_SLVV_16(slvv'range);
	BEGIN
		FOR I IN slvv'low TO slvv'high LOOP
			Result(slvv'high - I) := slvv(I);
		END LOOP;
		RETURN Result;
	END FUNCTION;
	
	FUNCTION rev(slvv : T_SLVV_32) RETURN T_SLVV_32 IS
		VARIABLE Result : T_SLVV_32(slvv'range);
	BEGIN
		FOR I IN slvv'low TO slvv'high LOOP
			Result(slvv'high - I) := slvv(I);
		END LOOP;
		RETURN Result;
	END FUNCTION;
	
	FUNCTION rev(slvv : T_SLVV_64) RETURN T_SLVV_64 IS
		VARIABLE Result : T_SLVV_64(slvv'range);
	BEGIN
		FOR I IN slvv'low TO slvv'high LOOP
			Result(slvv'high - I) := slvv(I);
		END LOOP;
		RETURN Result;
	END FUNCTION;
	
	FUNCTION rev(slvv : T_SLVV_128) RETURN T_SLVV_128 IS
		VARIABLE Result : T_SLVV_128(slvv'range);
	BEGIN
		FOR I IN slvv'low TO slvv'high LOOP
			Result(slvv'high - I) := slvv(I);
		END LOOP;
		RETURN Result;
	END FUNCTION;
	
	FUNCTION rev(slvv : T_SLVV_256) RETURN T_SLVV_256 IS
		VARIABLE Result : T_SLVV_256(slvv'range);
	BEGIN
		FOR I IN slvv'low TO slvv'high LOOP
			Result(slvv'high - I) := slvv(I);
		END LOOP;
		RETURN Result;
	END FUNCTION;
	
	FUNCTION rev(slvv : T_SLVV_512) RETURN T_SLVV_512 IS
		VARIABLE Result : T_SLVV_512(slvv'range);
	BEGIN
		FOR I IN slvv'low TO slvv'high LOOP
			Result(slvv'high - I) := slvv(I);
		END LOOP;
		RETURN Result;
	END FUNCTION;

	-- Resize functions
	-- ==========================================================================
	-- Resizes the vector to the specified length. Input vectors larger than the specified size are truncated from the left side. Smaller input
	-- vectors are extended on the left by the provided fill value (default: '0'). Use the resize functions of the numeric_std package for
	-- value-preserving resizes of the signed and unsigned data types.
	FUNCTION resize(slm : T_SLM; size : POSITIVE) RETURN T_SLM IS
		VARIABLE Result		: T_SLM(size - 1 DOWNTO 0, slm'high(2) DOWNTO slm'low(2))		:= (OTHERS => (OTHERS => '0'));
	BEGIN
		FOR I IN slm'range(1) LOOP
			FOR J IN slm'high(2) DOWNTO slm'low(2) LOOP
				Result(I, J)	:= slm(I, J);
			END LOOP;
		END LOOP;
		RETURN Result;
	END FUNCTION;
	
	FUNCTION to_string(slvv : T_SLVV_8; sep : CHARACTER := ':') RETURN STRING IS
		CONSTANT hex_len			: POSITIVE								:= ite((sep = NUL), (slvv'length * 2), (slvv'length * 3) - 1);
		VARIABLE Result				: STRING(1 TO hex_len)		:= (OTHERS => sep);
		VARIABLE pos					: POSITIVE								:= 1;
	BEGIN
		FOR I IN slvv'range LOOP
			Result(pos TO pos + 1)	:= to_string(slvv(I), 'h');
			pos											:= pos + ite((sep = NUL), 2, 3);
		END LOOP;
		RETURN Result;
	END FUNCTION;
end vectors;
