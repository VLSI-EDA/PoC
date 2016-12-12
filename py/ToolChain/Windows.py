# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#
# Python Class:     Windows tools specific classes
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
from pathlib import Path

from Base.Exceptions         import PlatformNotSupportedException
from Base.Executable         import Executable, ExecutableArgument, CommandLineArgumentList, WindowsTupleArgument, Environment
from ToolChain               import Environment, ToolChainException #, OutputFilteredExecutable


__api__ = [
	'WindowsException',
	'Cmd'
]
__all__ = __api__


class WindowsException(ToolChainException):
	pass


class Cmd(Executable):
	def __init__(self, platform, dryrun, logger=None):
		if (platform == "Windows"):    executablePath = Path("C:\Windows\System32\cmd.exe")
		else:                          raise PlatformNotSupportedException(platform)
		super().__init__(platform, dryrun, executablePath, logger=logger)

		self.Parameters[self.Executable] = executablePath

	class Executable(metaclass=ExecutableArgument):
		pass

	class SwitchCommand(metaclass=WindowsTupleArgument):
		_name = "C"

	Parameters = CommandLineArgumentList(
		Executable,
		SwitchCommand
	)

	def GetEnvironment(self, settingsFile=None):
		if (settingsFile is None):
			self.Parameters[self.SwitchCommand] = "set"
		else:
			self.Parameters[self.SwitchCommand] = "{settingsFile!s} && set".format(settingsFile=settingsFile)

		parameterList = self.Parameters.ToArgumentList()
		self.LogVerbose("command: {0}".format(" ".join(parameterList)))

		if (self._dryrun):
			self.LogDryRun("Start process: {0}".format(" ".join(parameterList)))
			return

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise WindowsException("Failed to launch cmd.exe.") from ex

		env = Environment()
		iterator = iter(self.GetReader())
		for line in iterator:
			try:
				var,value = line.split("=", 1)
				env.Variables[var] = value
			except Exception as ex:
				raise WindowsException("Error while reading output from cmd.exe.") from ex

		return env
