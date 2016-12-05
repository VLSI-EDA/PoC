-- EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Thomas B. Preusser
--
-- Entity:					A flexible scaler for fixed-point values.
--
-- Description:
-- -------------------------------------
-- A flexible scaler for fixed-point values. The scaler is implemented for a set
-- of multiplier and divider values. Each individual scaling operation can
-- arbitrarily select one value from each these sets.
--
-- The computation calculates: ``unsigned(arg) * MULS(msel) / DIVS(dsel)``
-- rounded to the nearest (tie upwards) fixed-point result of the same precision
-- as ``arg``.
--
-- The computation is started by asserting ``start`` to high for one cycle. If a
-- computation is running, it will be restarted. The completion of a calculation
-- is signaled via ``done``. ``done`` is high when no computation is in progress.
-- The result of the last scaling operation is stable and can be read from
-- ``res``. The weight of the LSB of ``res`` is the same as the LSB of ``arg``.
-- Make sure to tap a sufficient number of result bits in accordance to the
-- highest scaling ratio to be used in order to avoid a truncation overflow.
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
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

library	poc;
use			poc.utils.all;


entity arith_scaler is
	generic (
		MULS : T_POSVEC := (0 => 1);	-- The set of multipliers to choose from in scaling operations.
		DIVS : T_POSVEC := (0 => 1)		-- The set of divisors to choose from in scaling operations.
	);
	port (
		clk	 : in	std_logic;
		rst	 : in	std_logic;

		start : in	std_logic;					-- Start of Computation
		arg	 : in	std_logic_vector;			-- Fixed-point value to be scaled
		msel	: in	std_logic_vector(log2ceil(MULS'length)-1 downto 0) := (others => '0');
		dsel	: in	std_logic_vector(log2ceil(DIVS'length)-1 downto 0) := (others => '0');

		done	: out std_logic;					-- Completion
		res		: out std_logic_vector		-- Result
	);
end entity arith_scaler;


library	IEEE;
use			IEEE.numeric_std.all;

architecture rtl of arith_scaler is

	-- Derived Constants
	constant N : positive := arg'length;
	constant X : positive := log2ceil(imax(imax(MULS), imax(DIVS)/2+1));
	constant R : positive := log2ceil(imax(DIVS)+1);

	-- Division Properties
	type tDivProps is
		record	-- Properties of the operation for a divisor
			steps : T_POSVEC(DIVS'range);	-- Steps to perform
			align : T_POSVEC(DIVS'range);	-- Left-aligned divisor
		end record;

	function computeProps return tDivProps is
		variable	res			 : tDivProps;
		variable	min_steps : positive;
	begin
		for i in DIVS'range loop
			res.steps(i) := N+X - log2ceil(DIVS(i)+1) + 1;
		end loop;
		min_steps := imin(res.steps);
		for i in DIVS'range loop
			res.align(i) := DIVS(i) * 2**(res.steps(i) - min_steps);
		end loop;
		return	res;
	end computeProps;

	constant DIV_PROPS : tDivProps := computeProps;

	constant MAX_MUL_STEPS : positive := N;
	constant MAX_DIV_STEPS : positive := imax(DIV_PROPS.steps);
	constant MAX_ANY_STEPS : positive := imax(MAX_MUL_STEPS, MAX_DIV_STEPS);

	subtype tResMask	is std_logic_vector(MAX_DIV_STEPS-1 downto 0);
	type		tResMasks is array(natural range<>) of tResMask;
	function computeMasks return tResMasks is
		variable res : tResMasks(DIVS'range);
	begin
		for i in DIVS'range loop
			res(i)																:= (others => '0');
			res(i)(DIV_PROPS.steps(i)-1 downto 0) := (others => '1');
		end loop;
		return res;
	end computeMasks;
	constant RES_MASKS : tResMasks(DIVS'range) := computeMasks;

	-- Values computed for the selected multiplier/divisor pair.
	signal muloffset	: unsigned(X-1 downto 0);	-- Offset for correct rounding.
	signal multiplier : unsigned(X	 downto 0);	-- The actual multiplier value.
	signal divisor		: unsigned(R-1 downto 0);	-- The actual divisor value.
	signal divcini		: unsigned(log2ceil(MAX_ANY_STEPS)-1 downto 0);	-- Count for division steps.
	signal divmask		: tResMask;								-- Result Mask

begin

	-----------------------------------------------------------------------------
	-- Compute Parameters according to selected Multiplier/Divisor Pair.

	-- Selection of Multiplier
	genMultiMul: if MULS'length > 1 generate
		signal MS : unsigned(msel'range) := (others => '-');
	begin
		process(clk)
		begin
			if rising_edge(clk) then
				if rst = '1' then
					MS <= (others => '-');
				elsif start = '1' then
					MS <= unsigned(msel);
				end if;
			end if;
		end process;
		multiplier <= (others => 'X') when Is_X(std_logic_vector(MS)) else
									to_unsigned(MULS(to_integer(MS)), multiplier'length);
	end generate genMultiMul;
	genSingleMul: if MULS'length = 1 generate
		multiplier <= to_unsigned(MULS(0), multiplier'length);
	end generate genSingleMul;

	-- Selection of Divisor
	genMultiDiv: if DIVS'length > 1 generate
		signal DS : unsigned(dsel'range) := (others => '-');
	begin
		process(clk)
		begin
			if rising_edge(clk) then
				if rst = '1' then
					DS <= (others => '-');
				elsif start = '1' then
					DS <= unsigned(dsel);
				end if;
			end if;
		end process;
		muloffset <= (others => 'X') when Is_X(dsel) else
								 to_unsigned(DIVS(to_integer(unsigned(dsel)))/2, muloffset'length);
		divisor	 <= (others => 'X') when Is_X(std_logic_vector(DS)) else
								 to_unsigned(DIV_PROPS.align(to_integer(DS)), divisor'length);
		divcini	 <= (others => 'X') when Is_X(std_logic_vector(DS)) else
								 to_unsigned(DIV_PROPS.steps(to_integer(DS))-1, divcini'length);
		divmask	 <= (others => 'X') when Is_X(std_logic_vector(DS)) else
								 RES_MASKS(to_integer(DS));
	end generate genMultiDiv;
	genSingleDiv: if DIVS'length = 1 generate
		muloffset <= to_unsigned(DIVS(0)/2, muloffset'length);
		divisor	 <= to_unsigned(DIV_PROPS.align(0), divisor'length);
		divcini	 <= to_unsigned(DIV_PROPS.steps(0)-1, divcini'length);
		divmask	 <= RES_MASKS(0);
	end generate genSingleDiv;

	-----------------------------------------------------------------------------
	-- Implementation of Scaling Operation
	blkMain : block
		signal C : unsigned(1+log2ceil(MAX_ANY_STEPS) downto 0) := ('0', others => '-');
		signal Q : unsigned(X+N											 downto 0) := (others			=> '-');
	begin
		process(clk)
			variable cnxt : unsigned(C'range);
			variable d		: unsigned(R downto 0);
		begin
			if rising_edge(clk) then
				if rst = '1' then
					C <= ('0', others => '-');
					Q <= (others			=> '-');
				else
					if start = '1' then
						C <= "11" & to_unsigned(MAX_MUL_STEPS-1, C'length-2);
						Q <= '0' & muloffset & unsigned(arg);
					elsif C(C'left) = '1' then

						cnxt := C - 1;
						if C(C'left-1) = '1' then
							-- MUL Phase
							Q <= "00" & Q(X+N-1 downto 1);
							if Q(0) = '1' then
								Q(X+N-1 downto N-1) <= ('0' & Q(X+N-1 downto N)) + multiplier;
							end if;

							-- Transition to DIV
							if cnxt(cnxt'left-1) = '0' then
								cnxt(cnxt'left-2 downto 0) := divcini;
							end if;
						else
							-- DIV Phase
							d := Q(Q'left downto Q'left-R) - divisor;
							Q <= Q(Q'left-1 downto 0) & not d(d'left);
							if d(d'left) = '0' then
								Q(Q'left downto Q'left-R+1) <= d(d'left-1 downto 0);
							end if;
						end if;
						C <= cnxt;

					end if;
				end if;
			end if;
		end process;
		done <= not C(C'left);
		process(Q, divmask)
			variable r : std_logic_vector(res'length-1 downto 0);
		begin
			r	 := (others => '0');
			r(imin(r'left, tResMask'left) downto 0) :=
				std_logic_vector(Q(imin(r'left, tResMask'left) downto 0)) and
				divmask(imin(r'left, tResMask'left) downto 0);
			res <= r;
		end process;
	end block blkMain;

end rtl;
