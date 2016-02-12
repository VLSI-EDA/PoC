# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
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
# Copyright 2007-2015 Technische Universitaet Dresden - Germany
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
from pathlib import Path

from Base.Exceptions import *
from Compiler.Base import PoCCompiler 
from Compiler.Exceptions import *

class Compiler(PoCCompiler):

	__executables = {}

	def __init__(self, host, showLogs, showReport):
		super(self.__class__, self).__init__(host, showLogs, showReport)

		if (host.platform == "Windows"):
			self.__executables['XST'] =	"xst.exe"
		elif (host.platform == "Linux"):
			self.__executables['XST'] =	"xst"
		else:
			raise PlatformNotSupportedException(self.platform)

	def run(self, pocEntity, device):
		import os
		import re
		import shutil
		import subprocess
		import textwrap
	
		self.printNonQuiet(str(pocEntity))
		self.printNonQuiet("  preparing compiler environment...")

		# TODO: improve / resolve board to device
		deviceString = str(device).upper()
		deviceSection = "Device." + deviceString
		
		# create temporary directory for XST if not existent
		tempXstPath = self.host.directories["XSTTemp"]
		if not (tempXstPath).exists():
			self.printVerbose("Creating temporary directory for XST files.")
			self.printDebug("Temporary directors: %s" % str(tempXstPath))
			tempXstPath.mkdir(parents=True)

		# create output directory for CoreGen if not existent
		xstOutputPath = self.host.directories["PoCNetList"] / deviceString
		if not (xstOutputPath).exists():
			self.printVerbose("Creating temporary directory for XST files.")
			self.printDebug("Temporary directors: %s" % str(xstOutputPath))
			xstOutputPath.mkdir(parents=True)
			
		# add the key Device to section SPECIAL at runtime to change interpolation results
		self.host.netListConfig['SPECIAL'] = {}
		self.host.netListConfig['SPECIAL']['Device'] =				deviceString
		self.host.netListConfig['SPECIAL']['DeviceSeries'] =	device.series()
		self.host.netListConfig['SPECIAL']['OutputDir']	=			tempXstPath.as_posix()
		
		# read pre-copy tasks
		preCopyTasks = []
		preCopyFileList = self.host.netListConfig[str(pocEntity)]['PreCopy']
		if (len(preCopyFileList) != 0):
			self.printDebug("PreCopyTasks: \n  " + ("\n  ".join(preCopyFileList.split("\n"))))
			
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
		copyFileList = self.host.netListConfig[str(pocEntity)]['Copy']
		if (len(copyFileList) != 0):
			self.printDebug("CopyTasks: \n  " + ("\n  ".join(copyFileList.split("\n"))))
			
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
		replaceFileList = self.host.netListConfig[str(pocEntity)]['Replace']
		if (len(replaceFileList) != 0):
			self.printDebug("ReplacementTasks: \n  " + ("\n  ".join(replaceFileList.split("\n"))))

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
		self.printNonQuiet('  copy further input files into output directory...')
		for task in preCopyTasks:
			(fromPath, toPath) = task
			if not fromPath.exists(): raise CompilerException("Can not pre-copy '{0}' to destination.".format(str(fromPath))) from FileNotFoundError(str(fromPath))
			
			toDirectoryPath = toPath.parent
			if not toDirectoryPath.exists():
				toDirectoryPath.mkdir(parents=True)
		
			self.printVerbose("  pre-copying '{0}'.".format(fromPath))
			shutil.copy(str(fromPath), str(toPath))
		
		# setup all needed paths to execute coreGen
		xstExecutablePath =		self.host.directories["ISEBinary"] / self.__executables['XST']
		
