# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
# Authors:				 		Patrick Lehmann
# 
# Python Executable:	Entry point to the testbench tools in PoC repository.
# 
# Description:
# ------------------------------------
#	This is a python main module (executable) which:
#		- runs automated testbenches,
#		- ...
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

from pathlib import Path

from Base.Exceptions import *
from Base.PoCBase import CommandLineProgram
from PoC.Entity import *
from Simulator import *
from Simulator.Exceptions import *

class Testbench(CommandLineProgram):
	# configuration files
	__tbConfigFileName = "configuration.ini"
	
	# configuration
	tbConfig = None
	
	def __init__(self, debug, verbose, quiet):
		super(self.__class__, self).__init__(debug, verbose, quiet)

		if not ((self.platform == "Windows") or (self.platform == "Linux")):	raise PlatformNotSupportedException(self.platform)
		
		self.readTestbenchConfiguration()
		
	# read Testbench configuration
	# ==========================================================================
	def readTestbenchConfiguration(self):
		from configparser import ConfigParser, ExtendedInterpolation
	
		tbConfigFilePath = self.directories["PoCRoot"] / self.pocConfig['PoC.DirectoryNames']['TestbenchFiles'] / self.__tbConfigFileName
		self.files["PoCTBConfig"] = tbConfigFilePath
		
		self.printDebug("Reading testbench configuration from '%s'" % str(tbConfigFilePath))
		if not tbConfigFilePath.exists():	raise NotConfiguredException("PoC testbench configuration file does not exist. (%s)" % str(tbConfigFilePath))
			
		self.tbConfig = ConfigParser(interpolation=ExtendedInterpolation())
		self.tbConfig.optionxform = str
		self.tbConfig.read([
			str(self.files["PoCPrivateConfig"]),
			str(self.files["PoCPublicConfig"]),
			str(self.files["PoCTBConfig"])
		])
	
	def listSimulations(self, module):
		entityToList = Entity(self, module)
		
		print(str(entityToList))
		
		print(self.tbConfig.sections())
		print()
		print(self.tbConfig.options("PoC"))
		print()
		
		
		for sec in self.tbConfig.sections():
			if (sec[:4] == "PoC."):
				print(sec)
		
		return("return ...")
		return
	
	def iSimSimulation(self, module, showLogs, showReport, guiMode):
		# check if ISE is configure
		if (len(self.pocConfig.options("Xilinx-ISE")) == 0):	raise NotConfiguredException("Xilinx ISE is not configured on this system.")
		
		# prepare some paths
		self.directories["ISEInstallation"] = Path(self.pocConfig['Xilinx-ISE']['InstallationDirectory'])
		self.directories["ISEBinary"] =				Path(self.pocConfig['Xilinx-ISE']['BinaryDirectory'])
		
		# check if the appropriate environment is loaded
		from os import environ
		if (environ.get('XILINX') == None):		raise EnvironmentException("Xilinx ISE environment is not loaded in this shell environment. ")

		entityToSimulate = Entity(self, module)


		simulator = ISESimulator.Simulator(self, showLogs, showReport, guiMode)
		simulator.run(entityToSimulate)

	def xSimSimulation(self, module, showLogs, showReport, guiMode):
		# check if ISE is configure
		if (len(self.pocConfig.options("Xilinx-Vivado")) == 0):	raise NotConfiguredException("Xilinx Vivado is not configured on this system.")

		# prepare some paths
		self.directories["VivadoInstallation"] =	Path(self.pocConfig['Xilinx-Vivado']['InstallationDirectory'])
		self.directories["VivadoBinary"] =				Path(self.pocConfig['Xilinx-Vivado']['BinaryDirectory'])

		entityToSimulate = Entity(self, module)

		simulator = VivadoSimulator.Simulator(self, showLogs, showReport, guiMode)
		simulator.run(entityToSimulate)

	def vSimSimulation(self, module, showLogs, showReport, vhdlStandard, guiMode):
		# check if ISE is configure
		if (len(self.pocConfig.options("Questa-SIM")) != 0):
			# prepare some paths
			self.directories["vSimInstallation"] =	Path(self.pocConfig['Questa-SIM']['InstallationDirectory'])
			self.directories["vSimBinary"] =				Path(self.pocConfig['Questa-SIM']['BinaryDirectory'])
		
		elif (len(self.pocConfig.options("Altera-ModelSim")) != 0):
			# prepare some paths
			self.directories["vSimInstallation"] =	Path(self.pocConfig['Altera-ModelSim']['InstallationDirectory'])
			self.directories["vSimBinary"] =				Path(self.pocConfig['Altera-ModelSim']['BinaryDirectory'])
				
		else:
			raise NotConfiguredException("Neither Mentor Graphics Questa-SIM nor ModelSim are configured on this system.")

		if (len(self.pocConfig.options("GTKWave")) != 0):		
			self.directories["GTKWInstallation"] =	Path(self.pocConfig['GTKWave']['InstallationDirectory'])
			self.directories["GTKWBinary"] =				Path(self.pocConfig['GTKWave']['BinaryDirectory'])

		entityToSimulate = Entity(self, module)

		simulator = QuestaSimulator.Simulator(self, showLogs, showReport, vhdlStandard, guiMode)
		simulator.run(entityToSimulate)
		
	def ghdlSimulation(self, module, showLogs, showReport, vhdlStandard, guiMode):
		# check if GHDL is configure
		if (len(self.pocConfig.options("GHDL")) == 0):		raise NotConfiguredException("GHDL is not configured on this system.")
		
		# prepare some paths
		self.directories["GHDLInstallation"] =	Path(self.pocConfig['GHDL']['InstallationDirectory'])
		self.directories["GHDLBinary"] =				Path(self.pocConfig['GHDL']['BinaryDirectory'])
		
		if (len(self.pocConfig.options("GTKWave")) != 0):		
			self.directories["GTKWInstallation"] =	Path(self.pocConfig['GTKWave']['InstallationDirectory'])
			self.directories["GTKWBinary"] =				Path(self.pocConfig['GTKWave']['BinaryDirectory'])
		
		entityToSimulate = Entity(self, module)

		simulator = GHDLSimulator.Simulator(self, showLogs, showReport, vhdlStandard, guiMode)
		simulator.run(entityToSimulate)


