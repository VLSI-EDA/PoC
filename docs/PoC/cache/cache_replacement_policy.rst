
cache_replacement_policy
########################


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

Source file: `cache/cache_replacement_policy.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/cache/cache_replacement_policy.vhdl>`_



