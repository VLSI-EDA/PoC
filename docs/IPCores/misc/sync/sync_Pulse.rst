
sync_Pulse
##########

This module synchronizes multiple pulsed bits into the clock-domain ``Clock``.
The clock-domain boundary crossing is done by two synchronizer D-FFs. All bits
are independent from each other. If a known vendor like Altera or Xilinx are
recognized, a vendor specific implementation is chosen.

.. ATTENTION::
   Use this synchronizer for very short signals (pulse).

Constraints:
  General:
    Please add constraints for meta stability to all '_meta' signals and
    timing ignore constraints to all '_async' signals.

  Xilinx:
    In case of a Xilinx device, this module will instantiate the optimized
    module PoC.xil.sync.Pulse. Please attend to the notes of sync_Bits.vhdl.

  Altera sdc file:
    TODO



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/misc/sync/sync_Pulse.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 68-78

Source file: `misc/sync/sync_Pulse.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/misc/sync/sync_Pulse.vhdl>`_

.. seealso::

   :doc:`PoC.misc.sync.Bits </PoC/misc/sync/sync_Bits>`
     For a common 2 D-FF synchronizer for *flag*-signals.
   :doc:`PoC.misc.sync.Reset </PoC/misc/sync/sync_Reset>`
     For a special 2 D-FF synchronizer for *reset*-signals.
   :doc:`PoC.misc.sync.Strobe </PoC/misc/sync/sync_Strobe>`
     For a synchronizer for *strobe*-signals.
   :doc:`PoC.misc.sync.Vector </PoC/misc/sync/sync_Vector>`
     For a multiple bits capable synchronizer.



