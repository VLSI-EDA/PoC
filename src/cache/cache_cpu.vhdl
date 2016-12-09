-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:         Martin Zabel
--
-- Entity:          Cache with cache controller to be used within a CPU
--
-- Description:
-- -------------------------------------
-- This unit provides a cache (:ref:`IP:cache_par2`) together
-- with a cache controller which reads / writes cache lines from / to memory.
-- The memory is accessed using a :ref:`INT:PoC.Mem` interfaces, the related
-- ports and parameters are prefixed with ``mem_``.
--
-- The CPU side (prefix ``cpu_``) has a modified PoC.Mem interface, so that
-- this unit can be easily integrated into processor pipelines. For example,
-- let's have a pipeline where a load/store instruction is executed in 3
-- stages (after fetching, decoding, ...):
--
-- 1. Execute (EX) for address calculation,
-- 2. Load/Store 1 (LS1) for the cache access,
-- 3. Load/Store 2 (LS2) where the cache returns the read data.
--
-- The read data is always returned one cycle after the cache access completes,
-- so there is conceptually a pipeline register within this unit. The stage LS2
-- can be merged with a write-back stage if the clock period allows so.
--
-- The stage LS1 and thus EX and LS2 must stall, until the cache access is
-- completed, i.e., the EX/LS1 pipeline register must hold the cache request
-- until it is acknowledged by the cache. This is signaled by ``cpu_got`` as
-- described in Section Operation below. The pipeline moves forward (is
-- enabled) when::
--
--   pipeline_enable <= (not cpu_req) or cpu_got;
--
-- If the pipeline can stall due to other reasons, care must be taken to not
-- unintentionally executing the cache access twice or missing the read data.
--
-- Of course, the EX/LS1 pipeline register can be omitted and the CPU side
-- directly fed by the address caculator. But be aware of the high setup time
-- of this unit and high propate time for ``cpu_got``.
--
-- This unit supports only one outstanding CPU request. More outstanding
-- requests are provided by :ref:`IP:cache_mem`.
--
--
-- Configuration
-- *************
--
-- +--------------------+-----------------------------------------------------+
-- | Parameter          | Description                                         |
-- +====================+=====================================================+
-- | REPLACEMENT_POLICY | Replacement policy of embedded cache. For supported |
-- |                    | values see PoC.cache_replacement_policy.            |
-- +--------------------+-----------------------------------------------------+
-- | CACHE_LINES        | Number of cache lines.                              |
-- +--------------------+-----------------------------------------------------+
-- | ASSOCIATIVITY      | Associativity of embedded cache.                    |
-- +--------------------+-----------------------------------------------------+
-- | CPU_ADDR_BITS      | Number of address bits on the CPU side. Each address|
-- |                    | identifies one memory word as seen from the CPU.    |
-- |                    | Calculated from other parameters as described below.|
-- +--------------------+-----------------------------------------------------+
-- | CPU_DATA_BITS      | Width of the data bus (in bits) on the CPU side.    |
-- |                    | CPU_DATA_BITS must be divisible by 8.               |
-- +--------------------+-----------------------------------------------------+
-- | MEM_ADDR_BITS      | Number of address bits on the memory side. Each     |
-- |                    | address identifies one word in the memory.          |
-- +--------------------+-----------------------------------------------------+
-- | MEM_DATA_BITS      | Width of a memory word and of a cache line in bits. |
-- |                    | MEM_DATA_BITS must be divisible by CPU_DATA_BITS.   |
-- +--------------------+-----------------------------------------------------+
--
-- If the CPU data-bus width is smaller than the memory data-bus width, then
-- the CPU needs additional address bits to identify one CPU data word inside a
-- memory word. Thus, the CPU address-bus width is calculated from::
--
--   CPU_ADDR_BITS=log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS
--
-- The write policy is: write-through, no-write-allocate.
--
--
-- Operation
-- *********
--
-- Alignment of Cache / Memory Accesses
-- ++++++++++++++++++++++++++++++++++++
--
-- Memory accesses are always aligned to a word boundary. Each memory word
-- (and each cache line) consists of MEM_DATA_BITS bits.
-- For example if MEM_DATA_BITS=128:
--
-- * memory address 0 selects the bits   0..127 in memory,
-- * memory address 1 selects the bits 128..256 in memory, and so on.
--
-- Cache accesses are always aligned to a CPU word boundary. Each CPU word
-- consists of CPU_DATA_BITS bits. For example if CPU_DATA_BITS=32:
--
-- * CPU address 0 selects the bits   0.. 31 in memory word 0,
-- * CPU address 1 selects the bits  32.. 63 in memory word 0,
-- * CPU address 2 selects the bits  64.. 95 in memory word 0,
-- * CPU address 3 selects the bits  96..127 in memory word 0,
-- * CPU address 4 selects the bits   0.. 31 in memory word 1,
-- * CPU address 5 selects the bits  32.. 63 in memory word 1, and so on.
--
--
-- Shared and Memory Side Interface
-- ++++++++++++++++++++++++++++++++
--
-- A synchronous reset must be applied even on a FPGA.
--
-- The memory side interface is documented in detail :ref:`here <INT:PoC.Mem>`.
--
--
-- CPU Side Interface
-- ++++++++++++++++++
--
-- The CPU (pipeline stage LS1, see above) issues a request by setting
-- ``cpu_req``, ``cpu_write``, ``cpu_addr``, ``cpu_wdata`` and ``cpu_wmask`` as
-- in the :ref:`INT:PoC.Mem` interface. The cache acknowledges the request by
-- setting ``cpu_got`` to '1'. If the request is not acknowledged (``cpu_got =
-- '0'``) in the current clock cycle, then the request must be repeated in the
-- following clock cycle(s) until it is acknowledged, i.e., the pipeline must
-- stall.
--
-- A cache access is completed when it is acknowledged. A new request can be
-- issued in the following clock cycle.
--
-- Of course, ``cpu_got`` may be asserted in the same clock cycle where the
-- request was issued if a read hit occurs. This allows a throughput of one
-- (read) request per clock cycle, but the drawback is, that ``cpu_got`` has a
-- high propagation delay. Thus, this output should only control a simple
-- pipeline enable logic.
--
-- When ``cpu_got`` is asserted for a read access, then the read data will be
-- available in the following clock cycle.
--
-- Due to the write-through policy, a write will always take several clock
-- cycles and acknowledged when the data has been issued to the memory.
--
-- .. WARNING::
--
--    If the design is synthesized with Xilinx ISE / XST, then the synthesis
--    option "Keep Hierarchy" must be set to SOFT or TRUE.
--
-- SeeAlso:
--   :ref:`IP:cache_mem`
--
-- License:
-- =============================================================================
-- Copyright 2016-2016 Technische Universitaet Dresden - Germany
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library poc;
use poc.utils.all;

