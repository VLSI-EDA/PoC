# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#                   Thomas B. Preusser
#
# Python Class:     Mentor Graphics ModelSim specific classes
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
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================
#
# load dependencies
from collections                  import OrderedDict
from enum                         import unique, Enum
from re                           import compile as re_compile
from subprocess                   import check_output
from textwrap                     import dedent

from flags import Flags

from lib.Functions                import Init, CallByRefParam
from Base.Exceptions              import PlatformNotSupportedException
from Base.Executable              import ExecutableArgument, ShortFlagArgument, ShortTupleArgument, StringArgument, PathArgument, CommandLineArgumentList, DryRunException, \
	ShortOptionalValuedFlagArgument, OptionalValuedFlagArgument
from Base.Logging                 import Severity, LogEntry
from DataBase.Entity              import SimulationResult
from ToolChain                    import ConfigurationException, EditionDescription, Edition, ToolConfiguration, ToolSelector, ToolMixIn, OutputFilteredExecutable
from ToolChain.Mentor             import MentorException
from Simulator                    import PoCSimulationResultFilter, PoCSimulationResultNotFoundException


__api__ = [
	'ModelSimException',
	'MentorModelSimPEEditions',
	'ModelSimEditions',
	'Configuration',
	'ModelSimPEConfiguration',
	'ModelSimSE32Configuration',
	'ModelSimSE64Configuration',
	'Selector',
	'ModelSim',
	'VHDLLibraryTool',
	'VHDLCompiler',
	'VHDLSimulator',
	'VLibFilter',
	'VComFilter',
	'VSimFilter'
]
__all__ = __api__


class ModelSimException(MentorException):
	pass


@unique
class MentorModelSimPEEditions(Edition):
	"""Enumeration of all ModelSim editions provided by Mentor Graphics itself."""
	ModelSimPE =            EditionDescription(Name="ModelSim PE",                    Section=None)
	ModelSimPEEducation =   EditionDescription(Name="ModelSim PE (Student Edition)",  Section=None)

@unique
class ModelSimEditions(Edition):
	"""Enumeration of all ModelSim editions provided by Mentor Graphics inclusive
	editions shipped by other vendors.
	"""
	ModelSimPE =                    EditionDescription(Name="ModelSim PE",                      Section="INSTALL.Mentor.ModelSimPE")
	ModelSimDE =                    EditionDescription(Name="ModelSim DE",                      Section="INSTALL.Mentor.ModelSimDE")
	ModelSimSE32 =                  EditionDescription(Name="ModelSim SE 32-bit",               Section="INSTALL.Mentor.ModelSimSE32")
	ModelSimSE64 =                  EditionDescription(Name="ModelSim SE 64-bit",               Section="INSTALL.Mentor.ModelSimSE64")
	ModelSimAlteraEdition =         EditionDescription(Name="ModelSim Altera Edition",          Section="INSTALL.Altera.ModelSimAE")
	ModelSimAlteraStarterEdition =  EditionDescription(Name="ModelSim Altera Starter Edition",  Section="INSTALL.Altera.ModelSimASE")
	ModelSimIntelEdition =          EditionDescription(Name="ModelSim Intel Edition",           Section="INSTALL.Intel.ModelSimAE")
	ModelSimIntelStarterEdition =   EditionDescription(Name="ModelSim Intel Starter Edition",   Section="INSTALL.Intel.ModelSimASE")
	QuestaSim =                     EditionDescription(Name="QuestaSim",                        Section="INSTALL.Mentor.QuestaSim")


