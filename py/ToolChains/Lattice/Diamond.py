# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:					Patrick Lehmann
#
# Python Class:			Lattice Diamond specific classes
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
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module ToolChains.Lattice.Diamond")


from subprocess										import check_output, CalledProcessError, STDOUT

from Base.Configuration						import Configuration as BaseConfiguration, ConfigurationException
from Base.Exceptions							import PlatformNotSupportedException
from Base.Executable							import Executable, CommandLineArgumentList, ExecutableArgument
from Base.Logging									import Severity, LogEntry
from Base.Project									import File, FileTypes
from ToolChains.Lattice.Lattice		import LatticeException


class DiamondException(LatticeException):
	pass


class Configuration(BaseConfiguration):
	_vendor =		"Lattice"
	_toolName =	"Lattice Diamond"
	_section =	"INSTALL.Lattice.Diamond"
	_template = {
		"Windows": {
			_section: {
				"Version":								"3.7",
				"InstallationDirectory":	"${INSTALL.Lattice:InstallationDirectory}/Diamond/${Version}_x64",
				"BinaryDirectory":				"${InstallationDirectory}/bin/nt64"
			}
		},
		"Linux": {
			_section: {
				"Version":								"3.7",
				"InstallationDirectory":	"${INSTALL.Lattice:InstallationDirectory}/diamond/${Version}_x64",
				"BinaryDirectory":				"${InstallationDirectory}/bin/lin64"
			}
		}
	}

	def CheckDependency(self):
		# return True if Lattice is configured
		return (len(self._host.PoCConfig['INSTALL.Lattice']) != 0)

	def ConfigureForAll(self):
		try:
			if (not self._AskInstalled("Is Lattice Diamond installed on your system?")):
				self.ClearSection()
			else:
				version = self._ConfigureVersion()
				self._ConfigureInstallationDirectory()
				binPath = self._ConfigureBinaryDirectory()
				self.__CheckDiamondVersion(binPath, version)
		except ConfigurationException:
			self.ClearSection()
			raise

	def __CheckDiamondVersion(self, binPath, version):
		if (self._host.Platform == "Windows"):	tclShellPath = binPath / "pnmainc.exe"
		else:																		tclShellPath = binPath / "pnmainc"

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


class DiamondMixIn:
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		self._platform = platform
		self._binaryDirectoryPath = binaryDirectoryPath
		self._version = version
		self._logger = logger


class Diamond(DiamondMixIn):
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		DiamondMixIn.__init__(self, platform, binaryDirectoryPath, version, logger)

	def GetTclShell(self):
		return TclShell(self._platform, self._binaryDirectoryPath, self._version, logger=self._logger)

class TclShell(Executable, DiamondMixIn):
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		DiamondMixIn.__init__(self, platform, binaryDirectoryPath, version, logger)

		if (platform == "Windows"):		executablePath = binaryDirectoryPath / "pnmainc.exe"
		elif (platform == "Linux"):		executablePath = binaryDirectoryPath / "pnmainc"
		else:													raise PlatformNotSupportedException(platform)
		Executable.__init__(self, platform, executablePath, logger=logger)

		self.Parameters[self.Executable] = executablePath

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False

	@property
	def HasWarnings(self):	return self._hasWarnings
	@property
	def HasErrors(self):		return self._hasErrors

	class Executable(metaclass=ExecutableArgument):
		pass

	Parameters = CommandLineArgumentList(
		Executable
	)

	def Run(self):
		parameterList = self.Parameters.ToArgumentList()
		self._LogVerbose("command: {0}".format(" ".join(parameterList)))

		try:
			self.StartProcess(parameterList)
			self.SendBoundary()
		except Exception as ex:
			raise DiamondException("Failed to launch pnmainc.") from ex

		iterator = iter(MapFilter(self.GetReader()))

		for line in iterator:
			print(line)
			if (line == self._POC_BOUNDARY):
				break

		print("pnmainc is ready")

		self.Send("synthesis -f arith_prng.prj\n")
		self.SendBoundary()

		for line in iterator:
			print(line)
			if (line == self._POC_BOUNDARY):
				break

		print("pnmainc is ready")

		self.Send("exit\n")
		self.SendBoundary()

		for line in iterator:
			print(line)
			if (line == self._POC_BOUNDARY):
				break

		print("pnmainc finished")
		return

		# self._hasOutput = False
		# self._hasWarnings = False
		# self._hasErrors = False
		# try:
		# 	iterator = iter(MapFilter(self.GetReader()))
		#
		# 	line = next(iterator)
		# 	self._hasOutput = True
		# 	self._LogNormal("    pnmainc messages for '{0}'".format(self.Parameters[self.SwitchArgumentFile]))
		# 	self._LogNormal("    " + ("-" * 76))
		#
		# 	while True:
		# 		self._hasWarnings |= (line.Severity is Severity.Warning)
		# 		self._hasErrors |= (line.Severity is Severity.Error)
		#
		# 		line.Indent(2)
		# 		self._Log(line)
		# 		line = next(iterator)
		#
		# except StopIteration as ex:
		# 	pass
		# except DiamondException:
		# 	raise
		# # except Exception as ex:
		# #	raise GHDLException("Error while executing GHDL.") from ex
		# finally:
		# 	if self._hasOutput:
		# 		self._LogNormal("    " + ("-" * 76))


def MapFilter(gen):
	for line in gen:
		yield LogEntry(line, Severity.Normal)


class SynthesisArgumentFile(File):
	def __init__(self, file):
		super().__init__(file)

		self._architecture =	None
		self._topLevel =			None
		self._logfile =				None

	@property
	def Architecture(self):
		return self._architecture
	@Architecture.setter
	def Architecture(self, value):
		self._architecture = value

	@property
	def TopLevel(self):
		return self._topLevel
	@TopLevel.setter
	def TopLevel(self, value):
		self._topLevel = value

	@property
	def LogFile(self):
		return self._logfile
	@LogFile.setter
	def LogFile(self, value):
		self._logfile = value

	def Write(self, project):
		if (self._file is None):    raise DiamondException("No file path for SynthesisArgumentFile provided.")

		buffer = ""
		if (self._architecture is None):	raise DiamondException("Argument 'Architecture' (-a) is not set.")
		buffer += "-a {0}\n".format(self._architecture)
		if (self._topLevel is None):			raise DiamondException("Argument 'TopLevel' (-top) is not set.")
		buffer += "-top {0}\n".format(self._topLevel)
		if (self._logfile is not None):
			buffer += "-logfile {0}\n".format(self._logfile)

		for file in project.Files(fileType=FileTypes.VHDLSourceFile):
			buffer += "-lib {library}\n-vhd {file}\n".format(file=file.Path.as_posix(), library=file.LibraryName)

		with self._file.open('w') as fileHandle:
			fileHandle.write(buffer)
