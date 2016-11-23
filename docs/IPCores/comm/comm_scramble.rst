.. _IP:comm_scramble:

PoC.comm.scramble
#################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/comm/comm_scramble.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/comm/comm_scramble_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <comm/comm_scramble.vhdl>`
      * |gh-tb| :poctb:`Testbench <comm/comm_scramble_tb.vhdl>`

The LFSR computation is unrolled to generate an arbitrary number of mask
bits in parallel. The mask are output in little endian. The generated bit
sequence is independent from the chosen output width.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/comm/comm_scramble.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 37-51



.. only:: latex

   Source file: :pocsrc:`comm/comm_scramble.vhdl <comm/comm_scramble.vhdl>`
