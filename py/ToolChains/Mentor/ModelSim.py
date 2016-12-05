# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#                   Thomas B. Preusser
#
# Python Class:     Mentor Graphics ModelSim specific classes
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
from collections                  import OrderedDict
from enum                         import unique
from re                           import compile as re_compile
from subprocess                   import check_output

from lib.Functions                import Init
from ToolChains                   import ConfigurationException, EditionDescription, Edition, ToolSelector
from ToolChains.Mentor            import MentorException
from ToolChains.Mentor.QuestaSim  import Configuration as QuestaSim_Configuration


__api__ = [
	'ModelSimException',
	'MentorModelSimEditions',
	'ModelSimEditions',
	'Configuration'
]
__all__ = __api__


class ModelSimException(MentorException):
	pass


@unique
class MentorModelSimEditions(Edition):
	"""Enumeration of all ModelSim editions provided by Mentor Graphics itself."""
	ModelSimPE =            EditionDescription(Name="ModelSim PE",                    Section=None)
	ModelSimPEEducation =   EditionDescription(Name="ModelSim PE (Student Edition)",  Section=None)
	ModelSimSE32 =          EditionDescription(Name="ModelSim SE 32-bit",             Section=None)
	ModelSimSE64 =          EditionDescription(Name="ModelSim SE 64-bit",             Section=None)


@unique
class ModelSimEditions(Edition):
	"""Enumeration of all ModelSim editions provided by Mentor Graphics inclusive
	editions shipped by other vendors.
	"""
	ModelSimPE =                    EditionDescription(Name="ModelSim PE",                      Section="INSTALL.Mentor.ModelSim")
	ModelSimPEEducation =           EditionDescription(Name="ModelSim PE (Student Edition)",    Section="INSTALL.Mentor.ModelSim")
	ModelSimSE32 =                  EditionDescription(Name="ModelSim SE 32-bit",               Section="INSTALL.Mentor.ModelSim")
	ModelSimSE64 =                  EditionDescription(Name="ModelSim SE 64-bit",               Section="INSTALL.Mentor.ModelSim")
	ModelSimAlteraEdition =         EditionDescription(Name="ModelSim Altera Edition",          Section="INSTALL.Altera.ModelSim")
	# ModelSimAlteraStarterEdition =  EditionDescription(Name="ModelSim Altera Starter Edition",  Section=None)
	ModelSimIntelEdition =          EditionDescription(Name="ModelSim Intel Edition",           Section="INSTALL.Intel.ModelSim")
	# ModelSimIntelStarterEdition =   EditionDescription(Name="ModelSim Intel Starter Edition",   Section=None)
	QuestaSim =                     EditionDescription(Name="QuestaSim",                        Section="INSTALL.Mentor.QuestaSim")


