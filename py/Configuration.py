# EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
# Authors:         		 Patrick Lehmann
# 
# Python Main Module:  Entry point to configure the local copy of this PoC repository.
# 
# Description:
# ------------------------------------
#		This is a python main module (executable) which:
#		- configures the PoC Library to your local environment,
#		- return the paths to tool chain files (e.g. ISE settings file)
#		- ...
#
# License:
# ==============================================================================
# Copyright 2007-2015 Technische Universitaet Dresden - Germany
#                     Chair for VLSI-Design, Diagnostics and Architecture
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================

from pathlib import Path

import PoC


class PoCConfiguration(PoC.PoCBase):
	
	__privateSections = ["PoC", "Xilinx", "Xilinx-ISE", "Xilinx-LabTools", "Xilinx-Vivado", "Xilinx-HardwareServer", "Altera-QuartusII", "Altera-ModelSim", "Questa-ModelSim", "GHDL", "GTKWave", "Solutions"]
	
	def __init__(self, debug, verbose, quiet):
		try:
			super(self.__class__, self).__init__(debug, verbose, quiet)

			if not ((self.platform == "Windows") or (self.platform == "Linux")):
				raise PoC.PoCPlatformNotSupportedException(self.platform)
				
		except PoC.PoCNotConfiguredException as ex:
			from configparser import ConfigParser, ExtendedInterpolation
			from collections import OrderedDict
			
			self.printVerbose("Configuration file does not exists; creating a new one")
			
			self.pocConfig = ConfigParser(interpolation=ExtendedInterpolation())
			self.pocConfig.optionxform = str
			self.pocConfig['PoC'] = OrderedDict()
			self.pocConfig['PoC']['Version'] = '0.0.0'
			self.pocConfig['PoC']['InstallationDirectory'] = self.directories['PoCRoot'].as_posix()

			self.pocConfig['Xilinx'] =								OrderedDict()
			self.pocConfig['Xilinx-ISE'] =						OrderedDict()
			self.pocConfig['Xilinx-LabTools'] =				OrderedDict()
			self.pocConfig['Xilinx-Vivado'] =					OrderedDict()
			self.pocConfig['Xilinx-HardwareServer'] =	OrderedDict()
			self.pocConfig['Altera-QuartusII'] =			OrderedDict()
			self.pocConfig['Altera-ModelSim'] =				OrderedDict()
			self.pocConfig['Questa-ModelSim'] =				OrderedDict()
			self.pocConfig['GHDL'] =									OrderedDict()
			self.pocConfig['GTKWave'] =								OrderedDict()
			self.pocConfig['Solutions'] =							OrderedDict()

			# Writing configuration to disc
			with self.files['PoCPrivateConfig'].open('w') as configFileHandle:
				self.pocConfig.write(configFileHandle)
			
			self.printDebug("New configuration file created: %s" % self.files['PoCPrivateConfig'])
			
			# re-read configuration
			self.readPoCConfiguration()
	
	def autoConfiguration(self):
		raise PoC.NotImplementedException("No automatic configuration available!")
	
	def manualConfiguration(self):
		self.printConfigurationHelp()
		
		# configure Windows
		if (self.platform == 'Windows'):
			# configure ISE on Windows
			next = False
			while (next == False):
				try:
					self.manualConfigureWindowsISE()
					next = True
				except PoC.PoCException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
			
			# configure LabTools on Windows
			next = False
			while (next == False):
				try:
					self.manualConfigureWindowsLabTools()
					next = True
				except PoC.PoCException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
			
			# configure Vivado on Windows
			next = False
			while (next == False):
				try:
					self.manualConfigureWindowsVivado()
					next = True
				except PoC.PoCException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
			
			# configure HardwareServer on Windows
			next = False
			while (next == False):
				try:
					self.manualConfigureWindowsHardwareServer()
					next = True
				except PoC.PoCException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
			
			# configure GHDL on Windows
			next = False
			while (next == False):
				try:
					self.manualConfigureWindowsGHDL()
					next = True
				except PoC.PoCException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
		
		# configure Linux
		elif (self.platform == 'Linux'):
			# configure ISE on Linux
			next = False
			while (next == False):
				try:
					self.manualConfigureLinuxISE()
					next = True
				except PoC.PoCException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
			
			# configure LabTools on Linux
			next = False
			while (next == False):
				try:
					self.manualConfigureLinuxLabTools()
					next = True
				except PoC.PoCException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
			
			# configure Vivado on Linux
			next = False
			while (next == False):
				try:
					self.manualConfigureLinuxVivado()
					next = True
				except PoC.PoCException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
			
			# configure HardwareServer on Linux
			next = False
			while (next == False):
				try:
					self.manualConfigureLinuxHardwareServer()
					next = True
				except PoC.PoCException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
					
			# configure GHDL on Linux
			next = False
			while (next == False):
				try:
					self.manualConfigureLinuxGHDL()
					next = True
				except PoC.PoCException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
		else:
			raise PoC.PoCPlatformNotSupportedException(self.platform)
	
		# remove non private sections from pocConfig
		sections = self.pocConfig.sections()
		for privateSection in self.__privateSections:
			sections.remove(privateSection)
			
		for section in sections:
			self.pocConfig.remove_section(section)
	
		# Writing configuration to disc
		print("Writing configuration file to '%s'" % str(self.files['PoCPrivateConfig']))
		with self.files['PoCPrivateConfig'].open('w') as configFileHandle:
			self.pocConfig.write(configFileHandle)
	
		# re-read configuration
		self.readPoCConfiguration()
	
	def printConfigurationHelp(self):
		self.printVerbose("starting manual configuration...")
		print('Explanation of abbreviations:')
		print('  y - yes')
		print('  n - no')
		print('  p - pass (jump to next question)')
		print('Upper case means default value')
		print()
	
	def manualConfigureWindowsISE(self):
		# Ask for installed Xilinx ISE
		isXilinxISE = input('Is Xilinx ISE installed on your system? [Y/n/p]: ')
		isXilinxISE = isXilinxISE if isXilinxISE != "" else "Y"
		if (isXilinxISE != 'p'):
			if (isXilinxISE == 'Y'):
				xilinxDirectory =	input('Xilinx Installation Directory [C:\Xilinx]: ')
				iseVersion =			input('Xilinx ISE Version Number [14.7]: ')
				print()
				
				xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "C:\Xilinx"
				iseVersion = iseVersion if iseVersion != "" else "14.7"
				
				xilinxDirectoryPath = Path(xilinxDirectory)
				iseDirectoryPath = xilinxDirectoryPath / iseVersion / "ISE_DS/ISE"
				
				if not xilinxDirectoryPath.exists():	raise PoC.PoCException("Xilinx Installation Directory '%s' does not exist." % xilinxDirectory)
				if not iseDirectoryPath.exists():			raise PoC.PoCException("Xilinx ISE version '%s' is not installed." % iseVersion)
				
				self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
				self.pocConfig['Xilinx-ISE']['Version'] = iseVersion
				self.pocConfig['Xilinx-ISE']['InstallationDirectory'] = '${Xilinx:InstallationDirectory}/${Version}/ISE_DS'
				self.pocConfig['Xilinx-ISE']['BinaryDirectory'] = '${InstallationDirectory}/ISE/bin/nt64'
			elif (isXilinxISE == 'n'):
				self.pocConfig['Xilinx-ISE'] = {}
			else:
				raise PoC.PoCException("unknown option")
	
	def manualConfigureWindowsLabTools(self):
		# Ask for installed Xilinx LabTools
		isXilinxLabTools = input('Is Xilinx LabTools installed on your system? [Y/n/p]: ')
		isXilinxLabTools = isXilinxLabTools if isXilinxLabTools != "" else "Y"
		if (isXilinxLabTools != 'p'):
			if (isXilinxLabTools == 'Y'):
				xilinxDirectory =	input('Xilinx Installation Directory [C:\Xilinx]: ')
				labToolsVersion =	input('Xilinx LabTools Version Number [14.7]: ')
				print()
				
				xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "C:\Xilinx"
				labToolsVersion = labToolsVersion if labToolsVersion != "" else "14.7"
				
				xilinxDirectoryPath = Path(xilinxDirectory)
				labToolsDirectoryPath = xilinxDirectoryPath / labToolsVersion / "LabTools/LabTools"
				
				if not xilinxDirectoryPath.exists():		raise PoC.PoCException("Xilinx Installation Directory '%s' does not exist." % xilinxDirectory)
				if not labToolsDirectoryPath.exists():	raise PoC.PoCException("Xilinx LabTools version '%s' is not installed." % labToolsVersion)
				
				self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
				self.pocConfig['Xilinx-LabTools']['Version'] = labToolsVersion
				self.pocConfig['Xilinx-LabTools']['InstallationDirectory'] = '${Xilinx:InstallationDirectory}/${Version}/LabTools'
				self.pocConfig['Xilinx-LabTools']['BinaryDirectory'] = '${InstallationDirectory}/LabTools/bin/nt64'
			elif (isXilinxLabTools == 'n'):
				self.pocConfig['Xilinx-LabTools'] = {}
			else:
				raise PoC.PoCException("unknown option")
	
	def manualConfigureWindowsVivado(self):
		# Ask for installed Xilinx Vivado
		isXilinxVivado = input('Is Xilinx Vivado installed on your system? [Y/n/p]: ')
		isXilinxVivado = isXilinxVivado if isXilinxVivado != "" else "Y"
		if (isXilinxVivado != 'p'):
			if (isXilinxVivado == 'Y'):
				xilinxDirectory =	input('Xilinx Installation Directory [C:\Xilinx]: ')
				vivadoVersion =		input('Xilinx Vivado Version Number [2014.1]: ')
				print()
			
				xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "C:\Xilinx"
				vivadoVersion = vivadoVersion if vivadoVersion != "" else "2014.1"
			
				xilinxDirectoryPath = Path(xilinxDirectory)
				vivadoDirectoryPath = xilinxDirectoryPath / "Vivado" / vivadoVersion
			
				if not xilinxDirectoryPath.exists():	raise PoC.PoCException("Xilinx Installation Directory '%s' does not exist." % xilinxDirectory)
				if not vivadoDirectoryPath.exists():	raise PoC.PoCException("Xilinx Vivado version '%s' is not installed." % vivadoVersion)
			
				self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
				self.pocConfig['Xilinx-Vivado']['Version'] = vivadoVersion
				self.pocConfig['Xilinx-Vivado']['InstallationDirectory'] = '${Xilinx:InstallationDirectory}/Vivado/${Version}'
				self.pocConfig['Xilinx-Vivado']['BinaryDirectory'] = '${InstallationDirectory}/bin'
			elif (isXilinxVivado == 'n'):
				self.pocConfig['Xilinx-Vivado'] = {}
			else:
				raise PoC.PoCException("unknown option")
	
	def manualConfigureWindowsHardwareServer(self):
		# Ask for installed Xilinx HardwareServer
		isXilinxHardwareServer = input('Is Xilinx HardwareServer installed on your system? [Y/n/p]: ')
		isXilinxHardwareServer = isXilinxHardwareServer if isXilinxHardwareServer != "" else "Y"
		if (isXilinxHardwareServer != 'p'):
			if (isXilinxHardwareServer == 'Y'):
				xilinxDirectory =	input('Xilinx Installation Directory [C:\Xilinx]: ')
				hardwareServerVersion =		input('Xilinx HardwareServer Version Number [2014.1]: ')
				print()
			
				xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "C:\Xilinx"
				hardwareServerVersion = hardwareServerVersion if hardwareServerVersion != "" else "2014.1"
			
				xilinxDirectoryPath = Path(xilinxDirectory)
				hardwareServerDirectoryPath = xilinxDirectoryPath / "HardwareServer" / hardwareServerVersion
			
				if not xilinxDirectoryPath.exists():					raise PoC.PoCException("Xilinx Installation Directory '%s' does not exist." % xilinxDirectory)
				if not hardwareServerDirectoryPath.exists():	raise PoC.PoCException("Xilinx HardwareServer version '%s' is not installed." % hardwareServerVersion)
			
				self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
				self.pocConfig['Xilinx-HardwareServer']['Version'] = hardwareServerVersion
				self.pocConfig['Xilinx-HardwareServer']['InstallationDirectory'] = '${Xilinx:InstallationDirectory}/HardwareServer/${Version}'
				self.pocConfig['Xilinx-HardwareServer']['BinaryDirectory'] = '${InstallationDirectory}/bin'
			elif (isXilinxHardwareServer == 'n'):
				self.pocConfig['Xilinx-HardwareServer'] = {}
			else:
				raise PoC.PoCException("unknown option")
		
	def manualConfigureWindowsGHDL(self):
		# Ask for installed GHDL
		isGHDL = input('Is GHDL installed on your system? [Y/n/p]: ')
		isGHDL = isGHDL if isGHDL != "" else "Y"
		if (isGHDL != 'p'):
			if (isGHDL == 'Y'):
				ghdlDirectory =	input('GHDL Installation Directory [C:\Program Files (x86)\GHDL]: ')
				ghdlVersion =		input('GHDL Version Number [0.31]: ')
				print()
			
				ghdlDirectory = ghdlDirectory if ghdlDirectory != "" else "C:\Program Files (x86)\GHDL"
				ghdlVersion = ghdlVersion if ghdlVersion != "" else "0.31"
			
				ghdlDirectoryPath = Path(ghdlDirectory)
				ghdlExecutablePath = ghdlDirectoryPath / "bin" / "ghdl.exe"
			
				if not ghdlDirectoryPath.exists():	raise PoC.PoCException("GHDL Installation Directory '%s' does not exist." % ghdlDirectory)
				if not ghdlExecutablePath.exists():	raise PoC.PoCException("GHDL is not installed.")
			
				self.pocConfig['GHDL']['Version'] = ghdlVersion
				self.pocConfig['GHDL']['InstallationDirectory'] = ghdlDirectoryPath.as_posix()
				self.pocConfig['GHDL']['BinaryDirectory'] = '${InstallationDirectory}/bin'
			elif (isGHDL == 'n'):
				self.pocConfig['GHDL'] = {}
			else:
				raise PoC.PoCException("unknown option")
		
	def manualConfigureLinuxISE(self):
		# Ask for installed Xilinx ISE
		isXilinxISE = input('Is Xilinx ISE installed on your system? [Y/n/p]: ')
		isXilinxISE = isXilinxISE if isXilinxISE != "" else "Y"
		if (isXilinxISE != 'p'):
			if (isXilinxISE == 'Y'):
				xilinxDirectory =	input('Xilinx Installation Directory [/opt/Xilinx]: ')
				iseVersion =			input('Xilinx ISE Version Number [14.7]: ')
				print()
			
				xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "/opt/Xilinx"
				iseVersion = iseVersion if iseVersion != "" else "14.7"
			
				xilinxDirectoryPath = Path(xilinxDirectory)
				iseDirectoryPath = xilinxDirectoryPath / iseVersion / "ISE_DS/ISE"
			
				if not xilinxDirectoryPath.exists():	raise PoC.PoCException("Xilinx Installation Directory '%s' does not exist." % xilinxDirectory)
				if not iseDirectoryPath.exists():			raise PoC.PoCException("Xilinx ISE version '%s' is not installed." % iseVersion)
			
				self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
				self.pocConfig['Xilinx-ISE']['Version'] = iseVersion
				self.pocConfig['Xilinx-ISE']['InstallationDirectory'] = '${Xilinx:InstallationDirectory}/${Version}/ISE_DS'
				self.pocConfig['Xilinx-ISE']['BinaryDirectory'] = '${InstallationDirectory}/ISE/bin/lin64'
			elif (isXilinxISE == 'n'):
				self.pocConfig['Xilinx-ISE'] = {}
			else:
				raise PoC.PoCException("unknown option")
	
	def manualConfigureLinuxLabTools(self):
		# Ask for installed Xilinx LabTools
		isXilinxLabTools = input('Is Xilinx LabTools installed on your system? [Y/n/p]: ')
		isXilinxLabTools = isXilinxLabTools if isXilinxLabTools != "" else "Y"
		if (isXilinxLabTools != 'p'):
			if (isXilinxLabTools == 'Y'):
				xilinxDirectory =	input('Xilinx Installation Directory [/opt/Xilinx]: ')
				labToolsVersion =	input('Xilinx LabTools Version Number [14.7]: ')
				print()
			
				xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "/opt/Xilinx"
				labToolsVersion = labToolsVersion if labToolsVersion != "" else "14.7"
			
				xilinxDirectoryPath = Path(xilinxDirectory)
				labToolsDirectoryPath = xilinxDirectoryPath / labToolsVersion / "LabTools/LabTools"
			
				if not xilinxDirectoryPath.exists():		raise PoC.PoCException("Xilinx Installation Directory '%s' does not exist." % xilinxDirectory)
				if not labToolsDirectoryPath.exists():	raise PoC.PoCException("Xilinx LabTools version '%s' is not installed." % labToolsVersion)
			
				self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
				self.pocConfig['Xilinx-LabTools']['Version'] = labToolsVersion
				self.pocConfig['Xilinx-LabTools']['InstallationDirectory'] = '${Xilinx:InstallationDirectory}/${Version}/LabTools'
				self.pocConfig['Xilinx-LabTools']['BinaryDirectory'] = '${InstallationDirectory}/LabTools/bin/lin64'
			elif (isXilinxLabTools == 'n'):
				self.pocConfig['Xilinx-LabTools'] = {}
			else:
				raise PoC.PoCException("unknown option")
		
	def manualConfigureLinuxVivado(self):
		# Ask for installed Xilinx Vivado
		isXilinxVivado = input('Is Xilinx Vivado installed on your system? [Y/n/p]: ')
		isXilinxVivado = isXilinxVivado if isXilinxVivado != "" else "Y"
		if (isXilinxVivado != 'p'):
			if (isXilinxVivado == 'Y'):
				xilinxDirectory =	input('Xilinx Installation Directory [/opt/Xilinx]: ')
				vivadoVersion =		input('Xilinx Vivado Version Number [2014.1]: ')
				print()
			
				xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "/opt/Xilinx"
				vivadoVersion = vivadoVersion if vivadoVersion != "" else "2014.1"
			
				xilinxDirectoryPath = Path(xilinxDirectory)
				vivadoDirectoryPath = xilinxDirectoryPath / "Vivado" / vivadoVersion
			
				if not xilinxDirectoryPath.exists():	raise PoC.PoCException("Xilinx Installation Directory '%s' does not exist." % xilinxDirectory)
				if not vivadoDirectoryPath.exists():	raise PoC.PoCException("Xilinx Vivado version '%s' is not installed." % vivadoVersion)
			
				self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
				self.pocConfig['Xilinx-Vivado']['Version'] = vivadoVersion
				self.pocConfig['Xilinx-Vivado']['InstallationDirectory'] = '${Xilinx:InstallationDirectory}/Vivado/${Version}'
				self.pocConfig['Xilinx-Vivado']['BinaryDirectory'] = '${InstallationDirectory}/bin'
			elif (isXilinxVivado == 'n'):
				self.pocConfig['Xilinx-Vivado'] = {}
			else:
				raise PoC.PoCException("unknown option")
	
	def manualConfigureLinuxHardwareServer(self):
		# Ask for installed Xilinx HardwareServer
		isXilinxHardwareServer = input('Is Xilinx HardwareServer installed on your system? [Y/n/p]: ')
		isXilinxHardwareServer = isXilinxHardwareServer if isXilinxHardwareServer != "" else "Y"
		if (isXilinxHardwareServer != 'p'):
			if (isXilinxHardwareServer == 'Y'):
				xilinxDirectory =	input('Xilinx Installation Directory [/opt/Xilinx]: ')
				hardwareServerVersion =		input('Xilinx HardwareServer Version Number [2014.1]: ')
				print()
			
				xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "/opt/Xilinx"
				hardwareServerVersion = hardwareServerVersion if hardwareServerVersion != "" else "2014.1"
			
				xilinxDirectoryPath = Path(xilinxDirectory)
				hardwareServerDirectoryPath = xilinxDirectoryPath / "HardwareServer" / hardwareServerVersion
			
				if not xilinxDirectoryPath.exists():					raise PoC.PoCException("Xilinx Installation Directory '%s' does not exist." % xilinxDirectory)
				if not hardwareServerDirectoryPath.exists():	raise PoC.PoCException("Xilinx HardwareServer version '%s' is not installed." % hardwareServerVersion)
			
				self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
				self.pocConfig['Xilinx-HardwareServer']['Version'] = hardwareServerVersion
				self.pocConfig['Xilinx-HardwareServer']['InstallationDirectory'] = '${Xilinx:InstallationDirectory}/HardwareServer/${Version}'
				self.pocConfig['Xilinx-HardwareServer']['BinaryDirectory'] = '${InstallationDirectory}/bin'
			elif (isXilinxHardwareServer == 'n'):
				self.pocConfig['Xilinx-HardwareServer'] = {}
			else:
				raise PoC.PoCException("unknown option")
	
	def manualConfigureLinuxGHDL(self):
		# Ask for installed GHDL
		isGHDL = input('Is GHDL installed on your system? [Y/n/p]: ')
		isGHDL = isGHDL if isGHDL != "" else "Y"
		if (isGHDL != 'p'):
			if (isGHDL == 'Y'):
				ghdlDirectory =	input('GHDL Installation Directory [/usr/bin]: ')
				ghdlVersion =		input('GHDL Version Number [0.31]: ')
				print()
			
				ghdlDirectory = ghdlDirectory if ghdlDirectory != "" else "/usr/bin"
				ghdlVersion = ghdlVersion if ghdlVersion != "" else "0.31"
			
				ghdlDirectoryPath = Path(ghdlDirectory)
				ghdlExecutablePath = ghdlDirectoryPath / "ghdl"
			
				if not ghdlDirectoryPath.exists():	raise PoC.PoCException("GHDL Installation Directory '%s' does not exist." % ghdlDirectory)
				if not ghdlExecutablePath.exists():	raise PoC.PoCException("GHDL is not installed.")
			
				self.pocConfig['GHDL']['Version'] = ghdlVersion
				self.pocConfig['GHDL']['InstallationDirectory'] = ghdlDirectoryPath.as_posix()
				self.pocConfig['GHDL']['BinaryDirectory'] = '${InstallationDirectory}'
			elif (isGHDL == 'n'):
				self.pocConfig['GHDL'] = {}
			else:
				raise PoC.PoCException("unknown option")
				
	def newSolution(self, solutionName):
		print("new solution: name=%s" % solutionName)
		print("solution here: %s" % self.directories['Working'])
		print("script root: %s" % self.directories['ScriptRoot'])
	
		raise NotImplementedException("Currently new solution should be created by hand.")
	
	def addSolution(self, solutionName):
		print("Adding existing solution '%s' to PoC Library." % solutionName)
		print()
		print("You can specify paths and file names relative to the current working directory")
		print("or as an absolute path.")
		print()
		print("Current working directory: %s" % self.directories['Working'])
		print()
		
		if (not self.pocConfig.has_section('Solutions')):
			self.pocConfig['Solutions'] = OrderedDict()
		
		if self.pocConfig.has_option('Solutions', solutionName):
			raise PoC.PoCException("Solution is already registered in PoC Library.")
		
		# 
		solutionFileDirectoryName = input("Where is the solution file 'solution.ini' stored? [./py]: ")
		solutionFileDirectoryName = solutionFileDirectoryName if solutionFileDirectoryName != "" else "py"
	
		solutionFilePath = Path(solutionFileDirectoryName)
	
		if (solutionFilePath.is_absolute()):
			solutionFilePath = solutionFilePath / "solution.ini"
		else:
			solutionFilePath = ((self.directories['Working'] / solutionFilePath).resolve()) / "solution.ini"
			
		if (not solutionFilePath.exists()):
			raise PoC.PoCException("Solution file '%s' does not exist." % str(solutionFilePath))
		
		self.pocConfig['Solutions'][solutionName] = solutionFilePath.as_posix()
	
		# remove non private sections from pocConfig
		sections = self.pocConfig.sections()
		for privateSection in self.__privateSections:
			sections.remove(privateSection)
			
		for section in sections:
			self.pocConfig.remove_section(section)
	
		# Writing configuration to disc
		print("Writing configuration file to '%s'" % str(self.files['PoCPrivateConfig']))
		with self.files['PoCPrivateConfig'].open('w') as configFileHandle:
			self.pocConfig.write(configFileHandle)
	
		# re-read configuration
		self.readPoCConfiguration()
	
	def getISESettingsFile(self):
		if (len(self.pocConfig.options("Xilinx-ISE")) != 0):
			iseInstallationDirectoryPath = Path(self.pocConfig['Xilinx-ISE']['InstallationDirectory'])
			
			if		(self.platform == "Windows"):		return (str(iseInstallationDirectoryPath / "settings64.bat"))
			elif	(self.platform == "Linux"):			return (str(iseInstallationDirectoryPath / "settings64.sh"))
			else:	raise PoCPlatformNotSupportedException(self.platform)
		elif (len(self.pocConfig.options("Xilinx-LabTools")) != 0):
			labToolsInstallationDirectoryPath = Path(self.pocConfig['Xilinx-LabTools']['InstallationDirectory'])
			
			if		(self.platform == "Windows"):		return (str(labToolsInstallationDirectoryPath / "settings64.bat"))
			elif	(self.platform == "Linux"):			return (str(labToolsInstallationDirectoryPath / "settings64.sh"))
			else:	raise PoCPlatformNotSupportedException(self.platform)
		else:
			raise PoCNotConfiguredException("ERROR: Xilinx ISE or Xilinx LabTools is not configured on this system.")
			
	def getVivadoSettingsFile(self):
		if (len(self.pocConfig.options("Xilinx-Vivado")) != 0):
			vivadoInstallationDirectoryPath = Path(self.pocConfig['Xilinx-Vivado']['InstallationDirectory'])
			
			if		(self.platform == "Windows"):		return (str(vivadoInstallationDirectoryPath / "settings64.bat"))
			elif	(self.platform == "Linux"):			return (str(vivadoInstallationDirectoryPath / "settings64.sh"))
			else:	raise PoCPlatformNotSupportedException(self.platform)
		elif (len(self.pocConfig.options("Xilinx-HardwareServer")) != 0):
			hardwareServerInstallationDirectoryPath = Path(self.pocConfig['Xilinx-HardwareServer']['InstallationDirectory'])
			
			if		(self.platform == "Windows"):		return (str(hardwareServerInstallationDirectoryPath / "settings64.bat"))
			elif	(self.platform == "Linux"):			return (str(hardwareServerInstallationDirectoryPath / "settings64.sh"))
			else:	raise PoCPlatformNotSupportedException(self.platform)
		else:
			raise PoCNotConfiguredException("ERROR: Xilinx Vivado or Xilinx HardwareServer is not configured on this system.")
	
