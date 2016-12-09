.. _NS:fifo:

PoC.fifo
========

The namespace `PoC.fifo` offers different :abbr:`FIFO (first-in, first-out)` implementations.

**Package**

The package :ref:`NS:fifo` holds all component declarations for this namespace.

**Entities**

PoC offers FIFOs with a `got`-interface. This means, the current read-pointer value
is available on the output. Asserting the `got`-input, acknoledge the processing of
the current output signals and moves the read-pointer to the next value, if available.

All FIFOs implement a bidirectional flow control (`put`/`full` and `valid`/`got`).
Each FIFO also offers a EmptyState (write-side) and FullState (read-side) to indicate
the current fill-state.

The prefixes `cc_` (common clock), `dc_` (dependent clock) and `ic_` (independent
clock) refer to the write- and read-side clock relationship.

 * :ref:`IP:fifo_cc_got` implements a regular FIFO (one common clock,
   got-interface)
 * :ref:`IP:fifo_cc_got_tempgot` implements a regular FIFO (one common clock,
   got-interface), extended by a transactional `tempgot`-interface (read-side).
 * :ref:`IP:fifo_cc_got_tempput` implements a regular FIFO (one common clock,
   got-interface), extended by a transactional `tempput`-interface (write-side).
 * :ref:`IP:fifo_dc_got` implements a cross-clock FIFO (two related clocks,
   got-interface)
 * :ref:`IP:fifo_ic_got` implements a cross-clock FIFO (two independent clocks,
   got-interface)
 * :ref:`IP:fifo_glue` implements a two-stage FIFO (one common clock,
   got-interface)
 * :ref:`IP:fifo_shift` implements a regular FIFO (one common clock,
   got-interface, optimized for FPGAs with shifter primitives)

.. toctree::
   :hidden:

   Package <fifo.pkg>

.. toctree::
   :hidden:

   fifo_cc_got <fifo_cc_got>
   fifo_cc_got_tempgot <fifo_cc_got_tempgot>
   fifo_cc_got_tempput <fifo_cc_got_tempput>
   fifo_glue <fifo_glue>
   fifo_ic_assembly <fifo_ic_assembly>
   fifo_ic_got <fifo_ic_got>
   fifo_shift <fifo_shift>
