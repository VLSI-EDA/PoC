# EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
# Authors:         			Patrick Lehmann
# 
# Python Main Module:		Entry point to the testbench tools in PoC repository.
# 
# Description:
# ------------------------------------
#    This is a python main module (executable) which:
#    - runs automated testbenches,
#    - ...
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
# distributed under the License is distributed on an "AS IS" BASIS,default
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================

from argparse									import RawDescriptionHelpFormatter
from configparser							import Error as ConfigParser_Error, NoOptionError, ConfigParser, ExtendedInterpolation
from os												import environ
from pathlib									import Path
from platform									import system as platform_system
from sys											import argv as sys_argv
from textwrap									import dedent

from Base.Exceptions					import ExceptionBase, EnvironmentException, PlatformNotSupportedException, NotConfiguredException, \
																			CommonException, SimulatorException
from Base.ToolChain import ToolChainException
from Base.Compiler						import CompilerException
from Base.Logging							import ILogable, Logger, Severity
from Base.Project							import VHDLVersion
from Base.Configuration				import ConfigurationException
from Compiler.XCOCompiler			import Compiler as XCOCompiler
from Compiler.XSTCompiler			import Compiler as XSTCompiler
from Parser.Parser						import ParserException
from PoC.Config								import Device, Board
from PoC.Entity								import Entity, FQN, EntityTypes
from PoC.Query								import Query
from Simulator.ActiveHDLSimulator		import Simulator as ActiveHDLSimulator
from Simulator.GHDLSimulator				import Simulator as GHDLSimulator
from Simulator.ISESimulator					import Simulator as ISESimulator
from Simulator.QuestaSimulator			import Simulator as QuestaSimulator
from Simulator.VivadoSimulator			import Simulator as VivadoSimulator
from ToolChains								import Configurations
from lib.ArgParseAttributes		import ArgParseMixin, CommandAttribute, CommonSwitchArgumentAttribute, CommandGroupAttribute, ArgumentAttribute, SwitchArgumentAttribute, DefaultAttribute
from lib.Functions						import Init, Exit


# def HandleVerbosityOptions(func):
# 	def func_wrapper(self, args):
# 		self.ConfigureSyslog(args.quiet, args.verbose, args.debug)
# 		return func(self, args)
# 	return func_wrapper

