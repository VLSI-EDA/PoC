# Namespace `PoC.bus`

The namespace `PoC.bus` offers different bus specific modules.


## Sub-Namespaces

 - [`PoC.bus.stream`][bus_stream] - Modules for the *PoC.Stream* bus.
 - [`PoC.bus.wb`][bus_wb] - Modules for the [WISHBONE][wishbone] bus.

 [wishbone]:	http://opencores.org/opencores,wishbone


## Package

The package [`PoC.bus`][bus.pkg] holds all component declarations for this namespace.


## Entities

 -  [`bus_Arbiter`][bus_Arbiter] - a generic arbiter implementation with selectable
     port count and arbitration algorithm:
     -  RR - Round Robin
     -  *TODO: implement other algorithms*


 [bus_stream]:			stream
 [bus_wb]:					wb

 [bus.pkg]:					bus.pkg.vhdl

 [bus_Arbiter]:			bus_Arbiter.vhdl
