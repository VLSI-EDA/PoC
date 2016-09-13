
Why should I use PoC?
#####################

Here is a brief list of advantages:

* We explicitly use the wording *PoC-Library* rather then *collection*, because
  PoC's packages and IP cores build an ecosystem. Complex IP cores are build
  on-top of basic IP cores - they are no lose set of cores. The cores offer a
  clean interface and can be configured by many generic parameters.

* PoC is target independent: It's possible to switch the target device or even
  the device vendor without switching the IP core.


.. TODO::

   Use a well tested set of packages to ease the use of VHDL

   Use a well tested set of simulation helpers

   Run testbenches in various simulators.

   Run synthesis tests in varous synthesis tools.

   Compare hardware usage for different target platfroms.

   Supports simulation with vendor primitive libraries, ships with script to pre-compile vendor libraries.

   Vendor tools have bugs, check you IP cores when a new tool release is available, before changing code base

