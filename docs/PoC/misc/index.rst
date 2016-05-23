
misc
====

These are misc entities....

# Namespace `PoC.misc`

The namespace `PoC.misc` offers different yet uncathegorized entities.


## Sub-Namespace(s)

 -  [`PoC.misc.filter`][misc_filter] contains 1-bit filter algorithms.
 -  [`PoC.misc.stat`][misc_stat] contains statistic modules.
 -  [`PoC.misc.sync`][misc_sync] offers clock-domain-crossing (CDC) modules.


## Package(s)

The package [`misc`][misc.pkg] holds all component declarations for this namespace.

```VHDL
library PoC;
use     PoC.misc.all;
```


## Entities



 [misc.pkg]:		https://github.com/VLSI-EDA/PoC/blob/master/src/misc/misc.pkg.vhdl

 [misc_filter]:		src_misc_filter
 [misc_stat]:		src_misc_stat
 [misc_sync]:		src_misc_sync



.. toctree::
   
   filter/index
   gearbox/index
   stat/index
   sync/index
