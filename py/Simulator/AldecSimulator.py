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
#
# entry point
if __name__ != "__main__":
	# place library initialization code here
	pass
else:
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module Simulator.aSimSimulator")

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

		if (host.platform == "Windows"):
			self.__executables['alib'] =		"vlib.exe"
			self.__executables['acom'] =		"vcom.exe"
			self.__executables['asim'] =		"vsim.exe"
		elif (host.platform == "Linux"):
			self.__executables['alib'] =		"vlib"
			self.__executables['acom'] =		"vcom"
			self.__executables['asim'] =		"vsim"
		else:
			raise PlatformNotSupportedException(self.platform)
		
	def run(self, pocEntity):
		import os
		import re
		import subprocess
	
		self.printNonQuiet(str(pocEntity))
		self.printNonQuiet("  preparing simulation environment...")

		# create temporary directory for aSim if not existent
		tempaSimPath = self.host.directories["aSimTemp"]
		if not (tempaSimPath).exists():
			self.printVerbose("Creating temporary directory for simulator files.")
			self.printDebug("Temporary directors: %s" % str(tempaSimPath))
			tempaSimPath.mkdir(parents=True)

		# setup all needed paths to execute fuse
		aLibExecutablePath =	self.host.directories["aSimBinary"] / self.__executables['alib']
		aComExecutablePath =	self.host.directories["aSimBinary"] / self.__executables['acom']
		aSimExecutablePath =	self.host.directories["aSimBinary"] / self.__executables['asim']
#		gtkwExecutablePath =	self.host.directories["GTKWBinary"] / self.__executables['gtkwave']
		
		if not self.host.tbConfig.has_section(str(pocEntity)):
			from configparser import NoSectionError
			raise SimulatorException("Testbench '" + str(pocEntity) + "' not found.") from NoSectionError(str(pocEntity))
		
		testbenchName =				self.host.tbConfig[str(pocEntity)]['TestbenchModule']
		fileListFilePath =		self.host.directories["PoCRoot"] / self.host.tbConfig[str(pocEntity)]['fileListFile']
		tclBatchFilePath =		self.host.directories["PoCRoot"] / self.host.tbConfig[str(pocEntity)]['aSimBatchScript']
		tclGUIFilePath =			self.host.directories["PoCRoot"] / self.host.tbConfig[str(pocEntity)]['aSimGUIScript']
		tclWaveFilePath =			self.host.directories["PoCRoot"] / self.host.tbConfig[str(pocEntity)]['aSimWaveScript']
		
#		vcdFilePath =					tempvSimPath / (testbenchName + ".vcd")
#		gtkwSaveFilePath =		self.host.directories["PoCRoot"] / self.host.tbConfig[str(pocEntity)]['gtkwaveSaveFile']
		
		if (self.verbose):
			print("  Commands to be run:")
			print("  1. Change working directory to temporary directory")
			print("  2. Parse filelist file.")
			print("    a) For every file: Add the VHDL file to aSim's compile cache.")
			if (self.host.platform == "Windows"):
				print("  3. Compile and run simulation")
			elif (self.host.platform == "Linux"):
				print("  3. Compile simulation")
				print("  4. Run simulation")
			print("  ----------------------------------------")
		
		# change working directory to temporary iSim path
		self.printVerbose('  cd "%s"' % str(tempaSimPath))
		os.chdir(str(tempaSimPath))

		# parse project filelist
		filesLineRegExpStr =	r"\s*(?P<Keyword>(vhdl(\-(87|93|02|08))?|altera|xilinx))"				# Keywords: vhdl[-nn], altera, xilinx
		filesLineRegExpStr +=	r"\s+(?P<VHDLLibrary>[_a-zA-Z0-9]+)"		#	VHDL library name
		filesLineRegExpStr +=	r"\s+\"(?P<VHDLFile>.*?)\""						# VHDL filename without "-signs
		filesLineRegExp = re.compile(filesLineRegExpStr)

		self.printDebug("Reading filelist '%s'" % str(fileListFilePath))
		self.printNonQuiet("  running analysis for every vhdl file...")
		
		# add empty line if logs are enabled
		if self.showLogs:		print()
		
		vhdlLibraries = []
		
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
						else:
							continue
					elif (filesLineRegExpMatch.group('Keyword') == "altera"):
						self.printVerbose("    skipped Altera specific file: '%s'" % filesLineRegExpMatch.group('VHDLFile'))
					elif (filesLineRegExpMatch.group('Keyword') == "xilinx"):
