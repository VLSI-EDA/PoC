# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#
# Python Class:     Altera Quartus specific classes
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
from collections                import OrderedDict
from enum                       import unique
from subprocess                 import check_output, STDOUT

from lib.Functions              import Init
from Base.Exceptions            import PlatformNotSupportedException
from Base.Logging               import Severity, LogEntry
from Base.Executable            import Executable, CommandLineArgumentList
from Base.Executable            import ExecutableArgument, ShortValuedFlagArgument, LongValuedFlagArgument, StringArgument, ShortFlagArgument
from Base.Project               import Project as BaseProject, ProjectFile, FileTypes, SettingsFile
from ToolChains                 import ToolMixIn, ConfigurationException, ToolConfiguration, EditionDescription, Edition, ToolSelector
from ToolChains.Altera          import AlteraException


__api__ = [
	'QuartusException',
	'QuartusEditions',
	'Configuration',
	'Quartus',
	'Map',
	'TclShell',
	'MapFilter',
	'QuartusSession',
	'QuartusProject',
	'QuartusSettings',
	'QuartusProjectFile'
]
__all__ = __api__


class QuartusException(AlteraException):
	pass


@unique
class QuartusEditions(Edition):
	"""Enumeration of all Quartus editions provided by Altera itself."""
	AlteraQuartus =   EditionDescription(Name="Altera Quartus", Section="INSTALL.Altera.Quartus")
	IntelQuartus =    EditionDescription(Name="Intel Quartus",  Section="INSTALL.Intel.Quartus")


class Configuration(ToolConfiguration):
	_vendor =               "Altera"                    #: The name of the tools vendor.
	_toolName =             "Altera Quartus"            #: The name of the tool.
	_section =              "INSTALL.Altera.Quartus"    #: The name of the configuration section. Pattern: ``INSTALL.Vendor.ToolName``.
	_multiVersionSupport =  True                        #: Altera Quartus supports multiple versions installed on the same system.
	_template = {
		"Windows": {
			_section: {
				"Version":                "16.0",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Altera:InstallationDirectory}/${Version}/quartus"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/bin64")
			}
		},
		"Linux": {
			_section: {
				"Version":                "16.0",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Altera:InstallationDirectory}/${Version}/quartus"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/bin")
			}
		}
	}                                                   #: The template for the configuration sections represented as nested dictionaries.

	def CheckDependency(self):
		"""Check if general Altera support is configured in PoC."""
		return (len(self._host.PoCConfig['INSTALL.Altera']) != 0)

	def ConfigureForAll(self):
		try:
			if (not self._AskInstalled("Is Altera Quartus-II or Quartus Prime installed on your system?")):
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

				self.LogNormal("{DARK_GREEN}Altera Quartus is now configured.{NOCOLOR}".format(**Init.Foreground), indent=1)
		except ConfigurationException:
			self.ClearSection()
			raise

	def __CheckQuartusVersion(self, binPath, version):
		if (self._host.Platform == "Windows"):
			quartusPath = binPath / "quartus_sh.exe"
		else:
			quartusPath = binPath / "quartus_sh"

		if not quartusPath.exists():
			raise ConfigurationException("Executable '{0!s}' not found.".format(quartusPath)) \
				from FileNotFoundError(str(quartusPath))

		output = check_output([str(quartusPath), "-v"], universal_newlines=True, stderr=STDOUT)
		if "Version {0}".format(version) not in output:
			raise ConfigurationException("Quartus version mismatch. Expected version {0}.".format(version))


class Selector(ToolSelector):
	_toolName = "Quartus"

	def Select(self):
		editions = self._GetConfiguredEditions(QuartusEditions)

		if (len(editions) == 0):
			self._host.LogWarning("No Quartus installation found.", indent=1)
			self._host.PoCConfig['INSTALL.Quartus'] = OrderedDict()
		elif (len(editions) == 1):
			self._host.LogNormal("Default Quartus installation:", indent=1)
			self._host.LogNormal("Set to {0}".format(editions[0].Name), indent=2)
			self._host.PoCConfig['INSTALL.Quartus']['SectionName'] = editions[0].Section
		else:
			self._host.LogNormal("Select Quartus installation:", indent=1)

			defaultEdition = QuartusEditions.IntelQuartus
			if defaultEdition not in editions:
				defaultEdition = editions[0]

			selectedEdition = self._AskSelection(editions, defaultEdition)
			self._host.PoCConfig['INSTALL.Quartus']['SectionName'] = selectedEdition.Section


