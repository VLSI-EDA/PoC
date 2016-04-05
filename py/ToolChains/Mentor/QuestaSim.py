# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:				 	Patrick Lehmann
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
if __name__ != "__main__":
	# place library initialization code here
	pass
else:
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module ToolChains.Mentor.QuestaSim")


from collections				import OrderedDict
from pathlib						import Path

from Base.Executable		import Executable
from Base.Executable		import ExecutableArgument, ShortFlagArgument, ShortValuedFlagArgument, ShortTupleArgument, PathArgument, StringArgument, CommandLineArgumentList
from Base.Exceptions		import PlatformNotSupportedException, ToolChainException
from Base.Configuration import Configuration as BaseConfiguration
from Base.Logging				import LogEntry, Severity


class QuestaException(ToolChainException):
	pass

class Configuration(BaseConfiguration):
	__vendor =		"Mentor"
	__shortName =	"QuestaSim"
	__LongName =	"Mentor QuestaSim"
	__privateConfiguration = {
		"Windows": {
			"Mentor": {
				"InstallationDirectory":	"C:/Mentor"
			},
			"Mentor.QuestaSim": {
				"Version":								"10.4c",
				"InstallationDirectory":	"${Mentor:InstallationDirectory}/QuestaSim/${Version}",
				"BinaryDirectory":				"${InstallationDirectory}/win64"
			}
		},
		"Linux": {
			"Mentor": {
				"InstallationDirectory":	"/opt/QuestaSim"
			},
			"Mentor.QuestaSim": {
				"Version":								"10.4c",
				"InstallationDirectory":	"${Mentor:InstallationDirectory}/${Version}",
				"BinaryDirectory":				"${InstallationDirectory}/bin"
			}
		}
	}

	def IsSupportedPlatform(self, Platform):
		return (Platform in self.__privateConfiguration)

	def GetSections(self, Platform):
		pass

	def manualConfigureForWindows(self) :
		# Ask for installed Mentor Graphic tools
		isMentor = input('Is a Mentor Graphics tool installed on your system? [Y/n/p]: ')
		isMentor = isMentor if isMentor != "" else "Y"
		if (isMentor in ['p', 'P']) :
			pass
		elif (isMentor in ['n', 'N']) :
			self.pocConfig['Mentor'] = OrderedDict()
		elif (isMentor in ['y', 'Y']) :
			mentorDirectory = input('Mentor Graphics installation directory [C:\Mentor]: ')
			print()

			mentorDirectory = mentorDirectory if mentorDirectory != ""  else "C:\Altera"
			quartusIIVersion = quartusIIVersion if quartusIIVersion != ""  else "15.0"

			mentorDirectoryPath = Path(mentorDirectory)

			if not mentorDirectoryPath.exists() :    raise BaseException(
				"Mentor Graphics installation directory '%s' does not exist." % mentorDirectory)

			self.pocConfig['Mentor']['InstallationDirectory'] = mentorDirectoryPath.as_posix()

			# Ask for installed Mentor QuestaSIM
			isQuestaSim = input('Is Mentor QuestaSIM installed on your system? [Y/n/p]: ')
			isQuestaSim = isQuestaSim if isQuestaSim != "" else "Y"
			if (isQuestaSim in ['p', 'P']) :
				pass
			elif (isQuestaSim in ['n', 'N']) :
				self.pocConfig['Mentor.QuestaSIM'] = OrderedDict()
			elif (isQuestaSim in ['y', 'Y']) :
				QuestaSimDirectory = input(
					'QuestaSIM installation directory [{0}\QuestaSim64\\10.2c]: '.format(str(mentorDirectory)))
				QuestaSimVersion = input('QuestaSIM version number [10.4c]: ')
				print()

				QuestaSimDirectory = QuestaSimDirectory if QuestaSimDirectory != ""  else str(
					mentorDirectory) + "\QuestaSim64\\10.4c"
				QuestaSimVersion = QuestaSimVersion if QuestaSimVersion != ""    else "10.4c"

				QuestaSimDirectoryPath = Path(QuestaSimDirectory)
				QuestaSimExecutablePath = QuestaSimDirectoryPath / "win64" / "vsim.exe"

				if not QuestaSimDirectoryPath.exists() :    raise BaseException(
					"QuestaSIM installation directory '%s' does not exist." % QuestaSimDirectory)
				if not QuestaSimExecutablePath.exists() :  raise BaseException("QuestaSIM is not installed.")

				self.pocConfig['Mentor']['InstallationDirectory'] = MentorDirectoryPath.as_posix()

				self.pocConfig['Mentor.QuestaSIM']['Version'] = QuestaSimVersion
				self.pocConfig['Mentor.QuestaSIM']['InstallationDirectory'] = QuestaSimDirectoryPath.as_posix()
				self.pocConfig['Mentor.QuestaSIM']['BinaryDirectory'] = '${InstallationDirectory}/win64'
			else :
				raise BaseException("unknown option")
		else :
			raise BaseException("unknown option")

	def manualConfigureForLinux(self) :
		# Ask for installed Mentor QuestaSIM
		isQuestaSim = input('Is mentor QuestaSIM installed on your system? [Y/n/p]: ')
		isQuestaSim = isQuestaSim if isQuestaSim != "" else "Y"
		if (isQuestaSim in ['p', 'P']) :
			pass
		elif (isQuestaSim in ['n', 'N']) :
			self.pocConfig['Mentor.QuestaSIM'] = OrderedDict()
		elif (isQuestaSim in ['y', 'Y']) :
			QuestaSimDirectory = input('QuestaSIM installation directory [/opt/QuestaSim/10.2c]: ')
			QuestaSimVersion = input('QuestaSIM version number [10.2c]: ')
			print()

			QuestaSimDirectory = QuestaSimDirectory if QuestaSimDirectory != ""  else "/opt/QuestaSim/10.2c"
			QuestaSimVersion = QuestaSimVersion if QuestaSimVersion != ""    else "10.2c"

			QuestaSimDirectoryPath = Path(QuestaSimDirectory)
			QuestaSimExecutablePath = QuestaSimDirectoryPath / "bin" / "vsim"

			if not QuestaSimDirectoryPath.exists() :    raise BaseException(
				"QuestaSIM installation directory '%s' does not exist." % QuestaSimDirectory)
			if not QuestaSimExecutablePath.exists() :  raise BaseException("QuestaSIM is not installed.")

			self.pocConfig['Mentor.QuestaSIM']['Version'] = QuestaSimVersion
			self.pocConfig['Mentor.QuestaSIM']['InstallationDirectory'] = QuestaSimDirectoryPath.as_posix()
			self.pocConfig['Mentor.QuestaSIM']['BinaryDirectory'] = '${InstallationDirectory}/bin'
		else :
			raise BaseException("unknown option")

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

	class SwitchModelSimIniFile(metaclass=ShortValuedFlagArgument):
		_name =		"modelsimini "
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
		self._LogVerbose("    command: {0}".format(" ".join(parameterList)))

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise QuestaException("Failed to launch vcom run.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		try:
			filter = QuestaVComFilter(self.GetReader())
			iterator = iter(filter)

			line = next(iterator)
			line.Indent(2)
			self._hasOutput = True
			self._LogNormal("    vcom messages for '{0}'".format(self.Parameters[self.ArgSourceFile]))
			self._LogNormal("    " + ("-" * 76))
			self._Log(line)

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line = next(iterator)
				line.Indent(2)
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

	class SwitchModelSimIniFile(metaclass=ShortValuedFlagArgument):
		_name =		"modelsimini "
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
		self._LogVerbose("    command: {0}".format(" ".join(parameterList)))

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise QuestaException("Failed to launch vsim run.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		try:
			filter = QuestaVSimFilter(self.GetReader())
			iterator = iter(filter)

			line = next(iterator)
			line.Indent(2)
			self._hasOutput = True
			self._LogNormal("    vsim messages for '{0}'".format(self.Parameters[self.SwitchTopLevel]))
			self._LogNormal("    " + ("-" * 76))
			self._Log(line)

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line = next(iterator)
				line.Indent(2)
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
		self._LogVerbose("    command: {0}".format(" ".join(parameterList)))

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise QuestaException("Failed to launch vlib run.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		try:
			filter = QuestaVLibFilter(self.GetReader())
			iterator = iter(filter)

			line = next(iterator)
			line.Indent(2)
			self._hasOutput = True
			self._LogNormal("    vlib messages for '{0}'".format(self.Parameters[self.SwitchLibraryName]))
			self._LogNormal("    " + ("-" * 76))
			self._Log(line)

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line = next(iterator)
				line.Indent(2)
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
		elif line.startswith("** Error: "):
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
		elif line.startswith("** Error: "):
			yield LogEntry(line, Severity.Error)
		else:
			yield LogEntry(line, Severity.Normal)
