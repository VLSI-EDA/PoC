# Third Party Libraries

The PoC-Library is shiped with different third party libraries, which
are located in the `<PoCRoot>/lib/` folder. This document lists all these
libraries, their websites and licenses.

### Initializing and Updating Embedded Git Submodules

The third party libraries are embedded as git submodules. So if the PoC-Library
was not cloned with option `--recursive` it's rerquired to run sub module
initialization manually.

```PowerShell
cd <PoCRoot>\lib\
git submodule init
git submodule update
cd osvvm\
git remote rename origin github
cd ..\vunit\
git remote rename origin github
cd ..
```  


## Open Source VHDL Verification Methodology (OS-VVM)

**Folder:**		`<PoCRoot>\lib\osvvm\`  
**Copyright:**	Copyright © 2012-2015 by [SynthWorks Design Inc.](http://www.synthworks.com/)  
**License:**	[Artistic License 2.0][PAL2.0]

[**Open Source VHDL Verification Methodology (OS-VVM)**][11] is an intelligent testbench methodology that allows mixing of “Intelligent Coverage” (coverage driven randomization) with directed, algorithmic, file based, and constrained random test approaches. The methodology can be adopted in part or in whole as needed. With OSVVM you can add advanced verification methodologies to your current testbench without having to learn a new language or throw out your existing testbench or testbench models.

Source: [http://osvvm.org/about-os-vvm](http://osvvm.org/about-os-vvm)

 [11]: http://osvvm.org/


## VUnit

**Folder:**		`<PoCRoot>\lib\vunit\`  
**Copyright:**	Copyright © 2014-2015, Lars Asplund [lars.anders.asplund@gmail.com](mailto://lars.anders.asplund@gmail.com)  
**License:**	[Mozilla Public License, Version 2.0][MPL2.0]

[VUnit][21] is an open source unit testing framework for VHDL released under the terms of [Mozilla Public License, v. 2.0][MPL2.0]. It features the functionality needed to realize continuous and automated testing of your VHDL code. VUnit doesn't replace but rather complements traditional testing methodologies by supporting a "test early and often" approach through automation.

Source: [https://github.com/LarsAsplund/vunit][21]

 [21]: https://github.com/LarsAsplund/vunit


 [PAL2.0]:	http://www.perlfoundation.org/artistic_license_2_0
 [MPL2.0]:	https://www.mozilla.org/en-US/MPL/2.0/
 [AL2.0]:	http://www.apache.org/licenses/LICENSE-2.0
