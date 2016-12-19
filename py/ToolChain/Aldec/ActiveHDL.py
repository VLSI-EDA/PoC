# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#
# Python Class:     Aldec Active-HDL specific classes
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
from collections            import OrderedDict
from enum                   import unique
from subprocess             import check_output

from lib.Functions          import CallByRefParam, Init
from Base.Exceptions        import PlatformNotSupportedException
from Base.Logging           import LogEntry, Severity
from Base.Executable        import Executable, DryRunException
from Base.Executable        import ExecutableArgument, PathArgument, StringArgument
from Base.Executable        import LongFlagArgument, ShortValuedFlagArgument, ShortTupleArgument, CommandLineArgumentList
from DataBase.Entity        import SimulationResult
from ToolChain              import ToolMixIn, ConfigurationException, ToolConfiguration, EditionDescription, Edition, ToolSelector, OutputFilteredExecutable
from ToolChain.Aldec        import AldecException
from Simulator              import PoCSimulationResultFilter


__api__ = [
	'ActiveHDLException',
	'AldecActiveHDLEditions',
	'ActiveHDLEditions',
	'Configuration',
	'ActiveHDL',
	'VHDLLibraryTool',
	'VHDLCompiler',
	'VHDLStandaloneSimulator',
	'VLibFilter',
	'VComFilter',
	'VSimFilter'
]
__all__ = __api__


class ActiveHDLException(AldecException):
	"""An ActiveHDLException is raised if Active-HDL catches a system exception."""


@unique
class AldecActiveHDLEditions(Edition):
	"""Enumeration of all Active-HDL editions provided by Aldec itself."""
	StandardEdition = EditionDescription(Name="Active-HDL",                   Section="foo")
	StudentEdition =  EditionDescription(Name="Active-HDL (Student Edition)", Section="bar")


@unique
class ActiveHDLEditions(Edition):
	"""Enumeration of all Active-HDL editions provided by Aldec inclusive editions
	shipped by other vendors.
	"""
	StandardEdition = EditionDescription(Name="Aldec Active-HDL",             Section="INSTALL.Aldec.ActiveHDL")
	LatticeEdition =  EditionDescription(Name="Active-HDL Lattice Edition",   Section="INSTALL.Lattice.ActiveHDL")
	# StudentEdition =  "Active-HDL (Student Edition)"


