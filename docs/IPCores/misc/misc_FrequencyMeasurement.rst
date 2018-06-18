.. _IP:misc_FrequencyMeasurement:

PoC.misc.FrequencyMeasurement
#############################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/misc/misc_FrequencyMeasurement.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/misc/misc_FrequencyMeasurement_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <misc/misc_FrequencyMeasurement.vhdl>`
      * |gh-tb| :poctb:`Testbench <misc/misc_FrequencyMeasurement_tb.vhdl>`

This module counts 1 second in a reference timer at reference clock. This
reference time is used to start and stop a timer at input clock. The counter
value is the measured frequency in Hz.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/misc/misc_FrequencyMeasurement.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 44-56



.. only:: latex

   Source file: :pocsrc:`misc/misc_FrequencyMeasurement.vhdl <misc/misc_FrequencyMeasurement.vhdl>`
