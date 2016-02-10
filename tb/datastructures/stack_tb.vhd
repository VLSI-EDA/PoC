library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

library PoC;

entity stack_tb is
end entity;

architecture tb of stack_tb is

  -- component generics
  constant MIN_DEPTH      : positive := 128;
  constant D_BITS         : positive := 16;
  constant A_BITS         : natural := INTEGER(CEIL(LOG2(REAL(MIN_DEPTH))));


  -- Clock Control
  signal rst  : std_logic;
  signal clk  : std_logic := '1';
  signal done : std_logic := '0';
  constant clk_period : time := 20 ns;

  -- local Signals

  -- inputs
  signal din : std_logic_vector(D_BITS-1 downto 0) := (others => '0');
  signal put : std_logic := '0';
  signal got : std_logic := '0';

  -- outputs
  signal dout : std_logic_vector(D_BITS-1 downto 0);
  signal full : std_logic;
  signal valid : std_logic;
  signal empty : std_logic;


begin

  -- clk generation
  clk <= not clk after clk_period/2 when done /= '1' else '0';

  -- component initialisation
  DUT : entity PoC.stack
  generic map (
    D_BITS => D_BITS,
    MIN_DEPTH => MIN_DEPTH
  )
  port map(
    clk => clk,
    rst => rst,
    din => din,
    put => put,
    full => full,
    got => got,
    dout => dout,
    valid => valid
  );