class Configuration(ToolConfiguration):
	_vendor =               "Mentor"                    #: The name of the tools vendor.
	_toolName =             "Mentor ModelSim"           #: The name of the tool.
	_multiVersionSupport =  True                        #: Mentor ModelSim supports multiple versions installed on the same system.

	def CheckDependency(self):
		"""Check if general Mentor Graphics support is configured in PoC."""
		return (len(self._host.PoCConfig['INSTALL.Mentor']) != 0)

	def ConfigureForAll(self):
		"""Configuration routine for Mentor Graphics ModelSim on all supported platforms.

		#. Ask if ModelSim is installed.

		  * Pass |rarr| skip this configuration. Don't change existing settings.
		  * Yes |rarr| collect installation information for ModelSim.
		  * No |rarr| clear the ModelSim configuration section.

		#. Ask for ModelSim's version.
		#. Ask for ModelSim's edition (PE, PE student, SE 32-bit, SE 64-bit).
		#. Ask for ModelSim's installation directory.
		"""
		try:
			if (not self._AskInstalled("Is {0} installed on your system?".format(self._toolName))):
				self.ClearSection()
			else:
				# Configure ModelSim version
				version = self._ConfigureVersion()
				if self._multiVersionSupport:
					self.PrepareVersionedSections()
					sectionName = self._host.PoCConfig[self._section]['SectionName']
					self._host.PoCConfig[sectionName]['Version'] = version

				self._ConfigureEdition()

				self._ConfigureInstallationDirectory()
				binPath = self._ConfigureBinaryDirectory()
				self._CheckModelSimVersion(binPath, version)
				self._host.LogNormal("{DARK_GREEN}{0} is now configured.{NOCOLOR}".format(self._toolName, **Init.Foreground), indent=1)
		except ConfigurationException:
			self.ClearSection()
			raise

	def _GetModelSimVersion(self, binPath):
		if (self._host.Platform == "Windows"):
			vsimPath = binPath / "vsim.exe"
		else:
			vsimPath = binPath / "vsim"

		if not vsimPath.exists():
			raise ConfigurationException("Executable '{0!s}' not found.".format(vsimPath)) from FileNotFoundError(
				str(vsimPath))

		# get version and backend
		try:
			output = check_output([str(vsimPath), "-version"], universal_newlines=True)
		except OSError as ex:
			raise ConfigurationException("Error while accessing '{0!s}'.".format(vsimPath)) from ex

		version = None
		versionRegExpStr = r"^.* vsim (.+?) "
		versionRegExp = re_compile(versionRegExpStr)
		for line in output.split('\n'):
			if version is None:
				match = versionRegExp.match(line)
				if match is not None:
					version = match.group(1)

		print(self._section, version)

		self._host.PoCConfig[self._section]['Version'] = version

	def _CheckModelSimVersion(self, binPath, version):
		if (self._host.Platform == "Windows"):
			vsimPath = binPath / "vsim.exe"
		else:
			vsimPath = binPath / "vsim"

		if not vsimPath.exists():
			raise ConfigurationException("Executable '{0!s}' not found.".format(vsimPath)) from FileNotFoundError(
				str(vsimPath))

		output = check_output([str(vsimPath), "-version"], universal_newlines=True)
		if str(version) not in output:
			raise ConfigurationException("ModelSim version mismatch. Expected version {0}.".format(version))

	# def _ConfigureEdition(self):
	# 	pass

	def RunPostConfigurationTasks(self):
		if (len(self._host.PoCConfig[self._section]) == 0): return  # exit if not configured

		precompiledDirectory =  self._host.PoCConfig['CONFIG.DirectoryNames']['PrecompiledFiles']
		vSimSimulatorFiles =    self._host.PoCConfig['CONFIG.DirectoryNames']['ModelSimFiles']
		vsimPath =              self._host.Directories.Root / precompiledDirectory / vSimSimulatorFiles
		modelsimIniPath =       vsimPath / "modelsim.ini"

		if not vsimPath.exists():
			self.LogVerbose("Creating directory for ModelSim files.")
			try:
				self.LogDebug("Creating directory '{0!s}'.".format(vsimPath))
				vsimPath.mkdir(parents=True)
			except OSError as ex:
				raise ConfigurationException("Error while creating '{0!s}'.".format(vsimPath)) from ex
		else:
			self.LogDebug("Directory for ModelSim files already exists.")

		if not modelsimIniPath.exists():
			self.LogVerbose("Creating initial 'modelsim.ini' file.")
			self.LogDebug("Writing initial 'modelsim.ini' file to '{0!s}'.".format(modelsimIniPath))
			try:
				with modelsimIniPath.open('w') as fileHandle:
					fileContent = dedent("""\
						[Library]
						others = $MODEL_TECH/../modelsim.ini
						""")
					fileHandle.write(fileContent)
			except OSError as ex:
				raise ConfigurationException("Error while creating '{0!s}'.".format(modelsimIniPath)) from ex
		else:
			self.LogVerbose("ModelSim configuration file '{0!s}' already exists.".format(modelsimIniPath))


