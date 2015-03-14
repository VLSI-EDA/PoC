# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
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

# entry point
if __name__ != "__main__":
	# place library initialization code here
	pass
else:
	from sys import exit

	print("=" * 80)
	print("{: ^80s}".format("PoC Library - Python Class PoCXSTCompiler"))
	print("=" * 80)
	print()
	print("This is no executable file!")
	exit(1)

from pathlib import Path
import re
	
import PoCCompiler

class PoCXSTCompiler(PoCCompiler.PoCCompiler):

	executables = {}

	def __init__(self, host, showLogs, showReport):
		super(self.__class__, self).__init__(host, showLogs, showReport)

		self.__executables = {
			'XST' :	("xst.exe"	if (host.platform == "Windows") else "xst")
		}
		
	def run(self, pocEntity, device):
		import os
		import shutil
		import subprocess
		import textwrap
	
		self.printNonQuiet(str(pocEntity))
		self.printNonQuiet("  preparing compiler environment...")

		# TODO: improve / resolve board to device
		deviceString = str(device).upper()
		deviceSection = "Device." + deviceString
		
		# create temporary directory for XST if not existent
		tempXSTPath = self.host.directories["XSTTemp"]
		if not (tempXSTPath).exists():
			self.printVerbose("Creating temporary directory for core generator files.")
			self.printDebug("Temporary directors: %s" % str(tempXSTPath))
			tempXSTPath.mkdir(parents=True)

		# create output directory for XST if not existent
		coreGenOutputPath = self.host.directories["PoCNetList"] / deviceString
		if not (coreGenOutputPath).exists():
			self.printVerbose("Creating temporary directory for core generator files.")
			self.printDebug("Temporary directors: %s" % str(coreGenOutputPath))
			coreGenOutputPath.mkdir(parents=True)
			
		# add the key Device to section SPECIAL at runtime to change interpolation results
		self.host.netListConfig['SPECIAL'] = {}
		self.host.netListConfig['SPECIAL']['Device'] = deviceString
		self.host.netListConfig['SPECIAL']['OutputDir'] = tempXSTPath.as_posix()
		
		# read copy tasks
#		copyFileList = self.host.netListConfig[str(pocEntity)]['Copy']
#		self.printDebug("CopyTasks: \n  " + ("\n  ".join(copyFileList.split("\n"))))
#		copyTasks = []
#		for item in copyFileList.split("\n"):
#			list1 = re.split("\s+->\s+", item)
#			if (len(list1) != 2):				raise PoCCompiler.PoCCompilerException("Expected 2 arguments for every copy task!")
#			
#			copyTasks.append((Path(list1[0]), Path(list1[1])))
		
		# setup all needed paths to execute XST
		xstExecutablePath =		self.host.directories["ISEBinary"] / self.__executables['XST']
		
		# read netlist settings from configuration file
		if (self.host.netListConfig[str(pocEntity)]['Type'] != "XilinxSynthesis"):
			raise PoC.PoCCompilerException("This entity is not configured for XST compilation.")
		
		topModuleName =				self.host.netListConfig[str(pocEntity)]['TopModule']
		fileListFilePath =		self.host.directories["PoCRoot"] / self.host.netListConfig[str(pocEntity)]['FileListFile']
		xcfFilePath =					self.host.directories["PoCRoot"] / self.host.netListConfig[str(pocEntity)]['XSTConstraintsFile']
		filterFilePath =			self.host.directories["PoCRoot"] / self.host.netListConfig[str(pocEntity)]['XSTFilterFile']
		xstTemplateFilePath =	self.host.directories["XSTFiles"] / "template.xst"
		xstFilePath =					tempXSTPath / (topModuleName + ".xst")
		prjFilePath =					tempXSTPath / (topModuleName + ".prj")
		reportFilePath =			tempXSTPath / (topModuleName + ".log")

		# read/write XST options file
		self.printDebug("Reading Xilinx Synthesis Tool option file from '%s'" % str(xstTemplateFilePath))
		with xstTemplateFilePath.open('r') as xstFileHandle:
			xstFileContent = xstFileHandle.read()
			
		xstTemplateDictionary = {
			'prjFile' :													str(prjFilePath),
			'UseNewParser' :										self.host.netListConfig[str(pocEntity)]['XSTOption.UseNewParser'],
			'InputFormat' :											self.host.netListConfig[str(pocEntity)]['XSTOption.InputFormat'],
			'OutputFormat' :										self.host.netListConfig[str(pocEntity)]['XSTOption.OutputFormat'],
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
			'SearchDirectories' :								'"%s"' % str(coreGenOutputPath),
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

		self.printDebug("Writing Xilinx Synthesis Tool option file to '%s'" % str(xstFilePath))
		with xstFilePath.open('w') as xstFileHandle:
			xstFileHandle.write(xstFileContent)
		
		# parse project filelist
		regExpStr =	 r"\s*(?P<Keyword>(vhdl|xilinx))"				# Keywords: vhdl, xilinx
		regExpStr += r"\s+(?P<VHDLLibrary>[_a-zA-Z0-9]+)"		#	VHDL library name
		regExpStr += r"\s+\"(?P<VHDLFile>.*?)\""						# VHDL filename without "-signs
		regExp = re.compile(regExpStr)

		self.printDebug("Reading filelist '%s'" % str(fileListFilePath))
		xstProjectFileContent = ""
		with fileListFilePath.open('r') as prjFileHandle:
			for line in prjFileHandle:
				regExpMatch = regExp.match(line)
				
				if (regExpMatch is not None):
					if (regExpMatch.group('Keyword') == "vhdl"):
						vhdlFilePath = self.host.directories["PoCRoot"] / regExpMatch.group('VHDLFile')
					elif (regExpMatch.group('Keyword') == "xilinx"):
						vhdlFilePath = self.host.directories["ISEInstallation"] / "ISE/vhdl/src" / regExpMatch.group('VHDLFile')
					vhdlLibraryName = regExpMatch.group('VHDLLibrary')
					xstProjectFileContent += "vhdl %s \"%s\"\n" % (vhdlLibraryName, str(vhdlFilePath))
		
		# write XST project file
		self.printDebug("Writing XST project file to '%s'" % str(prjFilePath))
		with prjFilePath.open('w') as prjFileHandle:
			prjFileHandle.write(xstProjectFileContent)
		
		
		# change working directory to temporary XST path
		self.printVerbose('    cd "%s"' % str(tempXSTPath))
		os.chdir(str(tempXSTPath))
		
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
			xstLog = subprocess.check_output(parameterList, stderr=subprocess.STDOUT, universal_newlines=True)
		
			if self.showLogs:
				print("Synthesis log (XST)")
				print("--------------------------------------------------------------------------------")
				print(xstLog)
				print()
		
		print("return...")
		return
		
		# copy resulting files into PoC's netlist directory
		self.printNonQuiet('  copy result files into output directory...')
		for task in copyTasks:
			(fromPath, toPath) = task
			if not fromPath.exists():		raise PoCCompiler.PoCCompilerException("File '%s' does not exist!" % str(fromPath))
			#if not toPath.exists():			raise PoCCompiler.PoCCompilerException("File '%s' does not exist!" % str(toPath))
		
			self.printVerbose("  copying '%s'" % str(fromPath))
			shutil.copy(str(fromPath), str(toPath))
		