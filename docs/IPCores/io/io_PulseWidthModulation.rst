.. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
            :scale: 40
            :target: https://github.com/VLSI-EDA/PoC/blob/master/src/io/io_PulseWidthModulation.vhdl
            :alt: Source Code on GitHub
.. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
            :scale: 40
            :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/io/io_PulseWidthModulation_tb.vhdl
            :alt: Source Code on GitHub

.. sidebar:: GitHub Links

   * |gh-src| :pocsrc:`Sourcecode <io/io_PulseWidthModulation.vhdl>`
   * |gh-tb| :poctb:`Testbench <io/io_PulseWidthModulation_tb.vhdl>`

.. _IP:io_PulseWidthModulation:

io_PulseWidthModulation
#######################

This module generates a pulse width modulated signal, that can be configured
in frequency (``PWM_FREQ``) and modulation granularity (``PWM_RESOLUTION``).



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/io/io_PulseWidthModulation.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 41-53

Source file: :pocsrc:`io/io_PulseWidthModulation.vhdl <io/io_PulseWidthModulation.vhdl>`


