.. _IP:bus_Arbiter:

PoC.bus.Arbiter
###############

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/bus/bus_Arbiter.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/bus/bus_Arbiter_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <bus/bus_Arbiter.vhdl>`
      * |gh-tb| :poctb:`Testbench <bus/bus_Arbiter_tb.vhdl>`

This module implements a generic arbiter. It currently supports the
following arbitration strategies:

* Round Robin (RR)



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/bus/bus_Arbiter.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 42-60



.. only:: latex

   Source file: :pocsrc:`bus/bus_Arbiter.vhdl <bus/bus_Arbiter.vhdl>`