class ModelSimPEConfiguration(Configuration):
	_toolName =             "Mentor ModelSim PE"          #: The name of the tool.
	_section  =             "INSTALL.Mentor.ModelSimPE"   #: The name of the configuration section. Pattern: ``INSTALL.Vendor.ToolName``.
	_template = {
		"Windows": {
			_section: {
				"Version":                "10.5c",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"Edition":                "ModelSim PE",
				"ToolInstallationName":   "ModelSim PE",
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Mentor:InstallationDirectory}/${ToolInstallationName}/${Version}"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/win32pe"),
				"AdditionalVComOptions":  ("${${SectionName}:AdditionalVComOptions}", ""),
				"AdditionalVSimOptions":  ("${${SectionName}:AdditionalVSimOptions}", "")
			}
		}
	}                                                     #: The template for the configuration sections represented as nested dictionaries.

	def _ConfigureEdition(self):
		"""Configure ModelSim PE for Mentor Graphics."""
		sectionName = self._section
		if self._multiVersionSupport:
			sectionName = self._host.PoCConfig[sectionName]['SectionName']

		configSection = self._host.PoCConfig[sectionName]
		defaultEdition = MentorModelSimPEEditions.Parse(configSection['Edition'])
		edition = super()._ConfigureEdition(MentorModelSimPEEditions, defaultEdition)

		if (edition is not defaultEdition):
			configSection['Edition'] = edition.Name
			self._host.PoCConfig.Interpolation.clear_cache()

		if self._multiVersionSupport:
			sectionName = self._host.PoCConfig[self._section]['SectionName']
		else:
			sectionName = self._section

		configSection =   self._host.PoCConfig[sectionName]
		binaryDirectory = self._host.PoCConfig.get(sectionName, 'BinaryDirectory', raw=True)
		if (edition is MentorModelSimPEEditions.ModelSimPE):
			toolInstallationName =  "ModelSim PE"
			binaryDirectory =       binaryDirectory.replace("win32peedu", "win32pe")
		elif (edition is MentorModelSimPEEditions.ModelSimPEEducation):
			toolInstallationName =  "ModelSim PE Student Edition"
			binaryDirectory =       binaryDirectory.replace("win32pe", "win32pe_edu")
		else:
			toolInstallationName =  None

		configSection['ToolInstallationName'] = toolInstallationName
		configSection['BinaryDirectory'] =      binaryDirectory


class ModelSimDEConfiguration(Configuration):
	_toolName =             "Mentor ModelSim DE"          #: The name of the tool.
	_section  =             "INSTALL.Mentor.ModelSimDE"   #: The name of the configuration section. Pattern: ``INSTALL.Vendor.ToolName``.
	_template = {
		"Linux": {
			_section: {
				"Version":                "10.5c",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"Edition":                "ModelSim DE",
				"ToolInstallationName":   "ModelSim DE",
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Mentor:InstallationDirectory}/${ToolInstallationName}/${Version}"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/linuxpe"),
				"AdditionalVComOptions":  ("${${SectionName}:AdditionalVComOptions}", ""),
				"AdditionalVSimOptions":  ("${${SectionName}:AdditionalVSimOptions}", "")
			}
		}
	}                                                     #: The template for the configuration sections represented as nested dictionaries.

	def _ConfigureEdition(self):
		pass


class ModelSimSE32Configuration(Configuration):
	_toolName =             "Mentor ModelSim SE 32-bit"   #: The name of the tool.
	_section  =             "INSTALL.Mentor.ModelSimSE32" #: The name of the configuration section. Pattern: ``INSTALL.Vendor.ToolName``.
	_template = {
		"Windows": {
			_section: {
				"Version":                "10.5c",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"Edition":                "ModelSim SE 32-bit",
				"ToolInstallationName":   "ModelSim SE",
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Mentor:InstallationDirectory}/${ToolInstallationName}/${Version}"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/win32"),
				"AdditionalVComOptions":  ("${${SectionName}:AdditionalVComOptions}", ""),
				"AdditionalVSimOptions":  ("${${SectionName}:AdditionalVSimOptions}", "")
			}
		}
	}                                                     #: The template for the configuration sections represented as nested dictionaries.

	def _ConfigureEdition(self):
		pass


class ModelSimSE64Configuration(Configuration):
	_toolName =             "Mentor ModelSim SE 64-bit"   #: The name of the tool.
	_section  =             "INSTALL.Mentor.ModelSimSE64" #: The name of the configuration section. Pattern: ``INSTALL.Vendor.ToolName``.
	_template = {
		"Windows": {
			_section: {
				"Version":                "10.5c",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"Edition":                "ModelSim SE 64-bit",
				"ToolInstallationName":   "ModelSim SE",
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Mentor:InstallationDirectory}/${ToolInstallationName}/${Version}"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/win64"),
				"AdditionalVComOptions":  ("${${SectionName}:AdditionalVComOptions}", ""),
				"AdditionalVSimOptions":  ("${${SectionName}:AdditionalVSimOptions}", "")
			}
		},
		"Linux": {
			_section: {
				"Version":                "10.5c",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"Edition":                "ModelSim SE 64-bit",
				"ToolInstallationName":   "ModelSim_SE",
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Mentor:InstallationDirectory}/${ToolInstallationName}/${Version}"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/linux_x86_64"),
				"AdditionalVComOptions":  ("${${SectionName}:AdditionalVComOptions}", ""),
				"AdditionalVSimOptions":  ("${${SectionName}:AdditionalVSimOptions}", "")
			}
		}
	}                                                     #: The template for the configuration sections represented as nested dictionaries.

	def _ConfigureEdition(self):
		pass


