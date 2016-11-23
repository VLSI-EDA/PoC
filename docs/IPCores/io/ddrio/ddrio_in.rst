.. _IP:ddrio_in:

PoC.io.ddrio.in
###############

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/io/ddrio/ddrio_in.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/io/ddrio/ddrio_in_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <io/ddrio/ddrio_in.vhdl>`
      * |gh-tb| :poctb:`Testbench <io/ddrio/ddrio_in_tb.vhdl>`

Instantiates chip-specific :abbr:`DDR (Double Data Rate)` input registers.

Both data ``DataIn_high/low`` are synchronously outputted to the on-chip logic
with the rising edge of ``Clock``. ``DataIn_high`` is the value at the ``Pad``
sampled with the same rising edge. ``DataIn_low`` is the value sampled with
the falling edge directly before this rising edge. Thus sampling starts with
the falling edge of the clock as depicted in the following waveform.

.. wavedrom::

   { signal: [
     ['DataIn',
       {name: 'ClockIn',         wave: 'L.H.L.H.L.H.L.H.L.'},
       {name: 'ClockInEnable',   wave: '01............0...'},
       {name: 'DataIn_low',      wave: 'x.....2...4...x...', data: ['0',      '2'],      node: '......u...w.'},
       {name: 'DataIn_high',     wave: 'x.....3...5...x...', data: ['1',      '3'],      node: '......v...x.'}
     ],
     {name: 'Pad',             wave: 'x2.3.4.5.x........', data: ['0', '1', '2', '3'], node: '.a.b.c.d.....'},
     ],
     edge: ['a~>u', 'b~>v', 'c~>w', 'd~>x'],
     foot: {
       text: ['tspan',
         ['tspan', {'font-weight': 'bold'}, 'PoC.io.ddrio.inout'],
         ' -- DDR Data Input/Output sampled from pad.'
       ]
     }
   }

After power-up, the output ports ``DataIn_high`` and ``DataIn_low`` both equal
INIT_VALUE.

``Pad`` must be connected to a PAD because FPGAs only have these registers in
IOBs.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/io/ddrio/ddrio_in.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 74-86



.. only:: latex

   Source file: :pocsrc:`io/ddrio/ddrio_in.vhdl <io/ddrio/ddrio_in.vhdl>`
