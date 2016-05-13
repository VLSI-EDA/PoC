# Namespace `PoC`

The namespace `PoC` offers common packages.

## Packages

 -  [`PoC.config`][config] - implements PoC's configuration mechanism.
 -  [`PoC.components`][components] - implements synthesizable functions
    that map to common gates and flip-flops.
 -  [`PoC.debug`][debug]
 -  [`PoC.fileio`][fileio]
 -  [`PoC.math`][math] - implements special mathematical functions.
 -  [`PoC.physical`][physical] - implements new physical types like frequency
    `FREQ`, baudrate and memory. Various type conversion functions are
    provided, too. 
 -  [`PoC.strings`][strings] - implements string operations on strings of fixed size.
 -  [`PoC.utils`][utils] - implements common helper functions
 -  [`PoC.vectors`][vectors] - declares multi-dimensional vector types and
    implements conversion functions for these types. 

**Usage:**

```VHDL
library PoC;
use     PoC.config.all;
use     PoC.debug.all;
use     PoC.fileio.all;       -- If supported by the vendor tool
use     PoC.math.all;
use     PoC.physical.all;
use     PoC.strings.all;
use     PoC.utils.all;
use     PoC.vectors.all;
```


## Context

[`PoC.common`][common] offers a VHDL-2008 context for all common PoC packages.


## Templates

 - [`PoC.my_config`][my_config]
 - [`PoC.my_project`][my_project]


 [config]:			config.vhdl
 [components]:	components.vhdl
 [debug]:				debug.vhdl
 [fileio]:			fileio.vhdl
 [math]:				math.vhdl
 [physical]:		physical.vhdl
 [strings]:			strings.vhdl
 [utils]:				utils.vhdl
 [vectors]:			vectors.vhdl

 [common]:			common.vhdl

 [my_config]:		my_config.vhdl.template
 [my_project]:	my_project.vhdl.template
