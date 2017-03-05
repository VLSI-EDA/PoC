.. _IP:io_TimingCounter:

PoC.io.TimingCounter
####################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/io/io_TimingCounter.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/io/io_TimingCounter_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <io/io_TimingCounter.vhdl>`
      * |gh-tb| :poctb:`Testbench <io/io_TimingCounter_tb.vhdl>`

This down-counter can be configured with a ``TIMING_TABLE`` (a ROM), from which
the initial counter value is loaded. The table index can be selected by
``Slot``. ``Timeout`` is a registered output. Up to 16 values fit into one ROM
consisting of ``log2ceilnz(imax(TIMING_TABLE)) + 1`` 6-input LUTs.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/io/io_TimingCounter.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 43-54



.. only:: latex

   Source file: :pocsrc:`io/io_TimingCounter.vhdl <io/io_TimingCounter.vhdl>`
