
IP Core Database
################

.. contents:: Contents of this Page
   :local:

Overview
********

PoC internal IP core database uses INI files and advanced interpolation rules
provided by ExtendedConfigParser_.
The database consists of 5 *.ini files which are in-memory merge to a single
configuration database:

* ``py\config.boards.ini``
    This files contains all known :doc:`FPGA boards <ListOfBoards>` and
    :doc:`FPGA devices <ListOfDevices>`.
* ``py\config.defaults.ini``
    This files contains all default options and values for all supported nodes
    types.
* ``py\config.entity.ini``
    This file contains all IP cores (entities) and theirs corresponding testbench
    or netlist settings.
* ``py\config.private.ini``
    This files is created by ``.\poc.ps1 configure`` and contains settings for these
    local PoC installation. This files must not be shared with other PoC instances.
    See :doc:`Configuring PoC's Infrastructure </UsingPoC/PoCConfiguration>` on how
    to configure PoC on a local system.
* ``py\config.structure.ini``
    Nodes in these file describe PoC's namespace tree and which IP cores are
    assigned to which namespace.

Additionally, the database refers to *.files and *.rules files. The first file
type describes in an imperative langauge, which files are needed to compile a
simulation or to run a synthesis. the latter file type comprises patch
instructions per IP core. See :doc:`Files Format <FileFormats/FilesFormat>` and
:doc:`Rules Format <FileFormats/RulesFormat>` for more details.

.. _ExtendedConfigParser: https://github.com/Paebbels/ExtendedConfigParser

Database Structure
******************

The database is stored in *.ini files, which define an associative array of
`sections` and option lines. The content itself is an associative array of
`options` and values. Section names are inclosed in square brackets ``[...]``
and allow simple strings as names. A section name is case-sensitive. It is
followed by its section content, which consists of option lines.

One option is stored per line. An option name is a case-sensitive simple string
separated by an equal sign ``=`` from its value. The value is string, starts
after the first non-whitespace character and end before the newline character at
the line end. The content can be of any character string.

Values containing ``${...}`` and ``%{...}`` are raw values, which need to be
interpolated by the ExtendedConfigParser. See `Value Interpolation`_ and
`Node Interpolation`_ for more details.

Sections can have a default section called ``DEFAULT``. Options not found in a
normal section are looked up in the default section. If found, the value of the
matching option name is the lookup result.

.. productionlist::
   Document: `DocumentLine`*
   DocumentLine: `SpecialSection` | `Section` | `CommentLine` | `EmptyLine`
   CommentLine: "#" `CommentText` `LineBreak`
   EmptyLine: `WhiteSpace`* `LineBreak`
   SpecialSection: "[" `SimpleString` "]"
                 : (`OptionLine`)*
   Section: "[" `FQSectionName` "]"
          : (`OptionLine`)*
   OptionLine: `Reference` | `Option` | `UserDefVariable`
   Reference: `ReferenceName` `WhiteSpace`* "=" `WhiteSpace`* `Keyword`
   Option: `OptionName` `WhiteSpace`* "=" `WhiteSpace`* `OptionValue`
   UserDefVariable: `VariableName` `WhiteSpace`* "=" `WhiteSpace`* `VariableValue`
   FQSectionName: `Prefix` "." `SectionName`
   SectionName: `SectionNamePart` ("." `SectionNamePart`)*
   SectionNamePart: `SimpleString`
   ReferenceName: `SimpleString`
   OptionName: `SimpleString`
   VariableName: `SimpleString`

.. rubric:: Example

.. code-block:: ini

   [section1]
   option1 = value1
   opt2 =    val ue $2

   [section2]
   option1 = ${section1:option1}
   opt2 =    ${option1}

.. topic:: **foo bar**

   | wichtige hinweise
   |   2 leerzeichen

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

Option lines can be of three kinds:

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





References
==========



:Whatever: this is handy to create new field


Options
========

Values
======

Value Interpolation
===================

Node Interpolation
==================

Root Nodes
==========

Supported Options
*****************


.. NOTE::
   See ``py\config.defaults.ini`` for predefined default values (options) and
   predefined variables, which can be used as a shortcut.

Files in detail
***************

config.structure.ini
====================

config.entity.ini
=================

config.boards.ini
=================

config.private.ini
==================

User Defined Variables
**********************


.. |date| date:: %d.%m.%Y
.. |time| date:: %H:%M

This document was generated on |date| at |time|.
