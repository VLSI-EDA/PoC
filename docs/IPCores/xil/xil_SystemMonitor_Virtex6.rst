.. _IP:xil_SystemMonitor_Virtex6:

PoC.xil.SystemMonitor_Virtex6
#############################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/xil/xil_SystemMonitor_Virtex6.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/xil/xil_SystemMonitor_Virtex6_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <xil/xil_SystemMonitor_Virtex6.vhdl>`
      * |gh-tb| :poctb:`Testbench <xil/xil_SystemMonitor_Virtex6_tb.vhdl>`

This module wraps a Virtex-6 System Monitor primitive to report if preconfigured
temperature values are overrun.

.. rubric:: Temperature Curve

.. code-block:: none

                   |                      /-----\
   Temp_ov   on=80 | - - - - - - /-------/       \
                   |            /        |        \
   Temp_ov  off=60 | - - - - - / - - - - | - - - - \----\
                   |          /          |              |\
                   |         /           |              | \
   Temp_us   on=35 | -  /---/            |              |  \
   Temp_us  off=30 | - / - -|- - - - - - |- - - - - - - |- -\------\
                   |  /     |            |              |           \
   ----------------|--------|------------|--------------|-----------|--------
   pwm =           |   min  |  medium    |   max        |   medium  |  min



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/xil/xil_SystemMonitor_Virtex6.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 56-66



.. only:: latex

   Source file: :pocsrc:`xil/xil_SystemMonitor_Virtex6.vhdl <xil/xil_SystemMonitor_Virtex6.vhdl>`
