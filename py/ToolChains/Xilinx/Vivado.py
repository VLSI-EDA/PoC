# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:					Patrick Lehmann
#										Martin Zabel
#
# Python Class:			Xilinx Vivado specific classes
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
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module ToolChains.Xilinx.Vivado")


from lib.Functions							import CallByRefParam
from Base.Exceptions						import PlatformNotSupportedException
from Base.Logging								import LogEntry, Severity
from Base.Configuration 				import Configuration as BaseConfiguration, ConfigurationException
from Base.Project								import Project as BaseProject, ProjectFile, ConstraintFile, FileTypes
from Base.Simulator							import SimulationResult, PoCSimulationResultFilter
from Base.Executable						import Executable
from Base.Executable						import ExecutableArgument, ShortFlagArgument, ShortValuedFlagArgument, ShortTupleArgument, StringArgument, CommandLineArgumentList
from ToolChains.Xilinx.Xilinx		import XilinxException


class VivadoException(XilinxException):
	pass


class Configuration(BaseConfiguration):
	_vendor =			"Xilinx"
	_toolName =		"Xilinx Vivado"
	_section =		"INSTALL.Xilinx.Vivado"
	_template = {
		"Windows": {
			_section: {
				"Version":								"2015.4",
				"InstallationDirectory":	"${INSTALL.Xilinx:InstallationDirectory}/Vivado/${Version}",
				"BinaryDirectory":				"${InstallationDirectory}/bin"
			}
		},
		"Linux": {
			_section: {
				"Version":								"2015.4",
				"InstallationDirectory":	"${INSTALL.Xilinx:InstallationDirectory}/Vivado/${Version}",
				"BinaryDirectory":				"${InstallationDirectory}/bin"
			}
		}
	}

	def CheckDependency(self):
		# return True if Xilinx is configured
		return (len(self._host.PoCConfig['INSTALL.Xilinx']) != 0)

	def ConfigureForAll(self):
		try:
			if (not self._AskInstalled("Is Xilinx Vivado installed on your system?")):
				self.ClearSection()
			else:
				version = self._ConfigureVersion()
				self._ConfigureInstallationDirectory()
				binPath = self._ConfigureBinaryDirectory()
				self.__CheckVivadoVersion(binPath, version)
		except ConfigurationException:
			self.ClearSection()
			raise

	def __CheckVivadoVersion(self, binPath, version):
		if (self._host.Platform == "Windows"):
			vivadoPath = binPath / "vivado.bat"
		else:
			vivadoPath = binPath / "vivado"

		if not vivadoPath.exists():
			raise ConfigurationException("Executable '{0!s}' not found.".format(vivadoPath)) from FileNotFoundError(str(vivadoPath))

		output = check_output([str(vivadoPath), "-version"], universal_newlines=True)
		if str(version) not in output:
			raise ConfigurationException("Vivado version mismatch. Expected version {0}.".format(version))


class VivadoMixIn:
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		self._platform =						platform
		self._binaryDirectoryPath =	binaryDirectoryPath
		self._version =							version
		self._logger =							logger


class Vivado(VivadoMixIn):
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		VivadoMixIn.__init__(self, platform, binaryDirectoryPath, version, logger)

	def GetVHDLCompiler(self):
		return XVhComp(self._platform, self._binaryDirectoryPath, self._version, logger=self._logger)

	def GetElaborator(self):
		return XElab(self._platform, self._binaryDirectoryPath, self._version, logger=self._logger)

	def GetSimulator(self):
		return XSim(self._platform, self._binaryDirectoryPath, self._version, logger=self._logger)


