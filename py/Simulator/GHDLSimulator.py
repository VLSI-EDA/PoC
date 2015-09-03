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
	print("{: ^80s}".format("The PoC Library - Python Module Simulator.GHDLSimulator"))
	print("=" * 80)
	print()
	print("This is no executable file!")
	exit(1)

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

		if (host.platform == "Windows"):
			self.__executables['ghdl'] =		"ghdl.exe"
			self.__executables['gtkwave'] =	"gtkwave.exe"
		elif (host.platform == "Linux"):
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

		# setup all needed paths to execute fuse
		ghdlExecutablePath =	self.host.directories["GHDLBinary"] / self.__executables['ghdl']
		testbenchName =				self.host.tbConfig[str(pocEntity)]['TestbenchModule']
		fileListFilePath =		self.host.directories["PoCRoot"] / self.host.tbConfig[str(pocEntity)]['fileListFile']
		vcdFilePath =					tempGHDLPath / (testbenchName + ".vcd")
		
		if (self.verbose):
			print("  Commands to be run:")
			print("  1. Change working directory to temporary directory")
			print("  2. Parse filelist file.")
			print("    a) For every file: Add the VHDL file to GHDL's compile cache.")
			if (self.host.platform == "Windows"):
				print("  3. Compile and run simulation")
			elif (self.host.platform == "Linux"):
				print("  3. Compile simulation")
				print("  4. Run simulation")
			print("  ----------------------------------------")
		
		# change working directory to temporary iSim path
		self.printVerbose('  cd "%s"' % str(tempGHDLPath))
		os.chdir(str(tempGHDLPath))

		# parse project filelist
		filesLineRegExpStr =	r"\s*(?P<Keyword>(vhdl(\-(87|93|02|08))?|xilinx))"				# Keywords: vhdl[-nn], xilinx
		filesLineRegExpStr +=	r"\s+(?P<VHDLLibrary>[_a-zA-Z0-9]+)"		#	VHDL library name
		filesLineRegExpStr +=	r"\s+\"(?P<VHDLFile>.*?)\""						# VHDL filename without "-signs
		filesLineRegExp = re.compile(filesLineRegExpStr)

		self.printDebug("Reading filelist '%s'" % str(fileListFilePath))
		self.printNonQuiet("  running analysis for every vhdl file...")
		
		# add empty line if logs are enabled
		if self.showLogs:		print()
		
		with fileListFilePath.open('r') as fileFileHandle:
			for line in fileFileHandle:
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
						# check if ISE or Vivado is configured
						if not self.host.directories.__contains__("XilinxPrimitiveSource"):
							raise NotConfiguredException("This testbench requires some Xilinx Primitves. Please configure Xilinx ISE or Vivado.")
						
						vhdlFileName = filesLineRegExpMatch.group('VHDLFile')
						vhdlFilePath = self.host.directories["XilinxPrimitiveSource"] / vhdlFileName
					
					vhdlLibraryName = filesLineRegExpMatch.group('VHDLLibrary')

					if (not vhdlFilePath.exists()):
						raise SimulatorException("Can not analyse '" + vhdlFileName + "'.") from FileNotFoundError(str(vhdlFilePath))
					
					# assemble fuse command as list of parameters
					parameterList = [
						str(ghdlExecutablePath),
						'-a', '-P.', '--syn-binding',
						('--std=%s' % self.__vhdlStandard),
						('--work=%s' % vhdlLibraryName),
						str(vhdlFilePath)
					]
					command = " ".join(parameterList)
					
					self.printDebug("call ghdl: %s" % str(parameterList))
					self.printVerbose("    command: %s" % command)
					
					try:
						ghdlLog = subprocess.check_output(parameterList, stderr=subprocess.STDOUT, shell=False, universal_newlines=True)
					except subprocess.CalledProcessError as ex:
							print("ERROR while executing ghdl: %s" % str(vhdlFilePath))
							print("Return Code: %i" % ex.returncode)
							print("--------------------------------------------------------------------------------")
							print(ex.output)

					if self.showLogs:
						if (ghdlLog != ""):
							print("ghdl messages for : %s" % str(vhdlFilePath))
							print("--------------------------------------------------------------------------------")
							print(ghdlLog)

		
		# running simulation
		# ==========================================================================
		simulatorLog = ""
		
		# run GHDL simulation on Windows
		if (self.host.platform == "Windows"):
			self.printNonQuiet("  running simulation...")
		
			parameterList = [
				str(ghdlExecutablePath),
				'-r', '-P.',
				('--std=%s' % self.__vhdlStandard),
				'--syn-binding',
				'--work=test',
				testbenchName
			]

			# append RUNOPTS to save simulation results to *.vcd file
			if (self.__guiMode):
				parameterList += [('--vcd=%s' % str(vcdFilePath))]
				
			command = " ".join(parameterList)
		
			self.printDebug("call ghdl: %s" % str(parameterList))
			self.printVerbose("    command: %s" % command)
			
			try:
				simulatorLog = subprocess.check_output(parameterList, stderr=subprocess.STDOUT, shell=False, universal_newlines=True)
			except subprocess.CalledProcessError as ex:
				print("ERROR while executing ghdl command: %s" % command)
				print("Return Code: %i" % ex.returncode)
				print("--------------------------------------------------------------------------------")
				print(ex.output)
