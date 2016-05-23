sync_Bits
^^^^^^^^^

This module synchronizes multiple flag bits from clock-domain *unknown* or
*async* to clock-domain ``Clock``. The clock-domain boundary crossing is
done by at least two synchronizer D-FFs. All bits are independent from each
other. If a known vendor like Altera or Xilinx is recognized, a vendor specific
implementation is choosen.

.. ATTENTION::
   Use this synchronizer only for long time stable signals (flag, status).

Entity Declaration:
~~~~~~~~~~~~~~~~~~~

.. literalinclude:: ../../../../src/misc/sync/sync_Bits.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 60-71


Timing Constraints:
~~~~~~~~~~~~~~~~~~~

Altera SDC file:
................
  
  In case of a Altera device, this module will instantiate an optimized module.
  Please attend to the notes of ``sync_Bits_Altera.vhdl``.

Lattice LDC file:
.................
  
  .. TODO::
     No documentation available.
	
Xilinx UCF / XDC files:
.......................
  
  In case of a Xilinx device, this module will instantiate an optimized module.
  Please attend to the notes of ``sync_Bits_Xilinx.vhdl``. Please add constraints
  for meta stability to all ``_meta`` signals and timing ignore constraints to all
  ``_async`` signals.


File List:
~~~~~~~~~~

+--------------+------------------------------------------------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------+
|              | master (stable)                                                                                            | release (testing)                                                                                           |
+==============+============================================================================================================+=============================================================================================================+
| Source files | `sync_Bits.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/misc/sync/sync_Bits.vhdl>`_               | `sync_Bits.vhdl <https://github.com/VLSI-EDA/PoC/blob/release/src/misc/sync/sync_Bits.vhdl>`_               |
+--------------+------------------------------------------------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------+
| Altera files | `sync_Bits_Altera.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/misc/sync/sync_Bits_Altera.vhdl>`_ | `sync_Bits_Altera.vhdl <https://github.com/VLSI-EDA/PoC/blob/release/src/misc/sync/sync_Bits_Altera.vhdl>`_ |
+--------------+------------------------------------------------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------+
| Xilinx files | `sync_Bits_Xilinx.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/misc/sync/sync_Bits_Xilinx.vhdl>`_ | `sync_Bits_Xilinx.vhdl <https://github.com/VLSI-EDA/PoC/blob/release/src/misc/sync/sync_Bits_Xilinx.vhdl>`_ |
+--------------+------------------------------------------------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------+

.. seealso::
   
   :doc:`PoC.misc.sync.Reset </PoC/misc/sync/sync_Reset>`
     For a special 2 D-FF synchronizer for *reset*-signals.
   :doc:`PoC.misc.sync.Strobe </PoC/misc/sync/sync_Strobe>`
     For a synchronizer for *strobe*-signals.
   :doc:`PoC.misc.sync.Vector </PoC/misc/sync/sync_Vector>`
	   For a multiple bits capable synchronizer.