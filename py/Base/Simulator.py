# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#
# Python Class:      TODO
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
from datetime           import datetime
from enum               import Enum, unique

from lib.Functions      import Init
from Base.Exceptions    import ExceptionBase, SkipableException
from Base.Logging       import LogEntry
from Base.Project       import Environment, VHDLVersion
from Base.Shared        import Shared, to_time
from DataBase.Entity    import WildCard
from DataBase.TestCase  import TestCase, SimulationStatus, TestSuite


# required for autoapi.sphinx
__api__ = [
	'SimulatorException',
	'SkipableSimulatorException',
	'PoCSimulationResultNotFoundException',
	'SimulationState',
	'SimulationResult',
	'Simulator',
	'PoCSimulationResultFilter'
]
__all__ = __api__


VHDL_TESTBENCH_LIBRARY_NAME = "test"


class SimulatorException(ExceptionBase):
	"""Base class for all SimulatorExceptions."""
	pass

class SkipableSimulatorException(SimulatorException, SkipableException):
	"""Base class for all skipable SimulatorExceptions."""
	pass

class PoCSimulationResultNotFoundException(SkipableSimulatorException):
	"""This exception is raised if the expected PoC simulation result string was	not found in the simulator's output."""
	pass


@unique
class SimulationState(Enum):
	"""Simulation state enumeration."""
	Prepare =     0
	Analyze =     1
	Elaborate =   2
	Optimize =    3
	Simulate =    4
	View =        5

@unique
class SimulationResult(Enum):
	"""Simulation result enumeration."""
	NotRun =      0
	Error =       1
	Failed =      2
	NoAsserts =   3
	Passed =      4
	GUIRun =      5


