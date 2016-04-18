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
	# place library initialization code here
	pass
else:
	from lib.Functions import Exit

	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module Simulator.ISESimulator")

# load dependencies
from configparser							import NoSectionError
from colorama									import Fore as Foreground

from lib.Functions						import Init
from Base.Project							import FileTypes, VHDLVersion, Environment, ToolChain, Tool
from Base.Simulator						import SimulatorException, Simulator as BaseSimulator, VHDL_TESTBENCH_LIBRARY_NAME
from ToolChains.Xilinx.Xilinx	import XilinxProjectExportMixIn
from ToolChains.Xilinx.ISE		import ISE, ISESimulator, ISEException


class Simulator(BaseSimulator, XilinxProjectExportMixIn):
	_TOOL_CHAIN =						ToolChain.Xilinx_ISE
	_TOOL =									Tool.Xilinx_iSim

	def __init__(self, host, showLogs, showReport, guiMode):
		super().__init__(host, showLogs, showReport)
		XilinxProjectExportMixIn.__init__(self)

		self._guiMode =				guiMode

		self._entity =				None
		self._testbenchFQN =	None
		self._vhdlGenerics =	None

		self._ise =						None

		self._PrepareSimulationEnvironment()

	@property
	def TemporaryPath(self):
		return self._tempPath

	def _PrepareSimulationEnvironment(self):
		self._LogNormal("preparing simulation environment...")
		self._tempPath = self.Host.Directories["iSimTemp"]
		super()._PrepareSimulationEnvironment()

	def PrepareSimulator(self, binaryPath, version):
		# create the Xilinx ISE executable factory
		self._LogVerbose("  Preparing GHDL simulator.")
		self._ise = ISE(self.Host.Platform, binaryPath, version, logger=self.Logger)

	def Run(self, testbench, board, vhdlVersion=None, vhdlGenerics=None, guiMode=False):
		self._LogQuiet("Testbench: {YELLOW}{0!s}{RESET}".format(testbench.Parent, **Init.Foreground))

		self._vhdlVersion =		VHDLVersion.VHDL93
		self._vhdlGenerics =	vhdlGenerics

		# setup all needed paths to execute fuse
		self._CreatePoCProject(testbench, board)
		self._AddFileListFile(testbench.FilesFile)
		
		# self._RunCompile(testbenchName)
		self._RunLink(testbench)
		self._RunSimulation(testbench)

	def _RunCompile(self, testbench):
		self._LogNormal("  compiling source files...")
		
		prjFilePath = self._tempPath / (testbench.ModuleName + ".prj")
		self._WriteXilinxProjectFile(prjFilePath, "iSim", self._vhdlVersion)

		# create a VivadoVHDLCompiler instance
		vhcomp = self._ise.GetVHDLCompiler()
		vhcomp.Compile(str(prjFilePath))

	def _RunLink(self, testbench):
		self._LogNormal("  running fuse...")
		
		exeFilePath =	self._tempPath / (testbench.ModuleName + ".exe")
		prjFilePath = self._tempPath / (testbench.ModuleName + ".prj")
		self._WriteXilinxProjectFile(prjFilePath, "iSim")

		# create a ISELinker instance
		fuse = self._ise.GetFuse()
		fuse.Parameters[fuse.FlagIncremental] =				True
		fuse.Parameters[fuse.SwitchTimeResolution] =	"1fs"
		fuse.Parameters[fuse.SwitchMultiThreading] =	"4"
		fuse.Parameters[fuse.FlagRangeCheck] =				True
		fuse.Parameters[fuse.SwitchProjectFile] =			str(prjFilePath)
		fuse.Parameters[fuse.SwitchOutputFile] =			str(exeFilePath)
		fuse.Parameters[fuse.ArgTopLevel] =						"{0}.{1}".format(VHDL_TESTBENCH_LIBRARY_NAME, testbench.ModuleName)

		try:
			fuse.Link()
		except ISEException as ex:
			raise SimulatorException("Error while analysing '{0!s}'.".format(prjFilePath)) from ex

		if fuse.HasErrors:
			raise SimulatorException("Error while analysing '{0!s}'.".format(prjFilePath))
	
	def _RunSimulation(self, testbench):
		self._LogNormal("  running simulation...")
		
		iSimLogFilePath =		self._tempPath / (testbench.ModuleName + ".iSim.log")
		exeFilePath =				self._tempPath / (testbench.ModuleName + ".exe")
		tclBatchFilePath =	self.Host.Directories["PoCRoot"] / self.Host.PoCConfig[testbench.ConfigSectionName]['iSimBatchScript']
		tclGUIFilePath =		self.Host.Directories["PoCRoot"] / self.Host.PoCConfig[testbench.ConfigSectionName]['iSimGUIScript']
		wcfgFilePath =			self.Host.Directories["PoCRoot"] / self.Host.PoCConfig[testbench.ConfigSectionName]['iSimWaveformConfigFile']

		# create a ISESimulator instance
		iSim = ISESimulator(exeFilePath, logger=self.Logger)
		iSim.Parameters[iSim.SwitchLogFile] =					str(iSimLogFilePath)

		if (not self._guiMode):
			iSim.Parameters[iSim.SwitchTclBatchFile] =	str(tclBatchFilePath)
		else:
			iSim.Parameters[iSim.SwitchTclBatchFile] =	str(tclGUIFilePath)
			iSim.Parameters[iSim.FlagGuiMode] =					True

			# if iSim save file exists, load it's settings
			if wcfgFilePath.exists():
				self._LogDebug("    Found waveform config file: '{0!s}'".format(wcfgFilePath))
				iSim.Parameters[iSim.SwitchWaveformFile] =	str(wcfgFilePath)
			else:
				self._LogDebug("    Didn't find waveform config file: '{0!s}'".format(wcfgFilePath))

		iSim.Simulate()

		# print()
		# if (not self.__guiMode):
			# try:
				# result = self.checkSimulatorOutput(simulatorLog)
				
				# if (result == True):
					# print("Testbench '%s': PASSED" % testbenchName)
				# else:
					# print("Testbench '%s': FAILED" % testbenchName)
					
			# except SimulatorException as ex:
				# raise TestbenchException("PoC.ns.module", testbenchName, "'SIMULATION RESULT = [PASSED|FAILED]' not found in simulator output.") from ex
