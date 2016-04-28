# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:					Patrick Lehmann
#
# Python Class:			Mentor QuestaSim specific classes
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
from subprocess import check_output

if __name__ != "__main__":
	# place library initialization code here
	pass
else:
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module ToolChains.Mentor.QuestaSim")


from collections								import OrderedDict
from pathlib										import Path

from lib.Functions							import CallByRefParam
from Base.Exceptions						import PlatformNotSupportedException
from Base.Logging								import LogEntry, Severity
from Base.Configuration 				import Configuration as BaseConfiguration, ConfigurationException
from Base.Simulator							import SimulationResult, PoCSimulationResultFilter
from Base.Executable						import Executable
from Base.Executable						import ExecutableArgument, ShortFlagArgument, ShortValuedFlagArgument, ShortTupleArgument, PathArgument, StringArgument, CommandLineArgumentList
from ToolChains.Mentor.Mentor		import MentorException


class QuestaException(MentorException):
	pass

class Configuration(BaseConfiguration):
	_vendor =			"Mentor"
	_toolName =		"Mentor QuestaSim"
	_section = 		"INSTALL.Mentor.QuestaSim"
	_template = {
		"Windows": {
			_section: {
				"Version":								"10.4d",
				"InstallationDirectory":	"${INSTALL.Mentor:InstallationDirectory}/QuestaSim/${Version}",
				"BinaryDirectory":				"${InstallationDirectory}/win64"
			}
		},
		"Linux": {
			_section: {
				"Version":								"10.4d",
				"InstallationDirectory":	"${INSTALL.Mentor:InstallationDirectory}/${Version}/questasim",
				"BinaryDirectory":				"${InstallationDirectory}/bin"
			}
		}
	}

	def CheckDependency(self):
		# return True if Xilinx is configured
		return (len(self._host.PoCConfig['INSTALL.Mentor']) != 0)

	def ConfigureForAll(self):
		try:
			if (not self._AskInstalled("Is Mentor QuestaSim installed on your system?")):
				self.ClearSection()
			else:
				version = self._ConfigureVersion()
				self._ConfigureInstallationDirectory()
				binPath = self._ConfigureBinaryDirectory()
				self.__CheckQuestaSimVersion(binPath, version)
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


class QuestaSimMixIn:
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		self._platform =						platform
		self._binaryDirectoryPath =	binaryDirectoryPath
		self._version =							version
		self._logger =							logger

class QuestaSim(QuestaSimMixIn):
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		QuestaSimMixIn.__init__(self, platform, binaryDirectoryPath, version, logger)

	def GetVHDLCompiler(self):
		return QuestaVHDLCompiler(self._platform, self._binaryDirectoryPath, self._version, logger=self._logger)

	def GetSimulator(self):
		return QuestaSimulator(self._platform, self._binaryDirectoryPath, self._version, logger=self._logger)

	def GetVHDLLibraryTool(self):
		return QuestaVHDLLibraryTool(self._platform, self._binaryDirectoryPath, self._version, logger=self._logger)


