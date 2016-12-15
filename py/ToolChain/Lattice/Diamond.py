# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#
# Python Class:     Lattice Diamond specific classes
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
import time

from pathlib                  import Path
from subprocess               import check_output, CalledProcessError, STDOUT

from lib.Functions            import Init
from Base.Exceptions          import PlatformNotSupportedException
from Base.Logging             import Severity, LogEntry
from Base.Executable          import CommandLineArgumentList, ExecutableArgument, ShortTupleArgument, DryRunException
from Base.Project             import File, FileTypes, VHDLVersion
from ToolChain                import ToolMixIn, ConfigurationException, ToolConfiguration, OutputFilteredExecutable
from ToolChain.GNU            import Bash
from ToolChain.Windows        import Cmd
from ToolChain.Lattice        import LatticeException


__api__ = [
	'DiamondException',
	'Configuration',
	'Diamond',
	'Synth',
	'SynthesisArgumentFile',
	'MapFilter',
	'CompilerFilter'
]
__all__ = __api__


class DiamondException(LatticeException):
	pass


class Configuration(ToolConfiguration):
	_vendor =               "Lattice"                   #: The name of the tools vendor.
	_toolName =             "Lattice Diamond"           #: The name of the tool.
	_section  =             "INSTALL.Lattice.Diamond"   #: The name of the configuration section. Pattern: ``INSTALL.Vendor.ToolName``.
	_multiVersionSupport =  True                        #: Lattice Diamond supports multiple versions installed on the same system.
	_template = {
		"Windows": {
			_section: {
				"Version":                "3.8",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Lattice:InstallationDirectory}/Diamond/${Version}_x64"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/bin/nt64"),
				"BinaryDirectory2":       ("${${SectionName}:BinaryDirectory2}",      "${InstallationDirectory}/ispfpga/bin/nt64")
			}
		},
		"Linux": {
			_section: {
				"Version":                "3.8",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Lattice:InstallationDirectory}/diamond/${Version}_x64"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/bin/lin64"),
				"BinaryDirectory2":       ("${${SectionName}:BinaryDirectory2}",      "${InstallationDirectory}/ispfpga/bin/lin64")
			}
		}
	}                                                   #: The template for the configuration sections represented as nested dictionaries.

	def CheckDependency(self):
		"""Check if general Lattice support is configured in PoC."""
		return (len(self._host.PoCConfig['INSTALL.Lattice']) != 0)

	def ConfigureForAll(self):
		try:
			if (not self._AskInstalled("Is Lattice Diamond installed on your system?")):
				self.ClearSection()
			else:
				# Configure Diamond version
				version = self._ConfigureVersion()
				if self._multiVersionSupport:
					self.PrepareVersionedSections()
					sectionName = self._host.PoCConfig[self._section]['SectionName']
					self._host.PoCConfig[sectionName]['Version'] = version

				self._ConfigureInstallationDirectory()
				binPath = self._ConfigureBinaryDirectory()
				self.__CheckDiamondVersion(binPath, version)
				self._host.LogNormal("{DARK_GREEN}Lattice Diamond is now configured.{NOCOLOR}".format(**Init.Foreground), indent=1)
		except ConfigurationException:
			self.ClearSection()
			raise

	def __CheckDiamondVersion(self, binPath, version):
		if (self._host.Platform == "Windows"):  tclShellPath = binPath / "pnmainc.exe"
		else:                                   tclShellPath = binPath / "pnmainc"

		if not tclShellPath.exists():
			raise ConfigurationException("Executable '{0!s}' not found.".format(tclShellPath)) from FileNotFoundError(
				str(tclShellPath))

		try:
			output = check_output([str(tclShellPath), "???"], stderr=STDOUT, universal_newlines=True)
		except CalledProcessError as ex:
			output = ex.output

		for line in output.split('\n'):
			if str(version) in line:
				break
		else:
			raise ConfigurationException("Diamond version mismatch. Expected version {0}.".format(version))

		self._host.PoCConfig[self._section]['Version'] = version

	def _ConfigureBinaryDirectory(self):
		"""Updates section with value from _template and returns directory as Path object."""
		binPath = super()._ConfigureBinaryDirectory()
		# unresolved = self._template[self._host.Platform][self._section]['BinaryDirectory2']
		# self._host.PoCConfig[self._section]['BinaryDirectory2'] = unresolved  # create entry
		defaultPath = Path(self._host.PoCConfig[self._section]['BinaryDirectory2'])  # resolve entry

		binPath2 = defaultPath  # may be more complex in the future

		if (not binPath2.exists()):
			raise ConfigurationException("{0!s} 2nd binary directory '{1!s}' does not exist.".format(self, binPath2)) \
				from NotADirectoryError(str(binPath2))

		return binPath


class Diamond(ToolMixIn):
	def PreparseEnvironment(self, installationDirectory):
		if (self._platform == "Linux"):
			cmd = Bash(self._platform, self._dryrun, logger=self._logger)
			settingsFile = installationDirectory / "bin/lin64/diamond_env"
			self._environment = cmd.GetEnvironment(settingsFile, variables="bindir={0!s}/bin/lin64; ".format(installationDirectory))
		elif (self._platform == "Windows"):
			cmd = Cmd(self._platform, self._dryrun, logger=self._logger)
			self._environment = cmd.GetEnvironment()
			self._environment.Variables['LSC_INI_PATH'] = ""
			self._environment.Variables['LSC_DIAMOND'] =  "true"
			self._environment.Variables['FOUNDRY'] =      str(installationDirectory / "ispFPGA")
			self._environment.Variables['TCL_LIBRARY'] =  str(installationDirectory / "tcltk\\lib\\tcl8.5")

	def GetSynthesizer(self):
		return Synth(self)


