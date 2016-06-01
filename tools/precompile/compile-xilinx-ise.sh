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
Simulator=questa						# questa, ghdl, ...
Language=vhdl								# all, vhdl, verilog
TargetArchitecture=all			# all, virtex5, virtex6, virtex7, ...

ghdlScript=/space/install/ghdl/libraries/vendors/compile-xilinx-ise.sh

# define color escape codes
RED='\e[0;31m'			# Red
YELLOW='\e[1;33m'		# Yellow
NOCOLOR='\e[0m'			# No Color

# if $XILINX environment variable is not set and Simulator /= ghdl
if [ -z "$XILINX" -a \( "$Simulator" != "ghdl" \) ]; then
	PoC_ISE_SettingsFile=$($poc_sh query Xilinx.ISE:SettingsFile)
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

# Setup destination directory
DestDir=$($poc_sh query INSTALL.PoC:InstallationDirectory 2>/dev/null)/temp/precompiled
if [ $? -ne 0 ]; then
	echo 1>&2 -e "${RED}ERROR: Cannot get PoC installation dir.${NOCOLOR}"
	exit;
fi 

case "$Simulator" in
	ghdl)
		DestDir=$DestDir/ghdl
		;;
	questa)
		DestDir=$DestDir/vsim/xilinx-ise
		;;
	*)
		echo "Unsupported simulator."
		exit 1
		;;
esac

# Setup simulator directory
case "$Simulator" in
	questa)
		SimulatorDir=$($poc_sh query ModelSim:InstallationDirectory 2>/dev/null)/bin	# Path to the simulators bin directory
		if [ $? -ne 0 ]; then
			echo 1>&2 -e "${RED}ERROR: Cannot get ModelSim installation dir.${NOCOLOR}"
			exit;
		fi 
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

# Compile libraries with simulator, executed in $DestDir
case "$Simulator" in
	ghdl)
		$ghdlScript -a -s -S
		;;
	questa)
		# create modelsim.ini
		echo "[Library]" > modelsim.ini
		echo "others = ../modelsim.ini" >> modelsim.ini
		if [ $? -ne 0 ]; then
			echo 1>&2 -e "${RED}ERROR: Cannot create initial modelsim.ini.${NOCOLOR}"
			exit;
		fi

		# call Xilinx script
		compxlib -64bit -s $Simulator -l $Language -dir $DestDir -p $SimulatorDir -arch $TargetArchitecture -lib unisim -lib simprim -lib xilinxcorelib -intstyle ise
		cd ..
		;;
	*)
		echo "Unsupported simulator."
		exit 1
		;;
esac

# create "xilinx" symlink
rm -f xilinx
ln -s xilinx-ise xilinx
