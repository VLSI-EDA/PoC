# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
#	Authors:						Patrick Lehmann
#                     Martin Zabel
# 
#	Bash Script:				Script to compile the OSVVM library for Questa / ModelSim
#                     on Linux
# 
# Description:
# ------------------------------------
#	This is a Bash script (executable) which:
#		- creates a subdirectory in the current working directory
#		- compiles all OSVVM packages 
#
# License:
# ==============================================================================
# Copyright 2007-2016 Technische Universitaet Dresden - Germany
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

ANSI_RED="\e[31m"
ANSI_GREEN="\e[32m"
ANSI_YELLOW="\e[33m"
ANSI_BLUE="\e[34m"
ANSI_MAGENTA="\e[35m"
ANSI_CYAN="\e[36;1m"
ANSI_NOCOLOR="\e[0m"

# red texts
COLORED_ERROR="${ANSI_RED}[ERROR]"
COLORED_MESSAGE="${ANSI_YELLOW}       "
COLORED_FAILED="${ANSI_RED}[FAILED]${ANSI_NOCOLOR}"

# green texts
COLORED_DONE="${ANSI_GREEN}[DONE]${ANSI_NOCOLOR}"
COLORED_SUCCESSFUL="${ANSI_GREEN}[SUCCESSFUL]${ANSI_NOCOLOR}"


# set bash options
set -o pipefail


# -> $SUPPRESS_WARNINGS
# <= $GRC_COMMAND
SetupGRCat() {
	if [ -z "$(which grcat 2>/dev/null)" ]; then
		# if grcat (generic colourizer) is not installed, use a dummy pipe command like 'cat'
		GRC_COMMAND="cat"
	elif [ $SUPPRESS_WARNINGS -eq 1 ]; then
		GRC_COMMAND="grcat $ScriptDir/ghdl.skipwarning.grcrules"
	else
		GRC_COMMAND="grcat $ScriptDir/ghdl.grcrules"
	fi
}

CreateDestinationDirectory() {
	DestinationDirectory=$1
	
	mkdir -p $DestinationDirectory
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${COLORED_ERROR} Cannot create output directory.${ANSI_NOCOLOR}"
		exit -1;
	fi
	cd $DestinationDirectory
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${COLORED_ERROR} Cannot change to output directory.${ANSI_NOCOLOR}"
		exit -1;
	fi
}

# GetGHDLDirectories
# -> $PoC_sh
# <= $GHDLBinDir
# <= $GHDLScriptDir
# <= $GHDLDirName
GetGHDLDirectories() {
	PoC_sh=$1

	# Get GHDL binary directory
	GHDLBinDir=$($PoC_sh query INSTALL.GHDL:BinaryDirectory 2>/dev/null)	# Path to the simulators bin directory
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${COLORED_ERROR} Cannot get GHDL binary directory.${ANSI_NOCOLOR}"
		echo 1>&2 -e "${COLORED_MESSAGE} $GHDLBinDir${ANSI_NOCOLOR}"
		echo 1>&2 -e "${ANSI_YELLOW}Run 'poc.sh configure' to configure your GHDL installation.${ANSI_NOCOLOR}"
		exit -1;
	fi
	
	# Get GHDL script directory
	GHDLScriptDir=$($PoC_sh query INSTALL.GHDL:ScriptDirectory 2>/dev/null)	# Path to the simulators bin directory
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${COLORED_ERROR} Cannot get GHDL vendor script directory.${ANSI_NOCOLOR}"
		echo 1>&2 -e "${COLORED_MESSAGE} $GHDLScriptDir${ANSI_NOCOLOR}"
		echo 1>&2 -e "${ANSI_YELLOW}Run 'poc.sh configure' to configure your GHDL installation.${ANSI_NOCOLOR}"
		exit -1;
	fi
	
	# 
	GHDLDirName=$($PoC_sh query CONFIG.DirectoryNames:GHDLFiles 2>/dev/null)
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${COLORED_ERROR} Cannot get GHDL dir.${ANSI_NOCOLOR}"
		echo 1>&2 -e "${COLORED_MESSAGE} $GHDLDirName${ANSI_NOCOLOR}"
		exit -1;
	fi
}

# GetVSimDirectories
# -> $PoC_sh
# <= $VSimBinDir
# <= $VSimDirName
GetVSimDirectories() {
	# Get QuestaSim/ModelSim binary
	VSimBinDir=$($PoC_sh query ModelSim:BinaryDirectory 2>/dev/null)	# Path to the simulators bin directory
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${COLORED_ERROR} Cannot get QuestaSim/ModelSim binary directory.${ANSI_NOCOLOR}"
		echo 1>&2 -e "${COLORED_MESSAGE} $VSimBinDir${ANSI_NOCOLOR}"
		echo 1>&2 -e "${ANSI_YELLOW}Run 'poc.sh configure' to configure your Mentor QuestaSim/ModelSim installation.${ANSI_NOCOLOR}"
		exit -1;
	fi
	
	VSimDirName=$($PoC_sh query CONFIG.DirectoryNames:QuestaSimFiles 2>/dev/null)
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${COLORED_ERROR} Cannot get QuestaSim directory.${ANSI_NOCOLOR}"
		echo 1>&2 -e "${COLORED_MESSAGE} $VSimDirName${ANSI_NOCOLOR}"
		exit -1;
	fi
}

CreateLocalModelsim_ini() {
	# create an empty modelsim.ini in the altera directory
	echo "[Library]" > modelsim.ini
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${COLORED_ERROR} Cannot create initial modelsim.ini.${ANSI_NOCOLOR}"
		exit -1;
	fi
	# add reference to parent modelsim.ini
	if [ -e "../modelsim.ini" ]; then
		echo "others = ../modelsim.ini" >> modelsim.ini
	fi
}

