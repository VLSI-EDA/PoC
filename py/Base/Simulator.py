# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
# Authors:					Patrick Lehmann
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
	pass
	# place library initialization code here
else:
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module Simulator.Base")


# load dependencies
from enum							import Enum, unique
from os								import chdir

from Base.Exceptions	import ExceptionBase
from Base.Logging			import ILogable
from Base.Project			import Environment, ToolChain, Tool, VHDLVersion
from lib.Parser				import ParserException
from PoC.Project			import VirtualProject, FileListFile
from PoC.Entity				import WildCard


VHDL_TESTBENCH_LIBRARY_NAME = "test"


class SimulatorException(ExceptionBase):
	pass

class SkipableSimulatorException(SimulatorException):
	pass


@unique
class SimulationResult(Enum):
	Failed =		0
	NoAsserts =	1
	Passed =		2
	Error =			5


class Simulator(ILogable):
	_TOOL_CHAIN =	ToolChain.Any
	_TOOL =				Tool.Any

	class __Directories__:
		Working = None
		PoCRoot = None
		PreCompiled = None

	def __init__(self, host, showLogs, showReport):
		if isinstance(host, ILogable):
			ILogable.__init__(self, host.Logger)
		else:
			ILogable.__init__(self, None)

		self.__host =				host
		self.__showLogs =		showLogs
		self.__showReport =	showReport

		self._vhdlVersion =	VHDLVersion.VHDL2008
		self._pocProject =	None

		self._directories = self.__Directories__()

	# class properties
	# ============================================================================
	@property
	def Host(self):						return self.__host
	@property
	def ShowLogs(self):				return self.__showLogs
	@property
	def ShowReport(self):			return self.__showReport
	@property
	def Directories(self):		return self._directories

	def _PrepareSimulationEnvironment(self):
		self._LogNormal("Preparing simulation environment...")
		# create temporary directory if not existent
		if (not self.Directories.Working.exists()):
			self._LogVerbose("Creating temporary directory for simulator files.")
			self._LogDebug("Temporary directory: {0!s}".format(self.Directories.Working))
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
		# if (not fileListFilePath.exists()):		raise SimulatorException("Files file '{0!s}' not found.".format(fileListFilePath)) from FileNotFoundError(str(fileListFilePath))

		try:
			fileListFile = self._pocProject.AddFile(FileListFile(fileListFilePath))
			fileListFile.Parse()
			fileListFile.CopyFilesToFileSet()
			fileListFile.CopyExternalLibraries()
			self._pocProject.ExtractVHDLLibrariesFromVHDLSourceFiles()
		except ParserException as ex:
			raise SimulatorException("Error while parsing '{0!s}'.".format(fileListFilePath)) from ex

		self._LogDebug("=" * 78)
		self._LogDebug("Pretty printing the PoCProject...")
		self._LogDebug(self._pocProject.pprint(2))
		self._LogDebug("=" * 78)
		if (len(fileListFile.Warnings) > 0):
			for warn in fileListFile.Warnings:
				self._LogWarning(warn)
			raise SimulatorException("Found critical warnings while parsing '{0!s}'".format(fileListFilePath))

	def RunAll(self, fqnList, *args, **kwargs):
		for fqn in fqnList:
			entity = fqn.Entity
			if (isinstance(entity, WildCard)):
				for testbench in entity.GetVHDLTestbenches():
					try:
						self.Run(testbench, *args, **kwargs)
					except SkipableSimulatorException:
						pass
			else:
				testbench = entity.VHDLTestbench
				try:
					self.Run(testbench, *args, **kwargs)
				except SkipableSimulatorException:
					pass

	def Run(self, testbench, board, vhdlVersion="93c", vhdlGenerics=None, **kwargs):
		raise NotImplementedError("This method is abstract.")


def PoCSimulationResultFilter(gen, simulationResult):
	state = 0
	for line in gen:
		if   ((state == 0) and (line.Message == "========================================")):
			state = 1
		elif ((state == 1) and (line.Message == "POC TESTBENCH REPORT")):
			state = 2
		elif ((state == 2) and (line.Message == "========================================")):
			state = 3
		elif ((state == 3) and (line.Message == "========================================")):
			state = 4
		elif ((state == 4) and line.Message.startswith("SIMULATION RESULT = ")):
			state = 5
			if line.Message.endswith("FAILED"):
				simulationResult <<= SimulationResult.Failed
			elif line.Message.endswith("NO ASSERTS"):
				simulationResult <<= SimulationResult.NoAsserts
			elif line.Message.endswith("PASSED"):
				simulationResult <<= SimulationResult.Passed
			else:
				simulationResult <<= SimulationResult.Error
		elif ((state == 5) and (line.Message == "========================================")):
			state = 6

		yield line

	if (state != 6):		raise SimulatorException("No PoC Testbench Report in simulator output found.")
