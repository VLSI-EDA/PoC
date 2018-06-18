.. _IP:ddrio_inout:

PoC.io.ddrio.inout
##################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/io/ddrio/ddrio_inout.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/io/ddrio/ddrio_inout_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <io/ddrio/ddrio_inout.vhdl>`
      * |gh-tb| :poctb:`Testbench <io/ddrio/ddrio_inout_tb.vhdl>`

Instantiates chip-specific :abbr:`DDR (Double Data Rate)` input and output
registers.

Both data ``DataOut_high/low`` as well as ``OutputEnable`` are sampled with
the ``rising_edge(Clock)`` from the on-chip logic. ``DataOut_high`` is brought
out with this rising edge. ``DataOut_low`` is brought out with the falling
edge.

``OutputEnable`` (Tri-State) is high-active. It is automatically inverted if
necessary. Output is disabled after power-up.

Both data ``DataIn_high/low`` are synchronously outputted to the on-chip logic
with the rising edge of ``Clock``. ``DataIn_high`` is the value at the ``Pad``
sampled with the same rising edge. ``DataIn_low`` is the value sampled with
the falling edge directly before this rising edge. Thus sampling starts with
the falling edge of the clock as depicted in the following waveform.

.. wavedrom::

   { signal: [
     ['DataOut',
       {name: 'ClockOut',        wave: 'LH.L.H.L.H.L.H.L.H.L.H.'},
       {name: 'ClockOutEnable',  wave: '0..1...................'},
       {name: 'OutputEnable',    wave: '0.......1.......0......'},
       {name: 'DataOut_low',     wave: 'x.......2...4...x......', data: ['4',      '6'],      node: '........k...m...o..'},
       {name: 'DataOut_high',    wave: 'x.......3...5...x......', data: ['5',      '7'],      node: '........l...n...p..'}
       ],
       {},
       {name: 'Pad',             wave: 'x2.3.4.5.z...2.3.4.5.z.', data: ['0', '1', '2', '3', '4', '5', '6', '7'], node: '.a.b.c.d.....e.f.g.h.'},
       {},
     ['DataIn',
       {name: 'ClockIn',         wave: 'L.H.L.H.L.H.L.H.L.H.L.H'},
       {name: 'ClockInEnable',   wave: '01.......0.............'},
       {name: 'DataIn_low',      wave: 'x.....2...4...z...2...4', data: ['0',      '2',      '4'],      node: '......u...w.......y..'},
       {name: 'DataIn_high',     wave: 'x.....3...5...z...3...5', data: ['1',      '3',      '5'],      node: '......v...x.......z..'}
     ]
     ],
     edge: ['a~>u', 'b~>v', 'c~>w', 'd~>x', 'k~>e', 'l~>f', 'm~>g', 'n~>h', 'e~>y', 'f~>z'],
     foot: {
       text: ['tspan',
         ['tspan', {'font-weight': 'bold'}, 'PoC.io.ddrio.inout'],
         ' -- DDR Data Input/Output sampled from pad.'
       ]
     }
   }

``Pad`` must be connected to a PAD because FPGAs only have these registers in
IOBs.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/io/ddrio/ddrio_inout.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 89-107



.. only:: latex

   Source file: :pocsrc:`io/ddrio/ddrio_inout.vhdl <io/ddrio/ddrio_inout.vhdl>`
