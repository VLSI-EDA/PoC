.. _IP:ocram_sp:

PoC.mem.ocram.sp
################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/mem/ocram/ocram_sp.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/mem/ocram/ocram_sp_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <mem/ocram/ocram_sp.vhdl>`
      * |gh-tb| :poctb:`Testbench <mem/ocram/ocram_sp_tb.vhdl>`

Inferring / instantiating single port memory, with:

* single clock, clock enable,
* 1 read/write port.

Command Truth Table:

== == ================
ce we Command
== == ================
0  X  No operation
1  0  Read from memory
1  1  Write to memory
== == ================

Both reading and writing are synchronous to the rising-edge of the clock.
Thus, when reading, the memory data will be outputted after the
clock edge, i.e, in the following clock cycle.

When writing data, the read output will output the new data (in the
following clock cycle) which is aka. "write-first behavior". This behavior
also applies to Altera M20K memory blocks as described in the Altera:
"Stratix 5 Device Handbook" (S5-5V1). The documentation in the Altera:
"Embedded Memory User Guide" (UG-01068) is wrong.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/mem/ocram/ocram_sp.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 68-82



.. only:: latex

   Source file: :pocsrc:`mem/ocram/ocram_sp.vhdl <mem/ocram/ocram_sp.vhdl>`
