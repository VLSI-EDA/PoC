.. _IP:xil_SystemMonitor:

PoC.xil.SystemMonitor
#####################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/xil/xil_SystemMonitor.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/xil/xil_SystemMonitor_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <xil/xil_SystemMonitor.vhdl>`
      * |gh-tb| :poctb:`Testbench <xil/xil_SystemMonitor_tb.vhdl>`

This module generates a PWM signal for a 3-pin (transistor controlled) or
4-pin fan header. The FPGAs temperature is read from device specific system
monitors (normal, user temperature, over temperature).

**For example the Xilinx System Monitors are configured as follows:**

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

.. literalinclude:: ../../../src/xil/xil_SystemMonitor.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 62-73



.. only:: latex

   Source file: :pocsrc:`xil/xil_SystemMonitor.vhdl <xil/xil_SystemMonitor.vhdl>`