class Simulator(Shared):
	"""
	Base class for all Simulator classes.

	:type  host:      object
	:param host:      The hosting instance for this instance.
	:type  dryRun:    bool
	:param dryRun:    Enable dry-run mode
	:type  noCleanUp: bool
	:param noCleanUp: Don't clean up after a run.
	"""

	_ENVIRONMENT =    Environment.Simulation
	_vhdlVersion =    VHDLVersion.VHDL2008

	class __Directories__(Shared.__Directories__):
		PreCompiled = None

	def __init__(self, host, dryRun, guiMode):
		super().__init__(host, dryRun)

		self._guiMode =         guiMode
		self._testSuite =       TestSuite()  # TODO: This includes not the read ini files phases ...
		self._state =           SimulationState.Prepare
		self._analyzeTime =     None
		self._elaborationTime = None
		self._simulationTime =  None


	# class properties
	# ============================================================================
	@property
	def TestSuite(self):      return self._testSuite

	def _PrepareSimulator(self):
		self._Prepare()

	def _PrepareSimulationEnvironment(self):
		self.LogNormal("Preparing simulation environment...")
		self._PrepareEnvironment()

	def RunAll(self, fqnList, *args, **kwargs):
		"""Run a list of testbenches. Expand wildcards to all selected testbenches."""
		self._testSuite.StartTimer()
		self.Logger.BaseIndent = int(len(fqnList) > 1)
		try:
			for fqn in fqnList:
				entity = fqn.Entity
				if (isinstance(entity, WildCard)):
					self.Logger.BaseIndent = 1
					for testbench in entity.GetVHDLTestbenches():
						self.TryRun(testbench, *args, **kwargs)
				else:
					testbench = entity.VHDLTestbench
					self.TryRun(testbench, *args, **kwargs)
		except KeyboardInterrupt:
			self.LogError("Received a keyboard interrupt.")
		finally:
			self._testSuite.StopTimer()

		self.PrintOverallSimulationReport()

		return self._testSuite.IsAllPassed

	def TryRun(self, testbench, *args, **kwargs):
		"""Try to run a testbench. Skip skipable exceptions by printing the error and its cause."""
		__SIMULATION_STATE_TO_TESTCASE_STATUS__ = {
			SimulationState.Prepare:   SimulationStatus.InternalError,
			SimulationState.Analyze:   SimulationStatus.AnalyzeError,
			SimulationState.Elaborate: SimulationStatus.ElaborationError,
			SimulationState.Optimize:  SimulationStatus.ElaborationError,
			SimulationState.Simulate:  SimulationStatus.SimulationError
		}

		testCase = TestCase(testbench)
		self._testSuite.AddTestCase(testCase)
		testCase.StartTimer()
		try:
			self.Run(testbench, *args, **kwargs)
			testCase.UpdateStatus(testbench.Result)
		except SkipableSimulatorException as ex:
			testCase.Status = __SIMULATION_STATE_TO_TESTCASE_STATUS__[self._state]

			self.LogQuiet("  {RED}ERROR:{NOCOLOR} {ExMsg}".format(ExMsg=ex.message, **Init.Foreground))
			cause = ex.__cause__
			if (cause is not None):
				self.LogQuiet("    {YELLOW}{ExType}:{NOCOLOR} {ExMsg!s}".format(ExType=cause.__class__.__name__, ExMsg=cause, **Init.Foreground))
				cause = cause.__cause__
				if (cause is not None):
					self.LogQuiet("      {YELLOW}{ExType}:{NOCOLOR} {ExMsg!s}".format(ExType=cause.__class__.__name__, ExMsg=cause, **Init.Foreground))
			self.LogQuiet("  {RED}[SKIPPED DUE TO ERRORS]{NOCOLOR}".format(**Init.Foreground))
		except SimulatorException:
			testCase.Status = __SIMULATION_STATE_TO_TESTCASE_STATUS__[self._state]
			raise
		except ExceptionBase:
			testCase.Status = SimulationStatus.SystemError
			raise
		finally:
			testCase.StopTimer()

	def Run(self, testbench, board, vhdlVersion, vhdlGenerics=None, guiMode=False):
		"""Write the Testbench message line, create a PoCProject and add the first *.files file to it."""
		self.LogQuiet("{CYAN}Testbench: {0!s}{NOCOLOR}".format(testbench.Parent, **Init.Foreground))

		self._vhdlVersion =  vhdlVersion
		self._vhdlGenerics = vhdlGenerics

		# setup all needed paths to execute fuse
		self._CreatePoCProject(testbench.ModuleName, board)
		self._AddFileListFile(testbench.FilesFile)

		self._prepareTime = self._GetTimeDeltaSinceLastEvent()

		self.LogNormal("Running analysis for every vhdl file...")
		self._state = SimulationState.Analyze
		self._RunAnalysis(testbench)
		self._analyzeTime = self._GetTimeDeltaSinceLastEvent()

		self.LogNormal("Running elaboration...")
		self._state = SimulationState.Elaborate
		self._RunElaboration(testbench)
		self._elaborationTime = self._GetTimeDeltaSinceLastEvent()

		self.LogNormal("Running simulation...")
		self._state = SimulationState.Simulate
		self._RunSimulation(testbench)
		self._simulationTime = self._GetTimeDeltaSinceLastEvent()

		if (self._guiMode is True):
			self.LogNormal("Executing waveform viewer...")
			self._state = SimulationState.View
			self._RunView(testbench)

		self._endAt = datetime.now()

	def _RunAnalysis(self, testbench):
		pass

	def _RunElaboration(self, testbench):
		pass

	def _RunSimulation(self, testbench):
		pass

	def _RunView(self, testbench):
		pass

	def PrintOverallSimulationReport(self):
		self.LogQuiet("{HEADLINE}{line}{NOCOLOR}".format(line="=" * 80, **Init.Foreground))
		self.LogQuiet("{HEADLINE}{headline: ^80s}{NOCOLOR}".format(headline="Overall Simulation Report", **Init.Foreground))
		self.LogQuiet("{HEADLINE}{line}{NOCOLOR}".format(line="=" * 80, **Init.Foreground))
		# table header
		self.LogQuiet("{Name: <24} | {Duration: >5} | {Status: ^11}".format(Name="Name", Duration="Time", Status="Status"))
		self.LogQuiet("-" * 80)
		self.PrintSimulationReportLine(self._testSuite, 0, 24)

		self.LogQuiet("{HEADLINE}{line}{NOCOLOR}".format(line="=" * 80, **Init.Foreground))
		self.LogQuiet("Time: {time: >5}  Count: {count: <3}  Passed: {passed: <3}  No Asserts: {noassert: <2}  Failed: {failed: <2}  Errors: {error: <2}".format(
			time=to_time(self._testSuite.OverallRunTime),
			count=self._testSuite.Count,
			passed=self._testSuite.PassedCount,
			noassert=self._testSuite.NoAssertsCount,
			failed=self._testSuite.FailedCount,
			error=self._testSuite.ErrorCount
		))
		self.LogQuiet("{HEADLINE}{line}{NOCOLOR}".format(line="=" * 80, **Init.Foreground))

	__SIMULATION_REPORT_COLOR_TABLE__ = {
		SimulationStatus.Unknown:             "RED",
		SimulationStatus.InternalError:       "DARK_RED",
		SimulationStatus.SystemError:         "DARK_RED",
		SimulationStatus.AnalyzeError:        "DARK_RED",
		SimulationStatus.ElaborationError:    "DARK_RED",
		SimulationStatus.SimulationError:     "RED",
		SimulationStatus.SimulationFailed:    "RED",
		SimulationStatus.SimulationNoAsserts: "YELLOW",
		SimulationStatus.SimulationSuccess:   "GREEN",
		SimulationStatus.SimulationGUIRun:    "YELLOW"
	}

	__SIMULATION_REPORT_STATUS_TEXT_TABLE__ = {
		SimulationStatus.Unknown:             "-- ?? --",
		SimulationStatus.InternalError:       "INT. ERROR",
		SimulationStatus.SystemError:         "SYS. ERROR",
		SimulationStatus.AnalyzeError:        "ANA. ERROR",
		SimulationStatus.ElaborationError:    "ELAB. ERROR",
		SimulationStatus.SimulationError:     "SIM. ERROR",
		SimulationStatus.SimulationFailed:    "FAILED",
		SimulationStatus.SimulationNoAsserts: "NO ASSERTS",
		SimulationStatus.SimulationSuccess:   "PASSED",
		SimulationStatus.SimulationGUIRun:    "GUI RUN"
	}

	def PrintSimulationReportLine(self, testObject, indent, nameColumnWidth):
		_indent = "  " * indent
		for group in testObject.Groups.values():
			pattern = "{indent}{{groupName: <{nameColumnWidth}}} |       | ".format(indent=_indent, nameColumnWidth=nameColumnWidth)
			self.LogQuiet(pattern.format(groupName=group.Name))
			self.PrintSimulationReportLine(group, indent + 1, nameColumnWidth - 2)
		for testCase in testObject.TestCases.values():
			pattern = "{indent}{{testcaseName: <{nameColumnWidth}}} | {{duration: >5}} | {{{color}}}{{status: ^11}}{{NOCOLOR}}".format(
				indent=_indent, nameColumnWidth=nameColumnWidth, color=self.__SIMULATION_REPORT_COLOR_TABLE__[testCase.Status])
			self.LogQuiet(pattern.format(testcaseName=testCase.Name, duration=to_time(testCase.OverallRunTime),
																		status=self.__SIMULATION_REPORT_STATUS_TEXT_TABLE__[testCase.Status], **Init.Foreground))


