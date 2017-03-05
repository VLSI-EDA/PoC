.. _IP:io_GlitchFilter:

PoC.io.GlitchFilter
###################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/io/io_GlitchFilter.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/io/io_GlitchFilter_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <io/io_GlitchFilter.vhdl>`
      * |gh-tb| :poctb:`Testbench <io/io_GlitchFilter_tb.vhdl>`

This module filters glitches on a wire. The high and low spike suppression
cycle counts can be configured.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/io/io_GlitchFilter.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 41-51



.. only:: latex

   Source file: :pocsrc:`io/io_GlitchFilter.vhdl <io/io_GlitchFilter.vhdl>`
