# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:					Patrick Lehmann
#
# Python Class:			GHDL specific classes
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
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module ToolChains.GHDL")

from collections						import OrderedDict
from pathlib								import Path
from re											import compile as re_compile

from Base.Exceptions				import PlatformNotSupportedException
from Base.ToolChain import ToolChainException
from Base.Configuration			import Configuration as BaseConfiguration, ConfigurationException
from Base.Executable				import Executable, \
																		ExecutableArgument, PathArgument, StringArgument, ValuedFlagListArgument, \
																		ShortFlagArgument, LongFlagArgument, ShortValuedFlagArgument, CommandLineArgumentList
from Base.Logging						import LogEntry, Severity
from Base.Simulator					import SimulatorException


class GHDLException(ToolChainException):
	pass

class GHDLReanalyzeException(GHDLException):
	pass

class Configuration(BaseConfiguration):
	_vendor =		None
	_shortName = "GTKWave"
	_longName =	"GTKWave"
	_privateConfiguration = {
		"Windows": {
			"GHDL": {
				"Version":								"0.34dev",
				"InstallationDirectory":	None,
				"BinaryDirectory":				"${InstallationDirectory}/bin",
				"Backend":								"mcode"
			}
		},
		"Linux": {
			"GHDL": {
				"Version":								"0.34dev",
				"InstallationDirectory":	None,
				"BinaryDirectory":				"${InstallationDirectory}",
				"Backend":								"llvm"
			}
		}
	}

	def GetSections(self, Platform):
		pass

	def ConfigureForWindows(self):
		return

	def manualConfigureForWindows(self):
		# Ask for installed GHDL
		isGHDL = input('Is GHDL installed on your system? [Y/n/p]: ')
		isGHDL = isGHDL if isGHDL != "" else "Y"
		if (isGHDL  in ['p', 'P']):
			pass
		elif (isGHDL in ['n', 'N']):
			self.pocConfig['GHDL'] = OrderedDict()
		elif (isGHDL in ['y', 'Y']):
			ghdlDirectory =	input('GHDL installation directory [C:\Program Files (x86)\GHDL]: ')
			ghdlVersion =		input('GHDL version number [0.31]: ')
			print()

			ghdlDirectory = ghdlDirectory if ghdlDirectory != "" else "C:\Program Files (x86)\GHDL"
			ghdlVersion = ghdlVersion if ghdlVersion != "" else "0.31"

			ghdlDirectoryPath = Path(ghdlDirectory)
			ghdlExecutablePath = ghdlDirectoryPath / "bin" / "ghdl.exe"

			if not ghdlDirectoryPath.exists():	raise ConfigurationException("GHDL installation directory '%s' does not exist." % ghdlDirectory)
			if not ghdlExecutablePath.exists():	raise ConfigurationException("GHDL is not installed.")

			self.pocConfig['GHDL']['Version'] = ghdlVersion
			self.pocConfig['GHDL']['InstallationDirectory'] = ghdlDirectoryPath.as_posix()
			self.pocConfig['GHDL']['BinaryDirectory'] = '${InstallationDirectory}/bin'
			self.pocConfig['GHDL']['Backend'] = 'mcode'
		else:
			raise ConfigurationException("unknown option")

	def manualConfigureForLinux(self):
		# Ask for installed GHDL
		isGHDL = input('Is GHDL installed on your system? [Y/n/p]: ')
		isGHDL = isGHDL if isGHDL != "" else "Y"
		if (isGHDL  in ['p', 'P']):
			pass
		elif (isGHDL in ['n', 'N']):
			self.pocConfig['GHDL'] = OrderedDict()
		elif (isGHDL in ['y', 'Y']):
			ghdlDirectory =	input('GHDL installation directory [/usr/bin]: ')
			ghdlVersion =		input('GHDL version number [0.31]: ')
			print()

			ghdlDirectory = ghdlDirectory if ghdlDirectory != "" else "/usr/bin"
			ghdlVersion = ghdlVersion if ghdlVersion != "" else "0.31"

			ghdlDirectoryPath = Path(ghdlDirectory)
			ghdlExecutablePath = ghdlDirectoryPath / "ghdl"

			if not ghdlDirectoryPath.exists():	raise ConfigurationException("GHDL installation directory '%s' does not exist." % ghdlDirectory)
			if not ghdlExecutablePath.exists():	raise ConfigurationException("GHDL is not installed.")

			self.pocConfig['GHDL']['Version'] = ghdlVersion
			self.pocConfig['GHDL']['InstallationDirectory'] = ghdlDirectoryPath.as_posix()
			self.pocConfig['GHDL']['BinaryDirectory'] = '${InstallationDirectory}'
			self.pocConfig['GHDL']['Backend'] = 'llvm'
		else:
			raise ConfigurationException("unknown option")


