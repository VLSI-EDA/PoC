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
from textwrap                     import dedent

from lib.Functions                import Init
from ToolChains                   import ConfigurationException, EditionDescription, Edition, ToolConfiguration, ToolSelector
from ToolChains.Mentor            import MentorException


__api__ = [
	'ModelSimException',
	'MentorModelSimPEEditions',
	'ModelSimEditions',
	'Configuration',
	'ModelSimPEConfiguration',
	'ModelSimSE32Configuration',
	'ModelSimSE64Configuration',
	'Selector'
]
__all__ = __api__


class ModelSimException(MentorException):
	pass


@unique
class MentorModelSimPEEditions(Edition):
	"""Enumeration of all ModelSim editions provided by Mentor Graphics itself."""
	ModelSimPE =            EditionDescription(Name="ModelSim PE",                    Section=None)
	ModelSimPEEducation =   EditionDescription(Name="ModelSim PE (Student Edition)",  Section=None)

@unique
class ModelSimEditions(Edition):
	"""Enumeration of all ModelSim editions provided by Mentor Graphics inclusive
	editions shipped by other vendors.
	"""
	ModelSimPE =                    EditionDescription(Name="ModelSim PE",                      Section="INSTALL.Mentor.ModelSimPE")
	ModelSimSE32 =                  EditionDescription(Name="ModelSim SE 32-bit",               Section="INSTALL.Mentor.ModelSimSE32")
	ModelSimSE64 =                  EditionDescription(Name="ModelSim SE 64-bit",               Section="INSTALL.Mentor.ModelSimSE64")
	ModelSimAlteraEdition =         EditionDescription(Name="ModelSim Altera Edition",          Section="INSTALL.Altera.ModelSim")
	ModelSimIntelEdition =          EditionDescription(Name="ModelSim Intel Edition",           Section="INSTALL.Intel.ModelSim")
	QuestaSim =                     EditionDescription(Name="QuestaSim",                        Section="INSTALL.Mentor.QuestaSim")


class Configuration(ToolConfiguration):
	_vendor =               "Mentor"                    #: The name of the tools vendor.
	_toolName =             "Mentor ModelSim"           #: The name of the tool.
	_multiVersionSupport =  True                        #: Mentor ModelSim supports multiple versions installed on the same system.

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
			if (not self._AskInstalled("Is {0} installed on your system?".format(self._toolName))):
				self.ClearSection()
			else:
				# Configure ModelSim version
				version = self._ConfigureVersion()
				if self._multiVersionSupport:
					self.PrepareVersionedSections()
					sectionName = self._host.PoCConfig[self._section]['SectionName']
					self._host.PoCConfig[sectionName]['Version'] = version

				self._ConfigureEdition()

				self._ConfigureInstallationDirectory()
				binPath = self._ConfigureBinaryDirectory()
				self._CheckModelSimVersion(binPath, version)
				self._host.LogNormal("{DARK_GREEN}{0} is now configured.{NOCOLOR}".format(self._toolName, **Init.Foreground), indent=1)
		except ConfigurationException:
			self.ClearSection()
			raise

	def _GetModelSimVersion(self, binPath):
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

	def _CheckModelSimVersion(self, binPath, version):
		if (self._host.Platform == "Windows"):
			vsimPath = binPath / "vsim.exe"
		else:
			vsimPath = binPath / "vsim"

		if not vsimPath.exists():
			raise ConfigurationException("Executable '{0!s}' not found.".format(vsimPath)) from FileNotFoundError(
				str(vsimPath))

		output = check_output([str(vsimPath), "-version"], universal_newlines=True)
		if str(version) not in output:
			raise ConfigurationException("QuestaSim version mismatch. Expected version {0}.".format(version))

	# def _ConfigureEdition(self):
	# 	pass

	def RunPostConfigurationTasks(self):
		if (len(self._host.PoCConfig[self._section]) == 0): return  # exit if not configured

		precompiledDirectory = self._host.PoCConfig['CONFIG.DirectoryNames']['PrecompiledFiles']
		vSimSimulatorFiles = self._host.PoCConfig['CONFIG.DirectoryNames']['QuestaSimFiles']
		vsimPath = self._host.Directories.Root / precompiledDirectory / vSimSimulatorFiles
		modelsimIniPath = vsimPath / "modelsim.ini"
		if not modelsimIniPath.exists():
			if not vsimPath.exists():
				try:
					vsimPath.mkdir(parents=True)
				except OSError as ex:
					raise ConfigurationException("Error while creating '{0!s}'.".format(vsimPath)) from ex

			with modelsimIniPath.open('w') as fileHandle:
				fileContent = dedent("""\
					[Library]
					others = $MODEL_TECH/../modelsim.ini
					""")
				fileHandle.write(fileContent)