class Configuration(ToolConfiguration):
	_vendor =               "Aldec"                     #: The name of the tools vendor.
	_toolName =             "Aldec Active-HDL"          #: The name of the tool.
	_section  =             "INSTALL.Aldec.ActiveHDL"   #: The name of the configuration section. Pattern: ``INSTALL.Vendor.ToolName``.
	_multiVersionSupport =  True                        #: Aldec Active-HDL supports multiple versions installed on the same system.
	_template = {
		"Windows": {
			_section: {
				"Version":                "10.3",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"Edition":                ("${${SectionName}:Edition}",               "Active-HDL"),
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Aldec:InstallationDirectory}/Active-HDL"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/BIN")
			}
		}
	}                                                   #: The template for the configuration sections represented as nested dictionaries.

	def CheckDependency(self):
		"""Check if general Aldec support is configured in PoC."""
		return (len(self._host.PoCConfig['INSTALL.Aldec']) != 0)

	def ConfigureForAll(self):
		"""Configuration routine for Aldec Active-HDL on all supported platforms.

		#. Ask if Active-HDL is installed.

		  * Pass |rarr| skip this configuration. Don't change existing settings.
		  * Yes |rarr| collect installation information for Active-HDL.
		  * No |rarr| clear the Active-HDL configuration section.

		#. Ask for Active-HDL's version.
		#. Ask for Active-HDL's edition (normal, student).
		#. Ask for Active-HDL's installation directory.
		"""
		try:
			if (not self._AskInstalled("Is Aldec Active-HDL installed on your system?")):
				self.ClearSection()
			else:
				# Configure Active-HDL version
				version = self._ConfigureVersion()
				if self._multiVersionSupport:
					self.PrepareVersionedSections()
					sectionName = self._host.PoCConfig[self._section]['SectionName']
					self._host.PoCConfig[sectionName]['Version'] = version

				# Configure Active-HDL edition
				changed,edition = self._ConfigureEdition()
				if changed:
					if (edition is AldecActiveHDLEditions.StudentEdition):
						if self._multiVersionSupport:
							sectionName = self._host.PoCConfig[self._section]['SectionName']
						else:
							sectionName = self._section
						self._host.PoCConfig[sectionName]['InstallationDirectory'] = self._host.PoCConfig.get(sectionName, 'InstallationDirectory', raw=True) + "-Student-Edition"
						self._host.PoCConfig.Interpolation.clear_cache()
				# Configure installation directory
				self._ConfigureInstallationDirectory()
				# Configure binary directory
				binPath = self._ConfigureBinaryDirectory()
				# Check version for correctness
				self.__CheckActiveHDLVersion(binPath, version)
				self._host.LogNormal("{DARK_GREEN}Aldec Active-HDL is now configured.{NOCOLOR}".format(**Init.Foreground), indent=1)
		except ConfigurationException:
			self.ClearSection()
			# FIXME: also remove all versioned sections; implement it in ClearSection?
			raise

	def _ConfigureEdition(self):
		"""Configure Active-HDL for Aldec."""
		sectionName =     self._section
		if self._multiVersionSupport:
			sectionName =   self._host.PoCConfig[sectionName]['SectionName']

		configSection =   self._host.PoCConfig[sectionName]
		defaultEdition =  AldecActiveHDLEditions.Parse(configSection['Edition'])
		edition =         super()._ConfigureEdition(AldecActiveHDLEditions, defaultEdition)

		if (edition is not defaultEdition):
			configSection['Edition'] = edition.Name
			self._host.PoCConfig.Interpolation.clear_cache()
			return (True, edition)
		else:
			return (False, edition)

	def __CheckActiveHDLVersion(self, binPath, version):
		"""Compare the given Active-HDL version with the tool's version string."""
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
			raise ConfigurationException("Active-HDL version mismatch. Expected version {0}.".format(version))


class Selector(ToolSelector):
	_toolName = "Active-HDL"

	def Select(self):
		editions = self._GetConfiguredEditions(ActiveHDLEditions)

		if (len(editions) == 0):
			self._host.LogWarning("No Active-HDL installation found.", indent=1)
			self._host.PoCConfig['INSTALL.ActiveHDL'] = OrderedDict()
		elif (len(editions) == 1):
			self._host.LogNormal("Default Active-HDL installation:", indent=1)
			self._host.LogNormal("Set to {0}".format(editions[0].Name), indent=2)
			self._host.PoCConfig['INSTALL.ActiveHDL']['SectionName'] = editions[0].Section
		else:
			self._host.LogNormal("Select Active-HDL installation:", indent=1)

			defaultEdition = ActiveHDLEditions.LatticeEdition
			if defaultEdition not in editions:
				defaultEdition = editions[0]

			selectedEdition = self._AskSelection(editions, defaultEdition)
			self._host.PoCConfig['INSTALL.ActiveHDL']['SectionName'] = selectedEdition.Section


class ActiveHDL(ToolMixIn):
	"""Factory for executable abstractions in Active-HDL."""
	def GetVHDLLibraryTool(self):
		"""Return an instance of Active-HDL's VHDL library management tool 'vlib'."""
		return VHDLLibraryTool(self)

	def GetVHDLCompiler(self):
		"""Return an instance of Active-HDL's VHDL compiler 'vcom'."""
		return VHDLCompiler(self)

	def GetSimulator(self):
		"""Return an instance of Active-HDL's VHDL simulator 'vsim'."""
		return VHDLStandaloneSimulator(self)


