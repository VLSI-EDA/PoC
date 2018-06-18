#! /usr/bin/env bash
# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
#	Authors:         	Martin Zabel
#                   Patrick Lehmann
#
#	Bash Script:			Compile Lattice's simulation libraries
#
# Description:
# ------------------------------------
#	This is a Bash script (executable) which:
#		- creates a subdirectory in the current working directory
#		- compiles all Lattice libraries
#
# License:
# ==============================================================================
# Copyright 2017-2018 Patrick Lehmann - Bötzingen, Germany
# Copyright 2007-2016 Technische Universität Dresden - Germany
#											Chair of VLSI-Design, Diagnostics and Architecture
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
source $ScriptDir/precompile.sh


# command line argument processing
NO_COMMAND=1
VERBOSE=0
DEBUG=0
VHDL93=0
VHDL2008=0
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
		-v|--verbose)
		VERBOSE=1
		;;
		-d|--debug)
		VERBOSE=1
		DEBUG=1
		;;
		-h|--help)
		HELP=TRUE
		NO_COMMAND=0
		;;
		--vhdl93)
		VHDL93=1
		;;
		--vhdl2008)
		VHDL2008=1
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
	echo "  Script to compile the Lattice Diamond simulation libraries for"
	echo "  - GHDL"
	echo "  - QuestaSim/ModelSim"
	echo "  on Linux."
	echo ""
	echo "Usage:"
	echo "  compile-lattice.sh [-c] [--help|--all|--ghdl|--questa] [<Options>]"
	echo ""
	echo "Common commands:"
	echo "  -h --help             Print this help page"
	# echo "  -c --clean            Remove all generated files"
	echo ""
	echo "Common options:"
	echo "  -v --verbose          Print verbose messages."
	echo "  -d --debug            Print debug messages."
	echo ""
	echo "Tool chain:"
	echo "  -a --all              Compile for all tool chains."
	echo "     --ghdl             Compile for GHDL."
	echo "     --questa           Compile for QuestaSim/ModelSim."
	echo ""
	echo "Options:"
	echo "     --vhdl93           Compile for VHDL-93."
	echo "     --vhdl2008         Compile for VHDL-2008."
	echo ""
	exit 0
fi


if [ "$COMPILE_ALL" == "TRUE" ]; then
	test $VERBOSE -eq 1 && echo "  Enables all tool chains: GHDL, vsim"
	COMPILE_FOR_GHDL=TRUE
	# COMPILE_FOR_VSIM=TRUE
fi
if [ \( $VHDL93 -eq 0 \) -a \( $VHDL2008 -eq 0 \) ]; then
	VHDL93=1
	VHDL2008=1
fi

test $VERBOSE -eq 1 && echo "  Query pyIPCMI for 'CONFIG.DirectoryNames:PrecompiledFiles'"
test $DEBUG   -eq 1 && echo "    $PoC_sh query CONFIG.DirectoryNames:PrecompiledFiles 2>/dev/null"
PrecompiledDir=$($PoC_sh query CONFIG.DirectoryNames:PrecompiledFiles 2>/dev/null)
if [ $? -ne 0 ]; then
	echo 1>&2 -e "${COLORED_ERROR} Cannot get precompiled directory.${ANSI_NOCOLOR}"
	echo 1>&2 -e "${ANSI_RED}$PrecompiledDir${ANSI_NOCOLOR}"
	exit -1;
elif [ $DEBUG -eq 1 ]; then
	echo "    Return value: $PrecompiledDir"
fi

test $VERBOSE -eq 1 && echo "  Query pyIPCMI for 'CONFIG.DirectoryNames:LatticeSpecificFiles'"
test $DEBUG   -eq 1 && echo "    $PoC_sh query CONFIG.DirectoryNames:LatticeSpecificFiles 2>/dev/null"
LatticeDirName=$($PoC_sh query CONFIG.DirectoryNames:LatticeSpecificFiles 2>/dev/null)
if [ $? -ne 0 ]; then
	echo 1>&2 -e "${COLORED_ERROR} Cannot get Lattice directory.${ANSI_NOCOLOR}"
	echo 1>&2 -e "${ANSI_RED}$LatticeDirName${ANSI_NOCOLOR}"
	exit -1;
