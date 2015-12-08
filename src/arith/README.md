# Namespace `PoC.arith`

The namespace `PoC.arith` offers different arithmetic implementations.


## Package(s)

The package [`arith`][arith.pkg] holds all component declarations for this namespace.

```VHDL
library PoC;
use     PoC.arith.all;
```

## Entities

 - [`arith_addw`][arith_addw]
 - [`arith_convert_bin2bcd`][arith_convert_bin2bcd]
 - [`arith_counter_bcd`][arith_counter_bcd] implements a BCD (Binary Coded Dicimal) counter.
 - [`arith_counter_free`][arith_counter_free]
 - [`arith_counter_gray`][arith_counter_gray] implements a Gray-Code counter.
 - [`arith_counter_ring`][arith_counter_ring] implements a ring (Johnson) counter.
 - [`arith_div`][arith_addw]
 - [`arith_firstone`][arith_firstone]
 - [`arith_muls_wide`][arith_muls_wide]
 - [`arith_prefix_and`][arith_prefix_and]
 - [`arith_prefix_or`][arith_prefix_or]
 - [`arith_prng`][arith_prng] implements a Pseudo Random Number Generator (PRNG).
 - [`arith_same`][arith_same]
 - [`arith_scaler`][arith_scaler]
 - [`arith_shifter_barrel`][arith_shifter_barrel]
 - [`arith_sqrt`][arith_sqrt]


 [arith.pkg]:				arith.pkg.vhdl

 [arith_addw]:				arith_addw.vhdl
 [arith_convert_bin2bcd]:	arith_convert_bin2bcd.vhdl
 [arith_counter_bcd]:		arith_counter_bcd.vhdl
 [arith_counter_free]:		arith_counter_freev
 [arith_counter_gray]:		arith_counter_gray.vhdl
 [arith_counter_ring]:		arith_counter_ring.vhdl
 [arith_div]:				arith_addw.vhdl
 [arith_firstone]:			arith_firstone.vhdl
 [arith_muls_wide]:			arith_muls_wide.vhdl
 [arith_prefix_and]:		arith_addw.vhdl
 [arith_prefix_or]:			arith_addw.vhdl
 [arith_prng]:				arith_prng.vhdl
 [arith_same]:				arith_same.vhdl
 [arith_scaler]:			arith_scaler.vhdl
 [arith_shifter_barrel]:	arith_shifter_barrel.vhdl
 [arith_sqrt]:				arith_sqrt.vhdl
