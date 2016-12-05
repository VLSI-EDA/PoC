-- EMACS settings: -*-  tab-width:2  -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-------------------------------------------------------------------------------
-- Description:  Simple terminal interface to monitor and manipulate
--               basic IO components such as buttons, slide switches, LED
--               and hexadecimal displays.
--
-- A typical transport would be a UART connection using a terminal application.
-- A command line starts with a single letter identifying the addressed
-- resource type:
--
--    R .. Reset  - strobed input to the design
--    P .. Pulse  - strobed input to the design
--    S .. Switch - stateful input to the design
--    L .. Light  - (bit) output from the design
--    D .. Digit  - (hex) output from the design
--
-- This letter may be followed by a hexadecimal input vector, which triggers
--
--    R - a strobe on the corresponding inputs,
--    P - a strobe on the corresponding inputs, and
--    S - a state toggle of the corresponding inputs.
--
-- The input vector is ignored for outputs from the design.
-- The command line may contain an arbitrary amount of spaces.
--
-- The terminal interface will echo with:
--
--   <resource character>[<bit count>'<hex output vector>]
--
-- The <bit count> and <hex output vector> will only be present if, at least,
-- a single instance of the addressed resource type is available.
-- In particular, the resource characters of lines starting with other than
-- the listed resource types will simply be echoed.
-- The <bit count> describes how many bits of the addressed resource are
-- available, which may be used to explore the resources using a command line
-- with no or a zero input argument. The <bit count> is typically provided in
-- decimal (default) but may be changed to hexadecimal through the generic
-- parameter COUNT_DECIMAL.
-- The <hex output vector> acknowledges the input (R and P) and informs about
-- the current state (S, L and D).
--
-- Example:
--  > L
--    L10'21D
--  > D
--    D8'5E
--  > A
--    A
--  > S
--    S6'00
--  > S3A
--    S6'3A
--  > S 1
--    S6'3B
--  > P8
--    P4'8
--  > P
--    P4'0

-- Authors:      Thomas B. Preußer <thomas.preusser@utexas.edu>
-------------------------------------------------------------------------------
-- Copyright 2007-2014 Technische Universität Dresden - Germany
--                     Chair of VLSI-Design, Diagnostics and Architecture
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

library poc;
use poc.functions.all;

entity remote_terminal_control is
  generic (
    RESET_COUNT  : natural;
    PULSE_COUNT  : natural;
    SWITCH_COUNT : natural;
    LIGHT_COUNT  : natural;
    DIGIT_COUNT  : natural;

    COUNT_DECIMAL : boolean := true
  );
  port (
    -- Global Control
    clk  : in  std_logic;
    rst  : in  std_logic;

    -- UART Connectivity
    idat : in  std_logic_vector(6 downto 0);
    istb : in  std_logic;
    odat : out std_logic_vector(6 downto 0);
    ordy : in  std_logic;
    oput : out std_logic;

    -- Control Outputs
    resets   : out std_logic_vector(imax(RESET_COUNT -1, 0) downto 0);
    pulses   : out std_logic_vector(imax(PULSE_COUNT -1, 0) downto 0);
    switches : out std_logic_vector(imax(SWITCH_COUNT-1, 0) downto 0);

    -- Monitor Inputs
    lights : in std_logic_vector(imax(  LIGHT_COUNT-1, 0) downto 0);
    digits : in std_logic_vector(imax(4*DIGIT_COUNT-1, 0) downto 0)
  );
end remote_terminal_control;


library IEEE;
use IEEE.numeric_std.all;

architecture rtl of remote_terminal_control is

  type    tKind is (KIND_NONE,
                    KIND_RESET, KIND_PULSE, KIND_SWITCH,
                    KIND_LIGHT, KIND_DIGIT);
  --constant KIND_NONE   : natural := 0;
  --constant KIND_RESET  : natural := 1;
  --constant KIND_PULSE  : natural := 2;
  --constant KIND_SWITCH : natural := 3;
  --constant KIND_LIGHT  : natural := 4;
  --constant KIND_DIGIT  : natural := 5;
  --subtype tKind   is natural range KIND_NONE  to KIND_DIGIT;
  subtype tActual is tKind   range KIND_RESET to KIND_DIGIT;
  subtype tInput  is tActual range KIND_RESET to KIND_SWITCH;
  subtype tOutput is tActual range KIND_LIGHT to KIND_DIGIT;

  -----------------------------------------------------------------------------
  -- Counts
  type    tCounts is array(tKind range<>) of natural;
  constant COUNTS  : tCounts := (0,
                                 RESET_COUNT,   PULSE_COUNT, SWITCH_COUNT,
                                 LIGHT_COUNT, 4*DIGIT_COUNT);
  function max_count(arr : tCounts) return natural is
    -- Without this copy of arr, ISE (as of version 14.7) will choke.
	 variable  a   : tCounts(arr'range) := (others => 0);
    variable  res : natural;
  begin
    a(arr'range) := arr;
    res := 0;
    for i in a'range loop
      if a(i) > res then
        res := a(i);
      end if;
    end loop;
    return  res;
  end max_count;

  constant PAR_BITS : natural := max_count(COUNTS(tInput));
  constant RES_BITS : natural := max_count(COUNTS(tActual));
  constant ECO_BITS : natural := 4*((RES_BITS+3)/4);


  function log10ceil(x : natural) return positive is
    variable scale, res : positive;
  begin
    scale := 10;
    res   := 1;
    while x >= scale loop
      scale := 10*scale;
      res   := res+1;
    end loop;
    return res;
  end log10ceil;
  function makeCntBits return positive is
  begin
    if COUNT_DECIMAL then
      return  4*log10ceil(RES_BITS);
    end if;
    return  log2ceil(RES_BITS);
  end makeCntBits;

  constant CNT_BITS : positive := makeCntBits;


  subtype tOutCount  is unsigned(CNT_BITS-1 downto 0);
  type    tOutCounts is array(tKind range<>) of tOutCount;
  function makeOutCounts return tOutCounts is
    variable res : tOutCounts(COUNTS'range);
    variable ele : tOutCount;
    variable rmd : natural;
  begin
    for i in COUNTS'range loop
      if COUNT_DECIMAL then
        rmd := COUNTS(i);
        for j in 0 to ele'length/4-1 loop
          ele(4*j+3 downto 4*j) := to_unsigned(rmd mod 10, 4);
          rmd                   := rmd/10;
        end loop;
      else
        ele := to_unsigned(COUNTS(i), CNT_BITS);
      end if;
      res(i) := ele;
    end loop;
    return  res;
  end;
  constant OUT_COUNTS : tOutCounts(COUNTS'range) := makeOutCounts;

  subtype tCode is std_logic_vector(4 downto 0);
  type    tCodes is array(tKind range<>) of tCode;
  constant CODES : tCodes(tActual) := ("10010", "10000", "10011", "01100", "00100");

  type    tStrobes is array(tKind range<>) of boolean;
  constant STROBES : tStrobes(tInput) := (true, true, false);

  signal BufVld : std_logic                         := '0';
  signal BufCmd : std_logic_vector(4 downto 0)      := (others => '-');
  signal BufCnt : unsigned(CNT_BITS-1 downto 0)     := (others => '-');
  signal BufEco : std_logic_vector(0 to ECO_BITS-1) := (others => '-');
  signal BufAck : std_logic;

begin

  -- Reading the UART input stream
  blkReader: block

    type   tState is (Idle, Command);
    signal State     : tState := Idle;
    signal NextState : tState;

    signal Cmd : std_logic_vector(4 downto 0)          := (others => '-');
    signal Arg : std_logic_vector(PAR_BITS-1 downto 0) := (others => '-');
    signal Sel : tKind                                 := KIND_NONE;

    signal Load   : std_logic;
    signal Shift  : std_logic;
    signal Commit : std_logic;

    subtype tEcho is std_logic_vector(0 to ECO_BITS-1);
    type    tEchos is array(tKind range<>) of tEcho;
    signal  echos : tEchos(tKind);

    function leftAlignedBCD(x : std_logic_vector) return tEcho is
      constant MY_BITS : positive := 4*((x'length+3)/4);
      variable res     : tEcho;
    begin
      res                                := (others => '-');
      res(0 to 3)                        := x"0";
      res(MY_BITS-x'length to MY_BITS-1) := x;
      return  res;
    end leftAlignedBCD;

  begin
    -- State Registers
    process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          State <= Idle;
          Cmd   <= (others => '-');
          Arg   <= (others => '-');
        else
          State <= NextState;

          if Load = '1' then
            Cmd <= idat(4 downto 0);
            Arg <= (others => '0');

            Sel <= KIND_NONE;
            for i in CODES'range loop
              if CODES(i) = idat(4 downto 0) then
                Sel <= i;
              end if;
            end loop;

          elsif Shift = '1' then
            Arg <= Arg(Arg'left-4 downto 0) &
                   std_logic_vector(unsigned(idat(3 downto 0)) + (idat(6)&"00"&idat(6)));
          end if;
        end if;
      end if;
    end process;

    -- Common Reader State Machine
    process(State, istb, idat)
    begin
      NextState <= State;

      Load   <= '0';
      Shift  <= '0';
      Commit <= '0';

      if istb = '1' then
        case State is
          when Idle =>
            if idat(6) = '1' then
              Load      <= '1';
              NextState <= Command;
            end if;

          when Command =>
            if idat(6) = '1' or (idat(5) = '1' and idat(4) = '1') then
              Shift     <= '1';
            elsif idat(6) = '0' and idat(5) = '0' and idat(4) = '0' then
              Commit    <= '1';
              NextState <= Idle;
            end if;

        end case;
      end if;
    end process;

    echos(KIND_NONE) <= (others => '-');

    -- Generate Control Inputs
    genInputs: for i in tInput generate

      -- Control not used
      genNone: if COUNTS(i) = 0 generate
        genReset: if i = KIND_RESET generate
          resets <= "X";
        end generate genReset;
        genPulse: if i = KIND_PULSE generate
          pulses <= "X";
        end generate genPulse;
        genSwitch: if i = KIND_SWITCH generate
          switches <= "X";
        end generate genSwitch;
        echos(i) <= (others => '-');
      end generate genNone;

      -- Controls available
      genAvail: if COUNTS(i) > 0 generate
        signal Outputs  : std_logic_vector(COUNTS(i)-1 downto 0) := (others => '0');
        signal onxt     : std_logic_vector(Outputs'range);
      begin

        -- Output Computation: Strobed
        genStrobed: if STROBES(i) generate
          process(clk)
          begin
            if rising_edge(clk) then
              if rst = '1' then
                Outputs <= (others => '0');
              else
                if Commit = '1' and Sel = i then
                  Outputs <= onxt;
                else
                  Outputs <= (others => '0');
                end if;
              end if;
            end if;
          end process;
          onxt <= Arg(Outputs'range);
        end generate genStrobed;

        -- Output Computation: State
        genState: if not STROBES(i) generate
          process(clk)
          begin
            if rising_edge(clk) then
              if Commit = '1' and Sel = i then
                Outputs <= onxt;
              end if;
            end if;
          end process;
          onxt <= Outputs xor Arg(Outputs'range);
        end generate genState;
        echos(i) <= leftAlignedBCD(onxt);

        -- Assign to Output Pins
        genReset: if i = KIND_RESET generate
          resets <= Outputs;
        end generate genReset;
        genPulse: if i = KIND_PULSE generate
          pulses <= Outputs;
        end generate genPulse;
        genSwitch: if i = KIND_SWITCH generate
          switches <= Outputs;
        end generate genSwitch;
      end generate genAvail;

    end generate genInputs;

    process(lights, digits)
    begin
      echos(KIND_LIGHT) <= (others => '-');
      echos(KIND_DIGIT) <= (others => '-');
      if LIGHT_COUNT > 0 then
        echos(KIND_LIGHT) <= leftAlignedBCD(lights);
      end if;
      if DIGIT_COUNT > 0 then
        echos(KIND_DIGIT) <= leftAlignedBCD(digits);
      end if;
    end process;

    -- Build Data Record for Writer
    process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          BufVld <= '0';
          BufCmd <= (others => '-');
          BufCnt <= (others => '-');
          BufEco <= (others => '-');
        else
          if Commit = '1' then
            BufVld <= '1';
            BufCmd <= Cmd;
            BufCnt <= OUT_COUNTS(Sel);
            BufEco <= echos(Sel);
          elsif BufAck = '1' then
            BufVld <= '0';
            BufCmd <= (others => '-');
            BufCnt <= (others => '-');
            BufEco <= (others => '-');
          end if;
        end if;
      end if;
    end process;

  end block blkReader;

  blkWrite: block

    type   tState is (Idle, OutCommand, OutCount, OutTick, OutEcho, OutEOL);
    signal State     : tState := Idle;
    signal NextState : tState;

    signal OutCmd : std_logic_vector(4 downto 0)                 := (others => '-');
    signal OutCnt : unsigned(4*((BufCnt'length+3)/4)-1 downto 0) := (others => '-');
    signal OutEco : std_logic_vector(0 to ECO_BITS-1)            := (others => '-');

    signal Locked     : std_logic := '-';
    signal NextLocked : std_logic;
    signal OutCntDone : std_logic;
    signal OutCntDecr : unsigned(2 downto 0);
    signal NextOutCnt : unsigned(OutCnt'length downto 0);

    signal ShiftCnt : std_logic;
    signal ShiftEco : std_logic;

  begin

    process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          State <= Idle;

          OutCmd <= (others => '-');
          OutCnt <= (others => '-');
          OutEco <= (others => '-');
          Locked <= '-';

        else
          State <= NextState;

          if BufAck = '1' then
            OutCmd <= BufCmd;
            OutCnt <= (others => '0');
            OutCnt(BufCnt'length-1 downto 0) <= unsigned(BufCnt);
            OutEco <= BufEco;
            Locked <= '0';
          else

            -- OutCnt Register
            if OutCnt'length > 4 and ShiftCnt = '1' then
              OutCnt <= OutCnt(OutCnt'left-4 downto 0) & OutCnt(OutCnt'left downto OutCnt'left-3);
            else
              OutCnt <= NextOutCnt(OutCnt'range);
            end if;
            Locked <= NextLocked;

            -- OutEco Register
            if ShiftEco = '1' then
              OutEco <= OutEco(4 to OutEco'right) & "----";
            end if;

          end if;
        end if;
      end if;
    end process;
    NextLocked <= 'X' when Is_x(std_logic_vector(OutCnt(OutCnt'left downto OutCnt'left-3))) else
                  '1' when OutCnt(OutCnt'left downto OutCnt'left-3) /= x"0" else
                  Locked;

    genSingleDig: if OutCnt'length = 4 generate
      OutCntDone <= '1';
    end generate;
    genMultiDig: if OutCnt'length > 4 generate
      signal Cnt : unsigned(log2ceil(OutCnt'length/4)-1 downto 0) := (others => '-');
    begin
      process(clk)
      begin
        if rising_edge(clk) then
          if rst = '1' then
            Cnt <= (others => '-');
          else
            if BufAck = '1' then
              Cnt <= (others => '0');
            elsif ShiftCnt = '1' then
              Cnt <= Cnt + 1;
            end if;
          end if;
        end if;
      end process;
      OutCntDone <= 'X' when Is_X(std_logic_vector(Cnt)) else
                    '1' when (Cnt or not to_unsigned(OutCnt'length/4-1, Cnt'length)) = (Cnt'range => '1') else
                    '0';
    end generate;

    genDec: if COUNT_DECIMAL generate
      process(OutCnt, OutCntDecr)
        variable sub : unsigned(2 downto 0);
        variable d   : unsigned(4 downto 0);
      begin
        sub := OutCntDecr;
        for i in 0 to OutCnt'length/4-1 loop
          d := ('0'&OutCnt(4*i+3 downto 4*i)) - sub;
          if d(4) = '0' then
            NextOutCnt(4*i+3 downto 4*i) <= d(3 downto 0);
            sub := to_unsigned(0, sub'length);
          else
            NextOutCnt(4*i+3 downto 4*i) <= d(3 downto 0) - 6;
            sub := to_unsigned(1, sub'length);
          end if;
        end loop;
        NextOutCnt(OutCnt'length) <= sub(0);
      end process;
    end generate genDec;
    genHex: if not COUNT_DECIMAL generate
      NextOutCnt <= ('0'&OutCnt) - OutCntDecr;
    end generate genHex;

    process(State, ordy, BufVld, OutCmd, OutCnt, OutEco, OutCntDone, NextLocked, NextOutCnt)
    begin

      NextState <= State;

      BufAck     <= '0';
      ShiftCnt   <= '0';
      ShiftEco   <= '0';
      OutCntDecr <= (others => '0');

      odat <= (others => '-');
      oput <= '0';

      case State is
        when Idle =>
          if BufVld = '1' then
            BufAck    <= '1';
            NextState <= OutCommand;
          end if;

        when OutCommand =>
          odat <= "10" & OutCmd;
          oput <= '1';
          if ordy = '1' then
            NextState <= OutCount;
          end if;

        when OutCount =>
          if COUNT_DECIMAL or OutCnt(OutCnt'left downto OutCnt'left-3) < 10 then
            odat <= "011" & std_logic_vector(OutCnt(OutCnt'left downto OutCnt'left-3));
          else
            odat <= "100" & std_logic_vector(OutCnt(OutCnt'left downto OutCnt'left-3)+7);
          end if;
          oput <= NextLocked;
          if ordy = '1' then
            ShiftCnt <= '1';
            if OutCntDone = '1' then
              if NextLocked = '1' then
                NextState <= OutTick;
              else
                NextState <= OutEOL;
              end if;
            end if;
          end if;

        when OutTick =>
          odat <= "0100111";
          oput <= '1';
          if ordy = '1' then
            OutCntDecr <= to_unsigned(1, OutCntDecr'length);
            NextState  <= OutEcho;
          end if;

        when OutEcho =>
          if unsigned(OutEco(0 to 3)) < 10 then
            odat <= "011" & OutEco(0 to 3);
          else
            odat <= "100" & std_logic_vector(unsigned(OutEco(0 to 3))+7);
          end if;
          oput <= '1';
          if ordy = '1' then
            ShiftEco   <= '1';
            OutCntDecr <= "100";
            if NextOutCnt(OutCnt'length) = '1' then
              NextState <= OutEOL;
            end if;
          end if;

        when OutEOL =>
          odat <= "0001010";
          oput <= '1';
          if ordy = '1' then
            NextState <= Idle;
          end if;

      end case;
    end process;

  end block blkWrite;

end rtl;
