
ocram
=====

These are On-Chip RAM (OCRAM) entities...

# Namespace `PoC.mem.ocram`

The namespace `PoC.mem.ocram` offers different on-chip RAM abstractions.


## Package(s)

The package [`ocram`][ocram.pkg] holds all component declarations for this namespace.

```VHDL
library PoC;
use     PoC.ocram.all;
```


## Entities

 - [`ocram_sp`][ocram_sp] is a on-chip RAM with a single port interface.
 - [`ocram_sdp`][ocram_sp] is a on-chip RAM with a simple dual port interface.
 - [`ocram_esdp`][ocram_sp] is a on-chip RAM with a extended simple dual port interface.
 - [`ocram_tdp`][ocram_sp] is a on-chip RAM with a true dual port interface.


 [ocram.pkg]:	https://github.com/VLSI-EDA/PoC/blob/master/src/mem/ocram/ocram.pkg.vhdl
 [ocram_sp]:	https://github.com/VLSI-EDA/PoC/blob/master/src/mem/ocram/ocram_sp.vhdl
 [ocram_sdp]:	https://github.com/VLSI-EDA/PoC/blob/master/src/mem/ocram/ocram_sdp.vhdl
 [ocram_esdp]:	https://github.com/VLSI-EDA/PoC/blob/master/src/mem/ocram/ocram_esdp.vhdl
 [ocram_tdp]:	https://github.com/VLSI-EDA/PoC/blob/master/src/mem/ocram/ocram_tdp.vhdl


.. toctree::
   
   ocram_sp
   ocram_esdp
   ocram_sdp
   ocram_tdp
