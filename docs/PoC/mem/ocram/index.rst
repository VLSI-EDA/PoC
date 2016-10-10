
ocram
=====

These are On-Chip RAM (OCRAM) entities...

**Package**

The package PoC.mem.ocram holds all component declarations for this namespace.

.. code-block:: VHDL

   library PoC;
   use     PoC.ocram.all;


**Entities**

 * :doc:`PoC.mem.ocram.sp <ocram_sp>` - An on-chip RAM with a single port interface.
 * :doc:`PoC.mem.ocram.sdp <ocram_sdp>` - An on-chip RAM with a simple dual port interface.
 * :doc:`PoC.mem.ocram.esdp <ocram_esdp>` - An on-chip RAM with an extended simple dual port interface.
 * :doc:`PoC.mem.ocram.tdp <ocram_tdp>` - An on-chip RAM with a true dual port interface.

.. toctree::
   :hidden:

   ocram_sp
   ocram_esdp
   ocram_sdp
   ocram_tdp
