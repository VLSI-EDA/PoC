# Namespace `PoC.mem.ocrom`

The namespace `PoC.mem.ocrom` offers different on-chip ROM abstractions.


## Package(s)

The package [`ocrom`][ocrom.pkg] holds all component declarations for this namespace.

```VHDL
library PoC;
use     PoC.ocrom.all;
```


## Entities

 - [`ocrom_sp`][ocrom_sp] is a on-chip RAM with a single port interface.
 - [`ocrom_dp`][ocrom_dp] is a on-chip RAM with a dual port interface.


 [ocrom.pkg]:	ocrom.pkg.vhdl
 [ocrom_sp]:	ocrom_sp.vhdl
 [ocrom_dp]:	ocrom_dp.vhdl
