.. _IP:iic_BusController:

PoC.io.iic.BusController
########################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/io/iic/iic_BusController.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/io/iic/iic_BusController_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <io/iic/iic_BusController.vhdl>`
      * |gh-tb| :poctb:`Testbench <io/iic/iic_BusController_tb.vhdl>`

The I2C BusController transmitts bits over the I2C bus (SerialClock - SCL,
SerialData - SDA) and also receives them.	To send/receive words over the
I2C bus, use the I2C Controller, which utilizes this controller. This
controller is compatible to the System Management Bus (SMBus).



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/io/iic/iic_BusController.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 47-65



.. only:: latex

   Source file: :pocsrc:`io/iic/iic_BusController.vhdl <io/iic/iic_BusController.vhdl>`
