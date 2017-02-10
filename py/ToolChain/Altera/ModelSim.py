# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#                   Thomas B. Preusser
#
# Python Class:     Altera ModelSim specific classes
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
from enum                         import unique
from re                           import compile as re_compile
from subprocess                   import check_output

from lib.Functions                import Init
from ToolChain                    import ConfigurationException, EditionDescription, Edition
from ToolChain.Altera             import AlteraException
from ToolChain.Mentor.ModelSim    import Configuration as Mentor_ModelSim_Configuration, ModelSimException as Mentor_ModelSimException


__api__ = [
	'ModelSimException',
	'AlteraModelSimEditions',
	'Configuration'
]
__all__ = __api__


class ModelSimException(AlteraException, Mentor_ModelSimException):
	pass


@unique
class AlteraModelSimEditions(Edition):
	"""Enumeration of all ModelSim editions provided by Altera."""
	ModelSimAlteraEdition =         EditionDescription(Name="ModelSim Altera Edition",          Section=None)
	ModelSimAlteraStarterEdition =  EditionDescription(Name="ModelSim Altera Starter Edition",  Section=None)


class Configuration(Mentor_ModelSim_Configuration):
	_vendor =               "Altera"                    #: The name of the tools vendor.
	_toolName =             "ModelSim Altera Edition"   #: The name of the tool.
	_section  =             "INSTALL.Altera.ModelSim"   #: The name of the configuration section. Pattern: ``INSTALL.Vendor.ToolName``.
	_multiVersionSupport =  False                       #: Altera ModelSim Edition doesn't support multiple versions.
	_template = {
		"Windows": {
			_section: {
				"Version":                "10.4b",
				"Edition":                "ModelSim Altera Edition",
				"InstallationDirectory":  "${INSTALL.Altera:InstallationDirectory}/${INSTALL.Altera.Quartus:Version}/modelsim_ae",
				"BinaryDirectory":        "${InstallationDirectory}/win32aloem",
				"AdditionalVComOptions":  "",
				"AdditionalVSimOptions":  ""
			}
		},
		"Linux": {
			_section: {
				"Version":                "10.4b",
				"Edition":                "ModelSim Altera Edition",
				"InstallationDirectory":  "${INSTALL.Altera:InstallationDirectory}/${INSTALL.Altera.Quartus:Version}/modelsim_ae",
				"BinaryDirectory":        "${InstallationDirectory}/linuxaloem",
				"AdditionalVComOptions":  "",
				"AdditionalVSimOptions":  ""
			}
		}
	}                                                   #: The template for the configuration sections represented as nested dictionaries.

	def CheckDependency(self):
		"""Check if general Altera support is configured in PoC."""
		return (len(self._host.PoCConfig['INSTALL.Altera']) != 0)

	def ConfigureForAll(self):
		try:
			if (not self._AskInstalled("Is ModelSim Altera Edition installed on your system?")):
				self.ClearSection()
			else:
				# Configure ModelSim version

				changed,edition = self._ConfigureEdition()
				if changed:
					configSection = self._host.PoCConfig[self._section]
					if (edition is AlteraModelSimEditions.ModelSimAlteraEdition):
						configSection['InstallationDirectory'] = self._host.PoCConfig.get(self._section, 'InstallationDirectory', raw=True).replace("_ase", "_ae")
					elif (edition is AlteraModelSimEditions.ModelSimAlteraStarterEdition):
						configSection['InstallationDirectory'] = self._host.PoCConfig.get(self._section, 'InstallationDirectory', raw=True).replace("_ae", "_ase")

				self._ConfigureInstallationDirectory()
				binPath = self._ConfigureBinaryDirectory()
				self.__GetModelSimVersion(binPath)
				self._host.LogNormal("{DARK_GREEN}Altera ModelSim is now configured.{NOCOLOR}".format(**Init.Foreground), indent=1)
		except ConfigurationException:
			self.ClearSection()
			raise

	def _ConfigureEdition(self):
		"""Configure ModelSim for Altera."""
		configSection =   self._host.PoCConfig[self._section]
		defaultEdition =  AlteraModelSimEditions.Parse(configSection['Edition'])
		edition =         super()._ConfigureEdition(AlteraModelSimEditions, defaultEdition)

		if (edition is not defaultEdition):
			configSection['Edition'] = edition.Name
			self._host.PoCConfig.Interpolation.clear_cache()
			return (True, edition)
		else:
			return (False, edition)

	def __GetModelSimVersion(self, binPath):
		if (self._host.Platform == "Windows"):
			vsimPath = binPath / "vsim.exe"
		else:
			vsimPath = binPath / "vsim"

		if not vsimPath.exists():
			raise ConfigurationException("Executable '{0!s}' not found.".format(vsimPath)) \
				from FileNotFoundError(str(vsimPath))

		# get version and backend
		try:
			output = check_output([str(vsimPath), "-version"], universal_newlines=True)
		except OSError as ex:
			raise ConfigurationException("Error while accessing '{0!s}'.".format(vsimPath)) from ex

		version = None
		versionRegExpStr = r"^.* vsim (.+?) "
		versionRegExp = re_compile(versionRegExpStr)
		for line in output.split('\n'):
			if version is None:
				match = versionRegExp.match(line)
				if match is not None:
					version = match.group(1)

		self._host.PoCConfig[self._section]['Version'] = version
