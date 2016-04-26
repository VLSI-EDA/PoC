# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:					Patrick Lehmann
#
# Python Class:			Altera QuartusII specific classes
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
#											Chair for VLSI-Design, Diagnostics and Architecture
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#		http://www.apache.org/licenses/LICENSE-2.0
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
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module ToolChains.Altera.QuartusII")


from collections									import OrderedDict
from pathlib											import Path

from Base.Exceptions import PlatformNotSupportedException
from Base.Logging import Severity, LogEntry
from Base.Configuration						import Configuration as BaseConfiguration, ConfigurationException
from Base.Project									import Project as BaseProject, ProjectFile, FileTypes, SettingsFile
from Base.Executable							import Executable, ExecutableArgument, CommandLineArgumentList, ShortValuedFlagArgument, LongValuedFlagArgument, \
	StringArgument, ShortFlagArgument
from ToolChains.Altera.Altera import AlteraException


class QuartusIIException(AlteraException):
	pass

class Configuration(BaseConfiguration):


	def __init__(self, host):
		super().__init__(host)

	def manualConfigureForWindows(self) :
		# Ask for installed Altera Quartus-II
		isAlteraQuartusII = input('Is Altera Quartus-II installed on your system? [Y/n/p]: ')
		isAlteraQuartusII = isAlteraQuartusII if isAlteraQuartusII != "" else "Y"
		if (isAlteraQuartusII in ['p', 'P']) :
			pass
		elif (isAlteraQuartusII in ['n', 'N']) :
			self.pocConfig['Altera.QuartusII'] = OrderedDict()
		elif (isAlteraQuartusII in ['y', 'Y']) :
			alteraDirectory = input('Altera installation directory [C:\Altera]: ')
			quartusIIVersion = input('Altera QuartusII version number [15.0]: ')
			print()


			alteraDirectory = alteraDirectory if alteraDirectory != ""  else "C:\Altera"
			quartusIIVersion = quartusIIVersion if quartusIIVersion != ""  else "15.0"

			alteraDirectoryPath = Path(alteraDirectory)
			quartusIIDirectoryPath = alteraDirectoryPath / quartusIIVersion / "quartus"

			if not alteraDirectoryPath.exists() :    raise ConfigurationException(
				"Altera installation directory '%s' does not exist." % alteraDirectory)
			if not quartusIIDirectoryPath.exists() :  raise ConfigurationException(
				"Altera QuartusII version '%s' is not installed." % quartusIIVersion)

			self.pocConfig['Altera']['InstallationDirectory'] = alteraDirectoryPath.as_posix()
			self.pocConfig['Altera.QuartusII']['Version'] = quartusIIVersion
			self.pocConfig['Altera.QuartusII']['InstallationDirectory'] = '${Altera:InstallationDirectory}/${Version}'
			self.pocConfig['Altera.QuartusII']['BinaryDirectory'] = '${InstallationDirectory}/quartus/bin64'

			# Ask for installed Altera ModelSimAltera
			isAlteraModelSim = input('Is ModelSim - Altera Edition installed on your system? [Y/n/p]: ')
			isAlteraModelSim = isAlteraModelSim if isAlteraModelSim != "" else "Y"
			if (isAlteraModelSim in ['p', 'P']) :
				pass
			elif (isAlteraModelSim in ['n', 'N']) :
				self.pocConfig['Altera.ModelSim'] = OrderedDict()
			elif (isAlteraModelSim in ['y', 'Y']) :
				alteraModelSimVersion = input('ModelSim - Altera Edition version number [10.1e]: ')

				alteraModelSimDirectoryPath = alteraDirectoryPath / quartusIIVersion / "modelsim_ase"

				if not alteraModelSimDirectoryPath.exists() :  raise BaseException(
					"ModelSim - Altera Edition installation directory '%s' does not exist." % str(alteraModelSimDirectoryPath))

				self.pocConfig['Altera.ModelSim']['Version'] = alteraModelSimVersion
				self.pocConfig['Altera.ModelSim'][
					'InstallationDirectory'] = '${Altera:InstallationDirectory}/${Altera.QuartusII:Version}/modelsim_ase'
				self.pocConfig['Altera.ModelSim']['BinaryDirectory'] = '${InstallationDirectory}/win32aloem'
			else :
				raise ConfigurationException("unknown option")
		else :
			raise ConfigurationException("unknown option")

	def manualConfigureForLinux(self) :
		# Ask for installed Altera Quartus-II
		isAlteraQuartusII = input('Is Altera Quartus-II installed on your system? [Y/n/p]: ')
		isAlteraQuartusII = isAlteraQuartusII if isAlteraQuartusII != "" else "Y"
		if (isAlteraQuartusII in ['p', 'P']) :
			pass
		elif (isAlteraQuartusII in ['n', 'N']) :
			self.pocConfig['Altera.QuartusII'] = OrderedDict()
		elif (isAlteraQuartusII in ['y', 'Y']) :
			alteraDirectory = input('Altera installation directory [/opt/Altera]: ')
			quartusIIVersion = input('Altera QuartusII version number [15.0]: ')
			print()

			alteraDirectory = alteraDirectory if alteraDirectory != ""  else "/opt/Altera"
			quartusIIVersion = quartusIIVersion if quartusIIVersion != ""  else "15.0"

			alteraDirectoryPath = Path(alteraDirectory)
			quartusIIDirectoryPath = alteraDirectoryPath / quartusIIVersion / "quartus"

			if not alteraDirectoryPath.exists() :    raise ConfigurationException(
				"Altera installation directory '%s' does not exist." % alteraDirectory)
			if not quartusIIDirectoryPath.exists() :  raise ConfigurationException(
				"Altera QuartusII version '%s' is not installed." % quartusIIVersion)

			self.pocConfig['Altera']['InstallationDirectory'] = alteraDirectoryPath.as_posix()
			self.pocConfig['Altera.QuartusII']['Version'] = quartusIIVersion
			self.pocConfig['Altera.QuartusII']['InstallationDirectory'] = '${Altera:InstallationDirectory}/${Version}'
			self.pocConfig['Altera.QuartusII']['BinaryDirectory'] = '${InstallationDirectory}/quartus/bin'

			# Ask for installed Altera ModelSimAltera
			isAlteraModelSim = input('Is ModelSim - Altera Edition installed on your system? [Y/n/p]: ')
			isAlteraModelSim = isAlteraModelSim if isAlteraModelSim != "" else "Y"
			if (isAlteraModelSim in ['p', 'P']) :
				pass
			elif (isAlteraModelSim in ['n', 'N']) :
				self.pocConfig['Altera.ModelSim'] = OrderedDict()
			elif (isAlteraModelSim in ['y', 'Y']) :
				alteraModelSimVersion = input('ModelSim - Altera Edition version number [10.1e]: ')

				alteraModelSimDirectoryPath = alteraDirectoryPath / quartusIIVersion / "modelsim_ase"

				if not alteraModelSimDirectoryPath.exists() :  raise BaseException(
					"ModelSim - Altera Edition installation directory '%s' does not exist." % str(alteraModelSimDirectoryPath))

				self.pocConfig['Altera.ModelSim']['Version'] = alteraModelSimVersion
				self.pocConfig['Altera.ModelSim'][
					'InstallationDirectory'] = '${Altera:InstallationDirectory}/${Altera.QuartusII:Version}/modelsim_ase'
				self.pocConfig['Altera.ModelSim']['BinaryDirectory'] = '${InstallationDirectory}/bin'
			else :
				raise ConfigurationException("unknown option")
		else :
			raise ConfigurationException("unknown option")