# main program
def main():
	print("=" * 80)
	print("{: ^80s}".format("The PoC Library - Testbench Service Tool"))
	print("=" * 80)
	print()
	
	try:
		import argparse
		import textwrap
		
		# create a commandline argument parser
		argParser = argparse.ArgumentParser(
			formatter_class = argparse.RawDescriptionHelpFormatter,
			description = textwrap.dedent('''\
				This is the PoC Library Testbench Service Tool.
				'''),
			add_help=False)

		# add arguments
		group1 = argParser.add_argument_group('Verbosity')
		group1.add_argument('-D', 																							help='enable script wrapper debug mode',	action='store_const', const=True, default=False)
		group1.add_argument('-d',														dest="debug",				help='enable debug mode',									action='store_const', const=True, default=False)
		group1.add_argument('-v',														dest="verbose",			help='print out detailed messages',				action='store_const', const=True, default=False)
		group1.add_argument('-q',														dest="quiet",				help='run in quiet mode',									action='store_const', const=True, default=False)
		group1.add_argument('-r',														dest="showReport",	help='show report',												action='store_const', const=True, default=False)
		group1.add_argument('-l',														dest="showLog",			help='show logs',													action='store_const', const=True, default=False)
		group2 = argParser.add_argument_group('Commands')
		group21 = group2.add_mutually_exclusive_group(required=True)
		group21.add_argument('-h', '--help',								dest="help",				help='show this help message and exit',		action='store_const', const=True, default=False)
		group21.add_argument('--list',	metavar="<Entity>",	dest="list",				help='list available testbenches')
		group21.add_argument('--isim',	metavar="<Entity>",	dest="isim",				help='use Xilinx ISE Simulator (isim)')
		group21.add_argument('--xsim',	metavar="<Entity>",	dest="xsim",				help='use Xilinx Vivado Simulator (xsim)')
		group21.add_argument('--vsim',	metavar="<Entity>",	dest="vsim",				help='use Mentor Graphics Simulator (vsim)')
		group21.add_argument('--ghdl',	metavar="<Entity>",	dest="ghdl",				help='use GHDL Simulator (ghdl)')
		group3 = argParser.add_argument_group('Options')
		group3.add_argument('--std',	metavar="<version>",	dest="std",					help='set VHDL standard [87,93,02,08]; default=93')