class VHDLLibraryTool(OutputFilteredExecutable, ToolMixIn):
	"""Abstraction layer of Active-HDL's VHDL library management tool 'vlib'."""

	def __init__(self, toolchain: ToolMixIn):
		ToolMixIn.__init__(
			self, toolchain._platform, toolchain._dryrun, toolchain._binaryDirectoryPath, toolchain._version,
			toolchain._logger)

		if (self._platform == "Windows"):
			executablePath = self._binaryDirectoryPath / "vlib.exe"
		else:
			raise PlatformNotSupportedException(self._platform)
		super().__init__(self._platform, self._dryrun, executablePath, logger=self._logger)

		self.Parameters[self.Executable] = executablePath

	class Executable(metaclass=ExecutableArgument):
		_value = None

	# class FlagVerbose(metaclass=FlagArgument):
	# 	_name =    "-v"
	# 	_value =  None

	class SwitchLibraryName(metaclass=StringArgument):
		_value = None

	Parameters = CommandLineArgumentList(
		Executable,
		# FlagVerbose,
		SwitchLibraryName
	)

	def CreateLibrary(self):
		parameterList = self.Parameters.ToArgumentList()
		self.LogVerbose("command: {0}".format(" ".join(parameterList)))

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise ActiveHDLException("Failed to launch alib run.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		try:
			iterator = iter(VLibFilter(self.GetReader()))
			line = next(iterator)

			self._hasOutput = True
			self.LogNormal("  alib messages for '{0}'".format(self.Parameters[self.SwitchLibraryName]))
			self.LogNormal("  " + ("-" * (78 - self.Logger.BaseIndent * 2)))

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
				self.LogNormal("  " + ("-" * (78 - self.Logger.BaseIndent * 2)))


class VHDLCompiler(OutputFilteredExecutable, ToolMixIn):
	"""Abstraction layer of Active-HDL's VHDL compiler 'vcom'."""
	def __init__(self, toolchain : ToolMixIn):
		ToolMixIn.__init__(
			self, toolchain._platform, toolchain._dryrun, toolchain._binaryDirectoryPath, toolchain._version,
			toolchain._logger)

		if (self._platform == "Windows"):    executablePath = self._binaryDirectoryPath / "vcom.exe"
		else:                                raise PlatformNotSupportedException(self._platform)
		super().__init__(self._platform, self._dryrun, executablePath, logger=self._logger)

		self.Parameters[self.Executable] = executablePath

	class Executable(metaclass=ExecutableArgument):
		_value =  None

	class FlagNoRangeCheck(metaclass=LongFlagArgument):
		_name =    "norangecheck"
		_value =  None

	class SwitchVHDLVersion(metaclass=ShortValuedFlagArgument):
		_pattern =  "-{1}"
		_name =      ""
		_value =    None

	class SwitchVHDLLibrary(metaclass=ShortTupleArgument):
		_name =    "work"
		_value =  None

	class ArgSourceFile(metaclass=PathArgument):
		_value =  None

	Parameters = CommandLineArgumentList(
		Executable,
		FlagNoRangeCheck,
		SwitchVHDLVersion,
		SwitchVHDLLibrary,
		ArgSourceFile
	)

	# -reorder                      enables automatic file ordering
	# -O[0 | 1 | 2 | 3]             set optimization level
	# -93                                conform to VHDL 1076-1993
	# -2002                              conform to VHDL 1076-2002 (default)
	# -2008                              conform to VHDL 1076-2008
	# -relax                             allow 32-bit integer literals
	# -incr                              switching compiler to fast incremental mode

	def Compile(self):
		parameterList = self.Parameters.ToArgumentList()
		self.LogVerbose("command: {0}".format(" ".join(parameterList)))

		if (self._dryrun):
			self.LogDryRun("Start process: {0}".format(" ".join(parameterList)))
			return

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise ActiveHDLException("Failed to launch acom run.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
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


class VHDLStandaloneSimulator(OutputFilteredExecutable, ToolMixIn):
	"""Abstraction layer of Active-HDL's VHDL standalone simulator 'vsimsa'."""
	def __init__(self, toolchain : ToolMixIn):
		ToolMixIn.__init__(
			self, toolchain._platform, toolchain._dryrun, toolchain._binaryDirectoryPath, toolchain._version,
			toolchain._logger)

		if (self._platform == "Windows"):    executablePath = self._binaryDirectoryPath / "vsimsa.exe"
		else:                                raise PlatformNotSupportedException(self._platform)
		super().__init__(self._platform, self._dryrun, executablePath, logger=self._logger)

		self.Parameters[self.Executable] = executablePath

	class Executable(metaclass=ExecutableArgument):
		_value =  None

	class SwitchBatchCommand(metaclass=ShortTupleArgument):
		_name =    "do"
		_value =  None

	Parameters = CommandLineArgumentList(
		Executable,
		SwitchBatchCommand
	)

	def Simulate(self):
		parameterList = self.Parameters.ToArgumentList()
		self.LogVerbose("command: {0}".format(" ".join(parameterList)))
		self.LogDebug("tcl commands: {0}".format(self.Parameters[self.SwitchBatchCommand]))

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise ActiveHDLException("Failed to launch vsimsa run.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		simulationResult = CallByRefParam(SimulationResult.Error)
		try:
			iterator = iter(PoCSimulationResultFilter(VSimFilter(self.GetReader()), simulationResult))
			line = next(iterator)

			self._hasOutput = True
			self.LogNormal("  vsimsa messages for '{0}.{1}'".format("?????", "?????"))
			self.LogNormal("  " + ("-" * (78 - self.Logger.BaseIndent*2)))

			while True:
				self._hasWarnings |=  (line.Severity is Severity.Warning)
				self._hasErrors |=    (line.Severity is Severity.Error)

				line.IndentBy(self.Logger.BaseIndent + 1)
				self.Log(line)
				line = next(iterator)

		except DryRunException:
			simulationResult <<= SimulationResult.DryRun
		except StopIteration:
			pass
		finally:
			if self._hasOutput:
				self.LogNormal("  " + ("-" * (78 - self.Logger.BaseIndent*2)))

		return simulationResult.value


def VLibFilter(gen):
	"""A line based output stream filter for Active-HDL's VHDL library management
	tool.
	"""
	for line in gen:
		if line.startswith("ALIB: Library "):
			yield LogEntry(line, Severity.Verbose)
		else:
			yield LogEntry(line, Severity.Normal)

def VComFilter(gen): # mccabe:disable=MC0001
	"""A line based output stream filter for Active-HDL's VHDL compiler."""
	for line in gen:
		if line.startswith("Aldec, Inc. VHDL Compiler"):
			yield LogEntry(line, Severity.Debug)
		elif line.startswith("DAGGEN WARNING DAGGEN_0523"):
			yield LogEntry(line, Severity.Debug)
		elif line.startswith("ACOMP Initializing"):
			yield LogEntry(line, Severity.Debug)
		elif line.startswith("VLM Initialized with path"):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("VLM ERROR "):
			yield LogEntry(line, Severity.Error)
		elif line.startswith("COMP96 File: "):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("COMP96 Compile Package "):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("COMP96 Compile Entity "):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("COMP96 Compile Architecture "):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("COMP96 Compile success "):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("COMP96 Compile failure "):
			yield LogEntry(line, Severity.Error)
		elif line.startswith("COMP96 WARNING "):
			yield LogEntry(line, Severity.Warning)
		elif line.startswith("ELAB1 WARNING ELAB1_0026:"):
			yield LogEntry(line, Severity.Warning)
		elif line.startswith("COMP96 ERROR "):
			yield LogEntry(line, Severity.Error)
		else:
			yield LogEntry(line, Severity.Normal)

def VSimFilter(gen):
	"""A line based output stream filter for Active-HDL's VHDL simulator."""
	PoCOutputFound = False
	for line in gen:
		if line.startswith("asim"):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("VSIM: "):
			yield LogEntry(line, Severity.Verbose)
		elif (line.startswith("ELBREAD: Warning: ") and line.endswith("not bound.")):
			yield LogEntry(line, Severity.Error)
		elif line.startswith("ELBREAD: "):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("ELAB2: "):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("SLP: "):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("Allocation: "):
			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("KERNEL: ========================================"):
			PoCOutputFound = True
			yield LogEntry(line[8:], Severity.Normal)
		elif line.startswith("KERNEL: "):
			if (not PoCOutputFound):
				yield LogEntry(line, Severity.Verbose)
			else:
				yield LogEntry(line[8:], Severity.Normal)
		else:
			yield LogEntry(line, Severity.Normal)