class ModelSimPEConfiguration(Configuration):
	_toolName =             "Mentor ModelSim PE"          #: The name of the tool.
	_section  =             "INSTALL.Mentor.ModelSimPE"   #: The name of the configuration section. Pattern: ``INSTALL.Vendor.ToolName``.
	_template = {
		"Windows": {
			_section: {
				"Version":                "10.5c",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"Edition":                "ModelSim PE",
				"ToolInstallationName":   "ModelSim PE",
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Mentor:InstallationDirectory}/${ToolInstallationName}/${Version}"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/win32pe")  # 32pe / 32pe_edu
			}
		}
	}                                                     #: The template for the configuration sections represented as nested dictionaries.

	def _ConfigureEdition(self):
		"""Configure ModelSim PE for Mentor Graphics."""
		sectionName = self._section
		if self._multiVersionSupport:
			sectionName = self._host.PoCConfig[sectionName]['SectionName']

		configSection = self._host.PoCConfig[sectionName]
		defaultEdition = MentorModelSimPEEditions.Parse(configSection['Edition'])
		edition = super()._ConfigureEdition(MentorModelSimPEEditions, defaultEdition)

		if (edition is not defaultEdition):
			configSection['Edition'] = edition.Name
			self._host.PoCConfig.Interpolation.clear_cache()

		if self._multiVersionSupport:
			sectionName = self._host.PoCConfig[self._section]['SectionName']
		else:
			sectionName = self._section

		configSection =   self._host.PoCConfig[sectionName]
		binaryDirectory = self._host.PoCConfig.get(sectionName, 'BinaryDirectory', raw=True)
		if (edition is MentorModelSimPEEditions.ModelSimPE):
			toolInstallationName =  "ModelSim PE"
			binaryDirectory =       binaryDirectory.replace("win32peedu", "win32pe")
		elif (edition is MentorModelSimPEEditions.ModelSimPEEducation):
			toolInstallationName =  "ModelSim PE Student Edition"
			binaryDirectory =       binaryDirectory.replace("win32pe", "win32peedu")
		else:
			toolInstallationName =  None

		configSection['ToolInstallationName'] = toolInstallationName
		configSection['BinaryDirectory'] =      binaryDirectory


class ModelSimSE32Configuration(Configuration):
	_toolName =             "Mentor ModelSim SE 32-bit"   #: The name of the tool.
	_section  =             "INSTALL.Mentor.ModelSimSE32" #: The name of the configuration section. Pattern: ``INSTALL.Vendor.ToolName``.
	_template = {
		"Windows": {
			_section: {
				"Version":                "10.5c",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"Edition":                "ModelSim SE 32-bit",
				"ToolInstallationName":   "ModelSim SE",
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Mentor:InstallationDirectory}/${ToolInstallationName}/${Version}"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/win32")
			}
		}
	}                                                     #: The template for the configuration sections represented as nested dictionaries.

	def _ConfigureEdition(self):
		pass


class ModelSimSE64Configuration(Configuration):
	_toolName =             "Mentor ModelSim SE 64-bit"   #: The name of the tool.
	_section  =             "INSTALL.Mentor.ModelSimSE64" #: The name of the configuration section. Pattern: ``INSTALL.Vendor.ToolName``.
	_template = {
		"Windows": {
			_section: {
				"Version":                "10.5c",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"Edition":                "ModelSim SE 64-bit",
				"ToolInstallationName":   "ModelSim SE",
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Mentor:InstallationDirectory}/${ToolInstallationName}/${Version}"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/win64")
			}
		},
		"Linux": {
			_section: {
				"Version":                "10.5c",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"Edition":                "ModelSim SE 64-bit",
				"ToolInstallationName":   "ModelSim_SE",
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Mentor:InstallationDirectory}/${ToolInstallationName}/${Version}"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/linux_x86_64")
			}
		}
	}                                                     #: The template for the configuration sections represented as nested dictionaries.

	def _ConfigureEdition(self):
		pass


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