#		group3.add_argument('-i', '--interactive',					dest="interactive",	help='start simulation in interactive mode',	action='store_const', const=True, default=False)
		group3.add_argument('-g', '--gui',									dest="gui",					help='start simulation in gui mode',					action='store_const', const=True, default=False)

		# parse command line options
		args = argParser.parse_args()

	except Exception as ex:
		from traceback import print_tb
		print("FATAL: %s" % ex.__str__())
		print("-" * 80)
		print_tb(ex.__traceback__)
		print("-" * 80)
		print()
		return

	# create class instance and start processing
	try:
		test = Testbench(args.debug, args.verbose, args.quiet)
		
		if (args.help == True):
			argParser.print_help()
			print()
			return
		elif (args.list is not None):
			test.listSimulations(args.list)
		elif (args.isim is not None):
			iSimGUIMode =					args.gui
			
			test.iSimSimulation(args.isim, args.showLog, args.showReport, iSimGUIMode)
		elif (args.xsim is not None):
			xSimGUIMode =					args.gui
			
			test.xSimSimulation(args.xsim, args.showLog, args.showReport, xSimGUIMode)
		elif (args.vsim is not None):
			if ((args.std is not None) and (args.std in ["87","93","02","08"])):
				vhdlStandard = args.std
			else:
				vhdlStandard = "93"
			
			vSimGUIMode =					args.gui
			
			test.vSimSimulation(args.vsim, args.showLog, args.showReport, vhdlStandard, vSimGUIMode)
		elif (args.ghdl is not None):
			if ((args.std is not None) and (args.std in ["87","93","02","08"])):
				vhdlStandard = args.std
			else:
				vhdlStandard = "93"
			
			ghdlGUIMode =					args.gui
			
			test.ghdlSimulation(args.ghdl, args.showLog, args.showReport, vhdlStandard, ghdlGUIMode)
		else:
			argParser.print_help()
	
	except SimulatorException as ex:
		print("ERROR: %s" % ex.message)
		print()
		return
		
	except EnvironmentException as ex:
		print("ERROR: %s" % ex.message)
		print()
		print("Please run this script with it's provided wrapper or manually load the required environment before executing this script.")
		return
	
	except NotConfiguredException as ex:
		print("ERROR: %s" % ex.message)
		print()
		print("Please run 'poc.[sh/cmd] --configure' in PoC root directory.")
		return
	
	except PlatformNotSupportedException as ex:
		print("ERROR: Unknown platform '%s'" % ex.message)
		print()
		return
	
	except BaseException as ex:
		print("ERROR: %s" % ex.message)
		print()
		return
	
	except NotImplementedException as ex:
		print("ERROR: %s" % ex.message)
		print()
		return

	except Exception as ex:
		from traceback import print_tb
		print("FATAL: %s" % ex.__str__())
		print("-" * 80)
		print_tb(ex.__traceback__)
		print("-" * 80)
		print()
		return
	
# entry point
if __name__ == "__main__":
	from sys import version_info
	
	if (version_info<(3,4,0)):
		print("ERROR: Used Python interpreter is to old: %s" % version_info)
		print("Minimal required Python version is 3.4.0")
		exit(1)
			
	main()
else:
	from sys import exit
	
	print("=" * 80)
	print("{: ^80s}".format("The PoC Library - Testbench Service Tool"))
	print("=" * 80)
	print()
	print("This is no library file!")
	exit(1)
