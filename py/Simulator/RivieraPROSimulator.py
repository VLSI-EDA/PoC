# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#
# Python Module:    TODO
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
# load dependencies
from pathlib                      import Path
from textwrap                     import dedent

from Base.Executable              import DryRunException
from Base.Project                 import FileTypes, ToolChain, Tool
from DataBase.Config              import Vendors
from ToolChain.Aldec.RivieraPRO   import RivieraPRO, RivieraPROException
from Simulator                    import VHDL_TESTBENCH_LIBRARY_NAME, SimulatorException, SkipableSimulatorException, SimulationSteps, Simulator as BaseSimulator


class Simulator(BaseSimulator):
	_TOOL_CHAIN =   ToolChain.Aldec_RivieraPRO
	_TOOL =         Tool.Aldec_rPro

	def __init__(self, host, dryRun, simulationSteps):
		# A separate elaboration step is not implemented in RivieraPRO
		simulationSteps &= ~SimulationSteps.Elaborate
		super().__init__(host, dryRun, simulationSteps)

		vSimSimulatorFiles =            host.PoCConfig['CONFIG.DirectoryNames']['RivieraPROFiles']
		self.Directories.Working =      host.Directories.Temp / vSimSimulatorFiles
		self.Directories.PreCompiled =  host.Directories.PreCompiled / vSimSimulatorFiles

		if (SimulationSteps.CleanUpBefore in self._simulationSteps):
			pass

		if (SimulationSteps.Prepare in self._simulationSteps):
			self._PrepareSimulationEnvironment()
			self._PrepareSimulator()

	def _PrepareSimulator(self):
		# create the RivieraPRO executable factory
		self.LogVerbose("Preparing Mentor simulator.")
		# for sectionName in ['INSTALL.Mentor.QuestaSim', 'INSTALL.Mentor.RivieraPRO', 'INSTALL.Altera.RivieraPRO']:
		# 	if (len(self.Host.PoCConfig.options(sectionName)) != 0):
		# 		break
		# else:
		# XXX: check SectionName if RivieraPRO is configured
		# 	raise NotConfiguredException(
		# 		"Neither Mentor Graphics RivieraPRO, RivieraPRO PE nor RivieraPRO Altera-Edition are configured on this system.")

		# questaSection = self.Host.PoCConfig[sectionName]
		# binaryPath = Path(questaSection['BinaryDirectory'])
		# version = questaSection['Version']

		binaryPath = Path(self.Host.PoCConfig['INSTALL.Aldec.RivieraPRO']['BinaryDirectory'])
		version = self.Host.PoCConfig['INSTALL.Aldec.RivieraPRO']['Version']
		self._toolChain = RivieraPRO(self.Host.Platform, self.DryRun, binaryPath, version, logger=self.Logger)

	def Run(self, testbench, board, vhdlVersion, vhdlGenerics=None):
		# TODO: refactor into a RivieraPRO module, shared by RivieraPRO and Cocotb (-> MixIn class)?
		# select RivieraPRO.ini
		self._RivieraPROIniPath = self.Directories.PreCompiled
		if board.Device.Vendor is Vendors.Altera:
			self._RivieraPROIniPath /= self.Host.PoCConfig['CONFIG.DirectoryNames']['AlteraSpecificFiles']
		elif board.Device.Vendor is Vendors.Lattice:
			self._RivieraPROIniPath /= self.Host.PoCConfig['CONFIG.DirectoryNames']['LatticeSpecificFiles']
		elif board.Device.Vendor is Vendors.Xilinx:
			self._RivieraPROIniPath /= self.Host.PoCConfig['CONFIG.DirectoryNames']['XilinxSpecificFiles']

		# self._RivieraPROIniPath /= "RivieraPRO.ini"
		# if not self._RivieraPROIniPath.exists():
		# 	raise SimulatorException("RivieraPRO ini file '{0!s}' not found.".format(self._RivieraPROIniPath)) \
		# 		from FileNotFoundError(str(self._RivieraPROIniPath))

		super().Run(testbench, board, vhdlVersion, vhdlGenerics)

	def _RunAnalysis(self, _):
		# create a RivieraPROVHDLCompiler instance
		vlib = self._toolChain.GetVHDLLibraryTool()
		for lib in self._pocProject.VHDLLibraries:
			vlib.Parameters[vlib.SwitchLibraryName] = lib.Name
			try:
				vlib.CreateLibrary()
			except DryRunException:
				pass

		# create a RivieraPROVHDLCompiler instance
		vcom = self._toolChain.GetVHDLCompiler()
		vcom.Parameters[vcom.SwitchVHDLVersion] =       repr(self._vhdlVersion)

		# run vcom compile for each VHDL file
		for file in self._pocProject.Files(fileType=FileTypes.VHDLSourceFile):
			if (not file.Path.exists()):              raise SimulatorException("Cannot analyse '{0!s}'.".format(file.Path)) from FileNotFoundError(str(file.Path))

			vcomLogFile = self.Directories.Working / (file.Path.stem + ".vcom.log")
			vcom.Parameters[vcom.SwitchVHDLLibrary] = file.LibraryName
			vcom.Parameters[vcom.ArgSourceFile] =     file.Path

			try:
				vcom.Compile()
			except DryRunException:
				pass
			except RivieraPROException as ex:
				raise SimulatorException("Error while compiling '{0!s}'.".format(file.Path)) from ex
			if vcom.HasErrors:
				raise SkipableSimulatorException("Error while compiling '{0!s}'.".format(file.Path))

	def _RunSimulation(self, testbench):
		if (SimulationSteps.ShowWaveform in self._simulationSteps):
			return self._RunSimulationWithGUI(testbench)

		tclBatchFilePath =        self.Host.Directories.Root / self.Host.PoCConfig[testbench.ConfigSectionName]['vSimBatchScript']
		tclDefaultBatchFilePath = self.Host.Directories.Root / self.Host.PoCConfig[testbench.ConfigSectionName]['vSimDefaultBatchScript']

		# create a RivieraPROSimulator instance
		vsim = self._toolChain.GetSimulator()
		vsim.Parameters[vsim.SwitchTimeResolution] = "1fs"
		vsim.Parameters[vsim.FlagCommandLineMode] = True
		vsim.Parameters[vsim.SwitchTopLevel] = "{0}.{1}".format(VHDL_TESTBENCH_LIBRARY_NAME, testbench.ModuleName)

		# find a Tcl batch script for the BATCH mode
		vsimBatchCommand = ""
		if (tclBatchFilePath.exists()):
			self.LogDebug("Found Tcl script for BATCH mode: '{0!s}'".format(tclBatchFilePath))
			vsimBatchCommand += "do {0};".format(tclBatchFilePath.as_posix())
		elif (tclDefaultBatchFilePath.exists()):
			self.LogDebug("Falling back to default Tcl script for BATCH mode: '{0!s}'".format(tclDefaultBatchFilePath))
			vsimBatchCommand += "do {0};".format(tclDefaultBatchFilePath.as_posix())
		else:
			raise RivieraPROException("No Tcl batch script for BATCH mode found.") \
				from FileNotFoundError(str(tclDefaultBatchFilePath))

		vsim.Parameters[vsim.SwitchBatchCommand] = vsimBatchCommand

		try:
			testbench.Result = vsim.Simulate()
		except DryRunException:
			pass

	def _RunSimulationWithGUI(self, testbench):
		tclGUIFilePath = self.Host.Directories.Root / self.Host.PoCConfig[testbench.ConfigSectionName]['vSimGUIScript']
		tclWaveFilePath = self.Host.Directories.Root / self.Host.PoCConfig[testbench.ConfigSectionName]['vSimWaveScript']
		tclDefaultGUIFilePath = self.Host.Directories.Root / self.Host.PoCConfig[testbench.ConfigSectionName]['vSimDefaultGUIScript']
		tclDefaultWaveFilePath = self.Host.Directories.Root / self.Host.PoCConfig[testbench.ConfigSectionName]['vSimDefaultWaveScript']

		# create a RivieraPROSimulator instance
		vsim = self._toolChain.GetSimulator()
		vsim.Parameters[vsim.SwitchRivieraPROIniFile] = self._RivieraPROIniPath.as_posix()
		vsim.Parameters[vsim.SwitchTimeResolution] = "1fs"
		vsim.Parameters[vsim.SwitchTopLevel] = "{0}.{1}".format(VHDL_TESTBENCH_LIBRARY_NAME, testbench.ModuleName)

		vsimDefaultWaveCommands = "add wave *"

		# find a Tcl batch script to load predefined signals in the waveform window
		vsimBatchCommand = ""
		self.LogDebug("'{0!s}'\n    '{1!s}'".format(tclWaveFilePath, self.Host.Directories.Root))
		if (tclWaveFilePath != self.Host.Directories.Root):
			if (tclWaveFilePath.exists()):
				self.LogDebug("Found waveform script: '{0!s}'".format(tclWaveFilePath))
				vsimBatchCommand = "do {0};".format(tclWaveFilePath.as_posix())
			elif (tclDefaultWaveFilePath != self.Host.Directories.Root):
				if (tclDefaultWaveFilePath.exists()):
					self.LogDebug("Found default waveform script: '{0!s}'".format(tclDefaultWaveFilePath))
					vsimBatchCommand = "do {0};".format(tclDefaultWaveFilePath.as_posix())
				else:
					self.LogDebug("Couldn't find default waveform script: '{0!s}'. Loading default command '{1}'.".format(tclDefaultWaveFilePath, vsimDefaultWaveCommands))
					vsimBatchCommand = "{0};".format(vsimDefaultWaveCommands)
			else:
				self.LogDebug("Couldn't find waveform script: '{0!s}'. Loading default command '{1}'.".format(tclWaveFilePath, vsimDefaultWaveCommands))
				vsim.Parameters[vsim.SwitchBatchCommand] = "{0};".format(vsimDefaultWaveCommands)
		elif (tclDefaultWaveFilePath != self.Host.Directories.Root):
			if (tclDefaultWaveFilePath.exists()):
				self.LogDebug("Falling back to default waveform script: '{0!s}'".format(tclDefaultWaveFilePath))
				vsimBatchCommand = "do {0};".format(tclDefaultWaveFilePath.as_posix())
			else:
				self.LogDebug("Couldn't find default waveform script: '{0!s}'. Loading default command '{1}'.".format(tclDefaultWaveFilePath, vsimDefaultWaveCommands))
				vsimBatchCommand = "{0};".format(vsimDefaultWaveCommands)
		else:
			self.LogWarning("No waveform script specified. Loading default command '{0}'.".format(vsimDefaultWaveCommands))
			vsimBatchCommand = "{0};".format(vsimDefaultWaveCommands)

		# find a Tcl batch script for the GUI mode
		if (tclGUIFilePath.exists()):
			self.LogDebug("Found Tcl script for GUI mode: '{0!s}'".format(tclGUIFilePath))
			vsimRunScript = tclGUIFilePath.as_posix()
			vsimBatchCommand += "do {0};".format(vsimRunScript)
		elif (tclDefaultGUIFilePath.exists()):
			self.LogDebug("Falling back to default Tcl script for GUI mode: '{0!s}'".format(tclDefaultGUIFilePath))
			vsimRunScript = tclDefaultGUIFilePath.as_posix()
			vsimBatchCommand += "do {0};".format(vsimRunScript)
		else:
			raise RivieraPROException("No Tcl batch script for GUI mode found.") \
				from FileNotFoundError(str(tclDefaultGUIFilePath))

		vsim.Parameters[vsim.SwitchBatchCommand] = vsimBatchCommand

		try:
			testbench.Result = vsim.Simulate()
		except DryRunException:
			pass
