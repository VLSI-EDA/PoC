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

	DocumentationDirectory="docs"
	BuildDirectory="_build"
	Builder="html"
	SphinxBinary="sphinx-build"

	echo 1>&2 -e "${YELLOW}Executing Sphinx ...${NOCOLOR}"
	$SphinxBinary -b $Builder -d "./$DocumentationDirectory/$BuildDirectory/doctrees" "./$DocumentationDirectory" "./$DocumentationDirectory/$BuildDirectory/$Builder"

	return 1
}


CloseEnvironment() {
	# echo 1>&2 -e "${YELLOW}Unloading Xilinx ISE environment...${NOCOLOR}"
	return 0
}
