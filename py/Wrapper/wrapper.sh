# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
#	Authors:				Patrick Lehmann
#							Thomas B. Preusser
#							Martin Zabel
#
#	Bash Script:			Wrapper Script to execute a given Python script
#
# Description:
# ------------------------------------
#	This is a bash script (callable) which:
#		- checks for a minimum installed Python version
#		- loads vendor environments before executing the Python programs
#
# License:
# ==============================================================================
# Copyright 2007-2016 Technische Universitaet Dresden - Germany
#                     Chair of VLSI-Design, Diagnostics and Architecture
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================

# script settings
PoC_ExitCode=0
PoC_WorkingDir=$(pwd)
PoC_PythonScriptDir="py"
PoC_FrontEnd="$PoC_RootDir/$PoC_PythonScriptDir/PoC.py"
PoC_WrapperDirectory="$PoC_PythonScriptDir/Wrapper"
PoC_HookDirectory="$PoC_WrapperDirectory/Hooks"

# define color escape codes
RED='\e[0;31m'			# Red
YELLOW='\e[1;33m'		# Yellow
NOCOLOR='\e[0m'			# No Color

# set default values
PyWrapper_Debug=0

# Aldec tools
declare -A Env_Aldec=(
	["PreHookFile"]="Aldec.pre.sh"
	["PostHookFile"]="Aldec.post.sh"
	["Tools"]="ActiveHDL RevieraPRO"
)
declare -A Env_Aldec_ActiveHDL=(
	["Load"]=0
	["Commands"]="asim"
	["BashModule"]="Aldec.ActiveHDL.sh"
	["PreHookFile"]="Aldec.ActiveHDL.pre.sh"
	["PostHookFile"]="Aldec.ActiveHDL.post.sh"
)
declare -A Env_Aldec_RevieraPRO=(
	["Load"]=0
	["Commands"]="rpro"
	["BashModule"]="Aldec.RevieraPRO.sh"
	["PreHookFile"]="Aldec.RevieraPRO.pre.sh"
	["PostHookFile"]="Aldec.RevieraPRO.post.sh"
)
# Altera tools
declare -A Env_Altera=(
	["PreHookFile"]="Altera.pre.sh"
	["PostHookFile"]="Altera.post.sh"
	["Tools"]="Quartus"
)
declare -A Env_Altera_Quartus=(
	["Load"]=0
	["Commands"]="quartus"
	["BashModule"]="Altera.Quartus.sh"
	["PreHookFile"]="Altera.Quartus.pre.sh"
	["PostHookFile"]="Altera.Quartus.post.sh"
)
# GHDL + GTKWave
declare -A Env_GHDL=(
	["PreHookFile"]=""
	["PostHookFile"]=""
	["Tools"]="GHDL GTKWave"
)
declare -A Env_GHDL_GHDL=(
	["Load"]=0
	["Commands"]="ghdl"
	["BashModule"]="GHDL.sh"
	["PreHookFile"]="GHDL.pre.sh"
	["PostHookFile"]="GHDL.post.sh"
)
declare -A Env_GHDL_GTKWave=(
	["Load"]=0
	["Commands"]="ghdl"
	["BashModule"]="GTKWave.sh"
	["PreHookFile"]="GTKWave.pre.sh"
	["PostHookFile"]="GTKWave.post.sh"
)
# Lattice tools
declare -A Env_Lattice=(
	["PreHookFile"]="Lattice.pre.sh"
	["PostHookFile"]="Lattice.post.sh"
	["Tools"]="Diamond ActiveHDL"
)
declare -A Env_Lattice_Diamond=(
	["Load"]=0
	["Commands"]="lse"
	["BashModule"]="Lattice.Diamond.sh"
	["PreHookFile"]="Lattice.Diamond.pre.sh"
	["PostHookFile"]="Lattice.Diamond.post.sh"
)
declare -A Env_Lattice_ActiveHDL=(
	["Load"]=0
	["Commands"]="asim"
	["BashModule"]="Lattice.ActiveHDL.sh"
	["PreHookFile"]="Lattice.ActiveHDL.pre.sh"
	["PostHookFile"]="Lattice.ActiveHDL.post.sh"
)
# Mentor Graphics tools
declare -A Env_Mentor=(
	["PreHookFile"]="Mentor.pre.sh"
	["PostHookFile"]="Mentor.post.sh"
	["Tools"]="PrecisionRTL QuestaSim"
)
declare -A Env_Mentor_PrecisionRTL=(
	["Load"]=0
	["Commands"]="prtl"
	["BashModule"]="Mentor.PrecisionRTL.sh"
	["PreHookFile"]="Mentor.PrecisionRTL.pre.sh"
	["PostHookFile"]="Mentor.PrecisionRTL.post.sh"
)
declare -A Env_Mentor_QuestaSim=(
	["Load"]=0
	["Commands"]="vsim"
	["BashModule"]="Mentor.QuestaSim.sh"
	["PreHookFile"]="Mentor.QuestaSim.pre.sh"
	["PostHookFile"]="Mentor.QuestaSim.post.sh"
)
# Sphinx documentation system
declare -A Env_Sphinx=(
	["PreHookFile"]=""
	["PostHookFile"]=""
	["Tools"]="Sphinx"
)
declare -A Env_Sphinx_Sphinx=(
	["Load"]=0
	["Commands"]="docs"
	["BashModule"]="Sphinx.sh"
	["PreHookFile"]="Sphinx.pre.sh"
	["PostHookFile"]="Sphinx.post.sh"
)
# Xilinx tools
declare -A Env_Xilinx=(
	["PreHookFile"]="Xilinx.pre.sh"
	["PostHookFile"]="Xilinx.post.sh"
	["Tools"]="ISE Vivado"
)
declare -A Env_Xilinx_ISE=(
	["Load"]=0
	["Commands"]="isim xst coregen ise"
	["BashModule"]="Xilinx.ISE.sh"
	["PreHookFile"]="Xilinx.ISE.pre.sh"
	["PostHookFile"]="Xilinx.ISE.post.sh"
)
declare -A Env_Xilinx_Vivado=(
	["Load"]=0
	["Commands"]="xsim vivado"
	["BashModule"]="Xilinx.Vivado.sh"
	["PreHookFile"]="Xilinx.Vivado.pre.sh"
	["PostHookFile"]="Xilinx.Vivado.post.sh"
)


