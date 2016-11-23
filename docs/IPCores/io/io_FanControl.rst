.. _IP:io_FanControl:

PoC.io.FanControl
#################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/io/io_FanControl.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/io/io_FanControl_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <io/io_FanControl.vhdl>`
      * |gh-tb| :poctb:`Testbench <io/io_FanControl_tb.vhdl>`

.. code-block:: none

		This module generates a PWM signal for a 3-pin (transistor controlled) or
		4-pin fan header. The FPGAs temperature is read from device specific system
		monitors (normal, user temperature, over temperature).

		For example the Xilinx System Monitors are configured as follows:

										|											 /-----\
		Temp_ov	 on=80	|	-	-	-	-	-	-	/-------/				\
										|						 /				|				 \
		Temp_ov	off=60	|	-	-	-	-	-	/	-	-	-	-	|	-	-	-	-	\----\
										|					 /					|								\
										|					/						|							 | \
		Temp_us	 on=35	|	-	 /---/						|							 |	\
		Temp_us	off=30	|	-	/	-	-|-	-	-	-	-	-	|	-	-	-	-	-	-	-|-  \------\
										|  /		 |						|							 |					 \
		----------------|--------|------------|--------------|----------|---------
		pwm =						|		min	 |	medium		|		max				 |	medium	|	min




.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/io/io_FanControl.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 63-81



.. only:: latex

   Source file: :pocsrc:`io/io_FanControl.vhdl <io/io_FanControl.vhdl>`
