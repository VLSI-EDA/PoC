.. _FileFormat:files:

*.files Format
##############

.. contents:: Contents of this Page
   :local:

Files files are used to ...

Line comments start with ``#``.

Document
********


Source File Statements
**********************

Bla :token:`VHDLStatement` blub


* ``vhdl Library "<VHDLFile>"``
  This statement references a VHDL source file.

* ``verilog "<VerilogFile>"``
  This statement references a Verilog source file.

* ``cocotb "<PythonFile>"``
  This statement references a Cocotb testbench file (Python file).

* ``ucf "<UCFFile>"``
  This statement references a Xilinx User Constraint File (UCF).

* ``sdc "<SDCFile>"``
  This statement references a Synopsys Design Constraint file (SDC).

* ``xdc "<XDCFile>"``
  This statement references a Xilinx Design Constraint file (XDC).

* ``ldc "<LDCFile>"``
  This statement references a Lattice Design Constraint file (LDC).


Conditional Statements
**********************


* ``If (<Expression>) Then ... [ElseIf (<Expression>) Then ...][Else ...] End IF``
  This allows the user to define conditions, when to load a source file into
  the file list. The ``ElseIF`` and ``Else`` clause of an ``If`` statement are optional.


Boolean Expressions
*******************


Unary operators
---------------

* ``!`` - not
* ``[...]`` - list construction
* ``?`` - file exists

Binary operators
----------------

* ``and`` - and
* ``or`` - or
* ``xor`` - exclusive or
* ``in`` - in list
* ``=`` - equal
* ``!=`` - unequal
* ``<`` - less than
* ``<=`` - less than or equal
* ``>`` - greater than
* ``>=`` - greater than or equal

Literals
--------

* ``<constant>`` - a pre-defined constant
* ``"<String>"`` - Strings are enclosed in quote signs
* ``<Integer>`` - Integers as decimal values

Pre-defined constants
---------------------

* Environment Variables:

  * ``Environment``
	  Values:

    * ``"Simulation"``
    * ``"Synthesis"``

  * ``ToolChain`` - The used tool chain. E.g. ``"Xilinx_ISE"``
  * ``Tool`` - The used tool. E.g. ``"Mentor_QuestaSim"`` or ``"Xilinx_XST"``
  * ``VHDL`` - The used VHDL version. ``1987``, ``1993``, ``2002``, ``2008``

* Board Variables:

  * ``BoardName`` - A string. E.g. ``"KC705"``

* Device Variables:

  * ``DeviceVendor`` - The vendor of the device. E.g. ``"Altera"``
  * ``DeviceDevice`` -
  * ``DeviceFamily`` -
  * ``DeviceGeneration`` -
  * ``DeviceSeries`` -


Path Expressions
****************


* ``/`` - sub-directory
* ``&`` - string concat


### Other Statements

* ``include "<FilesFile>"``
  Include another \*.files file.

* ``library <VHDLLibrary> "<LibraryPath>"``
  Reference an existing (pre-compiled) VHDL library, which is passed to the simulator, if external libraries are supported.

* ``report "<Message>"``
  Print a critical warning in the log window. This critical warning is treated as an error.


