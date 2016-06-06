#! /bin/bash
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

poc_sh=../../poc.sh
OSVVMLibDir=lib/osvvm

# define color escape codes
RED="\e[0;31m"			# Red
GREEN="\e[32m"			# Green
YELLOW="\e[1;33m"		# Yellow
NOCOLOR="\e[0m"			# No Color

# red texts
COLORED_ERROR="$RED[ERROR]$NOCOLOR"
COLORED_FAILED="$RED[FAILED]$NOCOLOR"

# green texts
COLORED_DONE="$GREEN[DONE]$NOCOLOR"
COLORED_SUCCESSFUL="$GREEN[SUCCESSFUL]$NOCOLOR"

# Save working directory
WorkingDir=$(pwd)
ScriptDir="$(dirname $0)"
ScriptDir="$(readlink -f $ScriptDir)"

# set bash options
set -o pipefail

# command line argument processing
NO_COMMAND=TRUE
while [[ $# > 0 ]]; do
	key="$1"
	case $key in
		-c|--clean)
		CLEAN=TRUE
		;;
		-a|--all)
		COMPILE_ALL=TRUE
		NO_COMMAND=FALSE
		;;
		--ghdl)
		COMPILE_FOR_GHDL=TRUE
		NO_COMMAND=FALSE
		;;
		--questa)
		COMPILE_FOR_VSIM=TRUE
		NO_COMMAND=FALSE
		;;
		-h|--help)
		HELP=TRUE
		NO_COMMAND=FALSE
		;;
		*)		# unknown option
		UNKNOWN_OPTION=TRUE
		;;
	esac
	shift # past argument or value
done

if [ "$NO_COMMAND" == "TRUE" ]; then
	HELP=TRUE
fi

if [ "$UNKNOWN_OPTION" == "TRUE" ]; then
	echo -e $COLORED_ERROR "Unknown command line option.${NOCOLOR}"
	exit -1
elif [ "$HELP" == "TRUE" ]; then
	if [ "$NO_COMMAND" == "TRUE" ]; then
		echo -e $COLORED_ERROR " No command selected."
	fi
	echo ""
	echo "Synopsis:"
	echo "  Script to compile the simulation library OSVVM for"
	echo "  - GHDL"
	echo "  - QuestaSim/ModelSim"
	echo "  on Linux."
	echo ""
	echo "Usage:"
	echo "  compile-osvvm.sh [-c] [--help|--all|--ghdl|--vsim]"
	echo ""
	echo "Common commands:"
	echo "  -h --help             Print this help page"
	echo "  -c --clean            Remove all generated files"
	echo ""
	echo "Tool chain:"
	echo "  -a --all              Compile for all tool chains."
	echo "  -g --ghdl             Compile for GHDL."
	echo "  -v --vsim             Compile for QuestaSim/ModelSim."
	echo ""
	exit 0
fi

# Files
Files=(
	NamePkg.vhd
	OsvvmGlobalPkg.vhd
	TextUtilPkg.vhd
	TranscriptPkg.vhd
	AlertLogPkg.vhd
	MemoryPkg.vhd
	MessagePkg.vhd
	SortListPkg_int.vhd
	RandomBasePkg.vhd
	RandomPkg.vhd
	CoveragePkg.vhd
	OsvvmContext.vhd
)

PoCRootDir=$($poc_sh query INSTALL.PoC:InstallationDirectory 2>/dev/null)
if [ $? -ne 0 ]; then
	echo 1>&2 -e "${RED}ERROR: Cannot get PoC installation dir.${NOCOLOR}"
	echo 1>&2 -e "${RED}$PoCRootDir${NOCOLOR}"
	exit -1;
fi

PrecompiledDir=$($poc_sh query CONFIG.DirectoryNames:PrecompiledFiles 2>/dev/null)
if [ $? -ne 0 ]; then
	echo 1>&2 -e "${RED}ERROR: Cannot get precompiled dir.${NOCOLOR}"
	echo 1>&2 -e "${RED}$PrecompiledDir${NOCOLOR}"
	exit -1;
fi

# Setup destination directory
SourceDir=$PoCRootDir/$OSVVMLibDir

if [ "$COMPILE_ALL" == "TRUE" ]; then
	COMPILE_FOR_GHDL=TRUE
	COMPILE_FOR_VSIM=TRUE
fi

