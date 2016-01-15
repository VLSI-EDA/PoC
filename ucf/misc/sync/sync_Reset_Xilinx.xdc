# This XDC file must be directly applied to all instances of sync_Reset_Xilinx.
# To achieve this, set property SCOPED_TO_REF to sync_Reset_Xilinx within the Vivado project.
# Load XDC file defining the clocks before this XDC file by using the property PROCESSING_ORDER.
set_property ASYNC_REG true [get_cells {FF2_METASTABILITY_FFS FF3_METASTABILITY_FFS}]
set_false_path -from [all_clocks] -to  [get_pins FF2_METASTABILITY_FFS/PRE]
set_false_path -from [all_clocks] -to  [get_pins FF3_METASTABILITY_FFS/PRE]
