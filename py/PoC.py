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
from collections import OrderedDict
from configparser							import Error as ConfigParser_Error, DuplicateOptionError
from os												import environ
from pathlib									import Path
from platform									import system as platform_system
from sys											import argv as sys_argv
from textwrap									import dedent

from lib.Functions						import Init, Exit
from lib.ArgParseAttributes		import ArgParseMixin, CommandAttribute, CommonSwitchArgumentAttribute, CommandGroupAttribute, ArgumentAttribute, SwitchArgumentAttribute, DefaultAttribute, \
	CommonArgumentAttribute
from lib.ConfigParser					import ExtendedConfigParser
from lib.Parser								import ParserException
from Base.Exceptions					import ExceptionBase, CommonException, PlatformNotSupportedException, EnvironmentException, NotConfiguredException
from Base.Logging							import ILogable, Logger, Severity
from Base.Configuration				import ConfigurationException, SkipConfigurationException
from Base.Project							import VHDLVersion
from Base.ToolChain						import ToolChainException
from Base.Simulator						import SimulatorException
from Base.Compiler						import CompilerException
from PoC.Config								import Board
from PoC.Entity								import Root, FQN, EntityTypes, WildCard, TestbenchKind, NetlistKind
from PoC.Query								import Query
from ToolChains								import Configurations
from Simulator.ActiveHDLSimulator		import Simulator as ActiveHDLSimulator
from Simulator.CocotbSimulator 			import Simulator as CocotbSimulator
from Simulator.GHDLSimulator				import Simulator as GHDLSimulator
from Simulator.ISESimulator					import Simulator as ISESimulator
from Simulator.QuestaSimulator			import Simulator as QuestaSimulator
from Simulator.VivadoSimulator			import Simulator as VivadoSimulator
from Compiler.QuartusCompiler	import Compiler as MapCompiler
from Compiler.LSECompiler			import Compiler as LSECompiler
from Compiler.XCOCompiler			import Compiler as XCOCompiler
from Compiler.XSTCompiler			import Compiler as XSTCompiler


# def HandleVerbosityOptions(func):
# 	def func_wrapper(self, args):
# 		self.ConfigureSyslog(args.quiet, args.verbose, args.debug)
# 		return func(self, args)
# 	return func_wrapper

