.. _IP:sync_Reset:

PoC.misc.sync.Reset
###################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/misc/sync/sync_Reset.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/misc/sync/sync_Reset_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <misc/sync/sync_Reset.vhdl>`
      * |gh-tb| :poctb:`Testbench <misc/sync/sync_Reset_tb.vhdl>`

This module synchronizes an asynchronous reset signal to the clock
``Clock``. The ``Input`` can be asserted and de-asserted at any time.
The ``Output`` is asserted asynchronously and de-asserted synchronously
to the clock.

.. ATTENTION::
   Use this synchronizer only to asynchronously reset your design.
   The 'Output' should be feed by global buffer to the destination FFs, so
   that, it reaches their reset inputs within one clock cycle.

Constraints:
  General:
    Please add constraints for meta stability to all '_meta' signals and
    timing ignore constraints to all '_async' signals.

  Xilinx:
    In case of a Xilinx device, this module will instantiate the optimized
    module xil_SyncReset. Please attend to the notes of xil_SyncReset.

  Altera sdc file:
    TODO



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/misc/sync/sync_Reset.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 60-69



.. only:: latex

   Source file: :pocsrc:`misc/sync/sync_Reset.vhdl <misc/sync/sync_Reset.vhdl>`
