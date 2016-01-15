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
from pathlib import Path

from Base.Exceptions import *
from Simulator.Base import PoCSimulator 
from Simulator.Exceptions import * 

class Simulator(PoCSimulator):

	__executables =		{}
	__vhdlStandard =	"93"
	__guiMode =				False

	def __init__(self, host, showLogs, showReport, vhdlStandard, guiMode):
		super(self.__class__, self).__init__(host, showLogs, showReport)

		self.__vhdlStandard =	vhdlStandard
		self.__guiMode =			guiMode

		self.__initExecutables()
	
	def __initExecutables(self):
		if (self.host.platform == "Windows"):
			self.__executables['ghdl'] =		"ghdl.exe"
			self.__executables['gtkwave'] =	"gtkwave.exe"
		elif (self.host.platform == "Linux"):
			self.__executables['ghdl'] =		"ghdl"
			self.__executables['gtkwave'] =	"gtkwave"
		else:
			raise PlatformNotSupportedException(self.platform)
	
	def run(self, pocEntity):
		import os
		import re
		import subprocess
	
		self.printNonQuiet(str(pocEntity))
		self.printNonQuiet("  preparing simulation environment...")

		# create temporary directory for ghdl if not existent
		tempGHDLPath = self.host.directories["GHDLTemp"]
		if not (tempGHDLPath).exists():
			self.printVerbose("Creating temporary directory for simulator files.")
			self.printDebug("Temporary directors: %s" % str(tempGHDLPath))
			tempGHDLPath.mkdir(parents=True)

		if not self.host.tbConfig.has_section(str(pocEntity)):
			from configparser import NoSectionError
			raise SimulatorException("Testbench '" + str(pocEntity) + "' not found.") from NoSectionError(str(pocEntity))
			
		# setup all needed paths to execute fuse
		ghdlExecutablePath =	self.host.directories["GHDLBinary"] / self.__executables['ghdl']
		testbenchName =				self.host.tbConfig[str(pocEntity)]['TestbenchModule']
		waveformFileFormat =	self.host.tbConfig[str(pocEntity)]['ghdlWaveformFileFormat']
		fileListFilePath =		self.host.directories["PoCRoot"] / self.host.tbConfig[str(pocEntity)]['fileListFile']
		
		if (waveformFileFormat == "vcd"):
			waveformFilePath =	tempGHDLPath / (testbenchName + ".vcd")
		elif (waveformFileFormat == "vcdgz"):
			waveformFilePath =	tempGHDLPath / (testbenchName + ".vcd.gz")
		elif (waveformFileFormat == "fst"):
			waveformFilePath =	tempGHDLPath / (testbenchName + ".fst")
		elif (waveformFileFormat == "ghw"):
			waveformFilePath =	tempGHDLPath / (testbenchName + ".ghw")
		else:
			raise SimulatorException("Unknown waveform file format for GHDL.")
		
		if (self.__vhdlStandard == "93"):
			self.__vhdlStandard = "93c"
			self.__ieeeFlavor = "synopsys"
		elif (self.__vhdlStandard == "08"):
			self.__ieeeFlavor = "standard"
		
		# if (self.verbose):
			# print("  Commands to be run:")
			# print("  1. Change working directory to temporary directory")
			# print("  2. Parse filelist file.")
			# print("    a) For every file: Add the VHDL file to GHDL's compile cache.")
			# if (self.host.platform == "Windows"):
				# print("  3. Compile and run simulation")
			# elif (self.host.platform == "Linux"):
				# print("  3. Compile simulation")
				# print("  4. Run simulation")
			# print("  ----------------------------------------")
		
		# change working directory to temporary iSim path
		self.printVerbose('  cd "%s"' % str(tempGHDLPath))
		os.chdir(str(tempGHDLPath))

		# parse project filelist
		filesLineRegExpStr =	r"^"																						#	start of line
		filesLineRegExpStr =	r"(?:"																					#	open line type: empty, directive, keyword
		filesLineRegExpStr +=		r"(?P<EmptyLine>)|"														#		empty line
		filesLineRegExpStr +=		r"(?P<Directive>"															#		open directives:
		filesLineRegExpStr +=			r"(?P<DirInclude>@include)|"								#			 @include
		filesLineRegExpStr +=			r"(?P<DirLibrary>@library)"									#			 @library
		filesLineRegExpStr +=		r")|"																					#		close directives
		filesLineRegExpStr +=		r"(?P<Keyword>"																#		open keywords:
		filesLineRegExpStr +=			r"(?P<KwAltera>altera)|"										#			altera
		filesLineRegExpStr +=			r"(?P<KwXilinx>xilinx)|"										#			xilinx
		filesLineRegExpStr +=			r"(?P<KwVHDL>vhdl"													#			vhdl[-nn]
		filesLineRegExpStr +=				r"(?:-(?P<VHDLStandard>87|93|02|08))?)"		#				VHDL Standard Year: [-nn]
		filesLineRegExpStr +=		r")"																					#		close keywords
		filesLineRegExpStr +=	r")"																						#	close line type
		filesLineRegExpStr +=	r"(?(Directive)\s+(?:"													#	open directive parameters
		filesLineRegExpStr +=		r"(?(DirInclude)"															#		open @include directive
		filesLineRegExpStr +=			r"\"(?P<IncludeFile>.*?\.files)\""					#			*.files filename without enclosing "-signs
		filesLineRegExpStr +=		r")|"																					#		close @include directive
		filesLineRegExpStr +=		r"(?(DirLibrary)"															#		open @include directive
		filesLineRegExpStr +=			r"(?P<LibraryName>[_a-zA-Z0-9]+)"						#			VHDL library name
		filesLineRegExpStr +=			r"\s+"																			#			delimiter
		filesLineRegExpStr +=			r"\"(?P<LibraryPath>.*?)\""									#			VHDL library path without enclosing "-signs
		filesLineRegExpStr +=		r")"																					#		close @library directive
		filesLineRegExpStr +=	r"))"																						#	close directive parameters
		filesLineRegExpStr +=	r"(?(Keyword)\s+(?:"														#	open keyword parameters
		filesLineRegExpStr +=		r"(?P<VHDLLibrary>[_a-zA-Z0-9]+)"							#		VHDL library name
		filesLineRegExpStr +=		r"\s+"																				#		delimiter
		filesLineRegExpStr +=		r"\"(?P<VHDLFile>.*?\.vhdl?)\""								#		*.vhdl? filename without enclosing "-signs
		filesLineRegExpStr +=	r"))"																						#	close keyword parameters
		filesLineRegExpStr +=	r"\s*(?P<Comment>#.*)?"													#	optional comment until line end
		filesLineRegExpStr +=	r"$"																						#	end of line
		filesLineRegExp = re.compile(filesLineRegExpStr)

		self.printDebug("Reading filelist '%s'" % str(fileListFilePath))
		self.printNonQuiet("  running analysis for every vhdl file...")
		
		# add empty line if logs are enabled
		if self.showLogs:		print()
		
		externalLibraries = []
		
		with fileListFilePath.open('r') as fileFileHandle:
			for line in fileFileHandle:
				filesLineRegExpMatch = filesLineRegExp.match(line)
		
				if (filesLineRegExpMatch is not None):
					if (filesLineRegExpMatch.group('Directive') is not None):
						if (filesLineRegExpMatch.group('DirInclude') is not None):
							includeFile = filesLineRegExpMatch.group('IncludeFile')
							self.printVerbose("    referencing another file: {0}".format(includeFile))
						elif (filesLineRegExpMatch.group('DirLibrary') is not None):
							externalLibraryName = filesLineRegExpMatch.group('LibraryName')
							externalLibraryPath = filesLineRegExpMatch.group('LibraryPath')
							
							self.printVerbose("    referencing precompiled VHDL library: {0}".format(externalLibraryName))
							externalLibraries.append(externalLibraryPath)
						else:
							raise SimulatorException("Unknown directive in *.files file.")
						
						continue
						
					elif (filesLineRegExpMatch.group('Keyword') is not None):
						if (filesLineRegExpMatch.group('Keyword') == "vhdl"):
							vhdlFileName = filesLineRegExpMatch.group('VHDLFile')
							vhdlFilePath = self.host.directories["PoCRoot"] / vhdlFileName
						elif (filesLineRegExpMatch.group('Keyword')[0:5] == "vhdl-"):
							if (filesLineRegExpMatch.group('Keyword')[-2:] == self.__vhdlStandard[:2]):
								vhdlFileName = filesLineRegExpMatch.group('VHDLFile')
								vhdlFilePath = self.host.directories["PoCRoot"] / vhdlFileName
							else:
								continue
						elif (filesLineRegExpMatch.group('Keyword') == "altera"):
							# check if Quartus is configured
							if not self.host.directories.__contains__("AlteraPrimitiveSource"):
								raise NotConfiguredException("This testbench requires some Altera Primitves. Please configure Altera Quartus II.")
						
							vhdlFileName = filesLineRegExpMatch.group('VHDLFile')
							vhdlFilePath = self.host.directories["AlteraPrimitiveSource"] / vhdlFileName
						elif (filesLineRegExpMatch.group('Keyword') == "xilinx"):
							# check if ISE or Vivado is configured
							if not self.host.directories.__contains__("XilinxPrimitiveSource"):
								raise NotConfiguredException("This testbench requires some Xilinx Primitves. Please configure Xilinx ISE or Vivado.")
							
							vhdlFileName = filesLineRegExpMatch.group('VHDLFile')
							vhdlFilePath = self.host.directories["XilinxPrimitiveSource"] / vhdlFileName
						else:
							raise SimulatorException("Unknown keyword in *.files file.")
					elif (filesLineRegExpMatch.group('EmptyLine') is not None):
						continue
					else:
						raise SimulatorException("Unknown line in *.files file.")
					
					vhdlLibraryName = filesLineRegExpMatch.group('VHDLLibrary')

					if (not vhdlFilePath.exists()):
						raise SimulatorException("Can not analyse '" + vhdlFileName + "'.") from FileNotFoundError(str(vhdlFilePath))
					
					# assemble fuse command as list of parameters
					parameterList = [
						str(ghdlExecutablePath),
						'-a',
						'-fexplicit', '-frelaxed-rules', '--warn-binding', '--no-vital-checks', '--mb-comments', '--syn-binding',
						'-fpsl',
						'-v'
					]
					
					for path in externalLibraries:
						parameterList.append("-P{0}".format(path))
					
					parameterList += [
						('--ieee=%s' % self.__ieeeFlavor),
						('--std=%s' % self.__vhdlStandard),
						('--work=%s' % vhdlLibraryName),
						str(vhdlFilePath)
					]
					command = " ".join(parameterList)
					
					self.printDebug("call ghdl: %s" % str(parameterList))
					self.printVerbose("    command: %s" % command)
					
					try:
						ghdlLog = subprocess.check_output(parameterList, stderr=subprocess.STDOUT, shell=False, universal_newlines=True)

						if self.showLogs:
							if (ghdlLog != ""):
								print("ghdl messages for : %s" % str(vhdlFilePath))
								print("-" * 80)
								print(ghdlLog)
								print("-" * 80)
						
					except subprocess.CalledProcessError as ex:
						print("ERROR while executing ghdl: %s" % str(vhdlFilePath))
						print("Return Code: %i" % ex.returncode)
						print("-" * 80)
						print(ex.output)
						print("-" * 80)
						
						return
						
				else:
					raise SimulatorException("Error in *.files file.")

		
		# running simulation
		# ==========================================================================
		simulatorLog = ""
		
		# run GHDL simulation on Windows
		if (self.host.platform == "Windows"):
			self.printNonQuiet("  running simulation...")
		
			parameterList = [
				str(ghdlExecutablePath),
				'-r',
				'--syn-binding',
				'-fpsl',
				'-v'
			]
			
			for path in externalLibraries:
				parameterList.append("-P{0}".format(path))
			
			parameterList += [
				('--std=%s' % self.__vhdlStandard),
				'--work=test',
				testbenchName
			]

			# append RUNOPTS
			parameterList += [('--ieee-asserts={0}'.format("disable-at-0"))]		# enable, disable, disable-at-0
			
			# set dump format to save simulation results to *.vcd file
			if (self.__guiMode):
				if (waveformFileFormat == "vcd"):
					parameterList += [("--vcd={0}".format(str(waveformFilePath)))]
				elif (waveformFileFormat == "vcdgz"):
					parameterList += [("--vcdgz={0}".format(str(waveformFilePath)))]
				elif (waveformFileFormat == "fst"):
					parameterList += [("--fst={0}".format(str(waveformFilePath)))]
				elif (waveformFileFormat == "ghw"):
					parameterList += [("--wave={0}".format(str(waveformFilePath)))]
			
			command = " ".join(parameterList)
		
			self.printDebug("call ghdl: %s" % str(parameterList))
			self.printVerbose("    command: %s" % command)
			
			try:
				simulatorLog = subprocess.check_output(parameterList, stderr=subprocess.STDOUT, shell=False, universal_newlines=True)
				# 
				if self.showLogs:
					if (simulatorLog != ""):
						print("ghdl messages for : %s" % str(vhdlFilePath))
						print("-" * 80)
						print(simulatorLog)
						print("-" * 80)
				
			except subprocess.CalledProcessError as ex:
				print("ERROR while executing ghdl command: %s" % command)
				print("Return Code: %i" % ex.returncode)
				print("-" * 80)
				print(ex.output)
				print("-" * 80)
				
				return

		# run GHDL simulation on Linux
		elif (self.host.platform == "Linux"):
			# preparing some variables for Linux
			exeFilePath =		tempGHDLPath / testbenchName.lower()
		
			# run elaboration
			self.printNonQuiet("  running elaboration...")
		
			parameterList = [
				str(ghdlExecutablePath),
				'-e', '--syn-binding',
				'-fpsl'
			]
			
			for path in externalLibraries:
				parameterList.append("-P{0}".format(path))
			
			parameterList += [
				('--ieee=%s' % self.__ieeeFlavor),
				('--std=%s' % self.__vhdlStandard),
				'--work=test',
				testbenchName
			]

			command = " ".join(parameterList)
		
			self.printDebug("call ghdl: %s" % str(parameterList))
			self.printVerbose("    command: %s" % command)
			try:
				elaborateLog = subprocess.check_output(parameterList, stderr=subprocess.STDOUT, shell=False, universal_newlines=True)
				# 
				if self.showLogs:
					if (elaborateLog != ""):
						print("ghdl elaborate messages:")
						print("-" * 80)
						print(elaborateLog)
						print("-" * 80)
				
			except subprocess.CalledProcessError as ex:
				print("ERROR while executing ghdl command: %s" % command)
				print("Return Code: %i" % ex.returncode)
				print("-" * 80)
				print(ex.output)
				print("-" * 80)
				
				return

			# search log for fatal warnings
			analyzeErrors = []
			elaborateLogRegExpStr =	r"(?P<VHDLFile>.*?):(?P<LineNumber>\d+):\d+:warning: component instance \"(?P<ComponentName>[a-z]+)\" is not bound"
			elaborateLogRegExp = re.compile(elaborateLogRegExpStr)

			for logLine in elaborateLog.splitlines():
				print("line: " + logLine)
				elaborateLogRegExpMatch = elaborateLogRegExp.match(logLine)
				if (elaborateLogRegExpMatch is not None):
					analyzeErrors.append({
						'Type' : "Unbound Component",
						'File' : elaborateLogRegExpMatch.group('VHDLFile'),
						'Line' : elaborateLogRegExpMatch.group('LineNumber'),
						'Component' : elaborateLogRegExpMatch.group('ComponentName')
					})
		
			if (len(analyzeErrors) != 0):
				print("  ERROR list:")
				for err in analyzeErrors:
					print("    %s: '%s' in file '%s' at line %s" % (err['Type'], err['Component'], err['File'], err['Line']))
			
				raise SimulatorException("Errors while GHDL analysis phase.")

	
			# run simulation
			self.printNonQuiet("  running simulation...")
		
			parameterList = [str(exeFilePath)]
			
			# append RUNOPTS
			parameterList += [('--ieee-asserts={0}'.format("disable-at-0"))]		# enable, disable, disable-at-0
			
			# set dump format to save simulation results to *.vcd file
			if (self.__guiMode):
				if (waveformFileFormat == "vcd"):
					parameterList += [("--vcd={0}".format(str(waveformFilePath)))]
				elif (waveformFileFormat == "vcdgz"):
					parameterList += [("--vcdgz={0}".format(str(waveformFilePath)))]
				elif (waveformFileFormat == "fst"):
					parameterList += [("--fst={0}".format(str(waveformFilePath)))]
				elif (waveformFileFormat == "ghw"):
					parameterList += [("--wave={0}".format(str(waveformFilePath)))]
				
			command = " ".join(parameterList)
		
			self.printDebug("call ghdl: %s" % str(parameterList))
			self.printVerbose("    command: %s" % command)
			try:
				simulatorLog = subprocess.check_output(parameterList, stderr=subprocess.STDOUT, shell=False, universal_newlines=True)
				
				# 
				if self.showLogs:
					if (simulatorLog != ""):
						print("ghdl messages for : %s" % str(vhdlFilePath))
						print("-" * 80)
						print(simulatorLog)
						print("-" * 80)
				
			except subprocess.CalledProcessError as ex:
				print("ERROR while executing ghdl command: %s" % command)
				print("Return Code: %i" % ex.returncode)
				print("-" * 80)
				print(ex.output)
				print("-" * 80)
				
				return

		print()
		
		if (not self.__guiMode):
			try:
				result = self.checkSimulatorOutput(simulatorLog)
				
				if (result is None):
					print("Testbench '{0}': NO ASSERTS PERFORMED".format(testbenchName))
				elif (result == True):
					print("Testbench '{0}': PASSED".format(testbenchName))
				else:
					print("Testbench '{0}': FAILED".format(testbenchName))
					
			except SimulatorException as ex:
				raise TestbenchException("PoC.ns.module", testbenchName, "'SIMULATION RESULT = [PASSED|FAILED|NOT IMPLEMENTED]' not found in simulator output.") from ex
		
		else:	# guiMode
			# run GTKWave GUI
			self.printNonQuiet("  launching GTKWave...")
			
			if (not waveformFilePath.exists()):
				raise SimulatorException("Waveform file not found.") from FileNotFoundError(str(waveformFilePath))

			gtkwExecutablePath =	self.host.directories["GTKWBinary"] / self.__executables['gtkwave']
			gtkwSaveFilePath =		self.host.directories["PoCRoot"] / self.host.tbConfig[str(pocEntity)]['gtkwSaveFile']
		
			parameterList = [
				str(gtkwExecutablePath),
				("--dump={0}".format(str(waveformFilePath)))
			]

			# if GTKWave savefile exists, load it's settings
			if gtkwSaveFilePath.exists():
				self.printDebug("Found waveform save file: '%s'" % str(gtkwSaveFilePath))
				parameterList += ['--save', str(gtkwSaveFilePath)]
			else:
				self.printDebug("Didn't find waveform save file: '%s'." % str(gtkwSaveFilePath))
			
			command = " ".join(parameterList)
		
			self.printDebug("call GTKWave: %s" % str(parameterList))
			self.printVerbose("    command: %s" % command)
			try:
				gtkwLog = subprocess.check_output(parameterList, stderr=subprocess.STDOUT, shell=False, universal_newlines=True)
				
				# 
				if self.showLogs:
					if (gtkwLog != ""):
						print("GTKWave messages:")
						print("-" * 80)
						print(gtkwLog)
						print("-" * 80)
				
			except subprocess.CalledProcessError as ex:
				print("ERROR while executing GTKWave command: %s" % command)
				print("Return Code: %i" % ex.returncode)
				print("-" * 80)
				print(ex.output)
				print("-" * 80)
				
				return
			
			
			
			
			
			
			
			
			
			
			
			
			
