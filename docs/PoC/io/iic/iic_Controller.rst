
iic_Controller
##############

The I2C Controller transmitts words over the I2C bus (SerialClock - SCL,
SerialData - SDA) and also receives them. This controller utilizes the
I2C BusController to send/receive bits over the I2C bus. This controller
is compatible to the System Management Bus (SMBus).


.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/io/iic/iic_Controller.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 47-87


	 