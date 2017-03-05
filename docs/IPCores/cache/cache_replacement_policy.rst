.. _IP:cache_replacement_policy:

PoC.cache.replacement_policy
############################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/cache/cache_replacement_policy.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/cache/cache_replacement_policy_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <cache/cache_replacement_policy.vhdl>`
      * |gh-tb| :poctb:`Testbench <cache/cache_replacement_policy_tb.vhdl>`


**Supported policies:**

+----------+-----------------------+-----------+
| Abbr.    | Policies              | supported |
+==========+=======================+===========+
| RR       | round robin           | not yet   |
+----------+-----------------------+-----------+
| RAND     | random                | not yet   |
+----------+-----------------------+-----------+
| CLOCK    | clock algorithm       | not yet   |
+----------+-----------------------+-----------+
| LRU      | least recently used   | YES       |
+----------+-----------------------+-----------+
| LFU      | least frequently used | not yet   |
+----------+-----------------------+-----------+

**Command thruth table:**

+-----------+-----------+-------------+---------+-----------------------------------------------------+
| TagAccess | ReadWrite | Invalidate  | Replace | Command                                             |
+===========+===========+=============+=========+=====================================================+
|  0        |           |             |    0    | None                                                |
+-----------+-----------+-------------+---------+-----------------------------------------------------+
|  1        |    0      |    0        |    0    | TagHit and reading a cache line                     |
+-----------+-----------+-------------+---------+-----------------------------------------------------+
|  1        |    1      |    0        |    0    | TagHit and writing a cache line                     |
+-----------+-----------+-------------+---------+-----------------------------------------------------+
|  1        |    0      |    1        |    0    | TagHit and invalidate a  cache line (while reading) |
+-----------+-----------+-------------+---------+-----------------------------------------------------+
|  1        |    1      |    1        |    0    | TagHit and invalidate a  cache line (while writing) |
+-----------+-----------+-------------+---------+-----------------------------------------------------+
|  0        |           |    0        |    1    | Replace cache line                                  |
+-----------+-----------+-------------+---------+-----------------------------------------------------+

In a set-associative cache, each cache-set has its own instance of this component.

The input ``HitWay`` specifies the accessed way in a fully-associative or
set-associative cache.

The output ``ReplaceWay`` identifies the way which will be replaced as next by
a replace command. In a set-associative cache, this is the way in a specific
cache set (see above).



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/cache/cache_replacement_policy.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 85-104



.. only:: latex

   Source file: :pocsrc:`cache/cache_replacement_policy.vhdl <cache/cache_replacement_policy.vhdl>`