class Selector(ToolSelector):
	_toolName = "ModelSim"

	def Select(self):
		editions = self._GetConfiguredEditions(ModelSimEditions)

		if (len(editions) == 0):
			self._host.LogWarning("No ModelSim installation found.", indent=1)
			self._host.PoCConfig['INSTALL.ModelSim'] = OrderedDict()
		elif (len(editions) == 1):
			self._host.LogNormal("Default ModelSim installation:", indent=1)
			self._host.LogNormal("Set to {0}".format(editions[0].Name), indent=2)
			self._host.PoCConfig['INSTALL.ModelSim']['SectionName'] = editions[0].Section
		else:
			self._host.LogNormal("Select ModelSim installation:", indent=1)

			defaultEdition = ModelSimEditions.ModelSimSE64
			if defaultEdition not in editions:
				defaultEdition = editions[0]

			selectedEdition = self._AskSelection(editions, defaultEdition)
			self._host.PoCConfig['INSTALL.ModelSim']['SectionName'] = selectedEdition.Section


class ModelSim(ToolMixIn):
	def GetVHDLLibraryTool(self):
		return VHDLLibraryTool(self)

	def GetVHDLCompiler(self):
		return VHDLCompiler(self)

	def GetSimulator(self):
		return VHDLSimulator(self)


class VHDLLibraryTool(OutputFilteredExecutable, ToolMixIn):
	def __init__(self, toolchain: ToolMixIn):
		ToolMixIn.__init__(
			self, toolchain._platform, toolchain._dryrun, toolchain._binaryDirectoryPath, toolchain._version,
			toolchain._logger)

		if (self._platform == "Windows"):
			executablePath = self._binaryDirectoryPath / "vlib.exe"
		elif (self._platform == "Linux"):
			executablePath = self._binaryDirectoryPath / "vlib"
		else:
			raise PlatformNotSupportedException(self._platform)
		super().__init__(self._platform, self._dryrun, executablePath, logger=self._logger)

		self.Parameters[self.Executable] = executablePath

	class Executable(metaclass=ExecutableArgument):
		pass

	class SwitchLibraryName(metaclass=StringArgument):
		pass

	Parameters = CommandLineArgumentList(
		Executable,
		SwitchLibraryName
	)

	def CreateLibrary(self):
		parameterList = self.Parameters.ToArgumentList()
		self.LogVerbose("command: {0}".format(" ".join(parameterList)))

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise ModelSimException("Failed to launch vlib run.") from ex

		self._hasOutput =   False
		self._hasWarnings = False
		self._hasErrors =   False
		try:
			iterator = iter(VLibFilter(self.GetReader()))

			line = next(iterator)
			line.IndentBy(self.Logger.BaseIndent + 1)
			self._hasOutput = True
			self.LogNormal("vlib messages for '{0}'".format(self.Parameters[self.SwitchLibraryName]), indent=1)
			self.LogNormal("-" * (78 - self.Logger.BaseIndent * 2), indent=1)
			self.Log(line)

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |=   (line.Severity is Severity.Error)

				line = next(iterator)
				line.IndentBy(self.Logger.BaseIndent + 1)
				self.Log(line)

		except DryRunException:
			pass
		except StopIteration:
			pass
		finally:
			if self._hasOutput:
				self.LogNormal("-" * (78 - self.Logger.BaseIndent * 2), indent=1)


class VHDLCompilerCoverageOptions(Flags):
	__no_flags_name__ =   "Default"
	__all_flags_name__ =  "All"
	Statement =           "s"
	Branch =              "b"
	Condition =           "c"
	Expression =          "e"
	StateMachine =        "f"
	Toggle =              "t"

	def __str__(self):
		return "".join([i.value for i in self])

class VHDLCompilerFSMVerbosityLevel(Enum):
	Default =         ""
	Basic =           "b"
	TransitionTable = "t"
	AnyWarning =      "w"

	def __str__(self):
		return self.value


class OptionalModelSimMinusArgument(OptionalValuedFlagArgument):
	_pattern =          "-{0}"
	_patternWithValue = "-{0} {1}"

class OptionalModelSimPlusArgument(OptionalValuedFlagArgument):
	_pattern =          "+{0}"
	_patternWithValue = "+{0}={1}"


