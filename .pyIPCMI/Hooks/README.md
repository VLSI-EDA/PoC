# pyIPCMI Hook Files

This folder contains "hook files", which are sourced:
  - before (`PreHookFile`) and
  - after (`PostHostFile`)

a pyIPCMI command gets executed with `pyIPCMI.sh` or `pyIPCMI.ps1`. A common use case is the preparation
of special vendor or tool chain environments. E.g. many EDA tools are using FlexLM
as a license manager, which needs the environments variable `LM_LICENSE_FILE` to be
set. A `PreHookFile` can be used to load/export such an environment variable.


## Hook Files

The pyIPCMI's wrapper script parses the command line argument list for a known command. If such
a command is found, a pre- and post load event is triggered for a vendor hook file and a
tool hook file.


#### Example Mentor QuestaSim on Linux:

The pyIPCMI infrastructure is called with this command line:

```Bash
./pyIPCMI.sh -v vsim pyIPCMI.namespace.core
```

The `vsim` command is recognized and the following events are scheduled:

  1. `source ./Mentor.pre.sh`
  2. `source ./Mentor.QuestaSim.pre.sh`
  3. Execute `./py/pyIPCMI.py -v vsim LIB.namespace.core`
  4. `source ./Mentor.QuestaSim.post.sh`
  5. `source ./Mentor.post.sh`

If a hook files doesn't exist, it's skipped.


#### Example Mentor QuestaSim on Windows:

The pyIPCMI infrastructure is called with this command line:

```PowerShell
.\pyIPCMI.ps1 -v vsim LIB.namespace.core
```

The `vsim` command is recognized and the following events are scheduled:

  1. `. .\Mentor.pre.ps1`
  2. `. .\Mentor.QuestaSim.pre.ps1`
  3. Execute `.\py\pyIPCMI.py -v vsim pyIPCMI.namespace.core`
  4. `. .\Mentor.QuestaSim.post.ps1`
  5. `. .\Mentor.post.ps1`

If a hook files doesn't exist, it's skipped.

## FlexLM

Many EDA tools require an environment variable called `LM_LICENSE_FILE`.
If no other tool settings are required, a common `FlexLM.sh` can be
generated. This file is used as a symlink target for each tool specific
hook file. 

**Content of the `FlexLM.sh` script:**

```Bash
export LM_LICENSE_FILE=1234@flexlm.company.com
```

**Create symlinks:**

```Bash
ln -s FlexLM.sh Altera.Quartus.pre.sh
ln -s FlexLM.sh Mentor.QuestaSim.pre.sh
```
