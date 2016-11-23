.. _IP:stream_Buffer:

PoC.bus.stream.Buffer
#####################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/bus/stream/stream_Buffer.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/bus/stream/stream_Buffer_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <bus/stream/stream_Buffer.vhdl>`
      * |gh-tb| :poctb:`Testbench <bus/stream/stream_Buffer_tb.vhdl>`

This module implements a generic buffer (FIFO) for the
:doc:`PoC.Stream </Interfaces/Stream>` protocol. It is generic in
``DATA_BITS`` and in ``META_BITS`` as well as in FIFO depths for data and
meta information.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/bus/stream/stream_Buffer.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 44-74



.. only:: latex

   Source file: :pocsrc:`bus/stream/stream_Buffer.vhdl <bus/stream/stream_Buffer.vhdl>`
