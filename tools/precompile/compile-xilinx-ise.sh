#!/bin/bash
# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
#	Authors:				 	Martin Zabel
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

poc_sh=../../poc.sh
Simulator=questa						# questa, ...
Language=vhdl								# all, vhdl, verilog
TargetArchitecture=all			# all, virtex5, virtex6, virtex7, ...

# define color escape codes
RED='\e[0;31m'			# Red
YELLOW='\e[1;33m'		# Yellow
NOCOLOR='\e[0m'			# No Color

# if $XILINX environment variable is not set
if [ -z "$XILINX" ]; then
	PoC_ISE_SettingsFile=$($poc_sh --ise-settingsfile)
	if [ $? -ne 0 ]; then
		echo 1>&2 -e "${RED}ERROR: No Xilinx ISE installation found.${NOCOLOR}"
		echo 1>&2 -e "${RED}Run 'PoC.py --configure' to configure your Xilinx ISE installation.${NOCOLOR}"
		exit 1
	fi
	echo -e "${YELLOW}Loading Xilinx ISE environment '$PoC_ISE_SettingsFile'${NOCOLOR}"
	PyWrapper_RescueArgs=$@
	set --
	source "$PoC_ISE_SettingsFile"
	set -- $PyWrapper_RescueArgs
fi

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

# Execute command
compxlib -64bit -s $Simulator -l $Language -dir $DestDir -p $SimulatorDir -arch $TargetArchitecture -lib unisim -lib simprim -lib xilinxcorelib -intstyle ise
