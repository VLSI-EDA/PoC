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
from lib.Parser import ParserException

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
from PoC.Project			import Project as PoCProject, FileListFile

VHDL_TESTBENCH_LIBRARY_NAME = "test"


class SimulatorException(ExceptionBase):
	pass

@unique
class SimulationResult(Enum):
	Failed = 0
	NoAsserts = 1
	Passed = 2


class Simulator(ILogable):
	_TOOL_CHAIN =	ToolChain.Any
	_TOOL =				Tool.Any

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

		self._tempPath =		None

	# class properties
	# ============================================================================
	@property
	def Host(self):						return self.__host
	@property
	def ShowLogs(self):				return self.__showLogs
	@property
	def ShowReport(self):			return self.__showReport
	@property
	def TemporaryPath(self):	return self._tempPath


	def _PrepareSimulationEnvironment(self):
		# create temporary directory if not existent
		if (not (self._tempPath).exists()):
			self._LogVerbose("  Creating temporary directory for simulator files.")
			self._LogDebug("    Temporary directory: {0!s}".format(self._tempPath))
			self._tempPath.mkdir(parents=True)

		# change working directory to temporary path
		self._LogVerbose("  Changing working directory to temporary directory.")
		self._LogDebug("    cd \"{0!s}\"".format(self._tempPath))
		chdir(str(self._tempPath))

	def _CreatePoCProject(self, testbench, board):
		# create a PoCProject and read all needed files
		self._LogDebug("    Create a PoC project '{0}'".format(testbench.ModuleName))
		pocProject = PoCProject(testbench.ModuleName)

		# configure the project
		pocProject.RootDirectory = self.Host.Directories["PoCRoot"]
		pocProject.Environment = Environment.Simulation
		pocProject.ToolChain = self._TOOL_CHAIN
		pocProject.Tool = self._TOOL
		pocProject.VHDLVersion = self._vhdlVersion
		pocProject.Board = board

		self._pocProject = pocProject

	def _AddFileListFile(self, fileListFilePath):
		self._LogDebug("    Reading filelist '{0!s}'".format(fileListFilePath))
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

		self._LogDebug(self._pocProject.pprint(2))
		self._LogDebug("=" * 160)
		if (len(fileListFile.Warnings) > 0):
			for warn in fileListFile.Warnings:
				self._LogWarning(warn)
			raise SimulatorException("Found critical warnings while parsing '{0!s}'".format(fileListFilePath))

	def RunAll(self, fqnList, *args, **kwargs):
		for fqn in fqnList:
			entity = fqn.Entity
			# for entity in fqn.GetEntities():
			# try:
			self.Run(entity, *args, **kwargs)
			# except SimulatorException:
			# 	pass

	def Run(self, entity, board, vhdlVersion="93c", vhdlGenerics=None, **kwargs):
		raise NotImplementedError("This method is abstract.")

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
