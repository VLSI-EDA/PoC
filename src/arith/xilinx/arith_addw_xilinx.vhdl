-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Thomas B. Preusser
--
-- Entity:					arith_addw_xilinx
--
-- Description:
-- -------------------------------------
--	Implements wide addition providing several options all based
--	on an adaptation of a carry-select approach.
--
--	Xilinx-specific optimizations.
--
--	References:
--		* Hong Diep Nguyen and Bogdan Pasca and Thomas B. Preusser:
--			FPGA-Specific Arithmetic Optimizations of Short-Latency Adders,
--			FPL 2011.
--			-> ARCH:     AAM, CAI, CCA
--			-> SKIPPING: CCC
--
--		* Marcin Rogawski, Kris Gaj and Ekawat Homsirikamol:
--			A Novel Modular Adder for One Thousand Bits and More
--			Using Fast Carry Chains of Modern FPGAs, FPL 2014.
--			-> ARCH:		 PAI
--			-> SKIPPING: PPN_KS, PPN_BK
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
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- =============================================================================

library	IEEE;
use			IEEE.std_logic_1164.all;

library	PoC;
use			PoC.arith.all;


entity arith_addw_xilinx is
  generic (
    N : positive;                    -- Operand Width
    K : positive;                    -- Block Count

    ARCH     : tArch     := CAI;        -- Architecture
    BLOCKING : tBlocking := DFLT;       -- Blocking Scheme
    SKIPPING : tSkipping := CCC         -- Carry Skip Scheme
  );
  port (
    a, b : in std_logic_vector(N-1 downto 0);
    cin  : in std_logic;

    s    : out std_logic_vector(N-1 downto 0);
    cout : out std_logic
  );
end entity;


use			std.textio.all;

library	IEEE;
use			IEEE.numeric_std.all;

library	UNISIM;
use			UNISIM.vcomponents.all;

library	PoC;
use			PoC.utils.all;


