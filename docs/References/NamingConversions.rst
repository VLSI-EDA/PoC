
Naming Conversions
##################

Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.
At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor
sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et
accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet


Namespaces and Modules
**********************

Namespaces
==========

PoC uses namespaces and sub-namespaces to categorize all VHDL and Verilog
modules. Despite VHDL doesn't support sub-namespaces yet, PoC already uses
sub-namespaces enforced by a strict naming schema.

**Rules:**

1. Namespace names are lower-case, underscore free, valid VHDL identifiers.
2. A namespace name is unique, but can be part of a entity name.


Module Names
============

Module names are prefixed with its parents namespace name. A module name can
contain underscores to denote implementation variants of a module.

**Rules:**

3. Modul names are valid VHDL identifiers prefixed with its parent namespace's
   name.
4. The first part of module name must not contain the parents namespace name.
   E.g. ``fifo_fifo`` isn't a valid name.

	
.. rubric:: Example 1 - ``PoC.fifo.cc_got``
	
For example a FIFO module with a common clock interface and a *got*
semantic is named ``PoC.fifo.cc_got`` (fully qualified name). This name can
be split at every dot and underscore sign, resulting in the following table of
name parts:

+----------------+---------------+------------------------+--------------+
| PoC            | fifo          | cc                     | got          |
+================+===============+========================+==============+
| Root Namespace | Sub-Namespace | Common Clock Interface | Got Semantic |
+----------------+---------------+------------------------+--------------+

Because ``PoC.fifo.cc_got`` refers to an IP core, the source file is located in
the ``<PoCRoot>\src`` directory. The (sub-)namespace of the PoC entity is
``fifo``, so it's stored in the sub-directory ``fifo``. The file name ``cc_got``
FIFO is prefixed with the last sub-namespace: In this case ``fifo_``. This is
summarized in the following table:

+----------------------------+---------------------------------------------+
| Property                   | Value                                       |
+============================+=============================================+
| Fully Qualified Name       | PoC.fifo.cc_got                             |
+----------------------------+---------------------------------------------+
| VHDL entity name           | fifo_cc_got                                 |
+----------------------------+---------------------------------------------+
| File name                  | fifo_cc_got.vhdl                            |
+----------------------------+---------------------------------------------+
| IP Core Description File   | \\src\\fifo\\fifo_cc_got.files              |
+----------------------------+---------------------------------------------+
| Source File Location       | \\src\\fifo\\fifo_cc_got.vhdl               |
+----------------------------+---------------------------------------------+
| Testbench Location         | \\tb\\fifo\\fifo_cc_got_tb.vhdl             |
+----------------------------+---------------------------------------------+
| Testbench Description File | \\tb\\fifo\\fifo_cc_got_tb.files            |
+----------------------------+---------------------------------------------+
| Waveform Description Files | \\sim\\fifo\\fifo_cc_got_tb.*               |
+----------------------------+---------------------------------------------+

Other implementation variants are:

*	``_dc`` – dependent clock / related clock
*	``_ic`` – independent clock / cross clock
*	``_got_tempgot`` – got interface extended by a temporary got interface
*	``_got_tempput`` – got interface extended by a temporary put interface


.. rubric:: Example 2 - ``PoC.mem.ocram.tdp``

+----------------+---------------+---------------+------------------------+
| PoC            | mem           | ocram         | tdp                    |
+================+===============+===============+========================+
| Root Namespace | Sub-Namespace | Sub-Namespace | True-Dual-Port         |
+----------------+---------------+---------------+------------------------+

+----------------------------+-----------------------------------------------+
| Property                   | Value                                         |
+============================+===============================================+
| Fully Qualified Name       | PoC.mem.ocram.tdp                             |
+----------------------------+-----------------------------------------------+
| VHDL entity name           | ocram_tdp                                     |
+----------------------------+-----------------------------------------------+
| File name                  | ocram_tdp.vhdl                                |
+----------------------------+-----------------------------------------------+
| IP Core Description File   | \\src\\mem\\ocram\\ocram_tdp.files            |
+----------------------------+-----------------------------------------------+
| Source File Location       | \\src\\mem\\ocram\\ocram_tdp.vhdl             |
+----------------------------+-----------------------------------------------+
| Testbench Location         | \\tb\\mem\\ocram\\ocram_tdp_tb.vhdl           |
+----------------------------+-----------------------------------------------+
| Testbench Description File | \\tb\\mem\\ocram\\ocram_tdp_tb.files          |
+----------------------------+-----------------------------------------------+
| Waveform Description Files | \\sim\\mem\\ocram\\ocram_tdp_tb.*             |
+----------------------------+-----------------------------------------------+


So not all sub-namespace parts are include as a prefix in the name, only
the last one.


Directory Structure
===================

.. TODO::
   Sub-Namespace names are mapped to directories. The root directory is divided
   into directories per file kind: src, tb, sim, ucf, ...




