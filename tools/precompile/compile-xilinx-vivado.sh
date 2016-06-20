#! /usr/bin/env bash
# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
#	Authors:         	Martin Zabel
#                   Patrick Lehmann
# 
#	Bash Script:			Compile Xilinx's simulation libraries
# 
# Description:
# ------------------------------------
#	This is a bash script compiles Xilinx's simulation libraries into a local
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
	echo "  Script to compile the Xilinx Vivado simulation libraries for"
	echo "  - GHDL"
	echo "  - QuestaSim/ModelSim"
	echo "  on Linux."
	echo ""
	echo "Usage:"
	echo "  compile-xilinx-vivado.sh [-c] [--help|--all|--ghdl|--vsim]"
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

XilinxDirName=$($PoC_sh query CONFIG.DirectoryNames:XilinxSpecificFiles 2>/dev/null)
if [ $? -ne 0 ]; then
	echo 1>&2 -e "${COLORED_ERROR} Cannot get Xilinx directory.${ANSI_NOCOLOR}"
	echo 1>&2 -e "${ANSI_RED}$XilinxDirName${ANSI_NOCOLOR}"
	exit -1;
fi
XilinxDirName2=$XilinxDirName-vivado

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
	
	# Assemble Xilinx compile script path
	GHDLXilinxScript="$($READLINK -f $GHDLScriptDir/compile-xilinx-vivado.sh)"
	if [ ! -x $GHDLXilinxScript ]; then
		echo 1>&2 -e "${COLORED_ERROR} Xilinx compile script from GHDL is not executable.${ANSI_NOCOLOR}"
		exit -1;
	fi
	
	# Get Xilinx installation directory
	VivadoInstallDir=$($PoC_sh query INSTALL.Xilinx.Vivado:InstallationDirectory 2>/dev/null)
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${COLORED_ERROR} Cannot get Xilinx Vivado installation directory.${ANSI_NOCOLOR}"
		echo 1>&2 -e "${COLORED_MESSAGE} $VivadoInstallDir${ANSI_NOCOLOR}"
		echo 1>&2 -e "${ANSI_YELLOW}Run 'poc.sh configure' to configure your Xilinx Vivado installation.${ANSI_NOCOLOR}"
		exit -1;
	fi
	SourceDir=$VivadoInstallDir/data/vhdl/src

	# export GHDL binary dir if not allready set
	if [ -z $GHDL ]; then
		export GHDL=$GHDLBinDir/ghdl
	fi
	
	# compile all architectures, skip existing and large files, no wanrings
	$GHDLXilinxScript --all -s -S -n --src $SourceDir --out $XilinxDirName2
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${COLORED_ERROR} While executing vendor library compile script from GHDL.${ANSI_NOCOLOR}"
		exit -1;
	fi
	
	# create "xilinx" symlink
	rm -f $XilinxDirName
	ln -s $XilinxDirName2 $XilinxDirName
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
	DestDir=$PoCRootDir/$PrecompiledDir/$VSimDirName/$XilinxDirName2
	
	# Create and change to destination directory
	# -> $DestinationDirectory
	CreateDestinationDirectory $DestDir

	# if XILINX_VIVADO environment variable is not set, load Vivado environment
	if [ -z "$XILINX_VIVADO" ]; then
		Vivado_SettingsFile=$($PoC_sh query Xilinx.Vivado:SettingsFile)
		if [ $? -ne 0 ]; then
			echo 1>&2 -e "${COLORED_ERROR} No Xilinx Vivado installation found.${ANSI_NOCOLOR}"
			echo 1>&2 -e "${COLORED_MESSAGE} $Vivado_SettingsFile${ANSI_NOCOLOR}"
			echo 1>&2 -e "${ANSI_YELLOW}Run 'poc.sh configure' to configure your Xilinx Vivado installation.${ANSI_NOCOLOR}"
			exit -1
		fi
		echo -e "${YELLOW}Loading Xilinx Vivado environment '$Vivado_SettingsFile'${ANSI_NOCOLOR}"
		RescueArgs=$@
		set --
		source "$Vivado_SettingsFile"
		set -- $RescueArgs
	fi
	
	VivadoBinDir=$($PoC_sh query INSTALL.Xilinx.Vivado:BinaryDirectory 2>/dev/null)
  if [ $? -ne 0 ]; then
	  echo 1>&2 -e "${COLORED_ERROR} Cannot get Xilinx Vivado binary directory.${ANSI_NOCOLOR}"
	  echo 1>&2 -e "${COLORED_MESSAGE} $VivadoBinDir${ANSI_NOCOLOR}"
		echo 1>&2 -e "${ANSI_YELLOW}Run 'poc.sh configure' to configure your Xilinx Vivado installation.${ANSI_NOCOLOR}"
		exit -1;
  fi
	Vivado_tcl=$VivadoBinDir/vivado
	
	# create an empty modelsim.ini in the 'xilinx-vivado' directory and add reference to parent modelsim.ini
	CreateLocalModelsim_ini

	Simulator=questa
	Language=vhdl
	Library=all
	Family=all			# all, virtex5, virtex6, virtex7, ...
	
	CommandFile=vivado.tcl
	
	echo "compile_simlib -force -library $Library -family $Family -language $Language -simulator $Simulator -simulator_exec_path $VSimBinDir -directory $DestDir" > $CommandFile
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${COLORED_ERROR} Cannot create temporary tcl script.${ANSI_NOCOLOR}"
		exit -1;
	fi
	echo "exit" >> $CommandFile

	# compile common libraries
	$Vivado_tcl -mode tcl -source $CommandFile
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${COLORED_ERROR} Error while compiling Xilinx Vivado libraries.${ANSI_NOCOLOR}"
		exit -1;
	fi
	
	# create "xilinx" symlink
	cd ..
	rm -f $XilinxDirName
	ln -s $XilinxDirName2 $XilinxDirName
fi

