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
#                     Chair of VLSI-Design, Diagnostics and Architecture
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

	# if $XILINX_VIVADO environment variable is not set
	if [ -z "$XILINX_VIVADO" ]; then
		Query="Xilinx.Vivado:SettingsFile"
		PoC_Command="$Py_Interpreter $PoC_Query query $Query"
		test $Debug -eq 1 && echo 1>&2 -e "${YELLOW}Inquire Vivado settings file: command='$PoC_Command'${NOCOLOR}"
		Vivado_SettingsFile=$($PoC_Command)
		if [ $? -ne 0 ]; then
			echo 1>&2 -e "${RED}ERROR: ExitCode for '$PoC_Command' was not zero. Aborting script execution.${NOCOLOR}"
			echo 1>&2 -e "${RED}$Vivado_SettingsFile${NOCOLOR}"
			return 1
		fi
		test $Debug -eq 1 && echo 1>&2 -e "${YELLOW}Vivado settings file: '$Vivado_SettingsFile'${NOCOLOR}"
		if [ -z "$Vivado_SettingsFile" ]; then
			echo 1>&2 -e "${RED}No Xilinx Vivado installation found.${NOCOLOR}"
			echo 1>&2 -e "${RED}Run 'PoC.py configure' to configure your Xilinx Vivado installation.${NOCOLOR}"
			return 1
		fi
		if [ ! -f "$Vivado_SettingsFile" ]; then
			echo 1>&2 -e "${RED}Xilinx Vivado settings file not found.${NOCOLOR}"
			echo 1>&2 -e "${RED}Run 'PoC.py configure' to configure your Xilinx Vivado installation.${NOCOLOR}"
			return 1
		fi

		echo 1>&2 -e "${YELLOW}Loading Xilinx Vivado environment '$Vivado_SettingsFile'...${NOCOLOR}"
		PyWrapper_RescueArgs=$@
		set --
		source "$Vivado_SettingsFile"
		set -- $PyWrapper_RescueArgs

		return 0
	fi
}

CloseEnvironment() {
	# echo 1>&2 -e "${YELLOW}Unloading Xilinx Vivado environment...${NOCOLOR}"
	return 0
}