class PoC(ILogable, ArgParseMixin):
	HeadLine =								"The PoC-Library - Service Tool"

	# configure hard coded variables here
	__CONFIGFILE_DIRECTORY =		"py"
	__CONFIGFILE_PRIVATE =			"config.private.ini"
	__CONFIGFILE_DEFAULTS =			"config.defaults.ini"
	__CONFIGFILE_BOARDS =				"config.boards.ini"
	__CONFIGFILE_STRUCTURE =		"config.structure.ini"
	__CONFIGFILE_IPCORES =			"config.entity.ini"

	__PLATFORM =								platform_system()  # load platform information (Windows, Linux, ...)

	# private fields

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
		self._CheckEnvironment()

		# Call the constructor of the ArgParseMixin
		# --------------------------------------------------------------------------
		description = dedent('''\
			This is the PoC-Library Service Tool.
			''')
		epilog = "Epidingsbums"

		class HelpFormatter(RawDescriptionHelpFormatter):
			def __init__(self, *args, **kwargs):
				kwargs['max_help_position'] = 34
				super().__init__(*args, **kwargs)

		ArgParseMixin.__init__(self, description=description, epilog=epilog, formatter_class=HelpFormatter, add_help=False)

		# declare members
		# --------------------------------------------------------------------------
		self.__dryRun =				dryRun
		self.__pocConfig =		None
		self.__root =					None
		self.__directories =	{}

		self.__SimulationDefaultVHDLVersion = VHDLVersion.VHDL08
		self.__SimulationDefaultBoard =				None

		self.Directories['Working'] =			Path.cwd()
		self.Directories['PoCRoot'] =			Path(environ.get('PoCRootDirectory'))
		# self.Directories['ScriptRoot'] =	Path(environ.get('PoCRootDirectory'))

		self._pocPrivateConfigFile =		self.Directories["PoCRoot"] / self.__CONFIGFILE_DIRECTORY / self.__CONFIGFILE_PRIVATE
		self._pocDefaultsConfigFile =		self.Directories["PoCRoot"] / self.__CONFIGFILE_DIRECTORY / self.__CONFIGFILE_DEFAULTS
		self._pocBoardConfigFile =			self.Directories["PoCRoot"] / self.__CONFIGFILE_DIRECTORY / self.__CONFIGFILE_BOARDS
		self._pocStructureConfigFile =	self.Directories["PoCRoot"] / self.__CONFIGFILE_DIRECTORY / self.__CONFIGFILE_STRUCTURE
		self._pocEntityConfigFile =			self.Directories["PoCRoot"] / self.__CONFIGFILE_DIRECTORY / self.__CONFIGFILE_IPCORES

	# class properties
	# ============================================================================
	@property
	def Platform(self):						return self.__PLATFORM
	@property
	def DryRun(self):							return self.__dryRun
	@property
	def Directories(self):				return self.__directories
	@property
	def PoCPrivateConfig(self):		return self._pocPrivateConfigFile
	@property
	def PoCPublicConfig(self): 		return self._pocStructureConfigFile
	@property
	def PoCEntityConfig(self): 		return self._pocEntityConfigFile
	@property
	def PoCBoardConfig(self): 		return self._pocBoardConfigFile
	@property
	def PoCTBConfig(self): 				return self._pocDefaultsConfigFile
	@property
	def PoCNLConfig(self): 				return self._pocNLConfigFile
	@property
	def PoCConfig(self):					return self.__pocConfig
	@property
	def Root(self):								return self.__root

	def _CheckEnvironment(self):
		if (self.Platform not in ["Windows", "Linux", "Darwin"]):	raise PlatformNotSupportedException(self.Platform)
		if (environ.get('PoCRootDirectory') is None):							raise EnvironmentException("Shell environment does not provide 'PoCRootDirectory' variable.")

	# read PoC configuration
	# ============================================================================
	def __ReadPoCConfiguration(self):
		self._LogVerbose("Reading configuration files...")

		configFiles = [
			(self._pocPrivateConfigFile,		"private"),
			(self._pocDefaultsConfigFile, 	"defaults"),
			(self._pocBoardConfigFile,			"boards"),
			(self._pocStructureConfigFile,	"structure"),
			(self._pocEntityConfigFile,			"IP core")
		]

		# create parser instance
		self._LogDebug("Reading PoC configuration from:")
		self.__pocConfig = ExtendedConfigParser()
		self.__pocConfig.optionxform = str

		try:
			# process first file (private)
			file, name = configFiles[0]
			self._LogDebug("  {0!s}".format(file))
			if not file.exists():  raise NotConfiguredException("PoC's {0} configuration file '{1!s}' does not exist.".format(name, file))  from FileNotFoundError(str(file))
			self.__pocConfig.read(str(file))

			for file, name in configFiles[1:]:
				self._LogDebug("  {0!s}".format(file))
				if not file.exists():  raise ConfigurationException("PoC's {0} configuration file '{1!s}' does not exist.".format(name, file))  from FileNotFoundError(str(file))
				self.__pocConfig.read(str(file))
		except DuplicateOptionError as ex:
			raise ConfigurationException("Error in configuration file '{0!s}'.".format(file)) from ex

		# print("="*80)
		# print("PoCConfig:")
		# for sectionName in self.__pocConfig:
		# 	print("  {0}".format(sectionName))
		# 	for optionName in self.__pocConfig[sectionName]:
		# 		try:
		# 			value = self.__pocConfig[sectionName][optionName]
		# 			print("    {0} = {1}".format(optionName, value))
		# 		except InterpolationError as ex:
		# 			pass		#value = "[INTERPOLATION ERROR]"
		# print("=" * 80)

		self.__root = Root(self)
		# print("=" * 80)
		# print(self.Root.pprint(0))
		# print("=" * 80)

		# check PoC installation directory
		if (self.Directories["PoCRoot"] != Path(self.PoCConfig['INSTALL.PoC']['InstallationDirectory'])):	raise NotConfiguredException("There is a mismatch between PoCRoot and PoC installation directory.")

		self.__SimulationDefaultBoard =		Board(self)

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
		self._LogNormal("Writing configuration file to '{0!s}'".format(self._pocPrivateConfigFile))
		with self._pocPrivateConfigFile.open('w') as configFileHandle:
			self.PoCConfig.write(configFileHandle)

	def __PrepareForConfiguration(self):
		self.__ReadPoCConfiguration()

	def __PrepareForSimulation(self):
		self._LogNormal("Initializing PoC-Library Service Tool for simulations")
		self.__ReadPoCConfiguration()

		# parsing values into class fields
		self.Directories["PoCSource"] =			self.Directories["PoCRoot"] / self.PoCConfig['CONFIG.DirectoryNames']['HDLSourceFiles']
		self.Directories["PoCTestbench"] =	self.Directories["PoCRoot"] / self.PoCConfig['CONFIG.DirectoryNames']['TestbenchFiles']
		self.Directories["PoCTemp"] =				self.Directories["PoCRoot"] / self.PoCConfig['CONFIG.DirectoryNames']['TemporaryFiles']

	def __PrepareForSynthesis(self):
		self._LogNormal("Initializing PoC-Library Service Tool for synthesis")
		self.__ReadPoCConfiguration()

		# parsing values into class fields
		self.Directories["PoCSource"] =			self.Directories["PoCRoot"] / self.PoCConfig['CONFIG.DirectoryNames']['HDLSourceFiles']
		self.Directories["PoCNetList"] =		self.Directories["PoCRoot"] / self.PoCConfig['CONFIG.DirectoryNames']['NetlistFiles']
		self.Directories["PoCTemp"] =				self.Directories["PoCRoot"] / self.PoCConfig['CONFIG.DirectoryNames']['TemporaryFiles']

		# self.Directories["XSTFiles"] =			self.Directories["PoCRoot"] / self.PoCConfig['PoC.DirectoryNames']['ISESynthesisFiles']
		# #self.Directories["QuartusFiles"] =	self.Directories["PoCRoot"] / self.PoCConfig['PoC.DirectoryNames']['QuartusSynthesisFiles']

	# ============================================================================
	# Common commands
	# ============================================================================
	# common arguments valid for all commands
	# ----------------------------------------------------------------------------
	@CommonSwitchArgumentAttribute("-D",							dest="DEBUG",		help="enable script wrapper debug mode")
	@CommonSwitchArgumentAttribute("-d", "--debug",		dest="debug",		help="enable debug mode")
	@CommonSwitchArgumentAttribute("-v", "--verbose",	dest="verbose",	help="print out detailed messages")
	@CommonSwitchArgumentAttribute("-q", "--quiet",		dest="quiet",		help="reduce messages to a minimum")
	@CommonArgumentAttribute('--sln', metavar="<Solution>", dest="SolutionName", help="Solution name")
	def Run(self):
		ArgParseMixin.Run(self)

	def PrintHeadline(self):
		# self._LogNormal(Foreground.MAGENTA + "=" * 80)
		self._LogNormal("{HEADLINE}{line}{NOCOLOR}".format(line="="*80, **Init.Foreground))
		self._LogNormal("{HEADLINE}{headline: ^80s}{NOCOLOR}".format(headline=self.HeadLine, **Init.Foreground))
		self._LogNormal("{HEADLINE}{line}{NOCOLOR}".format(line="="*80, **Init.Foreground))

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
	def HandleManualConfiguration(self, _):
		self.PrintHeadline()
		try:
			self.__ReadPoCConfiguration()
			self.__UpdateConfiguration()
		except NotConfiguredException:
			self._InitializeConfiguration()

		self._LogVerbose("starting manual configuration...")
		print('Explanation of abbreviations:')
		print('  y - yes')
		print('  n - no')
		print('  p - pass (jump to next question)')
		#print('Upper case means default value')
		print()

		if (self.Platform == "Windows"):							self._manualConfigurationForWindows()
		elif (self.Platform in ["Linux", "Darwin"]):	self._manualConfigurationForLinux()
		else:																					raise PlatformNotSupportedException(self.Platform)

		# write configuration
		self.__WritePoCConfiguration()
		# re-read configuration
		self.__ReadPoCConfiguration()

	def _InitializeConfiguration(self):
		# create parser instance
		self._LogWarning("No private configuration found. Generating an empty PoC configuration...")
		# self.__pocConfig = ExtendedConfigParser()
		# self.__pocConfig.optionxform = str

		for config in Configurations:
			if ("ALL" in config._privateConfiguration):
				for sectionName in config._privateConfiguration['ALL']:
					self.__pocConfig[sectionName] = OrderedDict()
			if (self.Platform in config._privateConfiguration):
				for sectionName in config._privateConfiguration[self.Platform]:
					self.__pocConfig[sectionName] = OrderedDict()

	def __UpdateConfiguration(self):
		pass

	def _manualConfigurationForWindows(self):
		for config in Configurations:
			configurator = config(self)
			self._LogNormal("{CYAN}Configuring {0!s}{NOCOLOR}".format(configurator.Name, **Init.Foreground))

			nxt = False
			while (nxt == False):
				try:
					configurator.ConfigureForWindows()
					nxt = True
				except SkipConfigurationException:
					break
				except ExceptionBase as ex:
					print("  {RED}FAULT:{NOCOLOR} {0}".format(ex.message, **Init.Foreground))
			# end while

	def _manualConfigurationForLinux(self):
		for conf in Configurations:
			configurator = conf()
			self._LogNormal("Configure {0}".format(configurator.Name))

			nxt = False
			while (nxt == False):
				try:
					configurator.ConfigureForLinux()
					nxt = True
				except ExceptionBase as ex:
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
		print(result, end="")
		Exit.exit()


	# ============================================================================
	# Simulation	commands
	# ============================================================================
	def __PrepareVendorLibraryPaths(self):
		# prepare vendor library path for Altera
		if (len(self.PoCConfig.options("INSTALL.Altera.QuartusII")) != 0):
			self.Directories["AlteraPrimitiveSource"] = Path(self.PoCConfig['INSTALL.Altera.QuartusII']['InstallationDirectory']) / "eda/sim_lib"
		# prepare vendor library path for Xilinx
		if (len(self.PoCConfig.options("INSTALL.Xilinx.ISE")) != 0):
			self.Directories["XilinxPrimitiveSource"] = Path(self.PoCConfig['INSTALL.Xilinx.ISE']['InstallationDirectory']) / "ISE/vhdl/src"
		elif (len(self.PoCConfig.options("INSTALL.Xilinx.Vivado")) != 0):
			self.Directories["XilinxPrimitiveSource"] = Path(self.PoCConfig['INSTALL.Xilinx.Vivado']['InstallationDirectory']) / "data/vhdl/src"
		
	def _ExtractBoard(self, BoardName, DeviceName):
		if (BoardName is not None):			return Board(self, BoardName)
		elif (DeviceName is not None):	return Board(self, "Custom", DeviceName)
		else:														return self.__SimulationDefaultBoard

	def _ExtractFQNs(self, fqns, defaultType=EntityTypes.Testbench):
		if (len(fqns) == 0):             raise SimulatorException("No FQN given.")
		return [FQN(self, fqn, defaultType=defaultType) for fqn in fqns]

	def _ExtractVHDLVersion(self, vhdlVersion):
		if (vhdlVersion is None):				return self.__SimulationDefaultVHDLVersion
		else:														return VHDLVersion.parse(vhdlVersion)

	# TODO: move to Configuration class in ToolChains.Xilinx.Vivado
	def _CheckVivadoEnvironment(self):
		# check if Vivado is configure
		if (len(self.PoCConfig.options("INSTALL.Xilinx.Vivado")) == 0):	raise NotConfiguredException("Xilinx Vivado is not configured on this system.")
		if (environ.get('XILINX_VIVADO') is None):											raise EnvironmentException("Xilinx Vivado environment is not loaded in this shell environment.")

	# TODO: move to Configuration class in ToolChains.Xilinx.ISE
	def _CheckISEEnvironment(self):
		# check if ISE is configure
		if (len(self.PoCConfig.options("INSTALL.Xilinx.ISE")) == 0):		raise NotConfiguredException("Xilinx ISE is not configured on this system.")
		if (environ.get('XILINX') is None):															raise EnvironmentException("Xilinx ISE environment is not loaded in this shell environment.")

	# ----------------------------------------------------------------------------
	# create the sub-parser for the "list-testbench" command
	# ----------------------------------------------------------------------------
	@CommandGroupAttribute("Simulation commands")
	@CommandAttribute("list-testbench", help="List all testbenches")
	@ArgumentAttribute(metavar="<PoC Entity>", dest="FQN", type=str, nargs='+', help="todo help")
	@ArgumentAttribute('--kind', metavar="<Kind>", dest="TestbenchKind", help="Testbench kind: VHDL | COCOTB")
	# @HandleVerbosityOptions
	def HandleListTestbenches(self, args):
		self.PrintHeadline()
		self.__PrepareForSimulation()

		if (len(args.FQN) == 0):              raise SimulatorException("No FQN given.")

		if (args.SolutionName is not None):
			solutionName = args.SolutionName
			print("Solution name: {0}".format(solutionName))
			if self.PoCConfig.has_option("SOLUTION.Solutions", solutionName):
				sectionName = "SOLUTION.{0}".format(solutionName)
				print("Found registered solution:")
				print("  Name: {0}".format(self.PoCConfig[sectionName]['Name']))
				print("  Path: {0}".format(self.PoCConfig[sectionName]['Path']))

				solutionRootPath = self.Directories["PoCRoot"] / self.PoCConfig[sectionName]['Path']
				iniFile = solutionRootPath / ".PoC" / "PoC.Solution.ini"
				print("  sln ini: {0!s}".format(iniFile))

		if (args.TestbenchKind is None):
			tbFilter =	TestbenchKind.All
		else:
			tbFilter =	TestbenchKind.Unknown
			for kind in args.TestbenchKind.lower().split(","):
				if   (kind == "vhdl"):		tbFilter |= TestbenchKind.VHDLTestbench
				elif (kind == "cocotb"):	tbFilter |= TestbenchKind.CocoTestbench
				else:											raise CommonException("Argument --kind has an unknown value '{0}'.".format(kind))

		fqnList = self._ExtractFQNs(args.FQN)
		for fqn in fqnList:
			self._LogNormal("")
			entity = fqn.Entity
			if (isinstance(entity, WildCard)):
				for testbench in entity.GetTestbenches(tbFilter):
					print(str(testbench))
			else:
				testbench = entity.GetTestbenches(tbFilter)
				print(str(testbench))

		Exit.exit()
	
	
	# ----------------------------------------------------------------------------
	# create the sub-parser for the "asim" command
	# ----------------------------------------------------------------------------
	@CommandGroupAttribute("Simulation commands")
	@CommandAttribute("asim", help="Simulate a PoC Entity with Aldec Active-HDL")
	@ArgumentAttribute(metavar="<PoC Entity>", dest="FQN", type=str, nargs='+', help="todo help")
	@ArgumentAttribute('--device', metavar="<DeviceName>", dest="DeviceName", help="The target platform's device name.")
	@ArgumentAttribute('--board', metavar="<BoardName>", dest="BoardName", help="The target platform's board name.")
	@ArgumentAttribute('--std', metavar="<VHDLVersion>", dest="VHDLVersion", help="Simulate with VHDL-??")
	@SwitchArgumentAttribute("-g", "--gui", dest="GUIMode", help="show waveform in a GUI window.")
	@SwitchArgumentAttribute("-l", dest="logs", help="show logs")
	@SwitchArgumentAttribute("-r", dest="reports", help="show reports")
	# @SwitchArgumentAttribute("-08", dest="VHDLVersion", help="Simulate with VHDL-2008.")
	# @HandleVerbosityOptions
	def HandleActiveHDLSimulation(self, args):
		self.PrintHeadline()
		self.__PrepareForSimulation()

		# check if Aldec tools are configure
		if (len(self.PoCConfig.options("INSTALL.Aldec.ActiveHDL")) != 0):
			precompiledDirectory =											self.PoCConfig['CONFIG.DirectoryNames']['PrecompiledFiles']
			activeHDLSimulatorFiles =										self.PoCConfig['CONFIG.DirectoryNames']['ActiveHDLFiles']
			self.Directories["ActiveHDLTemp"] =					self.Directories["PoCTemp"] / activeHDLSimulatorFiles
			self.Directories["ActiveHDLPrecompiled"] =	self.Directories["PoCTemp"] / precompiledDirectory / activeHDLSimulatorFiles
			self.Directories["ActiveHDLInstallation"] =	Path(self.PoCConfig['INSTALL.Aldec.ActiveHDL']['InstallationDirectory'])
			self.Directories["ActiveHDLBinary"] =				Path(self.PoCConfig['INSTALL.Aldec.ActiveHDL']['BinaryDirectory'])
			aSimVersion =																self.PoCConfig['INSTALL.Aldec.ActiveHDL']['Version']
		elif (len(self.PoCConfig.options("INSTALL.Lattice.ActiveHDL")) != 0):
			precompiledDirectory =											self.PoCConfig['CONFIG.DirectoryNames']['PrecompiledFiles']
			activeHDLSimulatorFiles =										self.PoCConfig['CONFIG.DirectoryNames']['ActiveHDLFiles']
			self.Directories["ActiveHDLTemp"] =					self.Directories["PoCTemp"] / activeHDLSimulatorFiles
			self.Directories["ActiveHDLPrecompiled"] =	self.Directories["PoCTemp"] / precompiledDirectory / activeHDLSimulatorFiles
			self.Directories["ActiveHDLInstallation"] =	Path(self.PoCConfig['INSTALL.Lattice.ActiveHDL']['InstallationDirectory'])
			self.Directories["ActiveHDLBinary"] =				Path(self.PoCConfig['INSTALL.Lattice.ActiveHDL']['BinaryDirectory'])
			aSimVersion =																self.PoCConfig['INSTALL.Lattice.ActiveHDL']['Version']
		# elif (len(self.PoCConfig.options("INSTALL.Aldec.RivieraPRO")) != 0):
		# self.Directories["ActiveHDLInstallation"] =	Path(self.PoCConfig['Aldec.RivieraPRO']['InstallationDirectory'])
		# self.Directories["ActiveHDLBinary"] =				Path(self.PoCConfig['Aldec.RivieraPRO']['BinaryDirectory'])
		# aSimVersion =																self.PoCConfig['Aldec.RivieraPRO']['Version']
		else:
			# raise NotConfiguredException("Neither Aldec's Active-HDL nor Riviera PRO nor Active-HDL Lattice Edition are configured on this system.")
			raise NotConfiguredException("Neither Aldec's Active-HDL nor Active-HDL Lattice Edition are configured on this system.")

		if (len(args.FQN) == 0):              raise SimulatorException("No FQN given.")
		
		fqnList =			self._ExtractFQNs(args.FQN)
		board =				self._ExtractBoard(args.BoardName, args.DeviceName)
		vhdlVersion =	self._ExtractVHDLVersion(args.VHDLVersion)

		# prepare paths to vendor simulation libraries
		self.__PrepareVendorLibraryPaths()
		
		# prepare some paths
		binaryPath =	self.Directories["ActiveHDLBinary"]

		# create a GHDLSimulator instance and prepare it
		simulator = ActiveHDLSimulator(self, args.logs, args.reports, args.GUIMode)
		simulator.PrepareSimulator(binaryPath, aSimVersion)
		simulator.RunAll(fqnList, board=board, vhdlVersion=vhdlVersion)  # , vhdlGenerics=None)

		Exit.exit()
	
	
