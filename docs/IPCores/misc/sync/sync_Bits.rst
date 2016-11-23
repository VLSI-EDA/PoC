.. _IP:sync_Bits:

PoC.misc.sync.Bits
##################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/misc/sync/sync_Bits.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/misc/sync/sync_Bits_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <misc/sync/sync_Bits.vhdl>`
      * |gh-tb| :poctb:`Testbench <misc/sync/sync_Bits_tb.vhdl>`

This module synchronizes multiple flag bits into clock-domain ``Clock``.
The clock-domain boundary crossing is done by two synchronizer D-FFs. All
bits are independent from each other. If a known vendor like Altera or Xilinx
are recognized, a vendor specific implementation is chosen.

.. ATTENTION::
   Use this synchronizer only for long time stable signals (flags).

Constraints:
  General:
    Please add constraints for meta stability to all '_meta' signals and
    timing ignore constraints to all '_async' signals.

  Xilinx:
    In case of a Xilinx device, this module will instantiate the optimized
    module PoC.xil.sync.Bits. Please attend to the notes of sync_Bits.vhdl.

  Altera sdc file:
    TODO



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/misc/sync/sync_Bits.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 68-79

.. seealso::

   :doc:`PoC.misc.sync.Reset </IPCores/misc/sync/sync_Reset>`
     For a special 2 D-FF synchronizer for *reset*-signals.
   :doc:`PoC.misc.sync.Pulse </IPCores/misc/sync/sync_Pulse>`
     For a special 1+2 D-FF synchronizer for *pulse*-signals.
   :doc:`PoC.misc.sync.Strobe </IPCores/misc/sync/sync_Strobe>`
     For a synchronizer for *strobe*-signals.
   :doc:`PoC.misc.sync.Vector </IPCores/misc/sync/sync_Vector>`
     For a multiple bits capable synchronizer.



.. only:: latex

   Source file: :pocsrc:`misc/sync/sync_Bits.vhdl <misc/sync/sync_Bits.vhdl>`
