.. _IPDB:

IP Core Database
################

.. contents:: Contents of this Page
   :local:

Overview
********

PoC internal IP core database uses INI files and advanced interpolation rules
provided by ExtendedConfigParser_. The database consists of 5 *.ini files:

* :file:`py\config.boards.ini`
    This files contains all known :doc:`FPGA boards <ListOfBoards>` and
    :doc:`FPGA devices <ListOfDevices>`.
* :file:`py\config.defaults.ini`
    This files contains all default options and values for all supported node
    types.
* :file:`py\config.entity.ini`
    This file contains all IP cores (entities) and theirs corresponding testbench
    or netlist settings.
* :file:`py\config.private.ini`
    This files is created by ``.\poc.ps1 configure`` and contains settings for the
    local PoC installation. This files must not be shared with other PoC instances.
    See :doc:`Configuring PoC's Infrastructure </UsingPoC/PoCConfiguration>` on how
    to configure PoC on a local system.
* :file:`py\config.structure.ini`
    Nodes in this file describe PoC's namespace tree and which IP cores are
    assigned to which namespace.

Additionally, the database refers to :ref:`*.files <FileFormat:files>`
and :ref:`*.rules <FileFormat:rules>` files. The first file type describes, in
an imperative language, which files are needed to compile a simulation or to
run a synthesis. The latter file type contains patch instructions per IP core.
See :ref:`Files Formats <FileFormats>` for more details.

.. _ExtendedConfigParser: https://github.com/Paebbels/ExtendedConfigParser


.. _IPDB:Structure:

Database Structure
******************

The database is stored in multiple :ref:`INI files <FileFormat:ini>`,
which are merged in memory to a single configuration database. Each INI file
defines an associative array of *sections* and option lines. The content itself
is an associative array of *options* and values. Section names are inclosed in
square brackets ``[...]`` and allow simple case-sensitive strings as names. A
section name is followed by its section content, which consists of option lines.

One option is stored per option line and consists of an option name and a value
separated by an equal sign ``=``. The option name is also a case-sensitive
simple string. The value is string, starts after the first non-whitespace
character and end before the newline character at the end of the line. The
content can be of any string, except for the newline characters. Support for
escape sequences depends on the option usage.

Values containing ``${...}`` and ``%{...}`` are raw values, which need to be
interpolated by the ExtendedConfigParser. See `Value Interpolation`_ and
`Node Interpolation`_ for more details.

Sections can have a default section called ``DEFAULT``. Options not found in a
normal section are looked up in the default section. If found, the value of the
matching option name is the lookup result.

.. rubric:: Example

.. code-block:: ini

   [section1]
   option1 = value1
   opt2 =    val ue $2

   [section2]
   option1 = ${section1:option1}
   opt2 =    ${option1}


Option lines can be of three kinds: An option, a reference, or a user defined
variable. While the syntax is always the same, the meaning is infered from the
context.

+---------------------------+-----------------------------------------------------------------+
| Option Line Kind          | Distinguishing Characteristic                                   |
+===========================+=================================================================+
| **Reference**             | The option name is called a (node) reference, if the value\     |
|                           | of an option is a predefined keyword for the current node\      |
|                           | class. Because the option's value is a keyword, it can not\     |
|                           | be an interpolated value.                                       |
+---------------------------+-----------------------------------------------------------------+
| **Option**                | The option uses a defined option name valid for the current\    |
|                           | node class. The value can be a fixed or interpolated string.    |
+---------------------------+-----------------------------------------------------------------+
| **User Defined Variable** | Otherwise an option line is a user defined variable. It can\    |
|                           | have fixed or interpolated string values.                       |
+---------------------------+-----------------------------------------------------------------+

.. code-block:: ini

   [PoC]
   Name =
   Prefix =
   arith =         Namespace
   bus =           Namespace

   [PoC.arith]
   addw =          Entity
   prng =          Entity

   [PoC.bus]
   stream =        Namespace
   wb =            Namespace
   Arbiter =       Entity

   [PoC.bus.stream]
   Buffer =        Entity
   DeMux =         Entity
   Mirror =        Entity
   Mux =           Entity

   [PoC.bus.wb]
   fifo_adapter =  Entity
   ocram_adapter = Entity
   uart_wrapper =  Entity


.. _IPDB:Nodes:

Nodes
=====

