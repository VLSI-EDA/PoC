#! /usr/bin/env bash
# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
#	Authors:					Patrick Lehmann
#
#	Bash Script:			Compile UVVM simulation packages
#
# Description:
# ------------------------------------
#	This is a Bash script (executable) which:
#		- creates a subdirectory in the current working directory
#		- compiles all UVVM packages
#
# License:
# ==============================================================================
# Copyright 2007-2017 Technische Universitaet Dresden - Germany
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
#
# configure script here
UVVMLibDir=lib/uvvm

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
	echo "  Script to compile the simulation library UVVM for"
	echo "  - GHDL"
	echo "  - QuestaSim/ModelSim"
	echo "  on Linux."
	echo ""
	echo "Usage:"
	echo "  compile-uvvm.sh [-c] [--help|--all|--ghdl|--questa]"
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

UVVMDirName=uvvm
# GHDL
# ==============================================================================
if [ "$COMPILE_FOR_GHDL" == "TRUE" ]; then
	# Get GHDL directories
	# <= $GHDLBinDir
	# <= $GHDLScriptDir
	# <= $GHDLDirName
	GetGHDLDirectories $PoC_sh

	# Assemble output directory
	DestDir=$PoCRootDir/$PrecompiledDir/$GHDLDirName/$UVVMDirName
	# Create and change to destination directory
	# -> $DestinationDirectory
	CreateDestinationDirectory $DestDir

	# Assemble Altera compile script path
	GHDLUVVMScript="$($READLINK -f $GHDLScriptDir/compile-uvvm.sh)"


	# Get UVVM installation directory
	UVVMInstallDir=$PoCRootDir/$UVVMLibDir
	SourceDir=$UVVMInstallDir

	# export GHDL binary dir if not allready set
	if [ -z $GHDL ]; then
		export GHDL=$GHDLBinDir/ghdl
	fi

	BASH=$(which bash)

	# compile all architectures, skip existing and large files, no wanrings
	$BASH $GHDLUVVMScript --all -n --src $SourceDir --out "."
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${COLORED_ERROR} While executing vendor library compile script from GHDL.${ANSI_NOCOLOR}"
		exit -1;
	fi

	# # Cleanup
	# if [ "$CLEAN" == "TRUE" ]; then
		# echo -e "${YELLOW}Cleaning library 'uvvm' ...${ANSI_NOCOLOR}"
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
	DestDir=$PoCRootDir/$PrecompiledDir/$VSimDirName/$UVVMDirName
	# Create and change to destination directory
	# -> $DestinationDirectory
	CreateDestinationDirectory $DestDir


	# clean uvvm_util directory
	if [ -d $DestDir/uvvm_util ]; then
		echo -e "${YELLOW}Cleaning library 'uvvm_util' ...${ANSI_NOCOLOR}"
		rm -rf uvvm_util
	fi

	# Get UVVM installation directory
	UVVMInstallDir=$PoCRootDir/$UVVMLibDir
	SourceDir=$UVVMInstallDir

	# Files
	Library=uvvm_util
	Files=(
		uvvm_util/src/types_pkg.vhd
		uvvm_util/src/adaptations_pkg.vhd
		uvvm_util/src/string_methods_pkg.vhd
		uvvm_util/src/protected_types_pkg.vhd
		uvvm_util/src/hierarchy_linked_list_pkg.vhd
		uvvm_util/src/alert_hierarchy_pkg.vhd
		uvvm_util/src/license_pkg.vhd
		uvvm_util/src/methods_pkg.vhd
		uvvm_util/src/bfm_common_pkg.vhd
		uvvm_util/src/uvvm_util_context.vhd
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
		$VSimBinDir/vcom -suppress 1346,1236 -2008 -work $Library $SourceDir/$File
		if [ $? -ne 0 ]; then
			let ERRORCOUNT++
		fi
	done

	# Files
	Library=uvvm_vvc_framework
	Files=(
		uvvm_vvc_framework/src/ti_vvc_framework_support_pkg.vhd
		uvvm_vvc_framework/src/ti_generic_queue_pkg.vhd
		uvvm_vvc_framework/src/ti_data_queue_pkg.vhd
		uvvm_vvc_framework/src/ti_data_fifo_pkg.vhd
		uvvm_vvc_framework/src/ti_data_stack_pkg.vhd
		uvvm_vvc_framework/src/ti_uvvm_engine.vhd
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
		$VSimBinDir/vcom -suppress 1346,1236 -2008 -work $Library $SourceDir/$File
		if [ $? -ne 0 ]; then
			let ERRORCOUNT++
		fi
	done

	# Files
	Library=bitvis_vip_avalon_mm
	Files=(
		bitvis_vip_avalon_mm/src/avalon_mm_bfm_pkg.vhd
		bitvis_vip_avalon_mm/src/vvc_cmd_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_target_support_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_vvc_framework_common_methods_pkg.vhd
		bitvis_vip_avalon_mm/src/vvc_methods_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_queue_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_vvc_entity_support_pkg.vhd
		bitvis_vip_avalon_mm/src/avalon_mm_vvc.vhd
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
		$VSimBinDir/vcom -suppress 1346,1236 -2008 -work $Library $SourceDir/$File
		if [ $? -ne 0 ]; then
			let ERRORCOUNT++
		fi
	done

	# Files
	Library=bitvis_vip_axilite
	Files=(
		bitvis_vip_axilite/src/axilite_bfm_pkg.vhd
		bitvis_vip_axilite/src/vvc_cmd_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_target_support_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_vvc_framework_common_methods_pkg.vhd
		bitvis_vip_axilite/src/vvc_methods_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_queue_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_vvc_entity_support_pkg.vhd
		bitvis_vip_axilite/src/axilite_vvc.vhd
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
		$VSimBinDir/vcom -suppress 1346,1236 -2008 -work $Library $SourceDir/$File
		if [ $? -ne 0 ]; then
			let ERRORCOUNT++
		fi
	done

	# Files
	Library=bitvis_vip_axistream
	Files=(
		bitvis_vip_axistream/src/axistream_bfm_pkg.vhd
		bitvis_vip_axistream/src/vvc_cmd_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_target_support_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_vvc_framework_common_methods_pkg.vhd
		bitvis_vip_axistream/src/vvc_methods_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_queue_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_vvc_entity_support_pkg.vhd
		bitvis_vip_axistream/src/axistream_vvc.vhd
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
		$VSimBinDir/vcom -suppress 1346,1236 -2008 -work $Library $SourceDir/$File
		if [ $? -ne 0 ]; then
			let ERRORCOUNT++
		fi
	done

	# Files
	Library=bitvis_vip_gpio
	Files=(
		bitvis_vip_gpio/src/gpio_bfm_pkg.vhd
		bitvis_vip_gpio/src/vvc_cmd_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_target_support_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_vvc_framework_common_methods_pkg.vhd
		bitvis_vip_gpio/src/vvc_methods_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_queue_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_vvc_entity_support_pkg.vhd
		bitvis_vip_gpio/src/gpio_vvc.vhd
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
		$VSimBinDir/vcom -suppress 1346,1236 -2008 -work $Library $SourceDir/$File
		if [ $? -ne 0 ]; then
			let ERRORCOUNT++
		fi
	done

	# Files
	Library=bitvis_vip_i2c
	Files=(
		bitvis_vip_i2c/src/i2c_bfm_pkg.vhd
		bitvis_vip_i2c/src/vvc_cmd_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_target_support_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_vvc_framework_common_methods_pkg.vhd
		bitvis_vip_i2c/src/vvc_methods_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_queue_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_vvc_entity_support_pkg.vhd
		bitvis_vip_i2c/src/i2c_vvc.vhd
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
		$VSimBinDir/vcom -suppress 1346,1236 -2008 -work $Library $SourceDir/$File
		if [ $? -ne 0 ]; then
			let ERRORCOUNT++
		fi
	done

	# Files
	Library=bitvis_vip_sbi
	Files=(
		bitvis_vip_sbi/src/sbi_bfm_pkg.vhd
		bitvis_vip_sbi/src/vvc_cmd_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_target_support_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_vvc_framework_common_methods_pkg.vhd
		bitvis_vip_sbi/src/vvc_methods_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_queue_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_vvc_entity_support_pkg.vhd
		bitvis_vip_sbi/src/sbi_vvc.vhd
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
		$VSimBinDir/vcom -suppress 1346,1236 -2008 -work $Library $SourceDir/$File
		if [ $? -ne 0 ]; then
			let ERRORCOUNT++
		fi
	done

	# Files
	Library=bitvis_vip_spi
	Files=(
		bitvis_vip_spi/src/spi_bfm_pkg.vhd
		bitvis_vip_spi/src/vvc_cmd_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_target_support_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_vvc_framework_common_methods_pkg.vhd
		bitvis_vip_spi/src/vvc_methods_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_queue_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_vvc_entity_support_pkg.vhd
		bitvis_vip_spi/src/spi_vvc.vhd
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
		$VSimBinDir/vcom -suppress 1346,1236 -2008 -work $Library $SourceDir/$File
		if [ $? -ne 0 ]; then
			let ERRORCOUNT++
		fi
	done

	# Files
	Library=bitvis_vip_uart
	Files=(
		bitvis_vip_uart/src/uart_bfm_pkg.vhd
		bitvis_vip_uart/src/vvc_cmd_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_target_support_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_vvc_framework_common_methods_pkg.vhd
		bitvis_vip_uart/src/vvc_methods_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_queue_pkg.vhd
		uvvm_vvc_framework/src_target_dependent/td_vvc_entity_support_pkg.vhd
		bitvis_vip_uart/src/uart_rx_vvc.vhd
		bitvis_vip_uart/src/uart_tx_vvc.vhd
		bitvis_vip_uart/src/uart_vvc.vhd
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
		$VSimBinDir/vcom -suppress 1346,1236 -2008 -work $Library $SourceDir/$File
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
