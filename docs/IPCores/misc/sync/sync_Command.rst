.. _IP:sync_Command:

PoC.misc.sync.Command
#####################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/misc/sync/sync_Command.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/misc/sync/sync_Command_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <misc/sync/sync_Command.vhdl>`
      * |gh-tb| :poctb:`Testbench <misc/sync/sync_Command_tb.vhdl>`

This module synchronizes a vector of bits from clock-domain ``Clock1`` to
clock-domain ``Clock2``. The clock-domain boundary crossing is done by a
change comparator, a T-FF, two synchronizer D-FFs and a reconstructive
XOR indicating a value change on the input. This changed signal is used
to capture the input for the new output. A busy flag is additionally
calculated for the input clock-domain. The output has strobe character
and is reset to it's ``INIT`` value after one clock cycle.

Constraints:
  This module uses sub modules which need to be constrained. Please
  attend to the notes of the instantiated sub modules.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/misc/sync/sync_Command.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 51-65



.. only:: latex

   Source file: :pocsrc:`misc/sync/sync_Command.vhdl <misc/sync/sync_Command.vhdl>`
