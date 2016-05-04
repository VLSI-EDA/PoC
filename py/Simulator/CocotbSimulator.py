# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
# Authors:					Patrick Lehmann
#                   Martin Zabel
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
from textwrap import dedent

from PoC.Config import Vendors

if __name__ != "__main__":
	# place library initialization code here
	pass
else:
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module Simulator.CocotbSimulator")


# load dependencies
import shutil

from lib.Functions					import Init
from Base.Project						import FileTypes, ToolChain, Tool
from Base.Simulator					import SimulatorException, Simulator as BaseSimulator
from PoC.Entity							import WildCard
from ToolChains.GNU					import Make


class Simulator(BaseSimulator):
	_TOOL_CHAIN =						ToolChain.Cocotb
	_TOOL =									Tool.Cocotb_QuestaSim
	_COCOTB_SIMBUILD_DIRECTORY = "sim_build"

	class __Directories__:
		Working =			None
		PoCRoot =			None
		PreCompiled =	None

	def __init__(self, host, showLogs, showReport, guiMode):
		super().__init__(host, showLogs, showReport)

		self._guiMode =				guiMode

		self._entity =				None
		self._testbenchFQN =	None

		self._directories =		self.__Directories__()

		self._LogNormal("preparing simulation environment...")
		self._PrepareSimulationEnvironment()

	@property
	def Directories(self):
		return self._directories

	def _PrepareSimulationEnvironment(self):
		self._LogNormal("preparing simulation environment...")
		super()._PrepareSimulationEnvironment()

		simBuildPath = self.Directories.Working / self._COCOTB_SIMBUILD_DIRECTORY
		# create temporary directory for Cocotb if not existent
		if (not (simBuildPath).exists()):
			self._LogVerbose("Creating build directory for simulator files.")
			self._LogDebug("Build directory: {0!s}".format(simBuildPath))
			simBuildPath.mkdir(parents=True)

	def PrepareSimulator(self):
		# create the Cocotb executable factory
		self._LogVerbose("Preparing Cocotb simulator.")

	def RunAll(self, fqnList, *args, **kwargs):
		for fqn in fqnList:
			entity = fqn.Entity
			if (isinstance(entity, WildCard)):
				for testbench in entity.GetCocoTestbenches():
					try:
						self.Run(testbench, *args, **kwargs)
					except SimulatorException:
						pass
			else:
				testbench = entity.CocoTestbench
				try:
					self.Run(testbench, *args, **kwargs)
				except SimulatorException:
					pass

	def Run(self, testbench, board, **_):
		self._LogQuiet("Testbench: {0!s}".format(testbench.Parent, **Init.Foreground))

		# setup all needed paths to execute fuse
		self._CreatePoCProject(testbench, board)
		self._AddFileListFile(testbench.FilesFile)
		self._Run(testbench, board)

	def _Run(self, testbench, board):
		# select modelsim.ini from precompiled
		precompiledModelsimIniPath = self.Host.Directories["vSimPrecompiled"]
		if board.Device.Vendor is Vendors.Xilinx:
			precompiledModelsimIniPath /= "xilinx"
		elif board.Device.Vendor is Vendors.Altera:
			precompiledModelsimIniPath /= "altera"

		precompiledModelsimIniPath /= "modelsim.ini"
		if not precompiledModelsimIniPath.exists():
			raise SimulatorException("Modelsim ini file '{0!s}' not found.".format(precompiledModelsimIniPath)) \
				from FileNotFoundError(str(precompiledModelsimIniPath))

		# write local modelsim.ini
		modelsimIniPath = self.Host.Directories["CocotbTemp"] / "sim_build" / "modelsim.ini"
		if modelsimIniPath.exists(): modelsimIniPath.unlink()
		with modelsimIniPath.open('w') as fileHandle:
			fileContent = dedent("""\
				[Library]
				others = {0!s}
				""").format(precompiledModelsimIniPath)
			fileHandle.write(fileContent)

		#
		self._LogNormal("Running simulation...")
		cocotbTemplateFilePath = self.Host.Directories.Root / self.Host.PoCConfig[testbench.ConfigSectionName]['CocotbMakefile']
		topLevel =			testbench.TopLevel
		cocotbModule =	testbench.ModuleName

		# create one VHDL line for each VHDL file
		vhdlSources = ""
		for file in self._pocProject.Files(fileType=FileTypes.VHDLSourceFile):
			if (not file.Path.exists()):									raise SimulatorException("Cannot add '{0!s}' to Cocotb Makefile.".format(file.Path)) from FileNotFoundError(str(file.Path))
			vhdlSources += str(file.Path) + " "

		# copy Cocotb (Python) files to temp directory
		self._LogVerbose("Copying Cocotb (Python) files into temporary directory.")
		cocotbTempDir = str(self.Host.Directories["CocotbTemp"])
		for file in self._pocProject.Files(fileType=FileTypes.CocotbSourceFile):
			if (not file.Path.exists()):									raise SimulatorException("Cannot copy '{0!s}' to Cocotb temp directory.".format(file.Path)) from FileNotFoundError(str(file.Path))
			self._LogDebug("copy {0!s} {1!s}".format(file.Path, cocotbTempDir))
			shutil.copy(str(file.Path), cocotbTempDir)

		# read/write Makefile template
		self._LogVerbose("Generating Makefile...")
		self._LogDebug("Reading Cocotb Makefile template file from '{0!s}'".format(cocotbTemplateFilePath))
		with cocotbTemplateFilePath.open('r') as fileHandle:
			cocotbMakefileContent = fileHandle.read()

		cocotbMakefileContent = cocotbMakefileContent.format(PoCRootDirectory=str(self.Host.Directories.Root), VHDLSources=vhdlSources,
																													TopLevel=topLevel, CocotbModule=cocotbModule)

		cocotbMakefilePath = self.Host.Directories["CocotbTemp"] / "Makefile"
		self._LogDebug("Writing Cocotb Makefile to '{0!s}'".format(cocotbMakefilePath))
		with cocotbMakefilePath.open('w') as fileHandle:
			fileHandle.write(cocotbMakefileContent)

		# execute make
		make = Make(self.Host.Platform, logger=self.Host.Logger)
		if self._guiMode: make.Parameters[Make.SwitchGui] = 1
		make.Run()
