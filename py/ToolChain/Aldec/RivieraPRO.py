# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#
# Python Class:     Aldec Riviera-PRO specific classes
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
from subprocess             import check_output

from lib.Functions          import CallByRefParam, Init
from Base.Exceptions        import PlatformNotSupportedException
from Base.Logging           import LogEntry, Severity
from Base.Executable        import Executable, ShortFlagArgument, DryRunException
from Base.Executable        import ExecutableArgument, PathArgument, StringArgument
from Base.Executable        import LongFlagArgument, ShortValuedFlagArgument, ShortTupleArgument, CommandLineArgumentList
from ToolChain              import ToolMixIn, ConfigurationException, ToolConfiguration, EditionDescription, Edition, ToolSelector, OutputFilteredExecutable
from ToolChain.Aldec        import AldecException
from Simulator              import PoCSimulationResultFilter, PoCSimulationResultNotFoundException
from DataBase.Entity import SimulationResult


__api__ = [
	'RivieraPROException',
	'Configuration',
	'RivieraPRO',
	'VHDLLibraryTool',
	'VHDLCompiler',
	'VHDLSimulator',
	'VLibFilter',
	'VComFilter',
	'VSimFilter'
]
__all__ = __api__


class RivieraPROException(AldecException):
	"""An RivieraPROException is raised if Riviera-PRO catches a system exception."""


class Configuration(ToolConfiguration):
	_vendor =               "Aldec"                     #: The name of the tools vendor.
	_toolName =             "Aldec Riviera-PRO"         #: The name of the tool.
	_section  =             "INSTALL.Aldec.RivieraPRO"  #: The name of the configuration section. Pattern: ``INSTALL.Vendor.ToolName``.
	_multiVersionSupport =  True                        #: Aldec Riviera-PRO supports multiple versions installed on the same system.
	_template = {
		"Linux": {
			_section: {
				"Version":                "2016.10",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"Edition":                ("${${SectionName}:Edition}",               "Riviera-PRO"),
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Aldec:InstallationDirectory}/Riviera-PRO"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/BIN")
			}
		},
		"Windows": {
			_section: {
				"Version":                "2016.10",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"Edition":                ("${${SectionName}:Edition}",               "Riviera-PRO"),
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Aldec:InstallationDirectory}/Riviera-PRO"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/BIN")
			}
		}
	}                                                   #: The template for the configuration sections represented as nested dictionaries.

	def CheckDependency(self):
		"""Check if general Aldec support is configured in PoC."""
		return (len(self._host.PoCConfig['INSTALL.Aldec']) != 0)

	def ConfigureForAll(self):
		"""Configuration routine for Aldec Riviera-PRO on all supported platforms.

		#. Ask if Riviera-PRO is installed.

		  * Pass |rarr| skip this configuration. Don't change existing settings.
		  * Yes |rarr| collect installation information for Riviera-PRO.
		  * No |rarr| clear the Riviera-PRO configuration section.

		#. Ask for Riviera-PRO's version.
		#. Ask for Riviera-PRO's edition (normal, student).
		#. Ask for Riviera-PRO's installation directory.
		"""
		try:
			if (not self._AskInstalled("Is Aldec Riviera-PRO installed on your system?")):
				self.ClearSection()
			else:
				# Configure Riviera-PRO version
				version = self._ConfigureVersion()
				if self._multiVersionSupport:
					self.PrepareVersionedSections()
					sectionName = self._host.PoCConfig[self._section]['SectionName']
					self._host.PoCConfig[sectionName]['Version'] = version

				self._ConfigureInstallationDirectory()
				# Configure binary directory
				binPath = self._ConfigureBinaryDirectory()
				# Check version for correctness
				self.__CheckRivieraPROVersion(binPath, version)
				self._host.LogNormal("{DARK_GREEN}Aldec Riviera-PRO is now configured.{NOCOLOR}".format(**Init.Foreground), indent=1)
		except ConfigurationException:
			self.ClearSection()
			# FIXME: also remove all versioned sections; implement it in ClearSection?
			raise

	def __CheckRivieraPROVersion(self, binPath, version):
		"""Compare the given Riviera-PRO version with the tool's version string."""
		# TODO: use vsim abstraction?
		if (self._host.Platform == "Windows"):
			vsimPath = binPath / "vsim.exe"
		else:
			vsimPath = binPath / "vsim"

		if not vsimPath.exists():
			raise ConfigurationException("Executable '{0!s}' not found.".format(vsimPath)) \
				from FileNotFoundError(str(vsimPath))

		output = check_output([str(vsimPath), "-version"], universal_newlines=True)
		if str(version) not in output:
			raise ConfigurationException("Riviera-PRO version mismatch. Expected version {0}.".format(version))


