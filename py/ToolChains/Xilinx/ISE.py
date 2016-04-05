# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:					Patrick Lehmann
#
# Python Class:			Xilinx ISE specific classes
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
from Base.Project import Project as BaseProject, ProjectFile, ConstraintFile


if __name__ != "__main__":
	# place library initialization code here
	pass
else:
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module ToolChains.Xilinx.ISE")

from collections					import OrderedDict
from pathlib							import Path
from os										import environ

from Base.Executable							import Executable
from Base.Executable							import ExecutableArgument, ShortFlagArgument, ShortTupleArgument, StringArgument, CommandLineArgumentList
from Base.Exceptions			import PlatformNotSupportedException
from Base.ToolChain import ToolChainException
from Base.Logging					import LogEntry, Severity
from Base.Configuration import Configuration as BaseConfiguration, ConfigurationException, SkipConfigurationException


class ISEException(ToolChainException):
	pass


class Configuration(BaseConfiguration):
	_vendor =		"Xilinx"
	_shortName = "ISE"
	_longName =	"Xilinx ISE"
	_privateConfiguration = {
		"Windows": {
			"Xilinx": {
				"InstallationDirectory":	"C:/Xilinx"
			},
			"Xilinx.ISE": {
				"Version":								"14.7",
				"InstallationDirectory":	"${Xilinx:InstallationDirectory}/${Version}/ISE_DS",
				"BinaryDirectory":				"${InstallationDirectory}/ISE/bin/nt64"
			}
		},
		"Linux": {
			"Xilinx": {
				"InstallationDirectory":	"/opt/Xilinx"
			},
			"Xilinx.ISE": {
				"Version":								"14.7",
				"InstallationDirectory":	"${Xilinx:InstallationDirectory}/${Version}/ISE_DS",
				"BinaryDirectory":				"${InstallationDirectory}/ISE/bin/lin64"
			}
		}
	}

	def GetSections(self, Platform):
		pass

	def ConfigureForWindows(self):
		xilinxDirectory = self.__GetXilinxPath()
		if (xilinxDirectory is None):
			xilinxDirectory = self.__AskXilinxPath()
		if (not xilinxDirectory.exists()):		raise ConfigurationException("Xilinx installation directory '{0}' does not exist.".format(xilinxDirectory))	from NotADirectoryError(xilinxDirectory)


	def __GetXilinxPath(self):
		xilinx = environ.get('XILINX')
		if (xilinx is None):
			return None
		else:
			return Path(xilinx)

	def __AskXilinxPath(self):
		# Ask for installed Xilinx ISE
		isXilinxISE = input('Is Xilinx ISE installed on your system? [Y/n/p]: ')
		isXilinxISE = isXilinxISE if isXilinxISE != "" else "Y"
		if (isXilinxISE in ['p', 'P']):
			raise SkipConfigurationException()
		elif (isXilinxISE in ['n', 'N']):
			return None
		elif (isXilinxISE in ['y', 'Y']):
			default = Path(self._privateConfiguration['Windows']['Xilinx']['InstallationDirectory'])
			xilinxDirectory = input('Xilinx installation directory [{0}]: '.format(str(default)))
			if (xilinxDirectory != ""):
				return Path(xilinxDirectory)
			else:
				return default
		else:
			raise ConfigurationException("Unsupported choice '{0}'".format(isXilinxISE))

	def ManualConfigureForWindows(self):
		# Ask for installed Xilinx ISE
		isXilinxISE = input('Is Xilinx ISE installed on your system? [Y/n/p]: ')
		isXilinxISE = isXilinxISE if isXilinxISE != "" else "Y"
		if (isXilinxISE in ['p', 'P']):
			return
		elif (isXilinxISE in ['n', 'N']):
			self.pocConfig['Xilinx.ISE'] = OrderedDict()
		elif (isXilinxISE in ['y', 'Y']):
			xilinxDirectory = input('Xilinx installation directory [C:\Xilinx]: ')
			iseVersion = input('Xilinx ISE version number [14.7]: ')
			print()

			xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "C:\Xilinx"
			iseVersion = iseVersion if iseVersion != "" else "14.7"

			xilinxDirectoryPath = Path(xilinxDirectory)
			if not xilinxDirectoryPath.exists():	raise ConfigurationException("Xilinx installation directory '{0}' does not exist.".format(xilinxDirectory))	from NotADirectoryError(xilinxDirectory)

			iseDirectoryPath = xilinxDirectoryPath / iseVersion / "ISE_DS/ISE"
			if not iseDirectoryPath.exists():			raise ConfigurationException("Xilinx ISE version '{0}' is not installed.".format(iseVersion))								from NotADirectoryError(xilinxDirectory)

			self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
			self.pocConfig['Xilinx.ISE']['Version'] = iseVersion
			self.pocConfig['Xilinx.ISE']['InstallationDirectory'] = '${Xilinx:InstallationDirectory}/${Version}/ISE_DS'
			self.pocConfig['Xilinx.ISE']['BinaryDirectory'] = '${InstallationDirectory}/ISE/bin/nt64'
		else:
			raise ConfigurationException("unknown option")

	def ManualConfigureForLinux(self):
		# Ask for installed Xilinx ISE
		isXilinxISE = input('Is Xilinx ISE installed on your system? [Y/n/p]: ')
		isXilinxISE = isXilinxISE if isXilinxISE != "" else "Y"
		if (isXilinxISE in ['p', 'P']):
			pass
		elif (isXilinxISE in ['n', 'N']):
			self.pocConfig['Xilinx.ISE'] = OrderedDict()
		elif (isXilinxISE in ['y', 'Y']):
			xilinxDirectory = input('Xilinx installation directory [/opt/Xilinx]: ')
			iseVersion = input('Xilinx ISE version number [14.7]: ')
			print()

			xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "/opt/Xilinx"
			iseVersion = iseVersion if iseVersion != "" else "14.7"

			xilinxDirectoryPath = Path(xilinxDirectory)
			iseDirectoryPath = xilinxDirectoryPath / iseVersion / "ISE_DS/ISE"

			if not xilinxDirectoryPath.exists():  raise ConfigurationException(
				"Xilinx installation directory '%s' does not exist." % xilinxDirectory)
			if not iseDirectoryPath.exists():      raise ConfigurationException(
				"Xilinx ISE version '%s' is not installed." % iseVersion)

			self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
			self.pocConfig['Xilinx.ISE']['Version'] = iseVersion
			self.pocConfig['Xilinx.ISE']['InstallationDirectory'] = '${Xilinx:InstallationDirectory}/${Version}/ISE_DS'
			self.pocConfig['Xilinx.ISE']['BinaryDirectory'] = '${InstallationDirectory}/ISE/bin/lin64'
		else:
			raise ConfigurationException("unknown option")