class Configuration(QuestaSim_Configuration):
	_vendor =               "Mentor"                    #: The name of the tools vendor.
	_toolName =             "Mentor ModelSim"           #: The name of the tool.
	_section  =             "INSTALL.Mentor.ModelSim"   #: The name of the configuration section. Pattern: ``INSTALL.Vendor.ToolName``.
	_multiVersionSupport =  True                        #: Mentor ModelSim supports multiple versions installed on the same system.
	_template = {
		"Windows": {
			_section: {
				"Version":                "10.5c",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"Edition":                "ModelSim PE",
				"ToolInstallationName":   "ModelSim PE",
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Mentor:InstallationDirectory}/${ToolInstallationName}/${Version}"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/win")  # 32pe / 32pe_edu
			}
		},
		"Linux": {
			_section: {
				"Version":                "10.5c",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"Edition":                "ModelSim PE",
				"ToolInstallationName":   "ModelSim PE",
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Mentor:InstallationDirectory}/${ToolInstallationName}/${Version}"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/linux_x86_64")
			}
		}
	}                                                   #: The template for the configuration sections represented as nested dictionaries.

	def CheckDependency(self):
		"""Check if general Mentor Graphics support is configured in PoC."""
		return (len(self._host.PoCConfig['INSTALL.Mentor']) != 0)

	def ConfigureForAll(self):
		"""Configuration routine for Mentor Graphics ModelSim on all supported
		platforms.

		#. Ask if ModelSim is installed.

		  * Pass |rarr| skip this configuration. Don't change existing settings.
		  * Yes |rarr| collect installation information for ModelSim.
		  * No |rarr| clear the ModelSim configuration section.

		#. Ask for ModelSim's version.
		#. Ask for ModelSim's edition (PE, PE student, SE 32-bit, SE 64-bit).
		#. Ask for ModelSim's installation directory.
		"""
		try:
			if (not self._AskInstalled("Is Mentor ModelSim installed on your system?")):
				self.ClearSection()
			else:
				# Configure ModelSim version
				version = self._ConfigureVersion()
				if self._multiVersionSupport:
					self.PrepareVersionedSections()
					sectionName = self._host.PoCConfig[self._section]['SectionName']
					self._host.PoCConfig[sectionName]['Version'] = version

				_,edition = self._ConfigureEdition()
				if self._multiVersionSupport:
					sectionName = self._host.PoCConfig[self._section]['SectionName']
				else:
					sectionName = self._section

				configSection =   self._host.PoCConfig[sectionName]
				binaryDirectory = self._host.PoCConfig.get(sectionName, 'BinaryDirectory', raw=True)
				if (edition is MentorModelSimEditions.ModelSimPE):
					toolInstallaionName = "ModelSim PE"
					binaryDirectory =     binaryDirectory.replace("win", "win32pe")
				elif (edition is MentorModelSimEditions.ModelSimPEEducation):
					toolInstallaionName = "ModelSim PE Student Edition"
					binaryDirectory =     binaryDirectory.replace("win", "win32peedu")
				elif (edition is MentorModelSimEditions.ModelSimSE32):
					toolInstallaionName = "ModelSim SE"
					binaryDirectory =     binaryDirectory.replace("win", "win32")
				elif (edition is MentorModelSimEditions.ModelSimSE64):
					toolInstallaionName = "ModelSim SE"
					binaryDirectory =     binaryDirectory.replace("win", "win64")

				configSection['ToolInstallationName'] = toolInstallaionName
				configSection['BinaryDirectory'] =      binaryDirectory

				self._ConfigureInstallationDirectory()
				binPath = self._ConfigureBinaryDirectory()
				self.__CheckQuestaSimVersion(binPath, version)
				self._host.LogNormal("{DARK_GREEN}Mentor Graphics ModelSim is now configured.{NOCOLOR}".format(**Init.Foreground), indent=1)
		except ConfigurationException:
			self.ClearSection()
			raise

	def __GetModelSimVersion(self, binPath):
		if (self._host.Platform == "Windows"):
			vsimPath = binPath / "vsim.exe"
		else:
			vsimPath = binPath / "vsim"

		if not vsimPath.exists():
			raise ConfigurationException("Executable '{0!s}' not found.".format(vsimPath)) from FileNotFoundError(
				str(vsimPath))

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

		print(self._section, version)

		self._host.PoCConfig[self._section]['Version'] = version

	def _ConfigureEdition(self, editions=None, defaultEdition=None):
		"""Configure ModelSim for Mentor Graphics."""
		if (editions is None):
			sectionName = self._section
			if self._multiVersionSupport:
				sectionName = self._host.PoCConfig[sectionName]['SectionName']

			configSection = self._host.PoCConfig[sectionName]
			defaultEdition = MentorModelSimEditions.Parse(configSection['Edition'])
			edition = super()._ConfigureEdition(MentorModelSimEditions, defaultEdition)

			if (edition is not defaultEdition):
				configSection['Edition'] = edition.Name
				self._host.PoCConfig.Interpolation.clear_cache()
				return (True, edition)
			else:
				return (False, edition)
		else:
			return super()._ConfigureEdition(editions, defaultEdition)


class Selector(ToolSelector):
	_toolName = "ModelSim"

	def Select(self):
		editions = self._GetConfiguredEditions(ModelSimEditions)

		if (len(editions) == 0):
			self._host.LogWarning("No ModelSim installation found.", indent=1)
			self._host.PoCConfig['INSTALL.ModelSim'] = OrderedDict()
		elif (len(editions) == 1):
			self._host.LogNormal("Default ModelSim installation:", indent=1)
			self._host.LogNormal("Set to {0}".format(editions[0].Name), indent=2)
			self._host.PoCConfig['INSTALL.ModelSim']['SectionName'] = editions[0].Section
		else:
			self._host.LogNormal("Select ModelSim installation:", indent=1)

			defaultEdition = ModelSimEditions.ModelSimSE64
			if defaultEdition not in editions:
				defaultEdition = editions[0]

			selectedEdition = self._AskSelection(editions, defaultEdition)
			self._host.PoCConfig['INSTALL.ModelSim']['SectionName'] = selectedEdition.Section
