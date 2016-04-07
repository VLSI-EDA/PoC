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

# define color escape codes
RED='\e[0;31m'			# Red
YELLOW='\e[1;33m'		# Yellow
NOCOLOR='\e[0m'			# No Color

# Setup command to execute
DestDir=$($poc_sh --poc-installdir 2>/dev/null)/temp/vsim	# Output directory
if [ $? -ne 0 ]; then
	echo "${RED}ERROR: Cannot get PoC installation dir.${NOCOLOR}"
	exit;
fi 
SimulatorDir=$($poc_sh --modelsim-installdir 2>/dev/null)/bin	# Path to the simulators bin directory
if [ $? -ne 0 ]; then
	echo "${RED}ERROR: Cannot get ModelSim installation dir.${NOCOLOR}"
	exit;
fi 

SourceDir=$($poc_sh --poc-installdir 2>/dev/null)/lib/osvvm
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

# Check if modelsim.ini exists in DestDir
if [ ! -f "$DestDir/modelsim.ini" ]; then
	echo "Please run compile-xilinx-ise.sh first."
	exit 1
fi

# Execute command
cd $DestDir
rm -rf osvvm
vlib osvvm
vmap osvvm osvvm
for File in ${Files[@]}; do
	vcom -2008 -work osvvm $File
done
