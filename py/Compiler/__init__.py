# EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:               Patrick Lehmann
#
# Python Sub Module:    TODO:
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
from enum                         import unique, Enum
from pathlib                      import Path
from re                           import compile as re_compile, IGNORECASE, MULTILINE, DOTALL, subn
from shutil                       import copy as shutil_copy

from flags                        import Flags

from lib.Functions                import Init
from lib.Parser                   import ParserException
from Base                         import IHost
from Base.Exceptions              import ExceptionBase, SkipableException
from Base.Project                 import Environment, VHDLVersion, FileTypes
from Base.Shared                  import Shared, to_time
from Parser.RulesParser           import CopyRuleMixIn, DeleteRuleMixIn, ReplaceRuleMixIn, AppendLineRuleMixIn
from DataBase.Solution            import RulesFile
from DataBase.TestCase            import SynthesisSuite, CompileStatus, Synthesis

# required for autoapi.sphinx
from lib.SphinxExtensions import DocumentMemberAttribute


__api__ = [
	'CompilerException',
	'SkipableCompilerException',
	'CopyTask',
	'DeleteTask',
	'ReplaceTask',
	'AppendLineTask',
	'CompileState',
	'CompileResult',
	'Compiler'
]
__all__ = __api__


class CompilerException(ExceptionBase):
	"""Base class for all CompilerException classes. It is raised while running
	compiler (synthesis) tasks in PoC.
	"""


class SkipableCompilerException(CompilerException, SkipableException):
	"""``SkipableCompilerException`` is a :py:exc:`CompilerException`, which
	can be skipped.
	"""


class CopyTask(CopyRuleMixIn):
	"""This class represents a 'copy task' and inherits the partial class
	:class:`CopyRuleMixIn <Parser.RulesParser.CopyRuleMixIn>`.
	"""


class DeleteTask(DeleteRuleMixIn):
	"""This class represents a 'delete task' and inherits the partial class
	:class:`DeleteRuleMixIn <Parser.RulesParser.DeleteRuleMixIn>`.
	"""


class ReplaceTask(ReplaceRuleMixIn):
	"""This class represents a 'replace task' and inherits the partial class
	:class:`ReplaceRuleMixIn <Parser.RulesParser.ReplaceRuleMixIn>`.
	"""


class AppendLineTask(AppendLineRuleMixIn):
	"""This class represents a 'append line task' and inherits the partial class
	:class:`AppendLineRuleMixIn <Parser.RulesParser.AppendLineRuleMixIn>`.
	"""


@unique
class CompileSteps(Flags):
	"""Compiler step enumeration."""
	Prepare =        1 << 0
	CleanUpBefore =  1 << 1
	CleanUpAfter =   1 << 2
	Synthesize =     1 << 5
	Merge =          1 << 6
	AnalyzeTiming =  1 << 7
	Place =          1 << 8
	Route =          1 << 9
	WriteBitfile =   1 << 10
	ShowReport =     1 << 15
	# Recompile =      1 << 25
	# Resimulate =     1 << 26
	# Review =         1 << 27

@unique
class CompileState(Enum):
	"""Compile state enumeration."""
	Prepare =     0
	PreCopy =    10
	PrePatch =   11

	Compile =    50
	# Analyze =    61
	# Elaborate =  62
	# Optimize =   63
	# Translate =  64
	# Map =        65
	# Place =      66
	# Route =      67

	PostCopy =   90
	PostPatch =  91
	PostDelete = 92
	CleanUp =    99

@unique
class CompileResult(Enum):
	"""Compilation result enumeration."""
	NotRun =      0
	Error =       1
	Failed =      2
	Success =     3