class ISE:
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		self._platform =						platform
		self._binaryDirectoryPath =	binaryDirectoryPath
		self._version =							version
		self.__logger =							logger

	def GetVHDLCompiler(self):
		raise NotImplementedError("ISE.GetVHDLCompiler")
		# return ISEVHDLCompiler(self._platform, self._binaryDirectoryPath, self._version, logger=self.__logger)

	def GetFuse(self):
		return Fuse(self._platform, self._binaryDirectoryPath, self._version, logger=self.__logger)

	def GetXst(self):
		return Xst(self._platform, self._binaryDirectoryPath, self._version, logger=self.__logger)

	def GetCoreGenerator(self):
		return CoreGenerator(self._platform, self._binaryDirectoryPath, self._version, logger=self.__logger)

# class ISEVHDLCompiler(Executable, ISESimulatorExecutable):
# 	def __init__(self, platform, binaryDirectoryPath, version, defaultParameters=[], logger=None):
# 		ISESimulatorExecutable.__init__(self, platform, binaryDirectoryPath, version, logger=logger)
#
# 		if (self._platform == "Windows"):		executablePath = binaryDirectoryPath / "vhcomp.exe"
# 		elif (self._platform == "Linux"):		executablePath = binaryDirectoryPath / "vhcomp"
# 		else:																						raise PlatformNotSupportedException(self._platform)
# 		super().__init__(platform, executablePath, defaultParameters, logger=logger)
#
# 	def Compile(self, vhdlFile):
# 		parameterList = self.Parameters.ToArgumentList()
#
# 		self._LogVerbose("    command: {0}".format(" ".join(parameterList)))
#
		# _indent = "    "
		# print(_indent + "vhcomp messages for '{0}.{1}'".format("??????"))  # self.VHDLLibrary, topLevel))
		# print(_indent + "-" * 80)
		# try :
		# 	self.StartProcess(parameterList)
		# 	for line in self.GetReader() :
		# 		print(_indent + line)
		# except Exception as ex :
		# 	raise ex  # SimulatorException() from ex
		# print(_indent + "-" * 80)

