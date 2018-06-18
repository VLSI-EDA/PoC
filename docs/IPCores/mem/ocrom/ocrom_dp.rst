.. _IP:ocrom_dp:

PoC.mem.ocrom.dp
################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/mem/ocrom/ocrom_dp.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/mem/ocrom/ocrom_dp_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <mem/ocrom/ocrom_dp.vhdl>`
      * |gh-tb| :poctb:`Testbench <mem/ocrom/ocrom_dp_tb.vhdl>`

Inferring / instantiating dual-port read-only memory, with:

* dual clock, clock enable,
* 2 read ports.

The generalized behavior across Altera and Xilinx FPGAs since
Stratix/Cyclone and Spartan-3/Virtex-5, respectively, is as follows:

WARNING: The simulated behavior on RT-level is not correct.

TODO: add timing diagram
TODO: implement correct behavior for RT-level simulation



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/mem/ocrom/ocrom_dp.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 60-76



.. only:: latex

   Source file: :pocsrc:`mem/ocrom/ocrom_dp.vhdl <mem/ocrom/ocrom_dp.vhdl>`
