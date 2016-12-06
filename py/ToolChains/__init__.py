# EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#
# Python package:   Contains PoC's configuration mechanism.
#
# License:
# ==============================================================================
# Copyright 2007-2016 Technische Universitaet Dresden - Germany
#                     Chair of VLSI-Design, Diagnostics and Architecture
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
#
# load dependencies
from collections        import OrderedDict, namedtuple
from enum               import unique, Enum
from pathlib            import Path

from lib.Functions      import Init, CallByRefBoolParam
from Base               import ILogable, IHost
from Base.Exceptions    import ExceptionBase
from Base.Logging       import Severity


__api__ = [
	'ToolChainException',
	'ConfigurationException',
	'SkipConfigurationException',
	'ConfigurationState',
	'ChangeState',
	'ToolMixIn',
	'AskMixIn',
	'Configuration',
	'VendorConfiguration',
	'ToolConfiguration',
	'EditionDescription',
	'Edition',
	'ToolSelector',
	'Configurator'
]
__all__ = __api__


class ToolChainException(ExceptionBase):
	"""Base class for all tool specific exceptions"""

class ConfigurationException(ExceptionBase):
	"""``ConfigurationException`` is raise while running configuration or database
	tasks in PoC
	"""

class SkipConfigurationException(ExceptionBase):
	"""``SkipConfigurationException`` is a :py:exc:`ConfigurationException`,
	which can be skipped.
	"""


@unique
class ConfigurationState(Enum):
	"""Describes the configuration state of a tool or vendor."""
	Unconfigured =  0
	Configured =    1

	def __bool__(self):
		return self is self.Configured

@unique
class ChangeState(Enum):
	"""Describes if a configuration was changed."""
	Unchanged =   0
	Changed =     1

	def __bool__(self):
		return self is self.Changed


class ToolMixIn:
	def __init__(self, platform, dryrun, binaryDirectoryPath, version, logger=None):
		self._platform =            platform
		self._dryrun =              dryrun
		self._binaryDirectoryPath = binaryDirectoryPath
		self._version =             version
		self._logger =              logger


class AskMixIn:
	def _Ask(self, question, default, beforeDefault="", afterDefault="", indent=1):
		question += " [{beforeDefault!s}{CYAN}{default!s}{NOCOLOR}{afterDefault!s}]: "
		self.LogNormal(question.format(beforeDefault=beforeDefault, default=default, afterDefault=afterDefault, **Init.Foreground), indent=indent, appendLinebreak=False)
		print(Init.Foreground["GREEN"], end="")
		answer = input()
		print(Init.Foreground["NOCOLOR"], end="")

		if (answer == ""):
			answer = default
			question = "\x1B[1A" + question + "{GREEN}{default!s}{NOCOLOR}" # cursor 1 up
			self.LogNormal(question.format(beforeDefault=beforeDefault, default=default, afterDefault=afterDefault, **Init.Foreground), indent=indent)
		return answer

	def _Ask_YesNoPass(self, question, indent=1):
		"""Ask a YES/no/pass question."""
		while True:
			isInstalled = self._Ask(question, default="Y", afterDefault="/n/p", indent=indent)
			if (isInstalled in ['p', 'P']):
				raise SkipConfigurationException()
			elif (isInstalled in ['n', 'N']):
				return False
			elif (isInstalled in ['y', 'Y']):
				return True
			else:
				self.LogNormal("Unsupported choice '{0}'".format(isInstalled), indent=indent)

	def _AskYes_NoPass(self, question, indent=1):
		"""Ask a yes/NO/pass question."""
		while True:
			isInstalled = self._Ask(question, default="N", beforeDefault="y/", afterDefault="/p", indent=indent)
			if (isInstalled in ['p', 'P']):
				raise SkipConfigurationException()
			elif (isInstalled in ['n', 'N']):
				return False
			elif (isInstalled in ['y', 'Y']):
				return True
			else:
				self.LogNormal("Unsupported choice '{0}'".format(isInstalled), indent=indent)

	def _PrintAvailableEditions(self, editions, selectedEdition):
		"""Print all available editions and return the selected index."""
		if (not isinstance(editions, (list, tuple))):
			editions = list(editions)

		selectedIndex = 0
		for i, item in enumerate(editions):
			if (item is selectedEdition):
				self.LogNormal("{DARK_CYAN}{0}: {1!s}{NOCOLOR}".format(i, item.Name, **Init.Foreground), indent=2)
				selectedIndex = i
			else:
				self.LogNormal("{0}: {1!s}".format(i, item.Name), indent=2)

		return selectedIndex


