.. _IP:arith_addw:

PoC.arith.addw
##############

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/arith/arith_addw.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/arith/arith_addw_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <arith/arith_addw.vhdl>`
      * |gh-tb| :poctb:`Testbench <arith/arith_addw_tb.vhdl>`

Implements wide addition providing several options all based
on an adaptation of a carry-select approach.

References:

* Hong Diep Nguyen and Bogdan Pasca and Thomas B. Preusser:
  FPGA-Specific Arithmetic Optimizations of Short-Latency Adders,
  FPL 2011.
  -> ARCH:     AAM, CAI, CCA
  -> SKIPPING: CCC

* Marcin Rogawski, Kris Gaj and Ekawat Homsirikamol:
  A Novel Modular Adder for One Thousand Bits and More
  Using Fast Carry Chains of Modern FPGAs, FPL 2014.
  -> ARCH:		 PAI
  -> SKIPPING: PPN_KS, PPN_BK



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/arith/arith_addw.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 54-71



.. only:: latex

   Source file: :pocsrc:`arith/arith_addw.vhdl <arith/arith_addw.vhdl>`
