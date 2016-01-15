# This XDC file must be directly applied to all instances of fifo_ic_got.
# To achieve this, set property SCOPED_TO_REF to fifo_ic_got within the Vivado project.
# Load XDC file defining the clocks before this XDC file by using the property PROCESSING_ORDER.

# set max delay between register IPz and IPs to lower clock period
set_max_delay  -from [get_cells -regexp {IPz_reg\[\d+\]}] -to [get_cells -regexp {IPs_reg\[\d+\]}] -datapath_only [expr "min([get_property period [get_clocks -of_objects [get_pins {IPz_reg[0]/C}]]], [get_property period [get_clocks -of_objects [get_pins {IPs_reg[0]/C}]]])"]

# set max delay between regfile write and read side lower clock period
# TODO a critical warning is issued if DATA_REG = false
set_max_delay  -from [get_cells -regexp {gSmall\.regfile.*/RAM.*}] -to [get_cells -regexp {gSmall\.do_reg\[\d+\]}] -datapath_only [expr "min([get_property period [get_clocks -of_objects [get_pins {IPz_reg[0]/C}]]], [get_property period [get_clocks -of_objects [get_pins {IPs_reg[0]/C}]]])"]
# TODO a critical warning is issued if DATA_REG = false, or DATA_REG = true, but RAM is small and mapped to LUTs
set_max_delay  -from [get_cells -regexp {gLarge\.ram/gInfer.ram_reg.*/RAM.*}] -to [get_cells -regexp {gLarge\.ram/gInfer\.q_reg\[\d+\]}] -datapath_only [expr "min([get_property period [get_clocks -of_objects [get_pins {IPz_reg[0]/C}]]], [get_property period [get_clocks -of_objects [get_pins {IPs_reg[0]/C}]]])"]

# set max delay between register OP0 and OPs to lower clock period
set_max_delay  -from [get_cells -regexp {OP0_reg\[\d+\]}] -to [get_cells -regexp {OPs_reg\[\d+\]}] -datapath_only [expr "min([get_property period [get_clocks -of_objects [get_pins {OP0_reg[0]/C}]]], [get_property period [get_clocks -of_objects [get_pins {OPs_reg[0]/C}]]])"]
