# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#
# Python Class:     Lattice Active-HDL specific classes
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
# load dependencies
from subprocess                   import check_output

from lib.Functions                import Init
from ToolChain                    import ConfigurationException
from ToolChain.Lattice            import LatticeException
from ToolChain.Aldec.ActiveHDL    import Configuration as ActiveHDL_Configuration, ActiveHDLException as Aldec_ActiveHDL_ActiveHDLException


class ActiveHDLException(LatticeException, Aldec_ActiveHDL_ActiveHDLException):
	pass


class Configuration(ActiveHDL_Configuration):
	_vendor =               "Lattice"                     #: The name of the tools vendor.
	_toolName =             "Active-HDL Lattice Edition"  #: The name of the tool.
	_section  =             "INSTALL.Lattice.ActiveHDL"   #: The name of the configuration section. Pattern: ``INSTALL.Vendor.ToolName``.
	_template = {
		"Windows": {
			_section: {
				"Version":                "10.3",
				"InstallationDirectory":  "${INSTALL.Lattice.Diamond:InstallationDirectory}/active-hdl",
				"BinaryDirectory":        "${InstallationDirectory}/BIN"
			}
		}
	}                                                   #: The template for the configuration sections represented as nested dictionaries.

	def CheckDependency(self):
		"""Check if Lattice Diamond support is configured in PoC."""
		return (len(self._host.PoCConfig['INSTALL.Lattice.Diamond']) != 0)

	def ConfigureForAll(self):
		try:
			if (not self._AskInstalled("Is Aldec Active-HDL installed on your system?")):
				self.ClearSection()
			else:
				# Configure Active-HDL version
				version = self._ConfigureVersion()


				self._ConfigureInstallationDirectory()
				binPath = self._ConfigureBinaryDirectory()
				self.__CheckActiveHDLVersion(binPath, version)
				self._host.LogNormal("{DARK_GREEN}Lattice Active-HDL is now configured.{NOCOLOR}".format(**Init.Foreground), indent=1)
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
