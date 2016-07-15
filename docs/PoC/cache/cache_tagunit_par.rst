
cache_tagunit_par
#################

All inputs are synchronous to the rising-edge of the clock `clock`.
Command truth table:
Request | ReadWrite | Invalidate	| Replace | Command
--------+-----------+-------------+---------+--------------------------------
	0			|		0				|		0					|		0			| None
	1			|		0				|		0					|		0			| Read cache line
	1			|		1				|		0					|		0			| Update cache line
	1			|		0				|		1					|		0			| Read cache line and discard it
	1			|		1				|		1					|		0			| Write cache line and discard it
	0			|		-				|		0					|		1			| Replace cache line.
--------+-----------+-------------+------------------------------------------
All commands use `Address` to lookup (request) or replace a cache line.
Each command is completed within one clock cycle.
Upon requests, the outputs `CacheMiss` and `CacheHit` indicate (high-active)
immediately (combinational) whether the `Address` is stored within the cache, or not.
But, the cache-line usage is updated at the rising-edge of the clock.
If hit, `LineIndex` specifies the cache line where to find the content.
The output `ReplaceLineIndex` indicates which cache line will be replaced as
next by a replace command. The output `OldAddress` specifies the old tag stored at this
index. The replace command will store the `NewAddress` and update the cache-line
usage at the rising-edge of the clock.
For a direct-mapped cache, the number of CACHE_LINES must be a power of 2.
For a set-associative cache, the expression (CACHE_LINES / ASSOCIATIVITY)
must be a power of 2.


.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/cache/cache_tagunit_par.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 69-93

Source file: `cache/cache_tagunit_par.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/cache/cache_tagunit_par.vhdl>`_


	 