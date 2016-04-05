# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
# Authors:				 	Patrick Lehmann
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
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module Simulator.GHDLSimulator")

# load dependencies
from configparser						import NoSectionError
from os											import chdir

from colorama								import Fore as Foreground

from Base.Exceptions				import SimulatorException
from Base.Project						import FileTypes, VHDLVersion, Environment, ToolChain, Tool, FileListFile
from Base.Simulator					import Simulator as BaseSimulator, VHDLTestbenchLibraryName
from Parser.Parser					import ParserException
from PoC.Project					import Project as PoCProject
from ToolChains.GHDL				import GHDL, GHDLException
from ToolChains.GTKWave			import GTKWave


class Simulator(BaseSimulator):
	_guiMode =										False

	def __init__(self, host, showLogs, showReport, guiMode):
		super(self.__class__, self).__init__(host, showLogs, showReport)

		self._guiMode =				guiMode
		self._tempPath =			None
		self._ghdl =					None

		self._PrepareSimulationEnvironment()

	@property
	def TemporaryPath(self):
		return self._tempPath

	def _PrepareSimulationEnvironment(self):
		self._LogNormal("preparing simulation environment...")
		# create temporary directory for GHDL if not existent
		self._tempPath = self.Host.Directories["GHDLTemp"]
		if (not (self._tempPath).exists()):
			self._LogVerbose("  Creating temporary directory for simulator files.")
			self._LogDebug("    Temporary directory: {0}".format(str(self._tempPath)))
			self._tempPath.mkdir(parents=True)
			
		# change working directory to temporary iSim path
		self._LogVerbose("  Changing working directory to temporary directory.")
		self._LogDebug("    cd \"{0}\"".format(str(self._tempPath)))
		chdir(str(self._tempPath))

	def PrepareSimulator(self, binaryPath, version, backend):
		# create the GHDL executable factory
		self._LogVerbose("  Preparing GHDL simulator.")
		self._ghdl =			GHDL(self.Host.Platform, binaryPath, version, backend, logger=self.Logger)

	def RunAll(self, pocEntities, **kwargs):
		for pocEntity in pocEntities:
			self.Run(pocEntity, **kwargs)
		
	def Run(self, entity, board, vhdlVersion="93c", vhdlGenerics=None):
		self._pocEntity =			entity
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
		
		if (self._ghdl.Backend == "gcc"):
			self._RunAnalysis()
			self._RunElaboration(testbenchName)
			self._RunSimulation(testbenchName)
		elif (self._ghdl.Backend == "llvm"):
			self._RunAnalysis()
			self._RunElaboration(testbenchName)
			self._RunSimulation(testbenchName)
		elif (self._ghdl.Backend == "mcode"):
			self._RunAnalysis()
			self._RunSimulation(testbenchName)
	
	def _CreatePoCProject(self, testbenchName, board):
		# create a PoCProject and read all needed files
		self._LogDebug("    Create a PoC project '{0}'".format(str(testbenchName)))
		pocProject =									PoCProject(testbenchName)

		# configure the project
		pocProject.RootDirectory =		self.Host.Directories["PoCRoot"]
		pocProject.Environment =			Environment.Simulation
		pocProject.ToolChain =				ToolChain.GHDL_GTKWave
		pocProject.Tool =							Tool.GHDL
		pocProject.VHDLVersion =			self._vhdlVersion
		pocProject.Board =						board

		self._pocProject = pocProject
		
	def _AddFileListFile(self, fileListFilePath):
		self._LogDebug("    Reading filelist '{0}'".format(str(fileListFilePath)))
		# add the *.files file, parse and evaluate it
		try:
			fileListFile = self._pocProject.AddFile(FileListFile(fileListFilePath))
			fileListFile.Parse()
			fileListFile.CopyFilesToFileSet()
			fileListFile.CopyExternalLibraries()
			self._pocProject.ExtractVHDLLibrariesFromVHDLSourceFiles()
		except ParserException as ex:										raise SimulatorException("Error while parsing '{0}'.".format(str(fileListFilePath))) from ex
		
		self._LogDebug(self._pocProject.pprint(2))
		self._LogDebug("=" * 160)
		if (len(fileListFile.Warnings) > 0):
			for warn in fileListFile.Warnings:
				self._LogWarning(warn)
			raise SimulatorException("Found critical warnings while parsing '{0}'".format(str(fileListFilePath)))
		
	def _RunAnalysis(self):
		self._LogNormal("  running analysis for every vhdl file...")
		
		# create a GHDLAnalyzer instance
		ghdl = self._ghdl.GetGHDLAnalyze()
		ghdl.Parameters[ghdl.FlagVerbose] =						True
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

			ghdl.Parameters[ghdl.SwitchVHDLLibrary] =			file.VHDLLibraryName
			ghdl.Parameters[ghdl.ArgSourceFile] =					file.Path
			try:
				ghdl.Analyze()
			except GHDLException as ex:
				raise SimulatorException("Error while analysing '{0}'.".format(str(file.Path))) from ex

			if ghdl.HasErrors:
				raise SimulatorException("Error while analysing '{0}'.".format(str(file.Path)))


	# running simulation
	# ==========================================================================
	def _RunElaboration(self, testbenchName):
		self._LogNormal("  elaborate simulation...")
		
		# create a GHDLElaborate instance
		ghdl = self._ghdl.GetGHDLElaborate()
		ghdl.Parameters[ghdl.SwitchVHDLLibrary] =			VHDLTestbenchLibraryName
		ghdl.Parameters[ghdl.ArgTopLevel] =						testbenchName

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
			raise SimulatorException("Error while elaborating '{0}.{1}'.".format(VHDLTestbenchLibraryName, testbenchName)) from ex

		if ghdl.HasErrors:
			raise SimulatorException("Error while elaborating '{0}.{1}'.".format(VHDLTestbenchLibraryName, testbenchName))
	
	
	def _RunSimulation(self, testbenchName):
		self._LogNormal("  running simulation...")
			
		# create a GHDLRun instance
		ghdl = self._ghdl.GetGHDLRun()
		ghdl.Parameters[ghdl.FlagVerbose] =						True
		ghdl.Parameters[ghdl.FlagExplicit] =					True
		ghdl.Parameters[ghdl.FlagRelaxedRules] =			True
		ghdl.Parameters[ghdl.FlagWarnBinding] =				True
		ghdl.Parameters[ghdl.FlagNoVitalChecks] =			True
		ghdl.Parameters[ghdl.FlagMultiByteComments] =	True
		ghdl.Parameters[ghdl.FlagSynBinding] =				True
		ghdl.Parameters[ghdl.FlagPSL] =								True
		ghdl.Parameters[ghdl.SwitchVHDLLibrary] =			VHDLTestbenchLibraryName
		ghdl.Parameters[ghdl.ArgTopLevel] =						testbenchName

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
			waveformFileFormat =	self.Host.TBConfig[self._testbenchFQN]['ghdlWaveformFileFormat']
			if (waveformFileFormat == "vcd"):
				waveformFilePath = self._tempPath / (testbenchName + ".vcd")
				ghdl.RunOptions[ghdl.SwitchVCDWaveform] =		waveformFilePath
			elif (waveformFileFormat == "vcdgz"):
				waveformFilePath = self._tempPath / (testbenchName + ".vcd.gz")
				ghdl.RunOptions[ghdl.SwitchVCDGZWaveform] =	waveformFilePath
			elif (waveformFileFormat == "fst"):
				waveformFilePath = self._tempPath / (testbenchName + ".fst")
				ghdl.RunOptions[ghdl.SwitchFSTWaveform] =		waveformFilePath
			elif (waveformFileFormat == "ghw"):
				waveformFilePath = self._tempPath / (testbenchName + ".ghw")
				ghdl.RunOptions[ghdl.SwitchGHDLWaveform] =	waveformFilePath
			else:																						raise SimulatorException("Unknown waveform file format for GHDL.")
		
		ghdl.Run()
		
	def _ExecuteSimulation(self, testbenchName):
		self._LogNormal("  launching simulation...")
			
		# create a GHDLRun instance
		ghdl = self._ghdl.GetGHDLRun()
		ghdl.VHDLVersion =	self._vhdlVersion
		ghdl.VHDLLibrary =	VHDLTestbenchLibraryName
		
		# configure RUNOPTS
		runOptions = []
		runOptions.append('--ieee-asserts={0}'.format("disable-at-0"))		# enable, disable, disable-at-0
		# set dump format to save simulation results to *.vcd file
		if (self._guiMode):
			waveformFileFormat =	self.Host.TBConfig[self._testbenchFQN]['ghdlWaveformFileFormat']
					
			if (waveformFileFormat == "vcd"):
				waveformFilePath = self._tempPath / (testbenchName + ".vcd")
				runOptions.append("--vcd={0}".format(str(waveformFilePath)))
			elif (waveformFileFormat == "vcdgz"):
				waveformFilePath = self._tempPath / (testbenchName + ".vcd.gz")
				runOptions.append("--vcdgz={0}".format(str(waveformFilePath)))
			elif (waveformFileFormat == "fst"):
				waveformFilePath = self._tempPath / (testbenchName + ".fst")
				runOptions.append("--fst={0}".format(str(waveformFilePath)))
			elif (waveformFileFormat == "ghw"):
				waveformFilePath = self._tempPath / (testbenchName + ".ghw")
				runOptions.append("--wave={0}".format(str(waveformFilePath)))
			else:																						raise SimulatorException("Unknown waveform file format for GHDL.")
		
		ghdl.Run(testbenchName, runOptions)
	
	def GetViewer(self):
		return self
	
	def View(self, pocEntity):
		self._LogNormal("  launching GTKWave...")
		
		testbenchName =				self.Host.TBConfig[self._testbenchFQN]['TestbenchModule']
		waveformFileFormat =	self.Host.TBConfig[self._testbenchFQN]['ghdlWaveformFileFormat']
					
		if (waveformFileFormat == "vcd"):
			waveformFilePath = self._tempPath / (testbenchName + ".vcd")
		elif (waveformFileFormat == "vcdgz"):
			waveformFilePath = self._tempPath / (testbenchName + ".vcd.gz")
		elif (waveformFileFormat == "fst"):
			waveformFilePath = self._tempPath / (testbenchName + ".fst")
		elif (waveformFileFormat == "ghw"):
			waveformFilePath = self._tempPath / (testbenchName + ".ghw")
		else:																						raise SimulatorException("Unknown waveform file format for GHDL.")
		
		if (not waveformFilePath.exists()):							raise SimulatorException("Waveform file not found.") from FileNotFoundError(str(waveformFilePath))
		
		gtkwBinaryPath =		self.Host.Directories["GTKWBinary"]
		gtkwVersion =				self.Host.PoCConfig['GTKWave']['Version']
		gtkw = GTKWave(self.Host.Platform, gtkwBinaryPath, gtkwVersion)
		gtkw.Parameters[gtkw.SwitchDumpFile] = str(waveformFilePath)

		# if GTKWave savefile exists, load it's settings
		gtkwSaveFilePath =	self.Host.Directories["PoCRoot"] / self.Host.TBConfig[self._testbenchFQN]['gtkwSaveFile']
		if gtkwSaveFilePath.exists():
			self._LogDebug("    Found waveform save file: '{0}'".format(str(gtkwSaveFilePath)))
			gtkw.Parameters[gtkw.SwitchSaveFile] = str(gtkwSaveFilePath)
		else:
			self._LogDebug("    Didn't find waveform save file: '{0}'".format(str(gtkwSaveFilePath)))
		
		# run GTKWave GUI
		gtkw.View()
		
		# clean-up *.gtkw files
		if gtkwSaveFilePath.exists():
			self._LogNormal("    cleaning up GTKWave save file...")
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
