# EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
# Authors:         		 Patrick Lehmann
# 
# Python Main Module:  Entry point to the testbench tools in PoC repository.
# 
# Description:
# ------------------------------------
#    This is a python main module (executable) which:
#    - runs automated testbenches,
#    - ...
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

from lib.Functions import Exit
from Base.Exceptions import *
from Base.PoCBase import CommandLineProgram
from PoC.Entity import *
from PoC.Config import *
from Compiler import *
from Compiler.Exceptions import *


class NetList(CommandLineProgram):
	__netListConfigFileName = "configuration.ini"
	
	headLine = "The PoC Library - NetList Service Tool"
	
	dryRun = False
	netListConfig = None
	
	def __init__(self, debug, verbose, quiet):
		super(self.__class__, self).__init__(debug, verbose, quiet)

		if not ((self.platform == "Windows") or (self.platform == "Linux")):	raise PlatformNotSupportedException(self.platform)
		
		self.readNetListConfiguration()
		
	# read NetList configuration
	# ==========================================================================
	def readNetListConfiguration(self):
		from configparser import ConfigParser, ExtendedInterpolation
		
		self.files["PoCNLConfig"] = self.directories["PoCNetList"] / self.__netListConfigFileName
		netListConfigFilePath	= self.files["PoCNLConfig"]
		
		self.printDebug("Reading NetList configuration from '%s'" % str(netListConfigFilePath))
		if not netListConfigFilePath.exists():	raise NotConfiguredException("PoC netlist configuration file does not exist. (%s)" % str(netListConfigFilePath))
			
		self.netListConfig = ConfigParser(interpolation=ExtendedInterpolation())
		self.netListConfig.optionxform = str
		self.netListConfig.read([
			str(self.files['PoCPrivateConfig']),
			str(self.files['PoCPublicConfig']),
			str(self.files["PoCNLConfig"])
		])


	def coreGenCompilation(self, entity, showLogs, showReport, deviceString=None, boardString=None):
		# check if ISE is configure
		if (len(self.pocConfig.options("Xilinx-ISE")) == 0):	raise NotConfiguredException("Xilinx ISE is not configured on this system.")
		
		# prepare some paths
		self.directories["ISEInstallation"] = Path(self.pocConfig['Xilinx-ISE']['InstallationDirectory'])
		self.directories["ISEBinary"] =				Path(self.pocConfig['Xilinx-ISE']['BinaryDirectory'])
	
		# check if the appropriate environment is loaded
		from os import environ
		if (environ.get('XILINX') == None):	raise EnvironmentException("Xilinx ISE environment is not loaded in this shell environment. ")

		if (boardString is not None):
			device = Device(self.netListConfig['BOARDS'][boardString])
		elif (deviceString is not None):
			device = Device(deviceString)
		else: raise BaseException("No board or device given.")

		entityToCompile = Entity(self, entity)

		compiler = XCOCompiler.Compiler(self, showLogs, showReport)
		compiler.dryRun = self.dryRun
		compiler.run(entityToCompile, device)
		
	def xstCompilation(self, entity, showLogs, showReport, deviceString=None, boardString=None):
		# check if ISE is configure
		if (len(self.pocConfig.options("Xilinx-ISE")) == 0):
			raise NotConfiguredException("Xilinx ISE is not configured on this system.")
		
		# prepare some paths
		self.directories["ISEInstallation"] = Path(self.pocConfig['Xilinx-ISE']['InstallationDirectory'])
		self.directories["ISEBinary"] =				Path(self.pocConfig['Xilinx-ISE']['BinaryDirectory'])
	
		# check if the appropriate environment is loaded
		from os import environ
		if (environ.get('XILINX') == None):
			raise EnvironmentException("Xilinx ISE environment is not loaded in this shell environment. ")

		if (boardString is not None):
			device = Device(self.netListConfig['BOARDS'][boardString])
		elif (deviceString is not None):
			device = Device(deviceString)
		else: raise BaseException("No board or device given.")
		
		entityToCompile = Entity(self, entity)

		compiler = XSTCompiler.Compiler(self, showLogs, showReport)
		compiler.dryRun = self.dryRun
		compiler.run(entityToCompile, device)


# main program
def main():
	print("=" * 80)
	print("{: ^80s}".format("The PoC Library - NetList Service Tool"))
	print("=" * 80)
	print()
	
	try:
		import argparse
		import textwrap
		
		# create a command line argument parser
		argParser = argparse.ArgumentParser(
			formatter_class = argparse.RawDescriptionHelpFormatter,
			description = textwrap.dedent('''\
				This is the PoC Library NetList Service Tool.
				'''),
			add_help=False)

		# add arguments
		group1 = argParser.add_argument_group('Verbosity')
		group1.add_argument('-D', 																											help='enable script wrapper debug mode',	action='store_const', const=True, default=False)
		group1.add_argument('-d',																		dest="debug",				help='enable debug mode',									action='store_const', const=True, default=False)
		group1.add_argument('-v',																		dest="verbose",			help='print out detailed messages',				action='store_const', const=True, default=False)
		group1.add_argument('-q',																		dest="quiet",				help='run in quiet mode',									action='store_const', const=True, default=False)
		group1.add_argument('-r',																		dest="showReport",	help='show report',												action='store_const', const=True, default=False)
		group1.add_argument('-l',																		dest="showLog",			help='show logs',													action='store_const', const=True, default=False)
		group2 = argParser.add_argument_group('Commands')
		group21 = group2.add_mutually_exclusive_group(required=True)
		group21.add_argument('-h', '--help',												dest="help",				help='show this help message and exit',		action='store_const', const=True, default=False)
		group211 = group21.add_mutually_exclusive_group()
		group211.add_argument(		 '--coregen',	metavar="<Entity>",	dest="coreGen",			help='use Xilinx IP-Core Generator (CoreGen)')
		group211.add_argument(		 '--xst',			metavar="<Entity>",	dest="xst",					help='use Xilinx Compiler Tool (XST)')
		group3 = group211.add_argument_group('Specify target platform')
		group31 = group3.add_mutually_exclusive_group()
		group31.add_argument('--device',				metavar="<Device>",	dest="device",			help='target device (e.g. XC5VLX50T-1FF1136)')
		group31.add_argument('--board',					metavar="<Board>",	dest="board",				help='target board to infere the device (e.g. ML505)')

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

		
	try:
		netList = NetList(args.debug, args.verbose, args.quiet)
		#netList.dryRun = True
	
		if (args.help == True):
			argParser.print_help()
			return
		elif (args.coreGen is not None):
			netList.coreGenCompilation(args.coreGen, args.showLog, args.showReport, deviceString=args.device, boardString=args.board)
		elif (args.xst is not None):
			netList.xstCompilation(args.xst, args.showLog, args.showReport, deviceString=args.device, boardString=args.board)
		else:
			argParser.print_help()
		
	except CompilerException as ex:
		from colorama import Fore, Back, Style
		print(Fore.RED + "ERROR:" + Fore.RESET + " %s" % ex.message)
		if isinstance(ex.__cause__, FileNotFoundError):
			print(Fore.RED + "CAUSE:   FileNotFound: '%s'" % str(ex.__cause__))
		print()
		print(Fore.RESET + Back.RESET + Style.RESET_ALL)
		exit(1)
		
	except EnvironmentException as ex:					Exit.printEnvironmentException(ex)
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
	Exit.printThisIsNoLibraryFile(Netlist.headLine)
