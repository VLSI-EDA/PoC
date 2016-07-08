
io_FanControl
#############

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
   :lines: 61-79

Source file: `io/io_FanControl.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/io/io_FanControl.vhdl>`_


 
