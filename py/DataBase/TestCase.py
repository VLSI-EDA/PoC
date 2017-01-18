# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#
# Python Class:     TODO
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
#
# load dependencies
from collections      import OrderedDict
from datetime         import datetime
from enum             import Enum, unique


__api__ = [
	'SimulationStatus', 'CompileStatus',
	'ElementBase',
	'GroupBase', 'TestGroup', 'SynthesisGroup',
	'SuiteMixIn', 'TestSuite', 'SynthesisSuite',
	'TestBase', 'TestCase', 'Synthesis'
]
__all__ = __api__


@unique
class SimulationStatus(Enum):
	Unknown =              0
	DryRun =               1
	SystemError =          5
	InternalError =        6
	AnalyzeError =         7
	ElaborationError =     8
	SimulationError =      9
	SimulationFailed =    10
	SimulationNoAsserts = 15
	SimulationSuccess =   20
	SimulationGUIRun =    30

@unique
class CompileStatus(Enum):
	Unknown =              0
	DryRun =               1
	SystemError =          5
	InternalError =        6
	CompileError =         7
	CompileFailed =       10
	CompileSuccess =      20


class ElementBase:
	def __init__(self, name, parent):
		self._name =     name
		self._parent =   parent

	@property
	def Name(self):       return self._name
	@property
	def Parent(self):     return self._parent

	def __str__(self):
		return "{0!s}.{1}".format(self._parent, self._name)


class GroupBase(ElementBase):
	def __init__(self, name, parent):
		super().__init__(name, parent)

		self._groups =      OrderedDict()
		self._tests =       OrderedDict()

	def __getitem__(self, item):
		try:                return self._tests[item]
		except KeyError:    return self._groups[item]

	def __len__(self):
		return sum([len(group) for group in self._groups.values()]) + len(self._tests)

	@property
	def Groups(self):     return self._groups
	@property
	def Count(self):      return len(self)


class TestGroup(GroupBase):
	def __setitem__(self, key, value):
		if isinstance(value, TestGroup):    self._groups[key] = value
		elif isinstance(value, TestCase):   self._tests[key] =  value
		else:                               raise ValueError("Parameter 'value' is not of type TestGroup or TestCase")

	@property
	def TestCases(self):      return self._tests

	@property
	def PassedCount(self):
		return sum([tg.PassedCount for tg in self._groups.values()]) \
						+ sum([1 for tc in self._tests.values() if tc.Status is SimulationStatus.SimulationSuccess])

	@property
	def NoAssertsCount(self):
		return sum([tg.NoAssertsCount for tg in self._groups.values()]) \
						+ sum([1 for tc in self._tests.values() if tc.Status is SimulationStatus.SimulationNoAsserts])

	@property
	def DryRunCount(self):
		return sum([tg.DryRunCount for tg in self._groups.values()]) \
						+ sum([1 for tc in self._tests.values() if tc.Status is SimulationStatus.DryRun])

	@property
	def FailedCount(self):
		return sum([tg.FailedCount for tg in self._groups.values()]) \
						+ sum([1 for tc in self._tests.values() if tc.Status is SimulationStatus.SimulationFailed])

	@property
	def ErrorCount(self):
		errors = (SimulationStatus.SystemError, SimulationStatus.InternalError, SimulationStatus.AnalyzeError, SimulationStatus.ElaborationError, SimulationStatus.SimulationError)
		return sum([tg.ErrorCount for tg in self._groups.values()]) \
						+ sum([1 for tc in self._tests.values() if tc.Status in errors])


class SynthesisGroup(GroupBase):
	def __setitem__(self, key, value):
		if isinstance(value, SynthesisGroup): self._groups[key] = value
		elif isinstance(value, Synthesis):    self._tests[key] =  value
		else:                                 raise ValueError("Parameter 'value' is not of type SynthesisGroup or Synthesis")

	@property
	def Synthesises(self):    return self._tests

	@property
	def SuccessCount(self):
		return sum([tg.SuccessCount for tg in self._groups.values()]) \
						+ sum([1 for tc in self._tests.values() if tc.Status is CompileStatus.CompileSuccess])

	@property
	def DryRunCount(self):
		return sum([tg.DryRunCount for tg in self._groups.values()]) \
						+ sum([1 for tc in self._tests.values() if tc.Status is CompileStatus.DryRun])

	@property
	def FailedCount(self):
		return sum([tg.FailedCount for tg in self._groups.values()]) \
						+ sum([1 for tc in self._tests.values() if tc.Status is CompileStatus.CompileFailed])

	@property
	def ErrorCount(self):
		errors = (CompileStatus.SystemError, CompileStatus.InternalError, CompileStatus.CompileError)
		return sum([tg.ErrorCount for tg in self._groups.values()]) \
						+ sum([1 for tc in self._tests.values() if tc.Status in errors])


