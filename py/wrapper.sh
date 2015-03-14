#! /bin/bash
# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
#	Authors:				 	Patrick Lehmann
#										Thomas B. Preusser
#										Martin Zabel
# 
#	Bash Script:			Wrapper Script to execute a given python script
# 
# Description:
# ------------------------------------
#	This is a bash script (callable) which:
#		- 
#		- 
#		-
#
# License:
# ==============================================================================
# Copyright 2007-2015 Technische Universitaet Dresden - Germany
#											Chair for VLSI-Design, Diagnostics and Architecture
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#		http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================

# script settings
PoC_ExitCode=0
PoC_PythonScriptDir=py

# define color escape codes
RED='\e[0;31m'			# Yellow
YELLOW='\e[1;33m'		# Yellow
NOCOLOR='\e[0m'			# No Color


PoC_WorkingDir=$(pwd)

# publish PoC directories as environment variables
export PoCScriptDirectory=$PyWrapper_ScriptDir
export PoCRootDirectory=$PoC_RootDir_AbsPath
export PoCWorkingDirectory=$PoC_WorkingDir

if [ $PyWrapper_Debug -eq 1 ]; then
	echo -e "${YELLOW}This is the PoC Library script wrapper operating in debug mode.${NOCOLOR}"
	echo
	echo -e "${YELLOW}Directories:${NOCOLOR}"
	echo -e "${YELLOW}  Script root:   $PyWrapper_ScriptDir${NOCOLOR}"
	echo -e "${YELLOW}  PoC root:      $PoC_RootDir_AbsPath${NOCOLOR}"
	echo -e "${YELLOW}  working:       $PoC_WorkingDir${NOCOLOR}"
	echo -e "${YELLOW}Script:${NOCOLOR}"
	echo -e "${YELLOW}  Filename:      $PyWrapper_Script${NOCOLOR}"
	echo -e "${YELLOW}  Parameters:    $PyWrapper_Paramters${NOCOLOR}"
	echo -e "${YELLOW}Load Environment:${NOCOLOR}"
	echo -e "${YELLOW}  Xilinx ISE:    $PyWrapper_LoadEnv_ISE${NOCOLOR}"
	echo -e "${YELLOW}  Xilinx VIVADO: $PyWrapper_LoadEnv_Vivado${NOCOLOR}"
	echo
fi

# find suitable python version or abort execution
Python_VersionTest='import sys; sys.exit(not (0x03040000 < sys.hexversion < 0x04000000))'
python -c $Python_VersionTest 2>/dev/null
if [ $? -eq 0 ]; then
	Python_Interpreter=$(which python 2>/dev/null)
	if [ $PyWrapper_Debug -eq 1 ]; then echo -e "${YELLOW}PythonInterpreter: use standard interpreter: '$Python_Interpreter'${NOCOLOR}"; fi
else
	# standard python interpreter is not suitable, try to find a suitable version manually
	for pyVersion in 3.9 3.8 3.7 3.6 3.5 3.4; do
		Python_Interpreter=$(which python$pyVersion 2>/dev/null)
		# if ExitCode = 0 => version found
		if [ $? -eq 0 ]; then
			# redo version test
			$Python_Interpreter -c $Python_VersionTest 2>/dev/null
			if [ $? -eq 0 ]; then break; fi
		fi
	done
	if [ $PyWrapper_Debug -eq 1 ]; then echo -e "${YELLOW}PythonInterpreter: use this interpreter: '$Python_Interpreter'${NOCOLOR}"; fi
fi
# if no interpreter was found => exit
if [ ! $Python_Interpreter ]; then
	echo 1>&2 -e "${RED}No suitable Python interpreter found.${NOCOLOR}"
	echo 1>&2 -e "${RED}The script requires Python >= $PyWrapper_MIN_VERSION${NOCOLOR}"
	PoC_ExitCode=1
fi