class GHDL(Executable):
	def __init__(self, platform, binaryDirectoryPath, version, backend, logger=None):
		if (platform == "Windows"):			executablePath = binaryDirectoryPath/ "ghdl.exe"
		elif (platform == "Linux"):			executablePath = binaryDirectoryPath/ "ghdl"
		else:																						raise PlatformNotSupportedException(platform)
		super().__init__(platform, executablePath, logger=logger)

		self.Executable = executablePath
		#self.Parameters[self.Executable] = executablePath

		if (platform == "Windows"):
			if (backend not in ["mcode"]):								raise SimulatorException("GHDL for Windows does not support backend '{0}'.".format(backend))
		elif (platform == "Linux"):
			if (backend not in ["gcc", "llvm", "mcode"]):	raise SimulatorException("GHDL for Linux does not support backend '{0}'.".format(backend))

		self._binaryDirectoryPath =	binaryDirectoryPath
		self._backend =							backend
		self._version =							version

		self._hasOutput =						False
		self._hasWarnings =					False
		self._hasErrors =						False

	@property
	def BinaryDirectoryPath(self):
		return self._binaryDirectoryPath

	@property
	def Backend(self):
		return self._backend

	@property
	def Version(self):
		return self._version

	@property
	def HasWarnings(self):
		return self._hasWarnings

	@property
	def HasErrors(self):
		return self._hasErrors

	def deco(Arg):
		def getter(self):
			return Arg.Value
		def setter(self, value):
			Arg.Value = value
		return property(getter, setter)

	Executable = deco(ExecutableArgument("Executable", (), {}))

	#class Executable(metaclass=ExecutableArgument):
	#	pass

	class CmdAnalyze(metaclass=ShortFlagArgument):
		_name =		"a"

	class CmdElaborate(metaclass=ShortFlagArgument):
		_name =		"e"

	class CmdRun(metaclass=ShortFlagArgument):
		_name =		"r"

	class FlagVerbose(metaclass=ShortFlagArgument):
		_name =		"v"

	class FlagExplicit(metaclass=ShortFlagArgument):
		_name =		"fexplicit"

	class FlagRelaxedRules(metaclass=ShortFlagArgument):
		_name =		"frelaxed-rules"

	class FlagWarnBinding(metaclass=LongFlagArgument):
		_name =		"warn-binding"

	class FlagNoVitalChecks(metaclass=LongFlagArgument):
		_name =		"no-vital-checks"

	class FlagMultiByteComments(metaclass=LongFlagArgument):
		_name =		"mb-comments"

	class FlagSynBinding(metaclass=LongFlagArgument):
		_name =		"syn-binding"

	class FlagPSL(metaclass=ShortFlagArgument):
		_name =		"fpsl"

	class SwitchIEEEFlavor(metaclass=ShortValuedFlagArgument):
		_pattern =	"--{0}={1}"
		_name =			"ieee"

	class SwitchVHDLVersion(metaclass=ShortValuedFlagArgument):
		_pattern =	"--{0}={1}"
		_name =			"std"

	class SwitchVHDLLibrary(metaclass=ShortValuedFlagArgument):
		_pattern =	"--{0}={1}"
		_name =			"work"

	class ArgListLibraryReferences(metaclass=ValuedFlagListArgument):
		_pattern =	"-{0}{1}"
		_name =			"P"

	class ArgSourceFile(metaclass=PathArgument):
		pass

	class ArgTopLevel(metaclass=StringArgument):
		pass

	Parameters = CommandLineArgumentList(
		#Executable,
		CmdAnalyze,
		CmdElaborate,
		CmdRun,
		FlagVerbose,
		FlagExplicit,
		FlagRelaxedRules,
		FlagWarnBinding,
		FlagNoVitalChecks,
		FlagMultiByteComments,
		FlagSynBinding,
		FlagPSL,
		SwitchIEEEFlavor,
		SwitchVHDLVersion,
		SwitchVHDLLibrary,
		ArgListLibraryReferences,
		ArgSourceFile,
		ArgTopLevel
	)

	class SwitchIEEEAsserts(metaclass=ShortValuedFlagArgument):
		_pattern =	"--{0}={1}"
		_name =			"ieee-asserts"

	class SwitchVCDWaveform(metaclass=ShortValuedFlagArgument):
		_pattern =	"--{0}={1}"
		_name =			"vcd"

	class SwitchVCDGZWaveform(metaclass=ShortValuedFlagArgument):
		_pattern =	"--{0}={1}"
		_name =			"vcdgz"

	class SwitchFastWaveform(metaclass=ShortValuedFlagArgument):
		_pattern =	"--{0}={1}"
		_name =			"fst"

	class SwitchGHDLWaveform(metaclass=ShortValuedFlagArgument):
		_pattern =	"--{0}={1}"
		_name =			"wave"

	RunOptions = CommandLineArgumentList(
		SwitchIEEEAsserts,
		SwitchVCDWaveform,
		SwitchVCDGZWaveform,
		SwitchFastWaveform,
		SwitchGHDLWaveform
	)

	def GetGHDLAnalyze(self):
		ghdl = GHDLAnalyze(self._platform, self._binaryDirectoryPath, self._version, self._backend, logger=self.Logger)
		for param in ghdl.Parameters:
			if (param is not ghdl.Executable):
				ghdl.Parameters[param] = None
		ghdl.Parameters[ghdl.CmdAnalyze] = True
		return ghdl

	def GetGHDLElaborate(self):
		ghdl = GHDLElaborate(self._platform, self._binaryDirectoryPath, self._version, self._backend, logger=self.Logger)
		for param in ghdl.Parameters:
			if (param is not ghdl.Executable):
				ghdl.Parameters[param] = None
		ghdl.Parameters[ghdl.CmdElaborate] = True
		return ghdl

	def GetGHDLRun(self):
		ghdl = GHDLRun(self._platform, self._binaryDirectoryPath, self._version, self._backend, logger=self.Logger)
		for param in ghdl.Parameters:
			if (param is not ghdl.Executable):
				ghdl.Parameters[param] = None
		ghdl.Parameters[ghdl.CmdRun] =			True
		return ghdl


