# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:				 	Patrick Lehmann
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
if __name__ != "__main__":
	# place library initialization code here
	pass
else:
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module ToolChains.Xilinx.Vivado")


from collections					import OrderedDict
from os										import environ

from Base.Exceptions			import PlatformNotSupportedException
from Base.Executable			import *
from Base.Logging					import LogEntry, Severity
from Base.Configuration 	import ConfigurationBase, ConfigurationException, SkipConfigurationException


class Configuration(ConfigurationBase):
	_vendor =		"Xilinx"
	_shortName =	"Vivado"
	_longName =	"Xilinx Vivado"
	_privateConfiguration = {
		"Windows": {
			"Xilinx": {
				"InstallationDirectory":	"C:/Xilinx"
			},
			"Xilinx.Vivado": {
				"Version":								"2015.4",
				"InstallationDirectory":	"${Xilinx:InstallationDirectory}/Vivado/${Version}",
				"BinaryDirectory":				"${InstallationDirectory}/bin"
			}
		},
		"Linux": {
			"Xilinx": {
				"InstallationDirectory":	"/opt/Xilinx"
			},
			"Xilinx.Vivado": {
				"Version":								"2015.4",
				"InstallationDirectory":	"${Xilinx:InstallationDirectory}/Vivado/${Version}",
				"BinaryDirectory":				"${InstallationDirectory}/bin"
			}
		}
	}

	def GetSections(self, Platform):
		pass


	def ConfigureForWindows(self):
		xilinxDirectory = self.__GetXilinxPath()
		if (xilinxDirectory is None):
			xilinxDirectory = self.__AskXilinxPath()
		if (not xilinxDirectory.exists()):    raise ConfigurationException("Xilinx installation directory '{0}' does not exist.".format(xilinxDirectory))  from NotADirectoryError(xilinxDirectory)


	def __GetXilinxPath(self):
		xilinx = environ.get('XILINX')
		if (xilinx is None):
			return None
		else:
			return Path(xilinx)


	def __AskXilinxPath(self):
		# Ask for installed Xilinx ISE
		isXilinxISE = input('Is Xilinx ISE installed on your system? [Y/n/p]: ')
		isXilinxISE = isXilinxISE if isXilinxISE != "" else "Y"
		if (isXilinxISE in ['p', 'P']):
			raise SkipConfigurationException()
		elif (isXilinxISE in ['n', 'N']):
			return None
		elif (isXilinxISE in ['y', 'Y']):
			default = Path(self._privateConfiguration['Windows']['Xilinx']['InstallationDirectory'])
			xilinxDirectory = input('Xilinx installation directory [{0}]: '.format(str(default)))
			if (xilinxDirectory != ""):
				return Path(xilinxDirectory)
			else:
				return default
		else:
			raise ConfigurationException("Unsupported choice '{0}'".format(isXilinxISE))



	def manualConfigureForWindows(self) :
		# Ask for installed Xilinx Vivado
		isXilinxVivado = input('Is Xilinx Vivado installed on your system? [Y/n/p]: ')
		isXilinxVivado = isXilinxVivado if isXilinxVivado != "" else "Y"
		if (isXilinxVivado in ['p', 'P']) :
			pass
		elif (isXilinxVivado in ['n', 'N']) :
			self.pocConfig['Xilinx.Vivado'] = OrderedDict()
		elif (isXilinxVivado in ['y', 'Y']) :
			xilinxDirectory = input('Xilinx installation directory [C:\Xilinx]: ')
			vivadoVersion = input('Xilinx Vivado version number [2015.2]: ')
			print()

			xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "C:\Xilinx"
			vivadoVersion = vivadoVersion if vivadoVersion != "" else "2015.2"

			xilinxDirectoryPath = Path(xilinxDirectory)
			vivadoDirectoryPath = xilinxDirectoryPath / "Vivado" / vivadoVersion

			if not xilinxDirectoryPath.exists() :  raise BaseException(
				"Xilinx installation directory '%s' does not exist." % xilinxDirectory)
			if not vivadoDirectoryPath.exists() :  raise BaseException(
				"Xilinx Vivado version '%s' is not installed." % vivadoVersion)

			self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
			self.pocConfig['Xilinx.Vivado']['Version'] = vivadoVersion
			self.pocConfig['Xilinx.Vivado']['InstallationDirectory'] = '${Xilinx:InstallationDirectory}/Vivado/${Version}'
			self.pocConfig['Xilinx.Vivado']['BinaryDirectory'] = '${InstallationDirectory}/bin'
		else :
			raise BaseException("unknown option")


	def manualConfigureForLinuxo(self) :
		# Ask for installed Xilinx Vivado
		isXilinxVivado = input('Is Xilinx Vivado installed on your system? [Y/n/p]: ')
		isXilinxVivado = isXilinxVivado if isXilinxVivado != "" else "Y"
		if (isXilinxVivado in ['p', 'P']) :
			pass
		elif (isXilinxVivado in ['n', 'N']) :
			self.pocConfig['Xilinx.Vivado'] = OrderedDict()
		elif (isXilinxVivado in ['y', 'Y']) :
			xilinxDirectory = input('Xilinx installation directory [/opt/Xilinx]: ')
			vivadoVersion = input('Xilinx Vivado version number [2015.2]: ')
			print()

			xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "/opt/Xilinx"
			vivadoVersion = vivadoVersion if vivadoVersion != "" else "2015.2"

			xilinxDirectoryPath = Path(xilinxDirectory)
			vivadoDirectoryPath = xilinxDirectoryPath / "Vivado" / vivadoVersion

			if not xilinxDirectoryPath.exists() :  raise BaseException(
				"Xilinx installation directory '%s' does not exist." % xilinxDirectory)
			if not vivadoDirectoryPath.exists() :  raise BaseException(
				"Xilinx Vivado version '%s' is not installed." % vivadoVersion)

			self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
			self.pocConfig['Xilinx.Vivado']['Version'] = vivadoVersion
			self.pocConfig['Xilinx.Vivado']['InstallationDirectory'] = '${Xilinx:InstallationDirectory}/Vivado/${Version}'
			self.pocConfig['Xilinx.Vivado']['BinaryDirectory'] = '${InstallationDirectory}/bin'
		else :
			raise BaseException("unknown option")

