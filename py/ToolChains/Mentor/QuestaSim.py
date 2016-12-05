# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#
# Python Class:     Mentor QuestaSim specific classes
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
from subprocess                 import check_output
from textwrap                   import dedent

from lib.Functions              import CallByRefParam, Init
from Base.Exceptions            import PlatformNotSupportedException
from Base.Logging               import LogEntry, Severity
from Base.Executable            import Executable
from Base.Executable            import ExecutableArgument, ShortFlagArgument, ShortTupleArgument, PathArgument, StringArgument, CommandLineArgumentList
from ToolChains                 import ToolMixIn, ConfigurationException, ToolConfiguration
from ToolChains.Mentor          import MentorException
from Simulator                  import PoCSimulationResultNotFoundException, SimulationResult, PoCSimulationResultFilter


__api__ = [
	'QuestaSimException',
	'Configuration',
	'QuestaSim',
	'QuestaVHDLCompiler',
	'QuestaSimulator',
	'QuestaVHDLLibraryTool',
	'QuestaVComFilter',
	'QuestaVSimFilter',
	'QuestaVLibFilter'
]
__all__ = __api__


class QuestaSimException(MentorException):
	pass


class Configuration(ToolConfiguration):
	_vendor =               "Mentor"                    #: The name of the tools vendor.
	_toolName =             "Mentor QuestaSim"          #: The name of the tool.
	_section  =             "INSTALL.Mentor.QuestaSim"  #: The name of the configuration section. Pattern: ``INSTALL.Vendor.ToolName``.
	_multiVersionSupport =  True                        #: Mentor QuestaSim supports multiple versions installed on the same system.
	_template = {
		"Windows": {
			_section: {
				"Version":                "10.5c",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Mentor:InstallationDirectory}/QuestaSim/${Version}"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/win64")
			}
		},
		"Linux": {
			_section: {
				"Version":                "10.5c",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Mentor:InstallationDirectory}/${Version}/questasim"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/bin")
			}
		}
	}                                                   #: The template for the configuration sections represented as nested dictionaries.

	def CheckDependency(self):
		"""Check if general Mentor support is configured in PoC."""
		return (len(self._host.PoCConfig['INSTALL.Mentor']) != 0)

	def ConfigureForAll(self):
		try:
			if (not self._AskInstalled("Is Mentor QuestaSim installed on your system?")):
				self.ClearSection()
			else:
				# Configure QuestaSim version
				version = self._ConfigureVersion()
				if self._multiVersionSupport:
					self.PrepareVersionedSections()
					sectionName = self._host.PoCConfig[self._section]['SectionName']
					self._host.PoCConfig[sectionName]['Version'] = version

				self._ConfigureInstallationDirectory()
				binPath = self._ConfigureBinaryDirectory()
				self.__CheckQuestaSimVersion(binPath, version)
				self._host.LogNormal("{DARK_GREEN}Mentor Graphics QuestaSim is now configured.{NOCOLOR}".format(**Init.Foreground), indent=1)
		except ConfigurationException:
			self.ClearSection()
			raise

	def __CheckQuestaSimVersion(self, binPath, version):
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

	def RunPostConfigurationTasks(self):
		if (len(self._host.PoCConfig[self._section]) == 0): return # exit if not configured

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


class QuestaSim(ToolMixIn):
	def GetVHDLCompiler(self):
		return QuestaVHDLCompiler(self)

	def GetSimulator(self):
		return QuestaSimulator(self)

	def GetVHDLLibraryTool(self):
		return QuestaVHDLLibraryTool(self)