class VHDLCompiler(OutputFilteredExecutable, ToolMixIn):
	def __init__(self, toolchain : ToolMixIn):
		ToolMixIn.__init__(
			self, toolchain._platform, toolchain._dryrun, toolchain._binaryDirectoryPath, toolchain._version,
			toolchain._logger)

		if (self._platform == "Windows"):    executablePath = self._binaryDirectoryPath / "vcom.exe"
		elif (self._platform == "Linux"):    executablePath = self._binaryDirectoryPath / "vcom"
		else:                                raise PlatformNotSupportedException(self._platform)
		super().__init__(self._platform, self._dryrun, executablePath, logger=self._logger)

		self.Parameters[self.Executable] = executablePath

	class Executable(metaclass=ExecutableArgument):
		_value =    None

	class FlagTime(metaclass=ShortFlagArgument):
		_name =     "time"					# Print the compilation wall clock time
		_value =    None

	class FlagExplicit(metaclass=ShortFlagArgument):
		_name =     "explicit"
		_value =    None

	class FlagQuietMode(metaclass=ShortFlagArgument):
		_name =     "quiet"					# Do not report 'Loading...' messages"
		_value =    None

	class SwitchModelSimIniFile(metaclass=ShortTupleArgument):
		_name =     "modelsimini"
		_value =    None

	class FlagRangeCheck(metaclass=ShortFlagArgument):
		_name =     "rangecheck"
		_value =    None

	class SwitchCoverage(metaclass=OptionalModelSimPlusArgument):
		_name =     "cover"

		# @property
		# def Value(self):
		# 	return self._value
		#
		# @Value.setter
		# def Value(self, value):
		# 	if (value is None):                                         self._value = None
		# 	elif isinstance(value, VHDLCompilerCoverageOptions):        self._value = value
		# 	else:	                                                      raise ValueError("Parameter 'value' is not of type VHDLCompilerCoverageOptions.")
		#
		# def __str__(self):
		# 	if (self._value is None):                                   return ""
		# 	elif (self._value is VHDLCompilerCoverageOptions.Default):  return self._pattern.format(self._name)
		# 	else:                                                       return self._patternWithValue.format(self._name, str(self._value))
		#
		# def AsArgument(self):
		# 	if (self._value is None):                                   return None
		# 	elif (self._value is VHDLCompilerCoverageOptions.Default):  return self._pattern.format(self._name)
		# 	else:                                                       return self._patternWithValue.format(self._name, str(self._value))

	class FlagEnableFocusedExpressionCoverage(metaclass=ShortFlagArgument):
		_name =     "coverfec"

	class FlagDisableFocusedExpressionCoverage(metaclass=ShortFlagArgument):
		_name =     "nocoverfec"

	class FlagEnableRapidExpressionCoverage(metaclass=ShortFlagArgument):
		_name =     "coverrec"

	class FlagDisableRapidExpressionCoverage(metaclass=ShortFlagArgument):
		_name =     "nocoverrec"

	class FlagEnableRecognitionOfImplicitFSMResetTransitions(metaclass=ShortFlagArgument):
		_name =     "fsmresettrans"

	class FlagDisableRecognitionOfImplicitFSMResetTransitions(metaclass=ShortFlagArgument):
		_name =     "nofsmresettrans"

	class FlagEnableRecognitionOfSingleBitFSMState(metaclass=ShortFlagArgument):
		_name =     "fsmsingle"

	class FlagDisableRecognitionOfSingleBitFSMState(metaclass=ShortFlagArgument):
		_name =     "nofsmsingle"

	class FlagEnableRecognitionOfImplicitFSMTransitions(metaclass=ShortFlagArgument):
		_name =     "fsmimplicittrans"

	class FlagDisableRecognitionOfImplicitFSMTransitions(metaclass=ShortFlagArgument):
		_name =     "nofsmimplicittrans"

	class SwitchFSMVerbosityLevel(metaclass=OptionalModelSimMinusArgument):
		_name =     "fsmverbose"

		# @property
		# def Value(self):
		# 	return self._value
		#
		# @Value.setter
		# def Value(self, value):
		# 	if (value is None):                                           self._value = None
		# 	elif isinstance(value, VHDLCompilerFSMVerbosityLevel):        self._value = value
		# 	else:	                                                        raise ValueError("Parameter 'value' is not of type VHDLCompilerFSMVerbosityLevel.")
		#
		# def __str__(self):
		# 	if (self._value is None):                                     return ""
		# 	elif (self._value is VHDLCompilerFSMVerbosityLevel.Default):  return self._pattern.format(self._name)
		# 	else:                                                         return self._patternWithValue.format(self._name, str(self._value))
		#
		# def AsArgument(self):
		# 	if (self._value is None):                                     return None
		# 	elif (self._value is VHDLCompilerFSMVerbosityLevel.Default):  return self._pattern.format(self._name)
		# 	else:                                                         return self._patternWithValue.format(self._name, str(self._value))

	class FlagReportAsNote(metaclass=ShortTupleArgument):
		_name =   "note"
		_value =  None

	class FlagReportAsError(metaclass=ShortTupleArgument):
		_name =   "error"
		_value =  None

	class FlagReportAsWarning(metaclass=ShortTupleArgument):
		_name =   "warning"
		_value =  None

	class FlagReportAsFatal(metaclass=ShortTupleArgument):
		_name =   "fatal"
		_value =  None

	class FlagRelaxLanguageChecks(metaclass=ShortFlagArgument):
		_name =   "permissive"

	class FlagForceLanguageChecks(metaclass=ShortFlagArgument):
		_name =   "pedanticerrors"

	class SwitchVHDLVersion(metaclass=StringArgument):
		_pattern =  "-{0}"
		_value =    None

	class ArgLogFile(metaclass=ShortTupleArgument):
		_name =     "l"			# what's the difference to -logfile ?
		_value =    None

	class SwitchVHDLLibrary(metaclass=ShortTupleArgument):
		_name =     "work"
		_value =    None

	class ArgSourceFile(metaclass=PathArgument):
		_value =    None

	Parameters = CommandLineArgumentList(
		Executable,
		FlagTime,
		FlagExplicit,
		FlagQuietMode,
		SwitchModelSimIniFile,
		FlagRangeCheck,
		SwitchCoverage,
		FlagEnableFocusedExpressionCoverage,
		FlagDisableFocusedExpressionCoverage,
		FlagEnableRapidExpressionCoverage,
		FlagDisableRapidExpressionCoverage,
		FlagEnableRecognitionOfImplicitFSMResetTransitions,
		FlagDisableRecognitionOfImplicitFSMResetTransitions,
		FlagEnableRecognitionOfSingleBitFSMState,
		FlagDisableRecognitionOfSingleBitFSMState,
		FlagEnableRecognitionOfImplicitFSMTransitions,
		FlagDisableRecognitionOfImplicitFSMTransitions,
		SwitchFSMVerbosityLevel,
		FlagReportAsNote,
		FlagReportAsError,
		FlagReportAsWarning,
		FlagReportAsFatal,
		FlagRelaxLanguageChecks,
		FlagForceLanguageChecks,
		SwitchVHDLVersion,
		ArgLogFile,
		SwitchVHDLLibrary,
		ArgSourceFile
	)

	def Compile(self):
		parameterList = self.Parameters.ToArgumentList()
		self.LogVerbose("command: {0}".format(" ".join(parameterList)))

		if (self._dryrun):
			self.LogDryRun("Start process: {0}".format(" ".join(parameterList)))
			return

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise ModelSimException("Failed to launch vcom run.") from ex

		self._hasOutput =   False
		self._hasWarnings = False
		self._hasErrors =   False
		try:
			iterator = iter(VComFilter(self.GetReader()))

			line = next(iterator)
			line.IndentBy(self.Logger.BaseIndent + 1)
			self._hasOutput = True
			self.LogNormal("vcom messages for '{0}'".format(self.Parameters[self.ArgSourceFile]), indent=1)
			self.LogNormal("-" * (78 - self.Logger.BaseIndent*2), indent=1)
			self.Log(line)

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |= (line.Severity is Severity.Error)

				line = next(iterator)
				line.IndentBy(self.Logger.BaseIndent + 1)
				self.Log(line)

		except DryRunException:
			pass
		except StopIteration:
			pass
		finally:
			if self._hasOutput:
				self.LogNormal("-" * (78 - self.Logger.BaseIndent*2), indent=1)

	def GetTclCommand(self):
		parameterList = self.Parameters.ToArgumentList()
		return "vcom " + " ".join(parameterList[1:])