class RivieraPRO(ToolMixIn):
	"""Factory for executable abstractions in Riviera-PRO."""
	def GetVHDLLibraryTool(self):
		"""Return an instance of Riviera-PRO's VHDL library management tool 'vlib'."""
		return VHDLLibraryTool(self)

	def GetVHDLCompiler(self):
		"""Return an instance of Riviera-PRO's VHDL compiler 'vcom'."""
		return VHDLCompiler(self)

	def GetSimulator(self):
		"""Return an instance of Riviera-PRO's VHDL simulator 'vsim'."""
		return VHDLSimulator(self)


class VHDLLibraryTool(OutputFilteredExecutable, ToolMixIn):
	"""Abstraction layer of Riviera-PRO's VHDL library management tool 'vlib'."""
	def __init__(self, toolchain : ToolMixIn):
		ToolMixIn.__init__(
			self, toolchain._platform, toolchain._dryrun, toolchain._binaryDirectoryPath, toolchain._version,
			toolchain._logger)

		if (self._platform == "Windows"): executablePath = self._binaryDirectoryPath / "vlib.exe"
		elif (self._platform == "Linux"): executablePath = self._binaryDirectoryPath / "vlib"
		else:                             raise PlatformNotSupportedException(self._platform)
		super().__init__(self._platform, self._dryrun, executablePath, logger=self._logger)

		self.Parameters[self.Executable] = executablePath

	class Executable(metaclass=ExecutableArgument):
		_value =  None

	class SwitchLibraryName(metaclass=StringArgument):
		_value =  None

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
			raise RivieraPROException("Failed to launch alib run.") from ex

		self._hasOutput =   False
		self._hasWarnings = False
		self._hasErrors =   False
		try:
			iterator = iter(VLibFilter(self.GetReader()))
			line = next(iterator)

			self._hasOutput = True
			self.LogNormal("  alib messages for '{0}'".format(self.Parameters[self.SwitchLibraryName]))
			self.LogNormal("  " + ("-" * (78 - self.Logger.BaseIndent*2)))

			while True:
				self._hasWarnings |=  (line.Severity is Severity.Warning)
				self._hasErrors |=    (line.Severity is Severity.Error)

				line.IndentBy(self.Logger.BaseIndent + 1)
				self.Log(line)
				line = next(iterator)

		except DryRunException:
			pass
		except StopIteration:
			pass
		finally:
			if self._hasOutput:
				self.LogNormal("  " + ("-" * (78 - self.Logger.BaseIndent*2)))