class Configuration(ILogable, AskMixIn):    #(ISubClassRegistration):
	"""Base class for all Configuration classes."""

	_vendor =               "Unknown"           #: The name of the tools vendor.
	_section =              "INSTALL.Name"      #: The name of the configuration section. Pattern: ``INSTALL.Tool``.
	_multiVersionSupport =  False               #: True if a tool supports multiple versions installed on the same system.
	_template =   {
		"ALL":      {   _section: {}  },
		"Darwin":   {   _section: {}  },
		"Linux":    {   _section: {}  },
		"Windows":  {   _section: {}  }
	}                                   #: The template for the configuration sections represented as nested dictionaries.

	def __init__(self, host : IHost):
		"""Class initializer."""
		self._host =    host
		self._state =   self.IsConfigured()
		self._changed = ChangeState.Unchanged

		ILogable.__init__(self, host.Logger if isinstance(host, ILogable) else None)

	@property
	def Host(self):
		"""Return the hosting object."""
		return self._host

	@property
	def State(self):
		"""Return the configuration state."""
		return self._state

	@property
	def SectionName(self):
		"""Return the configuration's section name."""
		return self._section

	def IsSupportedPlatform(self):
		"""Return true if the given platform is supported by this configuration routine."""
		return ('ALL' in self._template) or (self._host.Platform in self._template)

	def IsConfigured(self):
		"""Return true if the configurations section is configured"""
		if self._host.PoCConfig.has_section(self._section):
			optionCount = len(self._host.PoCConfig.options(self._section))
			if (optionCount > 0):
				return ConfigurationState.Configured

		return ConfigurationState.Unconfigured

	def CheckDependency(self):
		"""Check if all vendor or tool dependencies are fulfilled to configure this tool."""
		return True

	@classmethod
	def GetSections(cls, platform):
		"""Return all section names for this configuration."""
		if ("ALL" in cls._template):
			for sectionName in cls._template['ALL']:
				yield sectionName
		if (platform in cls._template):
			for sectionName in cls._template[platform]:
				yield sectionName

	def PrepareSections(self, warningWasWritten, writeWarnings=True):
		pocConfig = self._host.PoCConfig
		for platform in ["ALL", self._host.Platform]:
			if (platform in self._template):
				for sectionName, section in self._template[platform].items():
					if (not pocConfig.has_section(sectionName)):
						self.LogWarning("WARNING: Adding new sections to configuration...", condition=(writeWarnings and not warningWasWritten))
						warningWasWritten |= True

						self.LogVerbose("Adding [{0}]".format(sectionName), condition=writeWarnings)
						pocConfig[sectionName] = OrderedDict()

	def ClearSection(self, writeWarnings=False):
		"""Clear the configuration section associated to this Configuration class."""
		self.LogWarning("WARNING: Clearing section '{0}'...".format(self._section), condition=writeWarnings, indent=1)
		self._host.PoCConfig[self._section] = OrderedDict()
		if self._multiVersionSupport:
			warningWasWritten = False
			sectionNames = [sectionName for sectionName in self._host.PoCConfig if ((len(sectionName) > len(self._section)) and sectionName.startswith(self._section))]
			for sectionName in sectionNames:
				self.LogWarning("WARNING: Removing versioned sections...", condition=(writeWarnings and not warningWasWritten), indent=1)
				self.LogWarning(sectionName, condition=writeWarnings, indent=2)
				self._host.PoCConfig.remove_section(sectionName)

	def PrepareOptions(self, writeWarnings=True):
		pocConfig = self._host.PoCConfig
		for platform in ["ALL", self._host.Platform]:
			if (platform in self._template):
				for sectionName, section in self._template[platform].items():
					warningWasWritten = False
					pocSection =        pocConfig[sectionName]

					for optionName, optionValue in section.items():
						if (not pocConfig.has_option(sectionName, optionName)):
							self.LogWarning("Adding new options to section '{0}'...".format(sectionName), condition=(writeWarnings and not warningWasWritten), indent=2)
							warningWasWritten |= True

							if (self._multiVersionSupport and isinstance(optionValue, tuple)):
								value = optionValue[0]
								if (value is not None):
									self.LogWarning("Adding {0} = {1}".format(optionName, value), condition=writeWarnings, indent=3)
									pocSection[optionName] = value
							else:
								self.LogWarning("Adding {0} = {1}".format(optionName, optionValue), condition=writeWarnings, indent=3)
								pocSection[optionName] = optionValue

	def ConfigureForDarwin(self):
		"""Start the configuration procedure for Darwin.

		This method is a wrapper for :py:meth:`ConfigureForAll`. Overwrite this
		method to implement a Darwin specific configuration routine.
		"""
		self.ConfigureForAll()

	def ConfigureForLinux(self):
		"""Start the configuration procedure for Linux.

		This method is a wrapper for :py:meth:`ConfigureForAll`. Overwrite this
		method to implement a Linux specific configuration routine.
		"""
		self.ConfigureForAll()

	def ConfigureForWindows(self):
		"""Start the configuration procedure for Windows.

		This method is a wrapper for :py:meth:`ConfigureForAll`. Overwrite this
		method to implement a Windows specific configuration routine.
		"""
		self.ConfigureForAll()

	def ConfigureForAll(self):
		"""Start a generic (platform independent) configuration procedure.

		Overwrite this method to implement a generic configuration routine for a
		(tool) Configuration class.
		"""
		raise NotImplementedError("Either ``ConfigureForAll()`` or one of the platform specific ``ConfigureFor***()`` methods must be overwritten.")

	def __str__(self):
		"""Return the vendor name."""
		return self._vendor

	def _AskInstalled(self, question):
		"""Ask a Yes/No/Pass question."""
		return self._Ask_YesNoPass(question)

	def _ConfigureInstallationDirectory(self):
		"""
		Asks for installation directory and updates section.
		Checks if entered directory exists and returns Path object.
		If no installation directory was configured before, then _GetDefaultInstallationDir is called.
		"""
		# if self._host.PoCConfig.has_option(self._section, 'InstallationDirectory'):
		defaultPath = Path(self._host.PoCConfig[self._section]['InstallationDirectory'])
		# else:
		# 	unresolved = self._GetDefaultInstallationDirectory() # may return an unresolved configuration string
		# 	self._host.PoCConfig[self._section]['InstallationDirectory'] = unresolved # create entry
		# 	defaultPath = Path(self._host.PoCConfig[self._section]['InstallationDirectory']) # resolve entry

		question = "{0!s} installation directory".format(self)
		installPath = self._Ask(question, default=defaultPath)
		if isinstance(installPath, str):
			installPath = Path(installPath)

		if (not installPath.exists()):
			raise ConfigurationException("{0!s} installation directory '{1!s}' does not exist.".format(self, installPath))  \
				from NotADirectoryError(str(installPath))

		if installPath != defaultPath: # update only if user entered something
			if self._multiVersionSupport:
				sectionName = self._host.PoCConfig[self._section]['SectionName']
			else:
				sectionName = self._section

			self._host.PoCConfig[sectionName]['InstallationDirectory'] = installPath.as_posix()
			self._host.PoCConfig.Interpolation.clear_cache()

		return installPath

	def _GetDefaultInstallationDirectory(self):
		"""Return unresolved default installation directory (str) from template.

		Overwrite function in sub-class for automatic search of installation directory.
		"""
		return self._GetDefaultOptionValue('InstallationDirectory')

	def _GetDefaultOptionValue(self, optionName):
		for platform in ["ALL", self._host.Platform]:
			if (platform in self._template):
				platformDict = self._template[platform]
				if (self._section in platformDict):
					sectionDict = platformDict[self._section]
					if (optionName in sectionDict):
						optionValue = sectionDict[optionName]
						if self._multiVersionSupport:
							return optionValue[1]
						else:
							return optionValue

	def _TestDefaultInstallPath(self, defaults):
		"""Helper function for automatic search of installation directory."""
		if (self._host.Platform == "Windows"):
			for drive in "CDEFGH":
				defaultPathNames = defaults["Windows"]
				if (not isinstance(defaultPathNames, (list, tuple))):
					defaultPathNames = (defaultPathNames)
				for pathName in defaultPathNames:
					defaultInstallPath = Path("{0}:/{1}".format(drive, pathName))
					try:
						if (defaultInstallPath.exists()):
							return defaultInstallPath
					except OSError:
						pass
		else:
			defaultPathNames = defaults[self._host.Platform]
			if (not isinstance(defaultPathNames, (list, tuple))):
				defaultPathNames = (defaultPathNames)

			for pathName in defaultPathNames:
				defaultInstallPath = Path("/opt") / pathName
				print("testing: {0!s}".format(defaultInstallPath))
				try:
					if (defaultInstallPath.exists()):
						return defaultInstallPath
				except OSError:
					pass

				defaultInstallPath = Path("/opt") / pathName.lower()
				print("testing: {0!s}".format(defaultInstallPath))
				try:
					if (defaultInstallPath.exists()):
						return defaultInstallPath
				except OSError:
					pass

		return None

	def RunPostConfigurationTasks(self):
		"""Virtual method. Overwrite to execute post-configuration tasks."""
		pass


