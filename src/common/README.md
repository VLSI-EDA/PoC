# Namespace `PoC`

The namespace `PoC` offers different packages.

## Packages

 -  [`config`][config] - implements PoC's configuration mechanism.
 -  [`components`][components] - implements synthesizable functions
    that map to common gates and flip-flops.
 -  [`debug`][debug]
 -  [`fileio`][fileio]
 -  [`math`][math] implements special mathematical functions.
 -  [`physical`][physical] implements new physical types like frequency
    `FREQ`, baudrate and memory. Various type conversion functions are
    provided, too. 
 -  [`simulation`][simulation] 
 -  [`strings`][strings] implements string operations on strings of fixed size.
 -  [`utils`][utils] implements common helper functions
 -  [`vectors`][vectors] declares multi-dimensional vector types and
    implements conversion functions for these types. 

**Usage:**

```VHDL
library PoC;
use     PoC.config.all;
use     PoC.debug.all;
use     PoC.fileio.all;
use     PoC.math.all;
use     PoC.physical.all;
use     PoC.simulation.all;		-- NOT SYNTHESIZIABLE !!
use     PoC.strings.all;
use     PoC.utils.all;
use     PoC.vectors.all;
```


## Context

[`common`][common] offers a VHDL-2008 context for all common PoC packages.


## Templates

 - [`my_config`][my_config]
 - [`my_project`][my_project]


 [config]:			config.vhdl
 [components]:	components.vhdl
 [debug]:				debug.vhdl
 [fileio]:			fileio.vhdl
 [math]:				math.vhdl
 [physical]:		physical.vhdl
 [simulation]:	simulation.vhdl
 [strings]:			strings.vhdl
 [utils]:				utils.vhdl
 [vectors]:			vectors.vhdl

 [common]:			common.vhdl

 [my_config]:		my_config.vhdl.template
 [my_project]:	my_project.vhdl.template
