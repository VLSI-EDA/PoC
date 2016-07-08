
sync_Bits
#########

This module synchronizes multiple flag bits from clock-domain ``Clock1`` to
clock-domain ``Clock``. The clock-domain boundary crossing is done by two
synchronizer D-FFs. All bits are independent from each other. If a known
vendor like Altera or Xilinx are recognized, a vendor specific
implementation is choosen.

.. ATTENTION::
   Use this synchronizer only for long time stable signals (flags).

Constraints:
	General:
		Please add constraints for meta stability to all '_meta' signals and
		timing ignore constraints to all '_async' signals.

	Xilinx:
		In case of a Xilinx device, this module will instantiate the optimized
		module PoC.xil.SyncBits. Please attend to the notes of xil_SyncBits.vhdl.

	Altera sdc file:
		TODO



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/misc/sync/sync_Bits.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 67-78

Source file: `misc/sync/sync_Bits.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/misc/sync/sync_Bits.vhdl>`_

.. seealso::
 
   :doc:`PoC.misc.sync.Reset </PoC/misc/sync/sync_Reset>`
     For a special 2 D-FF synchronizer for *reset*-signals.
   :doc:`PoC.misc.sync.Strobe </PoC/misc/sync/sync_Strobe>`
     For a synchronizer for *strobe*-signals.
   :doc:`PoC.misc.sync.Vector </PoC/misc/sync/sync_Vector>`
     For a multiple bits capable synchronizer.

 
