.. _IP:sync_Strobe:

PoC.misc.sync.Strobe
####################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/misc/sync/sync_Strobe.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/misc/sync/sync_Strobe_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <misc/sync/sync_Strobe.vhdl>`
      * |gh-tb| :poctb:`Testbench <misc/sync/sync_Strobe_tb.vhdl>`

This module synchronizes multiple high-active bits from clock-domain
``Clock1`` to clock-domain ``Clock2``. The clock-domain boundary crossing is
done by a T-FF, two synchronizer D-FFs and a reconstructive XOR. A busy
flag is additionally calculated and can be used to block new inputs. All
bits are independent from each other. Multiple consecutive strobes are
suppressed by a rising edge detection.

.. ATTENTION::
   Use this synchronizer only for one-cycle high-active signals (strobes).

.. image:: /_static/misc/sync/sync_Strobe.*
   :target: ../../../_static/misc/sync/sync_Strobe.svg

Constraints:
  This module uses sub modules which need to be constrained. Please
  attend to the notes of the instantiated sub modules.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/misc/sync/sync_Strobe.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 55-68



.. only:: latex

   Source file: :pocsrc:`misc/sync/sync_Strobe.vhdl <misc/sync/sync_Strobe.vhdl>`
