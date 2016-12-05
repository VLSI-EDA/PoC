# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#
# Python Class:     Intel Quartus specific classes
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
from subprocess                 import check_output, STDOUT

from ToolChains import ConfigurationException
from ToolChains.Altera.Quartus  import QuartusException as Altera_QuartusException, Configuration as Altera_Quartus_Configuration, Quartus as Altera_Quartus, Map as Altera_Quartus_Map
from ToolChains.Intel           import IntelException
from lib.Functions import Init


__api__ = [
	'QuartusException',
	'Configuration',
	'Quartus',
	'Map'
]
__all__ = __api__


class QuartusException(IntelException, Altera_QuartusException):
	pass


class Configuration(Altera_Quartus_Configuration):
	_vendor =               "Intel"                     #: The name of the tools vendor.
	_toolName =             "Intel Quartus"             #: The name of the tool.
	_section =              "INSTALL.Intel.Quartus"     #: The name of the configuration section. Pattern: ``INSTALL.Vendor.ToolName``.
	_multiVersionSupport =  True                        #: Intel Quartus supports multiple versions installed on the same system.
	_template = {
		"Windows": {
			_section: {
				"Version":                "16.1",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Intel:InstallationDirectory}/${Version}/quartus"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/bin64")
			}
		},
		"Linux": {
			_section: {
				"Version":                "16.1",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Intel:InstallationDirectory}/${Version}/quartus"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/bin")
			}
		}
	}                                                   #: The template for the configuration sections represented as nested dictionaries.

	def CheckDependency(self):
		"""Check if general Intel support is configured in PoC."""
		return (len(self._host.PoCConfig['INSTALL.Intel']) != 0)

	def ConfigureForAll(self):
		try:
			if (not self._AskInstalled("Is Intel Quartus Prime installed on your system?")):
				self.ClearSection()
			else:
				# Configure Quartus version
				version = self._ConfigureVersion()
				if self._multiVersionSupport:
					self.PrepareVersionedSections()
					sectionName = self._host.PoCConfig[self._section]['SectionName']
					self._host.PoCConfig[sectionName]['Version'] = version

				self._ConfigureInstallationDirectory()
				binPath = self._ConfigureBinaryDirectory()

				self.LogNormal("Checking Altera Quartus version... (this may take a few seconds)", indent=1)
				self.__CheckQuartusVersion(binPath, version)

				self._host.LogNormal("{DARK_GREEN}Intel Quartus Prime is now configured.{NOCOLOR}".format(**Init.Foreground), indent=1)
		except ConfigurationException:
			self.ClearSection()
			raise

	def __CheckQuartusVersion(self, binPath, version):
		if (self._host.Platform == "Windows"):
			quartusPath = binPath / "quartus_sh.exe"
		else:
			quartusPath = binPath / "quartus_sh"

		if not quartusPath.exists():
			raise ConfigurationException("Executable '{0!s}' not found.".format(quartusPath)) from FileNotFoundError(
				str(quartusPath))

		output = check_output([str(quartusPath), "-v"], universal_newlines=True, stderr=STDOUT)
		if "Version {0}".format(version) not in output:
			raise ConfigurationException("Quartus version mismatch. Expected version {0}.".format(version))


class Quartus(Altera_Quartus):
	def GetMap(self):
		return Map(self)

	# def GetTclShell(self):
	# 	return TclShell(self)


class Map(Altera_Quartus_Map):
	pass
