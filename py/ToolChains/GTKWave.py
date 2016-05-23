# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#                   Thomas B. Preusser
#
# Python Class:      GTKWave specific classes
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
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module ToolChains.GTKWave")


from pathlib                import Path
from re                     import compile as RegExpCompile
from subprocess             import check_output, CalledProcessError

from Base.Configuration      import Configuration as BaseConfiguration, ConfigurationException
from Base.Exceptions        import PlatformNotSupportedException
from Base.Executable        import Executable, ExecutableArgument, LongValuedFlagArgument, CommandLineArgumentList
from Base.Logging            import LogEntry, Severity
from Base.ToolChain          import ToolChainException


class GTKWaveException(ToolChainException):
	pass


class Configuration(BaseConfiguration):
	_vendor =      None
	_toolName =    "GTKWave"
	_section =     "INSTALL.GTKWave"
	_template = {
		"Windows": {
			_section: {
				"Version":                "3.3.71",
				"InstallationDirectory":  "C:/Program Files (x86)/GTKWave",
				"BinaryDirectory":        "${InstallationDirectory}/bin"
			}
		},
		"Linux": {
			_section: {
				"Version":                "3.3.71",
				"InstallationDirectory":  "/usr/bin",
				"BinaryDirectory":        "${InstallationDirectory}"
			}
		},
		"Darwin": {
			_section: {
				"Version":                "3.3.71",
				"InstallationDirectory":  "/usr/bin",
				"BinaryDirectory":        "${InstallationDirectory}"
			}
		}
	}

	def CheckDependency(self):
		# return True if Xilinx is configured
		return (len(self._host.PoCConfig['INSTALL.GHDL']) != 0)

	def ConfigureForAll(self):
		try:
			if (not self._AskInstalled("Is GTKWave installed on your system?")):
				self.ClearSection()
			else:
				self._ConfigureInstallationDirectory()
				binPath = self._ConfigureBinaryDirectory()
				self.__WriteGtkWaveSection(binPath)
		except ConfigurationException:
			self.ClearSection()
			raise

	def _GetDefaultInstallationDirectory(self):
		if (self._host.Platform in ["Linux", "Darwin"]):
			try:
				name = check_output(["which", "gtkwave"], universal_newlines=True)
				if name != "": return Path(name[:-1]).parent.as_posix()
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
		versionRegExp = RegExpCompile(versionRegExpStr)
		for line in output.split('\n'):
			if version is None:
				match = versionRegExp.match(line)
				if match is not None:
					version = match.group(1)

		self._host.PoCConfig[self._section]['Version'] = version



class GTKWave(Executable):
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		if (platform == "Windows"):      executablePath = binaryDirectoryPath/ "gtkwave.exe"
		elif (platform == "Linux"):      executablePath = binaryDirectoryPath/ "gtkwave"
		elif (platform == "Darwin"):    executablePath = binaryDirectoryPath/ "gtkwave"
		else:                                            raise PlatformNotSupportedException(self._platform)
		super().__init__(platform, executablePath, logger=logger)

		self.Parameters[self.Executable] = executablePath

		self._binaryDirectoryPath =  binaryDirectoryPath
		self._version =      version

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False

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
		self._LogVerbose("command: {0}".format(" ".join(parameterList)))

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
			line.IndentBy(2)
			self._hasOutput = True
			self._LogNormal("    GTKWave messages for '{0}'".format(self.Parameters[self.SwitchDumpFile]))
			self._LogNormal("    " + ("-" * 76))
			self._Log(line)

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line = next(iterator)
				line.IndentBy(2)
				self._Log(line)

		except StopIteration:
			pass
		finally:
			if self._hasOutput:
				self._LogNormal("    " + ("-" * 76))

def GTKWaveFilter(gen):
	for line in gen:
		yield LogEntry(line, Severity.Normal)