class QuartusIIMixIn:
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		self._platform =						platform
		self._binaryDirectoryPath =	binaryDirectoryPath
		self._version =							version
		self._logger =							logger


class QuartusII(QuartusIIMixIn):
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		QuartusIIMixIn.__init__(self, platform, binaryDirectoryPath, version, logger)

	def GetMap(self):
		return Map(self._platform, self._binaryDirectoryPath, self._version, logger=self._logger)

	def GetTclShell(self):
		return TclShell(self._platform, self._binaryDirectoryPath, self._version, logger=self._logger)


class Map(Executable, QuartusIIMixIn):
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		QuartusIIMixIn.__init__(self, platform, binaryDirectoryPath, version, logger)

		if (platform == "Windows") :			executablePath = binaryDirectoryPath / "quartus_map.exe"
		elif (platform == "Linux") :			executablePath = binaryDirectoryPath / "quartus_map"
		else :														raise PlatformNotSupportedException(platform)
		Executable.__init__(self, platform, executablePath, logger=logger)

		self.Parameters[self.Executable] = executablePath

		self._hasOutput =		False
		self._hasWarnings =	False
		self._hasErrors =		False

	@property
	def HasWarnings(self):	return self._hasWarnings
	@property
	def HasErrors(self):		return self._hasErrors

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
			raise QuartusIIException("Failed to launch quartus_map.") from ex

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

		except StopIteration as ex:
			pass
		except QuartusIIException:
			raise
		# except Exception as ex:
		#	raise GHDLException("Error while executing GHDL.") from ex
		finally:
			if self._hasOutput:
				self._LogNormal("    " + ("-" * 76))

