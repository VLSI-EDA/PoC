.. _IP:dstruct_deque:

PoC.dstruct.deque
#################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/dstruct/dstruct_deque.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/dstruct/dstruct_deque_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <dstruct/dstruct_deque.vhdl>`
      * |gh-tb| :poctb:`Testbench <dstruct/dstruct_deque_tb.vhdl>`

Implements a deque (double-ended queue). This data structure allows two
acting entities to queue data elements for the consumption by the other while
still being able to unqueue untaken ones in LIFO fashion.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/dstruct/dstruct_deque.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 37-62



.. only:: latex

   Source file: :pocsrc:`dstruct/dstruct_deque.vhdl <dstruct/dstruct_deque.vhdl>`
