.. _IP:cache_mem:

PoC.cache.mem
#############

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/cache/cache_mem.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/cache/cache_mem_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <cache/cache_mem.vhdl>`
      * |gh-tb| :poctb:`Testbench <cache/cache_mem_tb.vhdl>`

This unit provides a cache (:ref:`IP:cache_par2`) together
with a cache controller which reads / writes cache lines from / to memory.
It has two :ref:`INT:PoC.Mem` interfaces:

* one for the "CPU" side  (ports with prefix ``cpu_``), and
* one for the memory side (ports with prefix ``mem_``).

Thus, this unit can be placed into an already available memory path between
the CPU and the memory (controller). If you want to plugin a cache into a
CPU pipeline, see :ref:`IP:cache_cpu`.


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
| OUTSTANDING_REQ    | Number of oustanding requests, see notes below.     |
+--------------------+-----------------------------------------------------+

If the CPU data-bus width is smaller than the memory data-bus width, then
the CPU needs additional address bits to identify one CPU data word inside a
memory word. Thus, the CPU address-bus width is calculated from::

  CPU_ADDR_BITS=log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS

The write policy is: write-through, no-write-allocate.

The maximum throughput is one request per clock cycle, except for
``OUSTANDING_REQ = 1``.

If ``OUTSTANDING_REQ`` is:

* 1: then 1 request is buffered by a single register. To give a short
  critical path (clock-to-output delay) for ``cpu_rdy``, the throughput is
  degraded to one request per 2 clock cycles at maximum.

* 2: then 2 requests are buffered by :ref:`IP:fifo_glue`. This setting has
  the lowest area requirements without degrading the performance.

* >2: then the requests are buffered by :ref:`IP:fifo_cc_got`. The number of
  outstanding requests is rounded up to the next suitable value. This setting
  is useful in applications with out-of-order execution (of other
  operations). The CPU requests to the cache are always processed in-order.


Operation
*********

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

A synchronous reset must be applied even on a FPGA.

The interface is documented in detail :ref:`here <INT:PoC.Mem>`.

.. WARNING::

   If the design is synthesized with Xilinx ISE / XST, then the synthesis
   option "Keep Hierarchy" must be set to SOFT or TRUE.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/cache/cache_mem.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 135-169

.. seealso::

     :ref:`IP:cache_cpu`



.. only:: latex

   Source file: :pocsrc:`cache/cache_mem.vhdl <cache/cache_mem.vhdl>`