# Cocotb
declare -A Env_Cocotb=(
	["PreHookFile"]="Cocotb.pre.sh"
	["PostHookFile"]="Cocotb.post.sh"
	["Tools"]="QuestaSim"
)
declare -A Env_Cocotb_QuestaSim=(
	["Load"]=0
	["Commands"]="cocotb"
	["BashModule"]="Cocotb.QuestaSim.sh"
	["PreHookFile"]="Cocotb.QuestaSim.pre.sh"
	["PostHookFile"]="Cocotb.QuestaSim.post.sh"
)


# List all vendors
Env_Vendors="Aldec Altera GHDL Lattice Mentor Sphinx Xilinx Cocotb"

# search script parameters for known commands
BreakIt=0
for param in $PyWrapper_Parameters; do
	if [ "$param" = "-D" ]; then
		PyWrapper_Debug=1
		continue
	fi
	# compare registered commands from all vendor tools
	for VendorName in $Env_Vendors; do
		declare -n VendorIndex="Env_$VendorName"
		for ToolName in ${VendorIndex["Tools"]}; do
			declare -n ToolIndex="Env_${VendorName}_${ToolName}"
			for Command in ${ToolIndex["Commands"]}; do
				if [ "$param" = "$Command" ]; then
					ToolIndex["Load"]=1
					BreakIt=1
					break
				fi
			done	# Commands
		done	# ToolNames
	done	# VendorNames
	# break is a known command was detected
	if [ $BreakIt -eq 1 ]; then break; fi
done	# Parameters


# publish PoC directories as environment variables
export PoCRootDirectory=$PoC_RootDir
export PoCWorkingDirectory=$PoC_WorkingDir

if [ $PyWrapper_Debug -eq 1 ]; then
	echo -e "${YELLOW}This is the PoC Library script wrapper operating in debug mode.${NOCOLOR}"
	echo
	echo -e "${YELLOW}Directories:${NOCOLOR}"
	echo -e "${YELLOW}  PoC root:        $PoC_RootDir${NOCOLOR}"
	echo -e "${YELLOW}  working:         $PoC_WorkingDir${NOCOLOR}"
	echo -e "${YELLOW}Script:${NOCOLOR}"
	echo -e "${YELLOW}  Filename:        $PyWrapper_Script${NOCOLOR}"
	echo -e "${YELLOW}  Solution:        $PyWrapper_Solution${NOCOLOR}"
	echo -e "${YELLOW}  Parameters:      $PyWrapper_Parameters${NOCOLOR}"
	echo -e "${YELLOW}Load Environment:  ${NOCOLOR}"
	echo -e "${YELLOW}  Lattice Diamond: ${Env_Lattice_Diamond["Load"]}${NOCOLOR}"
	echo -e "${YELLOW}  Xilinx ISE:      ${Env_Xilinx_ISE["Load"]}${NOCOLOR}"
	echo -e "${YELLOW}  Xilinx VIVADO:   ${Env_Xilinx_Vivado["Load"]}${NOCOLOR}"
	echo
fi