class VendorConfiguration(Configuration):
	"""Base class for all vendor Configuration classes."""
	_section =      "INSTALL.Vendor.Tool"  #: The name of the configuration section. Pattern: ``INSTALL.Vendor``.
	_template = {
		"Darwin": {
			_section: {
				"InstallationDirectory":  "/opt/Vendor",
			}
		},
		"Linux": {
			_section: {
				"InstallationDirectory":  "/opt/Vendor",
			}
		},
		"Windows": {
			_section: {
				"InstallationDirectory":  "C:/Vendor",
			}
		}
	}  #: The template for the configuration section represented as nested dictionaries.

	# Method aliases
	IsConfigured = Configuration.IsConfigured
	"""Return true if the vendor represented by this Configuration class is
	configured in PoC.

	Inherited method :py:meth:`~Configuration.IsConfigured` from class
	:py:class:`Configuration`.
	"""

	def ConfigureForAll(self):
		"""Start a generic (platform independent) vendor configuration procedure.

		This method configures a vendor path. Overwrite this method to implement a
		vendor specific configuration routine for a vendor Configuration class.
		"""
		try:
			if (not self._AskInstalled("Are {0} products installed on your system?".format(self._vendor))):
				self.ClearSection()
			else:
				self._ConfigureInstallationDirectory()
		except SkipConfigurationException:
			if (self._state is not ConfigurationState.Configured):
				self.ClearSection()
			raise


