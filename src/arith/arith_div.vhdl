-- EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================================================================================================
-- Description:			Implementation of a Non-Performing restoring divider with a configurable radix.
--									For detailed documentation see below.
-- 
-- Authors:					Thomas B. Preusser
-- ============================================================================================================================================================
-- Copyright 2007-2014 Technische Universität Dresden - Germany, Chair for VLSI-Design, Diagnostics and Architecture
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
-- ============================================================================================================================================================

library	ieee;
use			ieee.std_logic_1164.all;
use			ieee.numeric_std.all;

library	poc;
USE			PoC.utils.ALL;


entity arith_div is
	generic (
		N					: positive;-- := 32;				-- Operand /Result Bit Widths
		RAPOW			: positive;-- := 1;				 -- Power of Radix used (2**RAPOW)
		REGISTERED : boolean	-- := false			-- Output is registered
	);

	port (
		-- Global Reset/Clock
		clk : in std_logic;
		rst : in std_logic;

		-- Ready / Start
		start : in	std_logic;
		rdy	 : out std_logic;

		-- Arguments / Result (2's complement)
		arg1, arg2 : in	std_logic_vector(N-1 downto 0);
		res				: out std_logic_vector(N-1 downto 0)
	);
end arith_div;

-------------------------------------------------------------------------------
-- Implementation of a Non-Performing Restoring Divider
--
-- Multi-Cycle division controlled by 'start' / 'rdy'. A new division can be
-- started, if 'rdy' = '1'. The result is available if 'rdy' is '1' again.
--
-- Note that the registered version is no slower than the unregistered one
-- as the conversion to a negative result is performed on-the-fly. It is,
-- however, somewhat more expensive as illustrated below.
--
-- Synthesis Costs of the differing feasible configurations:
--
--	 Baseline values of Radix-2 unregistered configuration per 2009-12-08.
--	 XST: Optimization Goal AREA
--
--				Radix	 2			 4			 8
--	 Registered
--
--		no				 134		 -2			-2			 Flip Flops
--							 244		+95		+189			 LUT4
--
--		yes				+30		+26		 +24			 Flip Flops
--								+1		+97		+189			 LUT4
--
-- 
-------------------------------------------------------------------------------


architecture div_npr of arith_div is

	-- Constants
	constant STEPS : positive := (N+RAPOW-1)/RAPOW;	-- Number of Iteration Steps

	-- State
	signal Exec : std_logic;							-- Operation is being executed

	-- Argument/Result Registers
	signal A : unsigned(N								-1 downto 0);	-- Dividend
	signal B : unsigned(N+RAPOW*(STEPS-1)-1 downto 0);	-- Divisor
	signal S : std_logic;															 -- Quotient Sign

	signal An : unsigned(N		-1 downto 0);	-- Next Residue Value
	signal dn : unsigned(RAPOW-1 downto 0);	-- Next Quotient Digit

	-- Iteration Counter
	signal Cnt		: unsigned(1 to log2ceil(STEPS));
	signal CntDD	: unsigned(1 to log2ceil(STEPS));	-- Cnt - 1
	signal CntEx0 : std_logic;											 -- Cnt = 0

begin	-- div_npr

	-- Registers
	process(clk)
	begin
		if clk'event and clk = '1' then
			-- Reset
			if rst = '1' then
				Exec <= '0';

			-- Iteration Step
			elsif Exec = '1' then
				Cnt <= CntDD;
				A	 <= An;
				B	 <= (1 to RAPOW => '0') & B(B'LEFT downto RAPOW);
			
				if CntEx0 = '1' then
					Exec <= '0';
				end if;
				
			-- Operation Initialization
			elsif start = '1' then
				Exec <= '1';

				if arg1(N-1) = '0' then
					A <= unsigned(arg1);
				else
					A <= 0 - unsigned(arg1);
				end if;
				if arg2(N-1) = '0' then
					B(B'LEFT downto (STEPS-1)*RAPOW) <= unsigned(arg2);
				else
					B(B'LEFT downto (STEPS-1)*RAPOW) <= 0 - unsigned(arg2);
				end if;
				B((STEPS-1)*RAPOW-1 downto 0) <= (others => '0');
				
				S	 <= arg1(N-1) xor arg2(N-1);
				Cnt <= to_unsigned(STEPS-1, log2ceil(STEPS));

			end if;
		end if;
	end process;
	rdy <= not Exec;

	-- Counter Logic
	CntDD	<= Cnt - 1;
	CntEx0 <= not Cnt(Cnt'LEFT) and CntDD(CntDD'LEFT);

	-- Subtractor
	blkSub: block
		
		subtype tData is unsigned(N-1 downto 0);
		subtype tDatx is unsigned(N	 downto 0);
		type tDataArr is array (natural range<>) of tData;
		type tDatxArr is array (natural range<>) of tDatx;
		
		signal rng : std_logic_vector(RAPOW-1 downto 0);	-- B beyond Range
		signal di : tDatxArr(RAPOW-1 downto 0);
		signal Ai : tDataArr(RAPOW	 downto 0);

	begin
		-- Calculate Ranges
		rng(0) <= '1' when B(B'LEFT downto N) /= (B'LEFT downto N => '0') else '0';
		lr: for i in 1 to RAPOW-1 generate
			rng(i) <= rng(i-1) or B(N-i);
		end generate lr;

		-- Speculative Subtractions
		Ai(RAPOW) <= A;
		ls: for i in RAPOW-1 downto 0 generate
			ieq0: if i = 0 generate
				di(i) <= ('0' & Ai(i+1)) - ('0' & B(N-1 downto 0));
			end generate ieq0;
			ine0: if i /= 0 generate
				di(i) <= ('0' & Ai(i+1)) - ('0' & B(N-i-1 downto 0) & (1 to i => '0'));
			end generate ine0;
			dn(i) <= not(rng(i) or di(i)(N));
			Ai(i) <= di(i)(N-1 downto 0) when dn(i) = '1' else Ai(i+1);
		end generate ls;
		An <= Ai(0);

	end block blkSub;

	-- Quotient Composition
	gNRG: if not REGISTERED generate
		blkOut: block
			signal Q : unsigned(N-1 downto 0);	-- Quotient
		
		begin
			process(clk)
			begin
				if clk'event and clk = '1' then
					if Exec = '1' then
						Q <= Q(N-RAPOW-1 downto 0) & (dn xor (1 to RAPOW => S));
					end if;
				end if;
			end process;
		
			res <= std_logic_vector(Q + ("0" & S));
		
		end block blkOut;
	end generate gNRG;

	gREG: if REGISTERED generate
		blkOut: block
			signal Q	 : unsigned(N			-1 downto 0);	-- Quotient
			signal Qm1 : unsigned(N-RAPOW-1 downto 0);	-- Quotient - 1
			signal dnx : unsigned(	RAPOW	 downto 0);	-- (not dn) + 1

		begin
			dnx <= ('0' & not dn) + 1;

			process(clk)
			begin
				if clk'event and clk = '1' then
					if Exec = '1' then
						if S = '0' then
							Q <= Q(N-RAPOW-1 downto 0) & dn;
						else
							if dnx(RAPOW) = '1' then
								Q(N-1 downto RAPOW) <= Q	(N-RAPOW-1 downto 0);
							else
								Q(N-1 downto RAPOW) <= Qm1(N-RAPOW-1 downto 0);
							end if;
							Q(RAPOW-1 downto 0) <= dnx(RAPOW-1 downto 0);

							Qm1 <= Qm1(N-2*RAPOW-1 downto 0) & not dn;
						end if;
					end if;
				end if;
			end process;

			res <= std_logic_vector(Q);

		end block blkOut;

	end generate gREG;

end div_npr;
