.. _NS:sdram:

PoC.mem.sdram
=============

The namespace ``PoC.mem.sdram`` offers components for the access of external SDRAMs.
A common finite state-machine is used to address the memory via banks, rows and
columns. Different physical layers are provide for the single-data-rate (SDR) or
double-data-rate (DDR, DDR2, ...) data bus. One has to instantiate the specific
module required by the FPGA board.

.. rubric:: SDRAM Controller for the Altera DE0 Board

The module :ref:`sdram_ctrl_de0 <IP:sdram_ctrl_de0>` combines the finite state machine
:ref:`sdram_ctrl_fsm <IP:sdram_ctrl_fsm>` and the DE0 specific physical layer
:ref:`sdram_ctrl_phy_de0 <IP:sdram_ctrl_phy_de0>`. It has been tested with the
IS42S16400F SDR memory at a frequency of 133 MHz. A usage example
is given in PoC-Examples_.


.. rubric:: SDRAM Controller for the Xilinx Spartan-3E Starter Kit (S3ESK)

The module :ref:`sdram_ctrl_s3esk <IP:sdram_ctrl_s3esk>` combines the finite state
machine :ref:`sdram_ctrl_fsm <IP:sdram_ctrl_fsm>` and the S3ESK specific physical layer
:ref:`sdram_ctrl_phy_s3esk <IP:sdram_ctrl_phy_s3esk>`. It has been tested with the
MT46V32M16-6T DDR memory at a frequency of 100 MHz (DDR-200). A usage
example is given in PoC-Examples_.

.. Note::
   See also :ref:`NS:mig` for board specific memory controller implementations
   created by Xilinx's Memory Interface Generator (MIG).



.. _PoC-Examples: https://github.com/VLSI-EDA/PoC-Examples

.. toctree::
   :hidden:

   sdram_ctrl_fsm <sdram_ctrl_fsm>
   sdram_ctrl_de0 <sdram_ctrl_de0>
   sdram_ctrl_phy_de0 <sdram_ctrl_phy_de0>
   sdram_ctrl_s3esk <sdram_ctrl_s3esk>
   sdram_ctrl_phy_s3esk <sdram_ctrl_phy_s3esk>