# GHDL
# ==============================================================================
ERRORCOUNT=0
if [ "$COMPILE_FOR_GHDL" == "TRUE" ]; then
	DestDir=$PoCRootDir/$PrecompiledDir/ghdl/osvvm/v08
	
	# Get GHDL binary
	BinDir=$($poc_sh query INSTALL.GHDL:BinaryDirectory 2>/dev/null)	# Path to the simulators bin directory
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${RED}ERROR: Cannot get GHDL binary dir.${NOCOLOR}"
		echo 1>&2 -e "${RED}$BinDir${NOCOLOR}"
		exit -1;
	fi
	
	# Cleanup
	if [ "$CLEAN" == "TRUE" ]; then
		echo -e "${YELLOW}Cleaning library 'osvvm' ...${NOCOLOR}"
		rm -Rf $DestDir 2> /dev/null
	fi
	
	# Create and change to destination directory
	mkdir -p $DestDir
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${RED}ERROR: Cannot create output directory.${NOCOLOR}"
		exit -1;
	fi
	cd $DestDir
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${RED}ERROR: Cannot change to output directory.${NOCOLOR}"
		exit -1;
	fi
	
	if [ -z "$(which grcat)" ]; then
		# if grcat (generic colourizer) is not installed, use a dummy pipe command like 'cat'
		GRC_COMMAND="cat"
	else
		# if [ "$SUPPRESS_WARNINGS" == "TRUE" ]; then
			GRC_COMMAND="grcat $ScriptDir/ghdl.skipwarning.grcrules"
		# else
			# GRC_COMMAND="grcat $ScriptDir/ghdl.grcrules"
		# fi
	fi
	
	# Analyze each VHDL source file.
	echo -e "${YELLOW}Compiling library 'osvvm' with GHDL ...${NOCOLOR}"
	for file in ${Files[@]}; do
		echo "  Compiling $file..."
		$BinDir/ghdl -a -fexplicit -frelaxed-rules --no-vital-checks --warn-binding --mb-comments --std=08 --work=osvvm $SourceDir/$file 2>&1 | $GRC_COMMAND
		if [ $? -ne 0 ]; then
			let ERRORCOUNT++
		fi
	done
	
	# print overall result
	echo -n "Compiling library 'osvvm' with GHDL "
	if [ $ERRORCOUNT -gt 0 ]; then
		echo -e $COLORED_FAILED
	else
		echo -e $COLORED_SUCCESSFUL
	fi
	
	cd $WorkingDir
fi

# QuestaSim/ModelSim
# ==============================================================================
ERRORCOUNT=0
if [ "$COMPILE_FOR_VSIM" == "TRUE" ]; then
	DestDir=$PoCRootDir/$PrecompiledDir/vsim
	
	# Get QuestaSim/ModelSim binary
	BinDir=$($poc_sh query ModelSim:BinaryDirectory 2>/dev/null)	# Path to the simulators bin directory
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${RED}ERROR: Cannot get QuestaSim/ModelSim binary dir.${NOCOLOR}"
		echo 1>&2 -e "${RED}$BinDir${NOCOLOR}"
		exit -1;
	fi
	
	# Create and change to destination directory
	mkdir -p $DestDir
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${RED}ERROR: Cannot create output directory.${NOCOLOR}"
		exit -1;
	fi
	cd $DestDir
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${RED}ERROR: Cannot change to output directory.${NOCOLOR}"
		exit -1;
	fi
	
	# Compile libraries with vcom, executed in destination directory
	echo -e "${YELLOW}Cleaning library 'osvvm' ...${NOCOLOR}"
	rm -rf osvvm
	echo -e "${YELLOW}Creating library 'osvvm' with vlib/vmap ...${NOCOLOR}"
	$BinDir/vlib osvvm
	$BinDir/vmap -del osvvm
	$BinDir/vmap osvvm $DestDir/osvvm
	echo -e "${YELLOW}Compiling library 'osvvm' with vcom ...${NOCOLOR}"
	for file in ${Files[@]}; do
		echo "  Compiling $file..."
		$BinDir/vcom -2008 -work osvvm $SourceDir/$file
		if [ $? -ne 0 ]; then
			let ERRORCOUNT++
		fi
	done
	
	# print overall result
	echo -n "Compiling library 'osvvm' with vcom "
	if [ $ERRORCOUNT -gt 0 ]; then
		echo -e $COLORED_FAILED
	else
		echo -e $COLORED_SUCCESSFUL
	fi
	
	cd $WorkingDir
fi
