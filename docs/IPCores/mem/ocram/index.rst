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
 * :ref:`IP:ocram_sdp` - An on-chip RAM with a simple dual-port interface.
 * :ref:`IP:ocram_sdp_wf` - An on-chip RAM with a simple dual-port
   interface and write-first behavior.
 * :ref:`IP:ocram_tdp` - An on-chip RAM with a true dual-port interface.
 * :ref:`IP:ocram_tdp_wf` - An on-chip RAM with a true dual-port
   interface and write-first behavior.

**Simulation Helper**

 * :ref:`IP:ocram_tdp_sim` - Simulation model of on-chip RAM with a true dual port interface.

**Deprecated Entities**

 * :ref:`IP:ocram_esdp` - An on-chip RAM with an extended simple dual port interface.


.. toctree::
   :hidden:

   Package <ocram.pkg>

.. toctree::
   :hidden:

   ocram_sp <ocram_sp>
   ocram_sdp <ocram_sdp>
   ocram_sdp_wf <ocram_sdp_wf>
   ocram_tdp <ocram_tdp>
   ocram_tdp_wf <ocram_tdp_wf>

.. toctree::
   :hidden:

   ocram_tdp_sim <ocram_tdp_sim>

.. toctree::
   :hidden:

   ocram_esdp <ocram_esdp>
