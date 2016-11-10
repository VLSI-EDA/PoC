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
# entry point

if __name__ != "__main__":
	# place library initialization code here
	pass
else:
	from lib.Functions import Exit

	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module Simulator.CocotbSimulator")


# load dependencies
import shutil
from textwrap                import dedent

from Base.Project            import FileTypes, ToolChain, Tool
from Base.Simulator          import SimulatorException, Simulator as BaseSimulator
from DataBase.Config              import Vendors
from DataBase.Entity              import WildCard
from ToolChains.GNU          import Make


class Simulator(BaseSimulator):
	_TOOL_CHAIN =            ToolChain.Cocotb
	_TOOL =                  Tool.Cocotb_QuestaSim
	_COCOTB_SIMBUILD_DIRECTORY = "sim_build"

	def __init__(self, host, dryRun, guiMode):
		super().__init__(host, dryRun)

		self._guiMode =       guiMode

		configSection =                 host.PoCConfig['CONFIG.DirectoryNames']
		self.Directories.Working =      host.Directories.Temp / configSection['CocotbFiles']
		self.Directories.PreCompiled =  host.Directories.PreCompiled / configSection['QuestaSimFiles']

		self._PrepareSimulationEnvironment()
		self._PrepareSimulator()

	def _PrepareSimulator(self):
		# create the Cocotb executable factory
		self.LogVerbose("Preparing Cocotb simulator.")

	def RunAll(self, fqnList, *args, **kwargs):
		self._testSuite.StartTimer()
		try:
			for fqn in fqnList:
				entity = fqn.Entity
				if (isinstance(entity, WildCard)):
					for testbench in entity.GetCocoTestbenches():
						self.TryRun(testbench, *args, **kwargs)
				else:
					testbench = entity.CocoTestbench
					self.TryRun(testbench, *args, **kwargs)
		except KeyboardInterrupt:
			self.LogError("Received a keyboard interrupt.")
		finally:
			self._testSuite.StopTimer()

		self.PrintOverallSimulationReport()

		return self._testSuite.IsAllPassed

	def _RunSimulation(self, testbench): # mccabe:disable=MC0001
		# select modelsim.ini from precompiled
		precompiledModelsimIniPath = self.Directories.PreCompiled
		device_vendor = self._pocProject.Board.Device.Vendor
		if device_vendor is Vendors.Altera:
			precompiledModelsimIniPath /= self.Host.PoCConfig['CONFIG.DirectoryNames']['AlteraSpecificFiles']
		elif device_vendor is Vendors.Lattice:
			precompiledModelsimIniPath /= self.Host.PoCConfig['CONFIG.DirectoryNames']['LatticeSpecificFiles']
		elif device_vendor is Vendors.Xilinx:
			precompiledModelsimIniPath /= self.Host.PoCConfig['CONFIG.DirectoryNames']['XilinxSpecificFiles']

		precompiledModelsimIniPath /= "modelsim.ini"
		if not precompiledModelsimIniPath.exists():
			raise SimulatorException("Modelsim ini file '{0!s}' not found.".format(precompiledModelsimIniPath)) \
				from FileNotFoundError(str(precompiledModelsimIniPath))

		simBuildPath = self.Directories.Working / self._COCOTB_SIMBUILD_DIRECTORY
		# create temporary directory for Cocotb if not existent
		if (not (simBuildPath).exists()):
			self.LogVerbose("Creating build directory for simulator files.")
			self.LogDebug("Build directory: {0!s}".format(simBuildPath))
			try:
				simBuildPath.mkdir(parents=True)
			except OSError as ex:
				raise SimulatorException("Error while creating '{0!s}'.".format(simBuildPath)) from ex

		# write local modelsim.ini
		modelsimIniPath = simBuildPath / "modelsim.ini"
		if modelsimIniPath.exists():
			try:
				modelsimIniPath.unlink()
			except OSError as ex:
				raise SimulatorException("Error while deleting '{0!s}'.".format(modelsimIniPath)) from ex

		with modelsimIniPath.open('w') as fileHandle:
			fileContent = dedent("""\
				[Library]
				others = {0!s}
				""").format(precompiledModelsimIniPath)
			fileHandle.write(fileContent)

		#
		self.LogNormal("Running simulation...")
		cocotbTemplateFilePath = self.Host.Directories.Root / \
															self.Host.PoCConfig[testbench.ConfigSectionName]['CocotbMakefile'] # depends on testbench
		topLevel =      testbench.TopLevel
		cocotbModule =  testbench.ModuleName

		# create one VHDL line for each VHDL file
		vhdlSources = ""
		for file in self._pocProject.Files(fileType=FileTypes.VHDLSourceFile):
			if (not file.Path.exists()):
				raise SimulatorException("Cannot add '{0!s}' to Cocotb Makefile.".format(file.Path)) \
					from FileNotFoundError(str(file.Path))
			vhdlSources += str(file.Path) + " "

		# copy Cocotb (Python) files to temp directory
		self.LogVerbose("Copying Cocotb (Python) files into temporary directory.")
		cocotbTempDir = str(self.Directories.Working)
		for file in self._pocProject.Files(fileType=FileTypes.CocotbSourceFile):
			if (not file.Path.exists()):
				raise SimulatorException("Cannot copy '{0!s}' to Cocotb temp directory.".format(file.Path)) \
					from FileNotFoundError(str(file.Path))
			self.LogDebug("copy {0!s} {1}".format(file.Path, cocotbTempDir))
			try:
				shutil.copy(str(file.Path), cocotbTempDir)
			except OSError as ex:
				raise SimulatorException("Error while copying '{0!s}'.".format(file.Path)) from ex

		# read/write Makefile template
		self.LogVerbose("Generating Makefile...")
		self.LogDebug("Reading Cocotb Makefile template file from '{0!s}'".format(cocotbTemplateFilePath))
		with cocotbTemplateFilePath.open('r') as fileHandle:
			cocotbMakefileContent = fileHandle.read()

		cocotbMakefileContent = cocotbMakefileContent.format(PoCRootDirectory=str(self.Host.Directories.Root),
																													VHDLSources=vhdlSources,
																													TopLevel=topLevel, CocotbModule=cocotbModule)

		cocotbMakefilePath = self.Directories.Working / "Makefile"
		self.LogDebug("Writing Cocotb Makefile to '{0!s}'".format(cocotbMakefilePath))
		with cocotbMakefilePath.open('w') as fileHandle:
			fileHandle.write(cocotbMakefileContent)

		# execute make
		make = Make(self.Host.Platform, self.DryRun, logger=self.Logger)
		if self._guiMode: make.Parameters[Make.SwitchGui] = 1
		testbench.Result = make.RunCocotb()