class QuestaVHDLCompiler(Executable, QuestaSimMixIn):
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		QuestaSimMixIn.__init__(self, platform, binaryDirectoryPath, version, logger)

		if (self._platform == "Windows"):		executablePath = binaryDirectoryPath / "vcom.exe"
		elif (self._platform == "Linux"):		executablePath = binaryDirectoryPath / "vcom"
		else:																						raise PlatformNotSupportedException(self._platform)
		super().__init__(platform, executablePath, logger=logger)

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
		_value =	None

	class FlagTime(metaclass=ShortFlagArgument):
		_name =		"time"					# Print the compilation wall clock time
		_value =	None

	class FlagExplicit(metaclass=ShortFlagArgument):
		_name =		"explicit"
		_value =	None

	class FlagQuietMode(metaclass=ShortFlagArgument):
		_name =		"quiet"					# Do not report 'Loading...' messages"
		_value =	None

	class SwitchModelSimIniFile(metaclass=ShortTupleArgument):
		_name =		"modelsimini"
		_value =	None

	class FlagRangeCheck(metaclass=ShortFlagArgument):
		_name =		"rangecheck"
		_value =	None

	class SwitchVHDLVersion(metaclass=StringArgument):
		_pattern =	"-{0}"
		_value =		None

	class ArgLogFile(metaclass=ShortTupleArgument):
		_name =		"l"			# what's the difference to -logfile ?
		_value =	None

	class SwitchVHDLLibrary(metaclass=ShortTupleArgument):
		_name =		"work"
		_value =	None

	class ArgSourceFile(metaclass=PathArgument):
		_value =	None

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
		self._LogVerbose("command: {0}".format(" ".join(parameterList)))

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise QuestaException("Failed to launch vcom run.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		try:
			iterator = iter(QuestaVComFilter(self.GetReader()))

			line = next(iterator)
			line.IndentBy(2)
			self._hasOutput = True
			self._LogNormal("    vcom messages for '{0}'".format(self.Parameters[self.ArgSourceFile]))
			self._LogNormal("    " + ("-" * 76))
			self._Log(line)

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line = next(iterator)
				line.IndentBy(2)
				self._Log(line)

		except StopIteration as ex:
			pass
		except QuestaException:
			raise
		# except Exception as ex:
		#	raise QuestaException("Error while executing GHDL.") from ex
		finally:
			if self._hasOutput:
				self._LogNormal("    " + ("-" * 76))

class QuestaSimulator(Executable, QuestaSimMixIn):
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		QuestaSimMixIn.__init__(self, platform, binaryDirectoryPath, version, logger)

		if (self._platform == "Windows"):		executablePath = binaryDirectoryPath / "vsim.exe"
		elif (self._platform == "Linux"):		executablePath = binaryDirectoryPath / "vsim"
		else:																						raise PlatformNotSupportedException(self._platform)
		super().__init__(platform, executablePath, logger=logger)

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
		_value =	None

	class FlagQuietMode(metaclass=ShortFlagArgument):
		_name =		"quiet"					# Do not report 'Loading...' messages"
		_value =	None

	class FlagBatchMode(metaclass=ShortFlagArgument):
		_name =		"batch"
		_value =	None

	class FlagGuiMode(metaclass=ShortFlagArgument):
		_name =		"gui"
		_value =	None

	class SwitchBatchCommand(metaclass=ShortTupleArgument):
		_name =		"do"
		_value =	None

	class FlagCommandLineMode(metaclass=ShortFlagArgument):
		_name =		"c"
		_value =	None

	class SwitchModelSimIniFile(metaclass=ShortTupleArgument):
		_name =		"modelsimini"
		_value =	None

	class FlagOptimization(metaclass=ShortFlagArgument):
		_name =		"vopt"
		_value =	None

	class FlagReportAsError(metaclass=ShortTupleArgument):
		_name =		"error"
		_value =	None

	class SwitchTimeResolution(metaclass=ShortTupleArgument):
		_name =		"t"			# -t [1|10|100]fs|ps|ns|us|ms|sec  Time resolution limit
		_value =	None

	class ArgLogFile(metaclass=ShortTupleArgument):
		_name =		"l"			# what's the difference to -logfile ?
		_value =	None

	class ArgVHDLLibraryName(metaclass=ShortTupleArgument):
		_name =		"lib"
		_value =	None

	class ArgOnFinishMode(metaclass=ShortTupleArgument):
		_name =		"onfinish"
		_value =	None				# Customize the kernel shutdown behavior at the end of simulation; Valid modes: ask, stop, exit, final (Default: ask)

	class SwitchTopLevel(metaclass=StringArgument):
		_value =	None

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
		ArgVHDLLibraryName,
		SwitchTimeResolution,
		ArgOnFinishMode,
		SwitchTopLevel
	)

	def Simulate(self):
		parameterList = self.Parameters.ToArgumentList()
		self._LogVerbose("command: {0}".format(" ".join(parameterList)))

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise QuestaException("Failed to launch vsim run.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		simulationResult = CallByRefParam(SimulationResult.Error)
		try:
			iterator = iter(PoCSimulationResultFilter(QuestaVSimFilter(self.GetReader()), simulationResult))

			line = next(iterator)
			line.IndentBy(2)
			self._hasOutput = True
			self._LogNormal("    vsim messages for '{0}'".format(self.Parameters[self.SwitchTopLevel]))
			self._LogNormal("    " + ("-" * 76))
			self._Log(line)

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line = next(iterator)
				line.IndentBy(2)
				self._Log(line)

		except StopIteration as ex:
			pass
		except QuestaException:
			raise
		# except Exception as ex:
		#	raise QuestaException("Error while executing GHDL.") from ex
		finally:
			if self._hasOutput:
				self._LogNormal("    " + ("-" * 76))

		return simulationResult.value

class QuestaVHDLLibraryTool(Executable, QuestaSimMixIn):
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		QuestaSimMixIn.__init__(self, platform, binaryDirectoryPath, version, logger)

		if (self._platform == "Windows"):		executablePath = binaryDirectoryPath / "vlib.exe"
		elif (self._platform == "Linux"):		executablePath = binaryDirectoryPath / "vlib"
		else:																						raise PlatformNotSupportedException(self._platform)
		super().__init__(platform, executablePath, logger=logger)

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

	class Executable(metaclass=ExecutableArgument):			pass
	class SwitchLibraryName(metaclass=StringArgument):	pass

	Parameters = CommandLineArgumentList(
		Executable,
		SwitchLibraryName
	)

	def CreateLibrary(self):
		parameterList = self.Parameters.ToArgumentList()
		self._LogVerbose("command: {0}".format(" ".join(parameterList)))

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise QuestaException("Failed to launch vlib run.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		try:
			iterator = iter(QuestaVLibFilter(self.GetReader()))

			line = next(iterator)
			line.IndentBy(2)
			self._hasOutput = True
			self._LogNormal("    vlib messages for '{0}'".format(self.Parameters[self.SwitchLibraryName]))
			self._LogNormal("    " + ("-" * 76))
			self._Log(line)

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line = next(iterator)
				line.IndentBy(2)
				self._Log(line)

		except StopIteration as ex:
			pass
		except QuestaException:
			raise
		# except Exception as ex:
		#	raise QuestaException("Error while executing GHDL.") from ex
		finally:
			if self._hasOutput:
				self._LogNormal("    " + ("-" * 76))


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
		elif line.startswith("# do "):
			yield LogEntry(line, Severity.Verbose)
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