# load Xilinx ISE environment
if [ $PoC_ExitCode -eq 0 ]; then
	if [ $PyWrapper_LoadEnv_ISE -eq 1 ]; then
		# if $XILINX environment variable is not set
		if [ -z "$XILINX" ]; then
			command="$Python_Interpreter $PoC_RootDir_AbsPath/py/Configuration.py --ise-settingsfile"
			if [ $PyWrapper_Debug -eq 1 ]; then echo -e "${YELLOW}getting ISE settings file: command='$command'${NOCOLOR}"; fi
			PoC_ISE_SettingsFile=$($command)
			if [ $? -eq 0 ]; then
				if [ $PyWrapper_Debug -eq 1 ]; then echo -e "${YELLOW}ISE settings file: '$PoC_ISE_SettingsFile'${NOCOLOR}"; fi
				if [ ! $PoC_ISE_SettingsFile ]; then
					echo 1>&2 -e "${RED}No Xilinx ISE installation found.${NOCOLOR}"
					echo 1>&2 -e "${RED}Run 'PoC.py --configure' to configure your Xilinx ISE installation.${NOCOLOR}"
					PoC_ExitCode=1
				fi
				echo -e "${YELLOW}Loading Xilinx ISE environment '$PoC_ISE_SettingsFile'${NOCOLOR}"
				PyWrapper_RescueArgs=$@
				set --
				source "$PoC_ISE_SettingsFile"
				set -- $PyWrapper_RescueArgs
			else
				echo 1>&2 -e "${RED}ERROR: ExitCode for '$command' was not zero. Aborting script execution.${NOCOLOR}"
				echo 1>&2 -e "${RED}$PoC_Vivado_SettingsFile${NOCOLOR}"
				PoC_ExitCode=1
			fi
		fi
	fi
fi

# load Xilinx Vivado environment
if [ $PoC_ExitCode -eq 0 ]; then
	if [ $PyWrapper_LoadEnv_Vivado -eq 1 ]; then
		# if $XILINX environment variable is not set
		if [ -z "$XILINX" ]; then
			command="$Python_Interpreter $PoC_RootDir_AbsPath/py/Configuration.py --vivado-settingsfile"
			if [ $PyWrapper_Debug -eq 1 ]; then echo -e "${YELLOW}getting Vivado settings file: command='$command'${NOCOLOR}"; fi
			PoC_Vivado_SettingsFile=$($command)
			if [ $? -eq 0 ]; then
				if [ $PyWrapper_Debug -eq 1 ]; then echo -e "${YELLOW}Vivado settings file: '$PoC_Vivado_SettingsFile'${NOCOLOR}"; fi
				if [ ! $PoC_Vivado_SettingsFile ]; then
					echo 1>&2 -e "${RED}No Xilinx Vivado installation found.${NOCOLOR}"
					echo 1>&2 -e "${RED}Run 'PoC.py --configure' to configure your Xilinx Vivado installation.${NOCOLOR}"
					PoC_ExitCode=1
				fi
				echo -e "${YELLOW}Loading Xilinx Vivado environment '$PoC_Vivado_SettingsFile'${NOCOLOR}"
				PyWrapper_RescueArgs=$@
				set --
				source "$PoC_Vivado_SettingsFile"
				set -- $PyWrapper_RescueArgs
			else
				echo 1>&2 -e "${RED}ERROR: ExitCode for '$command' was not zero. Aborting script execution.${NOCOLOR}"
				echo 1>&2 -e "${RED}$PoC_Vivado_SettingsFile${NOCOLOR}"
				PoC_ExitCode=1
			fi
		fi
	fi
fi

# execute script with appropriate python interpreter and all given parameters
if [ $PoC_ExitCode -eq 0 ]; then
	Python_Script="$PoC_RootDir_AbsPath/$PoC_PythonScriptDir/$PyWrapper_Script"
	Python_ScriptParameters=$PyWrapper_Paramters
	
	if [ $PyWrapper_Debug -eq 1 ]; then
		echo -e "${YELLOW}launching: '$Python_Interpreter $Python_Script $Python_ScriptParameters'${NOCOLOR}"
		echo -e "${YELLOW}------------------------------------------------------------${NOCOLOR}"
	fi
	
	# launching python script
	exec $Python_Interpreter $Python_Script $Python_ScriptParameters
fi

# clean up environment variables
unset PoCScriptDirectory
unset PoCRootDirectory
unset PoCWorkingDirectory
