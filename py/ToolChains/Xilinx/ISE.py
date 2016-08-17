# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#
# Python Class:      Xilinx ISE specific classes
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
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module ToolChains.Xilinx.ISE")


from subprocess            import check_output

from Base.Configuration          import Configuration as BaseConfiguration, ConfigurationException
from Base.Exceptions            import PlatformNotSupportedException
from Base.Executable            import Executable
from Base.Executable            import ExecutableArgument, ShortFlagArgument, ShortTupleArgument, StringArgument, CommandLineArgumentList
from Base.Logging                import LogEntry, Severity
from Base.Project                import Project as BaseProject, ProjectFile, ConstraintFile, FileTypes
from Base.Simulator              import SimulationResult, PoCSimulationResultFilter
from ToolChains.Xilinx.Xilinx    import XilinxException
from lib.Functions              import CallByRefParam


class ISEException(XilinxException):
	pass


class Configuration(BaseConfiguration):
	_vendor =   "Xilinx"
	_toolName = "Xilinx ISE"
	_section =  "INSTALL.Xilinx.ISE"
	_template = {
		"Windows": {
			_section: {
				"Version":                "14.7",
				"InstallationDirectory":  "${INSTALL.Xilinx:InstallationDirectory}/${Version}/ISE_DS",
				"BinaryDirectory":        "${InstallationDirectory}/ISE/bin/nt64"
			}
		},
		"Linux": {
			_section: {
				"Version":                "14.7",
				"InstallationDirectory":  "${INSTALL.Xilinx:InstallationDirectory}/${Version}/ISE_DS",
				"BinaryDirectory":        "${InstallationDirectory}/ISE/bin/lin64"
			}
		}
	}

	def CheckDependency(self):
		# return True if Xilinx is configured
		return (len(self._host.PoCConfig['INSTALL.Xilinx']) != 0)

	def ConfigureForAll(self):
		try:
			if (not self._AskInstalled("Is Xilinx ISE installed on your system?")):
				self.ClearSection()
			else:
				self._host.PoCConfig[self._section]['Version'] = self._template[self._host.Platform][self._section]['Version']
				self._ConfigureInstallationDirectory()
				binPath = self._ConfigureBinaryDirectory()
				self.__CheckISEVersion(binPath)
		except ConfigurationException:
			self.ClearSection()
			raise

	def __CheckISEVersion(self, binPath):
		# check for ISE 14.7
		if (self._host.Platform == "Windows"):
			fusePath = binPath / "fuse.exe"
		else:
			fusePath = binPath / "fuse"

		if not fusePath.exists():
			raise ConfigurationException("Executable '{0!s}' not found.".format(fusePath)) from FileNotFoundError(str(fusePath))

		output = check_output([str(fusePath), "--version"], universal_newlines=True)
		if "P.20131013" not in output:
			raise ConfigurationException("ISE version mismatch. Expected version 14.7 (P.20131013).")


class ISEMixIn:
	def __init__(self, platform, dryrun, binaryDirectoryPath, version, logger=None):
		self._platform =            platform
		self._dryrun =              dryrun
		self._binaryDirectoryPath = binaryDirectoryPath
		self._version =             version
		self.Logger =              logger


class ISE(ISEMixIn):
	def __init__(self, platform, dryrun, binaryDirectoryPath, version, logger=None):
		ISEMixIn.__init__(self, platform, dryrun, binaryDirectoryPath, version, logger)

	def GetVHDLCompiler(self):
		raise NotImplementedError("ISE.GetVHDLCompiler")
		# return ISEVHDLCompiler(self._platform, self._dryrun, self._binaryDirectoryPath, self._version, logger=self._Logger)

	def GetFuse(self):
		return Fuse(self._platform, self._dryrun, self._binaryDirectoryPath, self._version, logger=self.Logger)

	def GetXst(self):
		return Xst(self._platform, self._dryrun, self._binaryDirectoryPath, self._version, logger=self.Logger)

	def GetCoreGenerator(self):
		return CoreGenerator(self._platform, self._dryrun, self._binaryDirectoryPath, self._version, logger=self.Logger)


