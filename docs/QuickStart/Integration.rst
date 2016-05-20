Integrating PoC into Projects
*****************************

**The PoC-Library** is meant to be integrated into HDL projects. Therefore it's recommended to create a library folder and add the PoC-Library as a git
submodule. After the repository linking is done, some short configuration steps are required to setup paths and tool chains. The following command line
instructions show a short example on how to integrate PoC. A detailed list of steps can be found on the `Integration] page.

Adding the Library as a git submodule
=========================================

The following command line instructions will create the folder ``lib\PoC\`` and clone
the PoC-Library as a git [submodule] into that folder.

.. code-block:: powershell

   cd <ProjectRoot>
   mkdir lib | cd
   git submodule add git@github.com:VLSI-EDA/PoC.git PoC
   cd PoC
   git remote rename origin github
   cd ..\..
   git add .gitmodules lib\PoC
   git commit -m "Added new git submodule PoC in 'lib\PoC' (PoC-Library)."

.. http://git-scm.com/book/en/v2/Git-Tools-Submodules

Configuring PoC
===================

**The PoC-Library** needs to be configured.

.. code-block:: powershell
   
   cd <ProjectRoot>
   cd lib\PoC\
   .\poc.ps1 configure


Creating PoC's my_config and my_project Files
=================================================

**The PoC-Library** needs two VHDL files for it's configuration. These files are used to determine the most suitable implementation depending on the provided
platform information. Copy these two template files into your project's source folder. Rename these files to *.vhdl and configure the VHDL constants in these
files.

.. code-block:: powershell
   
   cd <ProjectRoot>
   cp lib\PoC\src\common\my_config.vhdl.template src\common\my_config.vhdl
   cp lib\PoC\src\common\my_project.vhdl.template src\common\my_project.vhdl

``my_config.vhdl`` defines two global constants, which need to be adjusted:

.. code-block:: vhdl
   
   constant MY_BOARD            : string := "CHANGE THIS"; -- e.g. Custom, ML505, KC705, Atlys
   constant MY_DEVICE           : string := "CHANGE THIS"; -- e.g. None, XC5VLX50T-1FF1136, EP2SGX90FF1508C3

``my_project.vhdl`` also defines two global constants, which need to be adjusted:

.. code-block:: vhdl
   
   constant MY_PROJECT_DIR      : string := "CHANGE THIS"; -- e.g. d:/vhdl/myproject/, /home/me/projects/myproject/"
   constant MY_OPERATING_SYSTEM : string := "CHANGE THIS"; -- e.g. WINDOWS, LINUX


Compile shipped Xilinx IP cores (*.xco files) to Netlists
=============================================================

**The PoC-Library** is shipped with some pre-configured IP cores from Xilinx. These IP cores are shipped as \*.xco files and need to be compiled to netlists
(\*.ngc files) and there auxillary files (\*.ncf files; \*.vhdl files; ...). This can be done by invoking PoC's Service Tool through one of the provided wrapper
scripts: ``poc.[sh|ps1]``.

The following example compiles ``PoC.xil.ChipScopeICON_1`` from ``<PoCRoot>\src\xil\xil_ChipScopeICON_1.xco`` for a Kintex-7 325T device into
``<PoCRoot>/netlist/XC7K325T-2FFG900/xil/``.

.. code-block:: powershell
   
   cd <PoCRoot>/netlist
   ..\poc.ps1 coregen PoC.xil.ChipScopeICON_1 --board=KC705
