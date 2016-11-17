.. _NS:ocram:

PoC.mem.ocram
=============

The namespace ``PoC.mem.ocram`` offers different on-chip RAM abstractions.

**Package**

The package PoC.mem.ocram holds all component declarations for this namespace.

.. code-block:: VHDL

   library PoC;
   use     PoC.ocram.all;


**Entities**

 * :ref:`IP:ocram_sp` - An on-chip RAM with a single port interface.
 * :ref:`IP:ocram_sdp` - An on-chip RAM with a simple dual port interface.
 * :ref:`IP:ocram_tdp` - An on-chip RAM with a true dual port interface.

**Deprecated Entities**

 * :ref:`IP:ocram_esdp` - An on-chip RAM with an extended simple dual port interface.

.. toctree::
   :hidden:

   ocram_sp <ocram_sp>
   ocram_esdp <ocram_esdp>
   ocram_sdp <ocram_sdp>
   ocram_tdp <ocram_tdp>
