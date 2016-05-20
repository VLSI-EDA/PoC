Configuring PoC on a Local System (Stand Alone)
***********************************************

To explore PoC's full potential, it's required to configure some paths and synthesis or simulation tool chains. The following commands start a guided
configuration process. Please follow the instructions. It's possible to relaunch the process at every time, for example to register new tools or to update
tool versions. See the `Configuration] for more details.

  All Windows command line instructions are intended for **Windows PowerShell**, if not marked otherwise. So executing the following instructions in Windows
  Command Prompt (``cmd.exe``) won't function or result in errors! See the [Requirements] on where to download or update  PowerShell.

Run the following command line instructions to configure PoC on your local system. ::

    cd <PoCRoot>
    .\poc.ps1 configure

**Note:** The configuration process can be re-run at every time to add, remove or update choices made.

If you want to check your installation, you can run one of our testbenches as described in `tb/README.md]
