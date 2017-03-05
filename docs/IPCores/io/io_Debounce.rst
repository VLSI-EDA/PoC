.. _IP:io_Debounce:

PoC.io.Debounce
###############

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/io/io_Debounce.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/io/io_Debounce_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <io/io_Debounce.vhdl>`
      * |gh-tb| :poctb:`Testbench <io/io_Debounce_tb.vhdl>`

This module debounces several input pins preventing input changes
following a previous one within the configured ``BOUNCE_TIME`` to pass.
Internally, the forwarded state is locked for, at least, this ``BOUNCE_TIME``.
As the backing timer is restarted on every input fluctuation, the next
passing input update must have seen a stabilized input.

The parameter ``COMMON_LOCK`` uses a single internal timer for all processed
inputs. Thus, all inputs must stabilize before any one may pass changed.
This option is usually fully acceptable for user inputs such as push buttons.

The parameter ``ADD_INPUT_SYNCHRONIZERS`` triggers the optional instantiation
of a two-FF input synchronizer on each input bit.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/io/io_Debounce.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 52-67



.. only:: latex

   Source file: :pocsrc:`io/io_Debounce.vhdl <io/io_Debounce.vhdl>`
