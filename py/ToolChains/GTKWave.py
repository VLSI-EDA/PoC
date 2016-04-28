# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:					Patrick Lehmann
#
# Python Class:			GTKWave specific classes
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
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module ToolChains.GTKWave")


from collections						import OrderedDict
from pathlib								import Path

from Base.Exceptions				import PlatformNotSupportedException
from Base.Logging						import LogEntry, Severity
from Base.Configuration			import Configuration as BaseConfiguration, ConfigurationException
from Base.Executable				import Executable, ExecutableArgument, LongValuedFlagArgument, CommandLineArgumentList
from Base.ToolChain					import ToolChainException


class GTKWaveException(ToolChainException):
	pass


class Configuration(BaseConfiguration):
	_vendor =			None
	_toolName =		"GTKWave"
	_section = 		"INSTALL.GTKWave"
	_template = {
		"Windows": {
			_section: {
				"Version":								"3.3.70",
				"InstallationDirectory":	"C:/Tools/GTKWave/${Version}",
				"BinaryDirectory":				"${InstallationDirectory}/bin"
			}
		},
		"Linux": {
			_section: {
				"Version":								"3.3.70",
				"InstallationDirectory":	"/usr/bin",
				"BinaryDirectory":				"${InstallationDirectory}"
			}
		},
		"Darwin": {
			_section: {
				"Version":								"3.3.70",
				"InstallationDirectory":	"/usr/bin",
				"BinaryDirectory":				"${InstallationDirectory}"
			}
		}
	}

	def CheckDependency(self):
		# return True if Xilinx is configured
		return (len(self._host.PoCConfig['INSTALL.GHDL']) != 0)


	# GTKWave unter Windows
	"""
	PS G:\git\PoC> C:\Tools\GTKwave\bin\gtkwave.exe --version
	GTKWave Analyzer v3.3.69 (w)1999-2016 BSI

	This is free software; see the source for copying conditions.  There is NO
	warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
	"""


	# def manualConfigureForWindows(self) :
	# 	# Ask for installed GTKWave
	# 	isGTKW = input('Is GTKWave installed on your system? [Y/n/p]: ')
	# 	isGTKW = isGTKW if isGTKW != "" else "Y"
	# 	if (isGTKW in ['p', 'P']) :
	# 		pass
	# 	elif (isGTKW in ['n', 'N']) :
	# 		self.pocConfig['GTKWave'] = OrderedDict()
	# 	elif (isGTKW in ['y', 'Y']) :
	# 		gtkwDirectory = input('GTKWave installation directory [C:\Program Files (x86)\GTKWave]: ')
	# 		gtkwVersion = input('GTKWave version number [3.3.61]: ')
	# 		print()
	#
	# 		gtkwDirectory = gtkwDirectory if gtkwDirectory != "" else "C:\Program Files (x86)\GTKWave"
	# 		gtkwVersion = gtkwVersion if gtkwVersion != "" else "3.3.61"
	#
	# 		gtkwDirectoryPath = Path(gtkwDirectory)
	# 		gtkwExecutablePath = gtkwDirectoryPath / "bin" / "gtkwave.exe"
	#
	# 		if not gtkwDirectoryPath.exists() :  raise ConfigurationException(
	# 			"GTKWave installation directory '%s' does not exist." % gtkwDirectory)
	# 		if not gtkwExecutablePath.exists() :  raise ConfigurationException("GTKWave is not installed.")
	#
	# 		self.pocConfig['GTKWave']['Version'] = gtkwVersion
	# 		self.pocConfig['GTKWave']['InstallationDirectory'] = gtkwDirectoryPath.as_posix()
	# 		self.pocConfig['GTKWave']['BinaryDirectory'] = '${InstallationDirectory}/bin'
	# 	else :
	# 		raise ConfigurationException("unknown option")
	#
	# def manualConfigureForLinux(self) :
	# 	# Ask for installed GTKWave
	# 	isGTKW = input('Is GTKWave installed on your system? [Y/n/p]: ')
	# 	isGTKW = isGTKW if isGTKW != "" else "Y"
	# 	if (isGTKW in ['p', 'P']) :
	# 		pass
	# 	elif (isGTKW in ['n', 'N']) :
	# 		self.pocConfig['GTKWave'] = OrderedDict()
	# 	elif (isGTKW in ['y', 'Y']) :
	# 		gtkwDirectory = input('GTKWave installation directory [/usr/bin]: ')
	# 		gtkwVersion = input('GTKWave version number [3.3.61]: ')
	# 		print()
	#
	# 		gtkwDirectory = gtkwDirectory if gtkwDirectory != "" else "/usr/bin"
	# 		gtkwVersion = gtkwVersion if gtkwVersion != "" else "3.3.61"
	#
	# 		gtkwDirectoryPath = Path(gtkwDirectory)
	# 		gtkwExecutablePath = gtkwDirectoryPath / "gtkwave"
	#
	# 		if not gtkwDirectoryPath.exists() :  raise ConfigurationException(
	# 			"GTKWave installation directory '%s' does not exist." % gtkwDirectory)
	# 		if not gtkwExecutablePath.exists() :  raise ConfigurationException("GTKWave is not installed.")
	#
	# 		self.pocConfig['GTKWave']['Version'] = gtkwVersion
	# 		self.pocConfig['GTKWave']['InstallationDirectory'] = gtkwDirectoryPath.as_posix()
	# 		self.pocConfig['GTKWave']['BinaryDirectory'] = '${InstallationDirectory}'
	# 	else :
	# 		raise ConfigurationException("unknown option")


class GTKWave(Executable):
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		if (platform == "Windows"):			executablePath = binaryDirectoryPath/ "gtkwave.exe"
		elif (platform == "Linux"):			executablePath = binaryDirectoryPath/ "gtkwave"
		elif (platform == "Darwin"):		executablePath = binaryDirectoryPath/ "gtkwave"
		else:																						raise PlatformNotSupportedException(self._platform)
		super().__init__(platform, executablePath, logger=logger)

		self.Parameters[self.Executable] = executablePath

		self._binaryDirectoryPath =	binaryDirectoryPath
		self._version =			version

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

		except StopIteration as ex:
			pass
		except GTKWaveException:
			raise
		#except Exception as ex:
		#	raise GTKWaveException("Error while executing GTKWave.") from ex
		finally:
			if self._hasOutput:
				self._LogNormal("    " + ("-" * 76))

def GTKWaveFilter(gen):
	for line in gen:
		yield LogEntry(line, Severity.Normal)
