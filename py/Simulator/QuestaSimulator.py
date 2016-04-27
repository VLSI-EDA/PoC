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

from lib.Functions					import Init
# from Base.Exceptions							import PlatformNotSupportedException, NotConfiguredException
from Base.Project									import FileTypes, VHDLVersion, Environment, ToolChain, Tool
from Base.Simulator								import SimulatorException, Simulator as BaseSimulator, VHDL_TESTBENCH_LIBRARY_NAME, SimulationResult
from ToolChains.Mentor.QuestaSim	import QuestaSim, QuestaException


class Simulator(BaseSimulator):
	_TOOL_CHAIN =						ToolChain.Mentor_QuestaSim
	_TOOL =									Tool.Mentor_vSim

	def __init__(self, host, showLogs, showReport, guiMode):
		super(self.__class__, self).__init__(host, showLogs, showReport)

		self._guiMode =				guiMode

		self._entity =				None
		self._testbenchFQN =	None
		self._vhdlVersion =		None
		self._vhdlGenerics =	None

		self._questa =				None

		self._PrepareSimulationEnvironment()

	@property
	def TemporaryPath(self):
		return self._tempPath

	def _PrepareSimulationEnvironment(self):
		self._LogNormal("preparing simulation environment...")
		self._tempPath = self.Host.Directories["vSimTemp"]
		super()._PrepareSimulationEnvironment()

	def PrepareSimulator(self, binaryPath, version):
		# create the QuestaSim executable factory
		self._LogVerbose("Preparing Mentor simulator.")
		self._questa =		QuestaSim(self.Host.Platform, binaryPath, version, logger=self.Logger)

	def Run(self, testbench, board, vhdlVersion="93", vhdlGenerics=None, guiMode=False):
		self._LogQuiet("Testbench: {0!s}".format(testbench.Parent, **Init.Foreground))

		self._vhdlVersion =		vhdlVersion
		self._vhdlGenerics =	vhdlGenerics

		# setup all needed paths to execute fuse
		self._CreatePoCProject(testbench, board)
		self._AddFileListFile(testbench.FilesFile)
		
		self._RunCompile(testbench)
		# self._RunOptimize()
		
		if (not self._guiMode):
			self._RunSimulation(testbench)
		else:
			self._RunSimulationWithGUI(testbench)

		if (testbench.Result is SimulationResult.Passed):				self._LogQuiet("  {GREEN}[PASSED]{NOCOLOR}".format(**Init.Foreground))
		elif (testbench.Result is SimulationResult.NoAsserts):	self._LogQuiet("  {YELLOW}[NO ASSERTS]{NOCOLOR}".format(**Init.Foreground))
		elif (testbench.Result is SimulationResult.Failed):			self._LogQuiet("  {RED}[FAILED]{NOCOLOR}".format(**Init.Foreground))
		elif (testbench.Result is SimulationResult.Error):			self._LogQuiet("  {RED}[ERROR]{NOCOLOR}".format(**Init.Foreground))
		
	def _RunCompile(self, testbench):
		self._LogNormal("Running VHDL compiler for every vhdl file...")

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
			if (not file.Path.exists()):								raise SimulatorException("Can not analyse '{0!s}'.".format(file.Path)) from FileNotFoundError(str(file.Path))

			vcomLogFile = self._tempPath / (file.Path.stem + ".vcom.log")
			vcom.Parameters[vcom.SwitchVHDLLibrary] =	file.LibraryName
			vcom.Parameters[vcom.ArgLogFile] =				vcomLogFile
			vcom.Parameters[vcom.ArgSourceFile] =			file.Path

			try:
				vcom.Compile()
			except QuestaException as ex:
				raise SimulatorException("Error while compiling '{0!s}'.".format(file.Path)) from ex

			if vcom.HasErrors:
				raise SimulatorException("Error while compiling '{0!s}'.".format(file.Path))

			# delete empty log files
			if (vcomLogFile.stat().st_size == 0):
				vcomLogFile.unlink()

	def _RunSimulation(self, testbench):
		self._LogNormal("Running simulation...")
		
		tclBatchFilePath =		self.Host.Directories["PoCRoot"] / self.Host.PoCConfig[testbench.ConfigSectionName]['vSimBatchScript']
		
		# create a QuestaSimulator instance
		vsim = self._questa.GetSimulator()
		# vsim.Parameters[vsim.FlagOptimization] =			True
		vsim.Parameters[vsim.FlagReportAsError] =			"3473"
		vsim.Parameters[vsim.SwitchTimeResolution] =	"1fs"
		vsim.Parameters[vsim.FlagCommandLineMode] =		True
		vsim.Parameters[vsim.SwitchBatchCommand] =		"do {0}".format(tclBatchFilePath.as_posix())
		vsim.Parameters[vsim.SwitchTopLevel] =				"{0}.{1}".format(VHDL_TESTBENCH_LIBRARY_NAME, testbench.ModuleName)
		testbench.Result = vsim.Simulate()
		
	def _RunSimulationWithGUI(self, testbench):
		self._LogNormal("Running simulation...")
	
		tclGUIFilePath =			self.Host.Directories["PoCRoot"] / self.Host.PoCConfig[testbench.ConfigSectionName]['vSimGUIScript']
		tclWaveFilePath =			self.Host.Directories["PoCRoot"] / self.Host.PoCConfig[testbench.ConfigSectionName]['vSimWaveScript']

		# create a QuestaSimulator instance
		vsim = self._questa.GetSimulator()
		# vsim.Parameters[vsim.FlagOptimization] =			True
		vsim.Parameters[vsim.FlagReportAsError] =			"3473"
		vsim.Parameters[vsim.SwitchTimeResolution] =	"1fs"
		vsim.Parameters[vsim.FlagGuiMode] =						True
		vsim.Parameters[vsim.SwitchTopLevel] =				"{0}.{1}".format(VHDL_TESTBENCH_LIBRARY_NAME, testbench.ModuleName)
		# vsim.Parameters[vsim.SwitchTitle] =						testbenchName

		if (tclWaveFilePath.exists()):
			self._LogDebug("Found waveform script: '{0!s}'".format(tclWaveFilePath))
			vsim.Parameters[vsim.SwitchBatchCommand] =	"do {0}; do {1}".format(tclWaveFilePath.as_posix(), tclGUIFilePath.as_posix())
		else:
			self._LogDebug("Didn't find waveform script: '{0!s}'. Loading default commands.".format(tclWaveFilePath))
			vsim.Parameters[vsim.SwitchBatchCommand] =	"add wave *; do {0}".format(tclGUIFilePath.as_posix())

		testbench.Result = vsim.Simulate()
