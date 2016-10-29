# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
#	Authors:						Patrick Lehmann
#
#	BashModule:
#
# Description:
# ------------------------------------
#	TODO:
#		-
#
# License:
# ==============================================================================
# Copyright 2007-2016 Technische Universitaet Dresden - Germany
#                     Chair for VLSI-Design, Diagnostics and Architecture
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================

OpenEnvironment() {
	Debug=0
	Py_Interpreter=$1
	# Py_Parameters=$2
	PoC_Query=$2

	# if $XILINX environment variable is not set
	if [ -z "$XILINX" ]; then
		Query="Xilinx.ISE:SettingsFile"
		PoC_Command="$Py_Interpreter $PoC_Query query $Query"
		test $Debug -eq 1 && echo 1>&2 -e "${YELLOW}Inquire ISE settings file: command='$PoC_Command'${NOCOLOR}"
		ISE_SettingsFile=$($PoC_Command)
		if [ $? -ne 0 ]; then
			echo 1>&2 -e "${RED}ERROR: ExitCode for '$PoC_Command' was not zero. Aborting script execution.${NOCOLOR}"
			echo 1>&2 -e "${RED}$ISE_SettingsFile${NOCOLOR}"
			return 1
		fi
		test $Debug -eq 1 && echo 1>&2 -e "${YELLOW}ISE settings file: '$ISE_SettingsFile'${NOCOLOR}"
		if [ -z "$ISE_SettingsFile" ]; then
			echo 1>&2 -e "${RED}No Xilinx ISE installation found.${NOCOLOR}"
			echo 1>&2 -e "${RED}Run 'PoC.py configure' to configure your Xilinx ISE installation.${NOCOLOR}"
			return 1
		fi
		if [ ! -f "$ISE_SettingsFile" ]; then
			echo 1>&2 -e "${RED}Xilinx ISE settings file not found.${NOCOLOR}"
			echo 1>&2 -e "${RED}Run 'PoC.py configure' to configure your Xilinx ISE installation.${NOCOLOR}"
			return 1
		fi

		echo 1>&2 -e "${YELLOW}Loading Xilinx ISE environment '$ISE_SettingsFile'...${NOCOLOR}"
		PyWrapper_RescueArgs=$@
		set --
		source "$ISE_SettingsFile"
		set -- $PyWrapper_RescueArgs

		return 0
	fi
}

CloseEnvironment() {
	# echo 1>&2 -e "${YELLOW}Unloading Xilinx ISE environment...${NOCOLOR}"
	return 0
}


