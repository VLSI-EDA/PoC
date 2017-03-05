.. _IP:gearbox_up_dc:

PoC.misc.gearbox.up_dc
######################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/misc/gearbox/gearbox_up_dc.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/misc/gearbox/gearbox_up_dc_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <misc/gearbox/gearbox_up_dc.vhdl>`
      * |gh-tb| :poctb:`Testbench <misc/gearbox/gearbox_up_dc_tb.vhdl>`

This module provides a upscaling gearbox with a dependent clock (dc)
interface. It perfoems a 'byte' to 'word' collection. The default order is
LITTLE_ENDIAN (starting at byte(0)). Input "In_Data" is of clock domain
"Clock1"; output "Out_Data" is of clock domain "Clock2". The "In_Align"
is required to mark the starting byte in the word. An optional input
register can be added by enabling (ADD_INPUT_REGISTERS = TRUE).

Assertions:
===========
- Clock periods of Clock1 and Clock2 MUST be multiples of each other.
- Clock1 and Clock2 MUST be phase aligned (related) to each other.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/misc/gearbox/gearbox_up_dc.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 51-66



.. only:: latex

   Source file: :pocsrc:`misc/gearbox/gearbox_up_dc.vhdl <misc/gearbox/gearbox_up_dc.vhdl>`
