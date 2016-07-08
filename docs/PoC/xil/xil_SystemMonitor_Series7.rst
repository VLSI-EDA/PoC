
xil_SystemMonitor_Series7
#########################

This module wraps a Series-7 XADC to report if preconfigured temperature values
are overrun. The XADC was formerly known as "System Monitor".

.. rubric:: Temperature Curve

.. code-block:: None
 
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

.. literalinclude:: ../../../src/xil/xil_SystemMonitor_Series7.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 56-66

Source file: `xil/xil_SystemMonitor_Series7.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/xil/xil_SystemMonitor_Series7.vhdl>`_


 
