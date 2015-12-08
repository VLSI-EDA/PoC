# Namespace `PoC.comm`

The namespace `PoC.comm` offers different communication modules.


## Package(s)

The package [`comm`][comm.pkg] holds all component declarations for this namespace.

```VHDL
library PoC;
use     PoC.comm.all;
```

## Entities

 - [`comm_crc`][comm_crc] implements a generic Cyclic Redundancy Check (CRC).
 - [`comm_scramble`][comm_scramble] implements a generic LFSR based scrambler.


 [comm.pkg]:			comm.pkg.vhdl

 [comm_crc]:			comm_crc.vhdl
 [comm_scramble]:		comm_scramble.vhdl
