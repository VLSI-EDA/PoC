# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#
# Python Class:      Altera Quartus specific classes
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
if __name__ != "__main__":
	# place library initialization code here
	pass
else:
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module ToolChains.Altera.Quartus")


from collections                import OrderedDict
from subprocess                 import check_output, STDOUT

from Base.Configuration          import Configuration as BaseConfiguration, ConfigurationException
from Base.Exceptions            import PlatformNotSupportedException
from Base.Logging                import Severity, LogEntry
from Base.Executable            import Executable, CommandLineArgumentList
from Base.Executable            import ExecutableArgument, ShortValuedFlagArgument, LongValuedFlagArgument, StringArgument, ShortFlagArgument
from Base.Project                import Project as BaseProject, ProjectFile, FileTypes, SettingsFile
from ToolChains.Altera.Altera    import AlteraException


class QuartusException(AlteraException):
	pass


class Configuration(BaseConfiguration):
	_vendor =    "Altera"
	_toolName =  "Altera Quartus"
	_section =  "INSTALL.Altera.Quartus"
	_template = {
		"Windows": {
			_section: {
				"Version":                "15.1",
				"InstallationDirectory":  "${INSTALL.Altera:InstallationDirectory}/${Version}/quartus",
				"BinaryDirectory":        "${InstallationDirectory}/bin64"
			}
		},
		"Linux": {
			_section: {
				"Version":                "15.1",
				"InstallationDirectory":  "${INSTALL.Altera:InstallationDirectory}/${Version}/quartus",
				"BinaryDirectory":        "${InstallationDirectory}/bin"
			}
		}
	}

	def CheckDependency(self):
		# return True if Altera is configured
		return (len(self._host.PoCConfig['INSTALL.Altera']) != 0)

	def ConfigureForAll(self):
		try:
			if (not self._AskInstalled("Is Altera Quartus-II or Quartus Prime installed on your system?")):
				self.ClearSection()
			else:
				version = self._ConfigureVersion()
				self._ConfigureInstallationDirectory()
				binPath = self._ConfigureBinaryDirectory()
				self.__CheckQuartusVersion(binPath, version)
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


class QuartusMixIn:
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		self._platform =            platform
		self._binaryDirectoryPath =  binaryDirectoryPath
		self._version =              version
		self._logger =              logger


class Quartus(QuartusMixIn):
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		QuartusMixIn.__init__(self, platform, binaryDirectoryPath, version, logger)

	def GetMap(self):
		return Map(self._platform, self._binaryDirectoryPath, self._version, logger=self._logger)

	def GetTclShell(self):
		return TclShell(self._platform, self._binaryDirectoryPath, self._version, logger=self._logger)


class Map(Executable, QuartusMixIn):
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		QuartusMixIn.__init__(self, platform, binaryDirectoryPath, version, logger)

		if (platform == "Windows") :      executablePath = binaryDirectoryPath / "quartus_map.exe"
		elif (platform == "Linux") :      executablePath = binaryDirectoryPath / "quartus_map"
		else :                            raise PlatformNotSupportedException(platform)
		Executable.__init__(self, platform, executablePath, logger=logger)

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
		self._LogVerbose("command: {0}".format(" ".join(parameterList)))

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
			self._LogNormal("    quartus_map messages for '{0}'".format(self.Parameters[self.SwitchArgumentFile]))
			self._LogNormal("    " + ("-" * 76))

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line.IndentBy(2)
				self._Log(line)
				line = next(iterator)

		except StopIteration:
			pass
		finally:
			if self._hasOutput:
				self._LogNormal("    " + ("-" * 76))

class TclShell(Executable, QuartusMixIn):
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		QuartusMixIn.__init__(self, platform, binaryDirectoryPath, version, logger)

		if (platform == "Windows") :      executablePath = binaryDirectoryPath / "quartus_sh.exe"
		elif (platform == "Linux") :      executablePath = binaryDirectoryPath / "quartus_sh"
		else :                            raise PlatformNotSupportedException(platform)
		Executable.__init__(self, platform, executablePath, logger=logger)

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
		elif line.startswith("Info:"):
			yield LogEntry(line, Severity.Info)
		elif line.startswith("    Info:"):
			yield LogEntry(line, Severity.Debug)
		else:
			yield LogEntry(line, Severity.Normal)

class QuartusProject(BaseProject):
	def __init__(self, host, name, projectFile=None):
		super().__init__(name)

		self._host =        host
		self._projectFile =  projectFile

	def Save(self):
		pass

	def Read(self):
		tclShell = self._host.Toolchain.GetTclShell()
		tclShell.StartProcess(["-s"])
		tclShell.SendBoundary()
		tclShell.ReadUntilBoundary()

		tclShell.Send("help")
		tclShell.SendBoundary()
		tclShell.ReadUntilBoundary()

		tclShell.Send("exit")
		tclShell.ReadUntilBoundary()

	def Open(self):
		pass

	def Close(self):
		pass


class QuartusSettingsFile(SettingsFile):
	def __init__(self, name, settingsFile=None):
		super().__init__(name)

		self._projectFile =    settingsFile

		self._sourceFiles =              []
		self._globalAssignments =        OrderedDict()

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

	def CopySourceFilesFromProject(self, project):
		for file in project.Files(fileType=FileTypes.VHDLSourceFile):
			self._sourceFiles.append(file)

	def Write(self):
		if (self._projectFile is None):    raise QuartusException("No file path for QuartusProject provided.")

		buffer = ""
		for key,value in self._globalAssignments.items():
			buffer += "set_global_assignment -name {key} {value!s}\n".format(key=key, value=value)

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

