library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

package datastructures is

component stack is
    generic(
    D_BITS  : positive := 8; -- Data Width
    MIN_DEPTH : positive := 16 -- Minimum Stack Depth
    );
    port(
    -- INPUTS
    clk, rst : in std_logic;

    -- Write Ports
    din : in std_logic_vector(D_BITS-1 downto 0); -- Data Input
    put : in std_logic; -- 0 -> pop, 1 -> push
    full : out std_logic;

    -- Read Ports
    got : in std_logic;
    dout : out std_logic_vector(D_BITS-1 downto 0);
    valid : out std_logic

    );
end component stack;

  component deque is
      generic(
      D_BITS  : positive := 8; -- Data Width
      MIN_DEPTH : positive := 16 -- Minimum Deque Depth
      );
      port(
      -- Shared Ports
      clk, rst : in std_logic;

      -- Port A
      dinA : in std_logic_vector(D_BITS-1 downto 0); -- DataA Input
      putA : in std_logic;
      gotA : in std_logic;
      doutA : out std_logic_vector(D_BITS-1 downto 0); -- DataA Output
      validA : out std_logic;
      fullA : out std_logic;

      -- Port B
      dinB : in std_logic_vector(D_BITS-1 downto 0); -- DataB Input
      putB: in std_logic;
      gotB : in std_logic;
      doutB : out std_logic_vector(D_BITS-1 downto 0);
      validB : out std_logic;
      fullB : out std_logic
      );
  end component deque;


end package;