class VHDLCompiler(OutputFilteredExecutable, ToolMixIn):
	"""Abstraction layer of Riviera-PRO's VHDL compiler 'vcom'."""
	def __init__(self, toolchain : ToolMixIn):
		ToolMixIn.__init__(
			self, toolchain._platform, toolchain._dryrun, toolchain._binaryDirectoryPath, toolchain._version,
			toolchain._logger)

		if (self._platform == "Windows"): executablePath = self._binaryDirectoryPath / "vcom.exe"
		elif (self._platform == "Linux"): executablePath = self._binaryDirectoryPath / "vcom"
		else:                             raise PlatformNotSupportedException(self._platform)
		super().__init__(self._platform, self._dryrun, executablePath, logger=self._logger)

		self.Parameters[self.Executable] = executablePath

	class Executable(metaclass=ExecutableArgument):
		_value =  None

	# class FlagNoRangeCheck(metaclass=LongFlagArgument):
	# 	_name =   "norangecheck"
	# 	_value =  None

	class SwitchVHDLVersion(metaclass=ShortValuedFlagArgument):
		_pattern =  "-{1}"
		_name =      ""
		_value =    None

	class SwitchVHDLLibrary(metaclass=ShortTupleArgument):
		_name =     "work"
		_value =    None

	class ArgSourceFile(metaclass=PathArgument):
		_value =    None

	Parameters = CommandLineArgumentList(
		Executable,
		# FlagNoRangeCheck,
		SwitchVHDLVersion,
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
			raise RivieraPROException("Failed to launch acom run.") from ex

		self._hasOutput =   False
		self._hasWarnings = False
		self._hasErrors =   False
		try:
			iterator = iter(VComFilter(self.GetReader()))
			line = next(iterator)


			self._hasOutput = True
			self.LogNormal("  acom messages for '{0}'".format(self.Parameters[self.ArgSourceFile]))
			self.LogNormal("  " + ("-" * (78 - self.Logger.BaseIndent*2)))

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line.IndentBy(self.Logger.BaseIndent + 1)
				self.Log(line)
				line = next(iterator)

		except DryRunException:
			pass
		except StopIteration:
			pass
		finally:
			if self._hasOutput:
				self.LogNormal("  " + ("-" * (78 - self.Logger.BaseIndent*2)))


class VHDLSimulator(OutputFilteredExecutable, ToolMixIn):
	def __init__(self, toolchain: ToolMixIn):
		ToolMixIn.__init__(
			self, toolchain._platform, toolchain._dryrun, toolchain._binaryDirectoryPath, toolchain._version,
			toolchain._logger)

		if (self._platform == "Windows"): executablePath = self._binaryDirectoryPath / "vsim.exe"
		elif (self._platform == "Linux"): executablePath = self._binaryDirectoryPath / "vsim"
		else:                             raise PlatformNotSupportedException(self._platform)
		super().__init__(self._platform, self._dryrun, executablePath, logger=self._logger)

		self.Parameters[self.Executable] = executablePath

	class Executable(metaclass=ExecutableArgument):
		"""The executable to launch."""
		_value = None

	class SwitchBatchCommand(metaclass=ShortTupleArgument):
		"""Specify a Tcl batch script for the batch mode."""
		_name = "do"
		_value = None

	class FlagCommandLineMode(metaclass=ShortFlagArgument):
		"""Run simulation in command line mode."""
		_name = "c"
		_value = None

	class SwitchTimeResolution(metaclass=ShortTupleArgument):
		"""Set simulation time resolution."""
		_name = "t"  # -t [1|10|100]fs|ps|ns|us|ms|sec  Time resolution limit
		_value = None

	class SwitchTopLevel(metaclass=StringArgument):
		"""The top-level for simulation."""
		_value = None

	#: Specify all accepted command line arguments
	Parameters = CommandLineArgumentList(
		Executable,
		SwitchBatchCommand,
		FlagCommandLineMode,
		SwitchTimeResolution,
		SwitchTopLevel
	)

	def Simulate(self):
		"""Start a simulation."""
		parameterList = self.Parameters.ToArgumentList()
		self.LogVerbose("command: {0}".format(" ".join(parameterList)))

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise RivieraPROException("Failed to launch vsim run.") from ex

		self._hasOutput =   False
		self._hasWarnings = False
		self._hasErrors =   False
		simulationResult =  CallByRefParam(SimulationResult.Error)
		try:
			iterator = iter(PoCSimulationResultFilter(VSimFilter(self.GetReader()), simulationResult))

			line = next(iterator)
			line.IndentBy(self.Logger.BaseIndent + 1)
			self._hasOutput = True
			self.LogNormal("vsim messages for '{0}'".format(self.Parameters[self.SwitchTopLevel]), indent=1)
			self.LogNormal("-" * (78 - self.Logger.BaseIndent * 2), indent=1)
			self.Log(line)

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |=   (line.Severity is Severity.Error)

				line = next(iterator)
				line.IndentBy(self.Logger.BaseIndent + 1)
				self.Log(line)

		except DryRunException:
			simulationResult <<= SimulationResult.DryRun
		except StopIteration:
			pass
		finally:
			if self._hasOutput:
				self.LogNormal("-" * (78 - self.Logger.BaseIndent * 2), indent=1)

		return simulationResult.value


def VLibFilter(gen):
	"""A line based output stream filter for Riviera-PRO's VHDL library management tool."""
	for line in gen:
		yield LogEntry(line, Severity.Normal)

def VComFilter(gen): # mccabe:disable=MC0001
	"""A line based output stream filter for Riviera-PRO's VHDL compiler."""
	for line in gen:
		yield LogEntry(line, Severity.Normal)

def VSimFilter(gen):
	"""A line based output stream filter for Riviera-PRO's VHDL simulator."""
	for line in gen:
		yield LogEntry(line, Severity.Normal)