entity cache_cpu is
	generic (
		REPLACEMENT_POLICY : string		:= "LRU";
		CACHE_LINES        : positive;
		ASSOCIATIVITY      : positive;
		CPU_DATA_BITS      : positive;
		MEM_ADDR_BITS      : positive;
		MEM_DATA_BITS      : positive
	);
	port (
    clk : in std_logic; -- clock
    rst : in std_logic; -- reset

    -- "CPU" side
    cpu_req   : in  std_logic;
    cpu_write : in  std_logic;
    cpu_addr  : in  unsigned(log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS-1 downto 0);
    cpu_wdata : in  std_logic_vector(CPU_DATA_BITS-1 downto 0);
    cpu_wmask : in  std_logic_vector(CPU_DATA_BITS/8-1 downto 0);
    cpu_got   : out std_logic;
    cpu_rdata : out std_logic_vector(CPU_DATA_BITS-1 downto 0);

		-- Memory side
		mem_req		: out std_logic;
		mem_write : out std_logic;
		mem_addr	: out unsigned(MEM_ADDR_BITS-1 downto 0);
		mem_wdata : out std_logic_vector(MEM_DATA_BITS-1 downto 0);
		mem_wmask : out std_logic_vector(MEM_DATA_BITS/8-1 downto 0);
		mem_rdy		: in	std_logic;
		mem_rstb	: in	std_logic;
		mem_rdata : in	std_logic_vector(MEM_DATA_BITS-1 downto 0)
    );
end entity;

