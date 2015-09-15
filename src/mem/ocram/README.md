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


 [ocram.pkg]:	ocram.pkg.vhdl
 [ocram_sp]:	ocram_sp.vhdl
 [ocram_sdp]:	ocram_sdp.vhdl
 [ocram_esdp]:	ocram_esdp.vhdl
 [ocram_tdp]:	ocram_tdp.vhdl