class QuestaVHDLCompiler(Executable, ToolMixIn):
	def __init__(self, toolchain : ToolMixIn):
		ToolMixIn.__init__(
			self, toolchain._platform, toolchain._dryrun, toolchain._binaryDirectoryPath, toolchain._version,
			toolchain._logger)

		if (self._platform == "Windows"):    executablePath = self._binaryDirectoryPath / "vcom.exe"
		elif (self._platform == "Linux"):    executablePath = self._binaryDirectoryPath / "vcom"
		else:                                            raise PlatformNotSupportedException(self._platform)
		super().__init__(self._platform, self._dryrun, executablePath, logger=self._logger)

		self.Parameters[self.Executable] = executablePath

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False

	@property
	def HasWarnings(self):
		return self._hasWarnings

	@property
	def HasErrors(self):
		return self._hasErrors

	class Executable(metaclass=ExecutableArgument):
		_value =    None

	class FlagTime(metaclass=ShortFlagArgument):
		_name =     "time"					# Print the compilation wall clock time
		_value =    None

	class FlagExplicit(metaclass=ShortFlagArgument):
		_name =     "explicit"
		_value =    None

	class FlagQuietMode(metaclass=ShortFlagArgument):
		_name =     "quiet"					# Do not report 'Loading...' messages"
		_value =    None

	class SwitchModelSimIniFile(metaclass=ShortTupleArgument):
		_name =     "modelsimini"
		_value =    None

	class FlagRangeCheck(metaclass=ShortFlagArgument):
		_name =     "rangecheck"
		_value =    None

	class SwitchVHDLVersion(metaclass=StringArgument):
		_pattern =  "-{0}"
		_value =    None

	class ArgLogFile(metaclass=ShortTupleArgument):
		_name =     "l"			# what's the difference to -logfile ?
		_value =    None

	class SwitchVHDLLibrary(metaclass=ShortTupleArgument):
		_name =     "work"
		_value =    None

	class ArgSourceFile(metaclass=PathArgument):
		_value =    None

	Parameters = CommandLineArgumentList(
		Executable,
		FlagTime,
		FlagExplicit,
		FlagQuietMode,
		SwitchModelSimIniFile,
		FlagRangeCheck,
		SwitchVHDLVersion,
		ArgLogFile,
		SwitchVHDLLibrary,
		ArgSourceFile
	)

	def Compile(self):
		parameterList = self.Parameters.ToArgumentList()
		self.LogVerbose("command: {0}".format(" ".join(parameterList)))

		if (self._dryrun):
			self.LogDryRun("Start process: {0}".format(" ".join(parameterList)))
			return

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise QuestaSimException("Failed to launch vcom run.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		try:
			iterator = iter(QuestaVComFilter(self.GetReader()))

			line = next(iterator)
			line.IndentBy(self.Logger.BaseIndent + 1)
			self._hasOutput = True
			self.LogNormal("  vcom messages for '{0}'".format(self.Parameters[self.ArgSourceFile]))
			self.LogNormal("  " + ("-" * (78 - self.Logger.BaseIndent*2)))
			self.Log(line)

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line = next(iterator)
				line.IndentBy(self.Logger.BaseIndent + 1)
				self.Log(line)

		except StopIteration:
			pass
		finally:
			if self._hasOutput:
				self.LogNormal("  " + ("-" * (78 - self.Logger.BaseIndent*2)))

	def GetTclCommand(self):
		parameterList = self.Parameters.ToArgumentList()
		return "vcom " + " ".join(parameterList[1:])


class QuestaSimulator(Executable, ToolMixIn):
	def __init__(self, toolchain : ToolMixIn):
		ToolMixIn.__init__(
			self, toolchain._platform, toolchain._dryrun, toolchain._binaryDirectoryPath, toolchain._version,
			toolchain._logger)

		if (self._platform == "Windows"):    executablePath = self._binaryDirectoryPath / "vsim.exe"
		elif (self._platform == "Linux"):    executablePath = self._binaryDirectoryPath / "vsim"
		else:                                            raise PlatformNotSupportedException(self._platform)
		super().__init__(self._platform, self._dryrun, executablePath, logger=self._logger)

		self.Parameters[self.Executable] = executablePath

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False

	@property
	def HasWarnings(self):
		return self._hasWarnings

	@property
	def HasErrors(self):
		return self._hasErrors

	class Executable(metaclass=ExecutableArgument):
		_value =  None

	class FlagQuietMode(metaclass=ShortFlagArgument):
		_name =   "quiet"					# Do not report 'Loading...' messages"
		_value =  None

	class FlagBatchMode(metaclass=ShortFlagArgument):
		_name =   "batch"
		_value =  None

	class FlagGuiMode(metaclass=ShortFlagArgument):
		_name =   "gui"
		_value =  None

	class SwitchBatchCommand(metaclass=ShortTupleArgument):
		_name =   "do"
		_value =  None

	class FlagCommandLineMode(metaclass=ShortFlagArgument):
		_name =   "c"
		_value =  None

	class SwitchModelSimIniFile(metaclass=ShortTupleArgument):
		_name =   "modelsimini"
		_value =  None

	class FlagOptimization(metaclass=ShortFlagArgument):
		_name =   "vopt"
		_value =  None

	class FlagReportAsError(metaclass=ShortTupleArgument):
		_name =   "error"
		_value =  None

	class SwitchTimeResolution(metaclass=ShortTupleArgument):
		_name =   "t"			# -t [1|10|100]fs|ps|ns|us|ms|sec  Time resolution limit
		_value =  None

	class ArgLogFile(metaclass=ShortTupleArgument):
		_name =   "l"			# what's the difference to -logfile ?
		_value =  None

	class ArgKeepStdOut(metaclass=ShortFlagArgument):
		_name =   "keepstdout"

	class ArgVHDLLibraryName(metaclass=ShortTupleArgument):
		_name =   "lib"
		_value =  None

	class ArgOnFinishMode(metaclass=ShortTupleArgument):
		_name =   "onfinish"
		_value =  None				# Customize the kernel shutdown behavior at the end of simulation; Valid modes: ask, stop, exit, final (Default: ask)

	class SwitchTopLevel(metaclass=StringArgument):
		_value =  None

	Parameters = CommandLineArgumentList(
		Executable,
		FlagQuietMode,
		FlagBatchMode,
		FlagGuiMode,
		SwitchBatchCommand,
		FlagCommandLineMode,
		SwitchModelSimIniFile,
		FlagOptimization,
		FlagReportAsError,
		ArgLogFile,
		ArgKeepStdOut,
		ArgVHDLLibraryName,
		SwitchTimeResolution,
		ArgOnFinishMode,
		SwitchTopLevel
	)

	def Simulate(self):
		parameterList = self.Parameters.ToArgumentList()
		self.LogVerbose("command: {0}".format(" ".join(parameterList)))

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise QuestaSimException("Failed to launch vsim run.") from ex

		self._hasOutput =   False
		self._hasWarnings = False
		self._hasErrors =   False
		simulationResult =  CallByRefParam(SimulationResult.Error)
		try:
			iterator = iter(PoCSimulationResultFilter(QuestaVSimFilter(self.GetReader()), simulationResult))

			line = next(iterator)
			line.IndentBy(self.Logger.BaseIndent + 1)
			self._hasOutput = True
			self.LogNormal("  vsim messages for '{0}'".format(self.Parameters[self.SwitchTopLevel]))
			self.LogNormal("  " + ("-" * (78 - self.Logger.BaseIndent*2)))
			self.Log(line)

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line = next(iterator)
				line.IndentBy(self.Logger.BaseIndent + 1)
				self.Log(line)

		except PoCSimulationResultNotFoundException:
			if self.Parameters[self.FlagGuiMode]:
				simulationResult <<= SimulationResult.GUIRun
		except StopIteration:
			pass
		finally:
			if self._hasOutput:
				self.LogNormal("  " + ("-" * (78 - self.Logger.BaseIndent*2)))

		return simulationResult.value


class QuestaVHDLLibraryTool(Executable, ToolMixIn):
	def __init__(self, toolchain : ToolMixIn):
		ToolMixIn.__init__(
			self, toolchain._platform, toolchain._dryrun, toolchain._binaryDirectoryPath, toolchain._version,
			toolchain._logger)

		if (self._platform == "Windows"):    executablePath = self._binaryDirectoryPath / "vlib.exe"
		elif (self._platform == "Linux"):    executablePath = self._binaryDirectoryPath / "vlib"
		else:                                            raise PlatformNotSupportedException(self._platform)
		super().__init__(self._platform, self._dryrun, executablePath, logger=self._logger)

		self.Parameters[self.Executable] = executablePath

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False

	@property
	def HasWarnings(self):
		return self._hasWarnings

	@property
	def HasErrors(self):
		return self._hasErrors

	class Executable(metaclass=ExecutableArgument):     pass
	class SwitchLibraryName(metaclass=StringArgument):  pass

	Parameters = CommandLineArgumentList(
		Executable,
		SwitchLibraryName
	)

	def CreateLibrary(self):
		parameterList = self.Parameters.ToArgumentList()
		self.LogVerbose("command: {0}".format(" ".join(parameterList)))

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise QuestaSimException("Failed to launch vlib run.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		try:
			iterator = iter(QuestaVLibFilter(self.GetReader()))

			line = next(iterator)
			line.IndentBy(self.Logger.BaseIndent + 1)
			self._hasOutput = True
			self.LogNormal("  vlib messages for '{0}'".format(self.Parameters[self.SwitchLibraryName]))
			self.LogNormal("  " + ("-" * (78 - self.Logger.BaseIndent*2)))
			self.Log(line)

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line = next(iterator)
				line.IndentBy(self.Logger.BaseIndent + 1)
				self.Log(line)

		except StopIteration:
			pass
		finally:
			if self._hasOutput:
				self.LogNormal("  " + ("-" * (78 - self.Logger.BaseIndent*2)))


def QuestaVComFilter(gen):
	for line in gen:
		if line.startswith("** Warning: "):
			yield LogEntry(line, Severity.Warning)
		elif line.startswith("** Error"):
			yield LogEntry(line, Severity.Error)
		elif line.startswith("** Fatal: "):
			yield LogEntry(line, Severity.Error)
		else:
			yield LogEntry(line, Severity.Normal)

def QuestaVSimFilter(gen):
	PoCOutputFound = False
	for line in gen:
		if line.startswith("# Loading "):
			yield LogEntry(line, Severity.Debug)
		elif line.startswith("# //"):
			if line[6:].startswith("Questa"):
				yield LogEntry(line, Severity.Debug)
			elif line[6:].startswith("Version "):
				yield LogEntry(line, Severity.Debug)
			else:
				continue
		elif line.startswith("# ========================================"):
			PoCOutputFound = True
			yield LogEntry(line[2:], Severity.Normal)
		elif line.startswith("# ** Warning: "):
			yield LogEntry(line, Severity.Warning)
		elif line.startswith("# ** Error"):
			yield LogEntry(line, Severity.Error)
		elif line.startswith("# ** Fatal: "):
			yield LogEntry(line, Severity.Error)
		elif line.startswith("** Fatal: "):
			yield LogEntry(line, Severity.Error)
		elif line.startswith("# %%"):
			if ("ERROR" in line):
				yield LogEntry("{DARK_RED}{line}{NOCOLOR}".format(line=line[2:], **Init.Foreground), Severity.Error)
			else:
				yield LogEntry("{DARK_CYAN}{line}{NOCOLOR}".format(line=line[2:], **Init.Foreground), Severity.Normal)
		elif line.startswith("# "):
			if (not PoCOutputFound):
				yield LogEntry(line, Severity.Verbose)
			else:
				yield LogEntry(line[2:], Severity.Normal)
		else:
			yield LogEntry(line, Severity.Normal)

def QuestaVLibFilter(gen):
	for line in gen:
		if line.startswith("** Warning: "):
			yield LogEntry(line, Severity.Warning)
		elif line.startswith("** Error"):
			yield LogEntry(line, Severity.Error)
		elif line.startswith("** Fatal: "):
			yield LogEntry(line, Severity.Error)
		else:
			yield LogEntry(line, Severity.Normal)
