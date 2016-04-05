# Third Party Libraries

**The PoC-Library** is shiped with different third party libraries, which
are located in the `<PoCRoot>/lib/` folder. This document lists all these
libraries, their websites and licenses.

### Initializing and Updating Embedded Git Submodules

The third party libraries are embedded as git submodules. So if the PoC-Library
was not cloned with option `--recursive` it's required to run the sub module
initialization manually:

```PowerShell
cd <PoCRoot>\lib\
git submodule init
git submodule update
foreach($dir in (dir -Directory)) {
  cd $dir
  git remote rename origin github
  cd ..
}
```  


## Open Source VHDL Verification Methodology (OS-VVM)

**Folder:**		`<PoCRoot>\lib\osvvm\`  
**Copyright:**	Copyright © 2012-2016 by [SynthWorks Design Inc.](http://www.synthworks.com/)  
**License:**	[Artistic License 2.0][PAL2.0]

[**Open Source VHDL Verification Methodology (OS-VVM)**][10] is an intelligent
testbench methodology that allows mixing of “Intelligent Coverage” (coverage
driven randomization) with directed, algorithmic, file based, and constrained
random test approaches. The methodology can be adopted in part or in whole as
needed. With OSVVM you can add advanced verification methodologies to your
current testbench without having to learn a new language or throw out your
existing testbench or testbench models.

Website: [http://osvvm.org/][10]
Source:  [https://github.com/JimLewis/OSVVM][11]

 [10]: http://osvvm.org/
 [11]: https://github.com/JimLewis/OSVVM


## VUnit

**Folder:**		`<PoCRoot>\lib\vunit\`  
**Copyright:**	Copyright © 2014-2016, Lars Asplund [lars.anders.asplund@gmail.com](mailto://lars.anders.asplund@gmail.com)  
**License:**	[Mozilla Public License, Version 2.0][MPL2.0]

[VUnit][31] is an open source unit testing framework for VHDL released under the
terms of [Mozilla Public License, v. 2.0][MPL2.0]. It features the functionality
needed to realize continuous and automated testing of your VHDL code. VUnit
doesn't replace but rather complements traditional testing methodologies by
supporting a "test early and often" approach through automation.

Website: [https://vunit.github.io/][30]
Source: [https://github.com/VUnit/vunit][31]

 [30]: https://vunit.github.io/
 [31]: https://github.com/VUnit/vunit

## Cocotb

**Folder:**		`<PoCRoot>\lib\cocotb\`  
**Copyright:**	Copyright © 2013, [Potential Ventures Ltd.](http://potential.ventures/), SolarFlare Communications Inc.  
**License:**	Revised BSD License, see [local copy](Cocotb BSD License.md)

[Cocotb][40] is a coroutine based cosimulation library for writing VHDL and Verilog testbenches in Python.

Documentation: [http://cocotb.readthedocs.org/en/latest/index.html][40]
Source: [https://github.com/potentialventures/cocotb][41]

 [40]: http://cocotb.readthedocs.org/en/latest/index.html
 [41]: https://github.com/potentialventures/cocotb


 [PAL2.0]:	http://www.perlfoundation.org/artistic_license_2_0
 [MPL2.0]:	https://www.mozilla.org/en-US/MPL/2.0/
 [AL2.0]:	http://www.apache.org/licenses/LICENSE-2.0