class SuiteMixIn:
	def __init__(self):
		self._startedAt =       datetime.now()
		self._endedAt =         None
		self._initRuntime =     None
		self._overallRuntime =  None

	def __str__(self):
		return self._name

	def StartTimer(self):
		now = datetime.now()
		self.__initRuntime =    now - self._startedAt
		self._startedAt =       now

	def StopTimer(self):
		self._endedAt = datetime.now()
		self._overallRuntime =  self._endedAt - self._startedAt

	@property
	def StartTime(self):          return self._startedAt
	@property
	def EndTime(self):            return self._endedAt
	@property
	def InitializationTime(self): return self._initRuntime.microseconds
	@property
	def OverallRunTime(self):     return self._overallRuntime.seconds


class TestSuite(TestGroup, SuiteMixIn):
	def __init__(self):
		super().__init__("PoC", None)
		SuiteMixIn.__init__(self)

	@property
	def IsAllPassed(self):
		return (self.Count == self.PassedCount + self.NoAssertsCount + self.DryRunCount)

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


class SynthesisSuite(SynthesisGroup, SuiteMixIn):
	def __init__(self):
		super().__init__("PoC", None)
		SuiteMixIn.__init__(self)

	@property
	def IsAllSuccess(self):
		return (self.Count == self.SuccessCount)

	def AddSynthesis(self, synthesis):
		cur = self
		netlistPath = synthesis.Netlist.Path
		for item in netlistPath[:-2]:
			try:
				synthGroup = cur[item.Name]
			except KeyError:
				synthGroup = SynthesisGroup(item.Name, cur)
				cur[item.Name] = synthGroup
			cur = synthGroup

		synthesisName = netlistPath[-2].Name
		cur[synthesisName] = synthesis


class TestBase(ElementBase):
	def __init__(self, test):
		super().__init__(test.Parent.Name, None)

		self._test =              test

		self._status =            None
		self._warnings =          []
		self._errors =            []

		self._startedAt =         None
		self._endedAt =           None
		self._overallRuntime =    None

	@property
	def Parent(self):           return self._parent
	@Parent.setter
	def Parent(self, value):    self._parent = value

	@property
	def TestGroup(self):        return self._group
	@TestGroup.setter
	def TestGroup(self, value): self._group = value

	@property
	def Status(self):           return self._status
	@Status.setter
	def Status(self, value):    self._status = value

	def StartTimer(self):
		self._startedAt =         datetime.now()

	def StopTimer(self):
		self._endedAt =           datetime.now()
		self._overallRuntime =    self._endedAt - self._startedAt

	@property
	def OverallRunTime(self):   return self._overallRuntime.seconds


class TestCase(TestBase):
	def __init__(self, testbench):
		super().__init__(testbench)

		self._status =          SimulationStatus.Unknown

	@property
	def Testbench(self):      return self._test

	def UpdateStatus(self, testResult):
		if (testResult is testResult.NotRun):       self._status = SimulationStatus.Unknown
		elif (testResult is testResult.DryRun):     self._status = SimulationStatus.DryRun
		elif (testResult is testResult.Error):      self._status = SimulationStatus.SimulationError
		elif (testResult is testResult.Failed):     self._status = SimulationStatus.SimulationFailed
		elif (testResult is testResult.NoAsserts):  self._status = SimulationStatus.SimulationNoAsserts
		elif (testResult is testResult.Passed):     self._status = SimulationStatus.SimulationSuccess
		elif (testResult is testResult.GUIRun):     self._status = SimulationStatus.SimulationGUIRun
		else:                                       raise ValueError("Unsupported value in 'testResult'.")


class Synthesis(TestBase):
	def __init__(self, synthesis):
		super().__init__(synthesis)

		self._status =          CompileStatus.Unknown

	@property
	def Netlist(self):      return self._test

	def UpdateStatus(self, synthResult):
		if (synthResult is synthResult.NotRun):     self._status = CompileStatus.Unknown
		if (synthResult is synthResult.DryRun):     self._status = CompileStatus.DryRun
		elif (synthResult is synthResult.Error):    self._status = CompileStatus.CompileError
		elif (synthResult is synthResult.Success):  self._status = CompileStatus.CompileSuccess
		else:                                       raise IndentationError("Wuhu2")
