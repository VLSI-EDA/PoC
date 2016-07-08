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

	# if $LSC_DIAMOND environment variable is not set
	if [ -z "$LSC_DIAMOND" ]; then
		Query="INSTALL.Lattice.Diamond:BinaryDirectory"
		PoC_Command="$Py_Interpreter $PoC_Query query $Query"
		test $Debug -eq 1 && echo -e "${YELLOW}Inquire Lattice Diamond binary directory: command='$PoC_Command'${NOCOLOR}"
		Diamond_BinDir=$($PoC_Command)
		if [ $? -ne 0 ]; then
			echo 1>&2 -e "${RED}ERROR: ExitCode for '$PoC_Command' was not zero. Aborting script execution.${NOCOLOR}"
			echo 1>&2 -e "${RED}$Diamond_BinDir${NOCOLOR}"
			return 1
		fi
		test $Debug -eq 1 && echo 1>&2 -e "${YELLOW}Lattice Diamond binary directory: '$Diamond_BinDir'${NOCOLOR}"
		if [ -z "$Diamond_BinDir" ]; then
			echo 1>&2 -e "${RED}No Lattice Diamond installation found.${NOCOLOR}"
			echo 1>&2 -e "${RED}Run 'PoC.py configure' to configure your Lattice Diamond installation.${NOCOLOR}"
			return 1
		fi
		# QUESTION: move into PoC.py query like ISESettingsFile ?
		Diamond_SettingsFile=$Diamond_BinDir/diamond_env
		if [ ! -f "$Diamond_SettingsFile" ]; then
			echo 1>&2 -e "${RED}Lattice Diamond settings file not found.${NOCOLOR}"
			echo 1>&2 -e "${RED}Run 'PoC.py configure' to configure your Lattice Diamond installation.${NOCOLOR}"
			return 1
		fi

		echo -e "${YELLOW}Loading Lattice Diamond environment '$Diamond_SettingsFile'...${NOCOLOR}"
		PyWrapper_RescueArgs=$@
		set --
		bindir=$Diamond_BinDir #variable required by diamond_env
		source $Diamond_SettingsFile
		unset bindir
		set -- $PyWrapper_RescueArgs

		return 0
	fi
}

CloseEnvironment() {
	# echo 1>&2 -e "${YELLOW}Unloading Lattice Diamond environment...${NOCOLOR}"
	return 0
}