#		
			if self.showLogs:
				if (simulatorLog != ""):
					print("ghdl messages for : %s" % str(vhdlFilePath))
					print("--------------------------------------------------------------------------------")
					print(simulatorLog)

		# run GHDL simulation on Linux
		elif (self.host.platform == "Linux"):
			# preparing some variables for Linux
			exeFilePath =		tempGHDLPath / testbenchName
		
			# run elaboration
			self.printNonQuiet("  running elaboration...")
		
			parameterList = [
				str(ghdlExecutablePath),
				'-e', '-P.',
				('--std=%s' % self.__vhdlStandard),
				'--syn-binding',
				'--work=test',
				testbenchName
			]

			command = " ".join(parameterList)
		
			self.printDebug("call ghdl: %s" % str(parameterList))
			self.printVerbose("    command: %s" % command)
			try:
				elaborateLog = subprocess.check_output(parameterList, stderr=subprocess.STDOUT, shell=False, universal_newlines=True)
			except subprocess.CalledProcessError as ex:
				print("ERROR while executing ghdl command: %s" % command)
				print("Return Code: %i" % ex.returncode)
				print("--------------------------------------------------------------------------------")
				print(ex.output)
#		
			if self.showLogs:
				if (elaborateLog != ""):
					print("ghdl elaborate messages:")
					print("--------------------------------------------------------------------------------")
					print(elaborateLog)

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
			# append RUNOPTS to save simulation results to *.vcd file
			if (self.__guiMode):
				parameterList += [('--vcd=%s' % str(vcdFilePath))]
				
			command = " ".join(parameterList)
		
			self.printDebug("call ghdl: %s" % str(parameterList))
			self.printVerbose("    command: %s" % command)
			try:
				simulatorLog = subprocess.check_output(parameterList, stderr=subprocess.STDOUT, shell=False, universal_newlines=True)
			except subprocess.CalledProcessError as ex:
				print("ERROR while executing ghdl command: %s" % command)
				print("Return Code: %i" % ex.returncode)
				print("--------------------------------------------------------------------------------")
				print(ex.output)
#		
			if self.showLogs:
				if (simulatorLog != ""):
					print("ghdl messages for : %s" % str(vhdlFilePath))
					print("--------------------------------------------------------------------------------")
					print(simulatorLog)

		print()
		
		if (not self.__guiMode):
			try:
				result = self.checkSimulatorOutput(simulatorLog)
				
				if (result == True):
					print("Testbench '%s': PASSED" % testbenchName)
				else:
					print("Testbench '%s': FAILED" % testbenchName)
					
			except SimulatorException as ex:
				raise TestbenchException("PoC.ns.module", testbenchName, "'SIMULATION RESULT = [PASSED|FAILED]' not found in simulator output.") from ex
		
		else:	# guiMode
			# run GTKWave GUI
			self.printNonQuiet("  launching GTKWave...")

			gtkwExecutablePath =	self.host.directories["GTKWBinary"] / self.__executables['gtkwave']
			gtkwSaveFilePath =		self.host.directories["PoCRoot"] / self.host.tbConfig[str(pocEntity)]['gtkwSaveFile']
		
			parameterList = [
				str(gtkwExecutablePath),
				('--dump=%s' % vcdFilePath)
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
			except subprocess.CalledProcessError as ex:
				print("ERROR while executing GTKWave command: %s" % command)
				print("Return Code: %i" % ex.returncode)
				print("--------------------------------------------------------------------------------")
				print(ex.output)
#		
			if self.showLogs:
				if (gtkwLog != ""):
					print("GTKWave messages:")
					print("--------------------------------------------------------------------------------")
					print(gtkwLog)
			
			
			
			
			
			
			
			
			
			
			
			
			