class ToolConfiguration(Configuration):
	"""Base class for all tool Configuration classes."""

	_section =              "INSTALL.Vendor.Tool"  #: The name of the configuration section. Pattern: ``INSTALL.Vendor.ToolName``.
	_toolName =             "Tool"                 #: The name of the tool.
	_template = {
		"ALL": {
			_section: {
				"Version": "1.0",
			}
		},
		"Darwin": {
			_section: {
				"InstallationDirectory":  "${INSTALL.Vendor:InstallationDirectory}/${Version}/Tool",
				"BinaryDirectory":        "${InstallationDirectory}/bin"
			}
		},
		"Linux": {
			_section: {
				"InstallationDirectory":  "${INSTALL.Vendor:InstallationDirectory}/${Version}/Tool",
				"BinaryDirectory":        "${InstallationDirectory}/bin"
			}
		},
		"Windows": {
			_section: {
				"InstallationDirectory":  "${INSTALL.Vendor:InstallationDirectory}/${Version}/Tool/",
				"BinaryDirectory":        "${InstallationDirectory}/bin"
			}
		}
	}  #: The template for the configuration section represented as nested dictionaries.

	# Method aliases
	IsConfigured = Configuration.IsConfigured
	"""Return true if the tool represented by this Configuration class is
	configured in PoC.

	Inherited method :py:meth:`~Configuration.IsConfigured` from class
	:py:class:`Configuration`.
	"""

	def _ConfigureVersion(self):
		"""
		If no version was configured before, then _GetDefaultVersion is called.
		Asks for version and updates section. Returns version as string.
		"""
		# if self._host.PoCConfig.has_option(self._section, 'Version'):
		defaultVersion = self._host.PoCConfig[self._section]['Version']
		# else:
		# 	unresolved = self._GetDefaultVersion()  # may return an unresolved configuration string
		# 	self._host.PoCConfig[self._section]['Version'] = unresolved  # create entry
		# 	defaultVersion = self._host.PoCConfig[self._section]['Version']  # resolve entry

		question = "{0!s} version".format(defaultVersion)
		version = self._Ask(question, default=defaultVersion, indent=1)

		if (version != defaultVersion):   # update only if user entered something
			self._host.PoCConfig[self._section]['Version'] = version
			self._host.PoCConfig.Interpolation.clear_cache()

		return version

	def _GetDefaultVersion(self):
		"""Returns unresolved default version (str) from template.

		Overwrite this method in a sub-class for automatic search of version.
		"""
		return self._template[self._host.Platform][self._section]['Version']

	def _ConfigureEdition(self, editions, defaultEdition):
		self._host.LogNormal("  Which {0} edition is installed on the system?".format(self._toolName))
		defaultIndex = self._PrintAvailableEditions(editions, defaultEdition)

		question = "Installed edition [{CYAN}{0}{NOCOLOR}]: "
		while True:
			self._host.LogNormal(question.format(defaultIndex, **Init.Foreground), indent=1, appendLinebreak=False)
			print(Init.Foreground["GREEN"], end="")
			selectedIndex = input()
			print(Init.Foreground["NOCOLOR"], end="")

			if (selectedIndex != ""):
				# FIXME: Can I use editions.Parse()?
				selectedIndex = int(selectedIndex)
				for i, item in enumerate(editions.__members__.values()):
					if (i == selectedIndex):
						edition = item
						break
				else:
					self._host.LogError("Invalid choice.")
					continue # the outer while loop

			else:
				edition = defaultEdition
				# reprint the colored lines on console
				print("\x1B[{n}A".format(n=len(editions) + 2)) # cursor n+2 up
				self._PrintAvailableEditions(editions, edition)
				question += "{GREEN}{0}"
				self._host.LogNormal(question.format(defaultIndex, **Init.Foreground), indent=1)
			break

		return edition

	def _GetDefaultEdition(self):
		"""Returns unresolved default edition (str) from template.

		Overwrite this method in a sub-class for automatic search of editions.
		"""
		return self._template[self._host.Platform][self._section]['Edition']

	def _ConfigureBinaryDirectory(self):
		"""Updates section with value from :attr:`_template` and returns directory
		as :class:`Path <pathlib.Path>` object.
		"""
		# unresolved = self._template[self._host.Platform][self._section]['BinaryDirectory']
		# self._host.PoCConfig[self._section]['BinaryDirectory'] = unresolved  # create entry
		defaultPath = Path(self._host.PoCConfig[self._section]['BinaryDirectory'])  # resolve entry

		binPath = defaultPath  # may be more complex in the future

		if (not binPath.exists()):
			raise ConfigurationException("{0!s} binary directory '{1!s}' does not exist.".format(self, binPath)) \
				from NotADirectoryError(str(binPath))

		return binPath

	def PrepareVersionedSections(self, writeWarnings=False):
		warningWasWritten = False
		pocConfig = self._host.PoCConfig
		for platform in ["ALL", self._host.Platform]:
			if ((platform not in self._template) or (self._section not in self._template[platform])):
				continue

			sectionName = self._host.PoCConfig[self._section]['SectionName']
			if (not pocConfig.has_section(sectionName)):
				self.LogWarning("WARNING: Adding new sections to configuration...", condition=(writeWarnings and not warningWasWritten), indent=2)
				warningWasWritten |= True

				self.LogWarning("Adding [{0}]".format(sectionName), condition=writeWarnings, indent=2)
				pocConfig[sectionName] = OrderedDict()

			section = self._template[platform][self._section]
			pocSection = pocConfig[sectionName]
			for optionName, optionValue in section.items():
				if (not pocConfig.has_option(sectionName, optionName)):
					self.LogWarning("Adding new options to section '{0}'...".format(sectionName), condition=(writeWarnings and not warningWasWritten), indent=2)
					warningWasWritten |= True

					if (self._multiVersionSupport and isinstance(optionValue, tuple)):
						value = optionValue[1]
						if (value is not None):
							self.LogWarning("Adding {0} = {1}".format(optionName, value), condition=writeWarnings, indent=3)
							pocSection[optionName] = value
					else:
						self.LogWarning("Adding {0} = {1}".format(optionName, optionValue), condition=writeWarnings, indent=3)
						pocSection[optionName] = optionValue

	def __str__(self):
		"""Return the tool name."""
		return self._toolName


