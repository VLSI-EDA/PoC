# Namespace `PoC.mem`

The namespace `PoC.mem` offers different on-chip and off-chip memory and memory-controller
implementations.


## Sub-Namespace(s)

 - [`PoC.mem.ddr3`][mem_ddr3] - Adapter and Wrapper for DDR3 controllers
 - [`PoC.mem.ddr2`][mem_ddr2] - Adapter and Wrapper for DDR3 controllers
 - [`PoC.mem.is61lv`][mem_is61lv] - ISSI - IS61LV SRAM controller
 - [`PoC.mem.is61nlp`][mem_is61nlp] - ISSI - IS61NLP SRAM controller
 - [`PoC.mem.lut`][mem_lut] - Lookup-Table (LUT) implementations
 - [`PoC.mem.ocram`][mem_ocram] - On-Chip RAM abstraction layer
 - [`PoC.mem.ocrom`][mem_ocrom] - On-Chip ROM abstraction layer
 - [`PoC.mem.sdram`][mem_sdram] - SDRAM controllers


## Package

The package [`PoC.mem`][mem.pkg] holds all component declarations for this namespace.


 [mem.pkg]:				mem.pkg.vhdl
 
 [mem_ddr3]:		ddr3
 [mem_is61lv]:		is61lv
 [mem_is61nlp]:		is61nlp
 [mem_lut]:				lut
 [mem_ocram]:			ocram
 [mem_ocrom]:			ocrom
 [mem_sdram]:			sdram