# find suitable python version or abort execution
Python_VersionTest='import sys; sys.exit(not (0x03050000 < sys.hexversion < 0x04000000))'
python -c "$Python_VersionTest" 2>/dev/null
if [ $? -eq 0 ]; then
	Python_Interpreter=$(which python 2>/dev/null)
	test $PyWrapper_Debug -eq 1 && echo -e "${YELLOW}PythonInterpreter: use standard interpreter: '$Python_Interpreter'${NOCOLOR}"
else
	# standard python interpreter is not suitable, try to find a suitable version manually
	for pyVersion in 3.9 3.8 3.7 3.6 3.5; do
		Python_Interpreter=$(which python$pyVersion 2>/dev/null)
		# if ExitCode = 0 => version found
		if [ $? -eq 0 ]; then
			# redo version test
			$Python_Interpreter -c "$Python_VersionTest" 2>/dev/null
			if [ $? -eq 0 ]; then break; fi
		fi
	done
	test $PyWrapper_Debug -eq 1 && echo -e "${YELLOW}PythonInterpreter: use this interpreter: '$Python_Interpreter'${NOCOLOR}"
fi
# if no interpreter was found => exit
if [ -z "$Python_Interpreter" ]; then
	echo 1>&2 -e "${RED}No suitable Python interpreter found.${NOCOLOR}"
	echo 1>&2 -e "${RED}The script requires Python >= $PyWrapper_MinVersion${NOCOLOR}"
	PoC_ExitCode=1
fi


# execute vendor and tool pre-hook files if present
for VendorName in $Env_Vendors; do
	declare -n VendorIndex="Env_$VendorName"
	for ToolName in ${VendorIndex["Tools"]}; do
		declare -n ToolIndex="Env_${VendorName}_${ToolName}"
		if [ ${ToolIndex["Load"]} -eq 1 ]; then
			# if exists, source the vendor pre-hook file
			VendorPreHookFile=$PoC_RootDir/$PoC_HookDirectory/${VendorIndex["PreHookFile"]}
			test -f $VendorPreHookFile && source $VendorPreHookFile

			# if exists, source the tool pre-hook file
			ToolPreHookFile=$PoC_RootDir/$PoC_HookDirectory/${ToolIndex["PreHookFile"]}
			test -f $ToolPreHookFile && source $ToolPreHookFile

			# if exists, source the BashModule file
			ModuleFile=$PoC_RootDir/$PoC_WrapperDirectory/${ToolIndex["BashModule"]}
			if [ -f $ModuleFile ]; then
				source $ModuleFile
				OpenEnvironment $Python_Interpreter $PoC_FrontEnd
				PoC_ExitCode=$?
			fi

			break 2
		fi
	done	# ToolNames
done	# VendorNames


# execute script with appropriate python interpreter and all given parameters
if [ $PoC_ExitCode -eq 0 ]; then
	Python_Script="$PoC_RootDir/$PoC_PythonScriptDir/$PyWrapper_Script"

	if [ -z $PyWrapper_Solution ]; then
		Python_ScriptParameters=$PyWrapper_Parameters
	else
		Python_ScriptParameters="--sln=$PyWrapper_Solution $PyWrapper_Parameters"
	fi

	if [ $PyWrapper_Debug -eq 1 ]; then
		echo -e "${YELLOW}Launching: '$Python_Interpreter $Python_Script $Python_ScriptParameters'${NOCOLOR}"
		echo -e "${YELLOW}------------------------------------------------------------${NOCOLOR}"
	fi

	# launching python script
	set -f
	"$Python_Interpreter" $Python_Script $Python_ScriptParameters
	PoC_ExitCode=$?
fi

# execute vendor and tool post-hook files if present
for VendorName in $Env_Vendors; do
	declare -n VendorIndex="Env_$VendorName"
	for ToolName in ${VendorIndex["Tools"]}; do
		declare -n ToolIndex="Env_${VendorName}_${ToolName}"
		if [ ${ToolIndex["Load"]} -eq 1 ]; then
			# if exists, source the tool Post-hook file
			ToolPostHookFile=$PoC_RootDir/$PoC_HookDirectory/${ToolIndex["PostHookFile"]}
			test -f $ToolPostHookFile && source $ToolPostHookFile

			# if exists, source the vendor post-hook file
			VendorPostHookFile=$PoC_RootDir/$PoC_HookDirectory/${VendorIndex["PostHookFile"]}
			test -f $VendorPostHookFile && source $VendorPostHookFile

			# if exists, source the BashModule file
			ModuleFile=$PoC_RootDir/$PoC_WrapperDirectory/${ToolIndex["BashModule"]}
			if [ -f $ModuleFile ]; then
				# source $ModuleFile
				CloseEnvironment $Python_Interpreter $PoC_FrontEnd
				PoC_ExitCode=$?
			fi
			break 2
		fi
	done	# ToolNames
done	# VendorNames

# clean up environment variables
unset PoCRootDirectory
unset PoCWorkingDirectory
