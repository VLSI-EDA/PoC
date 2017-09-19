-- EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Thomas B. Preusser
--
-- Package: Types and functions to work with the generalized bit counter
--          modules and the derived compressor.
--
-- License:
-- =============================================================================
-- Copyright 2007-2015 Technische Universität Dresden - Germany,
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
use IEEE.std_logic_1164.all;

use std.textio.all;
use work.utils.all;

package arith_counters is

  constant DEBUG : boolean := false;

  -----------------------------------------------------------------------------
  -- Counter and Accessors
  type counter is record
                    tag     : natural;
                    inputs  : natural_vector(3 downto 0);
                    outputs : natural_vector(4 downto 0);
                    luts    : positive;
                  end record counter;

  impure function to_string(c : counter) return string;

  -- Asymptotic Height Reduction Ratio per Step
  function strength(c : counter) return real;

  -- Dot Reduction per LUT
  function efficiency(c : counter) return real;

  -- Numerical Slack within Maximum Output Range
  function slack(c : counter) return real;

  -- Some Preference Order based on the above: smaller is better
  function "<"(l, r : counter) return boolean;

  type order_type is (EFFICIENCY_STRENGTH, STRENGTH_EFFICIENCY, PRODUCT);
  constant ORDER : order_type := EFFICIENCY_STRENGTH;

  -----------------------------------------------------------------------------
  -- Counter Arrays
  type counter_vector is array(natural range<>) of counter;

  impure function to_string(cv : counter_vector) return string;

  function sort(cv : counter_vector) return counter_vector;

  constant COUNTERS : counter_vector := (
    ( 0, (0,6,0,6), (1,1,1,1,1), 4),
    ( 1, (0,6,1,5), (1,1,1,1,1), 4),
    ( 2, (0,6,2,3), (1,1,1,1,1), 4),

    ( 3, (1,4,0,6), (1,1,1,1,1), 4),
    ( 4, (1,4,1,5), (1,1,1,1,1), 4),
    ( 5, (1,4,2,3), (1,1,1,1,1), 4),

    ( 6, (2,2,0,6), (1,1,1,1,1), 4),
    ( 7, (2,2,1,5), (1,1,1,1,1), 4),
    ( 8, (2,2,2,3), (1,1,1,1,1), 4),

    ( 9, (1,3,2,5), (1,1,1,1,1), 4),

    (10, (0,0,2,5), (0,0,1,2,1), 2),
    (11, (0,0,0,6), (0,0,1,1,1), 3),
    (12, (0,0,0,3), (0,0,0,1,1), 1)
  );

  constant TAG_BUF   : positive := COUNTERS'length + 0;
  constant TAG_CC_CP : positive := COUNTERS'length + 1;
  constant TAG_CC_FA : positive := COUNTERS'length + 2;
  constant TAG_CC_42 : positive := COUNTERS'length + 3;

  -----------------------------------------------------------------------------
  -- Schedule Computation
  procedure print_schedule(s : integer_vector);
  impure function schedule(primaries : natural_vector; depth : natural := 0) return integer_vector;

end package arith_counters;


use std.textio.all;

library IEEE;
use IEEE.numeric_bit.all;

