.. _IP:sort_lru_list:

PoC.sort.lru_list
#################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/sort/sort_lru_list.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/sort/sort_lru_list_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <sort/sort_lru_list.vhdl>`
      * |gh-tb| :poctb:`Testbench <sort/sort_lru_list_tb.vhdl>`

List storing ``(key, value)`` pairs. The least-recently inserted pair is
outputed on ``DataOut`` if ``Valid = '1'``. If ``Valid = '0'``, then the list
empty.

The inputs ``Insert``, ``Remove``, ``DataIn``, and ``Reset`` are synchronous
to the rising-edge of the clock ``clock``. All control signals are high-active.

Supported operations:
 * **Insert:** Insert ``DataIn`` as  recently used ``(key, value)`` pair. If
   key is already within the list, then the corresponding value is updated and
   the pair is moved to the recently used position.
 * **Remove:** Remove ``(key, value)`` pair with the given key. The list is not
   modified if key is not within the list.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/sort/sort_lru_list.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 55-74



.. only:: latex

   Source file: :pocsrc:`sort/sort_lru_list.vhdl <sort/sort_lru_list.vhdl>`
