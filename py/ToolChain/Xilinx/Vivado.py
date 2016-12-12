# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#
# Python Class:     Xilinx Vivado specific classes
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

from lib.Functions              import CallByRefParam, Init
from Base.Exceptions            import PlatformNotSupportedException
from Base.Logging               import LogEntry, Severity
from Base.Project               import Project as BaseProject, ProjectFile, ConstraintFile, FileTypes
from Base.Executable            import ExecutableArgument, ShortFlagArgument, ShortValuedFlagArgument, ShortTupleArgument, StringArgument, CommandLineArgumentList
from ToolChain                  import ToolMixIn, ConfigurationException, ToolConfiguration, OutputFilteredExecutable
from ToolChain.GNU              import Bash
from ToolChain.Windows          import Cmd
from ToolChain.Xilinx           import XilinxException
from Simulator                  import SimulationResult, PoCSimulationResultFilter


__api__ = [
	'VivadoException',
	'Configuration',
	'ToolMixIn',
	'Vivado',
	'XElab',
	'XSim',
	'Synth',
	'ElaborationFilter',
	'SimulatorFilter',
	'CompilerFilter',
	'VivadoProject',
	'VivadoProjectFile',
	'XilinxDesignConstraintFile'
]
__all__ = __api__


class VivadoException(XilinxException):
	pass


class Configuration(ToolConfiguration):
	_vendor =               "Xilinx"                    #: The name of the tools vendor.
	_toolName =             "Xilinx Vivado"             #: The name of the tool.
	_section  =             "INSTALL.Xilinx.Vivado"     #: The name of the configuration section. Pattern: ``INSTALL.Vendor.ToolName``.
	_multiVersionSupport =  True                        #: Xilinx Vivado supports multiple versions installed on the same system.
	_template = {
		"Windows": {
			_section: {
				"Version":                "2016.3",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Xilinx:InstallationDirectory}/Vivado/${Version}"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/bin")
			}
		},
		"Linux": {
			_section: {
				"Version":                "2016.3",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Xilinx:InstallationDirectory}/Vivado/${Version}"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/bin")
			}
		}
	}                                                   #: The template for the configuration sections represented as nested dictionaries.

	def CheckDependency(self):
		"""Check if general Xilinx support is configured in PoC."""
		return (len(self._host.PoCConfig['INSTALL.Xilinx']) != 0)

	def ConfigureForAll(self):
		try:
			if (not self._AskInstalled("Is Xilinx Vivado installed on your system?")):
				self.ClearSection()
			else:
				# Configure Vivado version
				version = self._ConfigureVersion()
				if self._multiVersionSupport:
					self.PrepareVersionedSections()
					sectionName = self._host.PoCConfig[self._section]['SectionName']
					self._host.PoCConfig[sectionName]['Version'] = version

				self._ConfigureInstallationDirectory()
				binPath = self._ConfigureBinaryDirectory()
				self.__CheckVivadoVersion(binPath, version)
				self._host.LogNormal("{DARK_GREEN}Xilinx Vivado is now configured.{NOCOLOR}".format(**Init.Foreground), indent=1)
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


class Vivado(ToolMixIn):
	def PreparseEnvironment(self, installationDirectory):
		if (self._platform == "Linux"):
			cmd = Bash(self._platform, self._dryrun, logger=self._logger)
			settingsFile = installationDirectory / "settings64.sh"
		elif (self._platform == "Windows"):
			cmd = Cmd(self._platform, self._dryrun, logger=self._logger)
			settingsFile = installationDirectory / "settings64.bat"
		self._environment = cmd.GetEnvironment(settingsFile)

	def GetElaborator(self):
		return XElab(self)

	def GetSimulator(self):
		return XSim(self)

	def GetSynthesizer(self):
		return Synth(self)


class XElab(OutputFilteredExecutable, ToolMixIn):
	def __init__(self, toolchain : ToolMixIn):
		ToolMixIn.__init__(
			self, toolchain._platform, toolchain._dryrun, toolchain._binaryDirectoryPath, toolchain._version,
			toolchain._logger)

		if (self._platform == "Windows"):    executablePath = self._binaryDirectoryPath / "xelab.bat"
		elif (self._platform == "Linux"):    executablePath = self._binaryDirectoryPath / "xelab"
		else:                                            raise PlatformNotSupportedException(self._platform)
		super().__init__(self._platform, self._dryrun, executablePath, environment=toolchain._environment, logger=self._logger)

		self.Parameters[self.Executable] = executablePath

	class Executable(metaclass=ExecutableArgument):
		_value =  None

	class FlagRangeCheck(metaclass=ShortFlagArgument):
		_name =    "rangecheck"
		_value =  None

	class SwitchMultiThreading(metaclass=ShortTupleArgument):
		_name =    "mt"
		_value =  None

	class SwitchVerbose(metaclass=ShortTupleArgument):
		_name =    "verbose"
		_value =  None

	class SwitchDebug(metaclass=ShortTupleArgument):
		_name =    "debug"
		_value =  None

	# class SwitchVHDL2008(metaclass=ShortFlagArgument):
	# 	_name =    "vhdl2008"
	# 	_value =  None

	class SwitchOptimization(metaclass=ShortValuedFlagArgument):
		_pattern = "--{0}{1}"
		_name =    "O"
		_value =  None

	class SwitchTimeResolution(metaclass=ShortTupleArgument):
		_name =    "timeprecision_vhdl"
		_value =  None

	class SwitchProjectFile(metaclass=ShortTupleArgument):
		_name =    "prj"
		_value =  None

	class SwitchLogFile(metaclass=ShortTupleArgument):
		_name =    "log"
		_value =  None

	class SwitchSnapshot(metaclass=ShortTupleArgument):
		_name =    "s"
		_value =  None

	class ArgTopLevel(metaclass=StringArgument):
		_value =  None

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
		self.LogVerbose("command: {0}".format(" ".join(parameterList)))

		if (self._dryrun):
			self.LogDryRun("Start process: {0}".format(" ".join(parameterList)))
			return

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
			self.LogNormal("  xelab messages for '{0}'".format(self.Parameters[self.SwitchProjectFile]))
			self.LogNormal("  " + ("-" * (78 - self.Logger.BaseIndent*2)))

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line.IndentBy(self.Logger.BaseIndent + 1)
				self.Log(line)
				line = next(iterator)

		except StopIteration:
			pass
		except VivadoException:
			raise
		# except Exception as ex:
		#	raise GHDLException("Error while executing GHDL.") from ex
		finally:
			if self._hasOutput:
				self.LogNormal("  " + ("-" * (78 - self.Logger.BaseIndent*2)))


