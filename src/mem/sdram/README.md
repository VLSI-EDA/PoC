# Namespace `PoC.mem.sdram`

The namespace PoC.mem.sdram offers components for the access of external SDRAMs.
A common finite state-machine is used to address the memory via banks, rows and
columns. Different physical layers are provide for the single-data-rate (SDR) or
double-data-rate (DDR, DDR2, ...) data bus. One has to instantiate the specific
module required by the FPGA board.
 

## Entities

#### SDRAM Controller for the Altera DE0 Board

The module [`sdram_ctrl_de0`][sdram_ctrl_de0] combines the finite state machine
[`sdram_ctrl_fsm`][sdram_ctrl_fsm] and the DE0 specific physical layer
[`sdram_ctrl_phy_de0`][sdram_ctrl_phy_de0]. It has been tested with the
IS42S16400F SDR memory at a frequency of 133 MHz. A [usage example][ex_mem_sdram]
is given in [PoC-Examples][PoCEx].


#### SDRAM Controller for the Xilinx Spartan-3E Starter Kit (S3ESK)

The module [`sdram_ctrl_s3esk`][sdram_ctrl_s3esk] combines the finite state
machine [`sdram_ctrl_fsm`][sdram_ctrl_fsm] and the S3ESK specific physical layer
[`sdram_ctrl_phy_s3esk`][sdram_ctrl_phy_s3esk]. It has been tested with the
MT46V32M16-6T DDR memory at a frequency of 100 MHz (DDR-200). A [usage
example][ex_mem_sdram] is given in [PoC-Examples][PoCEx].

 [PoCEx]:									https://github.com/VLSI-EDA/PoC-Examples
 [ex_mem_sdram]:					https://github.com/VLSI-EDA/PoC-Examples/tree/master/src/mem/sdram
 [sdram_ctrl_fsm]:				sdram_ctrl_fsm.vhdl
 [sdram_ctrl_de0]:				sdram_ctrl_de0.vhdl
 [sdram_ctrl_phy_de0]:		sdram_ctrl_phy_de0.vhdl
 [sdram_ctrl_s3esk]:			sdram_ctrl_s3esk.vhdl
 [sdram_ctrl_phy_s3esk]:	sdram_ctrl_phy_s3esk.vhdl
