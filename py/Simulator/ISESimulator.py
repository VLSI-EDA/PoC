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
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module Simulator.ISESimulator")


# load dependencies
from pathlib                    import Path

from Base.Project               import ToolChain, Tool
from Base.Simulator             import SimulatorException, Simulator as BaseSimulator, VHDL_TESTBENCH_LIBRARY_NAME, SkipableSimulatorException
from ToolChains.Xilinx.Xilinx   import XilinxProjectExportMixIn
from ToolChains.Xilinx.ISE      import ISE, ISESimulator, ISEException


class Simulator(BaseSimulator, XilinxProjectExportMixIn):
	_TOOL_CHAIN =            ToolChain.Xilinx_ISE
	_TOOL =                  Tool.Xilinx_iSim

	def __init__(self, host, dryRun, guiMode):
		super().__init__(host, dryRun)
		XilinxProjectExportMixIn.__init__(self)

		self._guiMode =       guiMode
		self._vhdlGenerics =  None
		self._toolChain =     None

		iseFilesDirectoryName =         host.PoCConfig['CONFIG.DirectoryNames']['ISESimulatorFiles']
		self.Directories.Working =      host.Directories.Temp / iseFilesDirectoryName
		self.Directories.PreCompiled =  host.Directories.PreCompiled / iseFilesDirectoryName

		self._PrepareSimulationEnvironment()
		self._PrepareSimulator()

	def _PrepareSimulator(self):
		# create the Xilinx ISE executable factory
		self.LogVerbose("Preparing ISE simulator.")
		iseSection =  self.Host.PoCConfig['INSTALL.Xilinx.ISE']
		version =     iseSection['Version']
		binaryPath =  Path(iseSection['BinaryDirectory'])
		self._toolChain = ISE(self.Host.Platform, self.DryRun, binaryPath, version, logger=self.Logger)

	def _RunElaboration(self, testbench):
		exeFilePath = self.Directories.Working / (testbench.ModuleName + ".exe")
		prjFilePath = self.Directories.Working / (testbench.ModuleName + ".prj")
		self._WriteXilinxProjectFile(prjFilePath, "iSim")

		# create a ISELinker instance
		fuse = self._toolChain.GetFuse()
		fuse.Parameters[fuse.FlagIncremental] =       True
		fuse.Parameters[fuse.SwitchTimeResolution] =  "1fs"
		fuse.Parameters[fuse.SwitchMultiThreading] =  "4"
		fuse.Parameters[fuse.FlagRangeCheck] =        True
		fuse.Parameters[fuse.SwitchProjectFile] =     str(prjFilePath)
		fuse.Parameters[fuse.SwitchOutputFile] =      str(exeFilePath)
		fuse.Parameters[fuse.ArgTopLevel] =           "{0}.{1}".format(VHDL_TESTBENCH_LIBRARY_NAME, testbench.ModuleName)

		try:
			fuse.Link()
		except ISEException as ex:
			raise SimulatorException("Error while analysing '{0!s}'.".format(prjFilePath)) from ex
		if fuse.HasErrors:
			raise SkipableSimulatorException("Error while analysing '{0!s}'.".format(prjFilePath))

	def _RunSimulation(self, testbench):
		iSimLogFilePath =   self.Directories.Working / (testbench.ModuleName + ".iSim.log")
		exeFilePath =       self.Directories.Working / (testbench.ModuleName + ".exe")
		tclBatchFilePath =  self.Host.Directories.Root / self.Host.PoCConfig[testbench.ConfigSectionName]['iSimBatchScript']
		tclGUIFilePath =    self.Host.Directories.Root / self.Host.PoCConfig[testbench.ConfigSectionName]['iSimGUIScript']
		wcfgFilePath =      self.Host.Directories.Root / self.Host.PoCConfig[testbench.ConfigSectionName]['iSimWaveformConfigFile']

		# create a ISESimulator instance
		iSim = ISESimulator(self._host.Platform, self._host.DryRun, exeFilePath, logger=self.Logger)
		iSim.Parameters[iSim.SwitchLogFile] =         str(iSimLogFilePath)

		if (not self._guiMode):
			iSim.Parameters[iSim.SwitchTclBatchFile] =  str(tclBatchFilePath)
		else:
			iSim.Parameters[iSim.SwitchTclBatchFile] =  str(tclGUIFilePath)
			iSim.Parameters[iSim.FlagGuiMode] =         True

			# if iSim save file exists, load it's settings
			if wcfgFilePath.exists():
				self.LogDebug("Found waveform config file: '{0!s}'".format(wcfgFilePath))
				iSim.Parameters[iSim.SwitchWaveformFile] =  str(wcfgFilePath)
			else:
				self.LogDebug("Didn't find waveform config file: '{0!s}'".format(wcfgFilePath))

		testbench.Result = iSim.Simulate()
