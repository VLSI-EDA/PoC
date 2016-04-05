# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
# Authors:				 	Patrick Lehmann
# 
# Python Class:			This PoCXCOCompiler compiles xco IPCores to netlists
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
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module Compiler.XSTCompiler")

# load dependencies
import re								# used for output filtering
import shutil
from colorama								import Fore as Foreground
from configparser						import NoSectionError
from os											import chdir
from pathlib								import Path

from Base.Exceptions				import CompilerException, NotConfiguredException, PlatformNotSupportedException
from Base.Project						import FileTypes, VHDLVersion
from Base.Compiler					import Compiler as BaseCompiler
from PoC.PoCProject					import Project as PoCProject
from ToolChains.Xilinx.ISE	import ISE


class Compiler(BaseCompiler):
	def __init__(self, host, showLogs, showReport):
		super(self.__class__, self).__init__(host, showLogs, showReport)


	def oldRun(self, pocEntity, device):
		self._pocEntity =	pocEntity
		self._ipcoreFQN =	str(pocEntity)
		
		self._LogNormal(self._ipcoreFQN)
		self._LogNormal("  preparing compiler environment...")

		# TODO: improve / resolve board to device
		deviceString = str(device).upper()
		deviceSection = "Device." + deviceString
		
		# create temporary directory for XST if not existent
		self._tempPath = self.Host.Directories["XSTTemp"]
		if not (self._tempPath).exists():
			self._LogVerbose("Creating temporary directory for XST files.")
			self._LogDebug("Temporary directors: {0}".format(str(self._tempPath)))
			self._tempPath.mkdir(parents=True)

		# create output directory for CoreGen if not existent
		self._outputPath = self.Host.Directories["PoCNetList"] / deviceString
		if not (self._outputPath).exists():
			self._LogVerbose("Creating temporary directory for XST files.")
			self._LogDebug("Temporary directors: {0}".format(str(self._outputPath)))
			self._outputPath.mkdir(parents=True)
			
		# add the key Device to section SPECIAL at runtime to change interpolation results
		self.Host.netListConfig['SPECIAL'] = {}
		self.Host.netListConfig['SPECIAL']['Device'] =				deviceString
		self.Host.netListConfig['SPECIAL']['DeviceSeries'] =	device.series()
		self.Host.netListConfig['SPECIAL']['OutputDir']	=			self._tempPath.as_posix()
		
		# read pre-copy tasks
		preCopyTasks = []
		preCopyFileList = self.Host.netListConfig[self._ipcoreFQN]['PreCopy.Rule']
		if (len(preCopyFileList) != 0):
			self._LogDebug("PreCopyTasks: \n  " + ("\n  ".join(preCopyFileList.split("\n"))))
			
			preCopyRegExpStr	 = r"^\s*(?P<SourceFilename>.*?)"			# Source filename
			preCopyRegExpStr += r"\s->\s"													#	Delimiter signs
			preCopyRegExpStr += r"(?P<DestFilename>.*?)$"					#	Destination filename
			preCopyRegExp = re.compile(preCopyRegExpStr)
			
			for item in preCopyFileList.split("\n"):
				preCopyRegExpMatch = preCopyRegExp.match(item)
				if (preCopyRegExpMatch is not None):
					preCopyTasks.append((
						Path(preCopyRegExpMatch.group('SourceFilename')),
						Path(preCopyRegExpMatch.group('DestFilename'))
					))
				else:
					raise CompilerException("Error in pre-copy rule '{0}'".format(item))
		
		# read (post) copy tasks
		copyTasks = []
		copyFileList = self.Host.netListConfig[self._ipcoreFQN]['Copy']
		if (len(copyFileList) != 0):
			self._LogDebug("CopyTasks: \n  " + ("\n  ".join(copyFileList.split("\n"))))
			
			copyRegExpStr	 = r"^\s*(?P<SourceFilename>.*?)"			# Source filename
			copyRegExpStr += r"\s->\s"													#	Delimiter signs
			copyRegExpStr += r"(?P<DestFilename>.*?)$"					#	Destination filename
			copyRegExp = re.compile(copyRegExpStr)
			
			for item in copyFileList.split("\n"):
				copyRegExpMatch = copyRegExp.match(item)
				if (copyRegExpMatch is not None):
					copyTasks.append((
						Path(copyRegExpMatch.group('SourceFilename')),
						Path(copyRegExpMatch.group('DestFilename'))
					))
				else:
					raise CompilerException("Error in copy rule '{0}'".format(item))
		
		# read replacement tasks
		replaceTasks = []
		replaceFileList = self.Host.netListConfig[self._ipcoreFQN]['Replace']
		if (len(replaceFileList) != 0):
			self._LogDebug("ReplacementTasks: \n  " + ("\n  ".join(replaceFileList.split("\n"))))

			replaceRegExpStr =	r"^\s*(?P<Filename>.*?)\s+:"			# Filename
			replaceRegExpStr += r"(?P<Options>[dim]{0,3}):\s+"			#	RegExp options
			replaceRegExpStr += r"\"(?P<Search>.*?)\"\s+->\s+"		#	Search regexp
			replaceRegExpStr += r"\"(?P<Replace>.*?)\"$"					# Replace regexp
			replaceRegExp = re.compile(replaceRegExpStr)

			for item in replaceFileList.split("\n"):
				replaceRegExpMatch = replaceRegExp.match(item)
				
				if (replaceRegExpMatch is not None):
					replaceTasks.append((
						Path(replaceRegExpMatch.group('Filename')),
						replaceRegExpMatch.group('Options'),
						replaceRegExpMatch.group('Search'),
						replaceRegExpMatch.group('Replace')
					))
				else:
					raise CompilerException("Error in replace rule '{0}'.".format(item))
		
		# run pre-copy tasks
		self._LogNormal('  copy further input files into output directory...')
		for task in preCopyTasks:
			(fromPath, toPath) = task
			if not fromPath.exists(): raise CompilerException("Can not pre-copy '{0}' to destination.".format(str(fromPath))) from FileNotFoundError(str(fromPath))
			
			toDirectoryPath = toPath.parent
			if not toDirectoryPath.exists():
				toDirectoryPath.mkdir(parents=True)
		
			self._LogVerbose("  pre-copying '{0}'.".format(fromPath))
			shutil.copy(str(fromPath), str(toPath))
		
		# setup all needed paths to execute coreGen
		xstExecutablePath =		self.Host.Directories["ISEBinary"] / self.__executables['XST']
		
		if not self.Host.netListConfig.has_section(self._ipcoreFQN):
			raise CompilerException("IP-Core '" + self._ipcoreFQN + "' not found.") from NoSectionError(self._ipcoreFQN)
		
		# read netlist settings from configuration file
		if (self.Host.netListConfig[self._ipcoreFQN]['Type'] != "XilinxSynthesis"):
			raise CompilerException("This entity is not configured for XST compilation.")
		
		topModuleName =				self.Host.netListConfig[self._ipcoreFQN]['TopModule']
		fileListFilePath =		self.Host.Directories["PoCRoot"] / self.Host.netListConfig[self._ipcoreFQN]['FileListFile']
		xcfFilePath =					self.Host.Directories["PoCRoot"] / self.Host.netListConfig[self._ipcoreFQN]['XSTConstraintsFile']
		filterFilePath =			self.Host.Directories["PoCRoot"] / self.Host.netListConfig[self._ipcoreFQN]['XSTFilterFile']
		#xstOptionsFilePath =	self.Host.Directories["XSTFiles"] / self.Host.netListConfig[self._ipcoreFQN]['XSTOptionsFile']
		xstTemplateFilePath =	self.Host.Directories["XSTFiles"] / self.Host.netListConfig[self._ipcoreFQN]['XSTOptionsFile']
		xstFilePath =					self._tempPath / (topModuleName + ".xst")
		prjFilePath =					self._tempPath / (topModuleName + ".prj")
		reportFilePath =			self._tempPath / (topModuleName + ".log")

		#if (not xstOptionsFilePath.exists()):
		# read/write XST options file
		self._LogDebug("Reading Xilinx Compiler Tool option file from '{0}'".format(str(xstTemplateFilePath)))
		with xstTemplateFilePath.open('r') as xstFileHandle:
			xstFileContent = xstFileHandle.read()
			
		xstTemplateDictionary = {
			'prjFile' :													str(prjFilePath),
			'UseNewParser' :										self.Host.netListConfig[self._ipcoreFQN]['XSTOption.UseNewParser'],
			'InputFormat' :											self.Host.netListConfig[self._ipcoreFQN]['XSTOption.InputFormat'],
			'OutputFormat' :										self.Host.netListConfig[self._ipcoreFQN]['XSTOption.OutputFormat'],
			'OutputName' :											topModuleName,
			'Part' :														str(device),
			'TopModuleName' :										topModuleName,
			'OptimizationMode' :								self.Host.netListConfig[self._ipcoreFQN]['XSTOption.OptimizationMode'],
			'OptimizationLevel' :								self.Host.netListConfig[self._ipcoreFQN]['XSTOption.OptimizationLevel'],
			'PowerReduction' :									self.Host.netListConfig[self._ipcoreFQN]['XSTOption.PowerReduction'],
			'IgnoreSynthesisConstraintsFile' :	self.Host.netListConfig[self._ipcoreFQN]['XSTOption.IgnoreSynthesisConstraintsFile'],
			'SynthesisConstraintsFile' :				str(xcfFilePath),
			'KeepHierarchy' :										self.Host.netListConfig[self._ipcoreFQN]['XSTOption.KeepHierarchy'],
			'NetListHierarchy' :								self.Host.netListConfig[self._ipcoreFQN]['XSTOption.NetListHierarchy'],
			'GenerateRTLView' :									self.Host.netListConfig[self._ipcoreFQN]['XSTOption.GenerateRTLView'],
			'GlobalOptimization' :							self.Host.netListConfig[self._ipcoreFQN]['XSTOption.Globaloptimization'],
			'ReadCores' :												self.Host.netListConfig[self._ipcoreFQN]['XSTOption.ReadCores'],
			'SearchDirectories' :								'"{0}"' % str(self._outputPath),
			'WriteTimingConstraints' :					self.Host.netListConfig[self._ipcoreFQN]['XSTOption.WriteTimingConstraints'],
			'CrossClockAnalysis' :							self.Host.netListConfig[self._ipcoreFQN]['XSTOption.CrossClockAnalysis'],
			'HierarchySeparator' :							self.Host.netListConfig[self._ipcoreFQN]['XSTOption.HierarchySeparator'],
			'BusDelimiter' :										self.Host.netListConfig[self._ipcoreFQN]['XSTOption.BusDelimiter'],
			'Case' :														self.Host.netListConfig[self._ipcoreFQN]['XSTOption.Case'],
			'SliceUtilizationRatio' :						self.Host.netListConfig[self._ipcoreFQN]['XSTOption.SliceUtilizationRatio'],
			'BRAMUtilizationRatio' :						self.Host.netListConfig[self._ipcoreFQN]['XSTOption.BRAMUtilizationRatio'],
			'DSPUtilizationRatio' :							self.Host.netListConfig[self._ipcoreFQN]['XSTOption.DSPUtilizationRatio'],
			'LUTCombining' :										self.Host.netListConfig[self._ipcoreFQN]['XSTOption.LUTCombining'],
			'ReduceControlSets' :								self.Host.netListConfig[self._ipcoreFQN]['XSTOption.ReduceControlSets'],
			'Verilog2001' :											self.Host.netListConfig[self._ipcoreFQN]['XSTOption.Verilog2001'],
			'FSMExtract' :											self.Host.netListConfig[self._ipcoreFQN]['XSTOption.FSMExtract'],
			'FSMEncoding' :											self.Host.netListConfig[self._ipcoreFQN]['XSTOption.FSMEncoding'],
			'FSMSafeImplementation' :						self.Host.netListConfig[self._ipcoreFQN]['XSTOption.FSMSafeImplementation'],
			'FSMStyle' :												self.Host.netListConfig[self._ipcoreFQN]['XSTOption.FSMStyle'],
			'RAMExtract' :											self.Host.netListConfig[self._ipcoreFQN]['XSTOption.RAMExtract'],
			'RAMStyle' :												self.Host.netListConfig[self._ipcoreFQN]['XSTOption.RAMStyle'],
			'ROMExtract' :											self.Host.netListConfig[self._ipcoreFQN]['XSTOption.ROMExtract'],
			'ROMStyle' :												self.Host.netListConfig[self._ipcoreFQN]['XSTOption.ROMStyle'],
			'MUXExtract' :											self.Host.netListConfig[self._ipcoreFQN]['XSTOption.MUXExtract'],
			'MUXStyle' :												self.Host.netListConfig[self._ipcoreFQN]['XSTOption.MUXStyle'],
			'DecoderExtract' :									self.Host.netListConfig[self._ipcoreFQN]['XSTOption.DecoderExtract'],
			'PriorityExtract' :									self.Host.netListConfig[self._ipcoreFQN]['XSTOption.PriorityExtract'],
			'ShRegExtract' :										self.Host.netListConfig[self._ipcoreFQN]['XSTOption.ShRegExtract'],
			'ShiftExtract' :										self.Host.netListConfig[self._ipcoreFQN]['XSTOption.ShiftExtract'],
			'XorCollapse' :											self.Host.netListConfig[self._ipcoreFQN]['XSTOption.XorCollapse'],
			'AutoBRAMPacking' :									self.Host.netListConfig[self._ipcoreFQN]['XSTOption.AutoBRAMPacking'],
			'ResourceSharing' :									self.Host.netListConfig[self._ipcoreFQN]['XSTOption.ResourceSharing'],
			'ASyncToSync' :											self.Host.netListConfig[self._ipcoreFQN]['XSTOption.ASyncToSync'],
			'UseDSP48' :												self.Host.netListConfig[self._ipcoreFQN]['XSTOption.UseDSP48'],
			'IOBuf' :														self.Host.netListConfig[self._ipcoreFQN]['XSTOption.IOBuf'],
			'MaxFanOut' :												self.Host.netListConfig[self._ipcoreFQN]['XSTOption.MaxFanOut'],
			'BufG' :														self.Host.netListConfig[self._ipcoreFQN]['XSTOption.BufG'],
			'RegisterDuplication' :							self.Host.netListConfig[self._ipcoreFQN]['XSTOption.RegisterDuplication'],
			'RegisterBalancing' :								self.Host.netListConfig[self._ipcoreFQN]['XSTOption.RegisterBalancing'],
			'SlicePacking' :										self.Host.netListConfig[self._ipcoreFQN]['XSTOption.SlicePacking'],
			'OptimizePrimitives' :							self.Host.netListConfig[self._ipcoreFQN]['XSTOption.OptimizePrimitives'],
			'UseClockEnable' :									self.Host.netListConfig[self._ipcoreFQN]['XSTOption.UseClockEnable'],
			'UseSyncSet' :											self.Host.netListConfig[self._ipcoreFQN]['XSTOption.UseSyncSet'],
			'UseSyncReset' :										self.Host.netListConfig[self._ipcoreFQN]['XSTOption.UseSyncReset'],
			'PackIORegistersIntoIOBs' :					self.Host.netListConfig[self._ipcoreFQN]['XSTOption.PackIORegistersIntoIOBs'],
			'EquivalentRegisterRemoval' :				self.Host.netListConfig[self._ipcoreFQN]['XSTOption.EquivalentRegisterRemoval'],
			'SliceUtilizationRatioMaxMargin' :	self.Host.netListConfig[self._ipcoreFQN]['XSTOption.SliceUtilizationRatioMaxMargin']
		}
		
		xstFileContent = xstFileContent.format(**xstTemplateDictionary)
		
		if (self.Host.netListConfig.has_option(self._ipcoreFQN, 'XSTOption.Generics')):
			xstFileContent += "-generics { {0} }".format(self.Host.netListConfig[self._ipcoreFQN]['XSTOption.Generics'])

		self._LogDebug("Writing Xilinx Compiler Tool option file to '{0}'".format(str(xstFilePath)))
		with xstFilePath.open('w') as xstFileHandle:
			xstFileHandle.write(xstFileContent)
	
		# TODO: parse project filelist
		# TODO: write iSim project file
		self._LogDebug("Writing XST project file to '{0}'".format(str(prjFilePath)))
		with prjFilePath.open('w') as prjFileHandle:
			prjFileHandle.write(xstProjectFileContent)

		# change working directory to temporary XST path
		self._LogVerbose('    cd "{0}"' % str(self._tempPath))
		os.chdir(str(self._tempPath))
		
		# running XST
		# ==========================================================================
		self._LogNormal("  running XST...")
		# assemble XST command as list of parameters
		parameterList = [
			str(xstExecutablePath),
			'-intstyle', 'xflow',
			'-filter', str(filterFilePath),
			'-ifn', str(xstFilePath),
			'-ofn', str(reportFilePath)
		]
		# TODO: copy resulting files into PoC's netlist directory
		# TODO: replace in resulting files

	@property
	def TemporaryPath(self):
		return self._tempPath
	
	@property
	def OutputPath(self):
		return self._outputPath

	def _PrepareCompilerEnvironment(self):
		self._LogNormal("  preparing compiler environment...")
		
		# create temporary directory for ghdl if not existent
		self._tempPath = self.Host.Directories["XstTemp"]
		if (not (self._tempPath).exists()):
			self._LogVerbose("  Creating temporary directory for compiler files.")
			self._LogDebug("    Temporary directors: {0}".format(str(self._tempPath)))
			self._tempPath.mkdir(parents=True)
			
		# change working directory to temporary iSim path
		self._LogVerbose("  Changing working directory to temporary directory.")
		self._LogDebug("    cd \"{0}\"".format(str(self._tempPath)))
		chdir(str(self._tempPath))

	def RunAll(self, pocEntities, device, **kwargs) :
		for pocEntity in pocEntities :
			self.Run(pocEntity, device, **kwargs)

	def Run(self, pocEntity, device) :
		self._pocEntity =		pocEntity
		self._ipcoreFQN =		str(pocEntity)  # TODO: implement FQN method on PoCEntity
		self._device =			device

		# check testbench database for the given testbench
		self._LogQuiet("IP-core: {0}{1}{2}".format(Foreground.YELLOW, self._ipcoreFQN, Foreground.RESET))
		if (not self.Host.netListConfig.has_section(self._ipcoreFQN)) :
			raise CompilerException("IP-core '{0}' not found.".format(self._ipcoreFQN)) from NoSectionError(
				self._ipcoreFQN)

		self._LogNormal(self._ipcoreFQN)

		# create output directory for CoreGen if not existent
		self._outputPath = self.Host.Directories["PoCNetList"] / str(device)
		if not (self._outputPath).exists() :
			self._LogVerbose("  Creating output directory for core generator files.")
			self._LogDebug("    Output directory: {0}.".format(str(self._outputPath)))
			self._outputPath.mkdir(parents=True)

		self._CreatePoCProject()
		self._AddFileListFile("ipcore.files") # FIXME:

		self._RunPrepareCompile()
		self._RunPreCopy()
		self._RunCompile()
		self._RunPostCopy()
		self._RunPostReplace()

	def PrepareCompiler(self, binaryPath, version):
		# create the GHDL executable factory
		self._LogVerbose("  Preparing Xilinx Synthesis Tool (XST).")
		self._xst =		XstCompilerExecutable(self.Host.Platform, binaryPath, version, logger=self.Logger)
	
	def _CreatePoCProject(self):
		# create a PoCProject and read all needed files
		self._LogDebug("    Create a PoC project '{0}'".format(self._ipcoreFQN))
		pocProject =									PoCProject(self._ipcoreFQN)
		
		# configure the project
		pocProject.RootDirectory =		self.Host.Directories["PoCRoot"]
		pocProject.Environment =			Environment.Synthesis
		pocProject.ToolChain =				ToolChain.Xilinx_ISE
		pocProject.Tool =							Tool.Xilinx_XST
		pocProject.Device =						self._device
		
		self._pocProject = pocProject
		
	def _AddFileListFile(self, fileListFilePath):
		self._LogDebug("    Reading filelist '{0}'".format(str(fileListFilePath)))
		# add the *.files file, parse and evaluate it
		fileListFile = self._pocProject.AddFile(FileListFile(fileListFilePath))
		fileListFile.Parse()
		fileListFile.CopyFilesToFileSet()
		fileListFile.CopyExternalLibraries()
		self._pocProject.ExtractVHDLLibrariesFromVHDLSourceFiles()
		self._LogDebug(self._pocProject.pprint(2))
		self._LogDebug("=" * 160)

	def _RunPrepareCompile(self):
		pass

	def _RunPreCopy(self):
		pass

	def _RunCompile(self):
		xst = ISE.GetXst(self.Host.Platform, "bin", "14.7", logger=self.Logger)
		xst.Parameters[xst.SwitchIniStyle] =		"xflow"
		xst.Parameters[xst.SwitchXstFile] =			"ipcore.xst"
		xst.Parameters[xst.SwitchReportFile] =	"ipcore.xst.report"
		xst.Compile()

	def _RunPostCopy(self):
		pass

	def _RunPostReplace(self) :
		pass
