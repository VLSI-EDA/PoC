# Namespace `PoC.misc`

The namespace `PoC.misc` offers different yet uncategorized entities.


## Sub-Namespaces

 -  [`PoC.misc.filter`][misc_filter] - contains 1-bit filter algorithms.
 -  [`PoC.misc.gearbox`][misc_gearbox] - contains gearbox implementations.
    A gearbox is a bus interface converter, that resizes an input stream of
    `INPUT_BITS` to an output stream of `OUTPUT_BITS`, while maintaining a
    constant transfer rate. This can be done by
    multipliing or dividing the clock frequency (`dc` - dependent clock
    interface) or by using the same clock (`cc` - common clock interface)
 -  [`PoC.misc.stat`][misc_stat] - contains statistic modules.
 -  [`PoC.misc.sync`][misc_sync] - offers clock-domain-crossing (CDC) modules.


## Package

The package [`PoC.misc`][misc.pkg] holds all component declarations for this namespace.


## Entities

 -  [`misc_Delay`][misc_Delay]
 -  [`misc_FrequencyMeasurement`][misc_FrequencyMeasurement] - implements a module to
    measure a signal's frequency relative to a reference clock's frequency.
 -  [`misc_bit_lz`][misc_bit_lz]


 [misc_filter]:		filter
 [misc_gearbox]:	gearbox
 [misc_stat]:		stat
 [misc_sync]:		sync

 [misc.pkg]:		misc.pkg.vhdl

 [misc_Delay]: misc_Delay.vhdl
 [misc_FrequencyMeasurement]:	misc_FrequencyMeasurement.vhdl
 [misc_bit_lz]: misc_bit_lz.vhdl
