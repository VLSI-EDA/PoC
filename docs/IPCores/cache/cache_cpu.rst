.. _IP:cache_cpu:

PoC.cache.cpu
#############

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/cache/cache_cpu.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/cache/cache_cpu_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <cache/cache_cpu.vhdl>`
      * |gh-tb| :poctb:`Testbench <cache/cache_cpu_tb.vhdl>`

This unit provides a cache (:ref:`IP:cache_par2`) together
with a cache controller which reads / writes cache lines from / to memory.
The memory is accessed using a :ref:`INT:PoC.Mem` interfaces, the related
ports and parameters are prefixed with ``mem_``.

The CPU side (prefix ``cpu_``) has a modified PoC.Mem interface, so that
this unit can be easily integrated into processor pipelines. For example,
let's have a pipeline where a load/store instruction is executed in 3
stages (after fetching, decoding, ...):

1. Execute (EX) for address calculation,
2. Load/Store 1 (LS1) for the cache access,
3. Load/Store 2 (LS2) where the cache returns the read data.

The read data is always returned one cycle after the cache access completes,
so there is conceptually a pipeline register within this unit. The stage LS2
can be merged with a write-back stage if the clock period allows so.

The stage LS1 and thus EX and LS2 must stall, until the cache access is
completed, i.e., the EX/LS1 pipeline register must hold the cache request
until it is acknowledged by the cache. This is signaled by ``cpu_got`` as
described in Section Operation below. The pipeline moves forward (is
enabled) when::

  pipeline_enable <= (not cpu_req) or cpu_got;

If the pipeline can stall due to other reasons, care must be taken to not
unintentionally executing the cache access twice or missing the read data.

Of course, the EX/LS1 pipeline register can be omitted and the CPU side
directly fed by the address caculator. But be aware of the high setup time
of this unit and high propate time for ``cpu_got``.

This unit supports only one outstanding CPU request. More outstanding
requests are provided by :ref:`IP:cache_mem`.


Configuration
*************

+--------------------+-----------------------------------------------------+
| Parameter          | Description                                         |
+====================+=====================================================+
| REPLACEMENT_POLICY | Replacement policy of embedded cache. For supported |
|                    | values see PoC.cache_replacement_policy.            |
+--------------------+-----------------------------------------------------+
| CACHE_LINES        | Number of cache lines.                              |
+--------------------+-----------------------------------------------------+
| ASSOCIATIVITY      | Associativity of embedded cache.                    |
+--------------------+-----------------------------------------------------+
| CPU_ADDR_BITS      | Number of address bits on the CPU side. Each address|
|                    | identifies one memory word as seen from the CPU.    |
|                    | Calculated from other parameters as described below.|
+--------------------+-----------------------------------------------------+
| CPU_DATA_BITS      | Width of the data bus (in bits) on the CPU side.    |
|                    | CPU_DATA_BITS must be divisible by 8.               |
+--------------------+-----------------------------------------------------+
| MEM_ADDR_BITS      | Number of address bits on the memory side. Each     |
|                    | address identifies one word in the memory.          |
+--------------------+-----------------------------------------------------+
| MEM_DATA_BITS      | Width of a memory word and of a cache line in bits. |
|                    | MEM_DATA_BITS must be divisible by CPU_DATA_BITS.   |
+--------------------+-----------------------------------------------------+

If the CPU data-bus width is smaller than the memory data-bus width, then
the CPU needs additional address bits to identify one CPU data word inside a
memory word. Thus, the CPU address-bus width is calculated from::

  CPU_ADDR_BITS=log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS

The write policy is: write-through, no-write-allocate.


Operation
*********

Alignment of Cache / Memory Accesses
++++++++++++++++++++++++++++++++++++

Memory accesses are always aligned to a word boundary. Each memory word
(and each cache line) consists of MEM_DATA_BITS bits.
For example if MEM_DATA_BITS=128:

* memory address 0 selects the bits   0..127 in memory,
* memory address 1 selects the bits 128..256 in memory, and so on.

Cache accesses are always aligned to a CPU word boundary. Each CPU word
consists of CPU_DATA_BITS bits. For example if CPU_DATA_BITS=32:

* CPU address 0 selects the bits   0.. 31 in memory word 0,
* CPU address 1 selects the bits  32.. 63 in memory word 0,
* CPU address 2 selects the bits  64.. 95 in memory word 0,
* CPU address 3 selects the bits  96..127 in memory word 0,
* CPU address 4 selects the bits   0.. 31 in memory word 1,
* CPU address 5 selects the bits  32.. 63 in memory word 1, and so on.


Shared and Memory Side Interface
++++++++++++++++++++++++++++++++

A synchronous reset must be applied even on a FPGA.

The memory side interface is documented in detail :ref:`here <INT:PoC.Mem>`.


CPU Side Interface
++++++++++++++++++

The CPU (pipeline stage LS1, see above) issues a request by setting
``cpu_req``, ``cpu_write``, ``cpu_addr``, ``cpu_wdata`` and ``cpu_wmask`` as
in the :ref:`INT:PoC.Mem` interface. The cache acknowledges the request by
setting ``cpu_got`` to '1'. If the request is not acknowledged (``cpu_got =
'0'``) in the current clock cycle, then the request must be repeated in the
following clock cycle(s) until it is acknowledged, i.e., the pipeline must
stall.

A cache access is completed when it is acknowledged. A new request can be
issued in the following clock cycle.

Of course, ``cpu_got`` may be asserted in the same clock cycle where the
request was issued if a read hit occurs. This allows a throughput of one
(read) request per clock cycle, but the drawback is, that ``cpu_got`` has a
high propagation delay. Thus, this output should only control a simple
pipeline enable logic.

When ``cpu_got`` is asserted for a read access, then the read data will be
available in the following clock cycle.

Due to the write-through policy, a write will always take several clock
cycles and acknowledged when the data has been issued to the memory.

.. WARNING::

   If the design is synthesized with Xilinx ISE / XST, then the synthesis
   option "Keep Hierarchy" must be set to SOFT or TRUE.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/cache/cache_cpu.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 175-207

.. seealso::

     :ref:`IP:cache_mem`



.. only:: latex

   Source file: :pocsrc:`cache/cache_cpu.vhdl <cache/cache_cpu.vhdl>`