EditionDescription = namedtuple('EditionDescription', ['Name', 'Section'])


class Edition(Enum):
	def __new__(cls, *_, **__):
		value = len(cls.__members__) + 1
		obj = object.__new__(cls)
		obj._value_ = value
		return obj

	def __init__(self, name, section):
		self.Name = name
		self.Section = section

	@classmethod
	def Parse(cls, value):
		"""Resolve edition name to enum member"""
		for item in cls.__members__.values():
			if (item.Name == value):
				return item
		raise ValueError("Unknown enum value '{0}'.".format(value))

	def __repr__(self):
		return self.Name


class ToolSelector(ILogable, AskMixIn):
	"""Base class for all Selector classes."""
	_toolName =     ""

	def __init__(self, host: IHost):
		"""Class initializer."""
		self._host = host

		ILogable.__init__(self, host.Logger if isinstance(host, ILogable) else None)

	@property
	def ToolName(self):
		return self._toolName

	def _GetConfiguredEditions(self, editions):
		"""Return all configured editions."""
		_editions = []
		for edition in editions:
			if (len(self._host.PoCConfig[edition.Section]) > 0):
				_editions.append(edition)

		return _editions

	def _AskSelection(self, editions, defaultEdition):
		defaultIndex = self._PrintAvailableEditions(editions, defaultEdition)

		question = "Selected installation [{CYAN}{0}{NOCOLOR}]: "
		while True:
			self._host.LogNormal(question.format(defaultIndex, **Init.Foreground), indent=1, appendLinebreak=False)
			print(Init.Foreground["GREEN"], end="")
			selectedIndex = input()
			print(Init.Foreground["NOCOLOR"], end="")

			if (selectedIndex != ""):
				# FIXME: Can I use editions.Parse()?
				selectedIndex = int(selectedIndex)
				for i, item in enumerate(editions):
					if (i == selectedIndex):
						edition = item
						break
				else:
					self._host.LogError("Invalid choice.")
					continue  # the outer while loop

			else:
				edition = defaultEdition
				# reprint the colored lines on console
				print("\x1B[{n}A".format(n=len(editions) + 2)) # cursor n+2 up
				self._PrintAvailableEditions(editions, edition)
				question += "{GREEN}{0}"
				self._host.LogNormal(question.format(defaultIndex, **Init.Foreground), indent=1)
			break

		return edition


