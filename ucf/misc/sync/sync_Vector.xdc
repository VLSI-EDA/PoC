# This XDC file must be directly applied to all instances of sync_Vector.
# To achieve this, set property SCOPED_TO_REF to sync_Vector within the Vivado project.
# Load XDC file defining the clocks before this XDC file by using the property PROCESSING_ORDER.
# Also load sync_Bits_Xilinx.xdc as described within that file.

# set max delay between data register D0 and D4 to lower clock period
set_max_delay  -from [get_cells -regexp {D0_reg\[\d+\]}] -to [get_cells -regexp {D4_reg\[\d+\]}] -datapath_only [expr "min([get_property period [get_clocks -of_objects [get_pins {D0_reg[0]/C}]]], [get_property period [get_clocks -of_objects [get_pins {D4_reg[0]/C}]]])"]
