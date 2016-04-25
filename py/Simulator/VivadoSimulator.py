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
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module Simulator.VivadoSimulator")

# load dependencies
from configparser							import NoSectionError
from colorama									import Fore as Foreground

from lib.Functions						import Init
# from Base.Exceptions					import PlatformNotSupportedException, NotConfiguredException
from Base.Project							import FileTypes, VHDLVersion, Environment, ToolChain, Tool
from Base.Simulator						import SimulatorException, Simulator as BaseSimulator, VHDL_TESTBENCH_LIBRARY_NAME, SimulationResult
from Base.Logging							import Severity
from ToolChains.Xilinx.Xilinx	import XilinxProjectExportMixIn
from ToolChains.Xilinx.Vivado	import Vivado, VivadoException


class Simulator(BaseSimulator, XilinxProjectExportMixIn):
	_TOOL_CHAIN =						ToolChain.Xilinx_Vivado
	_TOOL =									Tool.Xilinx_xSim

	def __init__(self, host, showLogs, showReport, guiMode):
		super(self.__class__, self).__init__(host, showLogs, showReport)
		XilinxProjectExportMixIn.__init__(self)

		self._guiMode =				guiMode

		self._entity =				None
		self._testbenchFQN =	None
		self._vhdlVersion =		None
		self._vhdlGenerics =	None

		self._vivado =				None

		self._PrepareSimulationEnvironment()

	@property
	def TemporaryPath(self):
		return self._tempPath

	def _PrepareSimulationEnvironment(self):
		self._LogNormal("preparing simulation environment...")
		self._tempPath = self.Host.Directories["xSimTemp"]
		super()._PrepareSimulationEnvironment()

	def PrepareSimulator(self, binaryPath, version):
		# create the Vivado executable factory
		self._LogVerbose("Preparing Vivado simulator.")
		self._vivado = Vivado(self.Host.Platform, binaryPath, version, logger=self.Logger)

	def Run(self, testbench, board, vhdlVersion="93", vhdlGenerics=None, guiMode=False):
		self._LogQuiet("Testbench: {0!s}".format(testbench.Parent, **Init.Foreground))

		self._vhdlVersion =		vhdlVersion
		self._vhdlGenerics =	vhdlGenerics

		# setup all needed paths to execute fuse
		self._CreatePoCProject(testbench, board)
		self._AddFileListFile(testbench.FilesFile)
		
		# self._RunCompile(testbenchName)
		self._RunLink(testbench)
		self._RunSimulation(testbench)
		
		if (testbench.Result is SimulationResult.Passed):				self._LogQuiet("  {GREEN}[PASSED]{NOCOLOR}".format(**Init.Foreground))
		elif (testbench.Result is SimulationResult.NoAsserts):	self._LogQuiet("  {YELLOW}[NO ASSERTS]{NOCOLOR}".format(**Init.Foreground))
		elif (testbench.Result is SimulationResult.Failed):			self._LogQuiet("  {RED}[FAILED]{NOCOLOR}".format(**Init.Foreground))
		elif (testbench.Result is SimulationResult.Error):			self._LogQuiet("  {RED}[ERROR]{NOCOLOR}".format(**Init.Foreground))

	def _RunCompile(self, testbench):
		self._LogNormal("  compiling source files...")

		prjFilePath = self._tempPath / (testbench.ModuleName + ".prj")
		self._WriteXilinxProjectFile(prjFilePath, "xSim", self._vhdlVersion)

		# create a VivadoVHDLCompiler instance
		xvhcomp = self._vivado.GetVHDLCompiler()
		xvhcomp.Compile(str(prjFilePath))
		
	def _RunLink(self, testbench):
		self._LogNormal("Running xelab...")
		
		xelabLogFilePath =	self._tempPath / (testbench.ModuleName + ".xelab.log")
		prjFilePath =				self._tempPath / (testbench.ModuleName + ".prj")
		self._WriteXilinxProjectFile(prjFilePath, "xSim", self._vhdlVersion)

		# create a VivadoLinker instance
		xelab = self._vivado.GetElaborator()
		xelab.Parameters[xelab.SwitchTimeResolution] =	"1fs"	# set minimum time precision to 1 fs
		xelab.Parameters[xelab.SwitchMultiThreading] =	"off" if self.Logger.LogLevel is Severity.Debug else "auto"		# disable multithreading support in debug mode
		xelab.Parameters[xelab.FlagRangeCheck] =				True

		# xelab.Parameters[xelab.SwitchOptimization] =		"2"
		xelab.Parameters[xelab.SwitchDebug] =						"typical"
		xelab.Parameters[xelab.SwitchSnapshot] =				testbench.ModuleName

		# if (self._vhdlVersion == VHDLVersion.VHDL2008):
		# 	xelab.Parameters[xelab.SwitchVHDL2008] =			True

		# if (self.verbose):
		xelab.Parameters[xelab.SwitchVerbose] =					"1" if self.Logger.LogLevel is Severity.Debug else "0"		# set to "1" for detailed messages
		xelab.Parameters[xelab.SwitchProjectFile] =			str(prjFilePath)
		xelab.Parameters[xelab.SwitchLogFile] =					str(xelabLogFilePath)
		xelab.Parameters[xelab.ArgTopLevel] =						"{0}.{1}".format(VHDL_TESTBENCH_LIBRARY_NAME, testbench.ModuleName)

		try:
			xelab.Link()
		except VivadoException as ex:
			raise SimulatorException("Error while analysing '{0!s}'.".format(prjFilePath)) from ex

		if xelab.HasErrors:
			raise SimulatorException("Error while analysing '{0!s}'.".format(prjFilePath))

	def _RunSimulation(self, testbench):
		self._LogNormal("Running simulation...")
		
		xSimLogFilePath =		self._tempPath / (testbench.ModuleName + ".xSim.log")
		tclBatchFilePath =	self.Host.Directories["PoCRoot"] / self.Host.PoCConfig[testbench.ConfigSectionName]['xSimBatchScript']
		tclGUIFilePath =		self.Host.Directories["PoCRoot"] / self.Host.PoCConfig[testbench.ConfigSectionName]['xSimGUIScript']
		wcfgFilePath =			self.Host.Directories["PoCRoot"] / self.Host.PoCConfig[testbench.ConfigSectionName]['xSimWaveformConfigFile']

		# create a VivadoSimulator instance
		xSim = self._vivado.GetSimulator()
		xSim.Parameters[xSim.SwitchLogFile] =					str(xSimLogFilePath)

		if (not self._guiMode):
			xSim.Parameters[xSim.SwitchTclBatchFile] =	str(tclBatchFilePath)
		else:
			xSim.Parameters[xSim.SwitchTclBatchFile] =	str(tclGUIFilePath)
			xSim.Parameters[xSim.FlagGuiMode] =					True

			# if xSim save file exists, load it's settings
			if wcfgFilePath.exists():
				self._LogDebug("Found waveform config file: '{0!s}'".format(wcfgFilePath))
				xSim.Parameters[xSim.SwitchWaveformFile] =	str(wcfgFilePath)
			else:
				self._LogDebug("Didn't find waveform config file: '{0!s}'".format(wcfgFilePath))

		xSim.Parameters[xSim.SwitchSnapshot] = testbench.ModuleName
		testbench.Result = xSim.Simulate()

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
	