def PoCSimulationResultFilter(gen, simulationResult):
	state = 0
	for line in gen:
		if   ((state == 0) and (line.Message == "========================================")):
			state += 1
		elif ((state == 1) and (line.Message == "POC TESTBENCH REPORT")):
			state += 1
		elif ((state == 2) and (line.Message == "========================================")):
			state += 1
		elif ((state == 3) and (line.Message == "========================================")):
			state += 1
		elif ((state == 4) and line.Message.startswith("SIMULATION RESULT = ")):
			state += 1
			if line.Message.endswith("FAILED"):
				color = Init.Foreground['RED']
				simulationResult <<= SimulationResult.Failed
			elif line.Message.endswith("NO ASSERTS"):
				color = Init.Foreground['YELLOW']
				simulationResult <<= SimulationResult.NoAsserts
			elif line.Message.endswith("PASSED"):
				color = Init.Foreground['GREEN']
				simulationResult <<= SimulationResult.Passed
			else:
				color = Init.Foreground['RED']
				simulationResult <<= SimulationResult.Error

			yield LogEntry("{COLOR}{line}{NOCOLOR}".format(COLOR=color,line=line.Message, **Init.Foreground), line.Severity, line.Indent)
			continue
		elif ((state == 5) and (line.Message == "========================================")):
			state += 1

		yield line

	if (state != 6):    raise PoCSimulationResultNotFoundException("No PoC Testbench Report in simulator output found.")
