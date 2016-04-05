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
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module Simulator.vSimSimulator")

# load dependencies
from configparser									import NoSectionError
from os														import chdir

from colorama											import Fore as Foreground

# from Base.Exceptions							import PlatformNotSupportedException, NotConfiguredException
from Base.Project									import FileTypes, VHDLVersion, Environment, ToolChain, Tool, FileListFile
from Base.Simulator								import SimulatorException, Simulator as BaseSimulator, VHDLTestbenchLibraryName
# from Parser.Parser								import ParserException
from PoC.Project								import Project as PoCProject
from ToolChains.Mentor.QuestaSim	import QuestaSim, QuestaException


class Simulator(BaseSimulator):
	__guiMode =				False

	def __init__(self, host, showLogs, showReport, guiMode):
		super(self.__class__, self).__init__(host, showLogs, showReport)

		self._guiMode =				guiMode
		self._questa =				None

		self._LogNormal("preparing simulation environment...")
		self._PrepareSimulationEnvironment()

	@property
	def TemporaryPath(self):
		return self._tempPath

	def _PrepareSimulationEnvironment(self):
		self._LogNormal("  preparing simulation environment...")
		
		# create temporary directory for ghdl if not existent
		self._tempPath = self.Host.Directories["vSimTemp"]
		if (not (self._tempPath).exists()):
			self._LogVerbose("  Creating temporary directory for simulator files.")
			self._LogDebug("    Temporary directors: {0}".format(str(self._tempPath)))
			self._tempPath.mkdir(parents=True)
			
		# change working directory to temporary iSim path
		self._LogVerbose("  Changing working directory to temporary directory.")
		self._LogDebug("    cd \"{0}\"".format(str(self._tempPath)))
		chdir(str(self._tempPath))

	def PrepareSimulator(self, binaryPath, version):
		# create the GHDL executable factory
		self._LogVerbose("  Preparing Mentor simulator.")
		self._questa =		QuestaSim(self.Host.Platform, binaryPath, version, logger=self.Logger)

	def RunAll(self, pocEntities, **kwargs):
		for pocEntity in pocEntities:
			self.Run(pocEntity, **kwargs)
		
	def Run(self, entity, board, vhdlVersion="93", vhdlGenerics=None):
		self._entity =				entity
		self._testbenchFQN =	str(entity)										# TODO: implement FQN method on PoCEntity
		self._vhdlVersion =		vhdlVersion
		self._vhdlGenerics =	vhdlGenerics

		# check testbench database for the given testbench		
		self._LogQuiet("Testbench: {0}{1}{2}".format(Foreground.YELLOW, self._testbenchFQN, Foreground.RESET))
		if (not self.Host.TBConfig.has_section(self._testbenchFQN)):
			raise SimulatorException("Testbench '{0}' not found.".format(self._testbenchFQN)) from NoSectionError(self._testbenchFQN)
			
		# setup all needed paths to execute fuse
		testbenchName =				self.Host.TBConfig[self._testbenchFQN]['TestbenchModule']
		fileListFilePath =		self.Host.Directories["PoCRoot"] / self.Host.TBConfig[self._testbenchFQN]['fileListFile']

		self._CreatePoCProject(testbenchName, board)
		self._AddFileListFile(fileListFilePath)
		
		self._RunCompile()
		# self._RunOptimize()
		
		if (not self._guiMode):
			self._RunSimulation(testbenchName)
		else:
			self._RunSimulationWithGUI(testbenchName)
		
	def _CreatePoCProject(self, testbenchName, board):
		# create a PoCProject and read all needed files
		self._LogDebug("    Create a PoC project '{0}'".format(str(testbenchName)))
		pocProject =									PoCProject(testbenchName)
		
		# configure the project
		pocProject.RootDirectory =		self.Host.Directories["PoCRoot"]
		pocProject.Environment =			Environment.Simulation
		pocProject.ToolChain =				ToolChain.Mentor_QuestaSim
		pocProject.Tool =							Tool.Mentor_vSim
		pocProject.VHDLVersion =			self._vhdlVersion
		pocProject.Board =						board

		self._pocProject =						pocProject
		
	def _AddFileListFile(self, fileListFilePath):
		self._LogDebug("    Reading filelist '{0}'".format(str(fileListFilePath)))
		# add the *.files file, parse and evaluate it
		fileListFile = self._pocProject.AddFile(FileListFile(fileListFilePath))
		fileListFile.Parse()
		fileListFile.CopyFilesToFileSet()
		fileListFile.CopyExternalLibraries()
		self._pocProject.ExtractVHDLLibrariesFromVHDLSourceFiles()
		self._LogDebug(self._pocProject.pprint(2))
		self._LogDebug("=" * 160)
		
	def _RunCompile(self):
		self._LogNormal("  running VHDL compiler for every vhdl file...")

		# create a QuestaVHDLCompiler instance
		vlib = self._questa.GetVHDLLibraryTool()
		for lib in self._pocProject.VHDLLibraries:
			vlib.Parameters[vlib.SwitchLibraryName] = lib.Name
			vlib.CreateLibrary()

		# create a QuestaVHDLCompiler instance
		vcom = self._questa.GetVHDLCompiler()
		vcom.Parameters[vcom.FlagQuietMode] =					True
		vcom.Parameters[vcom.FlagExplicit] =					True
		vcom.Parameters[vcom.FlagRangeCheck] =				True

		if (self._vhdlVersion == VHDLVersion.VHDL87):		vcom.Parameters[vcom.SwitchVHDLVersion] =		"87"
		elif (self._vhdlVersion == VHDLVersion.VHDL93):	vcom.Parameters[vcom.SwitchVHDLVersion] =		"93"
		elif (self._vhdlVersion == VHDLVersion.VHDL02):	vcom.Parameters[vcom.SwitchVHDLVersion] =		"2002"
		elif (self._vhdlVersion == VHDLVersion.VHDL08):	vcom.Parameters[vcom.SwitchVHDLVersion] =		"2008"
		else:																					raise SimulatorException("VHDL version is not supported.")

		# run vcom compile for each VHDL file
		for file in self._pocProject.Files(fileType=FileTypes.VHDLSourceFile):
			if (not file.Path.exists()):								raise SimulatorException("Can not analyse '{0}'.".format(str(file.Path))) from FileNotFoundError(str(file.Path))

			vcomLogFile = self._tempPath / (file.Path.stem + ".vcom.log")
			vcom.Parameters[vcom.SwitchVHDLLibrary] =	file.VHDLLibraryName
			vcom.Parameters[vcom.ArgLogFile] =				vcomLogFile
			vcom.Parameters[vcom.ArgSourceFile] =			file.Path

			try:
				vcom.Compile()
			except QuestaException as ex:
				raise SimulatorException("Error while compiling '{0}'.".format(str(file.Path))) from ex

			if vcom.HasErrors:
				raise SimulatorException("Error while compiling '{0}'.".format(str(file.Path)))

			# delete empty log files
			if (vcomLogFile.stat().st_size == 0):
				vcomLogFile.unlink()

	def _RunSimulation(self, testbenchName):
		self._LogNormal("  running simulation...")
		
		tclBatchFilePath =		self.Host.Directories["PoCRoot"] / self.Host.TBConfig[self._testbenchFQN]['vSimBatchScript']
		
		# create a QuestaSimulator instance
		vsim = self._questa.GetSimulator()
		vsim.Parameters[vsim.FlagOptimization] =			True
		vsim.Parameters[vsim.FlagReportAsError] =			"3473"
		vsim.Parameters[vsim.SwitchTimeResolution] =	"1fs"
		vsim.Parameters[vsim.FlagCommandLineMode] =		True
		vsim.Parameters[vsim.SwitchBatchCommand] =		"do {0}".format(tclBatchFilePath.as_posix())
		vsim.Parameters[vsim.SwitchTopLevel] =				"{0}.{1}".format(VHDLTestbenchLibraryName, testbenchName)
		vsim.Simulate()
		
	def _RunSimulationWithGUI(self, testbenchName):
		self._LogNormal("  running simulation...")
	
		tclGUIFilePath =			self.Host.Directories["PoCRoot"] / self.Host.TBConfig[self._testbenchFQN]['vSimGUIScript']
		tclWaveFilePath =			self.Host.Directories["PoCRoot"] / self.Host.TBConfig[self._testbenchFQN]['vSimWaveScript']

		# create a QuestaSimulator instance
		vsim = self._questa.GetSimulator()
		vsim.Parameters[vsim.FlagOptimization] =			True
		vsim.Parameters[vsim.FlagReportAsError] =			"3473"
		vsim.Parameters[vsim.SwitchTimeResolution] =	"1fs"
		vsim.Parameters[vsim.FlagGuiMode] =						True
		vsim.Parameters[vsim.SwitchTopLevel] =				"{0}.{1}".format(VHDLTestbenchLibraryName, testbenchName)
		# vsim.Parameters[vsim.SwitchTitle] =						testbenchName

		if (tclWaveFilePath.exists()):
			self._LogDebug("Found waveform script: '{0}'".format(str(tclWaveFilePath)))
			vsim.Parameters[vsim.SwitchBatchCommand] =	"do {0}; do {1}".format(tclWaveFilePath.as_posix(), tclGUIFilePath.as_posix())
		else:
			self._LogDebug("Didn't find waveform script: '{0}'. Loading default commands.".format(str(tclWaveFilePath)))
			vsim.Parameters[vsim.SwitchBatchCommand] =	"add wave *; do {0}".format(tclGUIFilePath.as_posix())

		vsim.Simulate()

		# if (not self.__guiMode):
			# try:
				# result = self.checkSimulatorOutput(simulatorLog)
				
				# if (result == True):
					# print("Testbench '%s': PASSED" % testbenchName)
				# else:
					# print("Testbench '%s': FAILED" % testbenchName)
					
			# except SimulatorException as ex:
				# raise TestbenchException("PoC.ns.module", testbenchName, "'SIMULATION RESULT = [PASSED|FAILED]' not found in simulator output.") from ex
		