class PoC(ILogable, ArgParseMixin):
	HeadLine =								"The PoC-Library - Service Tool"

	# configure hard coded variables here
	__scriptDirectoryName = 			"py"
	__pocPrivateConfigFileName =	"config.private.ini"
	__pocPublicConfigFileName =		"config.public.ini"
	__pocBoardConfigFileName =		"config.boards.ini"

	__tbConfigFileName =					"configuration.ini"
	__netListConfigFileName =			"configuration.ini"

	# private fields
	__platform = platform_system()  # load platform information (Windows, Linux, ...)

	def __init__(self, debug, verbose, quiet, dryRun):
		# Call the constructor of ILogable
		# --------------------------------------------------------------------------
		if quiet:			severity = Severity.Quiet
		elif debug:		severity = Severity.Debug
		elif verbose:	severity = Severity.Verbose
		else:					severity = Severity.Normal

		logger = Logger(self, severity, printToStdOut=True)
		ILogable.__init__(self, logger=logger)

		# Do some basic checks
		# --------------------------------------------------------------------------
		if (self.Platform not in ["Windows", "Linux"]):		raise PlatformNotSupportedException(self.Platform)
		if (environ.get('PoCRootDirectory') is None):			raise EnvironmentException("Shell environment does not provide 'PoCRootDirectory' variable.")
		if (environ.get('PoCScriptDirectory') is None):		raise EnvironmentException("Shell environment does not provide 'PoCScriptDirectory' variable.")

		# Call the constructor of the ArgParseMixin
		# --------------------------------------------------------------------------
		description = dedent('''\
			This is the PoC-Library Service Tool.
			''')
		epilog = "Epidingsbums"
		ArgParseMixin.__init__(self, description=description, epilog=epilog, formatter_class=RawDescriptionHelpFormatter, add_help=False)

		# declare members
		# --------------------------------------------------------------------------
		self.__dryRun =				dryRun
		self.__pocConfig =		None
		self.__tbConfig =			None
		self.__nlConfig =			None
		self.__files =				{}
		self.__directories =	{}

		self.__SimulationDefaultVHDLVersion = VHDLVersion.VHDL08
		self.__SimulationDefaultBoard =				None

		self.Directories['Working'] =			Path.cwd()
		self.Directories['PoCRoot'] =			Path(environ.get('PoCRootDirectory'))
		self.Directories['ScriptRoot'] =	Path(environ.get('PoCRootDirectory'))
		self.Files['PoCPrivateConfig'] =	self.Directories["PoCRoot"] / self.__scriptDirectoryName / self.__pocPrivateConfigFileName
		self.Files['PoCPublicConfig'] =		self.Directories["PoCRoot"] / self.__scriptDirectoryName / self.__pocPublicConfigFileName
		self.Files['PoCBoardConfig'] =		self.Directories["PoCRoot"] / self.__scriptDirectoryName / self.__pocBoardConfigFileName

	# class properties
	# ============================================================================
	@property
	def Platform(self):
		return self.__platform

	@property
	def DryRun(self):
		return self.__dryRun

	@property
	def Directories(self):
		return self.__directories

	@property
	def Files(self):
		return self.__files

	@property
	def PoCConfig(self):
		return self.__pocConfig

	@property
	def TBConfig(self):
		return self.__tbConfig

	@property
	def NLConfig(self):
		return self.__nlConfig


	# read PoC configuration
	# ============================================================================
	def __ReadPoCConfiguration(self):
		pocPrivateConfigFilePath =	self.Files['PoCPrivateConfig']
		pocPublicConfigFilePath =		self.Files['PoCPublicConfig']
		pocBoardConfigFilePath =		self.Files['PoCBoardConfig']

		self._LogDebug("Reading PoC configuration from\n  '{0}'\n  '{1}\n  '{2}'".format(str(pocPrivateConfigFilePath), str(pocPublicConfigFilePath), str(pocBoardConfigFilePath)))
		if not pocPrivateConfigFilePath.exists():	raise NotConfiguredException("PoC's private configuration file '{0}' does not exist.".format(str(pocPrivateConfigFilePath)))	from FileNotFoundError(str(pocPrivateConfigFilePath))
		if not pocPublicConfigFilePath.exists():	raise NotConfiguredException("PoC' public configuration file '{0}' does not exist.".format(str(pocPublicConfigFilePath)))			from FileNotFoundError(str(pocPublicConfigFilePath))
		if not pocBoardConfigFilePath.exists():		raise NotConfiguredException("PoC's board configuration file '{0}' does not exist.".format(str(pocBoardConfigFilePath)))			from FileNotFoundError(str(pocBoardConfigFilePath))

		# read PoC configuration
		# ============================================================================
		self.__pocConfig = ConfigParser(interpolation=ExtendedInterpolation())
		self.__pocConfig.optionxform = str
		self.__pocConfig.read([
			str(pocPrivateConfigFilePath),
			str(pocPublicConfigFilePath),
			str(pocBoardConfigFilePath)
		])

		# check PoC installation directory
		if (self.Directories["PoCRoot"] != Path(self.PoCConfig['PoC']['InstallationDirectory'])):	raise NotConfiguredException("There is a mismatch between PoCRoot and PoC installation directory.")

		self.__SimulationDefaultBoard =				Board(self)

		# self.Directories["XSTFiles"] =			self.Directories["PoCRoot"] / self.PoCConfig['PoC.DirectoryNames']['ISESynthesisFiles']
		# #self.Directories["QuartusFiles"] =	self.Directories["PoCRoot"] / self.PoCConfig['PoC.DirectoryNames']['QuartusSynthesisFiles']

		# self.Directories["CoreGenTemp"] =		self.Directories["PoCTemp"] / self.PoCConfig['PoC.DirectoryNames']['ISECoreGeneratorFiles']
		# self.Directories["XSTTemp"] =				self.Directories["PoCTemp"] / self.PoCConfig['PoC.DirectoryNames']['ISESynthesisFiles']
		# #self.Directories["QuartusTemp"] =	self.Directories["PoCTemp"] / self.PoCConfig['PoC.DirectoryNames']['QuartusSynthesisFiles']

	# read Testbench configuration
	# ==========================================================================
	def __ReadTestbenchConfiguration(self):
		self.Files["PoCTBConfig"] = tbConfigFilePath = self.Directories["PoCTestbench"] / self.__tbConfigFileName

		self._LogDebug("Reading testbench configuration from '{0}'".format(str(tbConfigFilePath)))
		if not tbConfigFilePath.exists():	raise NotConfiguredException("PoC testbench configuration file does not exist. ({0})".format(str(tbConfigFilePath)))

		self.__tbConfig = ConfigParser(interpolation=ExtendedInterpolation())
		self.__tbConfig.optionxform = str
		self.__tbConfig.read([
			str(self.Files["PoCPrivateConfig"]),
			str(self.Files["PoCPublicConfig"]),
			str(self.Files["PoCTBConfig"])
		])

	# read NetList configuration
	# ==========================================================================

	def __ReadNetlistConfiguration(self):
		self.Files["PoCNLConfig"] = netListConfigFilePath	= self.Directories["PoCNetList"] / self.__netListConfigFileName

		self._LogDebug("Reading NetList configuration from '{0}'".format(str(netListConfigFilePath)))
		if not netListConfigFilePath.exists():	raise NotConfiguredException("PoC netlist configuration file does not exist. ({0})".format(str(netListConfigFilePath)))

		self.__nlConfig = ConfigParser(interpolation=ExtendedInterpolation())
		self.__nlConfig.optionxform = str
		self.__nlConfig.read([
			str(self.Files['PoCPrivateConfig']),
			str(self.Files['PoCPublicConfig']),
			str(self.Files["PoCNLConfig"])
		])

	def __CleanupPoCConfiguration(self):
		# remove non-private sections from pocConfig
		sections = self.PoCConfig.sections()
		for privateSection in self.__privateSections:
			sections.remove(privateSection)
		for section in sections:
			self.PoCConfig.remove_section(section)

		# remove non-private options from [PoC] section
		pocOptions = self.PoCConfig.options("PoC")
		for privatePoCOption in self.__privatePoCOptions:
			pocOptions.remove(privatePoCOption)
		for pocOption in pocOptions:
			self.PoCConfig.remove_option("PoC", pocOption)

	def __WritePoCConfiguration(self):
		# self.__CleanupPoCConfiguration()

		# Writing configuration to disc
		self._LogNormal("Writing configuration file to '{0}'".format(str(self.Files['PoCPrivateConfig'])))
		with self.Files['PoCPrivateConfig'].open('w') as configFileHandle:
			self.PoCConfig.write(configFileHandle)

	def __PrepareForConfiguration(self):
		self.__ReadPoCConfiguration()

	def __PrepareForSimulation(self):
		self.__ReadPoCConfiguration()

		# parsing values into class fields
		self.Directories["PoCSource"] =			self.Directories["PoCRoot"] / self.PoCConfig['PoC.DirectoryNames']['HDLSourceFiles']
		self.Directories["PoCTestbench"] =	self.Directories["PoCRoot"] / self.PoCConfig['PoC.DirectoryNames']['TestbenchFiles']
		self.Directories["PoCTemp"] =				self.Directories["PoCRoot"] / self.PoCConfig['PoC.DirectoryNames']['TemporaryFiles']
		self.__ReadTestbenchConfiguration()

	def __PrepareForSynthesis(self):
		self.__ReadPoCConfiguration()

		# parsing values into class fields
		self.Directories["PoCSource"] =			self.Directories["PoCRoot"] / self.PoCConfig['PoC.DirectoryNames']['HDLSourceFiles']
		self.Directories["PoCNetList"] =		self.Directories["PoCRoot"] / self.PoCConfig['PoC.DirectoryNames']['NetListFiles']
		self.Directories["PoCTemp"] =				self.Directories["PoCRoot"] / self.PoCConfig['PoC.DirectoryNames']['TemporaryFiles']
		self.__ReadNetlistConfiguration()


	# ============================================================================
	# Common commands
	# ============================================================================
	# common arguments valid for all commands
	# ----------------------------------------------------------------------------
	@CommonSwitchArgumentAttribute("-D",							dest="DEBUG",		help="enable script wrapper debug mode")
	@CommonSwitchArgumentAttribute("-d", "--debug",		dest="debug",		help="enable debug mode")
	@CommonSwitchArgumentAttribute("-v", "--verbose",	dest="verbose",	help="print out detailed messages")
	@CommonSwitchArgumentAttribute("-q", "--quiet",		dest="quiet",		help="reduce messages to a minimum")
	def Run(self):
		ArgParseMixin.Run(self)

	def PrintHeadline(self):
		# self._LogNormal(Foreground.MAGENTA + "=" * 80)
		self._LogNormal("{HEADLINE}{line}{RESET}".format(line="="*80, **Init.Foreground))
		self._LogNormal("{HEADLINE}{headline: ^80s}{RESET}".format(headline=self.HeadLine, **Init.Foreground))
		self._LogNormal("{HEADLINE}{line}{RESET}".format(line="="*80, **Init.Foreground))

	# ----------------------------------------------------------------------------
	# fallback handler if no command was recognized
	# ----------------------------------------------------------------------------
	@DefaultAttribute()
	# @HandleVerbosityOptions
	def HandleDefault(self, args):
		self.PrintHeadline()

		# print("Common arguments:")
		# for funcname,func in CommonArgumentAttribute.GetMethods(self):
		# 	for comAttribute in CommonArgumentAttribute.GetAttributes(func):
		# 		print("  {0}  {1}".format(comAttribute.Args, comAttribute.KWArgs['help']))
		#
		# 		self.__mainParser.add_argument(*(comAttribute.Args), **(comAttribute.KWArgs))
		#
		# for funcname,func in CommonSwitchArgumentAttribute.GetMethods(self):
		# 	for comAttribute in CommonSwitchArgumentAttribute.GetAttributes(func):
		# 		print("  {0}  {1}".format(comAttribute.Args, comAttribute.KWArgs['help']))

		self.MainParser.print_help()
		Exit.exit()

	# ----------------------------------------------------------------------------
	# create the sub-parser for the "help" command
	# ----------------------------------------------------------------------------
	@CommandAttribute('help', help="help help")
	@ArgumentAttribute(metavar='<Command>', dest="Command", type=str, nargs='?', help='todo help')
	# @HandleVerbosityOptions
	def HandleHelp(self, args):
		self.PrintHeadline()
		if (args.Command is None):
			self.MainParser.print_help()
			Exit.exit()
		elif (args.Command == "help"):
			print("This is a recursion ...")
		else:
			self.SubParsers[args.Command].print_help()
		Exit.exit()

	# ============================================================================
	# Configuration commands
	# ============================================================================
	# create the sub-parser for the "configure" command
	# ----------------------------------------------------------------------------
	@CommandGroupAttribute("Configuration commands")
	@CommandAttribute("configure", help="Configure vendor tools for PoC.")
	# @HandleVerbosityOptions
	def HandleManualConfiguration(self, args):
		self.__Prepare()
		self.PrintHeadline()

		self._LogVerbose("starting manual configuration...")
		print('Explanation of abbreviations:')
		print('  y - yes')
		print('  n - no')
		print('  p - pass (jump to next question)')
		#print('Upper case means default value')
		print()

		if (self.Platform == 'Windows'):			self._manualConfigurationForWindows()
		elif (self.Platform == 'Linux'):			self._manualConfigurationForLinux()
		else:																	raise PlatformNotSupportedException(self.Platform)

		# write configuration
		self.__WritePoCConfiguration()
		# re-read configuration
		self.__ReadPoCConfiguration()

	def _manualConfigurationForWindows(self):
		for conf in Configurations:
			configurator = conf()
			self._LogNormal("Configure {0} - {1}".format(configurator.Name, conf))

			next = False
			while (next == False):
				try:
					configurator.ConfigureForWindows()
					next = True
				except BaseException as ex:
					print("FAULT: {0}".format(ex.message))
			# end while

	def _manualConfigurationForLinux(self):
		for conf in Configurations:
			configurator = conf()
			self._LogNormal("Configure {0}".format(configurator.Name))

			next = False
			while (next == False):
				try:
					configurator.ConfigureForLinux()
					next = True
				except BaseException as ex:
					print("FAULT: {0}".format(ex.message))
			# end while

	# ----------------------------------------------------------------------------
	# create the sub-parser for the "query" command
	# ----------------------------------------------------------------------------
	@CommandGroupAttribute("Configuration commands")
	@CommandAttribute("query", help="Simulate a PoC Entity with Aldec Active-HDL")
	@ArgumentAttribute(metavar="<Query>", dest="Query", type=str, help="todo help")
	# @HandleVerbosityOptions
	def HandleQueryConfiguration(self, args):
		self.__PrepareForConfiguration()
		query = Query(self)
		result = query.QueryConfiguration(args.Query)
		print(result)
		Exit.exit()


	# ============================================================================
	# Simulation	commands
	# ============================================================================
	def __PrepareVendorLibraryPaths(self):
		# prepare vendor library path for Altera
		if (len(self.PoCConfig.options("Altera.QuartusII")) != 0):
			self.Directories["AlteraPrimitiveSource"] = Path(self.PoCConfig['Altera.QuartusII']['InstallationDirectory']) / "eda/sim_lib"
		# prepare vendor library path for Xilinx
		if (len(self.PoCConfig.options("Xilinx.ISE")) != 0):
			self.Directories["XilinxPrimitiveSource"] = Path(self.PoCConfig['Xilinx.ISE']['InstallationDirectory']) / "ISE/vhdl/src"
		elif (len(self.PoCConfig.options("Xilinx.Vivado")) != 0):
			self.Directories["XilinxPrimitiveSource"] = Path(self.PoCConfig['Xilinx.Vivado']['InstallationDirectory']) / "data/vhdl/src"


	# ----------------------------------------------------------------------------
	# create the sub-parser for the "list-testbench" command
	# ----------------------------------------------------------------------------
	@CommandGroupAttribute("Simulation commands")
	@CommandAttribute("list-testbench", help="List all testbenches")
	@ArgumentAttribute(metavar="<PoC Entity>", dest="FQN", type=str, nargs='+', help="todo help")
	# @HandleVerbosityOptions
	def HandleListTestbenches(self, args):
		self.__PrepareForSimulation()
		self.PrintHeadline()

		if (len(args.FQN) == 0):              raise SimulatorException("No FQN given.")

		fqnList = [FQN(self, fqn, defaultType=EntityTypes.Testbench) for fqn in args.FQN]

		# run a testbench
		for fqn in fqnList:
			for entity in fqn.GetEntities():
				print(entity)

		Exit.exit()

	# ----------------------------------------------------------------------------
	# create the sub-parser for the "asim" command
	# ----------------------------------------------------------------------------
	@CommandGroupAttribute("Simulation commands")
	@CommandAttribute("asim", help="Simulate a PoC Entity with Aldec Active-HDL")
	@ArgumentAttribute(metavar="<PoC Entity>", dest="FQN", type=str, nargs='+', help="todo help")
	@ArgumentAttribute('--device', metavar="<DeviceName>", dest="DeviceName", help="todo")
	@ArgumentAttribute('--board', metavar="<BoardName>", dest="BoardName", help="todo")
	@SwitchArgumentAttribute("-l", dest="logs", help="show logs")
	@SwitchArgumentAttribute("-r", dest="reports", help="show reports")
	@ArgumentAttribute('--std', metavar="<VHDLVersion>", dest="VHDLVersion", help="Simulate with VHDL-??")
	# @SwitchArgumentAttribute("-08", dest="VHDLVersion", help="Simulate with VHDL-2008.")
	@SwitchArgumentAttribute("-g", "--gui", dest="GUIMode", help="show waveform in a GUI window.")
	# @HandleVerbosityOptions
	def HandleActiveHDLSimulation(self, args):
		self.__PrepareForSimulation()
		self.PrintHeadline()

		# check if Aldec tools are configure
		if (len(self.PoCConfig.options("Aldec.ActiveHDL")) != 0):
			precompiledDirectory =											self.PoCConfig['PoC.DirectoryNames']['PrecompiledFiles']
			activeHDLSimulatorFiles =										self.PoCConfig['PoC.DirectoryNames']['ActiveHDLSimulatorFiles']
			self.Directories["ActiveHDLTemp"] =					self.Directories["PoCTemp"] / activeHDLSimulatorFiles
			self.Directories["ActiveHDLPrecompiled"] =	self.Directories["PoCTemp"] / precompiledDirectory / activeHDLSimulatorFiles
			self.Directories["ActiveHDLInstallation"] =	Path(self.PoCConfig['Aldec.ActiveHDL']['InstallationDirectory'])
			self.Directories["ActiveHDLBinary"] =				Path(self.PoCConfig['Aldec.ActiveHDL']['BinaryDirectory'])
			aSimVersion =																self.PoCConfig['Aldec.ActiveHDL']['Version']
		elif (len(self.PoCConfig.options("Lattice.ActiveHDL")) != 0):
			precompiledDirectory =											self.PoCConfig['PoC.DirectoryNames']['PrecompiledFiles']
			activeHDLSimulatorFiles =										self.PoCConfig['PoC.DirectoryNames']['ActiveHDLSimulatorFiles']
			self.Directories["ActiveHDLTemp"] =					self.Directories["PoCTemp"] / activeHDLSimulatorFiles
			self.Directories["ActiveHDLPrecompiled"] =	self.Directories["PoCTemp"] / precompiledDirectory / activeHDLSimulatorFiles
			self.Directories["ActiveHDLInstallation"] =	Path(self.PoCConfig['Lattice.ActiveHDL']['InstallationDirectory'])
			self.Directories["ActiveHDLBinary"] =				Path(self.PoCConfig['Lattice.ActiveHDL']['BinaryDirectory'])
			aSimVersion =																self.PoCConfig['Lattice.ActiveHDL']['Version']
		# elif (len(self.PoCConfig.options("Aldec.RivieraPRO")) != 0):
		# self.Directories["ActiveHDLInstallation"] =	Path(self.PoCConfig['Aldec.RivieraPRO']['InstallationDirectory'])
		# self.Directories["ActiveHDLBinary"] =				Path(self.PoCConfig['Aldec.RivieraPRO']['BinaryDirectory'])
		# aSimVersion =																self.PoCConfig['Aldec.RivieraPRO']['Version']
		else:
			# raise NotConfiguredException("Neither Aldec's Active-HDL nor Riviera PRO nor Active-HDL Lattice Edition are configured on this system.")
			raise NotConfiguredException("Neither Aldec's Active-HDL nor Active-HDL Lattice Edition are configured on this system.")

		if (len(args.FQN) == 0):              raise SimulatorException("No FQN given.")

		if (args.BoardName is not None):
			board = Board(self, args.BoardName)
		elif (args.DeviceName is not None):
			board = Board(self, "Custom", args.DeviceName)
		else:
			board = self.__SimulationDefaultBoard

		if (args.VHDLVersion is None):
			vhdlVersion = self.__SimulationDefaultVHDLVersion
		else:
			vhdlVersion = VHDLVersion.parse(args.VHDLVersion)

		# prepare some paths
		binaryPath = self.Directories["ActiveHDLBinary"]

		# prepare paths to vendor simulation libraries
		self.__PrepareVendorLibraryPaths()

		# create a GHDLSimulator instance and prepare it
		simulator = ActiveHDLSimulator(self, args.logs, args.reports, args.GUIMode)
		simulator.PrepareSimulator(binaryPath, aSimVersion)

		fqnList = [FQN(self, fqn, defaultType=EntityTypes.Testbench) for fqn in args.FQN]

		# run a testbench
		for fqn in fqnList:
			for entity in fqn.GetEntities():
				# try:
				simulator.Run(entity, board=board, vhdlVersion=vhdlVersion)  # , vhdlGenerics=None)
				# except SimulatorException as ex:
					# pass

		Exit.exit()


	# ----------------------------------------------------------------------------
	# create the sub-parser for the "ghdl" command
	# ----------------------------------------------------------------------------
	@CommandGroupAttribute("Simulation commands")
	@CommandAttribute("ghdl", help="Simulate a PoC Entity with GHDL")
	@ArgumentAttribute(metavar="<PoC Entity>", dest="FQN", type=str, nargs='+', help="todo help")
	@ArgumentAttribute('--device', metavar="<DeviceName>", dest="DeviceName", help="todo")
	@ArgumentAttribute('--board', metavar="<BoardName>", dest="BoardName", help="todo")
	@SwitchArgumentAttribute("-l", dest="logs", help="show logs")
	@SwitchArgumentAttribute("-r", dest="reports", help="show reports")
	@ArgumentAttribute('--std', metavar="<VHDLVersion>", dest="VHDLVersion", help="Simulate with VHDL-??")
	# @SwitchArgumentAttribute("-08", dest="VHDLVersion", help="Simulate with VHDL-2008.")
	@SwitchArgumentAttribute("-g", "--gui", dest="GUIMode", help="show waveform in GTKWave.")
	# standard
	# @HandleVerbosityOptions
	def HandleGHDLSimulation(self, args):
		self.__PrepareForSimulation()
		self.PrintHeadline()

		# check if GHDL is configure
		if (len(self.PoCConfig.options("GHDL")) == 0):  raise NotConfiguredException("GHDL is not configured on this system.")

		if (len(args.FQN) == 0):							raise SimulatorException("No FQN given.")

		if (args.BoardName is not None):			board =		Board(self, args.BoardName)
		elif (args.DeviceName is not None):		board =		Board(self, "Custom", args.DeviceName)
		else:																	board =		self.__SimulationDefaultBoard

		if (args.VHDLVersion is None):				vhdlVersion = self.__SimulationDefaultVHDLVersion
		else:																	vhdlVersion = VHDLVersion.parse(args.VHDLVersion)

		# prepare some paths
		self.Directories["GHDLTemp"] =					self.Directories["PoCTemp"] / self.PoCConfig['PoC.DirectoryNames']['GHDLSimulatorFiles']
		self.Directories["GHDLPrecompiled"] =		self.Directories["PoCTemp"] / self.PoCConfig['PoC.DirectoryNames']['PrecompiledFiles'] / self.PoCConfig['PoC.DirectoryNames']['GHDLSimulatorFiles']
		self.Directories["GHDLInstallation"] =	Path(self.PoCConfig['GHDL']['InstallationDirectory'])
		self.Directories["GHDLBinary"] =				Path(self.PoCConfig['GHDL']['BinaryDirectory'])
		ghdlBinaryPath =												self.Directories["GHDLBinary"]
		ghdlVersion =														self.PoCConfig['GHDL']['Version']
		ghdlBackend =														self.PoCConfig['GHDL']['Backend']

		# prepare paths to vendor simulation libraries
		self.__PrepareVendorLibraryPaths()

		# create a GHDLSimulator instance and prepare it
		simulator = GHDLSimulator(self, args.logs, args.reports, args.GUIMode)
		simulator.PrepareSimulator(ghdlBinaryPath, ghdlVersion, ghdlBackend)

		fqnList = [FQN(self, fqn, defaultType=EntityTypes.Testbench) for fqn in args.FQN]

		# run a testbench
		for fqn in fqnList:
			for entity in fqn.GetEntities():
				try:
					simulator.Run(entity, board=board, vhdlVersion=vhdlVersion)		#, vhdlGenerics=None)

					if (args.GUIMode == True):
						# prepare paths for GTKWave, if configured
						if (len(self.PoCConfig.options("GTKWave")) != 0):
							self.Directories["GTKWInstallation"] = Path(self.PoCConfig['GTKWave']['InstallationDirectory'])
							self.Directories["GTKWBinary"] = Path(self.PoCConfig['GTKWave']['BinaryDirectory'])
						else:
							raise NotConfiguredException("No GHDL compatible waveform viewer is configured on this system.")

						viewer = simulator.GetViewer()
						viewer.View(entity)

				except SimulatorException as ex:
					pass

		Exit.exit()

	# ----------------------------------------------------------------------------
	# create the sub-parser for the "isim" command
	# ----------------------------------------------------------------------------
	@CommandGroupAttribute("Simulation commands")
	@CommandAttribute("isim", help="Simulate a PoC Entity with Xilinx ISE Simulator (iSim)")
	@ArgumentAttribute(metavar="<PoC Entity>", dest="FQN", type=str, nargs='+', help="todo help")
	@ArgumentAttribute('--device', metavar="<DeviceName>", dest="DeviceName", help="todo")
	@ArgumentAttribute('--board', metavar="<BoardName>", dest="BoardName", help="todo")
	@SwitchArgumentAttribute("-l", dest="logs", help="show logs")
	@SwitchArgumentAttribute("-r", dest="reports", help="show reports")
	@SwitchArgumentAttribute("-g", "--gui", dest="GUIMode", help="show waveform in a GUI window.")
	# standard
	# @HandleVerbosityOptions
	def HandleISESimulation(self, args):
		self.__PrepareForSimulation()
		self.PrintHeadline()

		# check if ISE is configure
		if (len(self.PoCConfig.options("Xilinx.ISE")) == 0):	raise NotConfiguredException("Xilinx ISE is not configured on this system.")
		if (environ.get('XILINX') is None):										raise EnvironmentException("Xilinx ISE environment is not loaded in this shell environment.")

		if (len(args.FQN) == 0):              raise SimulatorException("No FQN given.")

		if (args.BoardName is not None):			board = Board(self, args.BoardName)
		elif (args.DeviceName is not None):		board = Board(self, "Custom", args.DeviceName)
		else:																	board = self.__SimulationDefaultBoard

		# prepare some paths
		iseSimulatorFiles =													self.PoCConfig['PoC.DirectoryNames']['ISESimulatorFiles']
		precompiledDirectory =											self.PoCConfig['PoC.DirectoryNames']['PrecompiledFiles']
		self.Directories["iSimTemp"] =							self.Directories["PoCTemp"] / iseSimulatorFiles
		self.Directories["iSimPrecompiled"] =				self.Directories["PoCTemp"] / precompiledDirectory / iseSimulatorFiles
		self.Directories["ISEInstallation"] =				Path(self.PoCConfig['Xilinx.ISE']['InstallationDirectory'])
		self.Directories["ISEBinary"] =							Path(self.PoCConfig['Xilinx.ISE']['BinaryDirectory'])
		self.Directories["XilinxPrimitiveSource"] =	Path(self.PoCConfig['Xilinx.ISE']['InstallationDirectory']) / "data/vhdl/src"
		iseVersion =																self.PoCConfig['Xilinx.ISE']['Version']
		binaryPath =																self.Directories["ISEBinary"]

		# prepare paths to vendor simulation libraries
		self.__PrepareVendorLibraryPaths()

		# create a GHDLSimulator instance and prepare it
		simulator = ISESimulator(self, args.logs, args.reports, args.GUIMode)
		simulator.PrepareSimulator(binaryPath, iseVersion)

		fqnList = [FQN(self, fqn, defaultType=EntityTypes.Testbench) for fqn in args.FQN]

		# run a testbench
		for fqn in fqnList:
			for entity in fqn.GetEntities():
				# try:
				simulator.Run(entity, board=board)		#, vhdlGenerics=None)

		Exit.exit()


	# ----------------------------------------------------------------------------
	# create the sub-parser for the "vsim" command
	# ----------------------------------------------------------------------------
	@CommandGroupAttribute("Simulation commands")
	@CommandAttribute("vsim", help="Simulate a PoC Entity with Mentor QuestaSim or ModelSim (vsim)")
	@ArgumentAttribute(metavar="<PoC Entity>", dest="FQN", type=str, nargs='+', help="todo help")
	@ArgumentAttribute('--device', metavar="<DeviceName>", dest="DeviceName", help="todo")
	@ArgumentAttribute('--board', metavar="<BoardName>", dest="BoardName", help="todo")
	@SwitchArgumentAttribute("-l", dest="logs", help="show logs")
	@SwitchArgumentAttribute("-r", dest="reports", help="show reports")
	@ArgumentAttribute('--std', metavar="<VHDLVersion>", dest="VHDLVersion", help="Simulate with VHDL-??")
	# @SwitchArgumentAttribute("-08", dest="VHDLVersion", help="Simulate with VHDL-2008.")
	@SwitchArgumentAttribute("-g", "--gui", dest="GUIMode", help="show waveform in a GUI window.")
	# standard
	# @HandleVerbosityOptions
	def HandleQuestaSimulation(self, args):
		self.__PrepareForSimulation()
		self.PrintHeadline()

		# check if QuestaSim is configured
		if (len(self.PoCConfig.options("Mentor.QuestaSim")) != 0):
			precompiledDirectory =									self.PoCConfig['PoC.DirectoryNames']['PrecompiledFiles']
			vSimSimulatorFiles =										self.PoCConfig['PoC.DirectoryNames']['ActiveHDLSimulatorFiles']
			self.Directories["vSimTemp"] =					self.Directories["PoCTemp"] / vSimSimulatorFiles
			self.Directories["vSimPrecompiled"] =		self.Directories["PoCTemp"] / precompiledDirectory / vSimSimulatorFiles
			self.Directories["vSimInstallation"] =	Path(self.PoCConfig['Mentor.QuestaSim']['InstallationDirectory'])
			self.Directories["vSimBinary"] =				Path(self.PoCConfig['Mentor.QuestaSim']['BinaryDirectory'])
			binaryPath =														self.Directories["vSimBinary"]
			vSimVersion =														self.PoCConfig['Mentor.QuestaSim']['Version']
		elif (len(self.PoCConfig.options("Altera.ModelSim")) != 0):
			precompiledDirectory =									self.PoCConfig['PoC.DirectoryNames']['PrecompiledFiles']
			vSimSimulatorFiles =										self.PoCConfig['PoC.DirectoryNames']['ActiveHDLSimulatorFiles']
			self.Directories["vSimTemp"] =					self.Directories["PoCTemp"] / vSimSimulatorFiles
			self.Directories["vSimPrecompiled"] =		self.Directories["PoCTemp"] / precompiledDirectory / vSimSimulatorFiles
			self.Directories["vSimInstallation"] =	Path(self.PoCConfig['Altera.ModelSim']['InstallationDirectory'])
			self.Directories["vSimBinary"] =				Path(self.PoCConfig['Altera.ModelSim']['BinaryDirectory'])
			binaryPath =														self.Directories["vSimBinary"]
			vSimVersion =														self.PoCConfig['Altera.ModelSim']['Version']
		else:
			raise NotConfiguredException("Neither Mentor Graphics QuestaSim nor ModelSim Altera-Edition are configured on this system.")

		if (len(args.FQN) == 0):              raise SimulatorException("No FQN given.")

		if (args.BoardName is not None):			board = Board(self, args.BoardName)
		elif (args.DeviceName is not None):		board = Board(self, "Custom", args.DeviceName)
		else:																	board = self.__SimulationDefaultBoard

		if (args.VHDLVersion is None):				vhdlVersion = self.__SimulationDefaultVHDLVersion
		else:																	vhdlVersion = VHDLVersion.parse(args.VHDLVersion)

		# prepare paths to vendor simulation libraries
		self.__PrepareVendorLibraryPaths()

		# create a GHDLSimulator instance and prepare it
		simulator = QuestaSimulator(self, args.logs, args.reports, args.GUIMode)
		simulator.PrepareSimulator(binaryPath, vSimVersion)

		fqnList = [FQN(self, fqn, defaultType=EntityTypes.Testbench) for fqn in args.FQN]

		# run a testbench
		for fqn in fqnList:
			print(fqn)
			for entity in fqn.GetEntities():
				# try:
				simulator.Run(entity, board=board, vhdlVersion=vhdlVersion)  # , vhdlGenerics=None)

		Exit.exit()


	# ----------------------------------------------------------------------------
	# create the sub-parser for the "asim" command
	# ----------------------------------------------------------------------------
	@CommandGroupAttribute("Simulation commands")
	@CommandAttribute("xsim", help="Simulate a PoC Entity with Xilinx Vivado Simulator (xSim)")
	@ArgumentAttribute(metavar="<PoC Entity>", dest="FQN", type=str, nargs='+', help="todo help")
	@ArgumentAttribute('--device', metavar="<DeviceName>", dest="DeviceName", help="todo")
	@ArgumentAttribute('--board', metavar="<BoardName>", dest="BoardName", help="todo")
	@SwitchArgumentAttribute("-l", dest="logs", help="show logs")
	@SwitchArgumentAttribute("-r", dest="reports", help="show reports")
	@ArgumentAttribute('--std', metavar="<VHDLVersion>", dest="VHDLVersion", help="Simulate with VHDL-??")
	# @SwitchArgumentAttribute("-08", dest="VHDLVersion", help="Simulate with VHDL-2008.")
	@SwitchArgumentAttribute("-g", "--gui", dest="GUIMode", help="show waveform in a GUI window.")
	# standard
	# @HandleVerbosityOptions
	def HandleVivadoSimulation(self, args):
		self.__PrepareForSimulation()
		self.PrintHeadline()

		# check if ISE is configure
		if (len(self.PoCConfig.options("Xilinx.Vivado")) == 0):  raise NotConfiguredException("Xilinx Vivado is not configured on this system.")
		if (environ.get('XILINX') is None):												raise EnvironmentException("Xilinx Vivado environment is not loaded in this shell environment.")

		if (len(args.FQN) == 0):              raise SimulatorException("No FQN given.")

		if (args.BoardName is not None):
			board = Board(self, args.BoardName)
		elif (args.DeviceName is not None):
			board = Board(self, "Custom", args.DeviceName)
		else:
			board = self.__SimulationDefaultBoard

		if (args.VHDLVersion is None):
			vhdlVersion = VHDLVersion.VHDL93	# self.__SimulationDefaultVHDLVersion		# TODO: VHDL-2008 is broken in Vivado 2015.4 -> use VHDL-93 by default
		else:
			vhdlVersion = VHDLVersion.parse(args.VHDLVersion)

		# prepare some paths
		vivadoSimulatorFiles =											self.PoCConfig['PoC.DirectoryNames']['VivadoSimulatorFiles']
		precompiledDirectory =											self.PoCConfig['PoC.DirectoryNames']['PrecompiledFiles']
		self.Directories["xSimTemp"] =							self.Directories["PoCTemp"] / vivadoSimulatorFiles
		self.Directories["xSimPrecompiled"] =				self.Directories["PoCTemp"] / precompiledDirectory / vivadoSimulatorFiles
		self.Directories["VivadoInstallation"] =		Path(self.PoCConfig['Xilinx.Vivado']['InstallationDirectory'])
		self.Directories["VivadoBinary"] =					Path(self.PoCConfig['Xilinx.Vivado']['BinaryDirectory'])
		self.Directories["XilinxPrimitiveSource"] =	Path(self.PoCConfig['Xilinx.Vivado']['InstallationDirectory']) / "data/vhdl/src"
		vivadoVersion =															self.PoCConfig['Xilinx.Vivado']['Version']
		binaryPath =																self.Directories["VivadoBinary"]

		# prepare paths to vendor simulation libraries
		self.__PrepareVendorLibraryPaths()

		# create a GHDLSimulator instance and prepare it
		simulator = VivadoSimulator(self, args.logs, args.reports, args.GUIMode)
		simulator.PrepareSimulator(binaryPath, vivadoVersion)

		fqnList = [FQN(self, fqn, defaultType=EntityTypes.Testbench) for fqn in args.FQN]

		# run a testbench
		for fqn in fqnList:
			print(fqn)
			for entity in fqn.GetEntities():
				# try:
				simulator.Run(entity, board=board, vhdlVersion=vhdlVersion)  # , vhdlGenerics=None)

		Exit.exit()


	# ============================================================================
	# Synthesis	commands
	# ============================================================================
	# create the sub-parser for the "list-netlist" command
	# ----------------------------------------------------------------------------
	@CommandGroupAttribute("Simulation commands")
	@CommandAttribute("list-netlist", help="List all netlists")
	@ArgumentAttribute(metavar="<PoC Entity>", dest="FQN", type=str, nargs='+', help="todo help")
	# @HandleVerbosityOptions
	def HandleListNetlist(self, args):
		self.__PrepareForSynthesis()
		self.PrintHeadline()

		if (len(args.FQN) == 0):              raise SimulatorException("No FQN given.")

		fqnList = [FQN(self, fqn, defaultType=EntityTypes.NetList) for fqn in args.FQN]

		# run a testbench
		for fqn in fqnList:
			for entity in fqn.GetEntities():
				print(entity)

		Exit.exit()

	# ----------------------------------------------------------------------------
	# create the sub-parser for the "coregen" command
	# ----------------------------------------------------------------------------
	@CommandGroupAttribute("Synthesis commands")
	@CommandAttribute("coregen", help="Generate an IP core with Xilinx ISE Core Generator")
	@ArgumentAttribute(metavar="<PoC Entity>", dest="FQN", type=str, nargs='+', help="todo help")
	@ArgumentAttribute('--device', metavar="<DeviceName>", dest="DeviceName", help="todo")
	@ArgumentAttribute('--board', metavar="<BoardName>", dest="BoardName", help="todo")
	@SwitchArgumentAttribute("-l", dest="logs", help="show logs")
	@SwitchArgumentAttribute("-r", dest="reports", help="show reports")
	# @HandleVerbosityOptions
	def HandleCoreGeneratorCompilation(self, args):
		self.__PrepareForSynthesis()
		self.PrintHeadline()
		self._CoreGenCompilation(args.FQN[0], args.logs, args.reports, args.DeviceName, args.BoardName)
		Exit.exit()

	def _CoreGenCompilation(self, entity, showLogs, showReport, deviceString=None, boardString=None):
		# check if ISE is configure
		if (len(self.PoCConfig.options("Xilinx.ISE")) == 0):	raise NotConfiguredException("Xilinx ISE is not configured on this system.")
		# check if the appropriate environment is loaded
		if (environ.get('XILINX') is None):										raise EnvironmentException("Xilinx ISE environment is not loaded in this shell environment. ")
		
		# prepare some paths
		self.Directories["CoreGenTemp"] =			self.Directories["PoCTemp"] / self.PoCConfig['PoC.DirectoryNames']['ISECoreGeneratorFiles']
		self.Directories["ISEInstallation"] = Path(self.PoCConfig['Xilinx.ISE']['InstallationDirectory'])
		self.Directories["ISEBinary"] =				Path(self.PoCConfig['Xilinx.ISE']['BinaryDirectory'])
		iseVersion =													self.PoCConfig['Xilinx.ISE']['Version']

		if (boardString is not None):
			boardString = boardString.lower()
			boardSection = None
			for option in self.PoCConfig['BOARDS']:
				if (option.lower() == boardString):
					boardSection = self.PoCConfig['BOARDS'][option]
			if (boardSection is None):
				raise CompilerException("Unknown board '" + boardString + "'.") from NoOptionError(boardString, 'BOARDS')

			deviceString =	self.PoCConfig[boardSection]['FPGA']
			device =				Device(deviceString)
		elif (deviceString is not None):
			device = Device(deviceString)
		else: raise BaseException("No board or device given.")

		entityToCompile = Entity(self, entity)

		compiler = XCOCompiler.Compiler(self, showLogs, showReport)
		compiler.dryRun = self.__dryRun
		compiler.Run(entityToCompile, device)

	# ----------------------------------------------------------------------------
	# create the sub-parser for the "coregen" command
	# ----------------------------------------------------------------------------
	@CommandGroupAttribute("Synthesis commands")
	@CommandAttribute("xst", help="Compile a PoC IP core with Xilinx ISE XST to a netlist")
	@ArgumentAttribute(metavar="<PoC Entity>", dest="FQN", type=str, nargs='+', help="todo help")
	@ArgumentAttribute('--device', metavar="<DeviceName>", dest="DeviceName", help="todo")
	@ArgumentAttribute('--board', metavar="<BoardName>", dest="BoardName", help="todo")
	@SwitchArgumentAttribute("-l", dest="logs", help="show logs")
	@SwitchArgumentAttribute("-r", dest="reports", help="show reports")
	# @HandleVerbosityOptions
	def HandleXstCompilation(self, args):
		self.__PrepareForSynthesis()
		self.PrintHeadline()
		self._XstCompilation(args.FQN, args.logs, args.reports, args.DeviceName, args.BoardName)
		Exit.exit()

	def _XstCompilation(self, entity, showLogs, showReport, deviceString=None, boardString=None):
		# check if ISE is configure
		if (len(self.PoCConfig.options("Xilinx.ISE")) == 0):	raise NotConfiguredException("Xilinx ISE is not configured on this system.")
		# check if the appropriate environment is loaded
		if (environ.get('XILINX') is None):										raise EnvironmentException("Xilinx ISE environment is not loaded in this shell environment. ")
		
		# prepare some paths
		self.Directories["XSTFiles"] =				self.Directories["PoCRoot"] / self.PoCConfig['PoC.DirectoryNames']['ISESynthesisFiles']
		self.Directories["XSTTemp"] =					self.Directories["PoCTemp"] / self.PoCConfig['PoC.DirectoryNames']['ISESynthesisFiles']
		self.Directories["ISEInstallation"] = Path(self.PoCConfig['Xilinx.ISE']['InstallationDirectory'])
		self.Directories["ISEBinary"] =				Path(self.PoCConfig['Xilinx.ISE']['BinaryDirectory'])
		iseVersion =													self.PoCConfig['Xilinx.ISE']['Version']

		if (boardString is not None):
			boardString = boardString.lower()
			boardSection = None
			for option in self.PoCConfig['BOARDS']:
				if (option.lower() == boardString):
					boardSection = self.PoCConfig['BOARDS'][option]
			if (boardSection is None):
				raise CompilerException("Unknown board '" + boardString + "'.") from NoOptionError(boardString, 'BOARDS')

			deviceString = self.PoCConfig[boardSection]['FPGA']
			device = Device(deviceString)
		elif (deviceString is not None):
			device = Device(deviceString)
		else:
			raise BaseException("No board or device given.")

		entityToCompile = Entity(self, entity)

		compiler = XSTCompiler.Compiler(self, showLogs, showReport)
		compiler.dryRun = self.dryRun
		compiler.Run(entityToCompile, device)