class TclShell(Executable, QuartusIIMixIn):
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		QuartusIIMixIn.__init__(self, platform, binaryDirectoryPath, version, logger)

		if (platform == "Windows") :			executablePath = binaryDirectoryPath / "quartus_sh.exe"
		elif (platform == "Linux") :			executablePath = binaryDirectoryPath / "quartus_sh"
		else :														raise PlatformNotSupportedException(platform)
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
		if line.startswith("Info: Command: quartus_map"):		break

	for line in iterator:
		if line.startswith("Info ("):
			yield LogEntry(line[5:], Severity.Verbose)
		elif line.startswith("Error ("):
			yield LogEntry(line[6:], Severity.Error)
		elif line.startswith("Warning ("):
			yield LogEntry(line[8:], Severity.Warning)
		elif line.startswith("    Info ("):
			yield LogEntry("  " + line[9:], Severity.Verbose)
		elif line.startswith("Info:"):
			yield LogEntry(line[6:], Severity.Info)
		elif line.startswith("    Info:"):
			yield LogEntry(line[10:], Severity.Debug)
		else:
			yield LogEntry(line, Severity.Normal)

class QuartusProject(BaseProject):
	def __init__(self, host, name, projectFile=None):
		super().__init__(name)

		self._host =				host
		self._projectFile =	projectFile

	def Save(self):
		pass

	def Read(self):
		tclShell = self._host._quartus.GetTclShell()
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

		self._projectFile =		settingsFile

		self._sourceFiles =							[]
		self._globalAssignments =				OrderedDict()
		self._globalAssignmentsProxy =	GlobalAssignmentProxy(self)

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
		return self._globalAssignmentsProxy

	def CopySourceFilesFromProject(self, project):
		for file in project.Files(fileType=FileTypes.VHDLSourceFile):
			self._sourceFiles.append(file)

	def Write(self):
		if (self._projectFile is None):		raise QuartusIIException("No file path for QuartusProject provided.")

		buffer = ""
		for key,value in self._globalAssignments.items():
			buffer += "set_global_assignment -name {key} {value!s}\n".format(key=key, value=value)

		buffer += "\n"
		for file in self._sourceFiles:
			if (not file.Path.exists()):
				raise QuartusIIException("Can not add '{0!s}' to Quartus settings file.".
																 format(file.Path)) from FileNotFoundError(str(file.Path))
			buffer += "set_global_assignment -name VHDL_FILE {file} -library {library}\n".\
				format(file=file.Path.as_posix(), library=file.LibraryName)

		with self._projectFile.Path.open('w') as fileHandle:
			fileHandle.write(buffer)

class GlobalAssignmentProxy:
	def __init__(self, project):
		self._project = project

	def __getitem__(self, key):
		return self._project._globalAssignments[key]

	def __setitem__(self, key, value):
		self._project._globalAssignments[key] = value

	def __delitem__(self, key):
		del self._project._globalAssignments[key]

	def __contains__(self, key):
		return (key in self._project._globalAssignments)

	def __len__(self):
		return len(self._project._globalAssignments)

	def __iter__(self):
		return self._project._globalAssignments.__iter__()

class QuartusProjectFile(ProjectFile):
	def __init__(self, file):
		super().__init__(file)