#						self.printVerbose("    skipped Xilinx specific file: '%s'" % filesLineRegExpMatch.group('VHDLFile'))
						# check if ISE or Vivado is configured
						if not self.host.directories.__contains__("XilinxPrimitiveSource"):
							raise NotConfiguredException("This testbench requires some Xilinx Primitves. Please configure Xilinx ISE or Vivado.")
						
						vhdlFileName = filesLineRegExpMatch.group('VHDLFile')
						vhdlFilePath = self.host.directories["XilinxPrimitiveSource"] / vhdlFileName
					else:
						raise SimulatorException("Unknown keyword in *files file.")
						
					vhdlLibraryName = filesLineRegExpMatch.group('VHDLLibrary')
					
					if (not vhdlLibraries.__contains__(vhdlLibraryName)):
						# assemble alib command as list of parameters
						parameterList = [str(aLibExecutablePath), vhdlLibraryName]
						command = " ".join(parameterList)
						
						self.printDebug("call alib: %s" % str(parameterList))
						self.printVerbose("    command: %s" % command)
						
						try:
							aLibLog = subprocess.check_output(parameterList, stderr=subprocess.STDOUT, shell=False, universal_newlines=True)
							vhdlLibraries.append(vhdlLibraryName)

						except subprocess.CalledProcessError as ex:
								print("ERROR while executing alib: %s" % str(vhdlFilePath))
								print("Return Code: %i" % ex.returncode)
								print("--------------------------------------------------------------------------------")
								print(ex.output)
	
						if self.showLogs:
							if (aLibLog != ""):
								print("alib messages for : %s" % str(vhdlFilePath))
								print("--------------------------------------------------------------------------------")
								print(aLibLog)

					# 
					if (not vhdlFilePath.exists()):
						raise SimulatorException("Can not compile '" + vhdlFileName + "'.") from FileNotFoundError(str(vhdlFilePath))
					
					if (self.__vhdlStandard == "87"):
						vhdlStandard = "-87"
					elif (self.__vhdlStandard == "93"):
						vhdlStandard = "-93"
					elif (self.__vhdlStandard == "02"):
						vhdlStandard = "-2002"
					elif (self.__vhdlStandard == "08"):
						vhdlStandard = "-2008"
					
					# assemble acom command as list of parameters
					parameterList = [
						str(aComExecutablePath),
						'-O3',
						'-relax',
						'-l', 'acom.log',
						vhdlStandard,
						'-work', vhdlLibraryName,
						str(vhdlFilePath)
					]
					command = " ".join(parameterList)
					
					self.printDebug("call acom: %s" % str(parameterList))
					self.printVerbose("    command: %s" % command)
					
					try:
						aComLog = subprocess.check_output(parameterList, stderr=subprocess.STDOUT, shell=False, universal_newlines=True)
					except subprocess.CalledProcessError as ex:
							print("ERROR while executing acom: %s" % str(vhdlFilePath))
							print("Return Code: %i" % ex.returncode)
							print("--------------------------------------------------------------------------------")
							print(ex.output)

					if self.showLogs:
						if (aComLog != ""):
							print("acom messages for : %s" % str(vhdlFilePath))
							print("--------------------------------------------------------------------------------")
							print(aComLog)

		
		# running simulation
		# ==========================================================================
		simulatorLog = ""
		
		# run aSim simulation on Windows
		self.printNonQuiet("  running simulation...")
	
		parameterList = [
			str(aSimExecutablePath)#,
			# '-vopt',
			# '-t', '1fs',
		]

		# append RUNOPTS to save simulation results to *.vcd file
		if (self.__guiMode):
			parameterList += ['-title', testbenchName]
			
			if (tclWaveFilePath.exists()):
				self.printDebug("Found waveform script: '%s'" % str(tclWaveFilePath))
				parameterList += ['-do', ('do {%s}; do {%s}' % (str(tclWaveFilePath), str(tclGUIFilePath)))]
			else:
				self.printDebug("Didn't find waveform script: '%s'. Loading default commands." % str(tclWaveFilePath))
				parameterList += ['-do', ('add wave *; do {%s}' % str(tclGUIFilePath))]
		else:
			parameterList += [
				'-c',
				'-do', str(tclBatchFilePath)
			]
		
		# append testbench name
		parameterList += [
			'-work test', testbenchName
		]
		
		command = " ".join(parameterList)
	
		self.printDebug("call asim: %s" % str(parameterList))
		self.printVerbose("    command: %s" % command)
		
		try:
			simulatorLog = subprocess.check_output(parameterList, stderr=subprocess.STDOUT, shell=False, universal_newlines=True)
		except subprocess.CalledProcessError as ex:
			print("ERROR while executing asim command: %s" % command)
			print("Return Code: %i" % ex.returncode)
			print("--------------------------------------------------------------------------------")
			print(ex.output)
#		
		if self.showLogs:
			if (simulatorLog != ""):
				print("asim messages for : %s" % str(vhdlFilePath))
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
		
# 		else:	# guiMode
# 			# run GTKWave GUI
# 			self.printNonQuiet("  launching GTKWave...")
# 		
# 			parameterList = [
# 				str(gtkwExecutablePath),
# 				('--dump=%s' % vcdFilePath)
# 			]
# 
# 			# if GTKWave savefile exists, load it's settings
# 			if gtkwSaveFilePath.exists():
# 				parameterList += ['--save', str(gtkwSaveFilePath)]
# 				
# 			command = " ".join(parameterList)
# 		
# 			self.printDebug("call GTKWave: %s" % str(parameterList))
# 			self.printVerbose("    command: %s" % command)
# 			try:
# 				gtkwLog = subprocess.check_output(parameterList, stderr=subprocess.STDOUT, shell=False, universal_newlines=True)
# 			except subprocess.CalledProcessError as ex:
# 				print("ERROR while executing GTKWave command: %s" % command)
# 				print("Return Code: %i" % ex.returncode)
# 				print("--------------------------------------------------------------------------------")
# 				print(ex.output)
# #		
# 			if self.showLogs:
# 				if (gtkwLog != ""):
# 					print("GTKWave messages:")
# 					print("--------------------------------------------------------------------------------")
# 					print(gtkwLog)