class VivadoSimMixIn:
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		self._platform =						platform
		self._binaryDirectoryPath =	binaryDirectoryPath
		self._version =							version
		self._logger =							logger

class Vivado(VivadoSimMixIn):
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		VivadoSimMixIn.__init__(self, platform, binaryDirectoryPath, version, logger)

	def GetVHDLCompiler(self):
		return XVhComp(self._platform, self._binaryDirectoryPath, self._version, logger=self._logger)

	def GetElaborator(self):
		return XElab(self._platform, self._binaryDirectoryPath, self._version, logger=self._logger)

	def GetSimulator(self):
		return XSim(self._platform, self._binaryDirectoryPath, self._version, logger=self._logger)

class XVhComp(Executable, VivadoSimMixIn):
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		VivadoSimMixIn.__init__(self, platform, binaryDirectoryPath, version, logger)

		if (self._platform == "Windows"):		executablePath = binaryDirectoryPath / "xvhcomp.bat"
		elif (self._platform == "Linux"):		executablePath = binaryDirectoryPath / "xvhcomp"
		else:																						raise PlatformNotSupportedException(self._platform)
		super().__init__(platform, executablePath, logger=logger)



	def Compile(self, vhdlFile):
		parameterList = self.Parameters.ToArgumentList()

		self._LogVerbose("    command: {0}".format(" ".join(parameterList)))

		_indent = "    "
		print(_indent + "xvhcomp messages for '{0}.{1}'".format("??????"))  # self.VHDLLibrary, topLevel))
		print(_indent + "-" * 80)
		try:
			self.StartProcess(parameterList)
			for line in self.GetReader():
				print(_indent + line)
		except Exception as ex:
			raise ex  # SimulatorException() from ex
		print(_indent + "-" * 80)


class XElab(Executable, VivadoSimMixIn):
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		VivadoSimMixIn.__init__(self, platform, binaryDirectoryPath, version, logger)

		if (self._platform == "Windows"):		executablePath = binaryDirectoryPath / "xelab.bat"
		elif (self._platform == "Linux"):		executablePath = binaryDirectoryPath / "xelab"
		else:																						raise PlatformNotSupportedException(self._platform)
		super().__init__(platform, executablePath, logger=logger)

		self.Parameters[self.Executable] = executablePath

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

	class SwitchSnapshot(metaclass=StringArgument):
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

		self._LogVerbose("    command: {0}".format(" ".join(parameterList)))

		_indent = "    "
		print(_indent + "xelab messages for '{0}'".format(self.Parameters[self.ArgTopLevel]))
		print(_indent + "-" * 80)
		try:
			self.StartProcess(parameterList)
			for line in self.GetReader():
				print(_indent + line)
		except Exception as ex:
			raise ex  # SimulatorException() from ex
		print(_indent + "-" * 80)


class XSim(Executable, VivadoSimMixIn):
	def __init__(self, platform, binaryDirectoryPath, version, logger=None):
		VivadoSimMixIn.__init__(self, platform, binaryDirectoryPath, version, logger)

		if (self._platform == "Windows"):		executablePath = binaryDirectoryPath / "xsim.bat"
		elif (self._platform == "Linux"):		executablePath = binaryDirectoryPath / "xsim"
		else:																						raise PlatformNotSupportedException(self._platform)
		super().__init__(platform, executablePath, logger=logger)

		self.Parameters[self.Executable] = executablePath

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

		self._LogVerbose("    command: {0}".format(" ".join(parameterList)))

		_indent = "    "
		print(_indent + "xsim messages for '{0}'".format(self.Parameters[self.SwitchSnapshot]))
		print(_indent + "-" * 80)
		try:
			self.StartProcess(parameterList)
			for line in self.GetReader():
				print(_indent + line)
		except Exception as ex:
			raise ex  # SimulatorException() from ex
		print(_indent + "-" * 80)

