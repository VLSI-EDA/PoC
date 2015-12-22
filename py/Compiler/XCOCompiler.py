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
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Class Compiler(PoCCompiler)")

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
			self.__executables['CoreGen'] =	"coregen.exe"
		elif (host.platform == "Linux"):
			self.__executables['CoreGen'] =	"coregen"
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
		
		# create temporary directory for CoreGen if not existent
		tempCoreGenPath = self.host.directories["CoreGenTemp"]
		if not (tempCoreGenPath).exists():
			self.printVerbose("    Creating temporary directory for core generator files.")
			self.printDebug("    Temporary directory: {0}.".format(tempCoreGenPath))
			tempCoreGenPath.mkdir(parents=True)

		# create output directory for CoreGen if not existent
		coreGenOutputPath = self.host.directories["PoCNetList"] / deviceString
		if not (coreGenOutputPath).exists():
			self.printVerbose("    Creating output directory for core generator files.")
			self.printDebug("    Output directory: {0}.".format(coreGenOutputPath))
			coreGenOutputPath.mkdir(parents=True)
			
		# add the key Device to section SPECIAL at runtime to change interpolation results
		self.host.netListConfig['SPECIAL'] = {}
		self.host.netListConfig['SPECIAL']['Device'] = deviceString
		self.host.netListConfig['SPECIAL']['OutputDir'] = tempCoreGenPath.as_posix()
		
		if not self.host.netListConfig.has_section(str(pocEntity)):
			from configparser import NoSectionError
			raise CompilerException("IP-Core '{0}' not found.".format(str(pocEntity))) from NoSectionError(str(pocEntity))
		
		# read copy tasks
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
			replaceRegExpStr += r"(?P<Options>[im]{0,2}):\s+"			#	RegExp options
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
		
		# setup all needed paths to execute coreGen
		coreGenExecutablePath =		self.host.directories["ISEBinary"] / self.__executables['CoreGen']
		
		# read netlist settings from configuration file
		ipCoreName =					self.host.netListConfig[str(pocEntity)]['IPCoreName']
		xcoInputFilePath =		self.host.directories["PoCRoot"] / self.host.netListConfig[str(pocEntity)]['CoreGeneratorFile']
		cgcTemplateFilePath =	self.host.directories["PoCNetList"] / "template.cgc"
		cgpFilePath =					tempCoreGenPath / "coregen.cgp"
		cgcFilePath =					tempCoreGenPath / "coregen.cgc"
		xcoFilePath =					tempCoreGenPath / xcoInputFilePath.name

		# report the next steps in execution
#		if (self.getVerbose()):
#			print("  Commands to be run:")
#			print("  1. Write CoreGen project file into temporary directory.")
#			print("  2. Write CoreGen content file into temporary directory.")
#			print("  3. Copy IPCore's *.xco file into temporary directory.")
#			print("  4. Change working directory to temporary directory.")
#			print("  5. Run Xilinx Core Generator (coregen).")
#			print("  6. Copy resulting files into output directory.")
#			print("  ----------------------------------------")
		
		if (self.host.platform == "Windows"):
			WorkingDirectory = ".\\temp\\"
		else:
			WorkingDirectory = "./temp/"
		
		# write CoreGenerator project file
		cgProjectFileContent = textwrap.dedent('''\
			SET addpads = false
			SET asysymbol = false
			SET busformat = BusFormatAngleBracketNotRipped
			SET createndf = false
			SET designentry = VHDL
			SET device = {Device}
			SET devicefamily = {DeviceFamily}
			SET flowvendor = Other
			SET formalverification = false
			SET foundationsym = false
			SET implementationfiletype = Ngc
			SET package = {Package}
			SET removerpms = false
			SET simulationfiles = Behavioral
			SET speedgrade = {SpeedGrade}
			SET verilogsim = false
			SET vhdlsim = true
			SET workingdirectory = {WorkingDirectory}
			'''.format(
				Device=device.shortName(),
				DeviceFamily=device.familyName(),
				Package=(str(device.package) + str(device.pinCount)),
				SpeedGrade=device.speedGrade,
				WorkingDirectory=WorkingDirectory
			))

		self.printDebug("Writing CoreGen project file to '{0}'.".format(cgpFilePath))
		with cgpFilePath.open('w') as cgpFileHandle:
			cgpFileHandle.write(cgProjectFileContent)

		# write CoreGenerator content? file
		self.printDebug("Reading CoreGen content file to '{0}'.".format(cgcTemplateFilePath))
		with cgcTemplateFilePath.open('r') as cgcFileHandle:
			cgContentFileContent = cgcFileHandle.read()
			
		cgContentFileContent = cgContentFileContent.format(
			name="lcd_ChipScopeVIO",
			device=device.shortName(),
			devicefamily=device.familyName(),
			package=(str(device.package) + str(device.pinCount)),
			speedgrade=device.speedGrade
		)

		self.printDebug("Writing CoreGen content file to '{0}'.".format(cgcFilePath))
		with cgcFilePath.open('w') as cgcFileHandle:
			cgcFileHandle.write(cgContentFileContent)
		
		# copy xco file into temporary directory
		self.printDebug("Copy CoreGen xco file to '{0}'.".format(xcoFilePath))
		self.printVerbose("    cp {0} {1}".format(str(xcoInputFilePath), str(tempCoreGenPath)))
		shutil.copy(str(xcoInputFilePath), str(xcoFilePath), follow_symlinks=True)
		
		# change working directory to temporary CoreGen path
		self.printVerbose('    cd {0}'.format(str(tempCoreGenPath)))
		os.chdir(str(tempCoreGenPath))
		
		# running CoreGen
		# ==========================================================================
		self.printNonQuiet("  running CoreGen...")
		# assemble CoreGen command as list of parameters
		parameterList = [
			str(coreGenExecutablePath),
			'-r',
			'-b', str(xcoFilePath),
			'-p', '.'
		]
		self.printDebug("call coreGen: {0}.".format(parameterList))
		self.printVerbose('    {0} -r -b "{1}" -p .'.format(str(coreGenExecutablePath), str(xcoFilePath)))
		if (self.dryRun == False):
			coreGenLog = subprocess.check_output(parameterList, stderr=subprocess.STDOUT, universal_newlines=True)
		
			if self.showLogs:
				print("Core Generator log (CoreGen)")
				print("--------------------------------------------------------------------------------")
				print(coreGenLog)
				print()
		
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
			
			regExpFlags	 = re.DOTALL
			if ('i' in options):
				regExpFlags |= re.IGNORECASE
			if ('m' in options):
				regExpFlags |= re.MULTILINE
			
			regExp = re.compile(search, regExpFlags)
			
			with fromPath.open('r') as fileHandle:
				FileContent = fileHandle.read()
			
			NewContent = re.sub(regExp, replace, FileContent)
			
			with fromPath.open('w') as fileHandle:
				fileHandle.write(NewContent)
		