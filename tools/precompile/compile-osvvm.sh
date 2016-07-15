#! /usr/bin/env bash
# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
#	Authors:					Patrick Lehmann
#                   Martin Zabel
# 
#	Bash Script:			Compile OSVVM simulation packages
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

# configure script here
OSVVMLibDir=lib/osvvm

# work around for Darwin (Mac OS)
READLINK=readlink; if [[ $(uname) == "Darwin" ]]; then READLINK=greadlink; fi

# Save working directory
WorkingDir=$(pwd)
ScriptDir="$(dirname $0)"
ScriptDir="$($READLINK -f $ScriptDir)"

PoCRootDir="$($READLINK -f $ScriptDir/../..)"
PoC_sh=$PoCRootDir/poc.sh

# source shared file from precompile directory
source $ScriptDir/shared.sh


# command line argument processing
NO_COMMAND=1
while [[ $# > 0 ]]; do
	key="$1"
	case $key in
		-c|--clean)
		CLEAN=TRUE
		;;
		-a|--all)
		COMPILE_ALL=TRUE
		NO_COMMAND=0
		;;
		--ghdl)
		COMPILE_FOR_GHDL=TRUE
		NO_COMMAND=0
		;;
		--questa)
		COMPILE_FOR_VSIM=TRUE
		NO_COMMAND=0
		;;
		-h|--help)
		HELP=TRUE
		NO_COMMAND=0
		;;
		*)		# unknown option
		echo 1>&2 -e "${COLORED_ERROR} Unknown command line option '$key'.${ANSI_NOCOLOR}"
		exit -1
		;;
	esac
	shift # past argument or value
done

if [ $NO_COMMAND -eq 1 ]; then
	HELP=TRUE
fi

if [ "$HELP" == "TRUE" ]; then
	test $NO_COMMAND -eq 1 && echo 1>&2 -e "\n${COLORED_ERROR} No command selected.${ANSI_NOCOLOR}"
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
	# echo "  -c --clean            Remove all generated files"
	echo ""
	echo "Tool chain:"
	echo "  -a --all              Compile for all tool chains."
	echo "     --ghdl             Compile for GHDL."
	echo "     --questa           Compile for QuestaSim/ModelSim."
	echo ""
	exit 0
fi


if [ "$COMPILE_ALL" == "TRUE" ]; then
	COMPILE_FOR_GHDL=TRUE
	COMPILE_FOR_VSIM=TRUE
fi

PrecompiledDir=$($PoC_sh query CONFIG.DirectoryNames:PrecompiledFiles 2>/dev/null)
if [ $? -ne 0 ]; then
	echo 1>&2 -e "${COLORED_ERROR} Cannot get precompiled dir.${ANSI_NOCOLOR}"
	echo 1>&2 -e "${ANSI_RED}$PrecompiledDir${ANSI_NOCOLOR}"
	exit -1;
fi


# GHDL
# ==============================================================================
if [ "$COMPILE_FOR_GHDL" == "TRUE" ]; then
	# Get GHDL directories
	# <= $GHDLBinDir
	# <= $GHDLScriptDir
	# <= $GHDLDirName
	GetGHDLDirectories $PoC_sh

	# Assemble output directory
	DestDir=$PoCRootDir/$PrecompiledDir/$GHDLDirName
	# Create and change to destination directory
	# -> $DestinationDirectory
	CreateDestinationDirectory $DestDir
	
	# Assemble Altera compile script path
	GHDLOSVVMScript="$($READLINK -f $GHDLScriptDir/compile-osvvm.sh)"

	
	# Get OSVVM installation directory
	OSVVMInstallDir=$PoCRootDir/$OSVVMLibDir
	SourceDir=$OSVVMInstallDir

	# export GHDL binary dir if not allready set
	if [ -z $GHDL ]; then
		export GHDL=$GHDLBinDir/ghdl
	fi
	
	BASH=$(which bash)
	
	# compile all architectures, skip existing and large files, no wanrings
	$BASH $GHDLOSVVMScript --all -n --src $SourceDir --out "."
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${COLORED_ERROR} While executing vendor library compile script from GHDL.${ANSI_NOCOLOR}"
		exit -1;
	fi
	
	# # Cleanup
	# if [ "$CLEAN" == "TRUE" ]; then
		# echo -e "${YELLOW}Cleaning library 'osvvm' ...${ANSI_NOCOLOR}"
		# rm -Rf $DestDir 2> /dev/null
	# fi
	
	cd $WorkingDir
fi

# QuestaSim/ModelSim
# ==============================================================================
if [ "$COMPILE_FOR_VSIM" == "TRUE" ]; then
	# Get GHDL directories
	# <= $VSimBinDir
	# <= $VSimDirName
	GetVSimDirectories $PoC_sh

	# Assemble output directory
	DestDir=$PoCRootDir/$PrecompiledDir/$VSimDirName
	# Create and change to destination directory
	# -> $DestinationDirectory
	CreateDestinationDirectory $DestDir


	# clean osvvm directory
	if [ -d $DestDir/osvvm ]; then
		echo -e "${YELLOW}Cleaning library 'osvvm' ...${ANSI_NOCOLOR}"
		rm -rf osvvm
	fi
	
	# Get OSVVM installation directory
	OSVVMInstallDir=$PoCRootDir/$OSVVMLibDir
	SourceDir=$OSVVMInstallDir
	
	# Files
	Library=osvvm
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
	
	# Compile libraries with vcom, executed in destination directory
	echo -e "${YELLOW}Creating library '$Library' with vlib/vmap...${ANSI_NOCOLOR}"
	$VSimBinDir/vlib $Library
	$VSimBinDir/vmap -del $Library
	$VSimBinDir/vmap $Library $DestDir/$Library
	
	echo -e "${YELLOW}Compiling library '$Library' with vcom...${ANSI_NOCOLOR}"
	ERRORCOUNT=0
	for File in ${Files[@]}; do
		echo "  Compiling '$File'..."
		$VSimBinDir/vcom -2008 -work $Library $SourceDir/$File
		if [ $? -ne 0 ]; then
			let ERRORCOUNT++
		fi
	done
	
	# print overall result
	echo -n "Compiling library '$Library' with vcom "
	if [ $ERRORCOUNT -gt 0 ]; then
		echo -e $COLORED_FAILED
	else
		echo -e $COLORED_SUCCESSFUL
	fi
	
	cd $WorkingDir
fi

