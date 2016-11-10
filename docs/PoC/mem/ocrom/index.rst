
ocrom
=====

The namespace ``PoC.mem.ocrom`` offers different on-chip ROM abstractions.

**Package**

The package PoC.mem.ocrom holds all component declarations for this namespace.

.. code-block:: VHDL

   library PoC;
   use     PoC.ocrom.all;


**Entities**

 - :doc:`ocrom_sp <ocrom_sp>` is a on-chip RAM with a single port interface.
 - :doc:`ocrom_dp <ocrom_dp>` is a on-chip RAM with a dual port interface.


.. toctree::
   :hidden:

   ocrom_sp
   ocrom_dp
