# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#                   Thomas B. Preusser
#
# Python Class:     GTKWave specific classes
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
from pathlib                  import Path
from re                       import compile as re_compile
from subprocess               import check_output, CalledProcessError

from lib.Functions            import Init
from Base.Exceptions          import PlatformNotSupportedException
from Base.Logging             import LogEntry, Severity
from Base.Executable          import ExecutableArgument, LongValuedFlagArgument, CommandLineArgumentList, DryRunException
from ToolChain                import ToolChainException, ConfigurationException, ToolConfiguration, OutputFilteredExecutable


__api__ = [
	'GTKWaveException',
	'Configuration',
	'GTKWave',
	'GTKWaveFilter'
]
__all__ = __api__



class GTKWaveException(ToolChainException):
	pass


class Configuration(ToolConfiguration):
	_vendor =               "TonyBybell"                #: The name of the tools vendor.
	_toolName =             "GTKWave"                   #: The name of the tool.
	_section  =             "INSTALL.GTKWave"           #: The name of the configuration section. Pattern: ``INSTALL.Vendor.ToolName``.
	_multiVersionSupport =  True                        #: GTKWave supports multiple versions installed on the same system.
	_template = {
		"Windows": {
			_section: {
				"Version":                "3.3.78",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "C:/Program Files (x86)/GTKWave"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/bin")
			}
		},
		"Linux": {
			_section: {
				"Version":                "3.3.78",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "/usr/bin"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}")
			}
		},
		"Darwin": {
			_section: {
				"Version":                "3.3.78",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "/usr/bin"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}")
			}
		}
	}                                                   #: The template for the configuration sections represented as nested dictionaries.

	def CheckDependency(self):
		# return True if Xilinx is configured
		return (len(self._host.PoCConfig['INSTALL.GHDL']) != 0)

	def ConfigureForAll(self):
		try:
			if (not self._AskInstalled("Is GTKWave installed on your system?")):
				self.ClearSection()
			else:
				# Configure GTKWave version
				version = "3.3.78"
				if self._multiVersionSupport:
					self.PrepareVersionedSections()
					sectionName = self._host.PoCConfig[self._section]['SectionName']
					self._host.PoCConfig[sectionName]['Version'] = version

				self._ConfigureInstallationDirectory()
				binPath = self._ConfigureBinaryDirectory()
				self.__WriteGtkWaveSection(binPath)
				self._host.LogNormal("{DARK_GREEN}GTKWave is now configured.{NOCOLOR}".format(**Init.Foreground), indent=1)
		except ConfigurationException:
			self.ClearSection()
			raise

	def _GetDefaultInstallationDirectory(self):
		if (self._host.Platform in ["Linux", "Darwin"]):
			try:
				name = check_output(["which", "gtkwave"], universal_newlines=True).strip()
				if name != "": return Path(name).parent.as_posix()
			except CalledProcessError:
				pass # `which` returns non-zero exit code if executable is not in PATH

		return super()._GetDefaultInstallationDirectory()

	def __WriteGtkWaveSection(self, binPath):
		if (self._host.Platform == "Windows"):
			gtkwPath = binPath / "gtkwave.exe"
		else:
			gtkwPath = binPath / "gtkwave"

		if not gtkwPath.exists():
			raise ConfigurationException("Executable '{0!s}' not found.".format(gtkwPath)) from FileNotFoundError(
				str(gtkwPath))

		# get version and backend
		output = check_output([str(gtkwPath), "--version"], universal_newlines=True)
		version = None
		versionRegExpStr = r"^GTKWave Analyzer v(.+?) "
		versionRegExp = re_compile(versionRegExpStr)
		for line in output.split('\n'):
			if version is None:
				match = versionRegExp.match(line)
				if match is not None:
					version = match.group(1)

		self._host.PoCConfig[self._section]['Version'] = version


class GTKWave(OutputFilteredExecutable):
	def __init__(self, platform, dryrun, binaryDirectoryPath, version, logger=None):
		if (platform == "Windows"):     executablePath = binaryDirectoryPath/ "gtkwave.exe"
		elif (platform == "Linux"):     executablePath = binaryDirectoryPath/ "gtkwave"
		elif (platform == "Darwin"):    executablePath = binaryDirectoryPath/ "gtkwave"
		else:                                            raise PlatformNotSupportedException(self._platform)
		super().__init__(platform, dryrun, executablePath, logger=logger)

		self.Parameters[self.Executable] = executablePath

		self._binaryDirectoryPath = binaryDirectoryPath
		self._version =             version

	@property
	def BinaryDirectoryPath(self):
		return self._binaryDirectoryPath

	@property
	def Version(self):
		return self._version

	class Executable(metaclass=ExecutableArgument):
		pass

	class SwitchDumpFile(metaclass=LongValuedFlagArgument):
		_name = "dump"

	class SwitchSaveFile(metaclass=LongValuedFlagArgument):
		_name = "save"

	Parameters = CommandLineArgumentList(
		Executable,
		SwitchDumpFile,
		SwitchSaveFile
	)

	def View(self):
		parameterList = self.Parameters.ToArgumentList()
		self.LogVerbose("command: {0}".format(" ".join(parameterList)))

		if (self._dryrun):
			self.LogDryRun("Start process: {0}".format(" ".join(parameterList)))
			return

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise GTKWaveException("Failed to launch GTKWave run.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		try:
			iterator = iter(GTKWaveFilter(self.GetReader()))

			line = next(iterator)
			line.IndentBy(self.Logger.BaseIndent + 1)
			self._hasOutput = True
			self.LogNormal("  GTKWave messages for '{0}'".format(self.Parameters[self.SwitchDumpFile]))
			self.LogNormal("  " + ("-" * (78 - self.Logger.BaseIndent*2)))
			self.Log(line)

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line = next(iterator)
				line.IndentBy(self.Logger.BaseIndent + 1)
				self.Log(line)

		except DryRunException:
			pass
		except StopIteration:
			pass
		finally:
			if self._hasOutput:
				self.LogNormal("  " + ("-" * (78 - self.Logger.BaseIndent*2)))


def GTKWaveFilter(gen):
	for line in gen:
		yield LogEntry(line, Severity.Normal)
