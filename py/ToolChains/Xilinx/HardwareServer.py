# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#
# Python Class:      Xilinx Hardware Server specific classes
#
# Description:
# ------------------------------------
#		TODO:
#		-
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
#
# entry point
if __name__ != "__main__" :
	# place library initialization code here
	pass
else :
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module ToolChains.Xilinx.HardwareServer")

from Base.Configuration import Configuration as BaseConfiguration


class Configuration(BaseConfiguration):
	_vendor =    "Xilinx"
	_toolName =  "Xilinx HardwareServer"
	_section =   "INSTALL.Xilinx.HardwareServer"
	_template = {
		"Windows": {
			_section: {
				"Version":                "2015.4",
				"InstallationDirectory":  "${INSTALL.Xilinx:InstallationDirectory}/Vivado/${Version}",
				"BinaryDirectory":        "${InstallationDirectory}/bin"
			}
		},
		"Linux": {
			_section: {
				"Version":                "2015.4",
				"InstallationDirectory":  "${INSTALL.Xilinx:InstallationDirectory}/Vivado/${Version}",
				"BinaryDirectory":        "${InstallationDirectory}/bin"
			}
		}
	}

	def CheckDependency(self):
		# return True if Xilinx is configured
		return (len(self._host.PoCConfig['INSTALL.Xilinx']) != 0)