# ----------------------------------------------------------------------------
	# create the sub-parser for the "ghdl" command
	# ----------------------------------------------------------------------------
	@CommandGroupAttribute("Simulation commands")
	@CommandAttribute("ghdl", help="Simulate a PoC Entity with GHDL")
	@ArgumentAttribute(metavar="<PoC Entity>", dest="FQN", type=str, nargs='+', help="todo help")
	@ArgumentAttribute('--device', metavar="<DeviceName>", dest="DeviceName", help="The target platform's device name.")
	@ArgumentAttribute('--board', metavar="<BoardName>", dest="BoardName", help="The target platform's board name.")
	@ArgumentAttribute('--std', metavar="<VHDLVersion>", dest="VHDLVersion", help="Simulate with VHDL-??")
	@SwitchArgumentAttribute("-g", "--gui", dest="GUIMode", help="show waveform in GTKWave.")
	@SwitchArgumentAttribute("-l", dest="logs", help="show logs")
	@SwitchArgumentAttribute("-r", dest="reports", help="show reports")
	# @SwitchArgumentAttribute("-08", dest="VHDLVersion", help="Simulate with VHDL-2008.")
	# standard
	# @HandleVerbosityOptions
	def HandleGHDLSimulation(self, args):
		self.PrintHeadline()
		self.__PrepareForSimulation()

		# check if GHDL is configure
		if (len(self.PoCConfig.options("INSTALL.GHDL")) == 0):  raise NotConfiguredException("GHDL is not configured on this system.")
		
		fqnList =			self._ExtractFQNs(args.FQN)
		board =				self._ExtractBoard(args.BoardName, args.DeviceName)
		vhdlVersion =	self._ExtractVHDLVersion(args.VHDLVersion)

		# prepare some paths
		self.Directories["GHDLTemp"] =					self.Directories["PoCTemp"] / self.PoCConfig['CONFIG.DirectoryNames']['GHDLFiles']
		self.Directories["GHDLPrecompiled"] =		self.Directories["PoCTemp"] / self.PoCConfig['CONFIG.DirectoryNames']['PrecompiledFiles'] / self.PoCConfig['CONFIG.DirectoryNames']['GHDLFiles']
		self.Directories["GHDLInstallation"] =	Path(self.PoCConfig['INSTALL.GHDL']['InstallationDirectory'])
		self.Directories["GHDLBinary"] =				Path(self.PoCConfig['INSTALL.GHDL']['BinaryDirectory'])
		ghdlBinaryPath =												self.Directories["GHDLBinary"]
		ghdlVersion =														self.PoCConfig['INSTALL.GHDL']['Version']
		ghdlBackend =														self.PoCConfig['INSTALL.GHDL']['Backend']

		if (args.GUIMode == True):
			# prepare paths for GTKWave, if configured
			if (len(self.PoCConfig.options("INSTALL.GTKWave")) != 0):
				self.Directories["GTKWInstallation"] = Path(self.PoCConfig['INSTALL.GTKWave']['InstallationDirectory'])
				self.Directories["GTKWBinary"] = Path(self.PoCConfig['INSTALL.GTKWave']['BinaryDirectory'])
			else:
				raise NotConfiguredException("No GHDL compatible waveform viewer is configured on this system.")

		# prepare paths to vendor simulation libraries
		self.__PrepareVendorLibraryPaths()

		# create a GHDLSimulator instance and prepare it
		simulator = GHDLSimulator(self, args.logs, args.reports, args.GUIMode)
		simulator.PrepareSimulator(ghdlBinaryPath, ghdlVersion, ghdlBackend)
		simulator.RunAll(fqnList, board=board, vhdlVersion=vhdlVersion, guiMode=args.GUIMode)		#, vhdlGenerics=None)

		Exit.exit()


	# ----------------------------------------------------------------------------
	# create the sub-parser for the "isim" command
	# ----------------------------------------------------------------------------
	@CommandGroupAttribute("Simulation commands")
	@CommandAttribute("isim", help="Simulate a PoC Entity with Xilinx ISE Simulator (iSim)")
	@ArgumentAttribute(metavar="<PoC Entity>", dest="FQN", type=str, nargs='+', help="todo help")
	@ArgumentAttribute('--device', metavar="<DeviceName>", dest="DeviceName", help="The target platform's device name.")
	@ArgumentAttribute('--board', metavar="<BoardName>", dest="BoardName", help="The target platform's board name.")
	@SwitchArgumentAttribute("-g", "--gui", dest="GUIMode", help="show waveform in a GUI window.")
	@SwitchArgumentAttribute("-l", dest="logs", help="show logs")
	@SwitchArgumentAttribute("-r", dest="reports", help="show reports")
	# standard
	# @HandleVerbosityOptions
	def HandleISESimulation(self, args):
		self.PrintHeadline()
		self.__PrepareForSimulation()

		self._CheckISEEnvironment()
		
		fqnList =			self._ExtractFQNs(args.FQN)
		board =				self._ExtractBoard(args.BoardName, args.DeviceName)

		# prepare some paths
		iseSimulatorFiles =													self.PoCConfig['CONFIG.DirectoryNames']['ISESimulatorFiles']
		precompiledDirectory =											self.PoCConfig['CONFIG.DirectoryNames']['PrecompiledFiles']
		self.Directories["iSimTemp"] =							self.Directories["PoCTemp"] / iseSimulatorFiles
		self.Directories["iSimPrecompiled"] =				self.Directories["PoCTemp"] / precompiledDirectory / iseSimulatorFiles
		self.Directories["ISEInstallation"] =				Path(self.PoCConfig['INSTALL.Xilinx.ISE']['InstallationDirectory'])
		self.Directories["ISEBinary"] =							Path(self.PoCConfig['INSTALL.Xilinx.ISE']['BinaryDirectory'])
		self.Directories["XilinxPrimitiveSource"] =	Path(self.PoCConfig['INSTALL.Xilinx.ISE']['InstallationDirectory']) / "data/vhdl/src"
		iseVersion =																self.PoCConfig['INSTALL.Xilinx.ISE']['Version']
		binaryPath =																self.Directories["ISEBinary"]

		# prepare paths to vendor simulation libraries
		self.__PrepareVendorLibraryPaths()

		# create a GHDLSimulator instance and prepare it
		simulator = ISESimulator(self, args.logs, args.reports, args.GUIMode)
		simulator.PrepareSimulator(binaryPath, iseVersion)
		simulator.RunAll(fqnList, board=board)		#, vhdlGenerics=None)

		Exit.exit()
		
		
	# ----------------------------------------------------------------------------
	# create the sub-parser for the "vsim" command
	# ----------------------------------------------------------------------------
	@CommandGroupAttribute("Simulation commands")
	@CommandAttribute("vsim", help="Simulate a PoC Entity with Mentor QuestaSim or ModelSim (vsim)")
	@ArgumentAttribute(metavar="<PoC Entity>", dest="FQN", type=str, nargs='+', help="todo help")
	@ArgumentAttribute('--device', metavar="<DeviceName>", dest="DeviceName", help="The target platform's device name.")
	@ArgumentAttribute('--board', metavar="<BoardName>", dest="BoardName", help="The target platform's board name.")
	@ArgumentAttribute('--std', metavar="<VHDLVersion>", dest="VHDLVersion", help="Simulate with VHDL-??")
	@SwitchArgumentAttribute("-g", "--gui", dest="GUIMode", help="show waveform in a GUI window.")
	@SwitchArgumentAttribute("-l", dest="logs", help="show logs")
	@SwitchArgumentAttribute("-r", dest="reports", help="show reports")
	# @SwitchArgumentAttribute("-08", dest="VHDLVersion", help="Simulate with VHDL-2008.")
	# standard
	# @HandleVerbosityOptions
	def HandleQuestaSimulation(self, args):
		self.PrintHeadline()
		self.__PrepareForSimulation()

		# check if QuestaSim is configured
		if (len(self.PoCConfig.options("INSTALL.Mentor.QuestaSim")) != 0):
			precompiledDirectory =									self.PoCConfig['CONFIG.DirectoryNames']['PrecompiledFiles']
			vSimSimulatorFiles =										self.PoCConfig['CONFIG.DirectoryNames']['QuestaSimFiles']
			self.Directories["vSimTemp"] =					self.Directories["PoCTemp"] / vSimSimulatorFiles
			self.Directories["vSimPrecompiled"] =		self.Directories["PoCTemp"] / precompiledDirectory / vSimSimulatorFiles
			self.Directories["vSimInstallation"] =	Path(self.PoCConfig['INSTALL.Mentor.QuestaSim']['InstallationDirectory'])
			self.Directories["vSimBinary"] =				Path(self.PoCConfig['INSTALL.Mentor.QuestaSim']['BinaryDirectory'])
			binaryPath =														self.Directories["vSimBinary"]
			vSimVersion =														self.PoCConfig['INSTALL.Mentor.QuestaSim']['Version']
		elif (len(self.PoCConfig.options("INSTALL.Altera.ModelSim")) != 0):
			precompiledDirectory =									self.PoCConfig['CONFIG.DirectoryNames']['PrecompiledFiles']
			vSimSimulatorFiles =										self.PoCConfig['CONFIG.DirectoryNames']['QuestaSimFiles']
			self.Directories["vSimTemp"] =					self.Directories["PoCTemp"] / vSimSimulatorFiles
			self.Directories["vSimPrecompiled"] =		self.Directories["PoCTemp"] / precompiledDirectory / vSimSimulatorFiles
			self.Directories["vSimInstallation"] =	Path(self.PoCConfig['INSTALL.Altera.ModelSim']['InstallationDirectory'])
			self.Directories["vSimBinary"] =				Path(self.PoCConfig['INSTALL.Altera.ModelSim']['BinaryDirectory'])
			binaryPath =														self.Directories["vSimBinary"]
			vSimVersion =														self.PoCConfig['INSTALL.Altera.ModelSim']['Version']
		else:
			raise NotConfiguredException("Neither Mentor Graphics QuestaSim nor ModelSim Altera-Edition are configured on this system.")
		
		fqnList =			self._ExtractFQNs(args.FQN)
		board =				self._ExtractBoard(args.BoardName, args.DeviceName)
		vhdlVersion =	self._ExtractVHDLVersion(args.VHDLVersion)

		# prepare paths to vendor simulation libraries
		self.__PrepareVendorLibraryPaths()

		# create a GHDLSimulator instance and prepare it
		simulator = QuestaSimulator(self, args.logs, args.reports, args.GUIMode)
		simulator.PrepareSimulator(binaryPath, vSimVersion)
		simulator.RunAll(fqnList, board=board, vhdlVersion=vhdlVersion)  # , vhdlGenerics=None)

		Exit.exit()
	
	
	# ----------------------------------------------------------------------------
	# create the sub-parser for the "xsim" command
	# ----------------------------------------------------------------------------
	@CommandGroupAttribute("Simulation commands")
	@CommandAttribute("xsim", help="Simulate a PoC Entity with Xilinx Vivado Simulator (xSim)")
	@ArgumentAttribute(metavar="<PoC Entity>", dest="FQN", type=str, nargs='+', help="todo help")
	@ArgumentAttribute('--device', metavar="<DeviceName>", dest="DeviceName", help="The target platform's device name.")
	@ArgumentAttribute('--board', metavar="<BoardName>", dest="BoardName", help="The target platform's board name.")
	@ArgumentAttribute('--std', metavar="<VHDLVersion>", dest="VHDLVersion", help="Simulate with VHDL-??")
	@SwitchArgumentAttribute("-g", "--gui", dest="GUIMode", help="show waveform in a GUI window.")
	@SwitchArgumentAttribute("-l", dest="logs", help="show logs")
	@SwitchArgumentAttribute("-r", dest="reports", help="show reports")
	# @SwitchArgumentAttribute("-08", dest="VHDLVersion", help="Simulate with VHDL-2008.")
	# standard
	# @HandleVerbosityOptions
	def HandleVivadoSimulation(self, args):
		self.PrintHeadline()
		self.__PrepareForSimulation()

		self._CheckVivadoEnvironment()
		
		fqnList =			self._ExtractFQNs(args.FQN)
		board =				self._ExtractBoard(args.BoardName, args.DeviceName)
		# vhdlVersion =	self._ExtractVHDLVersion(args.VHDLVersion)

		# FIXME: VHDL-2008 is broken in Vivado 2015.4 -> use VHDL-93 by default
		if (args.VHDLVersion is None):
			vhdlVersion = VHDLVersion.VHDL93	# self.__SimulationDefaultVHDLVersion
		else:
			vhdlVersion = VHDLVersion.parse(args.VHDLVersion)

		# prepare some paths
		vivadoSimulatorFiles =											self.PoCConfig['CONFIG.DirectoryNames']['VivadoSimulatorFiles']
		precompiledDirectory =											self.PoCConfig['CONFIG.DirectoryNames']['PrecompiledFiles']
		self.Directories["xSimTemp"] =							self.Directories["PoCTemp"] / vivadoSimulatorFiles
		self.Directories["xSimPrecompiled"] =				self.Directories["PoCTemp"] / precompiledDirectory / vivadoSimulatorFiles
		self.Directories["VivadoInstallation"] =		Path(self.PoCConfig['INSTALL.Xilinx.Vivado']['InstallationDirectory'])
		self.Directories["VivadoBinary"] =					Path(self.PoCConfig['INSTALL.Xilinx.Vivado']['BinaryDirectory'])
		self.Directories["XilinxPrimitiveSource"] =	Path(self.PoCConfig['INSTALL.Xilinx.Vivado']['InstallationDirectory']) / "data/vhdl/src"
		vivadoVersion =															self.PoCConfig['INSTALL.Xilinx.Vivado']['Version']
		binaryPath =																self.Directories["VivadoBinary"]

		# prepare paths to vendor simulation libraries
		self.__PrepareVendorLibraryPaths()

		# create a GHDLSimulator instance and prepare it
		simulator = VivadoSimulator(self, args.logs, args.reports, args.GUIMode)
		simulator.PrepareSimulator(binaryPath, vivadoVersion)
		simulator.RunAll(fqnList, board=board, vhdlVersion=vhdlVersion)  # , vhdlGenerics=None)

		Exit.exit()


	# ----------------------------------------------------------------------------
	# create the sub-parser for the "cocotb" command
	# ----------------------------------------------------------------------------
	@CommandGroupAttribute("Simulation commands")
	@CommandAttribute("cocotb", help="Simulate a PoC Entity with Cocotb and Questa Simulator")
	@ArgumentAttribute(metavar="<PoC Entity>", dest="FQN", type=str, nargs='+', help="todo help")
	@ArgumentAttribute('--device', metavar="<DeviceName>", dest="DeviceName", help="The target platform's device name.")
	@ArgumentAttribute('--board', metavar="<BoardName>", dest="BoardName", help="The target platform's board name.")
	@SwitchArgumentAttribute("-g", "--gui", dest="GUIMode", help="show waveform in a GUI window.")
	@SwitchArgumentAttribute("-l", dest="logs", help="show logs")
	@SwitchArgumentAttribute("-r", dest="reports", help="show reports")
	# @HandleVerbosityOptions
	def HandleCocotbSimulation(self, args):
		self.PrintHeadline()
		self.__PrepareForSimulation()

		# check if QuestaSim is configured
		if (len(self.PoCConfig.options("INSTALL.Mentor.QuestaSim")) != 0):
			precompiledDirectory =									self.PoCConfig['CONFIG.DirectoryNames']['PrecompiledFiles']
			vSimSimulatorFiles =										self.PoCConfig['CONFIG.DirectoryNames']['QuestaSimFiles']
			cocotbSimulatorFiles =									self.PoCConfig['CONFIG.DirectoryNames']['CocotbFiles']
			self.Directories["CocotbTemp"] =				self.Directories["PoCTemp"] / cocotbSimulatorFiles
			self.Directories["vSimPrecompiled"] =		self.Directories["PoCTemp"] / precompiledDirectory / vSimSimulatorFiles
		else:
			raise NotConfiguredException("Mentor QuestaSim is not configured on this system.")

		fqnList =	self._ExtractFQNs(args.FQN)
		board =		self._ExtractBoard(args.BoardName, args.DeviceName)

		# prepare paths to vendor simulation libraries
		#self.__PrepareVendorLibraryPaths()

		# create a CocotbSimulator instance and prepare it
		simulator = CocotbSimulator(self, args.logs, args.reports, args.GUIMode)
		simulator.PrepareSimulator()
		simulator.RunAll(fqnList, board=board)

		Exit.exit()


	# ============================================================================
	# Synthesis	commands
	# ============================================================================
	# create the sub-parser for the "list-netlist" command
	# ----------------------------------------------------------------------------
	@CommandGroupAttribute("Simulation commands")
	@CommandAttribute("list-netlist", help="List all netlists")
	@ArgumentAttribute(metavar="<PoC Entity>", dest="FQN", type=str, nargs='+', help="todo help")
	@ArgumentAttribute('--kind', metavar="<Kind>", dest="NetlistKind", help="Netlist kind: Lattice | Quartus | XST | CoreGen")
	# @HandleVerbosityOptions
	def HandleListNetlist(self, args):
		self.PrintHeadline()
		self.__PrepareForSynthesis()

		if (len(args.FQN) == 0):              raise SimulatorException("No FQN given.")

		if (args.NetlistKind is None):
			nlFilter = NetlistKind.All
		else:
			nlFilter = NetlistKind.Unknown
			for kind in args.TestbenchKind.lower().split(","):
				if   (kind == "lattice"):	nlFilter |= NetlistKind.LatticeNetlist
				elif (kind == "quartus"):	nlFilter |= NetlistKind.QuartusNetlist
				elif (kind == "xst"):			nlFilter |= NetlistKind.XstNetlist
				elif (kind == "coregen"):	nlFilter |= NetlistKind.CoreGeneratorNetlist
				else:											raise CommonException("Argument --kind has an unknown value '{0}'.".format(kind))

		fqnList = self._ExtractFQNs(args.FQN)
		for fqn in fqnList:
			entity = fqn.Entity
			if (isinstance(entity, WildCard)):
				for testbench in entity.GetNetlists(nlFilter):
					print(str(testbench))
			else:
				testbench = entity.GetNetlists(nlFilter)
				print(str(testbench))

		Exit.exit()

	# ----------------------------------------------------------------------------
	# create the sub-parser for the "coregen" command
	# ----------------------------------------------------------------------------
	@CommandGroupAttribute("Synthesis commands")
	@CommandAttribute("coregen", help="Generate an IP core with Xilinx ISE Core Generator")
	@ArgumentAttribute(metavar="<PoC Entity>", dest="FQN", type=str, nargs='+', help="todo help")
	@ArgumentAttribute('--device', metavar="<DeviceName>", dest="DeviceName", help="The target platform's device name.")
	@ArgumentAttribute('--board', metavar="<BoardName>", dest="BoardName", help="The target platform's board name.")
	@SwitchArgumentAttribute("--no-cleanup", dest="NoCleanUp", help="Don't delete intermediate files. Skip post-delete rules.")
	@SwitchArgumentAttribute("-l", dest="logs", help="show logs")
	@SwitchArgumentAttribute("-r", dest="reports", help="show reports")
	# @HandleVerbosityOptions
	def HandleCoreGeneratorCompilation(self, args):
		self.PrintHeadline()
		self.__PrepareForSynthesis()

		self._CheckISEEnvironment()
		
		fqnList =	self._ExtractFQNs(args.FQN, defaultType=EntityTypes.NetList)
		board =		self._ExtractBoard(args.BoardName, args.DeviceName)

		# prepare some paths
		self.Directories["PoCNetlist"] =			self.Directories["PoCRoot"] / self.PoCConfig['CONFIG.DirectoryNames']['NetlistFiles']
		self.Directories["CoreGenTemp"] =			self.Directories["PoCTemp"] / self.PoCConfig['CONFIG.DirectoryNames']['ISECoreGeneratorFiles']
		self.Directories["ISEInstallation"] = Path(self.PoCConfig['INSTALL.Xilinx.ISE']['InstallationDirectory'])
		self.Directories["ISEBinary"] =				Path(self.PoCConfig['INSTALL.Xilinx.ISE']['BinaryDirectory'])
		iseBinaryPath =												self.Directories["ISEBinary"]
		iseVersion =													self.PoCConfig['INSTALL.Xilinx.ISE']['Version']

		compiler = XCOCompiler(self, args.logs, args.reports, self.DryRun, args.NoCleanUp)
		compiler.PrepareCompiler(iseBinaryPath, iseVersion)
		compiler.RunAll(fqnList, board)

		Exit.exit()

	# ----------------------------------------------------------------------------
	# create the sub-parser for the "xst" command
	# ----------------------------------------------------------------------------
	@CommandGroupAttribute("Synthesis commands")
	@CommandAttribute("xst", help="Compile a PoC IP core with Xilinx ISE XST to a netlist")
	@ArgumentAttribute(metavar="<PoC Entity>", dest="FQN", type=str, nargs='+', help="todo help")
	@ArgumentAttribute('--device', metavar="<DeviceName>", dest="DeviceName", help="The target platform's device name.")
	@ArgumentAttribute('--board', metavar="<BoardName>", dest="BoardName", help="The target platform's board name.")
	@SwitchArgumentAttribute("--no-cleanup", dest="NoCleanUp", help="Don't delete intermediate files. Skip post-delete rules.")
	@SwitchArgumentAttribute("-l", dest="logs", help="show logs")
	@SwitchArgumentAttribute("-r", dest="reports", help="show reports")
	# @HandleVerbosityOptions
	def HandleXstCompilation(self, args):
		self.PrintHeadline()
		self.__PrepareForSynthesis()
		self._CheckISEEnvironment()

		fqnList =	self._ExtractFQNs(args.FQN, defaultType=EntityTypes.NetList)
		board =		self._ExtractBoard(args.BoardName, args.DeviceName)

		# prepare some paths
		self.Directories["XSTFiles"] =				self.Directories["PoCRoot"] / self.PoCConfig['CONFIG.DirectoryNames']['ISESynthesisFiles']
		self.Directories["XSTTemp"] =					self.Directories["PoCTemp"] / self.PoCConfig['CONFIG.DirectoryNames']['ISESynthesisFiles']
		self.Directories["ISEInstallation"] = Path(self.PoCConfig['INSTALL.Xilinx.ISE']['InstallationDirectory'])
		self.Directories["ISEBinary"] =				Path(self.PoCConfig['INSTALL.Xilinx.ISE']['BinaryDirectory'])
		iseBinaryPath =												self.Directories["ISEBinary"]
		iseVersion =													self.PoCConfig['INSTALL.Xilinx.ISE']['Version']

		compiler = XSTCompiler(self, args.logs, args.reports, self.DryRun, args.NoCleanUp)
		compiler.PrepareCompiler(iseBinaryPath, iseVersion)
		compiler.RunAll(fqnList, board)

		Exit.exit()


	# ----------------------------------------------------------------------------
	# create the sub-parser for the "quartus" command
	# ----------------------------------------------------------------------------
	@CommandGroupAttribute("Synthesis commands")
	@CommandAttribute("quartus", help="Compile a PoC IP core with Altera Quartus II Map to a netlist")
	@ArgumentAttribute(metavar="<PoC Entity>", dest="FQN", type=str, nargs='+', help="todo help")
	@ArgumentAttribute('--device', metavar="<DeviceName>", dest="DeviceName", help="The target platform's device name.")
	@ArgumentAttribute('--board', metavar="<BoardName>", dest="BoardName", help="The target platform's board name.")
	@SwitchArgumentAttribute("--no-cleanup", dest="NoCleanUp", help="Don't delete intermediate files. Skip post-delete rules.")
	@SwitchArgumentAttribute("-l", dest="logs", help="show logs")
	@SwitchArgumentAttribute("-r", dest="reports", help="show reports")
	# @HandleVerbosityOptions
	def HandleQuartusCompilation(self, args):
		self.PrintHeadline()
		self.__PrepareForSynthesis()

		# TODO: check env variables
		# self._CheckQuartusIIEnvironment()

		fqnList =	self._ExtractFQNs(args.FQN, defaultType=EntityTypes.NetList)
		board =		self._ExtractBoard(args.BoardName, args.DeviceName)

		# prepare some paths
		self.Directories["QuartusTemp"] =					self.Directories["PoCTemp"] / self.PoCConfig['CONFIG.DirectoryNames']['QuartusSynthesisFiles']
		self.Directories["QuartusInstallation"] = Path(self.PoCConfig['INSTALL.Altera.QuartusII']['InstallationDirectory'])
		self.Directories["QuartusBinary"] =				Path(self.PoCConfig['INSTALL.Altera.QuartusII']['BinaryDirectory'])
		quartusBinaryPath =												self.Directories["QuartusBinary"]
		quartusVersion =													self.PoCConfig['INSTALL.Altera.QuartusII']['Version']

		compiler = MapCompiler(self, args.logs, args.reports, self.DryRun, args.NoCleanUp)
		compiler.PrepareCompiler(quartusBinaryPath, quartusVersion)
		compiler.RunAll(fqnList, board)

		Exit.exit()


	# ----------------------------------------------------------------------------
	# create the sub-parser for the "lattice" command
	# ----------------------------------------------------------------------------
	@CommandGroupAttribute("Synthesis commands")
	@CommandAttribute("lattice", help="Compile a PoC IP core with Lattice Diamond LSE to a netlist")
	@ArgumentAttribute(metavar="<PoC Entity>", dest="FQN", type=str, nargs='+', help="todo help")
	@ArgumentAttribute('--device', metavar="<DeviceName>", dest="DeviceName", help="The target platform's device name.")
	@ArgumentAttribute('--board', metavar="<BoardName>", dest="BoardName", help="The target platform's board name.")
	@SwitchArgumentAttribute("--no-cleanup", dest="NoCleanUp", help="Don't delete intermediate files. Skip post-delete rules.")
	@SwitchArgumentAttribute("-l", dest="logs", help="show logs")
	@SwitchArgumentAttribute("-r", dest="reports", help="show reports")
	# @HandleVerbosityOptions
	def HandleLatticeCompilation(self, args):
		self.PrintHeadline()
		self.__PrepareForSynthesis()

		# TODO: check env variables
		# self._CheckLatticeEnvironment()

		fqnList =	self._ExtractFQNs(args.FQN, defaultType=EntityTypes.NetList)
		board =		self._ExtractBoard(args.BoardName, args.DeviceName)

		# prepare some paths
		self.Directories["LatticeTemp"] =					self.Directories["PoCTemp"] / self.PoCConfig['CONFIG.DirectoryNames']['LatticeSynthesisFiles']
		self.Directories["LatticeInstallation"] = Path(self.PoCConfig['INSTALL.Lattice.Diamond']['InstallationDirectory'])
		self.Directories["LatticeBinary"] =				Path(self.PoCConfig['INSTALL.Lattice.Diamond']['BinaryDirectory'])
		diamondBinaryPath =												self.Directories["LatticeBinary"]
		diamondVersion =													self.PoCConfig['INSTALL.Lattice.Diamond']['Version']

		compiler = LSECompiler(self, args.logs, args.reports, self.DryRun, args.NoCleanUp)
		compiler.PrepareCompiler(diamondBinaryPath, diamondVersion)
		compiler.RunAll(fqnList, board)

		Exit.exit()


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
		print("{RED}ERROR:{NOCOLOR} {message}".format(message=ex.message, **Init.Foreground))
		cause = ex.__cause__
		if isinstance(cause, FileNotFoundError):
			print("{YELLOW}  FileNotFound:{NOCOLOR} '{cause}'".format(cause=str(cause), **Init.Foreground))
		elif isinstance(cause, DuplicateOptionError):
			print("{YELLOW}  DuplicateOptionError:{NOCOLOR} '{cause}'".format(cause=str(cause), **Init.Foreground))
		elif isinstance(cause, ConfigParser_Error):
			print("{YELLOW}  configparser.Error:{NOCOLOR} '{cause}'".format(cause=str(cause), **Init.Foreground))
		elif isinstance(cause, ParserException):
			print("{YELLOW}  ParserException:{NOCOLOR} {cause}".format(cause=str(cause), **Init.Foreground))
			cause = cause.__cause__
			if (cause is not None):
				print("{YELLOW}    {name}:{NOCOLOR} {cause}".format(name=cause.__class__.__name__, cause= str(cause), **Init.Foreground))
		elif isinstance(cause, ToolChainException):
			print("{YELLOW}  {name}:{NOCOLOR} {cause}".format(name=cause.__class__.__name__, cause=str(cause), **Init.Foreground))
			cause = cause.__cause__
			if (cause is not None):
				if isinstance(cause, OSError):
					print("{YELLOW}    {name}:{NOCOLOR} {cause}".format(name=cause.__class__.__name__, cause=str(cause), **Init.Foreground))
			else:
				print("  Possible causes:")
				print("   - The compile order is broken.")
				print("   - A source file was not compile and an old file got used.")

		if (not (verbose or debug)):
			print()
			print("{CYAN}  Use '-v' for verbose or '-d' for debug to print out extended messages.{NOCOLOR}".format(**Init.Foreground))
		Exit.exit(1)

	except EnvironmentException as ex:					Exit.printEnvironmentException(ex)
	except NotConfiguredException as ex:				Exit.printNotConfiguredException(ex)
	except PlatformNotSupportedException as ex:	Exit.printPlatformNotSupportedException(ex)
	except ExceptionBase as ex:									Exit.printExceptionbase(ex)
	except NotImplementedError as ex:						Exit.printNotImplementedError(ex)
	# except Exception as ex:											Exit.printException(ex)

# entry point
if __name__ == "__main__":
	Exit.versionCheck((3,4,0))
	main()
else:
	Exit.printThisIsNoLibraryFile(PoC.HeadLine)