architecture rtl of cache_cpu is
	-- Ratio 1:n between CPU data bus and cache-line size (memory data bus)
	constant RATIO : positive := MEM_DATA_BITS/CPU_DATA_BITS;

	-- Number of address bits identifying the CPU data word within a cache line (memory word)
	constant LOWER_ADDR_BITS : natural := log2ceil(RATIO);

	-- Widened CPU data path
	signal cpu_wdata_wide : std_logic_vector(MEM_DATA_BITS-1 downto 0);
	signal cpu_wmask_wide : std_logic_vector(MEM_DATA_BITS/8-1 downto 0);

	-- Interface to Cache instance.
	signal cache_Request		: std_logic;
	signal cache_ReadWrite	: std_logic;
	signal cache_Writemask	: std_logic_vector(MEM_DATA_BITS/8-1 downto 0);
	signal cache_Invalidate : std_logic;
	signal cache_Replace		: std_logic;
	signal cache_Address		: std_logic_vector(MEM_ADDR_BITS-1 downto 0);
	signal cache_LineIn			: std_logic_vector(MEM_DATA_BITS-1 downto 0);
	signal cache_LineOut		: std_logic_vector(MEM_DATA_BITS-1 downto 0);
	signal cache_Hit				: std_logic;
	signal cache_Miss				: std_logic;

  -- FSM and other state registers
  type T_FSM is (READY, ACCESS_MEM, READING_MEM, UNKNOWN);
  signal fsm_cs : T_FSM -- current state
		-- synthesis translate_off
		:= UNKNOWN
		-- synthesis translate_on
		;
  signal fsm_ns : T_FSM;-- next state