class Synth(OutputFilteredExecutable, ToolMixIn):
	def __init__(self, toolchain : ToolMixIn):
		ToolMixIn.__init__(
			self, toolchain._platform, toolchain._dryrun, toolchain._binaryDirectoryPath, toolchain._version,
			toolchain._logger)

		if (self._platform == "Windows"):    executablePath = self._binaryDirectoryPath / "synthesis.exe"
		elif (self._platform == "Linux"):    executablePath = self._binaryDirectoryPath / "synthesis"
		else:                          raise PlatformNotSupportedException(self._platform)
		super().__init__(self._platform, self._dryrun, executablePath, environment=toolchain._environment, logger=self._logger)

		self.Parameters[self.Executable] = executablePath

	class Executable(metaclass=ExecutableArgument):
		pass

	class SwitchProjectFile(metaclass=ShortTupleArgument):
		_name = "f"
		_value = None

	Parameters = CommandLineArgumentList(
		Executable,
		SwitchProjectFile
	)

	def GetLogFileReader(self, logFile):
		while True:
			if logFile.exists(): break
			time.sleep(5)							# FIXME: implement a 'tail -f' functionality

		with logFile.open('r') as logFileHandle:
			for line in logFileHandle:
				yield line[:-1]

	def Compile(self, logFile):
		parameterList = self.Parameters.ToArgumentList()
		self.LogVerbose("command: {0}".format(" ".join(parameterList)))

		if (self._dryrun):
			self.LogDryRun("Start process: {0}".format(" ".join(parameterList)))
			return

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise LatticeException("Failed to launch LSE.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		try:
			iterator = iter(CompilerFilter(self.GetReader()))

			line = next(iterator)
			self._hasOutput = True
			self.LogNormal("  LSE messages for '{0}'".format(self.Parameters[self.SwitchProjectFile]))
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


class SynthesisArgumentFile(File):
	def __init__(self, file):
		super().__init__(file)

		self._architecture =  None
		self._device =        None
		self._speedGrade =    None
		self._package =       None
		self._topLevel =      None
		self.Logfile =        None
		self._vhdlVersion =		VHDLVersion.Any
		self._hdlParams =			{}

	@property
	def Architecture(self):
		return self._architecture
	@Architecture.setter
	def Architecture(self, value):
		self._architecture = value

	@property
	def Device(self):
		return self._device
	@Device.setter
	def Device(self, value):
		self._device = value

	@property
	def SpeedGrade(self):
		return self._speedGrade
	@SpeedGrade.setter
	def SpeedGrade(self, value):
		self._speedGrade = value

	@property
	def Package(self):
		return self._package
	@Package.setter
	def Package(self, value):
		self._package = value

	@property
	def TopLevel(self):
		return self._topLevel
	@TopLevel.setter
	def TopLevel(self, value):
		self._topLevel = value

	@property
	def LogFile(self):
		return self.Logfile
	@LogFile.setter
	def LogFile(self, value):
		self.Logfile = value

	@property
	def VHDLVersion(self):
		return self._vhdlVersion
	@VHDLVersion.setter
	def VHDLVersion(self, value):
		self._vhdlVersion = value

	@property
	def HDLParams(self):
		return self._hdlParams

	def Write(self, project):
		if (self._file is None):    raise DiamondException("No file path for SynthesisArgumentFile provided.")

		buffer = ""
		if (self._architecture is None):  raise DiamondException("Argument 'Architecture' (-a) is not set.")
		buffer += "-a {0}\n".format(self._architecture)
		if (self._device is None):        raise DiamondException("Argument 'Device' (-d) is not set.")
		buffer += "-d {0}\n".format(self._device)
		if (self._speedGrade is None):    raise DiamondException("Argument 'SpeedGrade' (-s) is not set.")
		buffer += "-s {0}\n".format(self._speedGrade)
		if (self._package is None):       raise DiamondException("Argument 'Package' (-t) is not set.")
		buffer += "-t {0}\n".format(self._package)
		if (self._topLevel is None):      raise DiamondException("Argument 'TopLevel' (-top) is not set.")
		buffer += "-top {0}\n".format(self._topLevel)
		if (self._vhdlVersion is VHDLVersion.VHDL2008):
			buffer += "-vh2008\n"
		if (self.Logfile is not None):
			buffer += "-logfile {0}\n".format(self.Logfile)
		for keyValuePair in self._hdlParams.items():
			buffer += "-hdl_param {0} {1}\n".format(*keyValuePair)

		for file in project.Files(fileType=FileTypes.VHDLSourceFile):
			buffer += "-lib {library}\n-vhd {file}\n".format(file=file.Path.as_posix(), library=file.LibraryName)

		with self._file.open('w') as fileHandle:
			fileHandle.write(buffer)


def MapFilter(gen):
	for line in gen:
		yield LogEntry(line, Severity.Normal)


def CompilerFilter(gen):
	for line in gen:
		if line.startswith("ERROR "):
			yield LogEntry(line, Severity.Error)
		elif line.startswith("WARNING "):
			yield LogEntry(line, Severity.Warning)
		elif line.startswith("INFO "):
			yield LogEntry(line, Severity.Info)
		else:
			yield LogEntry(line, Severity.Normal)
