# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#
# Python Class:     GNU tools specific classes
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
from pathlib                 import Path
from re                      import compile as re_compile

from lib.Functions           import Init, CallByRefParam
from Base.Exceptions         import PlatformNotSupportedException
from Base.Executable         import Executable, ExecutableArgument, CommandLineArgumentList, ValuedFlagArgument, ShortTupleArgument, Environment, DryRunException
from Base.Logging            import LogEntry, Severity
from DataBase.Entity         import SimulationResult
from ToolChain               import ToolChainException, OutputFilteredExecutable


__api__ = [
	'GNUException',
	'Make',
	'GNUMakeQuestaSimFilter',
	'CocotbSimulationResultFilter'
]
__all__ = __api__


class GNUException(ToolChainException):
	pass


class Make(OutputFilteredExecutable):
	def __init__(self, platform, dryrun, logger=None):
		if (platform == "Linux"):      executablePath = Path("/usr/bin/make")
		else:                          raise PlatformNotSupportedException(platform)
		super().__init__(platform, dryrun, executablePath, logger=logger)

		self.Parameters[self.Executable] = executablePath

	class Executable(metaclass=ExecutableArgument):
		pass

	class SwitchGui(metaclass=ValuedFlagArgument):
		_name = "GUI"

	Parameters = CommandLineArgumentList(
		Executable,
		SwitchGui
	)

	def RunCocotb(self):
		parameterList = self.Parameters.ToArgumentList()
		self.LogVerbose("command: {0}".format(" ".join(parameterList)))

		if (self._dryrun):
			self.LogDryRun("Start process: {0}".format(" ".join(parameterList)))
			return

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise GNUException("Failed to launch Make.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		simulationResult = CallByRefParam(SimulationResult.Error)
		try:
			iterator = iter(CocotbSimulationResultFilter(GNUMakeQuestaSimFilter(self.GetReader()), simulationResult))

			line = next(iterator)
			line.IndentBy(self.Logger.BaseIndent + 1)
			self._hasOutput = True
			self.LogNormal("  Make messages")
			self.LogNormal("  " + ("-" * (78 - self.Logger.BaseIndent*2)))
			self.Log(line)

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line = next(iterator)
				line.IndentBy(self.Logger.BaseIndent + 1)
				self.Log(line)

		except DryRunException:
			simulationResult <<= SimulationResult.DryRun
		except StopIteration:
			pass
		finally:
			if self._hasOutput:
				self.LogNormal("  " + ("-" * (78 - self.Logger.BaseIndent*2)))

		return simulationResult.value


class Bash(Executable):
	def __init__(self, platform, dryrun, logger=None):
		if (platform == "Linux"):     executablePath = Path("/bin/bash")
		else:	                        raise PlatformNotSupportedException(platform)
		super().__init__(platform, dryrun, executablePath, logger=logger)

		self.Parameters[self.Executable] = executablePath

	class Executable(metaclass=ExecutableArgument):
		pass

	class SwitchCommand(metaclass=ShortTupleArgument):
		_name = "c"

	Parameters = CommandLineArgumentList(
		Executable,
		SwitchCommand
	)

	def GetEnvironment(self, settingsFile=None, variables=""):
		if (settingsFile is None):
			self.Parameters[self.SwitchCommand] = "env"
		else:
			self.Parameters[self.SwitchCommand] = "{variables}source {settingsFile!s} && env".format(settingsFile=settingsFile, variables=variables)

		parameterList = self.Parameters.ToArgumentList()
		self.LogVerbose("command: {0}".format(" ".join(parameterList)))

		if (self._dryrun):
			self.LogDryRun("Start process: {0}".format(" ".join(parameterList)))
			return

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise GNUException("Failed to launch /bin/bash.") from ex

		env = Environment()
		iterator = iter(self.GetReader())
		for line in iterator:
			try:
				var,value = line.split("=", 1)
				env.Variables[var] = value
			except Exception as ex:
				raise GNUException("Error while reading output from /bin/bash.") from ex

		return env

def GNUMakeQuestaSimFilter(gen):
	for line in gen:
		if   line.startswith("# --"):       yield LogEntry(line, Severity.Verbose)
		elif line.startswith("# Loading"):  yield LogEntry(line, Severity.Verbose)
		elif line.startswith("# ** Note"):  yield LogEntry(line, Severity.Info)
		elif line.startswith("# ** Warn"):  yield LogEntry(line, Severity.Warning)
		elif line.startswith("# ** Erro"):  yield LogEntry(line, Severity.Error)
		elif line.startswith("# ** Fata"):  yield LogEntry(line, Severity.Error)
		elif line.startswith("# //"):       continue
		else:                                yield LogEntry(line, Severity.Normal)

# Could not be moved to CocotbSimulator. Function could not be imported. (Why?)
def CocotbSimulationResultFilter(gen, simulationResult):
	passedRegExpStr = r".*?in tear_down\s+Passed \d+ tests"  # Source filename
	passedRegExp = re_compile(passedRegExpStr)
	failedRegExpStr = r".*?in tear_down\s+Failed \d+ out of \d+ tests"  # Source filename
	failedRegExp = re_compile(failedRegExpStr)

	for line in gen:
		color = None
		passedRegExpMatch = passedRegExp.match(str(line))
		failedRegExpMatch = failedRegExp.match(str(line))
		if passedRegExpMatch is not None:
			color = Init.Foreground['GREEN']
			simulationResult <<= SimulationResult.Passed
		elif failedRegExpMatch is not None:
			color = Init.Foreground['RED']
			simulationResult <<= SimulationResult.Failed

		# color is set when message should be printed
		if color is not None:
			yield LogEntry("{COLOR}{line}{NOCOLOR}".format(COLOR=color, line=line.Message, **Init.Foreground), line.Severity,
									line.Indent)
			continue

		yield line