architecture rtl of arith_addw_xilinx is

  -- Determine Block Boundaries
  type tBlocking_vector is array(tArch) of tBlocking;
  constant DEFAULT_BLOCKING : tBlocking_vector := (AAM => ASC, CAI => ASC, PAI => DESC, CCA => DESC);

  type integer_vector is array(natural range<>) of integer;
  function compute_blocks return integer_vector is
    variable  bs  : tBlocking := BLOCKING;
    variable  res : integer_vector(K-1 downto 0);

    variable l : line;
  begin
    if bs = DFLT then
      bs := DEFAULT_BLOCKING(ARCH);
    end if;
    case bs is
      when FIX =>
        assert N >= K
          report "Cannot have more blocks than input bits."
          severity failure;
        for i in res'range loop
          res(i) := ((i+1)*N+K/2)/K;
        end loop;

      when ASC =>
        assert N-K*(K-1)/2 >= K
          report "Too few input bits to implement growing block sizes."
          severity failure;
        for i in res'range loop
          res(i) := ((i+1)*(N-K*(K-1)/2)+K/2)/K + (i+1)*i/2;
        end loop;

      when DESC =>
        assert N-K*(K-1)/2 >= K
          report "Too few input bits to implement growing block sizes."
          severity failure;
        for i in res'range loop
          res(i) := ((i+1)*(N+K*(K-1)/2)+K/2)/K - (i+1)*i/2;
        end loop;

      when others =>
        report "Unknown blocking scheme: "&tBlocking'image(bs) severity failure;

    end case;
    --synthesis translate_off
    write(l, "Implementing "&integer'image(N)&"-bit wide adder: ARCH="&tArch'image(ARCH)&
             ", BLOCKING="&tBlocking'image(bs)&'[');
    for i in K-1 downto 1 loop
      write(l, res(i)-res(i-1));
      write(l, ',');
    end loop;
    write(l, res(0));
    write(l, "], SKIPPING="&tSkipping'image(SKIPPING));
    writeline(output, l);
    --synthesis translate_on
    return  res;
  end compute_blocks;
  constant BLOCKS : integer_vector(K-1 downto 0) := compute_blocks;

  signal g : std_logic_vector(K-1 downto 1);  -- Block Generate
  signal p : std_logic_vector(K-1 downto 1);  -- Block Propagate
  signal c : std_logic_vector(K-1 downto 1);  -- Block Carry-in
begin

  -----------------------------------------------------------------------------
  -- Rightmost Block and Core Carry Chain
	blkCore: block
    constant M : positive := BLOCKS(0);  -- Rightmost Block Width
		signal cc : std_logic_vector(K+M-1 downto 0);
	begin

		cc(0) <= cin;
		-- Rightmost Block
		genChain: for i in 0 to M-1 generate
			signal pp : std_logic;
		begin
			pp <= a(i) xor b(i);
			cc_mux: MUXCY
				port map (
					O  => cc(i+1),
					CI => cc(i),
					DI => a(i),
					S  => pp
				);
			cc_xor: XORCY
				port map (
					O  => s(i),
					CI => cc(i),
					LI => pp
				);
		end generate genChain;

		-- Carry Computation with Carry Chain
    genCCC: if SKIPPING = CCC generate
			genChain: for i in 1 to K-1 generate
				cc_mux: MUXCY
					port map (
						O  => cc(M+i),
						CI => cc(M+i-1),
						DI => g(i),
						S  => p(i)
					);
			end generate genChain;
    end generate genCCC;

		-- Plain linear LUT-based Carry Forwarding
		genPlain: if SKIPPING = PLAIN generate
			cc(cc'left downto M+1) <= g or (p and cc(K+M-2 downto M));
		end generate genPlain;

		-- Kogge-Stone Parallel Prefix Network
		genPPN_KS: if SKIPPING = PPN_KS generate
			subtype tLevel is std_logic_vector(K-1 downto 0);
			type tLevels is array(natural range<>) of tLevel;
			constant LEVELS : positive := log2ceil(K);
			signal   pp, gg : tLevels(0 to LEVELS);
		begin
			-- carry forwarding
			pp(0) <= p & 'X';
			gg(0) <= g & cc(M);
			genLevels: for i in 1 to LEVELS generate
				constant D : positive := 2**(i-1);
			begin
				pp(i) <= (pp(i-1)(K-1 downto D) and pp(i-1)(K-D-1 downto 0)) & pp(i-1)(D-1 downto 0);
				gg(i) <= (gg(i-1)(K-1 downto D) or (pp(i-1)(K-1 downto D) and gg(i-1)(K-D-1 downto 0))) & gg(i-1)(D-1 downto 0);
			end generate genLevels;
			cc(cc'left downto M+1) <= gg(gg'high)(K-1 downto 1);
		end generate genPPN_KS;

		-- Brent-Kung Parallel Prefix Network
		genPPN_BK: if SKIPPING = PPN_BK generate
			subtype tLevel is std_logic_vector(K-1 downto 0);
			type tLevels is array(natural range<>) of tLevel;
			constant LEVELS : positive := log2ceil(K);
			signal   pp, gg : tLevels(0 to 2*LEVELS-1);
		begin
			-- carry forwarding
			pp(0) <= p & 'X';
			gg(0) <= g & cc(M);
			genMerge: for i in 1 to LEVELS generate
				constant D : positive := 2**(i-1);
			begin
				genBits: for j in 0 to K-1 generate
					genOp: if j mod (2*D) = 2*D-1 generate
						gg(i)(j) <= (pp(i-1)(j) and gg(i-1)(j-D)) or gg(i-1)(j);
						pp(i)(j) <=  pp(i-1)(j) and pp(i-1)(j-D);
					end generate;
					genCp: if j mod (2*D) /= 2*D-1 generate
						gg(i)(j) <= gg(i-1)(j);
						pp(i)(j) <= pp(i-1)(j);
					end generate;
				end generate;
			end generate genMerge;
			genSpread: for i in LEVELS+1 to 2*LEVELS-1 generate
				constant D : positive := 2**(2*LEVELS-i-1);
			begin
				genBits: for j in 0 to K-1 generate
					genOp: if j > D and (j+1) mod (2*D) = D generate
						gg(i)(j) <= (pp(i-1)(j) and gg(i-1)(j-D)) or gg(i-1)(j);
						pp(i)(j) <=  pp(i-1)(j) and pp(i-1)(j-D);
					end generate;
					genCp: if j <= D or (j+1) mod (2*D) /= D generate
						gg(i)(j) <= gg(i-1)(j);
						pp(i)(j) <= pp(i-1)(j);
					end generate;
				end generate;
			end generate genSpread;
			cc(cc'left downto M+1) <= gg(gg'high)(K-1 downto 1);
		end generate genPPN_BK;

		c    <= cc(K+M-2 downto M);
		cout <= cc(cc'left);

	end block blkCore;

  -----------------------------------------------------------------------------
  -- Implement Carry-Select Variant
  --
  -- all but rightmost block, implementation architecture selected by ARCH
  genBlocks: for i in 1 to K-1 generate
    -- Covered Index Range
    constant LO : positive := BLOCKS(i-1);  -- Low  Bit Index
    constant HI : positive := BLOCKS(i)-1;  -- High Bit Index
  begin

    -- ARCH-specific Implementations

    --Add-Add-Multiplex
    genAAM: if ARCH = AAM generate
			signal c0 : std_logic_vector(HI+1 downto LO);
			signal c1 : std_logic_vector(HI+1 downto LO);
		begin
			c0(LO) <= '0';
			c1(LO) <= '1';
			genChain: for j in LO to HI generate
				signal p0, s0 : std_logic;
				signal p1, s1 : std_logic;
			begin
				p0 <= a(j) xor b(j);

				-- Computation of (c0, s0)
				c0_mux: MUXCY
					port map (
						O  => c0(j+1),
						CI => c0(j),
						DI => a(j),
						S  => p0
					);
				c0_xor: XORCY
					port map (
						O  => s0,
						CI => c0(j),
						LI => p0
					);

				-- Computation of (c1, s1) and Block Sum
				c1_lut: LUT6_2
          generic map (
            INIT => x"66666666_FF00F0F0"
					)
          port map (
            O6 => p1,
            O5 => s(j),
            I5 => '1',
            I4 => c(i),
            I3 => s1,
            I2 => s0,
            I1 => b(j),
            I0 => a(j)
					);
				c1_mux: MUXCY
					port map (
						O  => c1(j+1),
						CI => c1(j),
						DI => a(j),
						S  => p1
					);
				c1_xor: XORCY
					port map (
						O  => s1,
						CI => c1(j),
						LI => p1
					);

			end generate genChain;
			g(i) <= c0(HI+1);
			p(i) <= c1(HI+1) xor c0(HI+1);

    end generate genAAM;

    -- Compare-Add-Increment
    genCAI: if ARCH = CAI generate
			constant MD : natural := (HI-LO+1)/2;     -- Full double blocks
			constant MR : natural := HI-LO+1 - 2*MD;  -- Single closing block

			signal c0 : std_logic_vector(HI+1  downto LO);
      signal pp : std_logic_vector(MR+MD downto  0);  -- Cumulative Propagates
    begin

			-- Computation of P and s
			c0(LO) <= '0';
			pp(0)  <= '1';
			genDoubles: for j in 0 to MD-1 generate
				constant BASE : natural := LO + 2*j;
				signal pl, pr : std_logic;  		-- Left / right propagates
				signal sl, sr : std_logic;  		-- Left / right sum bits
				signal pd : std_logic;  				-- Joint propagate
			begin

				-- Sum Bit Computations
				ps_lut_r: LUT6_2
          generic map (
            INIT => x"66666666_9F60FF00"
					)
          port map (
            O6 => pr,
            O5 => s(BASE+1),
            I5 => '1',
            I4 => c(i),
            I3 => sl,
            I2 => pp(j),
            I1 => b(BASE),
            I0 => a(BASE)
					);
				ps_lut_l: LUT6_2
          generic map (
            INIT => x"66666666_0FF0FF00"
					)
          port map (
            O6 => pl,
            O5 => s(BASE),
            I5 => '1',
            I4 => c(i),
            I3 => sr,
            I2 => pp(j),
            I1 => b(BASE+1),
            I0 => a(BASE+1)
					);
				c0_mux_r: MUXCY
					port map (
						O  => c0(BASE+1),
						CI => c0(BASE),
						DI => a(BASE),
						S  => pr
					);
				c0_mux_l: MUXCY
					port map (
						O  => c0(BASE+2),
						CI => c0(BASE+1),
						DI => a(BASE+1),
						S  => pl
					);
        genLSB: if j = 0 generate
					sr <= pr;
				end generate;
				genHSB: if j > 0 generate
					s0_xor_r: XORCY
						port map (
							O  => sr,
							CI => c0(BASE),
							LI => pr
						);
				end generate;
				s0_xor_l: XORCY
					port map (
						O  => sl,
						CI => c0(BASE+1),
						LI => pl
					);

				-- Propagate Chain
				pd <= (a(BASE+1) xor b(BASE+1)) and (a(BASE) xor b(BASE));
				pp_mux: MUXCY
					port map (
						O  => pp(j+1),
						CI => pp(j),
						DI => '0',
						S  => pd
					);

			end generate genDoubles;

			genLast: if MR > 0 generate
				constant BASE : natural := LO+2*MD;
				signal p, s0 : std_logic;
			begin
				ps_lut_l: LUT6_2
          generic map (
            INIT => x"66666666_0FF0FF00"
					)
          port map (
            O6 => p,
            O5 => s(BASE),
            I5 => '1',
            I4 => c(i),
            I3 => s0,
            I2 => pp(MD),
            I1 => b(BASE),
            I0 => a(BASE)
					);
				c0_mux: MUXCY
					port map (
						O  => c0(BASE+1),
						CI => c0(BASE),
						DI => a(BASE),
						S  => p
					);
				s0_xor: XORCY
					port map (
						O  => s0,
						CI => c0(BASE),
						LI => p
					);

				-- Let synthesis merge it into carry computation
				pp(pp'left) <= (a(BASE) xor b(BASE)) and pp(MD);

			end generate genLast;
			g(i) <= c0(c0'left);
			p(i) <= pp(pp'left);
		end generate genCAI;

		genCCA: if ARCH = CCA generate
			constant M : positive := HI-LO+1;
			constant D : positive := M/2;
			constant H : positive := (D+5)/6;

			signal pl : std_logic_vector(M-D-1 downto 0);
			signal pc : std_logic_vector(M-D   downto 0);

		begin
			pc(0) <= '0';
			genDoubles: for j in 0 to D-1 generate
				signal gl : std_logic;
			begin
				gp_lut: LUT6_2
          generic map (
            INIT => x"12480000_EE880000"
					)
          port map (
            O6 => pl(j),
            O5 => gl,
            I5 => '1',
            I4 => '1',
            I3 => a(LO+2*j+1),
            I2 => a(LO+2*j),
            I1 => b(LO+2*j+1),
            I0 => b(LO+2*j)
					);
				c0_mux: MUXCY
					port map (
						O  => pc(j+1),
						CI => pc(j),
						DI => gl,
						S  => pl(j)
					);
			end generate genDoubles;
			genOdd: if M-D > D generate
				pl(D)   <= a(HI) xnor b(HI);
				pc(D+1) <= pl(D) and pc(D);
			end generate genOdd;
			g(i) <= pc(pc'left);
			p(i) <= 'X' when Is_X(pl) else
							'1' when pl = (pl'range => '1') else
							'0';
      s(HI downto LO) <= std_logic_vector(unsigned(a(HI downto LO)) + unsigned(b(HI downto LO)) +
						(0 to 0 => c(i)));
		end generate genCCA;

  end generate genBlocks;

end architecture;