# main program
def main():
	from sys import exit
	import argparse
	import textwrap
	import colorama
	
	colorama.init()
	
	try:
		# create a commandline argument parser
		argParser = argparse.ArgumentParser(
			formatter_class = argparse.RawDescriptionHelpFormatter,
			description = textwrap.dedent('''\
				This is the PoC Library Repository Service Tool.
				'''),
			add_help=False)

		# add arguments
		group1 = argParser.add_argument_group('Verbosity')
		group1.add_argument('-D', 																														help='enable script wrapper debug mode',		action='store_const', const=True, default=False)
		group1.add_argument('-d',																	dest="debug",								help='enable debug mode',										action='store_const', const=True, default=False)
		group1.add_argument('-v',																	dest="verbose",							help='print out detailed messages',					action='store_const', const=True, default=False)
		group1.add_argument('-q',																	dest="quiet",								help='run in quiet mode',										action='store_const', const=True, default=False)
		group2 = argParser.add_argument_group('Commands')
		group21 = group2.add_mutually_exclusive_group(required=True)
		group21.add_argument('-h', '--help',											dest="help",								help='show this help message and exit',			action='store_const', const=True, default=False)
		group21.add_argument('--configure',												dest="configurePoC",				help='configure PoC Library',								action='store_const', const=True, default=False)
		group21.add_argument('--new-solution',	metavar="<Name>",	dest="newSolution",					help='create a new solution')
		group21.add_argument('--add-solution',	metavar="<Name>",	dest="addSolution",					help='add an existing solution')
		group21.add_argument('--ise-settingsfile',								dest="iseSettingsFile",			help='return Xilinx ISE settings file',			action='store_const', const=True, default=False)
		group21.add_argument('--vivado-settingsfile',							dest="vivadoSettingsFile",	help='return Xilinx Vivado settings file',	action='store_const', const=True, default=False)

		# parse command line options
		args = argParser.parse_args()

	except Exception as ex:
		from traceback	import print_tb
		from colorama		import Fore, Back, Style
		
		print(Fore.RED + "FATAL: %s" % ex.__str__())
		print("-" * 80)
		print_tb(ex.__traceback__)
		print("-" * 80)
		print(Fore.RESET + Back.RESET + Style.RESET_ALL)
		exit(1)

	# create class instance and start processing
	try:
		config = PoCConfiguration(args.debug, args.verbose, args.quiet)
		
		if (args.help == True):
			argParser.print_help()
			return
		elif args.configurePoC:
			print("=" * 80)
			print("{: ^80s}".format("PoC Library - Repository Service Tool"))
			print("=" * 80)
			print()
		
			#config.autoConfiguration()
			config.manualConfiguration()
			exit(0)
		elif args.newSolution:
			print("=" * 80)
			print("{: ^80s}".format("PoC Library - Repository Service Tool"))
			print("=" * 80)
			print()
			
			config.newSolution(args.newSolution)
			exit(0)
			
		elif args.addSolution:
			print("=" * 80)
			print("{: ^80s}".format("PoC Library - Repository Service Tool"))
			print("=" * 80)
			print()
			
			config.addSolution(args.addSolution)
			exit(0)
			
		elif args.iseSettingsFile:
			print(config.getISESettingsFile())
			exit(0)
		elif args.vivadoSettingsFile:
			print(config.getVivadoSettingsFile())
			exit(0)
		else:
			argParser.print_help()
			exit(0)
	
	except PoC.PoCNotConfiguredException as ex:
		from colorama import Fore, Back, Style
		print(Fore.RED + "ERROR: %s" % ex.message)
		print()
		print("Please run 'poc.[sh/cmd] --configure' in PoC root directory.")
		print(Fore.RESET + Back.RESET + Style.RESET_ALL)
		exit(1)
	
	except PoC.PoCPlatformNotSupportedException as ex:
		from colorama import Fore, Back, Style
		print(Fore.RED + "ERROR: Unknown platform '%s'" % ex.message)
		print(Fore.RESET + Back.RESET + Style.RESET_ALL)
		exit(1)
		
	except PoC.PoCException as ex:
		from colorama import Fore, Back, Style
		print(Fore.RED + "ERROR: %s" % ex.message)
		print(Fore.RESET + Back.RESET + Style.RESET_ALL)
		exit(1)

	except PoC.NotImplementedException as ex:
		from colorama import Fore, Back, Style
		print(Fore.RED + "ERROR: %s" % ex.message)
		print(Fore.RESET + Back.RESET + Style.RESET_ALL)
		exit(1)

	except Exception as ex:
		from traceback	import print_tb
		from colorama		import Fore, Back, Style
		print(Fore.RED + "FATAL: %s" % ex.__str__())
		print("-" * 80)
		print_tb(ex.__traceback__)
		print("-" * 80)
		print(Fore.RESET + Back.RESET + Style.RESET_ALL)
		exit(1)


# entry point
if __name__ == "__main__":
	from sys import version_info
	
	if (version_info<(3,4,0)):
		from colorama		import Fore, Back, Style
		print(Fore.RED + "ERROR: Used Python interpreter is to old: %s" % version_info)
		print("Minimal required Python version is 3.4.0")
		print(Fore.RESET + Back.RESET + Style.RESET_ALL)
		exit(1)
		
	main()
else:
	from sys			import exit
	from colorama	import Fore, Back, Style
	print(Fore.RED + "=" * 80)
	print("{: ^80s}".format("PoC Library - Repository Service Tool"))
	print("=" * 80)
	print()
	print("This is no library file!")
	print(Fore.RESET + Back.RESET + Style.RESET_ALL)
	exit(1)