elif [ $DEBUG -eq 1 ]; then
	echo "    Return value: $LatticeDirName"
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

	# Assemble Lattice compile script path
	GHDLLatticeScript="$($READLINK -f $GHDLScriptDir/compile-lattice.sh)"


	# Get Lattice installation directory
	test $VERBOSE -eq 1 && echo "  Query pyIPCMI for 'INSTALL.Lattice.Diamond:InstallationDirectory'"
	test $DEBUG   -eq 1 && echo "    $PoC_sh query INSTALL.Lattice.Diamond:InstallationDirectory 2>/dev/null"
	DiamondInstallDir=$($PoC_sh query INSTALL.Lattice.Diamond:InstallationDirectory 2>/dev/null)
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${COLORED_ERROR} Cannot get Lattice Diamond installation directory.${ANSI_NOCOLOR}"
		echo 1>&2 -e "${COLORED_MESSAGE} $DiamondInstallDir${ANSI_NOCOLOR}"
		echo 1>&2 -e "${ANSI_YELLOW}Run 'poc.sh configure' to configure your Lattice Diamond installation.${ANSI_NOCOLOR}"
		exit -1;
	elif [ $DEBUG -eq 1 ]; then
		echo "    Return value: $DiamondInstallDir"
	fi
	SourceDir=$DiamondInstallDir/cae_library/simulation/vhdl

	# export GHDL binary dir if not allready set
	if [ -z $GHDL ]; then
		export GHDL=$GHDLBinDir/ghdl
	fi

	BASH=$(which bash)

	# compile all architectures, skip existing and large files, no wanrings
	if [ $VHDL93 -eq 1 ]; then
		$BASH $GHDLLatticeScript --all --vhdl93 -s -n --src $SourceDir --out $LatticeDirName
		if [ $? -ne 0 ]; then
			echo 1>&2 -e "${COLORED_ERROR} While executing vendor library compile script from GHDL.${ANSI_NOCOLOR}"
			exit -1;
		fi
	fi
	if [ $VHDL2008 -eq 1 ]; then
		$BASH $GHDLLatticeScript --all --vhdl2008 -s -n --src $SourceDir --out $LatticeDirName
		if [ $? -ne 0 ]; then
			echo 1>&2 -e "${COLORED_ERROR} While executing vendor library compile script from GHDL.${ANSI_NOCOLOR}"
			exit -1;
		fi
	fi
fi

# QuestaSim/ModelSim
# ==============================================================================
if [ "$COMPILE_FOR_VSIM" == "TRUE" ]; then
	# Get GHDL directories
	# <= $VSimBinDir
	# <= $VSimDirName
	GetVSimDirectories $PoC_sh

	# Assemble output directory
	DestDir=$PoCRootDir/$PrecompiledDir/$VSimDirName/$LatticeDirName

	# Create and change to destination directory
	# -> $DestinationDirectory
	CreateDestinationDirectory $DestDir

	test $VERBOSE -eq 1 && echo "  Query pyIPCMI for 'INSTALL.Lattice.Diamond:BinaryDirectory'"
	test $DEBUG   -eq 1 && echo "    $PoC_sh query INSTALL.Lattice.Diamond:BinaryDirectory 2>/dev/null"
	DiamondBinDir=$($PoC_sh query INSTALL.Lattice.Diamond:BinaryDirectory 2>/dev/null)
  if [ $? -ne 0 ]; then
	  echo 1>&2 -e "${COLORED_ERROR} Cannot get Lattice Diamond binary directory.${ANSI_NOCOLOR}"
	  echo 1>&2 -e "${COLORED_MESSAGE} $DiamondBinDir${ANSI_NOCOLOR}"
		echo 1>&2 -e "${ANSI_YELLOW}Run 'poc.sh configure' to configure your Lattice Diamond installation.${ANSI_NOCOLOR}"
		exit -1;
	elif [ $DEBUG -eq 1 ]; then
		echo "    Return value: $DiamondBinDir"
  fi
	Diamond_tcl=$DiamondBinDir/diamondc

	# create an empty modelsim.ini in the altera directory and add reference to parent modelsim.ini
	CreateLocalModelsim_ini

	Simulator=mentor
	Language=vhdl
	Device=all			# all, machxo, ecp, ...

	# compile common libraries
	echo -e "cmpl_libs -lang $Language -sim_vendor $Simulator -sim_path $VSimBinDir -device $Device\nexit" | $Diamond_tcl
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${COLORED_ERROR} Error while compiling Lattice libraries.${ANSI_NOCOLOR}"
		exit -1;
	fi
fi

