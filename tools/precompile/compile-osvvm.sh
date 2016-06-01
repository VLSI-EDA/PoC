#! /bin/bash
# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
#	Bash Script:				Script to compile the OSVVM library for Questa / ModelSim
#                     on Linux
# 
#	Authors:						Patrick Lehmann
#                     Martin Zabel
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
Simulator=questasim					# questasim, ghdl, ...

# define color escape codes
RED='\e[0;31m'			# Red
YELLOW='\e[1;33m'		# Yellow
NOCOLOR='\e[0m'			# No Color

# Files
SourceDir=$($poc_sh query INSTALL.PoC:InstallationDirectory 2>/dev/null)/lib/osvvm
if [ $? -ne 0 ]; then
	echo 1>&2 -e "${RED}ERROR: Cannot get PoC installation dir.${NOCOLOR}"
	exit;
fi 
Files=(
		$SourceDir/NamePkg.vhd
		$SourceDir/OsvvmGlobalPkg.vhd
		$SourceDir/TextUtilPkg.vhd
		$SourceDir/TranscriptPkg.vhd
		$SourceDir/AlertLogPkg.vhd
		$SourceDir/MemoryPkg.vhd
		$SourceDir/MessagePkg.vhd
		$SourceDir/SortListPkg_int.vhd
		$SourceDir/RandomBasePkg.vhd
		$SourceDir/RandomPkg.vhd
		$SourceDir/CoveragePkg.vhd
		$SourceDir/OsvvmContext.vhd
)

# Simulator binary directory
case "$Simulator" in
	ghdl)
		BinDir=$($poc_sh query INSTALL.GHDL:BinaryDirectory 2>/dev/null)	# Path to the simulators bin directory
		if [ $? -ne 0 ]; then
			echo 1>&2 -e "${RED}ERROR: Cannot get GHDL binary dir.${NOCOLOR}"
			exit;
		fi
		;;
	questasim)
		BinDir=$($poc_sh query ModelSim:BinaryDirectory 2>/dev/null)	# Path to the simulators bin directory
		if [ $? -ne 0 ]; then
			echo 1>&2 -e "${RED}ERROR: Cannot get ModelSim binary dir.${NOCOLOR}"
			exit;
		fi
		;;
	*)
		echo "Unsupported simulator."
		exit 1
		;;
esac

# Setup destination directory
DestDir=$($poc_sh query INSTALL.PoC:InstallationDirectory 2>/dev/null)/temp/precompiled
if [ $? -ne 0 ]; then
	echo 1>&2 -e "${RED}ERROR: Cannot get PoC installation dir.${NOCOLOR}"
	exit;
fi 

case "$Simulator" in
	ghdl)
		DestDir=$DestDir/ghdl/osvvm
		;;
	questasim)
		DestDir=$DestDir/vsim
		;;
	*)
		echo "Unsupported simulator."
		exit 1
		;;
esac

# Create and change to destination directory
mkdir -p $DestDir
if [ $? -ne 0 ]; then
	echo 1>&2 -e "${RED}ERROR: Cannot create output directory.${NOCOLOR}"
	exit;
fi 

cd $DestDir
if [ $? -ne 0 ]; then
	echo 1>&2 -e "${RED}ERROR: Cannot change to output directory.${NOCOLOR}"
	exit;
fi

# Compile libraries with simulator, executed in destination directory
case "$Simulator" in
  ghdl)
		for file in ${Files[@]}; do
			echo "Compiling $file..."
			$BinDir/ghdl -a -fexplicit -frelaxed-rules --no-vital-checks --warn-binding --mb-comments --std=08 --work=osvvm $file
		done
		;;
	questasim)
		rm -rf osvvm
		vlib osvvm
		vmap -del osvvm
		vmap osvvm $DestDir/osvvm
		for file in ${Files[@]}; do
			echo "Compiling $file..."
			$BinDir/vcom -2008 -work osvvm $file
		done
		;;
	*)
		echo "Unsupported simulator."
		exit 1
		;;
esac
