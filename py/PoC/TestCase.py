# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#
# Python Class:     TODO
#
# Description:
# ------------------------------------
#		TODO:
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
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module PoC.Query")


from collections  import OrderedDict
from datetime     import datetime
from enum         import Enum, unique


@unique
class Status(Enum):
	Unknown =              0
	SystemError =          1
	InternalError =        2
	AnalyzeError =         3
	ElaborationError =     4
	SimulationError =      5
	SimulationFailed =    10
	SimulationNoAsserts = 15
	SimulationSuccess =   20


class TestElement:
	def __init__(self, name, parent):
		self._name =     name
		self._parent =   parent

	@property
	def Name(self):       return self._name
	@property
	def Parent(self):     return self._parent

	def __str__(self):
		return "{0!s}.{1}".format(self._parent, self._name)

class TestGroup(TestElement):
	def __init__(self, name, parent):
		super().__init__(name, parent)

		self._parent =     None
		self._testGroups = OrderedDict()
		self._testCases =  OrderedDict()

	def __getitem__(self, item):
		try:
			return self._testCases[item]
		except KeyError:
			return self._testGroups[item]

	def __setitem__(self, key, value):
		if isinstance(value, TestGroup):
			self._testGroups[key] = value
		elif isinstance(value, TestCase):
			self._testCases[key] = value
		else:
			raise ValueError("Parameter 'value' is not of type TestGroup or TestCase")

	def __len__(self):
		return sum([len(group) for group in self._testGroups.values()]) + len(self._testCases)

	@property
	def TestGroups(self): return self._testGroups
	@property
	def TestCases(self):  return self._testCases

	@property
	def Count(self):
		return len(self)

	@property
	def PassedCount(self):
		return sum([tg.PassedCount for tg in self._testGroups.values()]) \
						+ sum([1 for tc in self._testCases.values() if tc.Status is Status.SimulationSuccess])

	@property
	def NoAssertsCount(self):
		return sum([tg.NoAssertsCount for tg in self._testGroups.values()]) \
						+ sum([1 for tc in self._testCases.values() if tc.Status is Status.SimulationNoAsserts])

	@property
	def FailedCount(self):
		return sum([tg.FailedCount for tg in self._testGroups.values()]) \
						+ sum([1 for tc in self._testCases.values() if tc.Status is Status.SimulationFailed])

	@property
	def ErrorCount(self):
		return sum([tg.ErrorCount for tg in self._testGroups.values()]) \
						+ sum([1 for tc in self._testCases.values() if tc.Status
										in (Status.SystemError, Status.AnalyzeError, Status.ElaborationError, Status.SimulationError)])


class TestSuite(TestGroup):
	def __init__(self):
		super().__init__("PoC", None)

		self._startedAt =      datetime.now()
		self._endedAt =        None
		self._initRuntime =    None
		self._overallRuntime = None

	def __str__(self):
		return self._name

	@property
	def IsAllPassed(self):
		return (self.Count == self.PassedCount + self.NoAssertsCount)

	def AddTestCase(self, testCase):
		cur = self
		testbenchPath = testCase.Testbench.Path
		for item in testbenchPath[:-2]:
			try:
				testGroup = cur[item.Name]
			except KeyError:
				testGroup = TestGroup(item.Name, cur)
				cur[item.Name] = testGroup
			cur = testGroup

		testCaseName = testbenchPath[-2].Name
		cur[testCaseName] = testCase

	def StartTimer(self):
		now = datetime.now()
		self.__initRuntime = now - self._startedAt
		self._startedAt =    now

	def StopTimer(self):
		self._endedAt = datetime.now()
		self._overallRuntime = self._endedAt - self._startedAt

	@property
	def StartTime(self):          return self._startedAt
	@property
	def EndTime(self):            return self._endedAt
	@property
	def InitializationTime(self): return self._initRuntime.microseconds
	@property
	def OverallRunTime(self):     return self._overallRuntime.seconds


class TestCase(TestElement):
	def __init__(self, testbench):
		super().__init__(testbench.Parent.Name, None)
		self._testbench =        testbench
		self._testGroup =        None
		self._status =          Status.Unknown
		self._warnings =        []
		self._errors =          []

		self._startedAt =        None
		self._endedAt =          None
		self._overallRuntime =  None

	@property
	def Parent(self):           return self._parent
	@Parent.setter
	def Parent(self, value):    self._parent = value

	@property
	def Testbench(self):        return self._testbench

	@property
	def TestGroup(self):        return self._testGroup
	@TestGroup.setter
	def TestGroup(self, value): self._testGroup = value

	@property
	def Status(self):           return self._status
	@Status.setter
	def Status(self, value):    self._status = value

	def UpdateStatus(self, testbenchResult):
		if (testbenchResult is testbenchResult.NotRun):
			self._status = Status.Unknown
		elif (testbenchResult is testbenchResult.Error):
			self._status = Status.SimulationError
		elif (testbenchResult is testbenchResult.Failed):
			self._status = Status.SimulationFailed
		elif (testbenchResult is testbenchResult.NoAsserts):
			self._status = Status.SimulationNoAsserts
		elif (testbenchResult is testbenchResult.Passed):
			self._status = Status.SimulationSuccess
		else:
			raise IndentationError("Wuhu")

	def StartTimer(self):
		self._startedAt =        datetime.now()

	def StopTimer(self):
		self._endedAt =          datetime.now()
		self._overallRuntime =  self._endedAt - self._startedAt

	@property
	def OverallRunTime(self): return self._overallRuntime.seconds
