.. _IP:iic_Controller:

PoC.io.iic.Controller
#####################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/io/iic/iic_Controller.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/io/iic/iic_Controller_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <io/iic/iic_Controller.vhdl>`
      * |gh-tb| :poctb:`Testbench <io/iic/iic_Controller_tb.vhdl>`

The I2C Controller transmitts words over the I2C bus (SerialClock - SCL,
SerialData - SDA) and also receives them. This controller utilizes the
I2C BusController to send/receive bits over the I2C bus. This controller
is compatible to the System Management Bus (SMBus).



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/io/iic/iic_Controller.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 47-82



.. only:: latex

   Source file: :pocsrc:`io/iic/iic_Controller.vhdl <io/iic/iic_Controller.vhdl>`
