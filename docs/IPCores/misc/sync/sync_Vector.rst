.. _IP:sync_Vector:

PoC.misc.sync.Vector
####################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/misc/sync/sync_Vector.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/misc/sync/sync_Vector_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <misc/sync/sync_Vector.vhdl>`
      * |gh-tb| :poctb:`Testbench <misc/sync/sync_Vector_tb.vhdl>`

This module synchronizes a vector of bits from clock-domain ``Clock1`` to
clock-domain ``Clock2``. The clock-domain boundary crossing is done by a
change comparator, a T-FF, two synchronizer D-FFs and a reconstructive
XOR indicating a value change on the input. This changed signal is used
to capture the input for the new output. A busy flag is additionally
calculated for the input clock domain.

Constraints:
  This module uses sub modules which need to be constrained. Please
  attend to the notes of the instantiated sub modules.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/misc/sync/sync_Vector.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 50-65



.. only:: latex

   Source file: :pocsrc:`misc/sync/sync_Vector.vhdl <misc/sync/sync_Vector.vhdl>`
