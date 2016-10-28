
sort_lru_cache
##############

This is an optimized implementation of ``sort_lru_list`` to be used for caches.
Only keys are stored within this list, and these keys are the index of the
cache lines. The list initially contains all indizes from 0 to ELEMENTS-1.
The least-recently used index ``KeyOut`` is always valid.

The first outputed least-recently used index will be ELEMENTS-1.

The inputs ``Insert``, ``Free``, ``KeyIn``, and ``Reset`` are synchronous to the
rising-edge of the clock ``clock``. All control signals are high-active.

Supported operations:
 * **Insert:** Mark index ``KeyIn`` as recently used, e.g., when a cache-line
   was accessed.
 * **Free:** Mark index ``KeyIn`` as least-recently used. Apply this operation,
   when a cache-line gets invalidated.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/sort/sort_lru_cache.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 56-70

Source file: `sort/sort_lru_cache.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/sort/sort_lru_cache.vhdl>`_



