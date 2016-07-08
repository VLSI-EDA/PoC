#! /usr/bin/env bash
# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
#	Authors:          Martin Zabel
#                   Patrick Lehmann
# 
#	Bash Script:			Compile Altera's simulation libraries
# 
# Description:
# ------------------------------------
#	This is a bash script compiles Altera's simulation libraries into a local
#	directory.
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

# set bash options
set -o pipefail

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
	echo "  Script to compile the Altera Quartus simulation libraries for"
	echo "  - GHDL"
	echo "  - QuestaSim/ModelSim"
	echo "  on Linux."
	echo ""
	echo "Usage:"
	echo "  compile-altera.sh [-c] [--help|--all|--ghdl|--vsim]"
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
	echo 1>&2 -e "${COLORED_ERROR} Cannot get precompiled directory.${ANSI_NOCOLOR}"
	echo 1>&2 -e "${ANSI_RED}$PrecompiledDir${ANSI_NOCOLOR}"
	exit -1;
fi

AlteraDirName=$($PoC_sh query CONFIG.DirectoryNames:AlteraSpecificFiles 2>/dev/null)
if [ $? -ne 0 ]; then
	echo 1>&2 -e "${COLORED_ERROR} Cannot get Altera directory.${ANSI_NOCOLOR}"
	echo 1>&2 -e "${ANSI_RED}$AlteraDirName${ANSI_NOCOLOR}"
	exit -1;
fi

# GHDL
# ==============================================================================
ERRORCOUNT=0
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
	GHDLAlteraScript="$($READLINK -f $GHDLScriptDir/compile-altera.sh)"
	if [ ! -x $GHDLAlteraScript ]; then
		echo 1>&2 -e "${COLORED_ERROR} Altera compile script from GHDL is not executable.${ANSI_NOCOLOR}"
		exit -1;
	fi
	
	echo "=> $GHDLAlteraScript"

	# Get Altera installation directory
	QuartusInstallDir=$($PoC_sh query INSTALL.Altera.Quartus:InstallationDirectory 2>/dev/null)
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${COLORED_ERROR} Cannot get Altera Quartus installation directory.${ANSI_NOCOLOR}"
		echo 1>&2 -e "${ANSI_RED}$QuartusInstallDir${ANSI_NOCOLOR}"
		exit -1;
	fi
	SourceDir=$QuartusInstallDir/eda/sim_lib

	# export GHDL binary dir if not allready set
	if [ -z $GHDL ]; then
		export GHDL=$GHDLBinDir/ghdl
	fi
	
	# compile all architectures, skip existing and large files, no wanrings
	$GHDLAlteraScript --all -s -S -n --src $SourceDir --out $AlteraDirName
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${COLORED_ERROR} While executing vendor library compile script from GHDL.${ANSI_NOCOLOR}"
		exit -1;
	fi
fi

# QuestaSim/ModelSim
# ==============================================================================
ERRORCOUNT=0
if [ "$COMPILE_FOR_VSIM" == "TRUE" ]; then
	# Get GHDL directories
	# <= $VSimBinDir
	# <= $VSimDirName
	GetVSimDirectories $PoC_sh

	# Assemble output directory
	DestDir=$PoCRootDir/$PrecompiledDir/$VSimDirName/$AlteraDirName
	# Create and change to destination directory
	# -> $DestinationDirectory
	CreateDestinationDirectory $DestDir

	QuartusBinDir=$($PoC_sh query INSTALL.Altera.Quartus:BinaryDirectory 2>/dev/null)
  if [ $? -ne 0 ]; then
	  echo 1>&2 -e "${COLORED_ERROR} Cannot get Altera Quartus binary directory.${ANSI_NOCOLOR}"
	  echo 1>&2 -e "${COLORED_MESSAGE} $QuartusBinDir${ANSI_NOCOLOR}"
		echo 1>&2 -e "${ANSI_YELLOW}Run 'poc.sh configure' to configure your Altera Quartus installation.${ANSI_NOCOLOR}"
		exit -1;
  fi
	Quartus_sh=$QuartusBinDir/quartus_sh
	
	# create an empty modelsim.ini in the altera directory and add reference to parent modelsim.ini
	CreateLocalModelsim_ini

	
	Simulator=questasim
	Language=vhdl
	TargetArchitecture=("all")		# "cycloneiii" "stratixiv")
	
	# compile common libraries
	$Quartus_sh --simlib_comp -tool $Simulator -language $Language -tool_path $VSimBinDir -directory $DestDir -rtl_only
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${COLORED_ERROR} Error while compiling common libraries.${ANSI_NOCOLOR}"
		exit -1;
	fi

	for Family in ${TargetArchitecture[@]}; do
		$Quartus_sh --simlib_comp -tool $Simulator -language $Language -family $Family -tool_path $VSimBinDir -directory $DestDir -no_rtl
		if [ $? -ne 0 ]; then
			echo 1>&2 -e "${COLORED_ERROR} Error while compiling family '$Family' libraries.${ANSI_NOCOLOR}"
			exit -1;
		fi
	done
fi