class XVhComp(Executable, VivadoMixIn):
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		VivadoMixIn.__init__(self, platform, binaryDirectoryPath, version, logger)
		if (self._platform == "Windows"):		executablePath = binaryDirectoryPath / "xvhcomp.bat"
		elif (self._platform == "Linux"):		executablePath = binaryDirectoryPath / "xvhcomp"
		else:																						raise PlatformNotSupportedException(self._platform)
		super().__init__(platform, executablePath, logger=logger)

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False

	@property
	def HasWarnings(self):
		return self._hasWarnings

	@property
	def HasErrors(self):
		return self._hasErrors

	def Compile(self):
		parameterList = self.Parameters.ToArgumentList()
		self._LogVerbose("command: {0}".format(" ".join(parameterList)))

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise VivadoException("Failed to launch xvhcomp.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		try:
			iterator = iter(VHDLCompilerFilter(self.GetReader()))

			line = next(iterator)
			self._hasOutput = True
			self._LogNormal("    xvhcomp messages for '{0}'".format(self.Parameters[self.ArgSourceFile]))
			self._LogNormal("    " + ("-" * 76))

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line.IndentBy(2)
				self._Log(line)
				line = next(iterator)

		except StopIteration as ex:
			pass
		except VivadoException:
			raise
		# except Exception as ex:
		#	raise GHDLException("Error while executing GHDL.") from ex
		finally:
			if self._hasOutput:
				self._LogNormal("    " + ("-" * 76))


class XElab(Executable, VivadoMixIn):
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		VivadoMixIn.__init__(self, platform, binaryDirectoryPath, version, logger)
		if (self._platform == "Windows"):		executablePath = binaryDirectoryPath / "xelab.bat"
		elif (self._platform == "Linux"):		executablePath = binaryDirectoryPath / "xelab"
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

	class FlagRangeCheck(metaclass=ShortFlagArgument):
		_name =		"rangecheck"
		_value =	None

	class SwitchMultiThreading(metaclass=ShortTupleArgument):
		_name =		"mt"
		_value =	None

	class SwitchVerbose(metaclass=ShortTupleArgument):
		_name =		"verbose"
		_value =	None

	class SwitchDebug(metaclass=ShortTupleArgument):
		_name =		"debug"
		_value =	None

	# class SwitchVHDL2008(metaclass=ShortFlagArgument):
	# 	_name =		"vhdl2008"
	# 	_value =	None

	class SwitchOptimization(metaclass=ShortValuedFlagArgument):
		_name =		"O"
		_value =	None

	class SwitchTimeResolution(metaclass=ShortTupleArgument):
		_name =		"timeprecision_vhdl"
		_value =	None

	class SwitchProjectFile(metaclass=ShortTupleArgument):
		_name =		"prj"
		_value =	None

	class SwitchLogFile(metaclass=ShortTupleArgument):
		_name =		"log"
		_value =	None

	class SwitchSnapshot(metaclass=ShortTupleArgument):
		_name =		"s"
		_value =	None

	class ArgTopLevel(metaclass=StringArgument):
		_value =	None

	Parameters = CommandLineArgumentList(
		Executable,
		FlagRangeCheck,
		SwitchMultiThreading,
		SwitchTimeResolution,
		SwitchVerbose,
		SwitchDebug,
		# SwitchVHDL2008,
		SwitchOptimization,
		SwitchProjectFile,
		SwitchLogFile,
		SwitchSnapshot,
		ArgTopLevel
	)

	def Link(self):
		parameterList = self.Parameters.ToArgumentList()
		self._LogVerbose("command: {0}".format(" ".join(parameterList)))

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise VivadoException("Failed to launch xelab.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		try:
			iterator = iter(ElaborationFilter(self.GetReader()))

			line = next(iterator)
			self._hasOutput = True
			self._LogNormal("    xelab messages for '{0}'".format(self.Parameters[self.SwitchProjectFile]))
			self._LogNormal("    " + ("-" * 76))

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line.IndentBy(2)
				self._Log(line)
				line = next(iterator)

		except StopIteration as ex:
			pass
		except VivadoException:
			raise
		# except Exception as ex:
		#	raise GHDLException("Error while executing GHDL.") from ex
		finally:
			if self._hasOutput:
				self._LogNormal("    " + ("-" * 76))


class XSim(Executable, VivadoMixIn):
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		VivadoMixIn.__init__(self, platform, binaryDirectoryPath, version, logger)
		if (self._platform == "Windows"):		executablePath = binaryDirectoryPath / "xsim.bat"
		elif (self._platform == "Linux"):		executablePath = binaryDirectoryPath / "xsim"
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

	class SwitchLogFile(metaclass=ShortTupleArgument):
		_name =		"-log"
		_value =	None

	class FlagGuiMode(metaclass=ShortFlagArgument):
		_name =		"-gui"
		_value =	None

	class SwitchTclBatchFile(metaclass=ShortTupleArgument):
		_name =		"-tclbatch"
		_value =	None

	class SwitchWaveformFile(metaclass=ShortTupleArgument):
		_name =		"-view"
		_value =	None

	class SwitchSnapshot(metaclass=StringArgument):
		_value =	None

	Parameters = CommandLineArgumentList(
		Executable,
		SwitchLogFile,
		FlagGuiMode,
		SwitchTclBatchFile,
		SwitchWaveformFile,
		SwitchSnapshot
	)

	def Simulate(self):
		parameterList = self.Parameters.ToArgumentList()
		self._LogVerbose("command: {0}".format(" ".join(parameterList)))

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise VivadoException("Failed to launch xsim.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		simulationResult =	CallByRefParam(SimulationResult.Error)
		try:
			iterator = iter(PoCSimulationResultFilter(SimulatorFilter(self.GetReader()), simulationResult))

			line = next(iterator)
			self._hasOutput = True
			self._LogNormal("    xsim messages for '{0}'".format(self.Parameters[self.SwitchSnapshot]))
			self._LogNormal("    " + ("-" * 76))

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line.IndentBy(2)
				self._Log(line)
				line = next(iterator)

		except StopIteration as ex:
			pass
		except VivadoException:
			raise
		# except Exception as ex:
		#	raise GHDLException("Error while executing GHDL.") from ex
		finally:
			if self._hasOutput:
				self._LogNormal("    " + ("-" * 76))

		return simulationResult.value


def VHDLCompilerFilter(gen):
	for line in gen:
		yield LogEntry(line, Severity.Normal)

def ElaborationFilter(gen):
	for line in gen:
		if line.startswith("Vivado Simulator "):
			continue
		elif line.startswith("Copyright 1986-1999"):
			continue
		elif line.startswith("Running: "):
			yield LogEntry(line, Severity.Debug)
		elif line.startswith("ERROR: "):
			yield LogEntry(line, Severity.Error)
		elif line.startswith("WARNING: "):
			yield LogEntry(line, Severity.Warning)
		elif line.startswith("INFO: "):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("Multi-threading is "):
			yield LogEntry(line, Severity.Debug)
		elif line.startswith("Determining compilation order of HDL files."):
			yield LogEntry(line, Severity.Debug)
		elif line.startswith("Determining compilation order of HDL files."):
			yield LogEntry(line, Severity.Debug)
		elif line.startswith("Starting static elaboration"):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("Completed static elaboration"):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("Starting simulation data flow analysis"):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("Completed simulation data flow analysis"):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("Time Resolution for simulation is"):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("Compiling package "):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("Compiling architecture "):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("Built simulation snapshot "):
			yield LogEntry(line, Severity.Verbose)
		elif ": warning:" in line:
			yield LogEntry(line, Severity.Warning)
		else:
			yield LogEntry(line, Severity.Normal)

def SimulatorFilter(gen):
	PoCOutputFound = False
	for line in gen:
		if (line == ""):
			if (not PoCOutputFound):
				continue
			else:
				yield LogEntry(line, Severity.Normal)
		elif line.startswith("Vivado Simulator "):
			continue
		elif line.startswith("****** xsim "):
			yield LogEntry(line, Severity.Debug)
		elif line.startswith("  **** SW Build "):
			yield LogEntry(line, Severity.Debug)
		elif line.startswith("  **** IP Build "):
			yield LogEntry(line, Severity.Debug)
		elif line.startswith("    ** Copyright "):
			continue
		elif line.startswith("INFO: [Common 17-206] Exiting xsim "):
			continue
		elif line.startswith("source "):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("# ") or line.startswith("## "):
			yield LogEntry(line, Severity.Debug)
		elif line.startswith("Time resolution is "):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("========================================"):
			PoCOutputFound = True
			yield LogEntry(line, Severity.Normal)
		else:
			yield LogEntry(line, Severity.Normal)


class VivadoProject(BaseProject):
	def __init__(self, name):
		super().__init__(name)


class VivadoProjectFile(ProjectFile):
	def __init__(self, file):
		super().__init__(file)


class XilinxDesignConstraintFile(ConstraintFile):
	_FileType = FileTypes.XdcConstraintFile

	def __str__(self):
		return "XDC file: '{0!s}".format(self._file)

