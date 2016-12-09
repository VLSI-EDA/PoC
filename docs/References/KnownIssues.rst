.. _ISSUE:

Known Issues
############


.. _ISSUE:General:

General
*******


.. _ISSUE:General:tristate:

Synthesis of tri-state signals
==============================

Tri-state signals should be only used when they are connected
(through the hierarchy) to top-level bidirectional or output pins.

Descriptions which infer a tri-state driver like::

  pin <= data when tri = '0' else 'Z';

should not be included in any IP core description because these hinder
or even inhibit block-based design flows. If a netlist is generated
from such an IP core, the netlist may contain only a simple internal
(on-chip) tri-state buffer instead of the correct tri-state I/O block
primitive because I/O buffers are not automatically added for netlist
generation. If the netlist is then used in another design, the
mapper, e.g. Xilinx ISE Map, may fail to merge the
internal tri-state buffer of the IP core netlist with the I/O buffer
automatically created for the top-level netlist. This failing behavior
is not considered as a tool bug.

Thus, if tri-state drivers should be included in an IP core, then the
IP core description must instantiate the appropiate I/O block
primitive of the target architecture like it is done by the Xilinx MIG.


.. _ISSUE:General:inout_records:

Synthesis of bidirectional records
==================================

Records are useful to group several signals of an IP core
interface. But the corresponding port of this record type should not
be of mode ``inout`` to pass data in both direction. This restriction
holds even if a record member will be driven only by one source in the
real hardware and even if all the drivers (one for each record member)
are visible to the current synthesis run. The following
observations have been made:

* An IP core (entity or procedure) must drive all record members with
  value 'Z' which are only used as an input in the IP core. If this is
  missed, then the respective record member will be driven by 'U' and
  the effective value after resolution will be 'U' as well, see IEEE
  Std. 1076-2008 para. 12.6.1. Thus simulation will fail.

  But these 'Z' drivers will flood the RTL / Netlist view of Altera
  Quartus-II, Intel Quartus Prime and Lattice Diamond with always
  tri-stated drivers and make this view unusable.

  Note: Simulation with ModelSim shows correct output even when the
  'Z' driver is missing, but a warning is reported that the behavior
  is not VHDL Standard compliant.

* Altera Quartus-II and Intel Quartus Prime report warnings about this
  meaningless 'Z' drivers. Synthesis result is as expected if each
  record member is only driven by one source in real hardware.

* The synthesis result of the Lattice Synthesis Engine (3.7.0 / 3.8.0)
  is not optimal. It seems that the synthesizer tries to implement the
  internal (on-chip) tristate bus using AND-OR logic but failed to
  optimize it away because there was only one real source. Test case
  was a simple SRAM controller which used the record type
  ``T_IO_TRISTATE`` to bring-out the data-bus so that the tri-state
  driver could be instantiated on the top-level.

Use separate records for the input and output data flow instead.


--------------------------------------------------------------------------------

.. _ISSUE:Aldec:ActiveHDL:

Aldec Active-HDL
****************

* Aliases to functions and protected type methods


.. _ISSUE:Altera:Quartus:
.. _ISSUE:Intel:Quartus:

Altera Quartus-II / Intel Quartus Prime
***************************************

* Generic types of type strings filled with NUL


.. _ISSUE:GHDL:

GHDL
****

* Aliases to protected type methods


.. _ISSUE:Xilinx:ISE:

Xilinx ISE
**********

* Shared Variables in Simulation (VHDL-93)


.. _ISSUE:Xilinx:Vivado:

Xilinx Vivado
*************

* Physical types in synthesis
* VHDL-2008 mode in simulation
* Shared variables in simulation (VHDL-93 and VHDL-2008))
