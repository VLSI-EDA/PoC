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
from Base.Logging import Severity

if __name__ != "__main__":
	# place library initialization code here
	pass
else:
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module Simulator.GHDLSimulator")

# load dependencies
from configparser						import NoSectionError
from colorama								import Fore as Foreground

# from Base.Exceptions				import NotConfiguredException, PlatformNotSupportedException
from lib.Functions					import Init
from Base.Project						import FileTypes, VHDLVersion, Environment, ToolChain, Tool
from Base.Simulator					import SimulatorException, Simulator as BaseSimulator, VHDL_TESTBENCH_LIBRARY_NAME, SimulationResult
from ToolChains.GHDL				import GHDL, GHDLException
from ToolChains.GTKWave			import GTKWave


class Simulator(BaseSimulator):
	_TOOL_CHAIN =						ToolChain.GHDL_GTKWave
	_TOOL =									Tool.GHDL

	def __init__(self, host, showLogs, showReport, guiMode):
		super(self.__class__, self).__init__(host, showLogs, showReport)

		self._guiMode =				guiMode

		self._entity =				None
		self._testbenchFQN =	None
		self._vhdlGenerics =	None

		self._ghdl =					None

		self._PrepareSimulationEnvironment()

	def _PrepareSimulationEnvironment(self):
		self._LogNormal("Preparing simulation environment...")
		self._tempPath = self.Host.Directories["GHDLTemp"]
		super()._PrepareSimulationEnvironment()

	def PrepareSimulator(self, binaryPath, version, backend):
		# create the GHDL executable factory
		self._LogVerbose("Preparing GHDL simulator.")
		self._ghdl =			GHDL(self.Host.Platform, binaryPath, version, backend, logger=self.Logger)

	def Run(self, testbench, board, vhdlVersion="93c", vhdlGenerics=None, guiMode=False):
		self._LogQuiet("Testbench: {0!s}".format(testbench.Parent, **Init.Foreground))

		self._vhdlVersion =		vhdlVersion
		self._vhdlGenerics =	vhdlGenerics

		# setup all needed paths to execute fuse
		self._CreatePoCProject(testbench, board)
		self._AddFileListFile(testbench.FilesFile)
		
		if (self._ghdl.Backend == "gcc"):
			self._RunAnalysis()
			self._RunElaboration(testbench)
			self._RunSimulation(testbench)
		elif (self._ghdl.Backend == "llvm"):
			self._RunAnalysis()
			self._RunElaboration(testbench)
			self._RunSimulation(testbench)
		elif (self._ghdl.Backend == "mcode"):
			self._RunAnalysis()
			self._RunSimulation(testbench)

		if   (testbench.Result is SimulationResult.Passed):			self._LogQuiet("  {GREEN}[PASSED]{NOCOLOR}".format(**Init.Foreground))
		elif (testbench.Result is SimulationResult.NoAsserts):	self._LogQuiet("  {YELLOW}[NO ASSERTS]{NOCOLOR}".format(**Init.Foreground))
		elif (testbench.Result is SimulationResult.Failed):			self._LogQuiet("  {RED}[FAILED]{NOCOLOR}".format(**Init.Foreground))
		elif (testbench.Result is SimulationResult.Error):			self._LogQuiet("  {RED}[ERROR]{NOCOLOR}".format(**Init.Foreground))

		# FIXME: a very quick implemenation
		if (guiMode == True):
			viewer = self.GetViewer()
			viewer.View(testbench.VHDLTestbench)
		
	def _RunAnalysis(self):
		self._LogNormal("Running analysis for every vhdl file...")
		
		# create a GHDLAnalyzer instance
		ghdl = self._ghdl.GetGHDLAnalyze()
		ghdl.Parameters[ghdl.FlagVerbose] =						(self.Logger.LogLevel is Severity.Debug)
		ghdl.Parameters[ghdl.FlagExplicit] =					True
		ghdl.Parameters[ghdl.FlagRelaxedRules] =			True
		ghdl.Parameters[ghdl.FlagWarnBinding] =				True
		ghdl.Parameters[ghdl.FlagNoVitalChecks] =			True
		ghdl.Parameters[ghdl.FlagMultiByteComments] =	True
		ghdl.Parameters[ghdl.FlagSynBinding] =				True
		ghdl.Parameters[ghdl.FlagPSL] =								True

		if (self._vhdlVersion == VHDLVersion.VHDL87):
			ghdl.Parameters[ghdl.SwitchVHDLVersion] =		"87"
			ghdl.Parameters[ghdl.SwitchIEEEFlavor] =		"synopsys"
		elif (self._vhdlVersion == VHDLVersion.VHDL93):
			ghdl.Parameters[ghdl.SwitchVHDLVersion] =		"93c"
			ghdl.Parameters[ghdl.SwitchIEEEFlavor] =		"synopsys"
		elif (self._vhdlVersion == VHDLVersion.VHDL02):
			ghdl.Parameters[ghdl.SwitchVHDLVersion] =		"02"
		elif (self._vhdlVersion == VHDLVersion.VHDL08):
			ghdl.Parameters[ghdl.SwitchVHDLVersion] =		"08"
		else:																					raise SimulatorException("VHDL version is not supported.")

		# add external library references
		ghdl.Parameters[ghdl.ArgListLibraryReferences] = [str(extLibrary.Path) for extLibrary in self._pocProject.ExternalVHDLLibraries]
		
		# run GHDL analysis for each VHDL file
		for file in self._pocProject.Files(fileType=FileTypes.VHDLSourceFile):
			if (not file.Path.exists()):									raise SimulatorException("Can not analyse '{0}'.".format(str(file.Path))) from FileNotFoundError(str(file.Path))

			ghdl.Parameters[ghdl.SwitchVHDLLibrary] =			file.LibraryName
			ghdl.Parameters[ghdl.ArgSourceFile] =					file.Path
			try:
				ghdl.Analyze()
			except GHDLException as ex:
				raise SimulatorException("Error while analysing '{0}'.".format(str(file.Path))) from ex

			if ghdl.HasErrors:
				raise SimulatorException("Error while analysing '{0}'.".format(str(file.Path)))


	# running simulation
	# ==========================================================================
	def _RunElaboration(self, testbench):
		self._LogNormal("Running elaboration...")
		
		# create a GHDLElaborate instance
		ghdl = self._ghdl.GetGHDLElaborate()
		ghdl.Parameters[ghdl.FlagVerbose] =						(self.Logger.LogLevel is Severity.Debug)
		ghdl.Parameters[ghdl.SwitchVHDLLibrary] =			VHDL_TESTBENCH_LIBRARY_NAME
		ghdl.Parameters[ghdl.ArgTopLevel] =						testbench.ModuleName

		# add external library references
		ghdl.Parameters[ghdl.ArgListLibraryReferences] = [str(extLibrary.Path) for extLibrary in self._pocProject.ExternalVHDLLibraries]

		if (self._vhdlVersion == VHDLVersion.VHDL87):
			ghdl.Parameters[ghdl.SwitchVHDLVersion] =		"87"
			ghdl.Parameters[ghdl.SwitchIEEEFlavor] =		"synopsys"
		elif (self._vhdlVersion == VHDLVersion.VHDL93):
			ghdl.Parameters[ghdl.SwitchVHDLVersion] =		"93c"
			ghdl.Parameters[ghdl.SwitchIEEEFlavor] =		"synopsys"
		elif (self._vhdlVersion == VHDLVersion.VHDL02):
			ghdl.Parameters[ghdl.SwitchVHDLVersion] =		"02"
		elif (self._vhdlVersion == VHDLVersion.VHDL08):
			ghdl.Parameters[ghdl.SwitchVHDLVersion] =		"08"
		else:																					raise SimulatorException("VHDL version is not supported.")
		
		try:
			ghdl.Elaborate()
		except GHDLException as ex:
			raise SimulatorException("Error while elaborating '{0}.{1}'.".format(VHDL_TESTBENCH_LIBRARY_NAME, testbench.ModuleName)) from ex

		if ghdl.HasErrors:
			raise SimulatorException("Error while elaborating '{0}.{1}'.".format(VHDL_TESTBENCH_LIBRARY_NAME, testbench.ModuleName))
	
	
	def _RunSimulation(self, testbench):
		self._LogNormal("Running simulation...")
			
		# create a GHDLRun instance
		ghdl = self._ghdl.GetGHDLRun()
		ghdl.Parameters[ghdl.FlagVerbose] =						(self.Logger.LogLevel is Severity.Debug)
		ghdl.Parameters[ghdl.FlagExplicit] =					True
		ghdl.Parameters[ghdl.FlagRelaxedRules] =			True
		ghdl.Parameters[ghdl.FlagWarnBinding] =				True
		ghdl.Parameters[ghdl.FlagNoVitalChecks] =			True
		ghdl.Parameters[ghdl.FlagMultiByteComments] =	True
		ghdl.Parameters[ghdl.FlagSynBinding] =				True
		ghdl.Parameters[ghdl.FlagPSL] =								True
		ghdl.Parameters[ghdl.SwitchVHDLLibrary] =			VHDL_TESTBENCH_LIBRARY_NAME
		ghdl.Parameters[ghdl.ArgTopLevel] =						testbench.ModuleName

		if (self._vhdlVersion == VHDLVersion.VHDL87):
			ghdl.Parameters[ghdl.SwitchVHDLVersion] =		"87"
			ghdl.Parameters[ghdl.SwitchIEEEFlavor] =		"synopsys"
		elif (self._vhdlVersion == VHDLVersion.VHDL93):
			ghdl.Parameters[ghdl.SwitchVHDLVersion] =		"93c"
			ghdl.Parameters[ghdl.SwitchIEEEFlavor] =		"synopsys"
		elif (self._vhdlVersion == VHDLVersion.VHDL02):
			ghdl.Parameters[ghdl.SwitchVHDLVersion] =		"02"
		elif (self._vhdlVersion == VHDLVersion.VHDL08):
			ghdl.Parameters[ghdl.SwitchVHDLVersion] =		"08"
		else:																					raise SimulatorException("VHDL version is not supported.")

		# add external library references
		ghdl.Parameters[ghdl.ArgListLibraryReferences] = [str(extLibrary.Path) for extLibrary in self._pocProject.ExternalVHDLLibraries]

		# configure RUNOPTS
		ghdl.RunOptions[ghdl.SwitchIEEEAsserts] = "disable-at-0"		# enable, disable, disable-at-0
		# set dump format to save simulation results to *.vcd file
		if (self._guiMode):
			waveformFileFormat =	self.Host.PoCConfig[testbench.ConfigSectionName]['ghdlWaveformFileFormat']
			if (waveformFileFormat == "vcd"):
				waveformFilePath = self._tempPath / (testbench.ModuleName + ".vcd")
				ghdl.RunOptions[ghdl.SwitchVCDWaveform] =		waveformFilePath
			elif (waveformFileFormat == "vcdgz"):
				waveformFilePath = self._tempPath / (testbench.ModuleName + ".vcd.gz")
				ghdl.RunOptions[ghdl.SwitchVCDGZWaveform] =	waveformFilePath
			elif (waveformFileFormat == "fst"):
				waveformFilePath = self._tempPath / (testbench.ModuleName + ".fst")
				ghdl.RunOptions[ghdl.SwitchFSTWaveform] =		waveformFilePath
			elif (waveformFileFormat == "ghw"):
				waveformFilePath = self._tempPath / (testbench.ModuleName + ".ghw")
				ghdl.RunOptions[ghdl.SwitchGHDLWaveform] =	waveformFilePath
			else:																						raise SimulatorException("Unknown waveform file format for GHDL.")
		
		testbench.Result = ghdl.Run()

	def _ExecuteSimulation(self, testbench):
		self._LogNormal("Executing simulation...")
			
		# create a GHDLRun instance
		ghdl = self._ghdl.GetGHDLRun()
		ghdl.VHDLVersion =	self._vhdlVersion
		ghdl.VHDLLibrary =	VHDL_TESTBENCH_LIBRARY_NAME
		
		# configure RUNOPTS
		runOptions = []
		runOptions.append('--ieee-asserts={0}'.format("disable-at-0"))		# enable, disable, disable-at-0
		# set dump format to save simulation results to *.vcd file
		if (self._guiMode):
			waveformFileFormat =	self.Host.PoCConfig[testbench.ConfigSectionName]['ghdlWaveformFileFormat']
					
			if (waveformFileFormat == "vcd"):
				waveformFilePath = self._tempPath / (testbench.ModuleName + ".vcd")
				runOptions.append("--vcd={0}".format(str(waveformFilePath)))
			elif (waveformFileFormat == "vcdgz"):
				waveformFilePath = self._tempPath / (testbench.ModuleName + ".vcd.gz")
				runOptions.append("--vcdgz={0}".format(str(waveformFilePath)))
			elif (waveformFileFormat == "fst"):
				waveformFilePath = self._tempPath / (testbench.ModuleName + ".fst")
				runOptions.append("--fst={0}".format(str(waveformFilePath)))
			elif (waveformFileFormat == "ghw"):
				waveformFilePath = self._tempPath / (testbench.ModuleName + ".ghw")
				runOptions.append("--wave={0}".format(str(waveformFilePath)))
			else:																						raise SimulatorException("Unknown waveform file format for GHDL.")
		
		ghdl.Run(testbench.ModuleName, runOptions)
	
	def GetViewer(self):
		return self
	
	def View(self, testbench):
		self._LogNormal("Executing GTKWave...")
		
		waveformFileFormat =	self.Host.PoCConfig[testbench.ConfigSectionName]['ghdlWaveformFileFormat']
		if (waveformFileFormat == "vcd"):
			waveformFilePath = self._tempPath / (testbench.ModuleName + ".vcd")
		elif (waveformFileFormat == "vcdgz"):
			waveformFilePath = self._tempPath / (testbench.ModuleName + ".vcd.gz")
		elif (waveformFileFormat == "fst"):
			waveformFilePath = self._tempPath / (testbench.ModuleName + ".fst")
		elif (waveformFileFormat == "ghw"):
			waveformFilePath = self._tempPath / (testbench.ModuleName + ".ghw")
		else:																						raise SimulatorException("Unknown waveform file format for GHDL.")
		
		if (not waveformFilePath.exists()):							raise SimulatorException("Waveform file not found.") from FileNotFoundError(str(waveformFilePath))
		
		gtkwBinaryPath =		self.Host.Directories["GTKWBinary"]
		gtkwVersion =				self.Host.PoCConfig['INSTALL.GTKWave']['Version']
		gtkw = GTKWave(self.Host.Platform, gtkwBinaryPath, gtkwVersion)
		gtkw.Parameters[gtkw.SwitchDumpFile] = str(waveformFilePath)

		# if GTKWave savefile exists, load it's settings
		gtkwSaveFilePath =	self.Host.Directories["PoCRoot"] / self.Host.PoCConfig[testbench.ConfigSectionName]['gtkwSaveFile']
		if gtkwSaveFilePath.exists():
			self._LogDebug("Found waveform save file: '{0}'".format(str(gtkwSaveFilePath)))
			gtkw.Parameters[gtkw.SwitchSaveFile] = str(gtkwSaveFilePath)
		else:
			self._LogDebug("Didn't find waveform save file: '{0}'".format(str(gtkwSaveFilePath)))
		
		# run GTKWave GUI
		gtkw.View()
		
		# clean-up *.gtkw files
		if gtkwSaveFilePath.exists():
			self._LogNormal("  Cleaning up GTKWave save file...")
			removeKeys = ("[dumpfile]", "[savefile]")
			buffer = ""
			with gtkwSaveFilePath.open('r') as gtkwHandle:
				lineNumber = 0
				for lineNumber,line in enumerate(gtkwHandle):
					lineNumber += 1
					if (not line.startswith(removeKeys)):			buffer += line
					if (lineNumber > 10):											break
				for line in gtkwHandle:
					buffer += line
			with gtkwSaveFilePath.open('w') as gtkwHandle:
				gtkwHandle.write(buffer)