class XSim(OutputFilteredExecutable, ToolMixIn):
	def __init__(self, toolchain : ToolMixIn):
		ToolMixIn.__init__(
			self, toolchain._platform, toolchain._dryrun, toolchain._binaryDirectoryPath, toolchain._version,
			toolchain._logger)

		if (self._platform == "Windows"):    executablePath = self._binaryDirectoryPath / "xsim.bat"
		elif (self._platform == "Linux"):    executablePath = self._binaryDirectoryPath / "xsim"
		else:                                raise PlatformNotSupportedException(self._platform)
		super().__init__(self._platform, self._dryrun, executablePath, environment=toolchain._environment, logger=self._logger)

		self.Parameters[self.Executable] = executablePath

	class Executable(metaclass=ExecutableArgument):
		_value =  None

	class SwitchLogFile(metaclass=ShortTupleArgument):
		_name =    "-log"
		_value =  None

	class FlagGuiMode(metaclass=ShortFlagArgument):
		_name =    "-gui"
		_value =  None

	class SwitchTclBatchFile(metaclass=ShortTupleArgument):
		_name =    "-tclbatch"
		_value =  None

	class SwitchWaveformFile(metaclass=ShortTupleArgument):
		_name =    "-view"
		_value =  None

	class SwitchSnapshot(metaclass=StringArgument):
		_value =  None

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
		self.LogVerbose("command: {0}".format(" ".join(parameterList)))

		if (self._dryrun):
			self.LogDryRun("Start process: {0}".format(" ".join(parameterList)))
			return

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise VivadoException("Failed to launch xsim.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		simulationResult =  CallByRefParam(SimulationResult.Error)
		try:
			iterator = iter(PoCSimulationResultFilter(SimulatorFilter(self.GetReader()), simulationResult))

			line = next(iterator)
			self._hasOutput = True
			self.LogNormal("  xsim messages for '{0}'".format(self.Parameters[self.SwitchSnapshot]))
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


class Synth(OutputFilteredExecutable, ToolMixIn):
	def __init__(self, toolchain : ToolMixIn):
		ToolMixIn.__init__(
			self, toolchain._platform, toolchain._dryrun, toolchain._binaryDirectoryPath, toolchain._version,
			toolchain._logger)

		if (self._platform == "Windows"):    executablePath = self._binaryDirectoryPath / "vivado.bat"
		elif (self._platform == "Linux"):    executablePath = self._binaryDirectoryPath / "vivado"
		else:                                            raise PlatformNotSupportedException(self._platform)
		super().__init__(self._platform, self._dryrun, executablePath, environment=toolchain._environment, logger=self._logger)

		self.Parameters[self.Executable] = executablePath

	class Executable(metaclass=ExecutableArgument):
		_value =  None

	class SwitchLogFile(metaclass=ShortTupleArgument):
		_name =    "log"
		_value =  None

	class SwitchSourceFile(metaclass=ShortTupleArgument):
		_name =    "source"
		_value =  None

	class SwitchMode(metaclass=ShortTupleArgument):
		_name =    "mode"
		_value =  "batch"


	Parameters = CommandLineArgumentList(
		Executable,
		SwitchLogFile,
		SwitchSourceFile,
		SwitchMode
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
			raise VivadoException("Failed to launch vivado.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		try:
			iterator = iter(CompilerFilter(self.GetReader()))

			line = next(iterator)
			self._hasOutput = True
			self.LogNormal("  vivado messages for '{0}'".format(self.Parameters[self.SwitchSourceFile]))
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



def ElaborationFilter(gen): # mccabe:disable=MC0001
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
		elif line.startswith("Failure: "):
			yield LogEntry(line, Severity.Error)
		elif line.startswith("FATAL_ERROR: "):
			yield LogEntry(line, Severity.Error)
		else:
			yield LogEntry(line, Severity.Normal)

def CompilerFilter(gen):
	for line in gen:
		if line.startswith("ERROR: "):
			yield LogEntry(line, Severity.Error)
		elif line.startswith("WARNING: "):
			yield LogEntry(line, Severity.Warning)
		elif line.startswith("INFO: "):
			yield LogEntry(line, Severity.Info)
		elif line.startswith("Start"):
			yield LogEntry(line, Severity.Normal)
		elif line.startswith("Finished"):
			yield LogEntry(line, Severity.Normal)
		elif line.startswith("****** Vivado "):
			yield LogEntry(line, Severity.Debug)
		elif line.startswith("  **** SW Build "):
			yield LogEntry(line, Severity.Debug)
		elif line.startswith("  **** IP Build "):
			yield LogEntry(line, Severity.Debug)
		elif line.startswith("    ** Copyright "):
			continue
		elif line.startswith("# "):
			yield LogEntry(line, Severity.Debug)
		else:
			yield LogEntry(line, Severity.Verbose)

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