class VHDLSimulator(OutputFilteredExecutable, ToolMixIn):
	def __init__(self, toolchain : ToolMixIn):
		ToolMixIn.__init__(
			self, toolchain._platform, toolchain._dryrun, toolchain._binaryDirectoryPath, toolchain._version,
			toolchain._logger)

		if (self._platform == "Windows"):    executablePath = self._binaryDirectoryPath / "vsim.exe"
		elif (self._platform == "Linux"):    executablePath = self._binaryDirectoryPath / "vsim"
		else:                                            raise PlatformNotSupportedException(self._platform)
		super().__init__(self._platform, self._dryrun, executablePath, logger=self._logger)

		self.Parameters[self.Executable] = executablePath

	class Executable(metaclass=ExecutableArgument):
		"""The executable to launch."""
		_value =  None

	class FlagQuietMode(metaclass=ShortFlagArgument):
		"""Run simulation in quiet mode. (Don't show 'Loading...' messages."""
		_name =   "quiet"
		_value =  None

	class FlagBatchMode(metaclass=ShortFlagArgument):
		"""Run simulation in batch mode."""
		_name =   "batch"
		_value =  None

	class FlagGuiMode(metaclass=ShortFlagArgument):
		"""Run simulation in GUI mode."""
		_name =   "gui"
		_value =  None

	class SwitchBatchCommand(metaclass=ShortTupleArgument):
		"""Specify a Tcl batch script for the batch mode."""
		_name =   "do"
		_value =  None

	class FlagCommandLineMode(metaclass=ShortFlagArgument):
		"""Run simulation in command line mode."""
		_name =   "c"
		_value =  None

	class SwitchModelSimIniFile(metaclass=ShortTupleArgument):
		"""Specify the used 'modelsim.ini' file."""
		_name =   "modelsimini"
		_value =  None

	class FlagEnableOptimization(metaclass=ShortFlagArgument):
		"""Enabled optimization while elaborating the design."""
		_name =   "vopt"

	class FlagDisableOptimization(metaclass=ShortFlagArgument):
		"""Disabled optimization while elaborating the design."""
		_name =   "novopt"

	class FlagEnableOptimizationVerbosity(metaclass=ShortFlagArgument):
		"""Enabled optimization while elaborating the design."""
		_name =   "vopt_verbose"

	class FlagEnableKeepAssertionCountsForCoverage(metaclass=ShortFlagArgument):
		_name =   "assertcover"

	class FlagDisableKeepAssertionCountsForCoverage(metaclass=ShortFlagArgument):
		_name =   "noassertcover"

	class FlagEnableCoverage(metaclass=ShortFlagArgument):
		_name =   "coverage"

	class FlagDisableCoverage(metaclass=ShortFlagArgument):
		_name =   "nocoverage"

	class FlagEnablePSL(metaclass=ShortFlagArgument):
		_name =   "psl"

	class FlagDisablePSL(metaclass=ShortFlagArgument):
		_name =   "nopsl"

	class FlagEnableFSMDebugging(metaclass=ShortFlagArgument):
		_name =   "fsmdebug"

	class FlagReportAsNote(metaclass=ShortTupleArgument):
		_name =   "note"
		_value =  None

	class FlagReportAsError(metaclass=ShortTupleArgument):
		_name =   "error"
		_value =  None

	class FlagReportAsWarning(metaclass=ShortTupleArgument):
		_name =   "warning"
		_value =  None

	class FlagReportAsFatal(metaclass=ShortTupleArgument):
		_name =   "fatal"
		_value =  None

	class FlagRelaxLanguageChecks(metaclass=ShortFlagArgument):
		_name =   "permissive"

	class FlagForceLanguageChecks(metaclass=ShortFlagArgument):
		_name =   "pedanticerrors"

	class SwitchTimeResolution(metaclass=ShortTupleArgument):
		"""Set simulation time resolution."""
		_name =   "t"			# -t [1|10|100]fs|ps|ns|us|ms|sec  Time resolution limit
		_value =  None

	class ArgLogFile(metaclass=ShortTupleArgument):
		_name =   "l"			# what's the difference to -logfile ?
		_value =  None

	class ArgKeepStdOut(metaclass=ShortFlagArgument):
		_name =   "keepstdout"

	class ArgVHDLLibraryName(metaclass=ShortTupleArgument):
		_name =   "lib"
		_value =  None

	class ArgOnFinishMode(metaclass=ShortTupleArgument):
		_name =   "onfinish"
		_value =  None				# Customize the kernel shutdown behavior at the end of simulation; Valid modes: ask, stop, exit, final (Default: ask)

	class SwitchTopLevel(metaclass=StringArgument):
		"""The top-level for simulation."""
		_value =  None

	#: Specify all accepted command line arguments
	Parameters = CommandLineArgumentList(
		Executable,
		FlagQuietMode,
		FlagBatchMode,
		FlagGuiMode,
		SwitchBatchCommand,
		FlagCommandLineMode,
		SwitchModelSimIniFile,
		FlagEnableOptimization,
		FlagDisableOptimization,
		FlagEnableOptimizationVerbosity,
		FlagEnableKeepAssertionCountsForCoverage,
		FlagDisableKeepAssertionCountsForCoverage,
		FlagEnableCoverage,
		FlagDisableCoverage,
		FlagEnablePSL,
		FlagDisablePSL,
		FlagEnableFSMDebugging,
		FlagReportAsNote,
		FlagReportAsError,
		FlagReportAsWarning,
		FlagReportAsFatal,
		FlagRelaxLanguageChecks,
		FlagForceLanguageChecks,
		ArgLogFile,
		ArgKeepStdOut,
		ArgVHDLLibraryName,
		SwitchTimeResolution,
		ArgOnFinishMode,
		SwitchTopLevel
	)

	def Simulate(self):
		"""Start a simulation."""
		parameterList = self.Parameters.ToArgumentList()
		self.LogVerbose("command: {0}".format(" ".join(parameterList)))

		try:
			self.StartProcess(parameterList)
		except Exception as ex:
			raise ModelSimException("Failed to launch vsim run.") from ex

		self._hasOutput =   False
		self._hasWarnings = False
		self._hasErrors =   False
		simulationResult =  CallByRefParam(SimulationResult.Error)
		try:
			iterator = iter(PoCSimulationResultFilter(VSimFilter(self.GetReader()), simulationResult))

			line = next(iterator)
			line.IndentBy(self.Logger.BaseIndent + 1)
			self._hasOutput = True
			self.LogNormal("vsim messages for '{0}'".format(self.Parameters[self.SwitchTopLevel]), indent=1)
			self.LogNormal("-" * (78 - self.Logger.BaseIndent*2), indent=1)
			self.Log(line)

			while True:
				self._hasWarnings |= (line.Severity is Severity.Warning)
				self._hasErrors |=   (line.Severity is Severity.Error)

				line = next(iterator)
				line.IndentBy(self.Logger.BaseIndent + 1)
				self.Log(line)

		except DryRunException:
			simulationResult <<= SimulationResult.DryRun
		except PoCSimulationResultNotFoundException:
			if self.Parameters[self.FlagGuiMode]:
				simulationResult <<= SimulationResult.GUIRun
		except StopIteration:
			pass
		finally:
			if self._hasOutput:
				self.LogNormal("-" * (78 - self.Logger.BaseIndent*2), indent=1)

		return simulationResult.value