class Fuse(Executable, ISEMixIn):
	def __init__(self, platform, dryrun, binaryDirectoryPath, version, logger=None):
		ISEMixIn.__init__(self, platform, dryrun, binaryDirectoryPath, version, logger=logger)
		if (platform == "Windows"):    executablePath = binaryDirectoryPath / "fuse.exe"
		elif (platform == "Linux"):    executablePath = binaryDirectoryPath / "fuse"
		else:                          raise PlatformNotSupportedException(self._platform)
		super().__init__(platform, dryrun, executablePath, logger=logger)

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

	class Executable(metaclass=ExecutableArgument):            pass

	class FlagIncremental(metaclass=ShortFlagArgument):
		_name =    "incremental"

	# FlagIncremental = ShortFlagArgument(_name="incremntal")

	class FlagRangeCheck(metaclass=ShortFlagArgument):
		_name =    "rangecheck"

	class SwitchMultiThreading(metaclass=ShortTupleArgument):
		_name =    "mt"

	class SwitchTimeResolution(metaclass=ShortTupleArgument):
		_name =    "timeprecision_vhdl"

	class SwitchProjectFile(metaclass=ShortTupleArgument):
		_name =    "prj"

	class SwitchOutputFile(metaclass=ShortTupleArgument):
		_name =    "o"

	class ArgTopLevel(metaclass=StringArgument):          pass

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
		self.LogVerbose("command: {0}".format(" ".join(parameterList)))

		if (self._dryrun):
			self.LogDryRun("Start process: {0}".format(" ".join(parameterList)))
			return

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
			self.LogNormal("  fuse messages for '{0}'".format(self.Parameters[self.SwitchProjectFile]))
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

	class Executable(metaclass=ExecutableArgument):      pass

	class SwitchLogFile(metaclass=ShortTupleArgument):
		_name =    "log"

	class FlagGuiMode(metaclass=ShortFlagArgument):
		_name =    "gui"

	class SwitchTclBatchFile(metaclass=ShortTupleArgument):
		_name =    "tclbatch"

	class SwitchWaveformFile(metaclass=ShortTupleArgument):
		_name =    "view"

	Parameters = CommandLineArgumentList(
		Executable,
		SwitchLogFile,
		FlagGuiMode,
		SwitchTclBatchFile,
		SwitchWaveformFile
	)

	def Simulate(self):
		parameterList = self.Parameters.ToArgumentList()
		self.LogVerbose("command: {0}".format(" ".join(parameterList)))

		if (self._dryrun):
			self.LogDryRun("Start process: {0}".format(" ".join(parameterList)))
			return

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise ISEException("Failed to launch isim.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		simulationResult =  CallByRefParam(SimulationResult.Error)
		try:
			iterator = iter(PoCSimulationResultFilter(SimulatorFilter(self.GetReader()), simulationResult))

			line = next(iterator)
			self._hasOutput = True
			self.LogNormal("  isim messages for '{0}'".format(self.Parameters[self.Executable]))
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

		return simulationResult.value


class Xst(Executable, ISEMixIn):
	def __init__(self, platform, dryrun, binaryDirectoryPath, version, logger=None):
		ISEMixIn.__init__(self, platform, dryrun, binaryDirectoryPath, version, logger=logger)
		if (platform == "Windows"):      executablePath = binaryDirectoryPath / "xst.exe"
		elif (platform == "Linux"):      executablePath = binaryDirectoryPath / "xst"
		else:                            raise PlatformNotSupportedException(platform)
		Executable.__init__(self, platform, dryrun, executablePath, logger=logger)

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
		pass

	class SwitchIntStyle(metaclass=ShortTupleArgument):
		_name = "intstyle"

	class SwitchXstFile(metaclass=ShortTupleArgument):
		_name = "ifn"

	class SwitchReportFile(metaclass=ShortTupleArgument):
		_name = "ofn"

	Parameters = CommandLineArgumentList(
			Executable,
			SwitchIntStyle,
			SwitchXstFile,
			SwitchReportFile
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
			raise ISEException("Failed to launch xst.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		try:
			iterator = iter(XstFilter(self.GetReader()))

			line = next(iterator)
			self._hasOutput = True
			self.LogNormal("  xst messages for '{0}'".format(self.Parameters[self.SwitchXstFile]))
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


class CoreGenerator(Executable, ISEMixIn):
	def __init__(self, platform, dryrun, binaryDirectoryPath, version, logger=None):
		ISEMixIn.__init__(self, platform, dryrun, binaryDirectoryPath, version, logger=logger)
		if (platform == "Windows"):      executablePath = binaryDirectoryPath / "coregen.exe"
		elif (platform == "Linux"):      executablePath = binaryDirectoryPath / "coregen"
		else:                            raise PlatformNotSupportedException(platform)
		super().__init__(platform, dryrun, executablePath, logger=logger)

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

	class Executable(metaclass=ExecutableArgument):        pass

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
		self.LogVerbose("command: {0}".format(" ".join(parameterList)))

		if (self._dryrun):
			self.LogDryRun("Start process: {0}".format(" ".join(parameterList)))
			return

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
			self.LogNormal("  coregen messages for '{0}'".format(self.Parameters[self.SwitchProjectFile]))
			self.LogNormal("  " + ("-" * (78 - self.Logger.BaseIndent*2)))

			while True:
				self._hasWarnings |=  (line.Severity is Severity.Warning)
				self._hasErrors |=    (line.Severity is Severity.Error)

				line.IndentBy(self.Logger.BaseIndent + 1)
				self.Log(line)
				line = next(iterator)

		except StopIteration:
			pass
		finally:
			if self._hasOutput:
				self.LogNormal("  " + ("-" * (78 - self.Logger.BaseIndent*2)))


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
	flagNormal = False
	for line in gen:
		if line.startswith("ERROR:"):
			yield LogEntry(line, Severity.Error)
		elif line.startswith("WARNING:"):
			yield LogEntry(line, Severity.Warning)
		elif line.startswith("Note:"):
			yield LogEntry(line, Severity.Info)
		elif line.startswith("*         "): # progress
			yield LogEntry(line, Severity.Normal)
			flagNormal = True
		else:
			yield LogEntry(line, Severity.Normal if flagNormal else Severity.Verbose)
			flagNormal = False

def CoreGeneratorFilter(gen):
	for line in gen:
		if line.startswith("ERROR:"):
			yield LogEntry(line, Severity.Error)
		elif line.startswith("WARNING:"):
			yield LogEntry(line, Severity.Warning)
		elif line.startswith("Note:"):
			yield LogEntry(line, Severity.Info)
		else:
			yield LogEntry(line, Severity.Normal)


class ISEProject(BaseProject):
	def __init__(self, name):
		super().__init__(name)


class ISEProjectFile(ProjectFile):
	def __init__(self, file):
		super().__init__(file)


class UserConstraintFile(ConstraintFile):
	_FileType = FileTypes.UcfConstraintFile

	def __str__(self):
		return "UCF file: '{0!s}".format(self._file)