#		# read netlist settings from configuration file
#		ipCoreName =					self.host.netListConfig[str(pocEntity)]['IPCoreName']
#		xcoInputFilePath =		self.host.directories["PoCRoot"] / self.host.netListConfig[str(pocEntity)]['XstFile']
#		cgcTemplateFilePath =	self.host.directories["PoCNetList"] / "template.cgc"
#		cgpFilePath =					xstGenPath / "coregen.cgp"
#		cgcFilePath =					xstGenPath / "coregen.cgc"
#		xcoFilePath =					xstGenPath / xcoInputFilePath.name

		if not self.host.netListConfig.has_section(str(pocEntity)):
			from configparser import NoSectionError
			raise CompilerException("IP-Core '" + str(pocEntity) + "' not found.") from NoSectionError(str(pocEntity))
		
		# read netlist settings from configuration file
		if (self.host.netListConfig[str(pocEntity)]['Type'] != "XilinxSynthesis"):
			raise CompilerException("This entity is not configured for XST compilation.")
		
		topModuleName =				self.host.netListConfig[str(pocEntity)]['TopModule']
		fileListFilePath =		self.host.directories["PoCRoot"] / self.host.netListConfig[str(pocEntity)]['FileListFile']
		xcfFilePath =					self.host.directories["PoCRoot"] / self.host.netListConfig[str(pocEntity)]['XSTConstraintsFile']
		filterFilePath =			self.host.directories["PoCRoot"] / self.host.netListConfig[str(pocEntity)]['XSTFilterFile']
		#xstOptionsFilePath =	self.host.directories["XSTFiles"] / self.host.netListConfig[str(pocEntity)]['XSTOptionsFile']
		xstTemplateFilePath =	self.host.directories["XSTFiles"] / self.host.netListConfig[str(pocEntity)]['XSTOptionsFile']
		xstFilePath =					tempXstPath / (topModuleName + ".xst")
		prjFilePath =					tempXstPath / (topModuleName + ".prj")
		reportFilePath =			tempXstPath / (topModuleName + ".log")

		#if (not xstOptionsFilePath.exists()):
		# read/write XST options file
		self.printDebug("Reading Xilinx Compiler Tool option file from '%s'" % str(xstTemplateFilePath))
		with xstTemplateFilePath.open('r') as xstFileHandle:
			xstFileContent = xstFileHandle.read()
			
		xstTemplateDictionary = {
			'prjFile' :													str(prjFilePath),
			'UseNewParser' :										self.host.netListConfig[str(pocEntity)]['XSTOption.UseNewParser'],
			'InputFormat' :											self.host.netListConfig[str(pocEntity)]['XSTOption.InputFormat'],
			'OutputFormat' :										self.host.netListConfig[str(pocEntity)]['XSTOption.OutputFormat'],
			'OutputName' :											topModuleName,
			'Part' :														str(device),
			'TopModuleName' :										topModuleName,
			'OptimizationMode' :								self.host.netListConfig[str(pocEntity)]['XSTOption.OptimizationMode'],
			'OptimizationLevel' :								self.host.netListConfig[str(pocEntity)]['XSTOption.OptimizationLevel'],
			'PowerReduction' :									self.host.netListConfig[str(pocEntity)]['XSTOption.PowerReduction'],
			'IgnoreSynthesisConstraintsFile' :	self.host.netListConfig[str(pocEntity)]['XSTOption.IgnoreSynthesisConstraintsFile'],
			'SynthesisConstraintsFile' :				str(xcfFilePath),
			'KeepHierarchy' :										self.host.netListConfig[str(pocEntity)]['XSTOption.KeepHierarchy'],
			'NetListHierarchy' :								self.host.netListConfig[str(pocEntity)]['XSTOption.NetListHierarchy'],
			'GenerateRTLView' :									self.host.netListConfig[str(pocEntity)]['XSTOption.GenerateRTLView'],
			'GlobalOptimization' :							self.host.netListConfig[str(pocEntity)]['XSTOption.Globaloptimization'],
			'ReadCores' :												self.host.netListConfig[str(pocEntity)]['XSTOption.ReadCores'],
			'SearchDirectories' :								'"%s"' % str(xstOutputPath),
			'WriteTimingConstraints' :					self.host.netListConfig[str(pocEntity)]['XSTOption.WriteTimingConstraints'],
			'CrossClockAnalysis' :							self.host.netListConfig[str(pocEntity)]['XSTOption.CrossClockAnalysis'],
			'HierarchySeparator' :							self.host.netListConfig[str(pocEntity)]['XSTOption.HierarchySeparator'],
			'BusDelimiter' :										self.host.netListConfig[str(pocEntity)]['XSTOption.BusDelimiter'],
			'Case' :														self.host.netListConfig[str(pocEntity)]['XSTOption.Case'],
			'SliceUtilizationRatio' :						self.host.netListConfig[str(pocEntity)]['XSTOption.SliceUtilizationRatio'],
			'BRAMUtilizationRatio' :						self.host.netListConfig[str(pocEntity)]['XSTOption.BRAMUtilizationRatio'],
			'DSPUtilizationRatio' :							self.host.netListConfig[str(pocEntity)]['XSTOption.DSPUtilizationRatio'],
			'LUTCombining' :										self.host.netListConfig[str(pocEntity)]['XSTOption.LUTCombining'],
			'ReduceControlSets' :								self.host.netListConfig[str(pocEntity)]['XSTOption.ReduceControlSets'],
			'Verilog2001' :											self.host.netListConfig[str(pocEntity)]['XSTOption.Verilog2001'],
			'FSMExtract' :											self.host.netListConfig[str(pocEntity)]['XSTOption.FSMExtract'],
			'FSMEncoding' :											self.host.netListConfig[str(pocEntity)]['XSTOption.FSMEncoding'],
			'FSMSafeImplementation' :						self.host.netListConfig[str(pocEntity)]['XSTOption.FSMSafeImplementation'],
			'FSMStyle' :												self.host.netListConfig[str(pocEntity)]['XSTOption.FSMStyle'],
			'RAMExtract' :											self.host.netListConfig[str(pocEntity)]['XSTOption.RAMExtract'],
			'RAMStyle' :												self.host.netListConfig[str(pocEntity)]['XSTOption.RAMStyle'],
			'ROMExtract' :											self.host.netListConfig[str(pocEntity)]['XSTOption.ROMExtract'],
			'ROMStyle' :												self.host.netListConfig[str(pocEntity)]['XSTOption.ROMStyle'],
			'MUXExtract' :											self.host.netListConfig[str(pocEntity)]['XSTOption.MUXExtract'],
			'MUXStyle' :												self.host.netListConfig[str(pocEntity)]['XSTOption.MUXStyle'],
			'DecoderExtract' :									self.host.netListConfig[str(pocEntity)]['XSTOption.DecoderExtract'],
			'PriorityExtract' :									self.host.netListConfig[str(pocEntity)]['XSTOption.PriorityExtract'],
			'ShRegExtract' :										self.host.netListConfig[str(pocEntity)]['XSTOption.ShRegExtract'],
			'ShiftExtract' :										self.host.netListConfig[str(pocEntity)]['XSTOption.ShiftExtract'],
			'XorCollapse' :											self.host.netListConfig[str(pocEntity)]['XSTOption.XorCollapse'],
			'AutoBRAMPacking' :									self.host.netListConfig[str(pocEntity)]['XSTOption.AutoBRAMPacking'],
			'ResourceSharing' :									self.host.netListConfig[str(pocEntity)]['XSTOption.ResourceSharing'],
			'ASyncToSync' :											self.host.netListConfig[str(pocEntity)]['XSTOption.ASyncToSync'],
			'UseDSP48' :												self.host.netListConfig[str(pocEntity)]['XSTOption.UseDSP48'],
			'IOBuf' :														self.host.netListConfig[str(pocEntity)]['XSTOption.IOBuf'],
			'MaxFanOut' :												self.host.netListConfig[str(pocEntity)]['XSTOption.MaxFanOut'],
			'BufG' :														self.host.netListConfig[str(pocEntity)]['XSTOption.BufG'],
			'RegisterDuplication' :							self.host.netListConfig[str(pocEntity)]['XSTOption.RegisterDuplication'],
			'RegisterBalancing' :								self.host.netListConfig[str(pocEntity)]['XSTOption.RegisterBalancing'],
			'SlicePacking' :										self.host.netListConfig[str(pocEntity)]['XSTOption.SlicePacking'],
			'OptimizePrimitives' :							self.host.netListConfig[str(pocEntity)]['XSTOption.OptimizePrimitives'],
			'UseClockEnable' :									self.host.netListConfig[str(pocEntity)]['XSTOption.UseClockEnable'],
			'UseSyncSet' :											self.host.netListConfig[str(pocEntity)]['XSTOption.UseSyncSet'],
			'UseSyncReset' :										self.host.netListConfig[str(pocEntity)]['XSTOption.UseSyncReset'],
			'PackIORegistersIntoIOBs' :					self.host.netListConfig[str(pocEntity)]['XSTOption.PackIORegistersIntoIOBs'],
			'EquivalentRegisterRemoval' :				self.host.netListConfig[str(pocEntity)]['XSTOption.EquivalentRegisterRemoval'],
			'SliceUtilizationRatioMaxMargin' :	self.host.netListConfig[str(pocEntity)]['XSTOption.SliceUtilizationRatioMaxMargin']
		}
		
		xstFileContent = xstFileContent.format(**xstTemplateDictionary)
		
		if (self.host.netListConfig.has_option(str(pocEntity), 'XSTOption.Generics')):
			xstFileContent += "-generics { %s }" % self.host.netListConfig[str(pocEntity)]['XSTOption.Generics']

		self.printDebug("Writing Xilinx Compiler Tool option file to '%s'" % str(xstFilePath))
		with xstFilePath.open('w') as xstFileHandle:
			xstFileHandle.write(xstFileContent)
	