class GHDLAnalyze(GHDL):
	def __init__(self, platform, binaryDirectoryPath, version, backend, logger=None):
		super().__init__(platform, binaryDirectoryPath, version, backend, logger=logger)

	def Analyze(self):
		parameterList = self.Parameters.ToArgumentList()
		parameterList.insert(0, self.Executable)
		self._LogVerbose("    command: {0}".format(" ".join(parameterList)))

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise GHDLException("Failed to launch GHDL analyze.") from ex

		self._hasOutput =		False
		self._hasWarnings =	False
		self._hasErrors =		False
		try:
			filter =		GHDLAnalyzeFilter(self.GetReader())
			iterator =	iter(filter)

			line = next(iterator)
			self._hasOutput =		True
			self._LogNormal("    ghdl analyze messages for '{0}'".format(self.Parameters[self.ArgSourceFile]))
			self._LogNormal("    " + ("-" * 76))

			while True:
				self._hasWarnings |=	(line.Severity is Severity.Warning)
				self._hasErrors |=		(line.Severity is Severity.Error)

				line.Indent(2)
				self._Log(line)
				line = next(iterator)

		except StopIteration as ex:
			pass
		except GHDLException:
			raise
		#except Exception as ex:
		#	raise GHDLException("Error while executing GHDL.") from ex
		finally:
			if self._hasOutput:
				self._LogNormal("    " + ("-" * 76))

