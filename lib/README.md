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

## Cocotb

**Folder:**		`<PoCRoot>\lib\cocotb\`  
**Copyright:**	Copyright © 2013, [Potential Ventures Ltd.](http://potential.ventures/), SolarFlare Communications Inc.  
**License:**	Revised BSD License, see [local copy](Cocotb BSD License.md)

[Cocotb][10] is a coroutine based cosimulation library for writing VHDL and Verilog testbenches in Python.

Documentation: [http://cocotb.readthedocs.org/en/latest/index.html][10]
Source: [https://github.com/potentialventures/cocotb][11]

 [10]: http://cocotb.readthedocs.org/en/latest/index.html
 [11]: https://github.com/potentialventures/cocotb


## Open Source VHDL Verification Methodology (OS-VVM)

**Folder:**		`<PoCRoot>\lib\osvvm\`  
**Copyright:**	Copyright © 2012-2016 by [SynthWorks Design Inc.](http://www.synthworks.com/)  
**License:**	[Artistic License 2.0][PAL2.0]

[**Open Source VHDL Verification Methodology (OS-VVM)**][20] is an intelligent
testbench methodology that allows mixing of “Intelligent Coverage” (coverage
driven randomization) with directed, algorithmic, file based, and constrained
random test approaches. The methodology can be adopted in part or in whole as
needed. With OSVVM you can add advanced verification methodologies to your
current testbench without having to learn a new language or throw out your
existing testbench or testbench models.

Website: [http://osvvm.org/][20]
Source:  [https://github.com/JimLewis/OSVVM][21]

 [20]: http://osvvm.org/
 [21]: https://github.com/JimLewis/OSVVM


## Universal VHDL Verification Methodology (UVVM)

**Folder:**		`<PoCRoot>\lib\uvvm\`  
**Copyright:**	Copyright © 2016 by [Bitvis AS](http://bitvis.no/)  
**License:**	[The MIT License (MIT)](UVVM MIT.md)

The Open Source **UVVM (Universal VHDL Verification Methodology) - VVC (VHDL
Verification Component) Framework** for making structured VHDL testbenches
for verification of FPGA. UVVM consists currently of: Utility Library, VVC
Framework and Verification IPs (VIP) for various protocols.

**For what do I need this VVC Framework?**  
The VVC Framework is a VHDL Verification Component system that allows multiple
interfaces on a DUT to be stimulated/handled simultaneously in a very
structured manner, and controlled by a very simple to understand software like
a test sequencer. VVC Framework is unique as an open source VHDL approach to
building a structured testbench architecture using Verification components and
a simple protocol to access these. As an example a simple command like
`uart_expect(UART_VVCT, my_data)`, or `axilite_write(AXILITE_VVCT, my_addr, my_data, my_message)`
will automatically tell the respective VVC (for UART or AXI-Lite) to execute the
`uart_receive()` or `axilite_write()` BFM respectively.

Website: [http://bitvis.no/][30]
Source:  [https://github.com/UVVM/UVVM_All][31]

 [30]: http://bitvis.no/
 [31]: https://github.com/UVVM/UVVM_All


## VUnit

**Folder:**		`<PoCRoot>\lib\vunit\`  
**Copyright:**	Copyright © 2014-2016, Lars Asplund [lars.anders.asplund@gmail.com](mailto://lars.anders.asplund@gmail.com)  
**License:**	[Mozilla Public License, Version 2.0][MPL2.0]

[VUnit][31] is an open source unit testing framework for VHDL released under the
terms of [Mozilla Public License, v. 2.0][MPL2.0]. It features the functionality
needed to realize continuous and automated testing of your VHDL code. VUnit
doesn't replace but rather complements traditional testing methodologies by
supporting a "test early and often" approach through automation.

Website: [https://vunit.github.io/][40]
Source: [https://github.com/VUnit/vunit][41]

 [40]: https://vunit.github.io/
 [41]: https://github.com/VUnit/vunit

 
## Xillybus

**Folder:**		`<PoCRoot>\lib\xillybus\`  
**Copyright:**	TODO
**License:**	TODO, see [local copy](Xillybus License.md)

[xillybus][50] TODO

Documentation: [http://xillybus.com][50]
Source: [http://xillybus.com][51]

 [50]: http://xillybus.com
 [51]: http://xillybus.com


 [PAL2.0]:	http://www.perlfoundation.org/artistic_license_2_0
 [MPL2.0]:	https://www.mozilla.org/en-US/MPL/2.0/
 [AL2.0]:	http://www.apache.org/licenses/LICENSE-2.0