#		else:		# xstFilePath exists
#			self.printDebug("Copy XST options file from '%s' to '%s'" % (str(xstOptionsFilePath), str(xstFilePath)))
#			shutil.copy(str(xstOptionsFilePath), str(xstFilePath))
		
		# parse project filelist
		filesLineRegExpStr =	r"\s*(?P<Keyword>(vhdl(\-(87|93|02|08))?|xilinx))"		# Keywords: vhdl[-nn], xilinx
		filesLineRegExpStr += r"\s+(?P<VHDLLibrary>[_a-zA-Z0-9]+)"									#	VHDL library name
		filesLineRegExpStr += r"\s+\"(?P<VHDLFile>.*?)\""														# VHDL filename without "-signs
		filesLineRegExp = re.compile(filesLineRegExpStr)

		self.printDebug("Reading filelist '%s'" % str(fileListFilePath))
		xstProjectFileContent = ""
		with fileListFilePath.open('r') as prjFileHandle:
			for line in prjFileHandle:
				filesLineRegExpMatch = filesLineRegExp.match(line)
				
				if (filesLineRegExpMatch is not None):
					if (filesLineRegExpMatch.group('Keyword') == "vhdl"):
						vhdlFileName = filesLineRegExpMatch.group('VHDLFile')
						vhdlFilePath = self.host.directories["PoCRoot"] / vhdlFileName
					elif (filesLineRegExpMatch.group('Keyword')[0:5] == "vhdl-"):
						if (filesLineRegExpMatch.group('Keyword')[-2:] == self.__vhdlStandard):
							vhdlFileName = filesLineRegExpMatch.group('VHDLFile')
							vhdlFilePath = self.host.directories["PoCRoot"] / vhdlFileName
					elif (filesLineRegExpMatch.group('Keyword') == "xilinx"):
						vhdlFileName = filesLineRegExpMatch.group('VHDLFile')
						vhdlFilePath = self.host.directories["XilinxPrimitiveSource"] / vhdlFileName
					
					vhdlLibraryName = filesLineRegExpMatch.group('VHDLLibrary')
					xstProjectFileContent += "vhdl %s \"%s\"\n" % (vhdlLibraryName, str(vhdlFilePath))
					
					if (not vhdlFilePath.exists()):
						raise CompilerException("Can not add '" + vhdlFileName + "' to project file.") from FileNotFoundError(str(vhdlFilePath))
		
		# write iSim project file
		self.printDebug("Writing XST project file to '%s'" % str(prjFilePath))
		with prjFilePath.open('w') as prjFileHandle:
			prjFileHandle.write(xstProjectFileContent)

		# change working directory to temporary XST path
		self.printVerbose('    cd "%s"' % str(tempXstPath))
		os.chdir(str(tempXstPath))
		
		# running XST
		# ==========================================================================
		self.printNonQuiet("  running XST...")
		# assemble XST command as list of parameters
		parameterList = [
			str(xstExecutablePath),
			'-intstyle', 'xflow',
			'-filter', str(filterFilePath),
			'-ifn', str(xstFilePath),
			'-ofn', str(reportFilePath)
		]
		self.printDebug("call xst: %s" % str(parameterList))
		self.printVerbose('    %s -intstyle xflow -filter "%s" -ifn "%s" -ofn "%s"' % (str(xstExecutablePath), str(fileListFilePath), str(xstFilePath), str(reportFilePath)))
		if (self.dryRun == False):
			try:
				xstLog = subprocess.check_output(parameterList, stderr=subprocess.STDOUT, universal_newlines=True)
				if self.showLogs:
					print("XST log file:")
					print("--------------------------------------------------------------------------------")
					print(xstLog)
					print()
			
			except subprocess.CalledProcessError as ex:
				print("ERROR while executing XST")
				print("Return Code: %i" % ex.returncode)
				print("--------------------------------------------------------------------------------")
				print(ex.output)
				return
			
		# copy resulting files into PoC's netlist directory
		self.printNonQuiet('  copy result files into output directory...')
		for task in copyTasks:
			(fromPath, toPath) = task
			if not fromPath.exists(): raise CompilerException("Can not copy '{0}' to destination.".format(str(fromPath))) from FileNotFoundError(str(fromPath))
			
			toDirectoryPath = toPath.parent
			if not toDirectoryPath.exists():
				toDirectoryPath.mkdir(parents=True)
		
			self.printVerbose("  copying '{0}'.".format(fromPath))
			shutil.copy(str(fromPath), str(toPath))
		
		# replace in resulting files
		self.printNonQuiet('  replace in result files...')
		for task in replaceTasks:
			(fromPath, options, search, replace) = task
			if not fromPath.exists(): raise CompilerException("Can not replace in file '{0}' to destination.".format(str(fromPath))) from FileNotFoundError(str(fromPath))
			
			self.printVerbose("  replace in file '{0}': search for '{1}' -> replace by '{2}'.".format(str(fromPath), search, replace))
			
			regExpFlags	 = 0
			if ('i' in options):
				regExpFlags |= re.IGNORECASE
			if ('m' in options):
				regExpFlags |= re.MULTILINE
			if ('d' in options):
				regExpFlags |= re.DOTALL
			
			regExp = re.compile(search, regExpFlags)
			
			with fromPath.open('r') as fileHandle:
				FileContent = fileHandle.read()
			
			NewContent = re.sub(regExp, replace, FileContent)
			
			with fromPath.open('w') as fileHandle:
				fileHandle.write(NewContent)
		
		