begin  -- architecture rtl

  cache_inst: entity work.cache_par2
    generic map (
			REPLACEMENT_POLICY => REPLACEMENT_POLICY,
			CACHE_LINES        => CACHE_LINES,
			ASSOCIATIVITY      => ASSOCIATIVITY,
			ADDR_BITS          => MEM_ADDR_BITS,
			DATA_BITS          => MEM_DATA_BITS,
			HIT_MISS_REG       => false)
    port map (
			Clock        => clk,
			Reset        => rst,
			Request      => cache_Request,
			ReadWrite    => cache_ReadWrite,
			WriteMask    => cache_WriteMask,
			Invalidate   => cache_Invalidate,
			Replace      => cache_Replace,
			Address      => cache_Address,
			CacheLineIn  => cache_LineIn,
			CacheLineOut => cache_LineOut,
			CacheHit     => cache_Hit,
			CacheMiss    => cache_Miss,
			OldAddress   => open);

  -- Address and Data path
  -- ===========================================================================
	gEqual: if RATIO = 1 generate -- Cache line size equals CPU data bus size
		cpu_wdata_wide <= cpu_wdata;
		cpu_wmask_wide <= cpu_wmask;
		cpu_rdata      <= cache_LineOut;
	end generate gEqual;

	gWider: if RATIO > 1 generate -- Cache line size is greater than CPU data bus size
		signal lower_addr   : unsigned(LOWER_ADDR_BITS-1 downto 0);
		signal lower_addr_r : unsigned(LOWER_ADDR_BITS-1 downto 0);
		type T_ARRAY is array(0 to RATIO-1) of std_logic_vector(CPU_DATA_BITS-1 downto 0);
		signal cache_LineOut_array : T_ARRAY;
	begin
		-- CPU Request Data Path
		lower_addr <= cpu_addr(LOWER_ADDR_BITS-1 downto 0);

		l0: for i in 0 to RATIO-1 generate
			cpu_wdata_wide((i+1)*CPU_DATA_BITS-1 downto i*CPU_DATA_BITS) <= cpu_wdata;

			cpu_wmask_wide((i+1)*CPU_DATA_BITS/8-1 downto i*CPU_DATA_BITS/8) <=
				-- synthesis translate_off
				(others => 'X') when is_x(lower_addr) else
				-- synthesis translate_on
				cpu_wmask when to_integer(lower_addr) = i else
				(others => '1');
		end generate l0;

		-- CPU Reply Data Path
		lower_addr_r <= lower_addr when rising_edge(clk); -- pipeline register

		l1: for i in 0 to RATIO-1 generate
			cache_LineOut_array(i) <= cache_LineOut((i+1)*CPU_DATA_BITS-1 downto i*CPU_DATA_BITS);
		end generate l1;

		cpu_rdata <=
			-- synthesis translate_off
			(others => 'X') when is_x(lower_addr_r) else
			-- synthesis translate_on
			cache_LineOut_array(to_integer(lower_addr_r));
	end generate gWider;

	-- Cache Request Data Path
	cache_Address   <= std_logic_vector(cpu_addr(cpu_addr'left downto LOWER_ADDR_BITS));
	cache_LineIn    <= mem_rdata       when fsm_cs = READING_MEM else cpu_wdata_wide;
	cache_WriteMask <= (others => '0') when fsm_cs = READING_MEM else cpu_wmask_wide;

	-- These outputs can be fed from buffer registers, but this is not
	-- neccessary because the cpu_* signals will typically be connected to a
	-- pipeline register. And even if this pipeline register is omitted, then the
	-- cache tag comparison will dominate the critical path.
	mem_write <= cpu_write;
	mem_addr  <= cpu_addr(cpu_addr'left downto LOWER_ADDR_BITS);
	mem_wdata <= cpu_wdata_wide;
	mem_wmask <= cpu_wmask_wide;

	-- FSM
	-- ===========================================================================
	process(fsm_cs, cpu_req, cpu_write, cache_Hit, cache_Miss, mem_rdy, mem_rstb)
	begin
		-- Update state registers
		fsm_ns <= fsm_cs;

		-- Control signals for cache access
		cache_Request		 <= '0';
		cache_ReadWrite	 <= '-';
		cache_Invalidate <= '-';
		cache_Replace		 <= '0';

		-- Control / status signals for CPU and MEM side
		cpu_got <= '0';
		mem_req <= '0';

		case fsm_cs is
			when READY =>
				-- Ready for a new cache access.
				-- -----------------------------
				cache_Request		 <= to_x01(cpu_req);
				cache_ReadWrite	 <= to_x01(cpu_write); -- doesn't care if no request
				cache_Invalidate <= '0';

				case ((cache_Hit and cpu_write) or cache_Miss) is
					when '1' =>	-- write successfull but write-through, or cache miss
						fsm_ns  <= ACCESS_MEM;
					when '0' => -- read successfull, or no request
						cpu_got <= to_x01(cpu_req);
					when others => -- invalid input
						fsm_ns  <= UNKNOWN;
						cpu_got <= 'X';
				end case;


			when ACCESS_MEM =>
				-- Access memory.
				-- --------------
				mem_req <= '1';
				case to_x01(mem_rdy) is
					when '1' => -- access granted
						case to_x01(cpu_write) is
							when '1'    => fsm_ns <= READY;   cpu_got <= '1'; -- write
							when '0'    => fsm_ns <= READING_MEM; -- read
							when others => fsm_ns <= UNKNOWN; cpu_got <= 'X'; -- invalid input
						end case;

					when '0' =>	null; -- still waiting
					when others => fsm_ns <= UNKNOWN; -- invalid input
				end case;


      when READING_MEM =>
        -- Wait for incoming read data and write it to cache.
				-- --------------------------------------------------
				cache_ReadWrite <= '1';

				case to_x01(mem_rstb) is
					when '1' => -- read data available
						fsm_ns        <= READY;
						cpu_got       <= '1'; -- cache access is complete now
						cache_Replace <= '1'; -- replace cache line
						-- The new data will be available on cache_LineOut in the following
						-- clock cycle.

					when '0' => null;-- still waiting
					when others => -- invalid input
						fsm_ns        <= UNKNOWN;
						cpu_got       <= 'X';
						cache_Replace <= 'X';
				end case;


			when UNKNOWN =>
				-- Catches invalid state transitions.
				-- ----------------------------------
				fsm_ns           <= UNKNOWN;
				cpu_got          <= 'X';
				cache_Request    <= 'X';
				cache_ReadWrite	 <= 'X';
				cache_Invalidate <= 'X';
				cache_Replace    <= 'X';
		end case;
	end process;

	process(clk)
	begin
		if rising_edge(clk) then
			case to_x01(rst) is
				when '1' =>
					fsm_cs <= READY;
				when '0' =>
					fsm_cs <= fsm_ns;
				when others =>
					fsm_cs <= UNKNOWN;
			end case;
		end if;
	end process;

end architecture rtl;
