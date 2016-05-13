# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
# 
# Python Class:     Base class for all PoC***Compilers
# 
# Description:
# ------------------------------------
#		TODO:
#		- 
#		- 
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
#   http://www.apache.org/licenses/LICENSE-2.0
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
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Class PoCCompiler")


# load dependencies
import re
import shutil
from pathlib            import Path
from os                 import chdir

from lib.Functions      import Init
from lib.Parser         import ParserException
from Base.Exceptions    import ExceptionBase
from Base.Logging       import ILogable
from Base.Project       import ToolChain, Tool, VHDLVersion, Environment, FileTypes
from Parser.RulesParser import CopyRuleMixIn, ReplaceRuleMixIn, DeleteRuleMixIn
from PoC.Solution       import VirtualProject, FileListFile, RulesFile


class CompilerException(ExceptionBase):
	pass

class SkipableCompilerException(CompilerException):
	pass

class CopyTask(CopyRuleMixIn):
	pass

class DeleteTask(DeleteRuleMixIn):
	pass

class ReplaceTask(ReplaceRuleMixIn):
	pass


class Compiler(ILogable):
	_TOOL_CHAIN =  ToolChain.Any
	_TOOL =        Tool.Any

	class __Directories__:
		Working = None
		PoCRoot = None
		Netlist = None
		Source = None
		Destination = None

	def __init__(self, host, dryRun, noCleanUp):
		if isinstance(host, ILogable):
			ILogable.__init__(self, host.Logger)
		else:
			ILogable.__init__(self, None)

		self.__host =        host
		self._noCleanUp =    noCleanUp
		self._dryRun =      dryRun

		self._vhdlVersion =  VHDLVersion.VHDL93
		self._pocProject =  None

		self._directories = self.__Directories__()

	# class properties
	# ============================================================================
	@property
	def Host(self):            return self.__host
	@property
	def PoCProject(self):      return self._pocProject
	@property
	def Directories(self):    return self._directories

	def TryRun(self, netlist, *args, **kwargs):
		try:
			self.Run(netlist, *args, **kwargs)
		except SkipableCompilerException as ex:
			self._LogQuiet("  {RED}ERROR:{NOCOLOR} {0}".format(ex.message, **Init.Foreground))
			cause = ex.__cause__
			if (cause is not None):
				self._LogQuiet("    {YELLOW}{ExType}:{NOCOLOR} {ExMsg!s}".format(ExType=cause.__class__.__name__, ExMsg=cause, **Init.Foreground))
				cause = cause.__cause__
				if (cause is not None):
					self._LogQuiet("      {YELLOW}{ExType}:{NOCOLOR} {ExMsg!s}".format(ExType=cause.__class__.__name__, ExMsg=cause, **Init.Foreground))
			self._LogQuiet("  {RED}[SKIPPED DUE TO ERRORS]{NOCOLOR}".format(**Init.Foreground))

	def Run(self, netlist, board):
		self._LogQuiet("{CYAN}IP core:{NOCOLOR} {0!s}".format(netlist.Parent, **Init.Foreground))

		# setup all needed paths to execute fuse
		self._PrepareCompilerEnvironment(board.Device)
		self._WriteSpecialSectionIntoConfig(board.Device)

		self._CreatePoCProject(netlist, board)
		if netlist.FilesFile is not None: self._AddFileListFile(netlist.FilesFile)
		if (netlist.RulesFile is not None):
			self._AddRulesFiles(netlist.RulesFile)

	def _PrepareCompilerEnvironment(self, device):
		self._LogNormal("Preparing synthesis environment...")
		self.Directories.Destination = self.Directories.Netlist / str(device)

		# create temporary directory for the compiler if not existent
		self._LogVerbose("Creating temporary directory for synthesizer files.")
		self._LogDebug("Temporary directory: {0!s}".format(self.Directories.Working))
		if (self.Directories.Working.exists()):
			try:
				shutil.rmtree(str(self.Directories.Working))
			except OSError as ex:
				raise CompilerException("Error while deleting '{0!s}'.".format(self.Directories.Working)) from ex
		try:
			self.Directories.Working.mkdir(parents=True)
		except OSError as ex:
			raise CompilerException("Error while creating '{0!s}'.".format(self.Directories.Working)) from ex

		# change working directory to temporary iSim path
		self._LogVerbose("Changing working directory to temporary directory.")
		self._LogDebug("cd \"{0!s}\"".format(self.Directories.Working))
		try:
			chdir(str(self.Directories.Working))
		except OSError as ex:
			raise CompilerException("Error while changing to '{0!s}'.".format(self.Directories.Working)) from ex

		# create output directory for CoreGen if not existent
		if (not self.Directories.Destination.exists()) :
			self._LogVerbose("Creating output directory for generated files.")
			self._LogDebug("Output directory: {0!s}.".format(self.Directories.Destination))
			self.Directories.Destination.mkdir(parents=True)

	def _WriteSpecialSectionIntoConfig(self, device):
		# add the key Device to section SPECIAL at runtime to change interpolation results
		self.Host.PoCConfig['SPECIAL'] = {}
		self.Host.PoCConfig['SPECIAL']['Device'] =        device.ShortName
		self.Host.PoCConfig['SPECIAL']['DeviceSeries'] =  device.Series
		self.Host.PoCConfig['SPECIAL']['OutputDir']	=      self.Directories.Working.as_posix()

	def _CreatePoCProject(self, netlist, board):
		# create a PoCProject and read all needed files
		self._LogVerbose("Creating a PoC project '{0}'".format(netlist.ModuleName))
		pocProject = VirtualProject(netlist.ModuleName)

		# configure the project
		pocProject.RootDirectory =  self.Host.Directories.Root
		pocProject.Environment =    Environment.Synthesis
		pocProject.ToolChain =      self._TOOL_CHAIN
		pocProject.Tool =            self._TOOL
		pocProject.VHDLVersion =    self._vhdlVersion
		pocProject.Board =          board

		self._pocProject =          pocProject

	def _AddFileListFile(self, fileListFilePath):
		self._LogVerbose("Reading filelist '{0!s}'".format(fileListFilePath))
		# add the *.files file, parse and evaluate it
		try:
			fileListFile = self._pocProject.AddFile(FileListFile(fileListFilePath))
			fileListFile.Parse()
			fileListFile.CopyFilesToFileSet()
			fileListFile.CopyExternalLibraries()
			self._pocProject.ExtractVHDLLibrariesFromVHDLSourceFiles()
		except ParserException as ex:
			raise CompilerException("Error while parsing '{0!s}'.".format(fileListFilePath)) from ex

		self._LogDebug("=" * 78)
		self._LogDebug("Pretty printing the PoCProject...")
		self._LogDebug(self._pocProject.pprint(2))
		self._LogDebug("=" * 78)
		if (len(fileListFile.Warnings) > 0):
			for warn in fileListFile.Warnings:
				self._LogWarning(warn)
			raise CompilerException("Found critical warnings while parsing '{0!s}'".format(fileListFilePath))

	def _AddRulesFiles(self, rulesFilePath):
		self._LogVerbose("Reading rules from '{0!s}'".format(rulesFilePath))
		# add the *.rules file, parse and evaluate it
		try:
			rulesFile = self._pocProject.AddFile(RulesFile(rulesFilePath))
			rulesFile.Parse()
		except ParserException as ex:
			raise SkipableCompilerException("Error while parsing '{0!s}'.".format(rulesFilePath)) from ex

		self._LogDebug("Pre-process rules:")
		for rule in rulesFile.PreProcessRules:
			self._LogDebug("  {0!s}".format(rule))
		self._LogDebug("Post-process rules:")
		for rule in rulesFile.PostProcessRules:
			self._LogDebug("  {0!s}".format(rule))

	def _RunPreCopy(self, netlist):
		self._LogVerbose("copy further input files into temporary directory...")
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
			if (len(preCopyRules) != 0):
				self._ParseCopyRules(preCopyRules, preCopyTasks)

		if (len(preCopyTasks) != 0):
			self._ExecuteCopyTasks(preCopyTasks, "pre")
		else:
			self._LogDebug("nothing to copy")

	def _RunPostCopy(self, netlist):
		self._LogVerbose("copy generated files into netlist directory...")
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
			if (len(postCopyRules) != 0):
				self._ParseCopyRules(postCopyRules, postCopyTasks)

		if (len(postCopyTasks) != 0):
			self._ExecuteCopyTasks(postCopyTasks, "post")
		else:
			self._LogDebug("nothing to copy")

	def _ParseCopyRules(self, rawList, copyTasks):
		# read copy tasks
		if (len(rawList) != 0):
			rawList = rawList.split("\n")
			self._LogDebug("Copy tasks from config file:\n  " + ("\n  ".join(rawList)))

			copyRegExpStr = r"^\s*(?P<SourceFilename>.*?)"  # Source filename
			copyRegExpStr += r"\s->\s"  # Delimiter signs
			copyRegExpStr += r"(?P<DestFilename>.*?)$"  # Destination filename
			copyRegExp = re.compile(copyRegExpStr)

			for item in rawList:
				preCopyRegExpMatch = copyRegExp.match(item)
				if (preCopyRegExpMatch is None):
					raise CompilerException("Error in copy rule '{0}'.".format(item))

				copyTasks.append(CopyTask(Path(preCopyRegExpMatch.group('SourceFilename')), Path(preCopyRegExpMatch.group('DestFilename'))))

	def _ExecuteCopyTasks(self, tasks, text):
		for task in tasks:
			if not task.SourcePath.exists(): raise CompilerException("Cannot {0}-copy '{1!s}' to destination.".format(text, task.SourcePath)) from FileNotFoundError(str(task.SourcePath))

			if not task.DestinationPath.parent.exists():
				task.DestinationPath.parent.mkdir(parents=True)

			self._LogDebug("{0}-copying '{1!s}'.".format(text, task.SourcePath))
			try:
				shutil.copy(str(task.SourcePath), str(task.DestinationPath))
			except OSError as ex:
				raise CompilerException("Error while copying '{0!s}'.".format(task.SourcePath)) from ex

	def _RunPostDelete(self, netlist):
		self._LogVerbose("copy generated files into netlist directory...")
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
			if (len(postDeleteRules) != 0):
				self._ParseDeleteRules(postDeleteRules, postDeleteTasks)

		if (self._noCleanUp is True):
			self._LogWarning("Disabled cleanup. Skipping post-delete rules.")
		elif (len(postDeleteTasks) != 0):
			self._ExecuteDeleteTasks(postDeleteTasks, "post")
		else:
			self._LogDebug("nothing to delete")

	def _ParseDeleteRules(self, rawList, deleteTasks):
		# read delete tasks
		if (len(rawList) != 0):
			rawList = rawList.split("\n")
			self._LogDebug("Delete tasks from config file:\n  " + ("\n  ".join(rawList)))

			deleteRegExpStr = r"^\s*(?P<Filename>.*?)$"  # filename
			deleteRegExp = re.compile(deleteRegExpStr)

			for item in rawList:
				deleteRegExpMatch = deleteRegExp.match(item)
				if (deleteRegExpMatch is None):
					raise CompilerException("Error in delete rule '{0}'.".format(item))

				deleteTasks.append(DeleteTask(Path(deleteRegExpMatch.group('Filename'))))

	def _ExecuteDeleteTasks(self, tasks, text):
		for task in tasks:
			if not task.FilePath.exists(): raise CompilerException("Cannot {0}-delete '{1!s}'.".format(text, task.FilePath)) from FileNotFoundError(str(task.FilePath))

			self._LogDebug("{0}-deleting '{1!s}'.".format(text, task.FilePath))
			task.FilePath.unlink()

	def _RunPreReplace(self, netlist):
		self._LogVerbose("patching files in temporary directory...")
		rulesFiles = [file for file in self.PoCProject.Files(fileType=FileTypes.RulesFile)]		# FIXME: get rulefile from netlist object as a rulefile object instead of a path
		preReplaceTasks = []
		if (rulesFiles):
			for rule in rulesFiles[0].PreProcessRules:
				if isinstance(rule, ReplaceRuleMixIn):
					filePath =        self.Host.PoCConfig.Interpolation.interpolate(self.Host.PoCConfig, netlist.ConfigSectionName, "RulesFile", rule.FilePath, {})
					searchPattern =    self.Host.PoCConfig.Interpolation.interpolate(self.Host.PoCConfig, netlist.ConfigSectionName, "RulesFile", rule.SearchPattern, {})
					replacePattern =  self.Host.PoCConfig.Interpolation.interpolate(self.Host.PoCConfig, netlist.ConfigSectionName, "RulesFile", rule.ReplacePattern, {})
					task = ReplaceTask(Path(filePath), searchPattern, replacePattern, rule.RegExpOption_MultiLine, rule.RegExpOption_DotAll, rule.RegExpOption_CaseInsensitive)
					preReplaceTasks.append(task)
		else:
			preReplaceRules = self.Host.PoCConfig[netlist.ConfigSectionName]['PreReplaceRules']
			if (len(preReplaceRules) != 0):
				self._ParseReplaceRules(preReplaceRules, preReplaceTasks)

		if (len(preReplaceTasks) != 0):
			self._ExecuteReplaceTasks(preReplaceTasks, "pre")
		else:
			self._LogDebug("nothing to patch")

	def _RunPostReplace(self, netlist):
		self._LogVerbose("patching files in netlist directory...")
		rulesFiles = [file for file in self.PoCProject.Files(fileType=FileTypes.RulesFile)]  # FIXME: get rulefile from netlist object as a rulefile object instead of a path
		postReplaceTasks = []
		if (rulesFiles):
			for rule in rulesFiles[0].PostProcessRules:
				if isinstance(rule, ReplaceRuleMixIn):
					filePath =        self.Host.PoCConfig.Interpolation.interpolate(self.Host.PoCConfig, netlist.ConfigSectionName, "RulesFile", rule.FilePath, {})
					searchPattern =    self.Host.PoCConfig.Interpolation.interpolate(self.Host.PoCConfig, netlist.ConfigSectionName, "RulesFile", rule.SearchPattern, {})
					replacePattern =  self.Host.PoCConfig.Interpolation.interpolate(self.Host.PoCConfig, netlist.ConfigSectionName, "RulesFile", rule.ReplacePattern, {})
					task = ReplaceTask(Path(filePath), searchPattern, replacePattern, rule.RegExpOption_MultiLine, rule.RegExpOption_DotAll, rule.RegExpOption_CaseInsensitive)
					postReplaceTasks.append(task)
		else:
			postReplaceRules = self.Host.PoCConfig[netlist.ConfigSectionName]['PostReplaceRules']
			if (len(postReplaceRules) != 0):
				self._ParseReplaceRules(postReplaceRules, postReplaceTasks)

		if (len(postReplaceTasks) != 0):
			self._ExecuteReplaceTasks(postReplaceTasks, "post")
		else:
			self._LogDebug("nothing to patch")

	def _ParseReplaceRules(self, rawList, replaceTasks):
		rawList = rawList.split("\n")
		self._LogDebug("Replacement tasks:\n  " + ("\n  ".join(rawList)))

		# FIXME: Rework inline replace rule syntax.
		replaceRegExpStr = r"^\s*(?P<Filename>.*?)\s+:"  # Filename
		replaceRegExpStr += r"(?P<Options>[dim]{0,3}):\s+"  # RegExp options
		replaceRegExpStr += r"\"(?P<Search>.*?)\"\s+->\s+"  # Search regexp
		replaceRegExpStr += r"\"(?P<Replace>.*?)\"$"  # Replace regexp
		replaceRegExp = re.compile(replaceRegExpStr)

		for item in rawList:
			replaceRegExpMatch = replaceRegExp.match(item)

			if (replaceRegExpMatch is None):
				raise CompilerException("Error in replace rule '{0}'.".format(item))

			replaceTasks.append(ReplaceTask(
				Path(replaceRegExpMatch.group('Filename')),
				replaceRegExpMatch.group('Search'),
				replaceRegExpMatch.group('Replace'),
				# replaceRegExpMatch.group('Options'),					# FIXME:
				# replaceRegExpMatch.group('Options'),					# FIXME:
				# replaceRegExpMatch.group('Options'),					# FIXME:
				False, False, False
			))

	def _ExecuteReplaceTasks(self, tasks, text):
		for task in tasks:
			if not task.FilePath.exists(): raise CompilerException("Cannot {0}-replace in file '{1!s}'.".format(text, task.FilePath)) from FileNotFoundError(str(task.FilePath))
			self._LogDebug("{0}-replace in file '{1!s}': search for '{2}' replace by '{3}'.".format(text, task.FilePath, task.SearchPattern, task.ReplacePattern))

			regExpFlags = 0
			if task.RegExpOption_CaseInsensitive:  regExpFlags |= re.IGNORECASE
			if task.RegExpOption_MultiLine:        regExpFlags |= re.MULTILINE
			if task.RegExpOption_DotAll:          regExpFlags |= re.DOTALL

			# compile regexp
			regExp = re.compile(task.SearchPattern, regExpFlags)
			# open file and read all lines
			with task.FilePath.open('r') as fileHandle:
				FileContent = fileHandle.read()
			# replace
			NewContent,replaceCount = re.subn(regExp, task.ReplacePattern, FileContent)
			if (replaceCount == 0):
				self._LogWarning("  Search pattern '{0}' not found in file '{1!s}'.".format(task.SearchPattern, task.FilePath))
			# open file to write the replaced data
			with task.FilePath.open('w') as fileHandle:
				fileHandle.write(NewContent)
