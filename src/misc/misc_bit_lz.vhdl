-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Description:
--
--  An LZ77-based bit stream compressor.
--
--  Output Format
--
--  1 | Literal
--    A literal bit string of length COUNT_BITS+OFFSET_BITS.
--
--  0 | <Count:COUNT_BITS> | <Offset:OFFSET_BITS>
--    Repetition starting at <Offset> in history buffer of length
--    <Count>+COUNT_BITS+OFFSET_BITS where <Count> < 2^COUNT_BITS-1.
--    Unless <Count> = 2^COUNT_BITS-2, this repetition is
--    followed by a trailing non-matching, i.e. inverted, bit.
--    The most recent bit just preceding the repetition is considered to be at
--    offset zero(0). Older bits are at higher offsets accordingly. The
--    reported length of the repetition may actually be greater than the
--    offset. In this case, the repetition is reoccuring in itself. The
--    reconstruction must then be performed in several steps.
--
--  0 | <1:COUNT_BITS> | <Offset:OFFSET_BITS>
--    This marks the end of the message. The <Offset> field alters the
--    semantics of the immediately preceding message:
--
--    a)If the preceding message was a repetition, <Offset> specifies the value
--      of the trailing bit explicitly in its rightmost bit. The implicit
--      trailing non-matching bit is overridden.
--    b)If the preceding message was a literal, <Offset> is a non-positive
--      number d given in its one's complement representation. The value
--      ~d specifies the number of bits,  which this literal repeated of the
--      preceding output. These bits must be deleted from the reconstructed
--      stream.
--
--
--  Parameter Constraints
--
--   COUNT_BITS <= OFFSET_BITS < 2**COUNT_BITS - COUNT_BITS
--
-- =============================================================================
-- Authors:     Thomas B. Preusser <thomas.preusser@utexas.edu>
--
-- =============================================================================
-- References:
--
--   Original Study
--      Kai-Uwe Irrgang <kai-uwe.irrgang@b-tu.de>
--      PhD Thesis: "Modellierung von On-Chip-Trace-Architekturen
--                   fuer eingebettete Systeme"
--
--   Papers
--      Kai-Uwe Irrgang and Thomas B. Preusser and Rainer G. Spallek:
--      "An LZ77-Style Bit-Level Compression for Trace Data Compaction",
--      International Conference on Field Programmable Logic and
--      Applications (FPL 2015), Sep, 2015.
--
--      Kai-Uwe Irrgang and Thomas B. Preusser and Rainer G. Spallek:
--      "Kompression von Tracedaten auf der Basis eines auf Bitebene
--       arbeitenden LZ77-Woerterbuchansatzes",
--      Fehlertolerante und energieeffiziente eingebettete Systeme:
--      Methoden und Anwendungen (FEES 2015), Oct, 2015.
-- =============================================================================
library IEEE;
use IEEE.std_logic_1164.all;

entity misc_bit_lz is
  generic(
    COUNT_BITS     : positive;
    OFFSET_BITS    : positive;
    OUTPUT_REGS    : boolean := true;   -- Register all outputs
    OPTIMIZE_SPEED : boolean := true    -- Favor achievable clock over size
  );
  port(
    -- Global Control
    clk : in std_logic;
    rst : in std_logic;

    -- Data Input
    din   : in std_logic;
    put   : in std_logic;
    flush : in std_logic;  -- end of message,
                           -- to be asserted after last associated put

    -- Data Output
    odat : out std_logic_vector(COUNT_BITS+OFFSET_BITS downto 0);
    ostb : out std_logic
  );
end misc_bit_lz;


library IEEE;
use IEEE.numeric_std.all;

