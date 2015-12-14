# Constraint Files

**The PoC-Library** ships constraint files in the following formats:
 -  User Constraint Files (*.ucf) for Xilinx ISE &le;14.7
 -  Xilinx Design Constraints (*.xdc) for Xilinx Vivado
 -  Synopsis Design Constraints (*.sdc) for Altera Quartus-II

## Constraints for PoC Entities

 -  PoC.misc.sync
     - `sync_Bits_Xilinx.ucf`
     - `sync_Reset_Xilinx.ucf`
 -  PoC.net.eth
     - `eth_RSLayer_GMII_GMII_ML605.ucf`
     - `eth_RSLayer_GMII_GMII_ML605.ucf`
     - `eth_RSLayer_GMII_GMII_KC705.ucf`
 -  [`MetaStability.ucf`][ucf_MetaStability]


## Constraints for Evaluation Boards

 -  Cyclone Boards
     -  [`DE0`][brd_de0]
 -  Stratix Boards
     -  [`DE4`][brd_de4]
     -  [`DE5`][brd_de5]
 -  Spartan Boards
     -  [`S3SK`][brd_s3sk]
     -  [`S3ESK`][brd_s3esk]
     -  [`Atlys`][brd_atlys]
 -  Artix Boards
 -  Kintex Boards
     -  [`KC705`][brd_kc705]
 -  Virtex Boards
     -  [`ML505`][brd_ml505]
     -  [`XUPV5`][brd_xupv5]
     -  [`ML605`][brd_ml605]
     -  [`VC707`][brd_vc707]
 -  Zynq Boards
     -  [`ZedBoard`][brd_zedboard]
     -  [`ZC706`][brd_zc706]



 [brd_de0]:					DE0
 [brd_de4]:					DE4
 [brd_de5]:					DE5
 [brd_s3sk]:				S3SK
 [brd_s3esk]:				S3ESK
 [brd_atlys]:				Atlys
 [brd_kc705]:				KC705
 [brd_ml505]:				ML505
 [brd_xupv5]:				XUPV5
 [brd_ml605]:				ML605
 [brd_vc707]:				VC707
 [brd_zc706]:				ZC706

 [ucf_MetaStability]:	MetaStability.ucf
