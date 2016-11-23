.. _IP:misc_bit_lz:

PoC.misc.bit_lz
###############

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/misc/misc_bit_lz.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/misc/misc_bit_lz_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <misc/misc_bit_lz.vhdl>`
      * |gh-tb| :poctb:`Testbench <misc/misc_bit_lz_tb.vhdl>`


 An LZ77-based bit stream compressor.

 Output Format

 1 | Literal
   A literal bit string of length COUNT_BITS+OFFSET_BITS.

 0 | <Count:COUNT_BITS> | <Offset:OFFSET_BITS>
   Repetition starting at <Offset> in history buffer of length
   <Count>+COUNT_BITS+OFFSET_BITS where <Count> < 2^COUNT_BITS-1.
   Unless <Count> = 2^COUNT_BITS-2, this repetition is
   followed by a trailing non-matching, i.e. inverted, bit.
   The most recent bit just preceding the repetition is considered to be at
   offset zero(0). Older bits are at higher offsets accordingly. The
   reported length of the repetition may actually be greater than the
   offset. In this case, the repetition is reoccuring in itself. The
   reconstruction must then be performed in several steps.

 0 | <1:COUNT_BITS> | <Offset:OFFSET_BITS>
   This marks the end of the message. The <Offset> field alters the
   semantics of the immediately preceding message:

   a)If the preceding message was a repetition, <Offset> specifies the value
     of the trailing bit explicitly in its rightmost bit. The implicit
     trailing non-matching bit is overridden.
   b)If the preceding message was a literal, <Offset> is a non-positive
     number d given in its one's complement representation. The value
     ~d specifies the number of bits,  which this literal repeated of the
     preceding output. These bits must be deleted from the reconstructed
     stream.


 Parameter Constraints

  COUNT_BITS <= OFFSET_BITS < 2**COUNT_BITS - COUNT_BITS

=============================================================================


.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/misc/misc_bit_lz.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 69-91



.. only:: latex

   Source file: :pocsrc:`misc/misc_bit_lz.vhdl <misc/misc_bit_lz.vhdl>`