class Configurator(ILogable, AskMixIn):
	"""A instance of this class controls the interactive configuration process."""
	def __init__(self, host : IHost):
		"""Class initializier."""
		ILogable.__init__(self, host.Logger if isinstance(host, ILogable) else None)

		self._host =              host
		self._saveConfiguration = True

		from .PoC                 import Configuration as PoC_Configuration
		from .Git                 import Configuration as Git_Configuration
		from .Aldec               import Configuration as Aldec_Configuration
		from .Aldec.ActiveHDL     import Configuration as ActiveHDL_Configuration
		from .Altera              import Configuration as Altera_Configuration
		from .Altera.Quartus      import Configuration as AlteraQuartus_Configuration
		from .Altera.ModelSim     import Configuration as AlteraModelSim_Configuration
		from .Intel               import Configuration as Intel_Configuration
		from .Intel.Quartus       import Configuration as IntelQuartus_Configuration
		from .Intel.ModelSim      import Configuration as IntelModelSim_Configuration
		from .GHDL                import Configuration as GHDL_Configuration
		from .GTKWave             import Configuration as GTKW_Configuration
		from .Lattice             import Configuration as Lattice_Configuration
		from .Lattice.Diamond     import Configuration as Diamond_Configuration
		from .Lattice.ActiveHDL   import Configuration as LatticeActiveHDL_Configuration
		# from .Lattice.Symplify    import Configuration as LatticeSymplify_Configuration
		from .Mentor              import Configuration as Mentor_Configuration
		from .Mentor.ModelSim     import ModelSimPEConfiguration, ModelSimSE32Configuration, ModelSimSE64Configuration
		from .Mentor.QuestaSim    import Configuration as Questa_Configuration
		# from .Mentor.PrecisionRTL import Configuration as PrecisionRTL_Configuration
		# from .Synopsys            import Configuration as Synopsys_Configuration
		# from .Synopsys.Symplify   import Configuration as Symplify_Configuration
		from .Xilinx              import Configuration as Xilinx_Configuration
		from .Xilinx.ISE          import Configuration as ISE_Configuration
		from .Xilinx.Vivado       import Configuration as Vivado_Configuration
		#: List of all available (and thus enabled) Configuration classes.
		Configurations = [
			PoC_Configuration,
			Git_Configuration,
			# Aldec products
			Aldec_Configuration,
			ActiveHDL_Configuration,
			# Altera products
			Altera_Configuration,
			AlteraQuartus_Configuration,
			AlteraModelSim_Configuration,
			# Intel products
			Intel_Configuration,
			IntelQuartus_Configuration,
			IntelModelSim_Configuration,
			# Lattice products
			Lattice_Configuration,
			Diamond_Configuration,
			LatticeActiveHDL_Configuration,
			# Mentor products
			Mentor_Configuration,
			ModelSimPEConfiguration,
			ModelSimSE32Configuration,
			ModelSimSE64Configuration,
			Questa_Configuration,
			# Xilinx products
			Xilinx_Configuration,
			ISE_Configuration,
			Vivado_Configuration,
			# other products
			GHDL_Configuration,
			GTKW_Configuration
		]

		from .Aldec.ActiveHDL     import Selector as ActiveHDL_Selector
		from .Altera.Quartus      import Selector as Quartus_Selector
		from .Mentor.ModelSim     import Selector as ModelSim_Selector
		#: List of all available (and thus enabled) Selector classes.
		Selectors = [
			ActiveHDL_Selector,
			ModelSim_Selector,
			Quartus_Selector
		]

		self._configurators =     [configuration(self._host)  for configuration in Configurations]
		self._selectors =         [selector(self._host)       for selector      in Selectors]

	def ConfigureAll(self):
		"""Select all tool chains for configuration"""
		self._WriteConfigurationHeader()
		self._ConfigureTools(self._configurators)

		# Write and re-read configuration
		if self._saveConfiguration:
			self._host.SaveAndReloadPoCConfiguration()

	def ConfigureTool(self, toolChain):
		"""Select tool chains for configuration."""
		sectionName = ("INSTALL.{0}".format(toolChain)).lower()
		configurators = [config for config in self._configurators if (config.SectionName.lower().startswith(sectionName))]

		if (len(configurators) == 0):
			self.LogError("{RED}No configuration named '{0}' found.{NOCOLOR}".format(toolChain, **Init.Foreground))
			return

		self._WriteConfigurationHeader()
		self._ConfigureTools(configurators)

		# Write and re-read configuration
		if self._saveConfiguration:
			self._host.SaveAndReloadPoCConfiguration()

	def InitializeConfiguration(self):
		"""Initialize PoC's configuration with empty sections.

		The list of sections is gathered from all enabled configurators'
		:py:data:`_template` fields.
		"""
		warningWasWritten = CallByRefBoolParam(False)
		for configurator in self._configurators:
			configurator.PrepareSections(warningWasWritten, writeWarnings=False)

	def UpdateConfiguration(self):
		"""Update an existing configuration e.g. after a PoC update."""
		warningWasWritten = CallByRefBoolParam(False)
		for configurator in self._configurators:
			configurator.PrepareSections(warningWasWritten)

			configured = configurator.IsConfigured()
			if configured:
				configurator.PrepareOptions()

		# pocSections =    set([sectionName for sectionName in self._host.PoCConfig])
		# configSections = set([sectionName for config in Configurations for sectionName in config.GetSections(self._host.Platform)]) # FIXME: what about the ALL platform?
		# delSections = pocSections.difference(configSections)

		# if delSections:
		# 	for sectionName in delSections:
		# 		self._host.PoCConfig.remove_section(sectionName)

	def _ConfigureTools(self, configurators):
		"""Run the configuration routines for a list of configurators"""
		self.LogNormal("{CYAN}Configuring installed tools\n---------------------------{NOCOLOR}".format(**Init.Foreground))

		# Configure each vendor or tool of a tool chain
		for configurator in configurators:
			# Skip configuration with unsupported platforms
			if (not configurator.IsSupportedPlatform()):
				configurator.ClearSection()
				continue

			# Skip configuration if dependency is not fulfilled
			if (not configurator.CheckDependency()):
				configurator.ClearSection()
				continue

			# Start configuration
			self.LogNormal("{DARK_CYAN}Configuring {0!s}{NOCOLOR}".format(configurator, **Init.Foreground))

			# Start configuration loop for the current configurator
			try:
				self._ConfigurationLoop(configurator)
			except KeyboardInterrupt:
				self._saveConfiguration = False
				self.LogNormal("\n\n{RED}Abort configuration.\nNo files have been created or changed.{NOCOLOR}".format(**Init.Foreground))
				return

			# TODO: move to host instance
			# Print the currently collected configuration if in debug mode
			if (self.Logger.LogLevel is Severity.Debug):
				self.LogDebug("-" * 40, indent=1)
				for sectionName in self._host.PoCConfig.sections():
					if (not sectionName.startswith("INSTALL")):
						continue
					self.LogDebug("[{0}]".format(sectionName), indent=1)
					configSection = self._host.PoCConfig[sectionName]
					for optionName in configSection:
						optionRaw =   self._host.PoCConfig.get(sectionName, optionName, raw=True)
						try:
							optionValue = configSection[optionName]
						except Exception:
							optionValue = "-- ERROR --"

						self.LogDebug("{0: <23} {1: <90} {2}".format(optionName + " =", optionRaw, optionValue), indent=2)
				self.LogDebug("-" * 40, indent=1)

		# TODO: MultiVersion installations?

		self.LogNormal("")
		if self._AskConfigureDefaultTools():
			self._ConfigureDefaultTools()
		else:
			self.LogWarning("You can rerun this configuration step with '.\poc.ps1 configure --set-default-tools'.", indent=1)

		# Write and re-read configuration
		self._host.SaveAndReloadPoCConfiguration()

		# Run post-configuration tasks
		self.LogNormal("{DARK_CYAN}Running post configuration tasks{NOCOLOR}".format(**Init.Foreground))
		for configurator in configurators:
			configurator.RunPostConfigurationTasks()

	def _ConfigurationLoop(self, configurator):
		"""Retry to configure a vendor or tool until it succeeds or the user presses
		:kbd:`P` to pass a configuration step.

		A :py:exec:`KeyboardInterrupt` should be handled in a calling method.
		"""
		while True:
			# Copy all options for a configurator's sections from _template into PoCConfig
			configurator.PrepareOptions(writeWarnings=False)

			try:
				if (self._host.Platform == "Darwin"):     configurator.ConfigureForDarwin()
				elif (self._host.Platform == "Linux"):    configurator.ConfigureForLinux()
				elif (self._host.Platform == "Windows"):  configurator.ConfigureForWindows()

				break
			except SkipConfigurationException:
				break
			except ExceptionBase as ex:
				print("  {RED}FAULT: {0}{NOCOLOR}".format(ex.message, **Init.Foreground))# Print the currently collected configuration if in debug mode

	def ConfigureDefaultTools(self):
		self._WriteConfigurationHeader()
		self._ConfigureDefaultTools()

		# Write and re-read configuration
		if self._saveConfiguration:
			self._host.SaveAndReloadPoCConfiguration()

	def _ConfigureDefaultTools(self):
		self.LogNormal("{CYAN}Choosing default tools\n----------------------{NOCOLOR}".format(**Init.Foreground))
		for selector in self._selectors:
			self._host.LogNormal("{DARK_CYAN}Selecting {0} installation{NOCOLOR}".format(selector.ToolName, **Init.Foreground))
			try:
				selector.Select()
			except KeyboardInterrupt:
				self._saveConfiguration = False
				self.LogNormal("\n\n{RED}Abort configuration.\nNo files have been created or changed.{NOCOLOR}".format(**Init.Foreground))
				return

	def _WriteConfigurationHeader(self):
		"""Write a header containing general information about the configuration
		and list allowed input values for yes/no/pass questions.
		"""
		# self.LogVerbose("starting manual configuration...")
		self.LogNormal("Explanation of abbreviations:")
		self.LogNormal("  {YELLOW}Y{NOCOLOR} - yes      {YELLOW}P{NOCOLOR}        - pass (jump to next question)".format(**Init.Foreground))
		self.LogNormal("  {YELLOW}N{NOCOLOR} - no       {YELLOW}Ctrl + C{NOCOLOR} - abort (no changes are saved)".format(**Init.Foreground))
		self.LogNormal("Upper case or value in '[...]' means default value")
		self.LogNormal("-" * 80)
		self.LogNormal("")

	def _AskConfigureDefaultTools(self):
		"""Ask if default tools should be configured now."""
		while True:
			configureDefaultTools = self._Ask("Configure default tools?", default="Y", afterDefault="/n", indent=0)
			if (configureDefaultTools in ['n', 'N']):
				return False
			elif (configureDefaultTools in ['y', 'Y']):
				return True
			else:
				self.LogNormal("Unsupported choice '{0}'".format(configureDefaultTools))
