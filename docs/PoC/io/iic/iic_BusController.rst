
iic_BusController
#################

The I2C BusController transmitts bits over the I2C bus (SerialClock - SCL,
SerialData - SDA) and also receives them.	To send/receive words over the
I2C bus, use the I2C Controller, which utilizes this controller. This
controller is compatible to the System Management Bus (SMBus).


.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/io/iic/iic_BusController.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 47-70

Source file: `io/iic/iic_BusController.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/io/iic/iic_BusController.vhdl>`_


	 