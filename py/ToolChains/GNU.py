# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:					Patrick Lehmann
#                   Martin Zabel
#
# Python Class:			GNU tools specific classes
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
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module ToolChains.GNU")

from Base.Configuration			import Configuration as BaseConfiguration
from Base.Exceptions				import PlatformNotSupportedException
from Base.Executable				import Executable, ExecutableArgument, CommandLineArgumentList, ValuedFlagArgument
from Base.Logging						import LogEntry, Severity
from Base.ToolChain					import ToolChainException


class GNUException(ToolChainException):
	pass


class Configuration(BaseConfiguration):
	_vendor =			"GNU"
	_toolName =		"GNU Make"
	_section = 		None

	def CheckDependency(self):
		return False


class Make(Executable):
	def __init__(self, platform, logger=None):
		if (platform == "Linux"):			executablePath = "/usr/bin/make"
		else:													raise PlatformNotSupportedException(self._platform)
		super().__init__(platform, executablePath, logger=logger)

		self.Parameters[self.Executable] = executablePath

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False

	class Executable(metaclass=ExecutableArgument):
		pass

	class SwitchGui(metaclass=ValuedFlagArgument):
		_name = "GUI"

	Parameters = CommandLineArgumentList(
		Executable,
		SwitchGui
	)

	def Run(self):
		parameterList = self.Parameters.ToArgumentList()
		self._LogVerbose("command: {0}".format(" ".join(parameterList)))

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise GNUException("Failed to launch Make.") from ex

		self._hasOutput = False
		self._hasWarnings = False
		self._hasErrors = False
		try:
			iterator = iter(GNUMakeFilter(self.GetReader()))

			line = next(iterator)
			line.IndentBy(2)
			self._hasOutput = True
			self._LogNormal("    Make messages")
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


# TODO: this is a QuestaSim specific filter. Add support to specify a user-defined filter for Make
def GNUMakeFilter(gen):
	for line in gen:
		if   line.startswith("# --"): 			yield LogEntry(line, Severity.Verbose)
		elif line.startswith("# Loading"):	yield LogEntry(line, Severity.Verbose)
		elif line.startswith("# ** Note"):	yield LogEntry(line, Severity.Info)
		elif line.startswith("# ** Warn"):	yield LogEntry(line, Severity.Warning)
		elif line.startswith("# ** Erro"):	yield LogEntry(line, Severity.Error)
		elif line.startswith("# ** Fata"):	yield LogEntry(line, Severity.Error)
		elif line.startswith("# //"): 			continue
		else:																yield LogEntry(line, Severity.Normal)