class Fuse(Executable, ISE):
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		if (platform == "Windows"):		executablePath = binaryDirectoryPath / "fuse.exe"
		elif (platform == "Linux"):		executablePath = binaryDirectoryPath / "fuse"
		else:																						raise PlatformNotSupportedException(self._platform)
		Executable.__init__(self, platform, executablePath, logger=logger)
		ISE.__init__(self, platform, binaryDirectoryPath, version, logger=logger)

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

	class Executable(metaclass=ExecutableArgument):						pass

	class FlagIncremental(metaclass=ShortFlagArgument):
		_name =		"incremental"

	# FlagIncremental = ShortFlagArgument(_name="incremntal")

	class FlagRangeCheck(metaclass=ShortFlagArgument):
		_name =		"rangecheck"

	class SwitchMultiThreading(metaclass=ShortTupleArgument):
		_name =		"mt"

	class SwitchTimeResolution(metaclass=ShortTupleArgument):
		_name =		"timeprecision_vhdl"

	class SwitchProjectFile(metaclass=ShortTupleArgument):
		_name =		"prj"

	class SwitchOutputFile(metaclass=ShortTupleArgument):
		_name =		"o"

	class ArgTopLevel(metaclass=StringArgument):					pass

	Parameters = CommandLineArgumentList(
		Executable,
		FlagIncremental,
		FlagRangeCheck,
		SwitchMultiThreading,
		SwitchTimeResolution,
		SwitchProjectFile,
		SwitchOutputFile,
		ArgTopLevel
	)

	def Link(self):
		parameterList = self.Parameters.ToArgumentList()
		self._LogVerbose("    command: {0}".format(" ".join(parameterList)))

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise ISEException("Failed to launch fuse.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		try:
			iterator = iter(FuseFilter(self.GetReader()))

			line = next(iterator)
			self._hasOutput = True
			self._LogNormal("    fuse messages for '{0}'".format(self.Parameters[self.SwitchProjectFile]))
			self._LogNormal("    " + ("-" * 76))

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line.Indent(2)
				self._Log(line)
				line = next(iterator)

		except StopIteration as ex:
			pass
		except ISEException:
			raise
		# except Exception as ex:
		#	raise GHDLException("Error while executing GHDL.") from ex
		finally:
			if self._hasOutput:
				self._LogNormal("    " + ("-" * 76))


class ISESimulator(Executable):
	def __init__(self, executablePath, logger=None):
		super().__init__("", executablePath, logger=logger)

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

	class SwitchLogFile(metaclass=ShortTupleArgument):
		_name =		"log"

	class FlagGuiMode(metaclass=ShortFlagArgument):
		_name =		"gui"

	class SwitchTclBatchFile(metaclass=ShortTupleArgument):
		_name =		"tclbatch"

	class SwitchWaveformFile(metaclass=ShortTupleArgument):
		_name =		"view"

	Parameters = CommandLineArgumentList(
		Executable,
		SwitchLogFile,
		FlagGuiMode,
		SwitchTclBatchFile,
		SwitchWaveformFile
	)

	def Simulate(self):
		parameterList = self.Parameters.ToArgumentList()
		self._LogVerbose("    command: {0}".format(" ".join(parameterList)))

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise ISEException("Failed to launch isim.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		try:
			iterator = iter(SimulatorFilter(self.GetReader()))

			line = next(iterator)
			self._hasOutput = True
			self._LogNormal("    isim messages for '{0}'".format(self.Parameters[self.Executable]))
			self._LogNormal("    " + ("-" * 76))

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line.Indent(2)
				self._Log(line)
				line = next(iterator)

		except StopIteration as ex:
			pass
		except ISEException:
			raise
		# except Exception as ex:
		#	raise GHDLException("Error while executing GHDL.") from ex
		finally:
			if self._hasOutput:
				self._LogNormal("    " + ("-" * 76))


class Xst(Executable) :
	def __init__(self, platform, binaryDirectoryPath, version, logger=None) :
		if (platform == "Windows") :			executablePath = binaryDirectoryPath / "xst.exe"
		elif (platform == "Linux") :			executablePath = binaryDirectoryPath / "xst"
		else :														raise PlatformNotSupportedException(platform)
		Executable.__init__(self, platform, executablePath, logger=logger)

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

	class Executable(metaclass=ExecutableArgument) :
		pass

	class SwitchIniStyle(metaclass=ShortTupleArgument):
		_name = "intstyle"

	class SwitchXstFile(metaclass=ShortFlagArgument) :
		_name = "ifn"

	class SwitchReportFile(metaclass=ShortTupleArgument) :
		_name = "ofn"

	Parameters = CommandLineArgumentList(
			Executable,
			SwitchIniStyle,
			SwitchXstFile,
			SwitchReportFile
	)

	def Compile(self) :
		parameterList = self.Parameters.ToArgumentList()
		self._LogVerbose("    command: {0}".format(" ".join(parameterList)))

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise ISEException("Failed to launch xst.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		try:
			iterator = iter(XstFilter(self.GetReader()))

			line = next(iterator)
			self._hasOutput = True
			self._LogNormal("    xst messages for '{0}'".format(self.Parameters[self.ArgSourceFile]))
			self._LogNormal("    " + ("-" * 76))

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line.Indent(2)
				self._Log(line)
				line = next(iterator)

		except StopIteration as ex:
			pass
		except ISEException:
			raise
		# except Exception as ex:
		#	raise GHDLException("Error while executing GHDL.") from ex
		finally:
			if self._hasOutput:
				self._LogNormal("    " + ("-" * 76))


class CoreGenerator(Executable):
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		if (platform == "Windows"):			executablePath = binaryDirectoryPath / "coregen.exe"
		elif (platform == "Linux"):			executablePath = binaryDirectoryPath / "coregen"
		else:														raise PlatformNotSupportedException(platform)
		Executable.__init__(self, platform, executablePath, logger=logger)

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

	class Executable(metaclass=ExecutableArgument):				pass

	class FlagRegenerate(metaclass=ShortFlagArgument):
		_name = "r"

	class SwitchProjectFile(metaclass=ShortTupleArgument):
		_name = "p"

	class SwitchBatchFile(metaclass=ShortTupleArgument):
		_name = "b"

	Parameters = CommandLineArgumentList(
		Executable,
		FlagRegenerate,
		SwitchProjectFile,
		SwitchBatchFile
	)

	def Generate(self):
		parameterList = self.Parameters.ToArgumentList()
		self._LogVerbose("    command: {0}".format(" ".join(parameterList)))

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise ISEException("Failed to launch corgen.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		try:
			iterator = iter(CoreGeneratorFilter(self.GetReader()))

			line = next(iterator)
			self._hasOutput = True
			self._LogNormal("    coregen messages for '{0}'".format(self.Parameters[self.ArgSourceFile]))
			self._LogNormal("    " + ("-" * 76))

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line.Indent(2)
				self._Log(line)
				line = next(iterator)

		except StopIteration as ex:
			pass
		except ISEException:
			raise
		# except Exception as ex:
		#	raise GHDLException("Error while executing GHDL.") from ex
		finally:
			if self._hasOutput:
				self._LogNormal("    " + ("-" * 76))


def VhCompFilter(gen):
	for line in gen:
		yield LogEntry(line, Severity.Normal)

def FuseFilter(gen):
	for line in gen:
		if line.startswith("ISim "):
			yield LogEntry(line, Severity.Debug)
		elif line.startswith("Fuse "):
			yield LogEntry(line, Severity.Debug)
		elif line.startswith("Determining compilation order of HDL files"):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("Parsing VHDL file "):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("WARNING:HDLCompiler:"):
			yield LogEntry(line, Severity.Warning)
		elif line.startswith("Starting static elaboration"):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("Completed static elaboration"):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("Compiling package "):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("Compiling architecture "):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("Time Resolution for simulation is"):
			yield LogEntry(line, Severity.Verbose)
		elif (line.startswith("Waiting for ") and line.endswith(" to finish...")):
			yield LogEntry(line, Severity.Verbose)
		elif (line.startswith("Compiled ") and line.endswith(" VHDL Units")):
			yield LogEntry(line, Severity.Verbose)
		else:
			yield LogEntry(line, Severity.Normal)

def SimulatorFilter(gen):
	for line in gen:
		if line.startswith("ISim "):
			yield LogEntry(line, Severity.Debug)
		elif line.startswith("This is a Full version of ISim."):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("Time resolution is "):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("Simulator is doing circuit initialization process."):
			yield LogEntry(line, Severity.Debug)
		elif line.startswith("Finished circuit initialization process."):
			yield LogEntry(line, Severity.Verbose)
		else:
			yield LogEntry(line, Severity.Normal)

def XstFilter(gen):
	for line in gen:
		yield LogEntry(line, Severity.Normal)

def CoreGeneratorFilter(gen):
	for line in gen:
		yield LogEntry(line, Severity.Normal)


class ISEProject(BaseProject):
	def __init__(self, name):
		super().__init__(name)


class ISEProjectFile(ProjectFile):
	def __init__(self, file):
		super().__init__(file)


class UserConstraintFile(ConstraintFile):
	def __init__(self, file):
		super().__init__(file)