-- Stimuli
process begin
  rst <= '1';
  wait for clk_period*3;
  rst <= '0';
  wait for clk_period;
  assert valid = '0' report "valid != 0!" severity error;
  assert full = '0' report "full != 0!" severity error;


  -- fill stack with data
  report "test: fill whole stack";
  for i in 0 to MIN_DEPTH-1 loop
    din <= std_logic_vector(to_unsigned(i, D_BITS));
    put <= '1';
    wait for clk_period;
  end loop;
  wait for clk_period;
  assert valid = '1' report "valid != 1!" severity error;
  assert full = '1' report "full != 1!" severity error;

  -- IDLE
  put <= '0';
  wait for clk_period*3;

  -- Test push to full stack
  report "test: push to full stack";
  put <= '1';
  din <= (others => '1');
  wait for clk_period;
  assert full = '1' report "full != 1" severity error;
  assert valid = '1' report "valid != 1" severity error;

  -- IDLE
  put <= '0';
  din <= (others => '0');
  wait for clk_period*3;

  -- TEST pop
  report "test: 1. pop";
  got <= '1';
  wait for clk_period;
  got <= '0';
  assert dout = std_logic_vector(to_unsigned(MIN_DEPTH-1,D_BITS)) report "pop doesnt work! dout != 0x1F; dout = " &integer'image(to_integer(unsigned(dout)));
  wait for clk_period;
  assert full = '0' report "full != 0" severity error;
  assert valid = '1' report "valid != 1" severity error;
  wait for clk_period*4;
  got <= '1';
  wait for clk_period;
  got <= '0';
  assert full = '0' report "full != 0" severity error;
  if(MIN_DEPTH <= 2) then
    assert valid = '0' report "valid != 0" severity error;
  else
    assert valid = '1' report "valid != 1" severity error;
  end if;
  assert dout = std_logic_vector(to_unsigned(MIN_DEPTH-2,D_BITS)) report "pop doesnt work! dout != 0x1E; dout = " &integer'image(to_integer(unsigned(dout)));

  -- Test push again
  report "test: 1. push";
  put <= '1';
  din <= std_logic_vector(to_unsigned(364,D_BITS));
  wait for clk_period;
  put <='0';
  wait for clk_period;
  put <= '1';
  assert full = '0' report "full != 0" severity error;
  assert valid = '1' report "valid != 1" severity error;
  din <= std_logic_vector(to_unsigned(363,D_BITS));
  wait for clk_period;
  put <='0';
  wait for clk_period;
  assert full = '1' report "full != 1" severity error;
  assert valid = '1' report "valid != 1" severity error;

  -- TEST pop
  report "test: 2. pop";
  wait for clk_period*4;
  got <= '1';
  wait for clk_period;
  got <= '0';
  assert dout = std_logic_vector(to_unsigned(363,D_BITS)) report "pop doesnt work! dout != 0xCD; dout = " &integer'image(to_integer(unsigned(dout)));
  wait for clk_period;
  assert full = '0' report "full != 0" severity error;
  assert valid = '1' report "valid != 1" severity error;
  wait for clk_period*3;
  got <= '1';
  wait for clk_period;
  got <= '0';
  assert full = '0' report "full != 0" severity error;
  if(MIN_DEPTH <= 2) then
    assert valid = '0' report "valid != 0" severity error;
  else
    assert valid = '1' report "valid != 1" severity error;
  end if;
  assert dout = std_logic_vector(to_unsigned(364,D_BITS)) report "pop doesnt work! dout != 0xAB; dout = " &integer'image(to_integer(unsigned(dout)));

  -- Test push again
  report "test: 2. push";
  put <= '1';
  din <= std_logic_vector(to_unsigned(MIN_DEPTH-2,D_BITS));
  wait for clk_period;
  put <= '1';
  assert full = '0' report "full != 0" severity error;
  assert valid = '1' report "valid != 1" severity error;
  din <= std_logic_vector(to_unsigned(MIN_DEPTH-1,D_BITS));
  wait for clk_period;
  put <='0';
  wait for clk_period;
  assert full = '1' report "full != 1" severity error;
  assert valid = '1' report "valid != 1" severity error;

  -- pop whole stack
  report "test: pop whole stack!";
  for j in MIN_DEPTH-1 downto 0 loop
    got <= '1';
    wait for clk_period;
    got <= '0';
  end loop;
  wait for clk_period;
  assert full = '0' report "full != 0!" severity error;
  assert valid = '0' report "valid != 0!" severity error;
  wait for clk_period;

  -- Test push and pop again
  report "test: 3. push/pop";
  put <= '1';
  din <= std_logic_vector(to_unsigned(MIN_DEPTH-2,D_BITS));
  wait for clk_period;
  put <= '0';
  wait for clk_period;
  assert full = '0' report "full != 0" severity error;
  assert valid = '1' report "valid != 1" severity error;
  wait for clk_period*4;
  got <= '1';
  wait for clk_period;
  got <= '0';
  assert dout = std_logic_vector(to_unsigned(MIN_DEPTH-2,D_BITS)) report "pop doesnt work! dout != MIN_DEPTH - 2; dout = " &integer'image(to_integer(unsigned(dout)));
  wait for clk_period;
  assert full = '0' report "full != 0" severity error;
  assert valid = '0' report "valid != 0" severity error;
  wait for clk_period;

  -- test push, push and pop parallel
  report "test: push and pop parallel";
  put <= '1';
  din <= std_logic_vector(to_unsigned(MIN_DEPTH-2,D_BITS));
  wait for clk_period;
  put <= '0';
  wait for clk_period;
  assert full = '0' report "full != 0" severity error;
  assert valid = '1' report "valid != 1" severity error;
  wait for clk_period;
  put <= '1';
  din <= std_logic_vector(to_unsigned(MIN_DEPTH-1,D_BITS));
  got <= '1';
  wait for clk_period;
  got <= '0';
  assert dout = std_logic_vector(to_unsigned(MIN_DEPTH-2,D_BITS)) report "pop doesnt work! dout != MIN_DEPTH - 2; dout = " &integer'image(to_integer(unsigned(dout)));
  wait for clk_period;
  assert full = '0' report "full != 0" severity error;
  assert valid = '1' report "valid != 1" severity error;


  -- finished
  wait for clk_period*5;
  report "TB finished!" severity note;
  done <= '1';
  wait;
end process;

end architecture;
