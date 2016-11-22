.. _NS:cache:

PoC.cache
=========

The namespace `PoC.cache` offers different cache implementations.

**Entities**

 * :ref:`IP:cache_cpu`: Cache with cache controller to be used within a CPU.

 * :ref:`IP:cache_mem`: Cache with :ref:`INT:PoC.Mem` interface on the "CPU" side.

 * :ref:`IP:cache_par`: Cache with parallel tag-unit and
   data memory (using infered memory).

 * :ref:`IP:cache_par2`: Cache with parallel tag-unit and
   data memory (using :ref:`IP:ocram_sp`).

 * :ref:`IP:cache_tagunit_par`: Tag-Unit with
   parallel tag comparison. Configurable as:

   * Full-associative cache,
   * Direct-mapped cache, or
   * Set-associative cache.

 * :ref:`IP:cache_tagunit_seq`: Tag-Unit with
   sequential tag comparison. Configurable as:

   * Full-associative cache,
   * Direct-mapped cache, or
   * Set-associative cache.



.. toctree::
   :hidden:

   cache_cpu <cache_cpu>
   cache_mem <cache_mem>
   cache_par <cache_par>
   cache_par2 <cache_par2>
   cache_replacement_policy <cache_replacement_policy>
   cache_tagunit_par <cache_tagunit_par>
   cache_tagunit_seq <cache_tagunit_seq>
