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
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module Simulator.ActiveHDLSimulator")


# load dependencies
from pathlib import Path

from Base.Exceptions import NotConfiguredException
from lib.Functions							import Init
from Base.Project								import FileTypes, VHDLVersion, ToolChain, Tool
from Base.Simulator							import SimulatorException, Simulator as BaseSimulator, VHDL_TESTBENCH_LIBRARY_NAME, SimulationResult
from ToolChains.Aldec.ActiveHDL	import ActiveHDL, ActiveHDLException


class Simulator(BaseSimulator):
	_TOOL_CHAIN =						ToolChain.Aldec_ActiveHDL
	_TOOL =									Tool.Aldec_aSim

	def __init__(self, host, showLogs, showReport, guiMode):
		super().__init__(host, showLogs, showReport)

		self._guiMode =				guiMode

		self._entity =				None
		self._testbenchFQN =	None
		self._vhdlVersion =		None
		self._vhdlGenerics =	None

		self._activeHDL =			None

		activeHDLFilesDirectoryName = host.PoCConfig['CONFIG.DirectoryNames']['ActiveHDLFiles']
		self.Directories.Working = host.Directories.Temp / activeHDLFilesDirectoryName
		self.Directories.PreCompiled = host.Directories.PreCompiled / activeHDLFilesDirectoryName
		
		self._PrepareSimulationEnvironment()
		self._PrepareSimulator()

	def _PrepareSimulator(self):
		# create the Active-HDL executable factory
		self._LogVerbose("Preparing Active-HDL simulator.")
		for sectionName in ['INSTALL.Aldec.ActiveHDL', 'INSTALL.Lattice.ActiveHDL']:
			if (len(self.Host.PoCConfig.options(sectionName)) != 0):
				break
		else:
			raise NotConfiguredException(
				"Neither Aldec's Active-HDL nor Active-HDL Lattice Edition are configured on this system.")

		asimSection = self.Host.PoCConfig[sectionName]
		binaryPath = Path(asimSection['BinaryDirectory'])
		version = asimSection['Version']
		self._activeHDL =		ActiveHDL(self.Host.Platform, binaryPath, version, logger=self.Logger)

	def Run(self, testbench, board, vhdlVersion="93", vhdlGenerics=None, guiMode=False):
		self._vhdlVersion =		vhdlVersion
		self._vhdlGenerics =	vhdlGenerics

		# check testbench database for the given testbench		
		self._LogQuiet("Testbench: {0!s}".format(testbench.Parent, **Init.Foreground))

		# setup all needed paths to execute fuse
		self._CreatePoCProject(testbench, board)
		self._AddFileListFile(testbench.FilesFile)
		
		self._RunCompile(testbench)

		if (not self._guiMode):
			self._RunSimulation(testbench)
		else:
			raise SimulatorException("GUI mode is not supported for Active-HDL.")
			# self._RunSimulationWithGUI(testbenchName)

		if (testbench.Result is SimulationResult.Passed):				self._LogQuiet("  {GREEN}[PASSED]{NOCOLOR}".format(**Init.Foreground))
		elif (testbench.Result is SimulationResult.NoAsserts):	self._LogQuiet("  {YELLOW}[NO ASSERTS]{NOCOLOR}".format(**Init.Foreground))
		elif (testbench.Result is SimulationResult.Failed):			self._LogQuiet("  {RED}[FAILED]{NOCOLOR}".format(**Init.Foreground))
		elif (testbench.Result is SimulationResult.Error):			self._LogQuiet("  {RED}[ERROR]{NOCOLOR}".format(**Init.Foreground))
		
	def _RunCompile(self, testbench):
		self._LogNormal("Running VHDL compiler for every vhdl file...")
		
		# create a ActiveHDLVHDLCompiler instance
		alib = self._activeHDL.GetVHDLLibraryTool()

		for lib in self._pocProject.VHDLLibraries:
			alib.Parameters[alib.SwitchLibraryName] = lib.Name
			try:
				alib.CreateLibrary()
			except ActiveHDLException as ex:
				raise SimulatorException("Error creating VHDL library '{0}'.".format(lib.Name)) from ex
			if alib.HasErrors:
				raise SimulatorException("Error creating VHDL library '{0}'.".format(lib.Name))

		# create a ActiveHDLVHDLCompiler instance
		acom = self._activeHDL.GetVHDLCompiler()
		if (self._vhdlVersion == VHDLVersion.VHDL87):			acom.Parameters[acom.SwitchVHDLVersion] =	"87"
		elif (self._vhdlVersion == VHDLVersion.VHDL93):		acom.Parameters[acom.SwitchVHDLVersion] =	"93"
		elif (self._vhdlVersion == VHDLVersion.VHDL02):		acom.Parameters[acom.SwitchVHDLVersion] =	"2002"
		elif (self._vhdlVersion == VHDLVersion.VHDL08):		acom.Parameters[acom.SwitchVHDLVersion] =	"2008"

		# run acom compile for each VHDL file
		for file in self._pocProject.Files(fileType=FileTypes.VHDLSourceFile):
			if (not file.Path.exists()):									raise SimulatorException("Can not analyse '{0!s}'.".format(file.Path)) from FileNotFoundError(str(file.Path))
			acom.Parameters[acom.SwitchVHDLLibrary] =	file.LibraryName
			acom.Parameters[acom.ArgSourceFile] =			file.Path
			# set a per file log-file with '-l', 'vcom.log',
			try:
				acom.Compile()
			except ActiveHDLException as ex:
				raise SimulatorException("Error while compiling '{0!s}'.".format(file.Path)) from ex
			if acom.HasErrors:
				raise SimulatorException("Error while compiling '{0!s}'.".format(file.Path))


	def _RunSimulation(self, testbench):
		self._LogNormal("Running simulation...")
		
		tclBatchFilePath =		self.Host.Directories.Root / self.Host.PoCConfig[testbench.ConfigSectionName]['aSimBatchScript']
		
		# create a ActiveHDLSimulator instance
		aSim = self._activeHDL.GetSimulator()
		aSim.Parameters[aSim.SwitchBatchCommand] = "asim -lib {0} {1}; run -all; bye".format(VHDL_TESTBENCH_LIBRARY_NAME, testbench.ModuleName)

		# aSim.Optimization =			True
		# aSim.TimeResolution =		"1fs"
		# aSim.ComanndLineMode =	True
		# aSim.BatchCommand =			"do {0}".format(str(tclBatchFilePath))
		# aSim.TopLevel =					"{0}.{1}".format(VHDLTestbenchLibraryName, testbenchName)
		try:
			testbench.Result = aSim.Simulate()
		except ActiveHDLException as ex:
			raise SimulatorException("Error while simulating '{0}.{1}'.".format(VHDL_TESTBENCH_LIBRARY_NAME, testbench.ModuleName)) from ex
		if aSim.HasErrors:
			raise SimulatorException("Error while simulating '{0}.{1}'.".format(VHDL_TESTBENCH_LIBRARY_NAME, testbench.ModuleName))

	def _RunSimulationWithGUI(self, testbench):
		self._LogNormal("Running simulation...")
	
		tclGUIFilePath =			self.Host.Directories.Root / self.Host.PoCConfig[testbench.ConfigSectionName]['aSimGUIScript']
		tclWaveFilePath =			self.Host.Directories.Root / self.Host.PoCConfig[testbench.ConfigSectionName]['aSimWaveScript']
		
		# create a ActiveHDLSimulator instance
		aSim = self._activeHDL.GetSimulator()
		aSim.Optimization =		True
		aSim.TimeResolution =	"1fs"
		aSim.Title =					testbench.ModuleName
	
		if (tclWaveFilePath.exists()):
			self._LogDebug("Found waveform script: '{0!s}'".format(tclWaveFilePath))
			aSim.BatchCommand =	"do {0!s}; do {1!s}".format(tclWaveFilePath, tclGUIFilePath)
		else:
			self._LogDebug("Didn't find waveform script: '{0!s}'. Loading default commands.".format(tclWaveFilePath))
			aSim.BatchCommand =	"add wave *; do {0!s}".format(tclGUIFilePath)

		aSim.TopLevel =		"{0}.{1}".format(VHDL_TESTBENCH_LIBRARY_NAME, testbench.ModuleName)
		aSim.Simulate()