# 			# search log for fatal warnings
# 			analyzeErrors = []
# 			elaborateLogRegExpStr =	r"(?P<VHDLFile>.*?):(?P<LineNumber>\d+):\d+:warning: component instance \"(?P<ComponentName>[a-z]+)\" is not bound"
# 			elaborateLogRegExp = re.compile(elaborateLogRegExpStr)
# 
# 			for logLine in elaborateLog.splitlines():
# 				print("line: " + logLine)
# 				elaborateLogRegExpMatch = elaborateLogRegExp.match(logLine)
# 				if (elaborateLogRegExpMatch is not None):
# 					analyzeErrors.append({
# 						'Type' : "Unbound Component",
# 						'File' : elaborateLogRegExpMatch.group('VHDLFile'),
# 						'Line' : elaborateLogRegExpMatch.group('LineNumber'),
# 						'Component' : elaborateLogRegExpMatch.group('ComponentName')
# 					})
# 		
# 			if (len(analyzeErrors) != 0):
# 				print("  ERROR list:")
# 				for err in analyzeErrors:
# 					print("    %s: '%s' in file '%s' at line %s" % (err['Type'], err['Component'], err['File'], err['Line']))
# 			
# 				raise SimulatorException("Errors while GHDL analysis phase.")
#
# 			except SimulatorException as ex:
# 				raise TestbenchException("PoC.ns.module", testbenchName, "'SIMULATION RESULT = [PASSED|FAILED|NO ASSERTS]' not found in simulator output.") from ex
#
