
Naming Conventions
##################

.. TODO:: Write an intruduction paragraph for this page.


Root Directory Overview (PoCRoot)
*********************************

The PoC-Library is structured into several sub-directories, naming the purpose
of the directory like ``src`` for sources files or ``tb`` for testbench files.
The structure within these directories is most likely the same and based on
PoC's :doc:`sub-namespace tree </IPCores/index>`. PoC's installation directory is
also referred to as ``PoCRoot``.

* ``lib``
    Third party libraries like Coctb, OSVVM or VUnit are shipped in this folder.
    The external library is stored in a sub directory named like the library. If
    a library is available as a Git submodule, then it is linked as a submodule
    for better version tracking.
* ``netlist``
    This is the output directory for pre-configured netlists, synthesized by PoC.
    Netlists and related constaint files are the result of IP core synthesis
    flows, either from PoC's source files or from vendor specific IP core files
    like \*.xco files from Xilinx Core Generator. Generated IP cores are stored
    in device sub-directories, because most netlists formats are device specific.
    For example the IP core ``PoC.arith.prng`` created from source file
    ``src\arith\arith_prng.vhdl`` generated for a Kintex-7 325T mounted on a
    KC705 board will be copied to ``netlist\XC7K325T-2FFG900\arith\arith_prng.ngc``
    if Xilinx ISE XST is used for synthesis.
* ``py``
    The supporting Python infrastructure, the configuration files and the IP
    core 'database' is stored in this directory.
* ``sim``
    Some of PoC's testbenches are shipped with pre-configured waveform views/
    waveform configuration files for selected simulators or waveform viewers.
    If a testbench is launched in GUI mode (``--gui``) and a waveform view for
    the choosen simulator is found, it's loaded as the default view.
* ``src``
    The source files of PoC's IP cores are stored in this directory. The IP
    cores are grouped by their sub-namespace into sub-directories according to
    the :doc:`sub-namespace tree </IPCores/index>`. See the paragraph below, for
    how IP cores are named and how PoC core names map to the sub-namespace
    hierachy and the resulting sub-namespace directory structure.
* ``tb``
    PoC is shipped with testbenches. All testbenches are categorized and stored
    in sub-directories like the IP core, which is tested.
* ``tcl``
    Supporting Tcl files.
* ``temp``
    A pre-created temporary directors for various tool's intermediate outputs.
    In case of errors in a used vendor tool or in PoC's infrastructure, this
    directory contains intermediate files, log files and report files, which
    can be used to analyze the error.
* ``tools``
    This directory contains miscelaneous files or scripts for external tools
    like emacs, git or text editor syntax highlighting files.

* ``ucf``
    Pre-configured constraint files (\*.ucf, \*.xdc, \*.sdc) for many FPGA
    boards, containing physical (pin, placement) and timing constraints.

* ``xst``
    Configuration files to synthesize PoC modules with Xilinx XST into a
    netlist.


Namespaces and Modules
**********************

Namespaces
==========

PoC uses namespaces and sub-namespaces to categorize all VHDL and Verilog
modules. Despite VHDL doesn't support sub-namespaces yet, PoC already uses
sub-namespaces enforced by a strict naming schema.

**Rules:** |br|
1. Namespace names are lower-case, underscore free, valid VHDL identifiers. |br|
2. A namespace name is unique, but can be part of a entity name.


Module Names
============

Module names are prefixed with its parents namespace name. A module name can
contain underscores to denote implementation variants of a module.

**Rules:** |br|
3. Modul names are valid VHDL identifiers prefixed with its parent namespace's name. |br|
4. The first part of module name must not contain the parents namespace name. |br|


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


Note: Not all sub-namespace parts are include as a prefix in the name, only
the last one.


Signal Names
************

.. todo:: No documentation available.