package body arith_counters is

  -----------------------------------------------------------------------------
  -- Counter and associated Metrics

  impure function to_string(c : counter) return string is
  begin
    return
      '('&to_string(ltrim(c.inputs))&':'&to_string(ltrim(c.outputs))&
      "] /"&integer'image(c.luts);
  end function;

  function strength(c : counter) return real is
  begin
    return  real(sum(c.inputs)) / real(sum(c.outputs));
  end function;

  function efficiency(c : counter) return real is
  begin
    return  real(sum(c.inputs)-sum(c.outputs)) / real(c.luts);
  end function;

  function slack(c : counter) return real is
  begin
    return  1.0 - real(1+max_weight(c.inputs))/real(1+max_weight(c.outputs));
  end function;

  function "<"(l, r : counter) return boolean is
    constant  le : real := efficiency(l);
    constant  re : real := efficiency(r);
    constant  ls : real := strength(l);
    constant  rs : real := strength(r);
  begin
    case ORDER is
    when EFFICIENCY_STRENGTH =>
      if le /= re then
	return  le > re;
      end if;
      if ls /= rs then
	return  ls > rs;
      end if;

    when STRENGTH_EFFICIENCY =>
      if ls /= rs then
	return  ls > rs;
      end if;
      if le /= re then
	return  le > re;
      end if;

    when others =>
      if le*ls /= re*rs then
	return  le*ls > re*rs;
      end if;

    end case;
    return  slack(l) < slack(r);
  end function;

  -----------------------------------------------------------------------------
  -- Counter Arrays
  function sort(cv : counter_vector) return counter_vector is
    variable res     : counter_vector(0 to cv'length-1);
    variable tmp     : counter;
    variable changed : boolean;
  begin
    -- Do a simple stable Bubble sort
    res := cv;
    for i in res'high-1 downto 0 loop
      -- Let bigger counters bubble up to the end
      changed := false;
      for j in 0 to i loop
        if res(j+1) < res(j) then
          tmp      := res(j);
          res(j)   := res(j+1);
          res(j+1) := tmp;
          changed  := true;
        end if;
      end loop;
      exit when not changed;
    end loop;
    return res;
  end function;

  impure function to_string(cv : counter_vector) return string is
    variable l : line;
  begin
    for i in cv'range loop
      write(l, to_string(cv(i)));
      write(l, LF);
    end loop;
    return  l.all;
  end function;

  -----------------------------------------------------------------------------
  -- Schedule Computation

  procedure print_schedule(s : integer_vector) is
    variable tag, w : natural;
    variable c      : counter;
    variable p      : positive;
    variable l      : line;
  begin
    for i in s'range loop
      if s(i) < 0 then
        tag := -s(i)-1;
        p   := i+1;
        if tag < COUNTERS'length then
          c := COUNTERS(tag);
          w := 0;
          for j in c.inputs'range loop
            w := w + c.inputs(j);
            if w > 0 then
              for k in 1 to c.inputs(j) loop
                --ite(l, character'('s'));
                write(l, s(p));
                if k < c.inputs(j) then
                  write(l, string'(", "));
                end if;
                p := p + 1;
              end loop;
              if j /= c.inputs'right then
                write(l, string'("; "));
              end if;
            end if;
          end loop;

          write(l, string'(" -> "));

          w := 0;
          for j in c.outputs'range loop
            w := w + c.outputs(j);
            if w > 0 then
              for k in 1 to c.outputs(j) loop
                --ite(l, character'('s'));
                write(l, s(p));
                if k < c.outputs(j) then
                  write(l, string'(", "));
                end if;
                p := p + 1;
              end loop;
              if j /= c.outputs'right then
                write(l, string'("; "));
              end if;
            end if;
          end loop;
        else
          -- not a counter
          if tag = TAG_BUF then
            write(l, s(p));
            p := p + 1;
            write(l, string'(" -> "));
            write(l, s(p));
            p := p + 1;
          elsif tag = TAG_CC_CP then
            write(l, string'("RES["));
						write(l, s(p));
            p := p + 1;
            write(l, string'("] = "));
						write(l, s(p));
            p := p + 1;
          elsif tag = TAG_CC_FA then
            write(l, string'("RES["));
						write(l, s(p));
            p := p + 1;
            write(l, string'("] = "));

            write(l, s(p));
            p := p + 1;
            write(l, string'(", "));
            write(l, s(p));
            p := p + 1;
            write(l, string'(", "));
            write(l, s(p));
            p := p + 1;
            write(l, string'("* -> "));
            write(l, s(p));
            p := p + 1;
            write(l, string'("*"));
          elsif tag = TAG_CC_42 then
            write(l, string'("RES["));
						write(l, s(p));
            p := p + 1;
            write(l, string'("] = "));

            write(l, s(p));
            p := p + 1;
            write(l, string'(", "));
            write(l, s(p));
            p := p + 1;
            write(l, string'(", "));
            write(l, s(p));
            p := p + 1;
            write(l, string'(", "));
            write(l, s(p));
            p := p + 1;
            write(l, string'(", "));
            write(l, s(p));
            p := p + 1;
            write(l, string'("* -> "));
            write(l, s(p));
            p := p + 1;
            write(l, string'(", "));
            write(l, s(p));
            p := p + 1;
            write(l, string'("*"));
          end if;
        end if;
        writeline(output, l);

      end if;
    end loop;
  end procedure print_schedule;

  impure function schedule(primaries : natural_vector; depth : natural := 0) return integer_vector is

    -- Reduction Dimensions
    constant M : natural := 2*MAXIMUM(primaries);
    constant W : natural := clog2_maxweight(primaries);

    --------------------
    -- Signal queue types and manipulation functions
    variable  sig_count : positive := 1;  -- Next ID to assign to a signal

    type natural_queue is record
      wp, rp : natural;                 -- Write and Read Pointers
      buf    : natural_vector(0 to M);  -- Data Buffer
    end record;
    type bit_queues is array(natural range<>) of natural_queue;
    variable cols : bit_queues(W-1 downto 0);

    impure function height(idx : natural) return natural is
    begin
      return  cols(idx).wp - cols(idx).rp;
    end function height;

    procedure append(idx : natural; val : integer) is
      variable  wp  : natural;
    begin
      wp := cols(idx).wp;
      cols(idx).buf(wp mod(M+1)) := val;
      cols(idx).wp := wp + 1;
    end procedure append;

    impure function push(idx : natural) return natural is
      variable  res : natural;
    begin
      res := sig_count;
      sig_count := res + 1;
      append(idx, res);
      return  res;
    end function push;

    impure function pop(idx : natural) return natural is
      variable  rp  : natural;
      variable  res : natural;
    begin
      rp  := cols(idx).rp;
      res := cols(idx).buf(rp mod(M+1));
      cols(idx).rp := rp + 1;
      return  res;
    end function pop;

    --------------------
    -- Result Construction
    variable res_buf : integer_vector(0 to 10*(sum(primaries)+W));
    variable res_ptr : natural := 0;

    procedure res_add(v : integer) is
    begin
      res_buf(res_ptr) := v;
      res_ptr := res_ptr + 1;
    end procedure res_add;

    --------------------
    -- Compression

    -- Ordered list of counters
    constant COUNTS : counter_vector := sort(COUNTERS);

    -- Height Status
    variable level   : natural := 0;
    variable anchor  : natural := 0;
		variable carries : natural := 0;

    -- Current Compression Anchor
    procedure update_anchor is
      variable cnt : natural;
    begin
      while (anchor < W) and (height(anchor) <= 4) and (height(anchor)+carries <= 5) loop
				-- Compute number of carries to pass in final addition and leave column alone
				carries := (height(anchor) + carries) / 2;
        anchor  := anchor + 1;
      end loop;
    end update_anchor;

    --------------------
    -- Temporaries
    variable tn      : natural;
    variable cnt     : counter;
    variable c_width : natural;
    variable l       : line;

    variable height_in : natural_vector(W-1 downto 0);

  begin

    -- Debug Ground State Report
    if DEBUG then
      write(l, string'("Counter Preference:"&HT&HT&"[  Eff / Strng/ Slack]"));
      writeline(output, l);
      write(l, string'("---------"));
      writeline(output, l);
      for i in COUNTS'range loop
        cnt := COUNTS(i);
        write(l, i, RIGHT, 2);
        write(l, ':');
        write(l, to_string(cnt), RIGHT, 23);
        write(l, string'(HT & "[ "));
        write(l, efficiency(cnt), RIGHT, 4, 2);
        write(l, string'(" / "));
        write(l, strength(cnt), RIGHT, 4, 2);
        write(l, string'(" / "));
        write(l, slack(cnt), RIGHT, 4, 2);
        write(l, string'(" ]"));
        writeline(output, l);
      end loop;
      write(l, string'("---------"));
      writeline(output, l);
    end if;

    write(l, string'("---------"));
    writeline(output, l);
    write(l, sum(primaries));
    write(l, string'(" Primaries: "));
    write(l, to_string(primaries));
    writeline(output, l);

    -- Initialize Primary Inputs
    for i in primaries'reverse_range loop
      for j in 1 to primaries(i) loop
        tn := push(abs(i-primaries'right));
      end loop;
    end loop;

    -- Schedule Compression Stages
    update_anchor;
    while anchor < W loop
      -- Freeze available Input Heights
      for i in anchor to W-1 loop
        height_in(i) := height(i);
      end loop;

      -- Schedule Counters
      for i in COUNTS'range loop
        cnt := COUNTS(i);
        c_width := ltrim(cnt.inputs)'length;
        for pos in anchor to W-c_width loop
          lplace: loop
            -- Drop out when counter no longer fits here
            for ofs in 0 to c_width-1 loop
              exit lplace when cnt.inputs(ofs) > height_in(pos+ofs);
            end loop;

            -- Schedule an Instance of this Counter
            assert not DEBUG
              report to_string(cnt)&" @"&integer'image(pos)
              severity note;

            -- Tag
            res_add(-cnt.tag-1);

            -- Inputs
            for k in c_width-1 downto 0 loop
              tn := cnt.inputs(k);
              for l in 1 to tn loop
                res_add(pop(pos+k));
              end loop;
              height_in(pos+k) := height_in(pos+k) - tn;
            end loop;

            -- Outputs
            for k in integer range ltrim(cnt.outputs)'length-1 downto 0 loop
              tn := cnt.outputs(k);
              for l in 1 to tn loop
                res_add(push(pos+k));
              end loop;
            end loop;

          end loop;    -- at position
        end loop; -- through positions
      end loop;   -- through counters

      -------------------------------------------------------------------------
      -- Insert Buffers as requested
      level := level + 1;
      if (depth > 0) and (level mod depth = 0) then
        for i in 0 to W-1 loop
          tn := height(i);
          for j in 1 to tn loop
            res_add(-TAG_BUF-1);
            res_add(pop(i));
            res_add(push(i));
          end loop;
        end loop;
      end if;
      update_anchor;

    end loop;

		---------------------------------------------------------------------------
		-- Schedule the Carry-Propagate Stage
		for i in 0 to W-1 loop
			-- Fill up column to a full CP[1->1]/FA[3->2]/TE[5->3]
			tn := height(i);

			-- Select Output Module
			case tn is
				when 0|1 =>
					res_add(-TAG_CC_CP-1);
				when 2|3 =>
					res_add(-TAG_CC_FA-1);
				when 4|5 =>
					res_add(-TAG_CC_42-1);
				when others =>
					report "Internal Compression Error" severity failure;
			end case;

			-- Define Output Column
			res_add(i);

			-- Pad even number of inputs
			if tn mod 2 = 0 then
				res_add(0);
			end if;

			-- Append true input signals
			for j in 1 to tn loop
				res_add(pop(i));
			end loop;

			-- Append output signals
			carries := tn/2;
			for j in 1 to carries loop
				if i+1 < W then
					res_add(push(i+1));
				else
					res_add(sig_count);
					sig_count := sig_count + 1;
				end if;
			end loop;

		end loop;  -- i

    write(l, string'("Total Levels:"));
    write(l, level, RIGHT, 3);
    writeline(output, l);
    write(l, string'("Final Width: "));
    write(l, W);
    writeline(output, l);
    write(l, string'("Counters:"));
    writeline(output, l);
    for i in COUNTS'range loop
      cnt := COUNTS(i);
      tn := count(res_buf(0 to res_ptr-1), -cnt.tag-1);
      if tn /= 0 then
        write(l, tn, RIGHT, 3);
        write(l, string'("x "));
        write(l, to_string(cnt), RIGHT, 22);
        writeline(output, l);
      end if;
    end loop;
    write(l, string'("---------"));
    writeline(output, l);
    writeline(output, l);

    -- Print Schedule
		if DEBUG then
			write(l, string'("Raw Schedule: "));
			write(l, to_string(res_buf(0 to res_ptr-1)));
			writeline(output, l);
			write(l, string'("Schedule Details:"));
			writeline(output, l);
			print_schedule(res_buf(0 to res_ptr-1));
		end if;

    return  res_buf(0 to res_ptr-1);

  end function schedule;

end package body arith_counters;