def VLibFilter(gen):
	for line in gen:
		if line.startswith("** Warning: "):
			yield LogEntry(line, Severity.Warning)
		elif line.startswith("** Error"):
			yield LogEntry(line, Severity.Error)
		elif line.startswith("** Fatal: "):
			yield LogEntry(line, Severity.Error)
		else:
			yield LogEntry(line, Severity.Normal)


def VComFilter(gen):
	for line in gen:
		if line.startswith("** Warning: "):
			yield LogEntry(line, Severity.Warning)
		elif line.startswith("** Error"):
			yield LogEntry(line, Severity.Error)
		elif line.startswith("** Fatal: "):
			yield LogEntry(line, Severity.Error)
		else:
			yield LogEntry(line, Severity.Normal)


def VSimFilter(gen):
	PoCOutputFound = False
	for line in gen:
		if line.startswith("# Loading "):
			yield LogEntry(line, Severity.Debug)
		elif line.startswith("# //"):
			if line[6:].startswith("Questa"):
				yield LogEntry(line, Severity.Debug)
			elif line[6:].startswith("Version "):
				yield LogEntry(line, Severity.Debug)
			else:
				continue
		elif line.startswith("# ========================================"):
			PoCOutputFound = True
			yield LogEntry(line[2:], Severity.Normal)
		elif line.startswith("# ** Warning: "):
			yield LogEntry(line, Severity.Warning)
		elif line.startswith("# ** Error"):
			yield LogEntry(line, Severity.Error)
		elif line.startswith("# ** Fatal: "):
			yield LogEntry(line, Severity.Error)
		elif line.startswith("** Fatal: "):
			yield LogEntry(line, Severity.Error)
		elif line.startswith("# %%"):
			if ("ERROR" in line):
				yield LogEntry("{DARK_RED}{line}{NOCOLOR}".format(line=line[2:], **Init.Foreground), Severity.Error)
			else:
				yield LogEntry("{DARK_CYAN}{line}{NOCOLOR}".format(line=line[2:], **Init.Foreground), Severity.Normal)
		elif line.startswith("# "):
			if (not PoCOutputFound):
				yield LogEntry(line, Severity.Verbose)
			else:
				yield LogEntry(line[2:], Severity.Normal)
		else:
			yield LogEntry(line, Severity.Normal)
