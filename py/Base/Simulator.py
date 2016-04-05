# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
# Authors:				 	Patrick Lehmann
# 
# Python Class:			TODO
# 
# Description:
# ------------------------------------
#		TODO:
#		- 
#		- 
#
# License:
# ==============================================================================
# Copyright 2007-2015 Technische Universitaet Dresden - Germany
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
from lib.Functions import Exit
if __name__ != "__main__":
	pass
	# place library initialization code here
else:
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module Simulator.Base")

# load dependencies
from enum							import Enum, unique

from Base.Exceptions	import *
from Base.Logging			import ILogable


VHDLTestbenchLibraryName = "test"


@unique
class SimulationResult(Enum):
	Failed = 0
	NoAsserts = 1
	Passed = 2


class Simulator(ILogable):
	def __init__(self, host, showLogs, showReport):
		if isinstance(host, ILogable):
			ILogable.__init__(self, host.Logger)
		else:
			ILogable.__init__(self, None)

		self.__host =				host
		self.__showLogs =		showLogs
		self.__showReport =	showReport

	# class properties
	# ============================================================================
	@property
	def Host(self):
		return self.__host

	@property
	def ShowLogs(self):
		return self.__showLogs

	@property
	def ShowReport(self):
		return self.__showReport

	def CheckSimulatorOutput(self, simulatorOutput):
		matchPos = simulatorOutput.find("SIMULATION RESULT = ")
		if (matchPos >= 0):
			if (simulatorOutput[matchPos + 20: matchPos + 26] == "PASSED"):
				return SimulationResult.Passed
			elif (simulatorOutput[matchPos + 20: matchPos + 26] == "FAILED"):
				return SimulationResult.Failed
			elif (simulatorOutput[matchPos + 20: matchPos + 30] == "NO ASSERTS"):
				return SimulationResult.NoAsserts
		raise SimulatorException("String 'SIMULATION RESULT ...' not found in simulator output.")