# main program
def main():
	dryRun =	"-D" in sys_argv
	debug =		"-d" in sys_argv
	verbose =	"-v" in sys_argv
	quiet =		"-q" in sys_argv

	# configure Exit class
	Exit.quiet = quiet

	try:
		Init.init()
		# handover to a class instance
		poc = PoC(debug, verbose, quiet, dryRun)
		poc.Run()
		Exit.exit()

	except (CommonException, ConfigurationException, SimulatorException, CompilerException) as ex:
		print("{RED}ERROR:{RESET} {message}".format(message=ex.message, **Init.Foreground))
		cause = ex.__cause__
		if isinstance(cause, FileNotFoundError):
			print("{YELLOW}  FileNotFound:{RESET} '{cause}'".format(cause=str(cause), **Init.Foreground))
		elif isinstance(cause, ConfigParser_Error):
			print("{YELLOW}  configparser.Error:{RESET} '{cause}'".format(cause=str(cause), **Init.Foreground))
		elif isinstance(cause, ParserException):
			print("{YELLOW}  ParserException:{RESET} {cause}".format(cause=str(cause), **Init.Foreground))
			cause = cause.__cause__
			if (cause is not None):
				print("{YELLOW}    {name}:{RESET} {cause}".format(name=cause.__class__.__name__, cause= str(cause), **Init.Foreground))
		elif isinstance(cause, ToolChainException):
			print("{YELLOW}  {name}:{RESET} {cause}".format(name=cause.__class__.__name__, cause=str(cause), **Init.Foreground))
			cause = cause.__cause__
			if (cause is not None):
				if isinstance(cause, OSError):
					print("{YELLOW}    {name}:{RESET} {cause}".format(name=cause.__class__.__name__, cause=str(cause), **Init.Foreground))
			else:
				print("  Possible causes:")
				print("   - The compile order is broken.")
				print("   - A source file was not compile and an old file got used.")

		if (not (verbose or debug)):
			print()
			print("{CYAN}  Use '-v' for verbose or '-d' for debug to print out extended messages.{RESET}".format(**Init.Foreground))
		Exit.exit(1)

	except EnvironmentException as ex:					Exit.printEnvironmentException(ex)
	except NotConfiguredException as ex:				Exit.printNotConfiguredException(ex)
	except PlatformNotSupportedException as ex:	Exit.printPlatformNotSupportedException(ex)
	except ExceptionBase as ex:									Exit.printExceptionbase(ex)
	except NotImplementedError as ex:						Exit.printNotImplementedError(ex)
	except Exception as ex:											Exit.printException(ex)

# entry point
if __name__ == "__main__":
	Exit.versionCheck((3,4,0))
	main()
else:
	Exit.printThisIsNoLibraryFile(PoC.HeadLine)
