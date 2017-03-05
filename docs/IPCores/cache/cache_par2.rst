.. _IP:cache_par2:

PoC.cache.par2
##############

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/cache/cache_par2.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/cache/cache_par2_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <cache/cache_par2.vhdl>`
      * |gh-tb| :poctb:`Testbench <cache/cache_par2_tb.vhdl>`

Cache with parallel tag-unit and data memory. For the data memory,
:ref:`IP:ocram_sp` is used.

Configuration
*************

+--------------------+----------------------------------------------------+
| Parameter          | Description                                        |
+====================+====================================================+
| REPLACEMENT_POLICY | Replacement policy. For supported policies see     |
|                    | PoC.cache_replacement_policy.                      |
+--------------------+----------------------------------------------------+
| CACHE_LINES        | Number of cache lines.                             |
+--------------------+----------------------------------------------------+
| ASSOCIATIVITY      | Associativity of the cache.                        |
+--------------------+----------------------------------------------------+
| ADDR_BITS          | Number of address bits. Each address identifies    |
|                    | exactly one cache line in memory.                  |
+--------------------+----------------------------------------------------+
| DATA_BITS          | Size of a cache line in bits.                      |
|                    | DATA_BITS must be divisible by 8.                  |
+--------------------+----------------------------------------------------+


Command truth table
*******************

+---------+-----------+-------------+---------+---------------------------------+
| Request | ReadWrite | Invalidate  | Replace | Command                         |
+=========+===========+=============+=========+=================================+
|  0      |    0      |    0        |    0    | None                            |
+---------+-----------+-------------+---------+---------------------------------+
|  1      |    0      |    0        |    0    | Read cache line                 |
+---------+-----------+-------------+---------+---------------------------------+
|  1      |    1      |    0        |    0    | Update cache line               |
+---------+-----------+-------------+---------+---------------------------------+
|  1      |    0      |    1        |    0    | Read cache line and discard it  |
+---------+-----------+-------------+---------+---------------------------------+
|  1      |    1      |    1        |    0    | Write cache line and discard it |
+---------+-----------+-------------+---------+---------------------------------+
|  0      |    0      |    0        |    1    | Read cache line before replace. |
+---------+-----------+-------------+---------+---------------------------------+
|  0      |    1      |    0        |    1    | Replace cache line.             |
+---------+-----------+-------------+---------+---------------------------------+


Operation
*********

All inputs are synchronous to the rising-edge of the clock `clock`.

All commands use ``Address`` to lookup (request) or replace a cache line.
``Address`` and ``OldAddress`` do not include the word/byte select part.
Each command is completed within one clock cycle, but outputs are delayed as
described below.

Upon requests, the outputs ``CacheMiss`` and ``CacheHit`` indicate (high-active)
whether the ``Address`` is stored within the cache, or not. Both outputs have a
latency of one clock cycle (pipelined) if ``HIT_MISS_REG`` is true, otherwise the
result is outputted immediately (combinational).

Upon writing a cache line, the new content is given by ``CacheLineIn``.
Only the bytes which are not masked, i.e. the corresponding bit in WriteMask
is '0', are actually written.

Upon reading a cache line, the current content is outputed on ``CacheLineOut``
with a latency of one clock cycle.

Replacing a cache line requires two steps, both with ``Replace = '1'``:

1. Read old contents of cache line by setting ``ReadWrite`` to '0'. The old
   content is outputed on ``CacheLineOut`` and the old tag on ``OldAddress``,
   both with a latency of one clock cycle.

2. Write new cache line by setting ``ReadWrite`` to '1'. The new content is
   given by ``CacheLineIn``. All bytes shall be written, i.e.
   ``WriteMask = 0``. The new cache line content will be outputed
   again on ``CacheLineOut`` in the next clock cycle (latency = 1).

.. WARNING::

   If the design is synthesized with Xilinx ISE / XST, then the synthesis
   option "Keep Hierarchy" must be set to SOFT or TRUE.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/cache/cache_par2.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 123-149



.. only:: latex

   Source file: :pocsrc:`cache/cache_par2.vhdl <cache/cache_par2.vhdl>`
