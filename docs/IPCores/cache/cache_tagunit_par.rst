.. _IP:cache_tagunit_par:

PoC.cache.tagunit_par
#####################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/cache/cache_tagunit_par.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/cache/cache_tagunit_par_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <cache/cache_tagunit_par.vhdl>`
      * |gh-tb| :poctb:`Testbench <cache/cache_tagunit_par_tb.vhdl>`

Tag-unit with fully-parallel compare of tag.

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
| ADDRESS_BITS       | Number of address bits. Each address identifies    |
|                    | exactly one cache line in memory.                  |
+--------------------+----------------------------------------------------+


Command truth table
*******************

+---------+-----------+-------------+---------+----------------------------------+
| Request | ReadWrite | Invalidate  | Replace | Command                          |
+=========+===========+=============+=========+==================================+
|   0     |    0      |    0        |    0    | None                             |
+---------+-----------+-------------+---------+----------------------------------+
|   1     |    0      |    0        |    0    | Read cache line                  |
+---------+-----------+-------------+---------+----------------------------------+
|   1     |    1      |    0        |    0    | Update cache line                |
+---------+-----------+-------------+---------+----------------------------------+
|   1     |    0      |    1        |    0    | Read cache line and discard it   |
+---------+-----------+-------------+---------+----------------------------------+
|   1     |    1      |    1        |    0    | Write cache line and discard it  |
+---------+-----------+-------------+---------+----------------------------------+
|   0     |           |    0        |    1    | Replace cache line.              |
+---------+-----------+-------------+---------+----------------------------------+


Operation
*********

All inputs are synchronous to the rising-edge of the clock `clock`.

All commands use ``Address`` to lookup (request) or replace a cache line.
Each command is completed within one clock cycle.

Upon requests, the outputs ``CacheMiss`` and ``CacheHit`` indicate (high-active)
immediately (combinational) whether the ``Address`` is stored within the cache, or not.
But, the cache-line usage is updated at the rising-edge of the clock.
If hit, ``LineIndex`` specifies the cache line where to find the content.

The output ``ReplaceLineIndex`` indicates which cache line will be replaced as
next by a replace command. The output ``OldAddress`` specifies the old tag stored at this
index. The replace command will store the ``Address`` and update the cache-line
usage at the rising-edge of the clock.

For a direct-mapped cache, the number of ``CACHE_LINES`` must be a power of 2.
For a set-associative cache, the expression ``CACHE_LINES / ASSOCIATIVITY``
must be a power of 2.

.. NOTE::
   The port ``NewAddress`` has been removed. Use ``Address`` instead as
   described above.

   If ``Address`` is fed from a register and an Altera FPGA is used, then
   Quartus Map converts the tag memory from a memory with asynchronous read to a
   memory with synchronous read by adding a pass-through logic. Quartus Map
   reports warning 276020 which is intended.

.. WARNING::

   If the design is synthesized with Xilinx ISE / XST, then the synthesis
   option "Keep Hierarchy" must be set to SOFT or TRUE.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/cache/cache_tagunit_par.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 114-137



.. only:: latex

   Source file: :pocsrc:`cache/cache_tagunit_par.vhdl <cache/cache_tagunit_par.vhdl>`
