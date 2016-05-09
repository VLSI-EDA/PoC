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
	pass
	# place library initialization code here
else:
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module Simulator.Base")


# load dependencies
import shutil
from datetime          import datetime
from enum              import Enum, unique
from os                import chdir

from lib.Functions     import Init
from lib.Parser        import ParserException
from Base.Exceptions   import ExceptionBase, CommonException
from Base.Logging      import ILogable, LogEntry
from Base.Project      import Environment, ToolChain, Tool, VHDLVersion
from PoC.Entity        import WildCard
from PoC.Solution      import VirtualProject, FileListFile
from PoC.TestCase      import TestSuite, TestCase, Status


VHDL_TESTBENCH_LIBRARY_NAME = "test"


class SimulatorException(ExceptionBase):
	pass

class SkipableSimulatorException(SimulatorException):
	pass


@unique
class SimulationState(Enum):
	Prepare =     0
	Analyze =     1
	Elaborate =   2
	Optimize =    3
	Simulate =    4
	View =        5

@unique
class SimulationResult(Enum):
	NotRun =      0
	Error =       1
	Failed =      2
	NoAsserts =   3
	Passed =      4


class Simulator(ILogable):
	_TOOL_CHAIN =  ToolChain.Any
	_TOOL =        Tool.Any

	class __Directories__:
		Working = None
		PoCRoot = None
		PreCompiled = None

	def __init__(self, host):
		if isinstance(host, ILogable):
			ILogable.__init__(self, host.Logger)
		else:
			ILogable.__init__(self, None)

		self.__host =       host

		self._vhdlVersion = VHDLVersion.VHDL2008
		self._directories = self.__Directories__()
		self._pocProject =  None
		self._testSuite =   TestSuite()			# TODO: This includes not the read ini files phases ...

		self._state =           SimulationState.Prepare
		self._startAt =         datetime.now()
		self._endAt =           None
		self._lastEvent =       self._startAt
		self._prepareTime =     None
		self._analyzeTime =     None
		self._elaborationTime = None
		self._simulationTime =  None


	# class properties
	# ============================================================================
	@property
	def Host(self):           return self.__host
	@property
	def Directories(self):    return self._directories

	def _GetTimeDeltaSinceLastEvent(self):
		now = datetime.now()
		result = now - self._lastEvent
		self._lastEvent = now
		return result

	def _PrepareSimulationEnvironment(self):
		self._LogNormal("Preparing simulation environment...")

		# create fresh temporary directory
		self._LogVerbose("Creating fresh temporary directory for simulator files.")
		self._LogDebug("Temporary directory: {0!s}".format(self.Directories.Working))
		if (self.Directories.Working.exists()):
			shutil.rmtree(str(self.Directories.Working))
		self.Directories.Working.mkdir(parents=True)

		# change working directory to temporary path
		self._LogVerbose("Changing working directory to temporary directory.")
		self._LogDebug("cd \"{0!s}\"".format(self.Directories.Working))
		chdir(str(self.Directories.Working))

	def _CreatePoCProject(self, testbench, board):
		# create a PoCProject and read all needed files
		self._LogVerbose("Creating a PoC project '{0}'".format(testbench.ModuleName))
		pocProject = VirtualProject(testbench.ModuleName)

		# configure the project
		pocProject.RootDirectory = self.Host.Directories.Root
		pocProject.Environment = Environment.Simulation
		pocProject.ToolChain = self._TOOL_CHAIN
		pocProject.Tool = self._TOOL
		pocProject.VHDLVersion = self._vhdlVersion
		pocProject.Board = board

		self._pocProject = pocProject

	def _AddFileListFile(self, fileListFilePath):
		self._LogVerbose("Reading filelist '{0!s}'".format(fileListFilePath))
		# add the *.files file, parse and evaluate it
		# if (not fileListFilePath.exists()):    raise SimulatorException("Files file '{0!s}' not found.".format(fileListFilePath)) from FileNotFoundError(str(fileListFilePath))

		try:
			fileListFile = self._pocProject.AddFile(FileListFile(fileListFilePath))
			fileListFile.Parse()
			fileListFile.CopyFilesToFileSet()
			fileListFile.CopyExternalLibraries()
			self._pocProject.ExtractVHDLLibrariesFromVHDLSourceFiles()
		except (ParserException, CommonException) as ex:
			raise SkipableSimulatorException("Error while parsing '{0!s}'.".format(fileListFilePath)) from ex

		self._LogDebug("=" * 78)
		self._LogDebug("Pretty printing the PoCProject...")
		self._LogDebug(self._pocProject.pprint(2))
		self._LogDebug("=" * 78)
		if (len(fileListFile.Warnings) > 0):
			for warn in fileListFile.Warnings:
				self._LogWarning(warn)
			raise SkipableSimulatorException("Found critical warnings while parsing '{0!s}'".format(fileListFilePath))

	def RunAll(self, fqnList, *args, **kwargs):
		self._testSuite.StartTimer()
		try:
			for fqn in fqnList:
				entity = fqn.Entity
				if (isinstance(entity, WildCard)):
					for testbench in entity.GetVHDLTestbenches():
						self.TryRun(testbench, *args, **kwargs)
				else:
					testbench = entity.VHDLTestbench
					self.TryRun(testbench, *args, **kwargs)
		except KeyboardInterrupt:
			self._LogError("Received a keyboard interrupt.")
		finally:
			self._testSuite.StopTimer()

		# if (len(self._testSuite) > 1):
		self.PrintOverallSimulationReport()

		return self._testSuite.IsAllPassed

	__SIMULATION_STATE_TO_TESTCASE_STATUS__ = {
		SimulationState.Prepare:    Status.InternalError,
		SimulationState.Analyze:    Status.AnalyzeError,
		SimulationState.Elaborate:  Status.ElaborationError,
		SimulationState.Optimize:   Status.ElaborationError,
		SimulationState.Simulate:   Status.SimulationError
	}

	def TryRun(self, testbench, *args, **kwargs):
		testCase = TestCase(testbench)
		self._testSuite.AddTestCase(testCase)
		testCase.StartTimer()
		try:
			self.Run(testbench, *args, **kwargs)
			testCase.UpdateStatus(testbench.Result)
		except SkipableSimulatorException as ex:
			testCase.Status = self.__SIMULATION_STATE_TO_TESTCASE_STATUS__[self._state]

			self._LogQuiet("  {RED}ERROR:{NOCOLOR} {ExMsg}".format(ExMsg=ex.message, **Init.Foreground))
			cause = ex.__cause__
			if (cause is not None):
				self._LogQuiet("    {YELLOW}{ExType}:{NOCOLOR} {ExMsg!s}".format(ExType=cause.__class__.__name__, ExMsg=cause, **Init.Foreground))
				cause = cause.__cause__
				if (cause is not None):
					self._LogQuiet("      {YELLOW}{ExType}:{NOCOLOR} {ExMsg!s}".format(ExType=cause.__class__.__name__, ExMsg=cause, **Init.Foreground))
			self._LogQuiet("  {RED}[SKIPPED DUE TO ERRORS]{NOCOLOR}".format(**Init.Foreground))
		except SimulatorException:
			testCase.Status = self.__SIMULATION_STATE_TO_TESTCASE_STATUS__[self._state]
			raise
		except ExceptionBase:
			testCase.Status = Status.SystemError
			raise
		finally:
			testCase.StopTimer()

	def Run(self, testbench, board, vhdlVersion, vhdlGenerics=None):
		self._LogQuiet("{CYAN}Testbench:{NOCOLOR} {0!s}".format(testbench.Parent, **Init.Foreground))

		self._vhdlVersion =  vhdlVersion
		self._vhdlGenerics = vhdlGenerics

		# setup all needed paths to execute fuse
		self._CreatePoCProject(testbench, board)
		self._AddFileListFile(testbench.FilesFile)

	def PrintOverallSimulationReport(self):
		def to_time(seconds):
			min = int(seconds / 60)
			sec = seconds - (min * 60)
			return "{min}:{sec:02}".format(min=min, sec=sec)

		self._LogQuiet("{HEADLINE}{line}{NOCOLOR}".format(line="=" * 80, **Init.Foreground))
		self._LogQuiet("{HEADLINE}{headline: ^80s}{NOCOLOR}".format(headline="Overall Simulation Report", **Init.Foreground))
		self._LogQuiet("{HEADLINE}{line}{NOCOLOR}".format(line="=" * 80, **Init.Foreground))
		# table header
		self._LogQuiet("{Name: <24} | {Duration: >5} | {Status: ^11}".format(Name="Name", Duration="Time", Status="Status"))
		self._LogQuiet("-"*80)
		self.PrintSimulationReportLine(self._testSuite, 0, 24)

		self._LogQuiet("{HEADLINE}{line}{NOCOLOR}".format(line="=" * 80, **Init.Foreground))
		self._LogQuiet("Time: {time: >5}  Count: {count: <3}  Passed: {passed: <3}  No Asserts: {noassert: <2}  Failed: {failed: <2}  Errors: {error: <2}".format(
				time=to_time(self._testSuite.OverallRunTime),
				count=self._testSuite.Count,
				passed=self._testSuite.PassedCount,
				noassert=self._testSuite.NoAssertsCount,
				failed=self._testSuite.FailedCount,
				error=self._testSuite.ErrorCount
		))
		self._LogQuiet("{HEADLINE}{line}{NOCOLOR}".format(line="=" * 80, **Init.Foreground))

	__SIMULATION_REPORT_COLOR_TABLE__ = {
		Status.Unknown:             "RED",
		Status.SystemError:         "DARK_RED",
		Status.AnalyzeError:        "DARK_RED",
		Status.ElaborationError:    "DARK_RED",
		Status.OptimizationError:   "DARK_RED",
		Status.SimulationError:     "RED",
		Status.SimulationFailed:    "RED",
		Status.SimulationNoAsserts: "YELLOW",
		Status.SimulationSuccess:   "GREEN"
	}

	__SIMULATION_REPORT_STATUS_TEXT_TABLE__ = {
		Status.Unknown:             "-- ?? --",
		Status.SystemError:         "SYS. ERROR",
		Status.AnalyzeError:        "ANA. ERROR",
		Status.ElaborationError:    "ELAB. ERROR",
		Status.OptimizationError:   "OPT. ERROR",
		Status.SimulationError:     "SIM. ERROR",
		Status.SimulationFailed:    "FAILED",
		Status.SimulationNoAsserts: "NO ASSERTS",
		Status.SimulationSuccess:   "PASSED"
	}

	def PrintSimulationReportLine(self, testObject, indent, nameColumnWidth):
		def to_time(seconds):
			min = int(seconds / 60)
			sec = seconds - (min * 60)
			return "{min}:{sec:02}".format(min=min, sec=sec)

		_indent = "  " * indent
		for group in testObject.TestGroups.values():
			pattern = "{indent}{{groupName: <{nameColumnWidth}}} |       | ".format(indent=_indent, nameColumnWidth=nameColumnWidth)
			self._LogQuiet(pattern.format(groupName=group.Name))
			self.PrintSimulationReportLine(group, indent+1, nameColumnWidth-2)
		for testCase in testObject.TestCases.values():
			pattern = "{indent}{{testcaseName: <{nameColumnWidth}}} | {{duration: >5}} | {{{color}}}{{status: ^11}}{{NOCOLOR}}".format(
					indent=_indent, nameColumnWidth=nameColumnWidth, color=self.__SIMULATION_REPORT_COLOR_TABLE__[testCase.Status])
			self._LogQuiet(pattern.format(testcaseName=testCase.Name, duration=to_time(testCase.OverallRunTime),
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

	if (state != 6):    raise SkipableSimulatorException("No PoC Testbench Report in simulator output found.")
