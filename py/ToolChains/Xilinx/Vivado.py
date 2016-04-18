# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:					Patrick Lehmann
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
from pathlib							import Path
from os										import environ

from Base.Exceptions			import PlatformNotSupportedException
from Base.Logging					import LogEntry, Severity
from Base.Configuration 	import Configuration as BaseConfiguration, ConfigurationException, SkipConfigurationException
from Base.Project					import Project as BaseProject, ProjectFile, ConstraintFile, FileTypes
from Base.Executable			import Executable
from Base.Executable			import ExecutableArgument, ShortFlagArgument, ShortValuedFlagArgument, ShortTupleArgument, StringArgument, CommandLineArgumentList
from ToolChains.Xilinx.Xilinx		import XilinxException


class VivadoException(XilinxException):
	pass

class Configuration(BaseConfiguration):
	_vendor =		"Xilinx"
	_shortName =	"Vivado"
	_longName =	"Xilinx Vivado"
	_privateConfiguration = {
		"Windows": {
			"INSTALL.Xilinx.Vivado": {
				"Version":								"2015.4",
				"InstallationDirectory":	"${INSTALL.Xilinx:InstallationDirectory}/Vivado/${Version}",
				"BinaryDirectory":				"${InstallationDirectory}/bin"
			}
		},
		"Linux": {
			"INSTALL.Xilinx.Vivado": {
				"Version":								"2015.4",
				"InstallationDirectory":	"${INSTALL.Xilinx:InstallationDirectory}/Vivado/${Version}",
				"BinaryDirectory":				"${InstallationDirectory}/bin"
			}
		}
	}

	def __init__(self, host):
		super().__init__(host)

	def GetSections(self, Platform):
		pass

	def ConfigureForWindows(self):
		xilinxVivadoPath = self.__GetXilinxVivadoPath()
		if (xilinxVivadoPath is not None):
			print("  Found a Xilinx Vivado installation directory.")
			xilinxVivadoPath = self.__ConfirmXilinxVivadoPath(xilinxVivadoPath)
			if (xilinxVivadoPath is None):
				xilinxVivadoPath = self.__AskXilinxVivadoPath()
		else:
			if (not self.__AskXilinxVivado()):
				self.__ClearXilinxVivadoSections()
			else:
				xilinxVivadoPath = self.__AskXilinxVivadoPath()
		if (not xilinxVivadoPath.exists()):    raise ConfigurationException(
			"Xilinx Vivado installation directory '{0}' does not exist.".format(xilinxVivadoPath))  from NotADirectoryError(xilinxVivadoPath)
		self.__WriteXilinxVivadoSection(xilinxVivadoPath)

	def __GetXilinxVivadoPath(self):
		xilinx = environ.get('XILINX_VIVADO')
		if (xilinx is not None):
			return Path(xilinx).parent
		# FIXME: use Xilinx path to improve the search
		if (self._host.Platform == "Linux"):
			p = Path("/opt/xilinx/Vivado/2015.4")
			if (p.exists()):    return p
			p = Path("/opt/Xilinx/Vivado/2015.4")
			if (p.exists()):    return p
		elif (self._host.Platform == "Windows"):
			for drive in "CDEFGH":
				p = Path(r"{0}:\Xilinx\Vivado\2015.4".format(drive))
				try:
					if (p.exists()):  return p
				except WindowsError:
					pass
		return None

	def __AskXilinxVivado(self):
		isXilinxVivado = input("  Is Xilinx Vivado installed on your system? [Y/n/p]: ")
		isXilinxVivado = isXilinxVivado if isXilinxVivado != "" else "Y"
		if (isXilinxVivado in ['p', 'P']):
			raise SkipConfigurationException()
		elif (isXilinxVivado in ['n', 'N']):
			return False
		elif (isXilinxVivado in ['y', 'Y']):
			return True
		else:
			raise ConfigurationException("Unsupported choice '{0}'".format(isXilinxVivado))

	def __AskXilinxVivadoPath(self):
		self._host.PoCConfig['INSTALL.Xilinx.Vivado']['Version'] =								self._privateConfiguration[self._host.Platform]['INSTALL.Xilinx.Vivado']['Version']
		self._host.PoCConfig['INSTALL.Xilinx.Vivado']['InstallationDirectory'] =	self._privateConfiguration[self._host.Platform]['INSTALL.Xilinx.Vivado']['InstallationDirectory']

		default = Path(self._privateConfiguration[self._host.Platform]['INSTALL.Xilinx.Vivado']['InstallationDirectory'])
		xilinxVivadoDirectory = input("  Xilinx Vivado installation directory [{0!s}]: ".format(default))
		if (xilinxVivadoDirectory != ""):
			return Path(xilinxVivadoDirectory)
		else:
			return default

	def __ConfirmXilinxVivadoPath(self, xilinxVivadoPath):
		# Ask for installed Xilinx Vivado
		isXilinxVivadoPath = input("  Is Xilinx Vivado installed in '{0!s}'? [Y/n/p]: ".format(xilinxVivadoPath))
		isXilinxVivadoPath = isXilinxVivadoPath if isXilinxVivadoPath != "" else "Y"
		if (isXilinxVivadoPath in ['p', 'P']):
			raise SkipConfigurationException()
		elif (isXilinxVivadoPath in ['n', 'N']):
			return None
		elif (isXilinxVivadoPath in ['y', 'Y']):
			return xilinxVivadoPath

	def __ClearXilinxVivadoSections(self):
		self._host.PoCConfig['INSTALL.Xilinx.Vivado'] = OrderedDict()

	def __WriteXilinxVivadoSection(self, xilinxVivadoPath):
		version = self._privateConfiguration[self._host.Platform]['INSTALL.Xilinx.Vivado']['Version']
		for p in xilinxVivadoPath.parts:
			sp = p.split(".")
			if (len(sp) == 2):
				if ((12 <= int(sp[0]) <= 14) and (int(sp[1]) <= 7)):
					version = p
					break

		self._host.PoCConfig['INSTALL.Xilinx.Vivado']['Version'] = version
		self._host.PoCConfig['INSTALL.Xilinx.Vivado']['InstallationDirectory'] = self._privateConfiguration[self._host.Platform]['INSTALL.Xilinx.Vivado']['InstallationDirectory']
		defaultPath = self._host.PoCConfig['INSTALL.Xilinx.Vivado']['InstallationDirectory']

		if (xilinxVivadoPath.as_posix() == defaultPath):
			self._host.PoCConfig['INSTALL.Xilinx.Vivado']['InstallationDirectory'] = self._privateConfiguration[self._host.Platform]['INSTALL.Xilinx.Vivado'][
				'InstallationDirectory']
		else:
			self._host.PoCConfig['INSTALL.Xilinx.Vivado']['InstallationDirectory'] = xilinxVivadoPath.as_posix()

		self._host.PoCConfig['INSTALL.Xilinx.Vivado']['BinaryDirectory'] = self._privateConfiguration[self._host.Platform]['INSTALL.Xilinx.Vivado']['BinaryDirectory']

	# def manualConfigureForWindows(self) :
	# 	# Ask for installed Xilinx Vivado
	# 	isXilinxVivado = input('Is Xilinx Vivado installed on your system? [Y/n/p]: ')
	# 	isXilinxVivado = isXilinxVivado if isXilinxVivado != "" else "Y"
	# 	if (isXilinxVivado in ['p', 'P']) :
	# 		pass
	# 	elif (isXilinxVivado in ['n', 'N']) :
	# 		self.pocConfig['Xilinx.Vivado'] = OrderedDict()
	# 	elif (isXilinxVivado in ['y', 'Y']) :
	# 		xilinxDirectory = input('Xilinx installation directory [C:\Xilinx]: ')
	# 		vivadoVersion = input('Xilinx Vivado version number [2015.2]: ')
	# 		print()
	#
	# 		xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "C:\Xilinx"
	# 		vivadoVersion = vivadoVersion if vivadoVersion != "" else "2015.2"
	#
	# 		xilinxDirectoryPath = Path(xilinxDirectory)
	# 		vivadoDirectoryPath = xilinxDirectoryPath / "Vivado" / vivadoVersion
	#
	# 		if not xilinxDirectoryPath.exists() :  raise BaseException(
	# 			"Xilinx installation directory '%s' does not exist." % xilinxDirectory)
	# 		if not vivadoDirectoryPath.exists() :  raise BaseException(
	# 			"Xilinx Vivado version '%s' is not installed." % vivadoVersion)
	#
	# 		self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
	# 		self.pocConfig['Xilinx.Vivado']['Version'] = vivadoVersion
	# 		self.pocConfig['Xilinx.Vivado']['InstallationDirectory'] = '${Xilinx:InstallationDirectory}/Vivado/${Version}'
	# 		self.pocConfig['Xilinx.Vivado']['BinaryDirectory'] = '${InstallationDirectory}/bin'
	# 	else :
	# 		raise BaseException("unknown option")
	#
	#
	# def manualConfigureForLinuxo(self) :
	# 	# Ask for installed Xilinx Vivado
	# 	isXilinxVivado = input('Is Xilinx Vivado installed on your system? [Y/n/p]: ')
	# 	isXilinxVivado = isXilinxVivado if isXilinxVivado != "" else "Y"
	# 	if (isXilinxVivado in ['p', 'P']) :
	# 		pass
	# 	elif (isXilinxVivado in ['n', 'N']) :
	# 		self.pocConfig['Xilinx.Vivado'] = OrderedDict()
	# 	elif (isXilinxVivado in ['y', 'Y']) :
	# 		xilinxDirectory = input('Xilinx installation directory [/opt/Xilinx]: ')
	# 		vivadoVersion = input('Xilinx Vivado version number [2015.2]: ')
	# 		print()
	#
	# 		xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "/opt/Xilinx"
	# 		vivadoVersion = vivadoVersion if vivadoVersion != "" else "2015.2"
	#
	# 		xilinxDirectoryPath = Path(xilinxDirectory)
	# 		vivadoDirectoryPath = xilinxDirectoryPath / "Vivado" / vivadoVersion
	#
	# 		if not xilinxDirectoryPath.exists() :  raise BaseException(
	# 			"Xilinx installation directory '%s' does not exist." % xilinxDirectory)
	# 		if not vivadoDirectoryPath.exists() :  raise BaseException(
	# 			"Xilinx Vivado version '%s' is not installed." % vivadoVersion)
	#
	# 		self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
	# 		self.pocConfig['Xilinx.Vivado']['Version'] = vivadoVersion
	# 		self.pocConfig['Xilinx.Vivado']['InstallationDirectory'] = '${Xilinx:InstallationDirectory}/Vivado/${Version}'
	# 		self.pocConfig['Xilinx.Vivado']['BinaryDirectory'] = '${InstallationDirectory}/bin'
	# 	else :
	# 		raise BaseException("unknown option")

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
		self._LogVerbose("    command: {0}".format(" ".join(parameterList)))

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

				line.Indent(2)
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
		self._LogVerbose("    command: {0}".format(" ".join(parameterList)))

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

				line.Indent(2)
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
		self._LogVerbose("    command: {0}".format(" ".join(parameterList)))

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise VivadoException("Failed to launch xsim.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		try:
			iterator = iter(SimulatorFilter(self.GetReader()))

			line = next(iterator)
			self._hasOutput = True
			self._LogNormal("    xsim messages for '{0}'".format(self.Parameters[self.SwitchSnapshot]))
			self._LogNormal("    " + ("-" * 76))

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line.Indent(2)
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

