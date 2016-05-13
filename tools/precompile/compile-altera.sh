#!/bin/bash
# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
#	Authors:				 	Martin Zabel
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

poc_sh=../../poc.sh
Simulator=ghdl					# questasim, ghdl, ...
Language=vhdl								# vhdl
TargetArchitecture="cycloneiii	stratixiv"		# space separated device list

ghdlScript=/space/install/ghdl/libraries/vendors/compile-altera.sh

# define color escape codes
RED='\e[0;31m'			# Red
YELLOW='\e[1;33m'		# Yellow
NOCOLOR='\e[0m'			# No Color

# Setup command to execute
if [ "$Simulator" != ghdl ]; then
  QuartusSH=$($poc_sh query INSTALL.Altera.Quartus:BinaryDirectory 2>/dev/null)/quartus_sh
  if [ $? -ne 0 ]; then
	  echo 1>&2 -e "${RED}ERROR: Cannot get Altera Quartus binary dir.${NOCOLOR}"
	  exit;
  fi
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
	questasim)
		DestDir=$DestDir/vsim/altera
		;;
	*)
		echo "Unsupported simulator."
		exit 1
		;;
esac

# Setup simulator directory
case "$Simulator" in
	questasim)
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

# Compile libraries with simulator, executed in destination directory
case "$Simulator" in
	ghdl)
		$ghdlScript -a -s -S
		;;
	questasim)
		# create modelsim.ini
		echo "[Library]" > modelsim.ini
		echo "others = ../modelsim.ini" >> modelsim.ini
		if [ $? -ne 0 ]; then
			echo 1>&2 -e "${RED}ERROR: Cannot create initial modelsim.ini.${NOCOLOR}"
			exit;
		fi

		# call compile script
		$QuartusSH --simlib_comp -tool $Simulator -language $Language -tool_path $SimulatorDir -directory $DestDir -rtl_only

		for Family in $TargetArchitecture; do
			$QuartusSH --simlib_comp -tool $Simulator -language $Language -family $Family -tool_path $SimulatorDir -directory $DestDir -no_rtl
		done
		;;
	*)
		echo "Unsupported simulator."
		exit 1
		;;
esac
