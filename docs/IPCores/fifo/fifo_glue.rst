.. _IP:fifo_glue:

PoC.fifo.glue
#############

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/fifo/fifo_glue.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/fifo/fifo_glue_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <fifo/fifo_glue.vhdl>`
      * |gh-tb| :poctb:`Testbench <fifo/fifo_glue_tb.vhdl>`

Its primary use is the decoupling of enable domains in a processing
pipeline. Data storage is limited to two words only so as to allow both
the ``ful``  and the ``vld`` indicators to be driven by registers.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/fifo/fifo_glue.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 36-55



.. only:: latex

   Source file: :pocsrc:`fifo/fifo_glue.vhdl <fifo/fifo_glue.vhdl>`