The database is build of nested associative arrays and generated in-memory from
5 *.ini files. This implies that all section names are required to be unique.
(Section merging is not allowed.) A fully qualified section name has a prefix
and a section name delimited by a dot character. The section name itself can
consist of parts also delimited by dot characters. All nodes with the same
prefix shape a node class.

.. rubric:: The following table lists all used prefixes:

+---------------+---------------------------------------------------------------------------------+
| Prefix        | Description                                                                     |
+===============+=================================================================================+
| ``INSTALL``   | A installed tool (chain) or program.                                            |
+---------------+---------------------------------------------------------------------------------+
| ``SOLUTION``  | Registered external solutions / projects.                                       |
+---------------+---------------------------------------------------------------------------------+
| ``CONFIG``    | Configurable PoC settings.                                                      |
+---------------+---------------------------------------------------------------------------------+
| ``BOARD``     | A node to describe a known board.                                               |
+---------------+---------------------------------------------------------------------------------+
| ``CONST``     | A node to describe constraint file set for a known board.                       |
+---------------+---------------------------------------------------------------------------------+
| ``PoC``       | Nodes to describe PoC's namespace structure.                                    |
+---------------+---------------------------------------------------------------------------------+
| ``IP``        | A node describing an IP core.                                                   |
+---------------+---------------------------------------------------------------------------------+
| ``TB``        | A node describing testbenches.                                                  |
+---------------+---------------------------------------------------------------------------------+
| ``COCOTB``    | A node describing Cocotb testbenches.                                           |
+---------------+---------------------------------------------------------------------------------+
| ``CG``        | A node storing Core Generator settings.                                         |
+---------------+---------------------------------------------------------------------------------+
| ``LSE``       | A node storing settings for LSE based netlist generation.                       |
+---------------+---------------------------------------------------------------------------------+
| ``QMAP``      | A node storing settings for Quartus based netlist generation.                   |
+---------------+---------------------------------------------------------------------------------+
| ``XST``       | A node storing settings for XST based netlist generation.                       |
+---------------+---------------------------------------------------------------------------------+
| ``VIVADO``    | A node storing settings for Vivado based netlist generation.                    |
+---------------+---------------------------------------------------------------------------------+
| ``XCI``       | A node storing settings for IP Catalog based netlist generation.                |
+---------------+---------------------------------------------------------------------------------+

.. rubric:: The database has 3 special sections without prefixes:

+---------------+------------------------------------------------------------------------------------+
| Section Name  | Description                                                                        |
+===============+====================================================================================+
| ``PoC``       | Root node for PoC's namespace hierarchy.                                           |
+---------------+------------------------------------------------------------------------------------+
| ``BOARDS``    | Lists all known boards.                                                            |
+---------------+------------------------------------------------------------------------------------+
| ``SPECIAL``   | Section with dummy values. This is needed by synthesis and overwritten at runtime. |
+---------------+------------------------------------------------------------------------------------+


.. rubric:: Example section names

.. code-block:: ini

   [PoC]
   [PoC.arith]
   [PoC.bus]
   [PoC.bus.stream]
   [PoC.bus.wb]

The fully qualified section name ``PoC.bus.stream``	has the prefix ``PoC`` and
the section name ``bus.stream``. The section name has two parts: ``bus`` and
``stream``. The dot delimited section name can be considered a path in a
hierarchical database. The parent node is ``PoC.bus`` and its grandparent is
``PoC``. (Note this is a special section. See the special sections table from
above.)


.. _IPDB:Refs:

References
==========



:Whatever: this is handy to create new field


.. _IPDB:Options:

Options
========


.. _IPDB:Values:

Values
======


.. _IPDB:ValueInterpol:

Value Interpolation
===================


.. _IPDB:NodeInterpol:

Node Interpolation
==================


.. _IPDB:Roots:

Root Nodes
==========

Supported Options
*****************


.. NOTE::
   See ``py\config.defaults.ini`` for predefined default values (options) and
   predefined variables, which can be used as a shortcut.


.. _IPDB:Files:

Files in detail
***************



.. _IPDB:File:Structure:

config.structure.ini
====================



.. _IPDB:File:Entity:

config.entity.ini
=================



.. _IPDB:File:Boards:

config.boards.ini
=================



.. _IPDB:File:Private:

config.private.ini
==================

.. _IPDB:UserDefVar:

User Defined Variables
**********************


.. |date| date:: %d.%m.%Y
.. |time| date:: %H:%M