class Quartus(ToolMixIn):
	def GetMap(self):
		return Map(self)

	def GetTclShell(self):
		return TclShell(self)


class Map(Executable, ToolMixIn):
	def __init__(self, toolchain : ToolMixIn):
		ToolMixIn.__init__(
			self, toolchain._platform, toolchain._dryrun, toolchain._binaryDirectoryPath, toolchain._version,
			toolchain._logger)

		if (self._platform == "Windows") :      executablePath = self._binaryDirectoryPath / "quartus_map.exe"
		elif (self._platform == "Linux") :      executablePath = self._binaryDirectoryPath / "quartus_map"
		else :                            raise PlatformNotSupportedException(self._platform)
		Executable.__init__(self, self._platform, self._dryrun, executablePath, logger=self._logger)

		self.Parameters[self.Executable] = executablePath

		self._hasOutput =    False
		self._hasWarnings =  False
		self._hasErrors =    False

	@property
	def HasWarnings(self):  return self._hasWarnings
	@property
	def HasErrors(self):    return self._hasErrors

	class Executable(metaclass=ExecutableArgument) :
		pass

	class ArgProjectName(metaclass=StringArgument):
		pass

	class SwitchArgumentFile(metaclass=ShortValuedFlagArgument):
		_name = "f"

	class SwitchDeviceFamily(metaclass=LongValuedFlagArgument) :
		_name = "family"

	class SwitchDevicePart(metaclass=LongValuedFlagArgument) :
		_name = "part"

	Parameters = CommandLineArgumentList(
			Executable,
			ArgProjectName,
			SwitchArgumentFile,
			SwitchDeviceFamily,
			SwitchDevicePart
	)

	def Compile(self) :
		parameterList = self.Parameters.ToArgumentList()
		self.LogVerbose("command: {0}".format(" ".join(parameterList)))

		if (self._dryrun):
			self.LogDryRun("Start process: {0}".format(" ".join(parameterList)))
			return

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise QuartusException("Failed to launch quartus_map.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		try:
			iterator = iter(MapFilter(self.GetReader()))

			line = next(iterator)
			self._hasOutput = True
			self.LogNormal("  quartus_map messages for '{0}'".format(self.Parameters[self.SwitchArgumentFile]))
			self.LogNormal("  " + ("-" * (78 - self.Logger.BaseIndent*2)))

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line.IndentBy(self.Logger.BaseIndent + 1)
				self.Log(line)
				line = next(iterator)

		except StopIteration:
			pass
		finally:
			if self._hasOutput:
				self.LogNormal("  " + ("-" * (78 - self.Logger.BaseIndent*2)))


class TclShell(Executable, ToolMixIn):
	def __init__(self, toolchain : ToolMixIn):
		ToolMixIn.__init__(
			self, toolchain._platform, toolchain._dryrun, toolchain._binaryDirectoryPath, toolchain._version,
			toolchain._logger)

		if (self._platform == "Windows") :      executablePath = self._binaryDirectoryPath / "quartus_sh.exe"
		elif (self._platform == "Linux") :      executablePath = self._binaryDirectoryPath / "quartus_sh"
		else :                            raise PlatformNotSupportedException(self._platform)
		super().__init__(self._platform, self._dryrun, executablePath, logger=self._logger)

		self.Parameters[self.Executable] = executablePath

	class Executable(metaclass=ExecutableArgument):
		pass

	class SwitchShell(metaclass=ShortFlagArgument):
		_name = "s"

	Parameters = CommandLineArgumentList(
			Executable,
			SwitchShell
	)


def MapFilter(gen):
	iterator = iter(gen)

	for line in iterator:
		if line.startswith("Error ("):
			yield LogEntry(line, Severity.Error)
		elif line.startswith("Info: Command: quartus_map"):
			break

	for line in iterator:
		if line.startswith("Info ("):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("Error ("):
			yield LogEntry(line, Severity.Error)
		elif line.startswith("Warning ("):
			yield LogEntry(line, Severity.Warning)
		elif line.startswith("    Info ("):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("        Info ("):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("Info:"):
			yield LogEntry(line, Severity.Info)
		elif line.startswith("    Info:"):
			yield LogEntry(line, Severity.Debug)
		else:
			yield LogEntry(line, Severity.Normal)


class QuartusSession:
	def __init__(self, host):
		self.TclShell = host.Toolchain.GetTclShell()
		self.TclShell.Parameters[self.TclShell.SwitchShell] = True
		self.TclShell.StartProcess()
		self.TclShell.SendBoundary()
		self.TclShell.ReadUntilBoundary()

	def exit(self):
		self.TclShell.Send("exit")
		self.TclShell.ReadUntilBoundary()


class QuartusProject(BaseProject):
	def __init__(self, host, name, projectFile=None):
		super().__init__(name)

		self._host =        host
		self._projectFile = projectFile

	def Create(self, session=None):
		if (session is None):
			tclShell = self._host.Toolchain.GetTclShell()
			tclShell.Parameters[tclShell.SwitchShell] = True
			tclShell.StartProcess()
			tclShell.SendBoundary()
			tclShell.ReadUntilBoundary()
		else:
			tclShell = session.TclShell

		tclShell.Send("project_create {0}".format(self._name))
		tclShell.SendBoundary()
		tclShell.ReadUntilBoundary()

		if (session is None):
			tclShell.Send("project_close")
			tclShell.SendBoundary()
			tclShell.ReadUntilBoundary()

			tclShell.Send("exit")
			tclShell.ReadUntilBoundary()

	def Save(self, session):
		tclShell = session.TclShell
		tclShell.Send("export_assignments")
		tclShell.SendBoundary()
		tclShell.ReadUntilBoundary()

	def Read(self):
		tclShell = self._host.Toolchain.GetSynthesizer()
		tclShell.StartProcess(["-s"])
		tclShell.SendBoundary()
		tclShell.ReadUntilBoundary()

		tclShell.Send("help")
		tclShell.SendBoundary()
		tclShell.ReadUntilBoundary()

		tclShell.Send("exit")
		tclShell.ReadUntilBoundary()

	def Open(self, session):
		tclShell = session.TclShell

		tclShell.Send("project_open {0}".format(self._name))
		tclShell.SendBoundary()
		tclShell.ReadUntilBoundary()

	def Close(self, session):
		tclShell = session.TclShell

		tclShell.Send("project_close")
		tclShell.SendBoundary()
		tclShell.ReadUntilBoundary()

		tclShell.Send("exit")
		tclShell.ReadUntilBoundary()


class QuartusSettings(SettingsFile):
	def __init__(self, name, settingsFile=None):
		super().__init__(name)

		self._projectFile =       settingsFile
		self._sourceFiles =       []
		self._globalAssignments = OrderedDict()
		self._parameters =        {}

	@property
	def File(self):
		return self._projectFile
	@File.setter
	def File(self, value):
		if (not isinstance(value, QuartusProjectFile)):
			raise ValueError("Parameter 'value' is not of type QuartusProjectFile.")
		self._projectFile = value

	@property
	def GlobalAssignments(self):
		return self._globalAssignments

	@property
	def Parameters(self):
		return self._parameters

	def CopySourceFilesFromProject(self, project):
		for file in project.Files(fileType=FileTypes.VHDLSourceFile):
			self._sourceFiles.append(file)

	def Write(self):
		if (self._projectFile is None):    raise QuartusException("No file path for QuartusProject provided.")

		buffer = ""
		for key,value in self._globalAssignments.items():
			buffer += "set_global_assignment -name {key} {value!s}\n".format(key=key, value=value)

		buffer += "\n"
		for key,value in self._parameters.items():
				buffer += "set_parameter -name {key} {value}\n".format(key=key, value=value)

		buffer += "\n"
		for file in self._sourceFiles:
			if (not file.Path.exists()):
				raise QuartusException("Cannot add '{0!s}' to Quartus settings file.".
																	format(file.Path)) from FileNotFoundError(str(file.Path))
			buffer += "set_global_assignment -name VHDL_FILE {file} -library {library}\n".\
				format(file=file.Path.as_posix(), library=file.LibraryName)

		with self._projectFile.Path.open('w') as fileHandle:
			fileHandle.write(buffer)


class QuartusProjectFile(ProjectFile):
	def __init__(self, file):
		super().__init__(file)