class Compiler(Shared):
	"""Base class for all Compiler classes."""

	ENVIRONMENT =     Environment.Synthesis
	VHDL_VERSION =    VHDLVersion.VHDL93

	class __Directories__(Shared.__Directories__):
		Netlist =     None
		Source =      None
		Destination = None

	@DocumentMemberAttribute()
	def __init__(self, host : IHost, dryRun, noCleanUp):
		"""Class initializer

		:type  host:      object
		:param host:      The hosting instance for this instance.
		:type  dryRun:    bool
		:param dryRun:    Enable dry-run mode
		:type  noCleanUp: bool
		:param noCleanUp: Don't clean up after a run.
		"""
		super().__init__(host, dryRun)

		self._noCleanUp =       noCleanUp

		self._testSuite =       SynthesisSuite()  # TODO: This includes not the read ini files phases ...
		self._state =           CompileState.Prepare
		self._preTasksTime =    None
		self._compileTime =     None
		self._postTasksTime =   None

	@property
	def NoCleanUp(self):      return self._noCleanUp

	def _PrepareCompiler(self):
		"""Prepare for compilation. This method forwards to :py:meth:`Base.Compiler.Compiler._Prepare`,
		which is inherited from :py:class:`Base.Shared.Shared`.
		"""

	def TryRun(self, netlist, *args, **kwargs):
		"""Try to run a testbench. Skip skipable exceptions by printing the error and its cause."""

		__COMPILE_STATE_TO_SYNTHESIS_STATUS__ = {
			CompileState.Prepare:    CompileStatus.InternalError,
			CompileState.PreCopy:    CompileStatus.SystemError,
			CompileState.PrePatch:   CompileStatus.SystemError,
			CompileState.Compile:    CompileStatus.CompileError,
			CompileState.PostCopy:   CompileStatus.SystemError,
			CompileState.PostPatch:  CompileStatus.SystemError,
			CompileState.PostDelete: CompileStatus.SystemError
		}

		synthesis = Synthesis(netlist)
		self._testSuite.AddSynthesis(synthesis)
		synthesis.StartTimer()
		try:
			self.Run(netlist, *args, **kwargs)
			# synthesis.UpdateStatus(netlist.Result)
			synthesis.Status = CompileStatus.CompileSuccess
		except SkipableCompilerException as ex:
			synthesis.Status = __COMPILE_STATE_TO_SYNTHESIS_STATUS__[self._state]

			self.LogQuiet("  {RED}ERROR:{NOCOLOR} {0}".format(ex.message, **Init.Foreground))
			cause = ex.__cause__
			if (cause is not None):
				self.LogQuiet("    {YELLOW}{ExType}:{NOCOLOR} {ExMsg!s}".format(ExType=cause.__class__.__name__, ExMsg=cause, **Init.Foreground))
				cause = cause.__cause__
				if (cause is not None):
					self.LogQuiet("      {YELLOW}{ExType}:{NOCOLOR} {ExMsg!s}".format(ExType=cause.__class__.__name__, ExMsg=cause, **Init.Foreground))
			self.LogQuiet("  {RED}[SKIPPED DUE TO ERRORS]{NOCOLOR}".format(**Init.Foreground))
		except CompilerException:
			synthesis.Status = __COMPILE_STATE_TO_SYNTHESIS_STATUS__[self._state]
			raise
		except ExceptionBase:
			synthesis.Status = CompileStatus.SystemError
			raise
		finally:
			synthesis.StopTimer()

	def Run(self, netlist, board):
		"""Run a testbench."""

		self.LogQuiet("{CYAN}IP core: {0!s}{NOCOLOR}".format(netlist.Parent, **Init.Foreground))
		# # TODO: refactor
		# self.LogNormal("Checking for dependencies:")
		# for dependency in netlist.Dependencies:
		# 	print("  " + str(dependency))

		# setup all needed paths to execute fuse
		self._PrepareCompilerEnvironment(board.Device)
		self._WriteSpecialSectionIntoConfig(board.Device)

		self._CreatePoCProject(netlist.ModuleName, board)
		if netlist.FilesFile is not None:   self._AddFileListFile(netlist.FilesFile)
		if (netlist.RulesFile is not None): self._AddRulesFiles(netlist.RulesFile)

	def _PrepareCompilerEnvironment(self, device):
		self.LogNormal("Preparing synthesis environment...")
		self.Directories.Destination = self.Directories.Netlist / str(device)

		self._PrepareEnvironment()

		# create output directory for CoreGen if not existent
		if (not self.Directories.Destination.exists()) :
			self.LogVerbose("Creating output directory for generated files.")
			self.LogDebug("Output directory: {0!s}.".format(self.Directories.Destination))
			try:
				self.Directories.Destination.mkdir(parents=True)
			except OSError as ex:
				raise CompilerException("Error while creating '{0!s}'.".format(self.Directories.Destination)) from ex

	def _WriteSpecialSectionIntoConfig(self, device):
		# add the key Device to section SPECIAL at runtime to change interpolation results
		self.Host.PoCConfig['SPECIAL'] = {}
		self.Host.PoCConfig['SPECIAL']['Device'] =        device.ShortName
		self.Host.PoCConfig['SPECIAL']['DeviceSeries'] =  device.Series
		self.Host.PoCConfig['SPECIAL']['OutputDir']	=     self.Directories.Working.as_posix()

	def _AddRulesFiles(self, rulesFilePath):
		self.LogVerbose("Reading rules from '{0!s}'".format(rulesFilePath))
		# add the *.rules file, parse and evaluate it
		try:
			rulesFile = self._pocProject.AddFile(RulesFile(rulesFilePath))
			rulesFile.Parse()
		except ParserException as ex:
			raise SkipableCompilerException("Error while parsing '{0!s}'.".format(rulesFilePath)) from ex

		self.LogDebug("Pre-process rules:")
		for rule in rulesFile.PreProcessRules:
			self.LogDebug("  {0!s}".format(rule))
		self.LogDebug("Post-process rules:")
		for rule in rulesFile.PostProcessRules:
			self.LogDebug("  {0!s}".format(rule))

	def _RunPreCopy(self, netlist):
		self.LogVerbose("Copy further input files into temporary directory...")
		rulesFiles = [file for file in self.PoCProject.Files(fileType=FileTypes.RulesFile)]		# FIXME: get rulefile from netlist object as a rulefile object instead of a path
		preCopyTasks = []
		if (rulesFiles):
			for rule in rulesFiles[0].PreProcessRules:
				if isinstance(rule, CopyRuleMixIn):
					sourcePath =      self.Host.PoCConfig.Interpolation.interpolate(self.Host.PoCConfig, netlist.ConfigSectionName, "RulesFile", rule.SourcePath, {})
					destinationPath =  self.Host.PoCConfig.Interpolation.interpolate(self.Host.PoCConfig, netlist.ConfigSectionName, "RulesFile", rule.DestinationPath, {})
					task = CopyTask(Path(sourcePath), Path(destinationPath))
					preCopyTasks.append(task)
		else:
			preCopyRules = self.Host.PoCConfig[netlist.ConfigSectionName]['PreCopyRules']
			self._ParseCopyRules(preCopyRules, preCopyTasks, "pre")

		if (len(preCopyTasks) != 0):
			self._ExecuteCopyTasks(preCopyTasks, "pre")
		else:
			self.LogDebug("Nothing to copy")

	def _RunPostCopy(self, netlist):
		self.LogVerbose("copy generated files into netlist directory...")
		rulesFiles = [file for file in self.PoCProject.Files(fileType=FileTypes.RulesFile)]		# FIXME: get rulefile from netlist object as a rulefile object instead of a path
		postCopyTasks = []
		if (rulesFiles):
			for rule in rulesFiles[0].PostProcessRules:
				if isinstance(rule, CopyRuleMixIn):
					sourcePath =      self.Host.PoCConfig.Interpolation.interpolate(self.Host.PoCConfig, netlist.ConfigSectionName, "RulesFile", rule.SourcePath, {})
					destinationPath =  self.Host.PoCConfig.Interpolation.interpolate(self.Host.PoCConfig, netlist.ConfigSectionName, "RulesFile", rule.DestinationPath, {})
					task = CopyTask(Path(sourcePath), Path(destinationPath))
					postCopyTasks.append(task)
		else:
			postCopyRules = self.Host.PoCConfig[netlist.ConfigSectionName]['PostCopyRules']
			self._ParseCopyRules(postCopyRules, postCopyTasks, "post")

		if (len(postCopyTasks) != 0):
			self._ExecuteCopyTasks(postCopyTasks, "post")
		else:
			self.LogDebug("Nothing to copy")

	def _ParseCopyRules(self, rawList, copyTasks, text):
		# read copy tasks
		if (len(rawList) != 0):
			self.LogDebug("Parsing {0}-copy tasks from config file:".format(text))
			rawList = rawList.split("\n")

			copyRegExpStr  = r"^\s*(?P<SourceFilename>.*?)" # Source filename
			copyRegExpStr += r"\s->\s"                      # Delimiter signs
			copyRegExpStr += r"(?P<DestFilename>.*?)$"      # Destination filename
			copyRegExp = re_compile(copyRegExpStr)

			for item in rawList:
				preCopyRegExpMatch = copyRegExp.match(item)
				if (preCopyRegExpMatch is None):
					raise CompilerException("Error in copy rule '{0}'.".format(item))

				task = CopyTask(
					Path(preCopyRegExpMatch.group('SourceFilename')),
					Path(preCopyRegExpMatch.group('DestFilename'))
				)
				copyTasks.append(task)
				self.LogDebug("  {0!s}".format(task))
		else:
			self.LogDebug("No {0}-copy tasks specified in config file.".format(text))

	def _ExecuteCopyTasks(self, tasks, text):
		for task in tasks:
			if (not self.DryRun and not task.SourcePath.exists()):
				raise CompilerException("Cannot {0}-copy '{1!s}' to destination.".format(text, task.SourcePath)) from FileNotFoundError(str(task.SourcePath))

			if not task.DestinationPath.parent.exists():
				if self.DryRun:
					self.LogDryRun("mkdir '{0!s}'.".format(task.DestinationPath.parent))
				else:
					try:
						task.DestinationPath.parent.mkdir(parents=True)
					except OSError as ex:
						raise CompilerException("Error while creating '{0!s}'.".format(task.DestinationPath.parent)) from ex

			self.LogDebug("{0}-copying '{1!s}'.".format(text, task.SourcePath))
			if self.DryRun:
				self.LogDryRun("Copy '{0!s}' to '{1!s}'.".format(task.SourcePath, task.DestinationPath))
			else:
				try:
					shutil_copy(str(task.SourcePath), str(task.DestinationPath))
				except OSError as ex:
					raise CompilerException("Error while copying '{0!s}'.".format(task.SourcePath)) from ex

	def _RunPostDelete(self, netlist):
		self.LogVerbose("copy generated files into netlist directory...")
		rulesFiles = [file for file in self.PoCProject.Files(fileType=FileTypes.RulesFile)]  # FIXME: get rulefile from netlist object as a rulefile object instead of a path
		postDeleteTasks = []
		if (rulesFiles):
			for rule in rulesFiles[0].PostProcessRules:
				if isinstance(rule, DeleteRuleMixIn):
					filePath = self.Host.PoCConfig.Interpolation.interpolate(self.Host.PoCConfig, netlist.ConfigSectionName, "RulesFile", rule.FilePath, {})
					task = DeleteTask(Path(filePath))
					postDeleteTasks.append(task)
		else:
			postDeleteRules = self.Host.PoCConfig[netlist.ConfigSectionName]['PostDeleteRules']
			self._ParseDeleteRules(postDeleteRules, postDeleteTasks, "post")

		if self.NoCleanUp:
			self.LogWarning("Disabled cleanup. Skipping post-delete rules.")
		elif (len(postDeleteTasks) != 0):
			self._ExecuteDeleteTasks(postDeleteTasks, "post")
		else:
			self.LogDebug("Nothing to delete")

	def _ParseDeleteRules(self, rawList, deleteTasks, text):
		# read delete tasks
		if (len(rawList) != 0):
			self.LogDebug("Parse {0}-delete tasks from config file:".format(text))
			rawList = rawList.split("\n")

			deleteRegExpStr = r"^\s*(?P<Filename>.*?)$"  # filename
			deleteRegExp = re_compile(deleteRegExpStr)

			for item in rawList:
				deleteRegExpMatch = deleteRegExp.match(item)
				if (deleteRegExpMatch is None):
					raise CompilerException("Error in delete rule '{0}'.".format(item))

				task = DeleteTask(Path(deleteRegExpMatch.group('Filename')))
				deleteTasks.append(task)
				self.LogDebug("  {0!s}".format(task))
		else:
			self.LogDebug("No {0}-delete tasks specified in config file.".format(text))

	def _ExecuteDeleteTasks(self, tasks, text):
		for task in tasks:
			if (not self.DryRun and not task.FilePath.exists()):
				raise CompilerException("Cannot {0}-delete '{1!s}'.".format(text, task.FilePath)) from FileNotFoundError(str(task.FilePath))

			self.LogDebug("{0}-deleting '{1!s}'.".format(text, task.FilePath))
			if self.DryRun:
				self.LogDryRun("Delete '{0!s}'.".format(task.FilePath))
			else:
				try:
					task.FilePath.unlink()
				except OSError as ex:
					raise CompilerException("Error while deleting '{0!s}'.".format(task.FilePath)) from ex

	def _RunPreReplace(self, netlist):
		self.LogVerbose("Patching files in temporary directory...")
		rulesFiles = [file for file in self.PoCProject.Files(fileType=FileTypes.RulesFile)]		# FIXME: get rulefile from netlist object as a rulefile object instead of a path
		preReplaceTasks = []
		if (rulesFiles):
			for rule in rulesFiles[0].PreProcessRules:
				if isinstance(rule, ReplaceRuleMixIn):
					filePath =        self.Host.PoCConfig.Interpolation.interpolate(self.Host.PoCConfig, netlist.ConfigSectionName, "RulesFile", rule.FilePath, {})
					searchPattern =   self.Host.PoCConfig.Interpolation.interpolate(self.Host.PoCConfig, netlist.ConfigSectionName, "RulesFile", rule.SearchPattern, {})
					replacePattern =  self.Host.PoCConfig.Interpolation.interpolate(self.Host.PoCConfig, netlist.ConfigSectionName, "RulesFile", rule.ReplacePattern, {})
					task = ReplaceTask(Path(filePath), searchPattern, replacePattern, rule.RegExpOption_MultiLine, rule.RegExpOption_DotAll, rule.RegExpOption_CaseInsensitive)
					preReplaceTasks.append(task)
				elif isinstance(rule, AppendLineRuleMixIn):
					filePath =        self.Host.PoCConfig.Interpolation.interpolate(self.Host.PoCConfig, netlist.ConfigSectionName, "RulesFile", rule.FilePath, {})
					appendPattern =   self.Host.PoCConfig.Interpolation.interpolate(self.Host.PoCConfig, netlist.ConfigSectionName, "RulesFile", rule.AppendPattern, {})
					task = AppendLineTask(Path(filePath), appendPattern)
					preReplaceTasks.append(task)
				elif isinstance(rule, CopyRuleMixIn):
					pass
				else:
					raise CompilerException("Unknown pre-process rule '{0!s}'.".format(rule))
		else:
			preReplaceRules = self.Host.PoCConfig[netlist.ConfigSectionName]['PreReplaceRules']
			self._ParseReplaceRules(preReplaceRules, preReplaceTasks, "pre")

		if (len(preReplaceTasks) != 0):
			self._ExecuteReplaceTasks(preReplaceTasks, "pre")
		else:
			self.LogDebug("Nothing to patch.")

	def _RunPostReplace(self, netlist):
		self.LogVerbose("Patching files in netlist directory...")
		rulesFiles = [file for file in self.PoCProject.Files(fileType=FileTypes.RulesFile)]  # FIXME: get rulefile from netlist object as a rulefile object instead of a path
		postReplaceTasks = []
		if (rulesFiles):
			for rule in rulesFiles[0].PostProcessRules:
				if isinstance(rule, ReplaceRuleMixIn):
					filePath =        self.Host.PoCConfig.Interpolation.interpolate(self.Host.PoCConfig, netlist.ConfigSectionName, "RulesFile", rule.FilePath, {})
					searchPattern =   self.Host.PoCConfig.Interpolation.interpolate(self.Host.PoCConfig, netlist.ConfigSectionName, "RulesFile", rule.SearchPattern, {})
					replacePattern =  self.Host.PoCConfig.Interpolation.interpolate(self.Host.PoCConfig, netlist.ConfigSectionName, "RulesFile", rule.ReplacePattern, {})
					task = ReplaceTask(Path(filePath), searchPattern, replacePattern, rule.RegExpOption_MultiLine, rule.RegExpOption_DotAll, rule.RegExpOption_CaseInsensitive)
					postReplaceTasks.append(task)
				elif isinstance(rule, AppendLineRuleMixIn):
					filePath =        self.Host.PoCConfig.Interpolation.interpolate(self.Host.PoCConfig, netlist.ConfigSectionName, "RulesFile", rule.FilePath, {})
					appendPattern =   self.Host.PoCConfig.Interpolation.interpolate(self.Host.PoCConfig, netlist.ConfigSectionName, "RulesFile", rule.AppendPattern, {})
					task = AppendLineTask(Path(filePath), appendPattern)
					postReplaceTasks.append(task)
				elif isinstance(rule, (CopyRuleMixIn, DeleteRuleMixIn)):
					pass
				else:
					raise CompilerException("Unknown post-process rule '{0!s}'.".format(rule))
		else:
			postReplaceRules = self.Host.PoCConfig[netlist.ConfigSectionName]['PostReplaceRules']
			self._ParseReplaceRules(postReplaceRules, postReplaceTasks, "post")

		if (len(postReplaceTasks) != 0):
			self._ExecuteReplaceTasks(postReplaceTasks, "post")
		else:
			self.LogDebug("Nothing to patch.")

	def _ParseReplaceRules(self, rawList, replaceTasks, text):
		# read replace tasks
		if (len(rawList) != 0):
			self.LogDebug("Parsing {0}-replacement tasks:".format(text))
			rawList = rawList.split("\n")

			# FIXME: Rework inline replace rule syntax.
			replaceRegExpStr = r"^\s*(?P<Filename>.*?)\s+:"  # Filename
			replaceRegExpStr += r"(?P<Options>[dim]{0,3}):\s+"  # RegExp options
			replaceRegExpStr += r"\"(?P<Search>.*?)\"\s+->\s+"  # Search regexp
			replaceRegExpStr += r"\"(?P<Replace>.*?)\"$"  # Replace regexp
			replaceRegExp = re_compile(replaceRegExpStr)

			for item in rawList:
				replaceRegExpMatch = replaceRegExp.match(item)

				if (replaceRegExpMatch is None):
					raise CompilerException("Error in replace rule '{0}'.".format(item))

				task = ReplaceTask(
					Path(replaceRegExpMatch.group('Filename')),
					replaceRegExpMatch.group('Search'),
					replaceRegExpMatch.group('Replace'),
					# replaceRegExpMatch.group('Options'),					# FIXME:
					# replaceRegExpMatch.group('Options'),					# FIXME:
					# replaceRegExpMatch.group('Options'),					# FIXME:
					False, False, False
				)
				replaceTasks.append(task)
				self.LogDebug("  {0!s}".format(task))
		else:
			self.LogDebug("No {0}-replace tasks specified in config file.".format(text))

	def _ExecuteReplaceTasks(self, tasks, text):
		for task in tasks:
			if (not self.DryRun and not task.FilePath.exists()):
				raise CompilerException("Cannot {0}-replace in file '{1!s}'.".format(text, task.FilePath)) from FileNotFoundError(str(task.FilePath))
			self.LogDebug("{0}-replace in file '{1!s}': search for '{2}' replace by '{3}'.".format(text, task.FilePath, task.SearchPattern, task.ReplacePattern))

			if self.DryRun:
				self.LogDryRun("Patch '{0!s}'.".format(task.FilePath))
			else:
				regExpFlags = 0
				if task.RegExpOption_CaseInsensitive: regExpFlags |= RE_IGNORECASE
				if task.RegExpOption_MultiLine:       regExpFlags |= RE_MULTILINE
				if task.RegExpOption_DotAll:          regExpFlags |= RE_DOTALL

				# compile regexp
				regExp = re_compile(task.SearchPattern, regExpFlags)
				# open file and read all lines
				with task.FilePath.open('r') as fileHandle:
					FileContent = fileHandle.read()
				# replace
				NewContent,replaceCount = re_subn(regExp, task.ReplacePattern, FileContent)
				if (replaceCount == 0):
					self.LogWarning("  Search pattern '{0}' not found in file '{1!s}'.".format(task.SearchPattern, task.FilePath))
				# open file to write the replaced data
				with task.FilePath.open('w') as fileHandle:
					fileHandle.write(NewContent)

	def PrintOverallCompileReport(self):
		self.LogQuiet("{HEADLINE}{line}{NOCOLOR}".format(line="=" * 80, **Init.Foreground))
		self.LogQuiet("{HEADLINE}{headline: ^80s}{NOCOLOR}".format(headline="Overall Compile Report", **Init.Foreground))
		self.LogQuiet("{HEADLINE}{line}{NOCOLOR}".format(line="=" * 80, **Init.Foreground))
		# table header
		self.LogQuiet("{Name: <24} | {Duration: >5} | {Status: ^11}".format(Name="Name", Duration="Time", Status="Status"))
		self.LogQuiet("-" * 80)
		self.PrintCompileReportLine(self._testSuite, 0, 24)

		self.LogQuiet("{HEADLINE}{line}{NOCOLOR}".format(line="=" * 80, **Init.Foreground))
		self.LogQuiet("Time: {time: >5}  Count: {count: <3}  Success: {success: <3}  Failed: {failed: <2}  Errors: {error: <2}".format(
			time=to_time(self._testSuite.OverallRunTime),
			count=self._testSuite.Count,
			success=self._testSuite.SuccessCount,
			failed=self._testSuite.FailedCount,
			error=self._testSuite.ErrorCount
		))
		self.LogQuiet("{HEADLINE}{line}{NOCOLOR}".format(line="=" * 80, **Init.Foreground))

	__COMPILE_REPORT_COLOR_TABLE__ = {
		CompileStatus.Unknown:        "RED",
		CompileStatus.InternalError:  "DARK_RED",
		CompileStatus.SystemError:    "DARK_RED",
		CompileStatus.CompileError:   "RED",
		CompileStatus.CompileSuccess: "GREEN"
	}

	__COMPILE_REPORT_STATUS_TEXT_TABLE__ = {
		CompileStatus.Unknown:        "-- ?? --",
		CompileStatus.InternalError:  "INT. ERROR",
		CompileStatus.SystemError:    "SYS. ERROR",
		CompileStatus.CompileError:   "COMP. ERROR",
		CompileStatus.CompileSuccess: "SUCCESS"
	}

	def PrintCompileReportLine(self, testObject, indent, nameColumnWidth):
		_indent = "  " * indent
		for group in testObject.Groups.values():
			pattern = "{indent}{{groupName: <{nameColumnWidth}}} |       | ".format(indent=_indent, nameColumnWidth=nameColumnWidth)
			self.LogQuiet(pattern.format(groupName=group.Name))
			self.PrintCompileReportLine(group, indent + 1, nameColumnWidth - 2)
		for synthesis in testObject.Synthesises.values():
			pattern = "{indent}{{netlistName: <{nameColumnWidth}}} | {{duration: >5}} | {{{color}}}{{status: ^11}}{{NOCOLOR}}".format(
				indent=_indent, nameColumnWidth=nameColumnWidth, color=self.__COMPILE_REPORT_COLOR_TABLE__[synthesis.Status])
			self.LogQuiet(pattern.format(
				netlistName=synthesis.Name,
				duration=to_time(synthesis.OverallRunTime),
				status=self.__COMPILE_REPORT_STATUS_TEXT_TABLE__[synthesis.Status], **Init.Foreground
			))
