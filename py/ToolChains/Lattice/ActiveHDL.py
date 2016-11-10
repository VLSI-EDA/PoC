# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#
# Python Class:      Lattice Active-HDL specific classes
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
#
# entry point
if __name__ != "__main__":
	# place library initialization code here
	pass
else:
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module ToolChains.Lattice.ActiveHDL")


from subprocess                  import check_output

from Base.Configuration          import Configuration as BaseConfiguration, ConfigurationException
from ToolChains.Lattice.Lattice  import LatticeException


class ActiveHDLException(LatticeException):
	pass


class Configuration(BaseConfiguration):
	_vendor =    "Lattice"
	_toolName =  "Active-HDL Lattice Edition"
	_section =  "INSTALL.Lattice.ActiveHDL"
	_template = {
		"Windows": {
			_section: {
				"Version":                "10.2",
				"InstallationDirectory":  "${INSTALL.Lattice.Diamond:InstallationDirectory}/active-hdl",
				"BinaryDirectory":        "${InstallationDirectory}/BIN"
			}
		},
		"Linux": {
			_section: {
			# 	"Version":                "15.0",
			# 	"InstallationDirectory":  "${INSTALL.Lattice:InstallationDirectory}/${Version}/activeHDL",
			# 	"BinaryDirectory":        "${InstallationDirectory}/fix_me"
			}
		}
	}

	def CheckDependency(self):
		# return True if Lattice is configured
		return (len(self._host.PoCConfig['INSTALL.Lattice.Diamond']) != 0)

	def ConfigureForAll(self):
		try:
			if (not self._AskInstalled("Is Aldec Active-HDL installed on your system?")):
				self.ClearSection()
			else:
				version = self._ConfigureVersion()
				self._ConfigureInstallationDirectory()
				binPath = self._ConfigureBinaryDirectory()
				self.__CheckActiveHDLVersion(binPath, version)
		except ConfigurationException:
			self.ClearSection()
			raise

	def __CheckActiveHDLVersion(self, binPath, version):
		if (self._host.Platform == "Windows"):
			vsimPath = binPath / "vsim.exe"
		else:
			vsimPath = binPath / "vsim"

		if not vsimPath.exists():
			raise ConfigurationException("Executable '{0!s}' not found.".format(vsimPath)) from FileNotFoundError(
				str(vsimPath))

		output = check_output([str(vsimPath), "-version"], universal_newlines=True)
		if str(version) not in output:
			raise ConfigurationException("Active-HDL version mismatch. Expected version {0}.".format(version))
