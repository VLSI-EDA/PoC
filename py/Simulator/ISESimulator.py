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
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module Simulator.ISESimulator")

# load dependencies
from configparser						import NoSectionError
from os											import chdir

from colorama								import Fore as Foreground

from Base.Exceptions				import SimulatorException
from Base.Project						import FileTypes, VHDLVersion, Environment, ToolChain, Tool, FileListFile
from Base.Simulator					import Simulator as BaseSimulator, VHDLTestbenchLibraryName
from Parser.Parser					import ParserException
from PoC.Project						import Project as PoCProject
from ToolChains.Xilinx.ISE	import ISE, ISESimulator, ISEException


class Simulator(BaseSimulator):
	__guiMode =					False

	def __init__(self, host, showLogs, showReport, guiMode):
		super().__init__(host, showLogs, showReport)

		self._guiMode =				guiMode
		self._ise =						None

		self._LogNormal("preparing simulation environment...")
		self._PrepareSimulationEnvironment()

	@property
	def TemporaryPath(self):
		return self._tempPath

	def _PrepareSimulationEnvironment(self):
		self._LogNormal("  preparing simulation environment...")
		
		# create temporary directory for ghdl if not existent
		self._tempPath = self.Host.Directories["iSimTemp"]
		if (not (self._tempPath).exists()):
			self._LogVerbose("  Creating temporary directory for simulator files.")
			self._LogDebug("    Temporary directors: {0}".format(str(self._tempPath)))
			self._tempPath.mkdir(parents=True)

		# change working directory to temporary iSim path
		self._LogVerbose("  Changing working directory to temporary directory.")
		self._LogDebug("    cd \"{0}\"".format(str(self._tempPath)))
		chdir(str(self._tempPath))

		# if (self._host.platform == "Windows"):
			# self.__executables['vhcomp'] =	"vhpcomp.exe"
			# self.__executables['fuse'] =		"fuse.exe"
		# elif (self._host.platform == "Linux"):
			# self.__executables['vhcomp'] =	"vhpcomp"
			# self.__executables['fuse'] =		"fuse"

	def PrepareSimulator(self, binaryPath, version):
		# create the GHDL executable factory
		self._LogVerbose("  Preparing GHDL simulator.")
		self._ise = ISE(self.Host.Platform, binaryPath, version, logger=self.Logger)

	def RunAll(self, pocEntities, **kwargs):
		for pocEntity in pocEntities:
			self.Run(pocEntity, **kwargs)

	def Run(self, entity, board, vhdlGenerics=None):
		self._entity =				entity
		self._testbenchFQN =	str(entity)										# TODO: implement FQN method on PoCEntity
		self._vhdlVersion =		VHDLVersion.VHDL93
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
		
		# self._RunCompile(testbenchName)
		self._RunLink(testbenchName)
		self._RunSimulation(testbenchName)

	def _CreatePoCProject(self, testbenchName, board):
		# create a PoCProject and read all needed files
		self._LogDebug("    Create a PoC project '{0}'".format(str(testbenchName)))
		pocProject =									PoCProject(testbenchName)
		
		# configure the project
		pocProject.RootDirectory =		self.Host.Directories["PoCRoot"]
		pocProject.Environment =			Environment.Simulation
		pocProject.ToolChain =				ToolChain.Xilinx_ISE
		pocProject.Tool =							Tool.Xilinx_iSim
		pocProject.VHDLVersion =			self._vhdlVersion
		pocProject.Board =						board

		self._pocProject =						pocProject

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

	def _RunCompile(self, testbenchName):
		self._LogNormal("  compiling source files...")
		
		# create one VHDL line for each VHDL file
		iSimProjectFileContent = ""
		for file in self._pocProject.Files(fileType=FileTypes.VHDLSourceFile):
			if (not file.Path.exists()):									raise SimulatorException("Can not add '{0}' to iSim project file.".format(str(file.Path))) from FileNotFoundError(str(file.Path))
			iSimProjectFileContent += "vhdl {0} \"{1}\"\n".format(file.VHDLLibraryName, str(file.Path))

		# write iSim project file
		prjFilePath = self._tempPath / (testbenchName + ".prj")
		self._LogDebug("Writing iSim project file to '{0}'".format(str(prjFilePath)))
		with prjFilePath.open('w') as prjFileHandle:
			prjFileHandle.write(iSimProjectFileContent)
		
		# create a VivadoVHDLCompiler instance
		vhcomp = self._ise.GetVHDLCompiler()
		vhcomp.Compile(str(prjFilePath))

	def _RunLink(self, testbenchName):
		self._LogNormal("  running fuse...")
		
		exeFilePath =				self._tempPath / (testbenchName + ".exe")

		# create one VHDL line for each VHDL file
		iSimProjectFileContent = ""
		for file in self._pocProject.Files(fileType=FileTypes.VHDLSourceFile):
			if (not file.Path.exists()):									raise SimulatorException("Can not add '{0}' to iSim project file.".format(str(file.Path))) from FileNotFoundError(str(file.Path))
			iSimProjectFileContent += "vhdl {0} \"{1}\"\n".format(file.VHDLLibraryName, str(file.Path))

		# write iSim project file
		prjFilePath = self._tempPath / (testbenchName + ".prj")
		self._LogDebug("Writing iSim project file to '{0}'".format(str(prjFilePath)))
		with prjFilePath.open('w') as prjFileHandle:
			prjFileHandle.write(iSimProjectFileContent)

		# create a ISELinker instance
		fuse = self._ise.GetFuse()
		fuse.Parameters[fuse.FlagIncremental] =				True
		fuse.Parameters[fuse.SwitchTimeResolution] =	"1fs"
		fuse.Parameters[fuse.SwitchMultiThreading] =	"4"
		fuse.Parameters[fuse.FlagRangeCheck] =				True
		fuse.Parameters[fuse.SwitchProjectFile] =			str(prjFilePath)
		fuse.Parameters[fuse.SwitchOutputFile] =			str(exeFilePath)
		fuse.Parameters[fuse.ArgTopLevel] =						"{0}.{1}".format(VHDLTestbenchLibraryName, testbenchName)

		try:
			fuse.Link()
		except ISEException as ex:
			raise SimulatorException("Error while analysing '{0}'.".format(str(prjFilePath))) from ex

		if fuse.HasErrors:
			raise SimulatorException("Error while analysing '{0}'.".format(str(prjFilePath)))
	
	def _RunSimulation(self, testbenchName):
		self._LogNormal("  running simulation...")
		
		iSimLogFilePath =		self._tempPath / (testbenchName + ".iSim.log")
		exeFilePath =				self._tempPath / (testbenchName + ".exe")
		tclBatchFilePath =	self.Host.Directories["PoCRoot"] / self.Host.TBConfig[self._testbenchFQN]['iSimBatchScript']
		tclGUIFilePath =		self.Host.Directories["PoCRoot"] / self.Host.TBConfig[self._testbenchFQN]['iSimGUIScript']
		wcfgFilePath =			self.Host.Directories["PoCRoot"] / self.Host.TBConfig[self._testbenchFQN]['iSimWaveformConfigFile']

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
				self._LogDebug("    Found waveform config file: '{0}'".format(str(wcfgFilePath)))
				iSim.Parameters[iSim.SwitchWaveformFile] =	str(wcfgFilePath)
			else:
				self._LogDebug("    Didn't find waveform config file: '{0}'".format(str(wcfgFilePath)))

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