class GHDLElaborate(GHDL):
	def __init__(self, platform, binaryDirectoryPath, version, backend, logger=None):
		super().__init__(platform, binaryDirectoryPath, version, backend, logger=logger)

	def Elaborate(self):
		parameterList = self.Parameters.ToArgumentList()
		parameterList.insert(0, self.Executable)
		self._LogVerbose("    command: {0}".format(" ".join(parameterList)))

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise GHDLException("Failed to launch GHDL elaborate.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		try:
			filter = GHDLElaborateFilter(self.GetReader())
			iterator = iter(filter)

			line = next(iterator)
			line.Indent(2)
			self._hasOutput = True
			vhdlLibraryName = self.Parameters[self.SwitchVHDLLibrary]
			topLevel = self.Parameters[self.ArgTopLevel]
			self._LogNormal("    ghdl elaborate messages for '{0}.{1}'".format(vhdlLibraryName, topLevel))
			self._LogNormal("    " + ("-" * 76))
			self._Log(line)

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line = next(iterator)
				line.Indent(2)
				self._Log(line)

		except StopIteration as ex:
			pass
		except GHDLException:
			raise
		#except Exception as ex:
		#	raise GHDLException("Error while executing GHDL.") from ex
		finally:
			if self._hasOutput:
				self._LogNormal("    " + ("-" * 76))

class GHDLRun(GHDL):
	def __init__(self, platform, binaryDirectoryPath, version, backend, logger=None):
		super().__init__(platform, binaryDirectoryPath, version, backend, logger=logger)

	def Run(self):
		parameterList = self.Parameters.ToArgumentList()
		parameterList += self.RunOptions.ToArgumentList()
		parameterList.insert(0, self.Executable)

		self._LogVerbose("    command: {0}".format(" ".join(parameterList)))

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise GHDLException("Failed to launch GHDL run.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		try:
			filter = GHDLRunFilter(self.GetReader())
			iterator = iter(filter)

			line = next(iterator)
			line.Indent(2)
			self._hasOutput = True
			vhdlLibraryName =	self.Parameters[self.SwitchVHDLLibrary]
			topLevel =				self.Parameters[self.ArgTopLevel]
			self._LogNormal("    ghdl run messages for '{0}.{1}'".format(vhdlLibraryName, topLevel))
			self._LogNormal("    " + ("-" * 76))
			self._Log(line)

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line = next(iterator)
				line.Indent(2)
				self._Log(line)

		except StopIteration as ex:
			pass
		except GHDLException:
			raise
		#except Exception as ex:
		#	raise GHDLException("Error while executing GHDL.") from ex
		finally:
			if self._hasOutput:
				self._LogNormal("    " + ("-" * 76))


def GHDLAnalyzeFilter(gen):
	warningRegExpPattern =	r".+?:\d+:\d+:warning: (?P<Message>.*)"			# <Path>:<line>:<column>:warning: <message>
	errorRegExpPattern =		r".+?:\d+:\d+: (?P<Message>.*)"  						# <Path>:<line>:<column>: <message>

	warningRegExp =	re_compile(warningRegExpPattern)
	errorRegExp =		re_compile(errorRegExpPattern)

	for line in gen:
		warningRegExpMatch = warningRegExp.match(line)
		if (warningRegExpMatch is not None):
			yield LogEntry(line, Severity.Warning)
		else:
			errorRegExpMatch = errorRegExp.match(line)
			if (errorRegExpMatch is not None):
				message = errorRegExpMatch.group('Message')
				if message.endswith("has changed and must be reanalysed"):
					raise GHDLReanalyzeException(message)
				yield LogEntry(line, Severity.Error)
			else:
				yield LogEntry(line, Severity.Normal)

GHDLElaborateFilter = GHDLAnalyzeFilter

def GHDLRunFilter(gen):
	#warningRegExpPattern =	".+?:\d+:\d+:warning: .*"		# <Path>:<line>:<column>:warning: <message>
	#errorRegExpPattern =		".+?:\d+:\d+: .*"  					# <Path>:<line>:<column>: <message>

	#warningRegExp =	re_compile(warningRegExpPattern)
	#errorRegExp =		re_compile(errorRegExpPattern)

	lineno = 0
	for line in gen:
		if (lineno < 2):
			lineno += 1
			if ("Linking in memory" in line):
				yield LogEntry(line, Severity.Verbose)
			elif ("Starting simulation" in line):
				yield LogEntry(line, Severity.Verbose)
		else:
			yield LogEntry(line, Severity.Normal)
