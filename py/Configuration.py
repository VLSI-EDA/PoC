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
# Copyright 2007-2016 Technische Universitaet Dresden - Germany
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

from lib.Functions import Exit
from Base.Exceptions import *
from Base.PoCBase import CommandLineProgram
from collections import OrderedDict

class Configuration(CommandLineProgram):
	headLine = "The PoC-Library - Repository Service Tool"
	
	__privateSections = [
		"PoC",
		"Aldec", "Aldec.ActiveHDL", "Aldec.RivieraPRO",
		"Altera", "Altera.QuartusII", "Altera.ModelSim",
		"GHDL", "GTKWave",
		"Lattice", "Lattice.Diamond", "Lattice.ActiveHDL", "Lattice.Symplify",
		"Mentor", "Mentor.QuestaSIM",
		"Xilinx", "Xilinx.ISE", "Xilinx.LabTools", "Xilinx.Vivado", "Xilinx.HardwareServer",
		"Solutions"
	]
	__privatePoCOptions = ["Version", "InstallationDirectory"]
	
	def __init__(self, debug, verbose, quiet):
		try:
			super(self.__class__, self).__init__(debug, verbose, quiet)

			if not ((self.platform == "Windows") or (self.platform == "Linux")):	raise PlatformNotSupportedException(self.platform)
				
		except NotConfiguredException as ex:
			from configparser import ConfigParser, ExtendedInterpolation
			
			self.printVerbose("Configuration file does not exists; creating a new one")
			
			self.pocConfig = ConfigParser(interpolation=ExtendedInterpolation())
			self.pocConfig.optionxform = str
			self.pocConfig['PoC'] = OrderedDict()
			self.pocConfig['PoC']['Version'] = '0.0.0'
			self.pocConfig['PoC']['InstallationDirectory'] = self.directories['PoCRoot'].as_posix()

			self.pocConfig['Aldec'] =									OrderedDict()
			self.pocConfig['Aldec.ActiveHDL'] =				OrderedDict()
			self.pocConfig['Aldec.RivieraPRO'] =			OrderedDict()
			self.pocConfig['Altera'] =								OrderedDict()
			self.pocConfig['Altera.QuartusII'] =			OrderedDict()
			self.pocConfig['Altera.ModelSim'] =				OrderedDict()
			self.pocConfig['Lattice'] =								OrderedDict()
			self.pocConfig['Lattice.Diamond'] =				OrderedDict()
			self.pocConfig['Lattice.ActiveHDL'] =			OrderedDict()
			self.pocConfig['Lattice.Symplify'] =			OrderedDict()
			self.pocConfig['GHDL'] =									OrderedDict()
			self.pocConfig['GTKWave'] =								OrderedDict()
			self.pocConfig['Mentor'] =								OrderedDict()
			self.pocConfig['Mentor.QuestaSIM'] =			OrderedDict()
			self.pocConfig['Xilinx'] =								OrderedDict()
			self.pocConfig['Xilinx.ISE'] =						OrderedDict()
			self.pocConfig['Xilinx.LabTools'] =				OrderedDict()
			self.pocConfig['Xilinx.Vivado'] =					OrderedDict()
			self.pocConfig['Xilinx.HardwareServer'] =	OrderedDict()
			self.pocConfig['Solutions'] =							OrderedDict()

			# Writing configuration to disc
			with self.files['PoCPrivateConfig'].open('w') as configFileHandle:
				self.pocConfig.write(configFileHandle)
			
			self.printDebug("New configuration file created: %s" % self.files['PoCPrivateConfig'])
			
			# re-read configuration
			self.readPoCConfiguration()
	
	def autoConfiguration(self):
		raise NotImplementedException("No automatic configuration available!")
	
	def manualConfiguration(self):
		self.printConfigurationHelp()
		
		# configure Windows
		if (self.platform == 'Windows'):
			# configure QuartusII on Windows
			next = False
			while (next == False):
				try:
					self.manualConfigureWindowsQuartusII()
					next = True
				except BaseException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
			
			# configure ISE on Windows
			next = False
			while (next == False):
				try:
					self.manualConfigureWindowsISE()
					next = True
				except BaseException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
			
			# configure LabTools on Windows
			next = False
			while (next == False):
				try:
					self.manualConfigureWindowsLabTools()
					next = True
				except BaseException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
			
			# configure Vivado on Windows
			next = False
			while (next == False):
				try:
					self.manualConfigureWindowsVivado()
					next = True
				except BaseException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
			
			# configure HardwareServer on Windows
			next = False
			while (next == False):
				try:
					self.manualConfigureWindowsHardwareServer()
					next = True
				except BaseException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
				
			# configure Mentor QuestaSIM on Windows
			next = False
			while (next == False):
				try:
					self.manualConfigureWindowsQuestaSim()
					next = True
				except BaseException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
				
			# configure GHDL on Windows
			next = False
			while (next == False):
				try:
					self.manualConfigureWindowsGHDL()
					next = True
				except BaseException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
				
			# configure GTKWave on Windows
			next = False
			while (next == False):
				try:
					self.manualConfigureWindowsGTKW()
					next = True
				except BaseException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
				
		# configure Linux
		elif (self.platform == 'Linux'):
			# configure QuartusII on Linux
			next = False
			while (next == False):
				try:
					self.manualConfigureLinuxQuartusII()
					next = True
				except BaseException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
			
			# configure ISE on Linux
			next = False
			while (next == False):
				try:
					self.manualConfigureLinuxISE()
					next = True
				except BaseException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
			
			# configure LabTools on Linux
			next = False
			while (next == False):
				try:
					self.manualConfigureLinuxLabTools()
					next = True
				except BaseException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
			
			# configure Vivado on Linux
			next = False
			while (next == False):
				try:
					self.manualConfigureLinuxVivado()
					next = True
				except BaseException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
			
			# configure HardwareServer on Linux
			next = False
			while (next == False):
				try:
					self.manualConfigureLinuxHardwareServer()
					next = True
				except BaseException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
			
			# configure Mentor QuestaSIM on Linux
			next = False
			while (next == False):
				try:
					self.manualConfigureLinuxQuestaSim()
					next = True
				except BaseException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
			
			# configure GHDL on Linux
			next = False
			while (next == False):
				try:
					self.manualConfigureLinuxGHDL()
					next = True
				except BaseException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
			
			# configure GTKWave on Linux
			next = False
			while (next == False):
				try:
					self.manualConfigureLinuxGTKW()
					next = True
				except BaseException as ex:
					print("FAULT: %s" % ex.message)
				except Exception as ex:
					raise
		else:
			raise PlatformNotSupportedException(self.platform)
	
		# write configuration
		self.writePoCConfiguration()
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
	
	def manualConfigureWindowsQuartusII(self):
		# Ask for installed Altera Quartus-II
		isAlteraQuartusII = input('Is Altera Quartus-II installed on your system? [Y/n/p]: ')
		isAlteraQuartusII = isAlteraQuartusII if isAlteraQuartusII != "" else "Y"
		if (isAlteraQuartusII  in ['p', 'P']):
			pass
		elif (isAlteraQuartusII in ['n', 'N']):
			self.pocConfig['Altera.QuartusII'] = OrderedDict()
		elif (isAlteraQuartusII in ['y', 'Y']):
			alteraDirectory =		input('Altera installation directory [C:\Altera]: ')
			quartusIIVersion =	input('Altera QuartusII version number [15.0]: ')
			print()
			
			alteraDirectory =		alteraDirectory		if alteraDirectory != ""	else "C:\Altera"
			quartusIIVersion =	quartusIIVersion	if quartusIIVersion != ""	else "15.0"
			
			alteraDirectoryPath = Path(alteraDirectory)
			quartusIIDirectoryPath = alteraDirectoryPath / quartusIIVersion / "quartus"
			
			if not alteraDirectoryPath.exists():		raise BaseException("Altera installation directory '%s' does not exist." % alteraDirectory)
			if not quartusIIDirectoryPath.exists():	raise BaseException("Altera QuartusII version '%s' is not installed." % quartusIIVersion)
			
			self.pocConfig['Altera']['InstallationDirectory'] = alteraDirectoryPath.as_posix()
			self.pocConfig['Altera.QuartusII']['Version'] = quartusIIVersion
			self.pocConfig['Altera.QuartusII']['InstallationDirectory'] = '${Altera:InstallationDirectory}/${Version}'
			self.pocConfig['Altera.QuartusII']['BinaryDirectory'] = '${InstallationDirectory}/quartus/bin64'
			
			# Ask for installed Altera ModelSimAltera
			isAlteraModelSim = input('Is ModelSim - Altera Edition installed on your system? [Y/n/p]: ')
			isAlteraModelSim = isAlteraModelSim if isAlteraModelSim != "" else "Y"
			if (isAlteraModelSim  in ['p', 'P']):
				pass
			elif (isAlteraModelSim in ['n', 'N']):
				self.pocConfig['Altera.ModelSim'] = OrderedDict()
			elif (isAlteraModelSim in ['y', 'Y']):
				alteraModelSimVersion =	input('ModelSim - Altera Edition version number [10.1e]: ')
			
				alteraModelSimDirectoryPath = alteraDirectoryPath / quartusIIVersion / "modelsim_ase"
			
				if not alteraModelSimDirectoryPath.exists():	raise BaseException("ModelSim - Altera Edition installation directory '%s' does not exist." % str(alteraModelSimDirectoryPath))
				
				self.pocConfig['Altera.ModelSim']['Version'] = alteraModelSimVersion
				self.pocConfig['Altera.ModelSim']['InstallationDirectory'] = '${Altera:InstallationDirectory}/${Altera.QuartusII:Version}/modelsim_ase'
				self.pocConfig['Altera.ModelSim']['BinaryDirectory'] = '${InstallationDirectory}/win32aloem'
			else:
				raise BaseException("unknown option")
		else:
			raise BaseException("unknown option")
			
	def manualConfigureWindowsISE(self):
		# Ask for installed Xilinx ISE
		isXilinxISE = input('Is Xilinx ISE installed on your system? [Y/n/p]: ')
		isXilinxISE = isXilinxISE if isXilinxISE != "" else "Y"
		if (isXilinxISE  in ['p', 'P']):
			pass
		elif (isXilinxISE in ['n', 'N']):
			self.pocConfig['Xilinx.ISE'] = OrderedDict()
		elif (isXilinxISE in ['y', 'Y']):
			xilinxDirectory =	input('Xilinx installation directory [C:\Xilinx]: ')
			iseVersion =			input('Xilinx ISE version number [14.7]: ')
			print()
			
			xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "C:\Xilinx"
			iseVersion = iseVersion if iseVersion != "" else "14.7"
			
			xilinxDirectoryPath = Path(xilinxDirectory)
			iseDirectoryPath = xilinxDirectoryPath / iseVersion / "ISE_DS/ISE"
			
			if not xilinxDirectoryPath.exists():	raise BaseException("Xilinx installation directory '%s' does not exist." % xilinxDirectory)
			if not iseDirectoryPath.exists():			raise BaseException("Xilinx ISE version '%s' is not installed." % iseVersion)
			
			self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
			self.pocConfig['Xilinx.ISE']['Version'] = iseVersion
			self.pocConfig['Xilinx.ISE']['InstallationDirectory'] = '${Xilinx:InstallationDirectory}/${Version}/ISE_DS'
			self.pocConfig['Xilinx.ISE']['BinaryDirectory'] = '${InstallationDirectory}/ISE/bin/nt64'
		else:
			raise BaseException("unknown option")
	
	def manualConfigureWindowsLabTools(self):
		# Ask for installed Xilinx LabTools
		isXilinxLabTools = input('Is Xilinx LabTools installed on your system? [Y/n/p]: ')
		isXilinxLabTools = isXilinxLabTools if isXilinxLabTools != "" else "Y"
		if (isXilinxLabTools  in ['p', 'P']):
			pass
		elif (isXilinxLabTools in ['n', 'N']):
			self.pocConfig['Xilinx.LabTools'] = OrderedDict()
		elif (isXilinxLabTools in ['y', 'Y']):
			xilinxDirectory =	input('Xilinx installation directory [C:\Xilinx]: ')
			labToolsVersion =	input('Xilinx LabTools version number [14.7]: ')
			print()
			
			xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "C:\Xilinx"
			labToolsVersion = labToolsVersion if labToolsVersion != "" else "14.7"
			
			xilinxDirectoryPath = Path(xilinxDirectory)
			labToolsDirectoryPath = xilinxDirectoryPath / labToolsVersion / "LabTools/LabTools"
			
			if not xilinxDirectoryPath.exists():		raise BaseException("Xilinx installation directory '%s' does not exist." % xilinxDirectory)
			if not labToolsDirectoryPath.exists():	raise BaseException("Xilinx LabTools version '%s' is not installed." % labToolsVersion)
			
			self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
			self.pocConfig['Xilinx.LabTools']['Version'] = labToolsVersion
			self.pocConfig['Xilinx.LabTools']['InstallationDirectory'] = '${Xilinx:InstallationDirectory}/${Version}/LabTools'
			self.pocConfig['Xilinx.LabTools']['BinaryDirectory'] = '${InstallationDirectory}/LabTools/bin/nt64'
		else:
			raise BaseException("unknown option")
	
	def manualConfigureWindowsVivado(self):
		# Ask for installed Xilinx Vivado
		isXilinxVivado = input('Is Xilinx Vivado installed on your system? [Y/n/p]: ')
		isXilinxVivado = isXilinxVivado if isXilinxVivado != "" else "Y"
		if (isXilinxVivado  in ['p', 'P']):
			pass
		elif (isXilinxVivado in ['n', 'N']):
			self.pocConfig['Xilinx.Vivado'] = OrderedDict()
		elif (isXilinxVivado in ['y', 'Y']):
			xilinxDirectory =	input('Xilinx installation directory [C:\Xilinx]: ')
			vivadoVersion =		input('Xilinx Vivado version number [2015.2]: ')
			print()
		
			xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "C:\Xilinx"
			vivadoVersion = vivadoVersion if vivadoVersion != "" else "2015.2"
		
			xilinxDirectoryPath = Path(xilinxDirectory)
			vivadoDirectoryPath = xilinxDirectoryPath / "Vivado" / vivadoVersion
		
			if not xilinxDirectoryPath.exists():	raise BaseException("Xilinx installation directory '%s' does not exist." % xilinxDirectory)
			if not vivadoDirectoryPath.exists():	raise BaseException("Xilinx Vivado version '%s' is not installed." % vivadoVersion)
		
			self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
			self.pocConfig['Xilinx.Vivado']['Version'] = vivadoVersion
			self.pocConfig['Xilinx.Vivado']['InstallationDirectory'] = '${Xilinx:InstallationDirectory}/Vivado/${Version}'
			self.pocConfig['Xilinx.Vivado']['BinaryDirectory'] = '${InstallationDirectory}/bin'
		else:
			raise BaseException("unknown option")
	
	def manualConfigureWindowsHardwareServer(self):
		# Ask for installed Xilinx HardwareServer
		isXilinxHardwareServer = input('Is Xilinx HardwareServer installed on your system? [Y/n/p]: ')
		isXilinxHardwareServer = isXilinxHardwareServer if isXilinxHardwareServer != "" else "Y"
		if (isXilinxHardwareServer  in ['p', 'P']):
			pass
		elif (isXilinxHardwareServer in ['n', 'N']):
			self.pocConfig['Xilinx.HardwareServer'] = OrderedDict()
		elif (isXilinxHardwareServer in ['y', 'Y']):
			xilinxDirectory =	input('Xilinx installation directory [C:\Xilinx]: ')
			hardwareServerVersion =		input('Xilinx HardwareServer version number [2015.2]: ')
			print()
		
			xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "C:\Xilinx"
			hardwareServerVersion = hardwareServerVersion if hardwareServerVersion != "" else "2015.2"
		
			xilinxDirectoryPath = Path(xilinxDirectory)
			hardwareServerDirectoryPath = xilinxDirectoryPath / "HardwareServer" / hardwareServerVersion
		
			if not xilinxDirectoryPath.exists():					raise BaseException("Xilinx installation directory '%s' does not exist." % xilinxDirectory)
			if not hardwareServerDirectoryPath.exists():	raise BaseException("Xilinx HardwareServer version '%s' is not installed." % hardwareServerVersion)
		
			self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
			self.pocConfig['Xilinx.HardwareServer']['Version'] = hardwareServerVersion
			self.pocConfig['Xilinx.HardwareServer']['InstallationDirectory'] = '${Xilinx:InstallationDirectory}/HardwareServer/${Version}'
			self.pocConfig['Xilinx.HardwareServer']['BinaryDirectory'] = '${InstallationDirectory}/bin'
		else:
			raise BaseException("unknown option")

	def manualConfigureWindowsQuestaSim(self):
		# Ask for installed Mentor Graphic tools
		isMentor = input('Is a Mentor Graphics tool installed on your system? [Y/n/p]: ')
		isMentor = isMentor if isMentor != "" else "Y"
		if (isMentor  in ['p', 'P']):
			pass
		elif (isMentor in ['n', 'N']):
			self.pocConfig['Mentor'] = OrderedDict()
		elif (isMentor in ['y', 'Y']):
			mentorDirectory =		input('Mentor Graphics installation directory [C:\Mentor]: ')
			print()
			
			mentorDirectory =		mentorDirectory		if mentorDirectory != ""	else "C:\Altera"
			quartusIIVersion =	quartusIIVersion	if quartusIIVersion != ""	else "15.0"
			
			mentorDirectoryPath = Path(mentorDirectory)
			
			if not mentorDirectoryPath.exists():		raise BaseException("Mentor Graphics installation directory '%s' does not exist." % mentorDirectory)
			
			self.pocConfig['Mentor']['InstallationDirectory'] = mentorDirectoryPath.as_posix()
	
			# Ask for installed Mentor QuestaSIM
			isQuestaSim = input('Is Mentor QuestaSIM installed on your system? [Y/n/p]: ')
			isQuestaSim = isQuestaSim if isQuestaSim != "" else "Y"
			if (isQuestaSim  in ['p', 'P']):
				pass
			elif (isQuestaSim in ['n', 'N']):
				self.pocConfig['Mentor.QuestaSIM'] = OrderedDict()
			elif (isQuestaSim in ['y', 'Y']):
				QuestaSimDirectory =	input('QuestaSIM installation directory [{0}\QuestaSim64\\10.2c]: '.format(str(mentorDirectory)))
				QuestaSimVersion =		input('QuestaSIM version number [10.4c]: ')
				print()
			
				QuestaSimDirectory =	QuestaSimDirectory	if QuestaSimDirectory != ""	else str(mentorDirectory) + "\QuestaSim64\\10.4c"
				QuestaSimVersion =		QuestaSimVersion		if QuestaSimVersion != ""		else "10.4c"
				
				QuestaSimDirectoryPath =	Path(QuestaSimDirectory)
				QuestaSimExecutablePath = QuestaSimDirectoryPath / "win64" / "vsim.exe"
			
				if not QuestaSimDirectoryPath.exists():		raise BaseException("QuestaSIM installation directory '%s' does not exist." % QuestaSimDirectory)
				if not QuestaSimExecutablePath.exists():	raise BaseException("QuestaSIM is not installed.")
				
				self.pocConfig['Mentor']['InstallationDirectory'] =			MentorDirectoryPath.as_posix()
				
				self.pocConfig['Mentor.QuestaSIM']['Version'] =								QuestaSimVersion
				self.pocConfig['Mentor.QuestaSIM']['InstallationDirectory'] =	QuestaSimDirectoryPath.as_posix()
				self.pocConfig['Mentor.QuestaSIM']['BinaryDirectory'] =				'${InstallationDirectory}/win64'
			else:
				raise BaseException("unknown option")
		else:
			raise BaseException("unknown option")

	def manualConfigureWindowsGHDL(self):
		# Ask for installed GHDL
		isGHDL = input('Is GHDL installed on your system? [Y/n/p]: ')
		isGHDL = isGHDL if isGHDL != "" else "Y"
		if (isGHDL  in ['p', 'P']):
			pass
		elif (isGHDL in ['n', 'N']):
			self.pocConfig['GHDL'] = OrderedDict()
		elif (isGHDL in ['y', 'Y']):
			ghdlDirectory =	input('GHDL installation directory [C:\Program Files (x86)\GHDL]: ')
			ghdlVersion =		input('GHDL version number [0.31]: ')
			print()
		
			ghdlDirectory = ghdlDirectory if ghdlDirectory != "" else "C:\Program Files (x86)\GHDL"
			ghdlVersion = ghdlVersion if ghdlVersion != "" else "0.31"
		
			ghdlDirectoryPath = Path(ghdlDirectory)
			ghdlExecutablePath = ghdlDirectoryPath / "bin" / "ghdl.exe"
		
			if not ghdlDirectoryPath.exists():	raise BaseException("GHDL installation directory '%s' does not exist." % ghdlDirectory)
			if not ghdlExecutablePath.exists():	raise BaseException("GHDL is not installed.")
		
			self.pocConfig['GHDL']['Version'] = ghdlVersion
			self.pocConfig['GHDL']['InstallationDirectory'] = ghdlDirectoryPath.as_posix()
			self.pocConfig['GHDL']['BinaryDirectory'] = '${InstallationDirectory}/bin'
			self.pocConfig['GHDL']['Backend'] = 'mcode'
		else:
			raise BaseException("unknown option")
	
	def manualConfigureWindowsGTKW(self):
		# Ask for installed GTKWave
		isGTKW = input('Is GTKWave installed on your system? [Y/n/p]: ')
		isGTKW = isGTKW if isGTKW != "" else "Y"
		if (isGTKW  in ['p', 'P']):
			pass
		elif (isGTKW in ['n', 'N']):
			self.pocConfig['GTKWave'] = OrderedDict()
		elif (isGTKW in ['y', 'Y']):
			gtkwDirectory =	input('GTKWave installation directory [C:\Program Files (x86)\GTKWave]: ')
			gtkwVersion =		input('GTKWave version number [3.3.61]: ')
			print()
		
			gtkwDirectory = gtkwDirectory if gtkwDirectory != "" else "C:\Program Files (x86)\GTKWave"
			gtkwVersion = gtkwVersion if gtkwVersion != "" else "3.3.61"
		
			gtkwDirectoryPath = Path(gtkwDirectory)
			gtkwExecutablePath = gtkwDirectoryPath / "bin" / "gtkwave.exe"
		
			if not gtkwDirectoryPath.exists():	raise BaseException("GTKWave installation directory '%s' does not exist." % gtkwDirectory)
			if not gtkwExecutablePath.exists():	raise BaseException("GTKWave is not installed.")
		
			self.pocConfig['GTKWave']['Version'] = gtkwVersion
			self.pocConfig['GTKWave']['InstallationDirectory'] = gtkwDirectoryPath.as_posix()
			self.pocConfig['GTKWave']['BinaryDirectory'] = '${InstallationDirectory}/bin'
		else:
			raise BaseException("unknown option")
	
	def manualConfigureLinuxQuartusII(self):
		# Ask for installed Altera Quartus-II
		isAlteraQuartusII = input('Is Altera Quartus-II installed on your system? [Y/n/p]: ')
		isAlteraQuartusII = isAlteraQuartusII if isAlteraQuartusII != "" else "Y"
		if (isAlteraQuartusII  in ['p', 'P']):
			pass
		elif (isAlteraQuartusII in ['n', 'N']):
			self.pocConfig['Altera.QuartusII'] = OrderedDict()
		elif (isAlteraQuartusII in ['y', 'Y']):
			alteraDirectory =		input('Altera installation directory [/opt/Altera]: ')
			quartusIIVersion =	input('Altera QuartusII version number [15.0]: ')
			print()
			
			alteraDirectory =		alteraDirectory		if alteraDirectory != ""	else "/opt/Altera"
			quartusIIVersion =	quartusIIVersion	if quartusIIVersion != ""	else "15.0"
			
			alteraDirectoryPath = Path(alteraDirectory)
			quartusIIDirectoryPath = alteraDirectoryPath / quartusIIVersion / "quartus"
			
			if not alteraDirectoryPath.exists():		raise BaseException("Altera installation directory '%s' does not exist." % alteraDirectory)
			if not quartusIIDirectoryPath.exists():	raise BaseException("Altera QuartusII version '%s' is not installed." % quartusIIVersion)
			
			self.pocConfig['Altera']['InstallationDirectory'] = alteraDirectoryPath.as_posix()
			self.pocConfig['Altera.QuartusII']['Version'] = quartusIIVersion
			self.pocConfig['Altera.QuartusII']['InstallationDirectory'] = '${Altera:InstallationDirectory}/${Version}'
			self.pocConfig['Altera.QuartusII']['BinaryDirectory'] = '${InstallationDirectory}/quartus/bin'
			
			# Ask for installed Altera ModelSimAltera
			isAlteraModelSim = input('Is ModelSim - Altera Edition installed on your system? [Y/n/p]: ')
			isAlteraModelSim = isAlteraModelSim if isAlteraModelSim != "" else "Y"
			if (isAlteraModelSim  in ['p', 'P']):
				pass
			elif (isAlteraModelSim in ['n', 'N']):
				self.pocConfig['Altera.ModelSim'] = OrderedDict()
			elif (isAlteraModelSim in ['y', 'Y']):
				alteraModelSimVersion =	input('ModelSim - Altera Edition version number [10.1e]: ')
			
				alteraModelSimDirectoryPath = alteraDirectoryPath / quartusIIVersion / "modelsim_ase"
			
				if not alteraModelSimDirectoryPath.exists():	raise BaseException("ModelSim - Altera Edition installation directory '%s' does not exist." % str(alteraModelSimDirectoryPath))
				
				self.pocConfig['Altera.ModelSim']['Version'] = alteraModelSimVersion
				self.pocConfig['Altera.ModelSim']['InstallationDirectory'] = '${Altera:InstallationDirectory}/${Altera.QuartusII:Version}/modelsim_ase'
				self.pocConfig['Altera.ModelSim']['BinaryDirectory'] = '${InstallationDirectory}/bin'
			else:
				raise BaseException("unknown option")
		else:
			raise BaseException("unknown option")
			
	def manualConfigureLinuxISE(self):
		# Ask for installed Xilinx ISE
		isXilinxISE = input('Is Xilinx ISE installed on your system? [Y/n/p]: ')
		isXilinxISE = isXilinxISE if isXilinxISE != "" else "Y"
		if (isXilinxISE  in ['p', 'P']):
			pass
		elif (isXilinxISE in ['n', 'N']):
			self.pocConfig['Xilinx.ISE'] = OrderedDict()
		elif (isXilinxISE in ['y', 'Y']):
			xilinxDirectory =	input('Xilinx installation directory [/opt/Xilinx]: ')
			iseVersion =			input('Xilinx ISE version number [14.7]: ')
			print()
		
			xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "/opt/Xilinx"
			iseVersion = iseVersion if iseVersion != "" else "14.7"
		
			xilinxDirectoryPath = Path(xilinxDirectory)
			iseDirectoryPath = xilinxDirectoryPath / iseVersion / "ISE_DS/ISE"
		
			if not xilinxDirectoryPath.exists():	raise BaseException("Xilinx installation directory '%s' does not exist." % xilinxDirectory)
			if not iseDirectoryPath.exists():			raise BaseException("Xilinx ISE version '%s' is not installed." % iseVersion)
		
			self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
			self.pocConfig['Xilinx.ISE']['Version'] = iseVersion
			self.pocConfig['Xilinx.ISE']['InstallationDirectory'] = '${Xilinx:InstallationDirectory}/${Version}/ISE_DS'
			self.pocConfig['Xilinx.ISE']['BinaryDirectory'] = '${InstallationDirectory}/ISE/bin/lin64'
		else:
			raise BaseException("unknown option")
	
	def manualConfigureLinuxLabTools(self):
		# Ask for installed Xilinx LabTools
		isXilinxLabTools = input('Is Xilinx LabTools installed on your system? [Y/n/p]: ')
		isXilinxLabTools = isXilinxLabTools if isXilinxLabTools != "" else "Y"
		if (isXilinxLabTools  in ['p', 'P']):
			pass
		elif (isXilinxLabTools in ['n', 'N']):
			self.pocConfig['Xilinx.LabTools'] = OrderedDict()
		elif (isXilinxLabTools in ['y', 'Y']):
			xilinxDirectory =	input('Xilinx installation directory [/opt/Xilinx]: ')
			labToolsVersion =	input('Xilinx LabTools version number [14.7]: ')
			print()
		
			xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "/opt/Xilinx"
			labToolsVersion = labToolsVersion if labToolsVersion != "" else "14.7"
		
			xilinxDirectoryPath = Path(xilinxDirectory)
			labToolsDirectoryPath = xilinxDirectoryPath / labToolsVersion / "LabTools/LabTools"
		
			if not xilinxDirectoryPath.exists():		raise BaseException("Xilinx installation directory '%s' does not exist." % xilinxDirectory)
			if not labToolsDirectoryPath.exists():	raise BaseException("Xilinx LabTools version '%s' is not installed." % labToolsVersion)
		
			self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
			self.pocConfig['Xilinx.LabTools']['Version'] = labToolsVersion
			self.pocConfig['Xilinx.LabTools']['InstallationDirectory'] = '${Xilinx:InstallationDirectory}/${Version}/LabTools'
			self.pocConfig['Xilinx.LabTools']['BinaryDirectory'] = '${InstallationDirectory}/LabTools/bin/lin64'
		else:
			raise BaseException("unknown option")
		
	def manualConfigureLinuxVivado(self):
		# Ask for installed Xilinx Vivado
		isXilinxVivado = input('Is Xilinx Vivado installed on your system? [Y/n/p]: ')
		isXilinxVivado = isXilinxVivado if isXilinxVivado != "" else "Y"
		if (isXilinxVivado  in ['p', 'P']):
			pass
		elif (isXilinxVivado in ['n', 'N']):
			self.pocConfig['Xilinx.Vivado'] = OrderedDict()
		elif (isXilinxVivado in ['y', 'Y']):
			xilinxDirectory =	input('Xilinx installation directory [/opt/Xilinx]: ')
			vivadoVersion =		input('Xilinx Vivado version number [2015.2]: ')
			print()
		
			xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "/opt/Xilinx"
			vivadoVersion = vivadoVersion if vivadoVersion != "" else "2015.2"
		
			xilinxDirectoryPath = Path(xilinxDirectory)
			vivadoDirectoryPath = xilinxDirectoryPath / "Vivado" / vivadoVersion
		
			if not xilinxDirectoryPath.exists():	raise BaseException("Xilinx installation directory '%s' does not exist." % xilinxDirectory)
			if not vivadoDirectoryPath.exists():	raise BaseException("Xilinx Vivado version '%s' is not installed." % vivadoVersion)
		
			self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
			self.pocConfig['Xilinx.Vivado']['Version'] = vivadoVersion
			self.pocConfig['Xilinx.Vivado']['InstallationDirectory'] = '${Xilinx:InstallationDirectory}/Vivado/${Version}'
			self.pocConfig['Xilinx.Vivado']['BinaryDirectory'] = '${InstallationDirectory}/bin'
		else:
			raise BaseException("unknown option")
	
	def manualConfigureLinuxHardwareServer(self):
		# Ask for installed Xilinx HardwareServer
		isXilinxHardwareServer = input('Is Xilinx HardwareServer installed on your system? [Y/n/p]: ')
		isXilinxHardwareServer = isXilinxHardwareServer if isXilinxHardwareServer != "" else "Y"
		if (isXilinxHardwareServer  in ['p', 'P']):
			pass
		elif (isXilinxHardwareServer in ['n', 'N']):
			self.pocConfig['Xilinx.HardwareServer'] = OrderedDict()
		elif (isXilinxHardwareServer in ['y', 'Y']):
			xilinxDirectory =	input('Xilinx installation directory [/opt/Xilinx]: ')
			hardwareServerVersion =		input('Xilinx HardwareServer version number [2015.2]: ')
			print()
		
			xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "/opt/Xilinx"
			hardwareServerVersion = hardwareServerVersion if hardwareServerVersion != "" else "2015.2"
		
			xilinxDirectoryPath = Path(xilinxDirectory)
			hardwareServerDirectoryPath = xilinxDirectoryPath / "HardwareServer" / hardwareServerVersion
		
			if not xilinxDirectoryPath.exists():					raise BaseException("Xilinx installation directory '%s' does not exist." % xilinxDirectory)
			if not hardwareServerDirectoryPath.exists():	raise BaseException("Xilinx HardwareServer version '%s' is not installed." % hardwareServerVersion)
		
			self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
			self.pocConfig['Xilinx.HardwareServer']['Version'] = hardwareServerVersion
			self.pocConfig['Xilinx.HardwareServer']['InstallationDirectory'] = '${Xilinx:InstallationDirectory}/HardwareServer/${Version}'
			self.pocConfig['Xilinx.HardwareServer']['BinaryDirectory'] = '${InstallationDirectory}/bin'
		else:
			raise BaseException("unknown option")
			
	def manualConfigureLinuxQuestaSim(self):
		# Ask for installed Mentor QuestaSIM
		isQuestaSim = input('Is mentor QuestaSIM installed on your system? [Y/n/p]: ')
		isQuestaSim = isQuestaSim if isQuestaSim != "" else "Y"
		if (isQuestaSim  in ['p', 'P']):
			pass
		elif (isQuestaSim in ['n', 'N']):
			self.pocConfig['Mentor.QuestaSIM'] = OrderedDict()
		elif (isQuestaSim in ['y', 'Y']):
			QuestaSimDirectory =	input('QuestaSIM installation directory [/opt/QuestaSim/10.2c]: ')
			QuestaSimVersion =		input('QuestaSIM version number [10.2c]: ')
			print()
		
			QuestaSimDirectory =	QuestaSimDirectory	if QuestaSimDirectory != ""	else "/opt/QuestaSim/10.2c"
			QuestaSimVersion =		QuestaSimVersion		if QuestaSimVersion != ""		else "10.2c"
		
			QuestaSimDirectoryPath = Path(QuestaSimDirectory)
			QuestaSimExecutablePath = QuestaSimDirectoryPath / "bin" / "vsim"
		
			if not QuestaSimDirectoryPath.exists():		raise BaseException("QuestaSIM installation directory '%s' does not exist." % QuestaSimDirectory)
			if not QuestaSimExecutablePath.exists():	raise BaseException("QuestaSIM is not installed.")
		
			self.pocConfig['Mentor.QuestaSIM']['Version'] =								QuestaSimVersion
			self.pocConfig['Mentor.QuestaSIM']['InstallationDirectory'] =	QuestaSimDirectoryPath.as_posix()
			self.pocConfig['Mentor.QuestaSIM']['BinaryDirectory'] =				'${InstallationDirectory}/bin'
		else:
			raise BaseException("unknown option")
	
	def manualConfigureLinuxGHDL(self):
		# Ask for installed GHDL
		isGHDL = input('Is GHDL installed on your system? [Y/n/p]: ')
		isGHDL = isGHDL if isGHDL != "" else "Y"
		if (isGHDL  in ['p', 'P']):
			pass
		elif (isGHDL in ['n', 'N']):
			self.pocConfig['GHDL'] = OrderedDict()
		elif (isGHDL in ['y', 'Y']):
			ghdlDirectory =	input('GHDL installation directory [/usr/bin]: ')
			ghdlVersion =		input('GHDL version number [0.31]: ')
			print()
		
			ghdlDirectory = ghdlDirectory if ghdlDirectory != "" else "/usr/bin"
			ghdlVersion = ghdlVersion if ghdlVersion != "" else "0.31"
		
			ghdlDirectoryPath = Path(ghdlDirectory)
			ghdlExecutablePath = ghdlDirectoryPath / "ghdl"
		
			if not ghdlDirectoryPath.exists():	raise BaseException("GHDL installation directory '%s' does not exist." % ghdlDirectory)
			if not ghdlExecutablePath.exists():	raise BaseException("GHDL is not installed.")
		
			self.pocConfig['GHDL']['Version'] = ghdlVersion
			self.pocConfig['GHDL']['InstallationDirectory'] = ghdlDirectoryPath.as_posix()
			self.pocConfig['GHDL']['BinaryDirectory'] = '${InstallationDirectory}'
			self.pocConfig['GHDL']['Backend'] = 'llvm'
		else:
			raise BaseException("unknown option")

	def manualConfigureLinuxGTKW(self):
		# Ask for installed GTKWave
		isGTKW = input('Is GTKWave installed on your system? [Y/n/p]: ')
		isGTKW = isGTKW if isGTKW != "" else "Y"
		if (isGTKW  in ['p', 'P']):
				pass
		elif (isGTKW in ['n', 'N']):
			self.pocConfig['GTKWave'] = OrderedDict()
		elif (isGTKW in ['y', 'Y']):
			gtkwDirectory =	input('GTKWave installation directory [/usr/bin]: ')
			gtkwVersion =		input('GTKWave version number [3.3.61]: ')
			print()
		
			gtkwDirectory = gtkwDirectory if gtkwDirectory != "" else "/usr/bin"
			gtkwVersion = gtkwVersion if gtkwVersion != "" else "3.3.61"
		
			gtkwDirectoryPath = Path(gtkwDirectory)
			gtkwExecutablePath = gtkwDirectoryPath / "gtkwave"
		
			if not gtkwDirectoryPath.exists():	raise BaseException("GTKWave installation directory '%s' does not exist." % gtkwDirectory)
			if not gtkwExecutablePath.exists():	raise BaseException("GTKWave is not installed.")
		
			self.pocConfig['GTKWave']['Version'] = gtkwVersion
			self.pocConfig['GTKWave']['InstallationDirectory'] = gtkwDirectoryPath.as_posix()
			self.pocConfig['GTKWave']['BinaryDirectory'] = '${InstallationDirectory}'
		else:
			raise BaseException("unknown option")
	
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
			raise BaseException("Solution is already registered in PoC Library.")
		
		# 
		solutionFileDirectoryName = input("Where is the solution file 'solution.ini' stored? [./py]: ")
		solutionFileDirectoryName = solutionFileDirectoryName if solutionFileDirectoryName != "" else "py"
	
		solutionFilePath = Path(solutionFileDirectoryName)
	
		if (solutionFilePath.is_absolute()):
			solutionFilePath = solutionFilePath / "solution.ini"
		else:
			solutionFilePath = ((self.directories['Working'] / solutionFilePath).resolve()) / "solution.ini"
			
		if (not solutionFilePath.exists()):
			raise BaseException("Solution file '%s' does not exist." % str(solutionFilePath))
		
		self.pocConfig['Solutions'][solutionName] = solutionFilePath.as_posix()
	
		# write configuration
		self.writePoCConfiguration()
		# re-read configuration
		self.readPoCConfiguration()
	
	def cleanupPoCConfiguration(self):
		# remove non-private sections from pocConfig
		sections = self.pocConfig.sections()
		for privateSection in self.__privateSections:
			sections.remove(privateSection)
		for section in sections:
			self.pocConfig.remove_section(section)
		
		# remove non-private options from [PoC] section
		pocOptions = self.pocConfig.options("PoC")
		for privatePoCOption in self.__privatePoCOptions:
			pocOptions.remove(privatePoCOption)
		for pocOption in pocOptions:
			self.pocConfig.remove_option("PoC", pocOption)
	
	def writePoCConfiguration(self):
		self.cleanupPoCConfiguration()
		
		# Writing configuration to disc
		print("Writing configuration file to '%s'" % str(self.files['PoCPrivateConfig']))
		with self.files['PoCPrivateConfig'].open('w') as configFileHandle:
			self.pocConfig.write(configFileHandle)
	
	def getPoCInstallationDir(self):
		if (len(self.pocConfig.options("PoC")) != 0):
			pocInstallationDirectoryPath = Path(self.pocConfig['PoC']['InstallationDirectory'])
			
			return str(pocInstallationDirectoryPath)
		else:
			raise NotConfiguredException("ERROR: PoC is not configured on this system.")
			
	def getModelSimInstallationDir(self):
		if (len(self.pocConfig.options("Mentor.QuestaSim")) != 0):
			modelSimInstallationDirectoryPath = Path(self.pocConfig['Mentor.QuestaSim']['InstallationDirectory'])
			
		elif (len(self.pocConfig.options("Altera.ModelSim")) != 0):
			modelSimInstallationDirectoryPath = Path(self.pocConfig['Altera.ModelSim']['InstallationDirectory'])
			
		else:
			raise NotConfiguredException("ERROR: ModelSim is not configured on this system.")
		return str(modelSimInstallationDirectoryPath)
			
	def getISESettingsFile(self):
		if (len(self.pocConfig.options("Xilinx.ISE")) != 0):
			iseInstallationDirectoryPath = Path(self.pocConfig['Xilinx.ISE']['InstallationDirectory'])
			
			if		(self.platform == "Windows"):		return (str(iseInstallationDirectoryPath / "settings64.bat"))
			elif	(self.platform == "Linux"):			return (str(iseInstallationDirectoryPath / "settings64.sh"))
			else:	raise PlatformNotSupportedException(self.platform)
		elif (len(self.pocConfig.options("Xilinx.LabTools")) != 0):
			labToolsInstallationDirectoryPath = Path(self.pocConfig['Xilinx.LabTools']['InstallationDirectory'])
			
			if		(self.platform == "Windows"):		return (str(labToolsInstallationDirectoryPath / "settings64.bat"))
			elif	(self.platform == "Linux"):			return (str(labToolsInstallationDirectoryPath / "settings64.sh"))
			else:	raise PlatformNotSupportedException(self.platform)
		else:
			raise NotConfiguredException("ERROR: Xilinx ISE or Xilinx LabTools is not configured on this system.")
			
	def getVivadoSettingsFile(self):
		if (len(self.pocConfig.options("Xilinx.Vivado")) != 0):
			vivadoInstallationDirectoryPath = Path(self.pocConfig['Xilinx.Vivado']['InstallationDirectory'])
			
			if		(self.platform == "Windows"):		return (str(vivadoInstallationDirectoryPath / "settings64.bat"))
			elif	(self.platform == "Linux"):			return (str(vivadoInstallationDirectoryPath / "settings64.sh"))
			else:	raise PlatformNotSupportedException(self.platform)
		elif (len(self.pocConfig.options("Xilinx.HardwareServer")) != 0):
			hardwareServerInstallationDirectoryPath = Path(self.pocConfig['Xilinx.HardwareServer']['InstallationDirectory'])
			
			if		(self.platform == "Windows"):		return (str(hardwareServerInstallationDirectoryPath / "settings64.bat"))
			elif	(self.platform == "Linux"):			return (str(hardwareServerInstallationDirectoryPath / "settings64.sh"))
			else:	raise PlatformNotSupportedException(self.platform)
		else:
			raise NotConfiguredException("ERROR: Xilinx Vivado or Xilinx HardwareServer is not configured on this system.")
	
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
				This is the PoC-Library Repository Service Tool.
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
		group21.add_argument('--poc-installdir',									dest="pocInstallationDir",			help='return PoC installation directory',			action='store_const', const=True, default=False)
		group21.add_argument('--modelsim-installdir',								dest="modelSimInstallationDir",			help='return ModelSim installation directory',			action='store_const', const=True, default=False)
		group21.add_argument('--ise-settingsfile',								dest="iseSettingsFile",			help='return Xilinx ISE settings file',			action='store_const', const=True, default=False)
		group21.add_argument('--vivado-settingsfile',							dest="vivadoSettingsFile",	help='return Xilinx Vivado settings file',	action='store_const', const=True, default=False)

		# parse command line options
		args = argParser.parse_args()

	except Exception as ex:
		Exit.printException(ex)

	# create class instance and start processing
	try:
		from colorama import Fore, Back, Style
		
		config = Configuration(args.debug, args.verbose, args.quiet)
		
		if (args.help == True):
			print(Fore.MAGENTA + "=" * 80)
			print("{: ^80s}".format(Configuration.headLine))
			print("=" * 80)
			print(Fore.RESET + Back.RESET + Style.RESET_ALL)
		
			argParser.print_help()
			return
		elif args.configurePoC:
			print(Fore.MAGENTA + "=" * 80)
			print("{: ^80s}".format(Configuration.headLine))
			print("=" * 80)
			print(Fore.RESET + Back.RESET + Style.RESET_ALL)
		
			#config.autoConfiguration()
			config.manualConfiguration()
			exit(0)
			
		elif args.newSolution:
			print(Fore.MAGENTA + "=" * 80)
			print("{: ^80s}".format(Configuration.headLine))
			print("=" * 80)
			print(Fore.RESET + Back.RESET + Style.RESET_ALL)
			
			config.newSolution(args.newSolution)
			exit(0)
			
		elif args.addSolution:
			print(Fore.MAGENTA + "=" * 80)
			print("{: ^80s}".format(Configuration.headLine))
			print("=" * 80)
			print(Fore.RESET + Back.RESET + Style.RESET_ALL)
			
			config.addSolution(args.addSolution)
			exit(0)
			
		elif args.pocInstallationDir:
			print(config.getPoCInstallationDir())
			exit(0)
		elif args.modelSimInstallationDir:
			print(config.getModelSimInstallationDir())
			exit(0)
		elif args.iseSettingsFile:
			print(config.getISESettingsFile())
			exit(0)
		elif args.vivadoSettingsFile:
			print(config.getVivadoSettingsFile())
			exit(0)
		else:
			print(Fore.MAGENTA + "=" * 80)
			print("{: ^80s}".format(Configuration.headLine))
			print("=" * 80)
			print(Fore.RESET + Back.RESET + Style.RESET_ALL)
		
			argParser.print_help()
			exit(0)
	
#	except ConfiguratorException as ex:
#		from colorama import Fore, Back, Style
#		print(Fore.RED + "ERROR:" + Fore.RESET + " %s" % ex.message)
#		if isinstance(ex.__cause__, FileNotFoundError):
#			print(Fore.YELLOW + "  FileNotFound:" + Fore.RESET + " '%s'" % str(ex.__cause__))
#		print(Fore.RESET + Back.RESET + Style.RESET_ALL)
#		exit(1)
		
	except NotConfiguredException as ex:				Exit.printNotConfiguredException(ex)
	except PlatformNotSupportedException as ex:	Exit.printPlatformNotSupportedException(ex)
	except BaseException as ex:									Exit.printBaseException(ex)
	except NotImplementedException as ex:				Exit.printNotImplementedException(ex)
	except Exception as ex:											Exit.printException(ex)
			
# entry point
if __name__ == "__main__":
	Exit.versionCheck((3,4,0))
	main()
else:
	Exit.printThisIsNoLibraryFile(Configuration.headLine)