architecture rtl of misc_bit_lz is

  constant HISTORY_SIZE : positive := 2**OFFSET_BITS;
  constant LITERAL_LEN  : positive := COUNT_BITS + OFFSET_BITS;

  -- History and Match Buffers
  signal History : std_logic_vector(HISTORY_SIZE   downto 0) := (others => '0');
  signal Match   : std_logic_vector(HISTORY_SIZE-1 downto 0) := (others => '1');

  signal Count  : signed(COUNT_BITS downto 0)      := to_signed(-LITERAL_LEN-1, 1+COUNT_BITS);
  signal Offset : unsigned(OFFSET_BITS-1 downto 0) := (others => '-');
  signal Term   : std_logic                        := '0';

  signal Offset_nxt : unsigned(Offset'range);
  signal ov         : X01;              -- Counter Overflow
  signal valid      : X01;              -- Still some Match available

  -- Outputs
  signal data : std_logic_vector(odat'range);
  signal push : std_logic;

begin

  assert COUNT_BITS <= OFFSET_BITS
    report "Requiring: COUNT_BITS <= OFFSET_BITS"
    severity failure;
  assert LITERAL_LEN < 2**COUNT_BITS
    report "Requiring: COUNT_BITS + OFFSET_BITS < 2**COUNT_BITS"
    severity failure;

  -- Registers
  process(clk)
    variable Count_nxt : signed(Count'range);
    variable Match_nxt : std_logic_vector(Match'range);
  begin
    if rising_edge(clk) then
      if rst = '1' or Term = '1' then
        History <= (others => '0');
        Match   <= (others => '1');
        Count   <= to_signed(-LITERAL_LEN-1, Count'length);
        Offset  <= (others => '-');
        Term    <= '0';
      elsif flush = '1' then
        History <= (others => '-');
        Match   <= (others => '-');
				Count   <= (others => '1');  -- End Marker
				Count(Count'left) <= '0';    -- Output Format Selector
        if Count(Count'left) = '0' then
					Offset    <= (others => '0');
          Offset(0) <= History(0);
        else
					Offset    <= (others => '1'); -- Sign Extension
          Offset(Count'left-1 downto 0) <= unsigned(Count(Count'left-1 downto 0));
        end if;
        Term <= '1';
      else

        -- Check for an output condition
        if push = '0' then
          Match_nxt := Match;
          Count_nxt := Count;
          Offset    <= Offset_nxt;
        else
          case ov is
            when '0' =>
              Count_nxt := to_signed(-LITERAL_LEN-1, Count'length);
              Match_nxt := (others => '1');
            when '1' =>
              Count_nxt := to_signed(-LITERAL_LEN,   Count'length);
              Match_nxt := History(History'left downto 1) xnor (Match'range => History(0));
            when 'X' =>
              Count_nxt := (others => 'X');
              Match_nxt := (others => 'X');
          end case;

          Offset <= (others => '-');
        end if;

        -- Check for an input condition
        if put = '1' then
          -- Shift input into History Buffer
          History <= History(History'left-1 downto 0) & din;

          -- Update Match vector and Count
          Match_nxt := Match_nxt and (History(Match'range) xnor (Match'range => din));
          Count_nxt := Count_nxt + 1;
        end if;

        Match <= Match_nxt;
        Count <= Count_nxt;

      end if; -- rst /= '1'
    end if;   -- rising_edge(clk)

  end process;

  genPlain: if OPTIMIZE_SPEED generate
    process(Match)
    begin
      Offset_nxt <= (others => '-');
      for i in Match'range loop
        if Match(i) = '1' then
          Offset_nxt <= to_unsigned(i, Offset'length);
        end if;
      end loop;
    end process;
  end generate genPlain;
  genArith: if not OPTIMIZE_SPEED generate
    process(Match)
      variable onehot : std_logic_vector(Match'range);
      variable binary : unsigned(Offset'range);
    begin
      onehot := std_logic_vector(unsigned(not Match) + 1) and Match;
      binary := (others => '0');
      for i in onehot'range loop
        if onehot(i) = '1' then
          binary := binary or to_unsigned(i, binary'length);
        end if;
      end loop;
      Offset_nxt <= binary;
    end process;
  end generate genArith;

  -- Check for Counter Overflow
  ov <= 'X' when Is_X(std_logic_vector(Count)) else
        '1' when Count = 2**COUNT_BITS-2 else
        '0';

  -- Check if there is still some valid Match
  valid <= '0' when Match = (Match'range => '0') else                                  -- all '0'
           'X' when to_bitvector(std_ulogic_vector(Match)) = (Match'range => '0') else -- no '1'
           '1';                                                                        -- some '1'

  -- Compute Outputs
  data <= '1' & History(LITERAL_LEN-1 downto 0) when Count(Count'left) = '1' else -- literal
          std_logic_vector(Count) & std_logic_vector(Offset);                     -- repetition
  push <= '1' when flush = '1' or Term = '1' else
          'X' when Is_X(std_logic_vector(Count)) else
          ov  when ov /= '0' else
          not valid when Count >= -1 else
          '0';

  genOutputComb: if not OUTPUT_REGS generate
    odat <= data;
    ostb <= push;
  end generate;
  genOutputRegs: if OUTPUT_REGS generate
    process(clk)
    begin
      if rising_edge(clk) then
				odat <= data;
				ostb <= push;
      end if;
    end process;
  end generate;

end rtl;
