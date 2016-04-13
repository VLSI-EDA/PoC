# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
# Authors:					Patrick Lehmann
# 
# Python Class:			Base class for all PoC***Compilers
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

# entry point
import re
from pathlib import Path

import shutil

from lib.Parser import ParserException

if __name__ != "__main__":
	# place library initialization code here
	pass
else:
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Class PoCCompiler")


from os import chdir

# load dependencies
from Base.Exceptions		import ExceptionBase
from Base.Logging				import ILogable
from Base.Project				import ToolChain, Tool, VHDLVersion, Environment
from PoC.Project				import Project as PoCProject, FileListFile, RulesFile
from Parser.RulesParser	import CopyRuleMixIn, ReplaceMixIn

class CompilerException(ExceptionBase):
	pass

class CopyTask(CopyRuleMixIn):
	pass

class ReplaceTask(ReplaceMixIn):
	pass


class Compiler(ILogable):
	_TOOL_CHAIN =	ToolChain.Any
	_TOOL =				Tool.Any

	def __init__(self, host, showLogs, showReport):
		if isinstance(host, ILogable):
			ILogable.__init__(self, host.Logger)
		else:
			ILogable.__init__(self, None)

		self.__host =				host
		self.__showLogs =		showLogs
		self.__showReport =	showReport
		self.__dryRun =			False

		self._vhdlVersion =	VHDLVersion.VHDL2008
		self._pocProject =	None

		self._tempPath =		None
		self._outputPath =	None

	# class properties
	# ============================================================================
	@property
	def Host(self):						return self.__host
	@property
	def ShowLogs(self):				return self.__showLogs
	@property
	def ShowReport(self):			return self.__showReport
	@property
	def TemporaryPath(self):	return self._tempPath
	@property
	def OutputPath(self):			return self._outputPath
	@property
	def PoCProject(self):			return self._pocProject

	def _PrepareCompilerEnvironment(self):
		# create temporary directory for GHDL if not existent
		if (not (self._tempPath).exists()):
			self._LogVerbose("  Creating temporary directory for synthesizer files.")
			self._LogDebug("    Temporary directory: {0!s}".format(self._tempPath))
			self._tempPath.mkdir(parents=True)

		# change working directory to temporary iSim path
		self._LogVerbose("  Changing working directory to temporary directory.")
		self._LogDebug("    cd \"{0!s}\"".format(self._tempPath))
		chdir(str(self._tempPath))

		# create output directory for CoreGen if not existent
		if not (self._outputPath).exists() :
			self._LogVerbose("  Creating output directory for generated files.")
			self._LogDebug("    Output directory: {0!s}.".format(self._outputPath))
			self._outputPath.mkdir(parents=True)

	def _CreatePoCProject(self, netlist, board):
		# create a PoCProject and read all needed files
		self._LogVerbose("  Create a PoC project '{0}'".format(netlist.ModuleName))
		pocProject = PoCProject(netlist.ModuleName)

		# configure the project
		pocProject.RootDirectory =	self.Host.Directories["PoCRoot"]
		pocProject.Environment =		Environment.Synthesis
		pocProject.ToolChain =			self._TOOL_CHAIN
		pocProject.Tool =						self._TOOL
		pocProject.VHDLVersion =		self._vhdlVersion
		pocProject.Board =					board

		self._pocProject =					pocProject

	def _AddFileListFile(self, fileListFilePath):
		self._LogVerbose("  Reading filelist '{0!s}'".format(fileListFilePath))
		# add the *.files file, parse and evaluate it
		try:
			fileListFile = self._pocProject.AddFile(FileListFile(fileListFilePath))
			fileListFile.Parse()
			fileListFile.CopyFilesToFileSet()
			fileListFile.CopyExternalLibraries()
			self._pocProject.ExtractVHDLLibrariesFromVHDLSourceFiles()
		except ParserException as ex:
			raise CompilerException("Error while parsing '{0!s}'.".format(fileListFilePath)) from ex

		self._LogDebug(self._pocProject.pprint(2))
		self._LogDebug("=" * 160)
		if (len(fileListFile.Warnings) > 0):
			for warn in fileListFile.Warnings:
				self._LogWarning(warn)
			raise CompilerException("Found critical warnings while parsing '{0!s}'".format(fileListFilePath))

	def _AddRulesFiles(self, rulesFilePath):
		self._LogVerbose("  Reading rules from '{0!s}'".format(rulesFilePath))
		# add the *.rules file, parse and evaluate it
		try:
			rulesFile = self._pocProject.AddFile(RulesFile(rulesFilePath))
			rulesFile.Parse()
		except ParserException as ex:
			raise CompilerException("Error while parsing '{0!s}'.".format(rulesFilePath)) from ex

		self._LogDebug("    Pre-process rules:")
		for rule in rulesFile.PreProcessRules:
			self._LogDebug("      {0!s}".format(rule))
		self._LogDebug("    Post-process rules:")
		for rule in rulesFile.PostProcessRules:
			self._LogDebug("      {0!s}".format(rule))

	def _RunPreCopy(self, netlist):
		preCopyRules = self.Host.PoCConfig[netlist._sectionName]['PreCopy.Rules']
		if (len(preCopyRules) != 0):
			preCopyTasks = self._ParseCopyRules(preCopyRules)
		else:
			preCopyTasks = []

		# get more tasks from rules files
		# preCopyTasks += self.Host.PoCProject

		self._ExecuteCopyTasks(preCopyTasks, "pre")

	def _RunPostCopy(self, netlist):
		postCopyRules = self.Host.PoCConfig[netlist._sectionName]['PostCopy.Rules']
		if (len(postCopyRules) != 0):
			postCopyTasks = self._ParseCopyRules(postCopyRules)
		else:
			postCopyTasks = []

		self._ExecuteCopyTasks(postCopyTasks, "post")

	def _ParseCopyRules(self, rawList):
		# read pre-copy tasks
		copyTasks = []
		if (len(rawList) != 0):
			rawList = rawList.split("\n")
			self._LogDebug("Copy tasks from config file:\n  " + ("\n  ".join(rawList)))

			preCopyRegExpStr = r"^\s*(?P<SourceFilename>.*?)"  # Source filename
			preCopyRegExpStr += r"\s->\s"  # Delimiter signs
			preCopyRegExpStr += r"(?P<DestFilename>.*?)$"  # Destination filename
			preCopyRegExp = re.compile(preCopyRegExpStr)

			for item in rawList:
				preCopyRegExpMatch = preCopyRegExp.match(item)
				if (preCopyRegExpMatch is not None):
					copyTasks.append(CopyTask(Path(preCopyRegExpMatch.group('SourceFilename')), Path(preCopyRegExpMatch.group('DestFilename'))))
				else:
					raise CompilerException("Error in copy rule '{0}'.".format(item))
		return copyTasks

	def _ExecuteCopyTasks(self, tasks, text):
		self._LogNormal('  copy further input files into output directory...')
		for task in tasks:
			if not task.SourcePath.exists(): raise CompilerException("Can not {0}-copy '{1!s}' to destination.".format(text, task.SourcePath)) from FileNotFoundError(str(task.SourcePath))

			if not task.DestinationPath.parent.exists():
				task.DestinationPath.parent.mkdir(parents=True)

			self._LogVerbose("  {0}-copying '{1!s}'.".format(text, task.SourcePath))
			shutil.copy(str(task.SourcePath), str(task.DestinationPath))

	def _RunPreReplace(self, netlist):
		preReplaceRules = self.Host.PoCConfig[netlist._sectionName]['PreReplace.Rules']
		if (len(preReplaceRules) != 0):
			preReplaceTasks = self._ParseReplaceRules(preReplaceRules)
		else:
			preReplaceTasks = []

		self._ExecuteReplaceTasks(preReplaceTasks, "pre")

	def _RunPostReplace(self, netlist):
		postReplaceRules = self.Host.PoCConfig[netlist._sectionName]['PostReplace.Rules']
		if (len(postReplaceRules) != 0):
			postReplaceTasks = self._ParseReplaceRules(postReplaceRules)
		else:
			postReplaceTasks = []

		self._ExecuteReplaceTasks(postReplaceTasks, "post")

	def _ParseReplaceRules(self, rawList):
		replaceTasks = []
		rawList = rawList.split("\n")
		self._LogDebug("Replacement tasks:\n  " + ("\n  ".join(rawList)))

		replaceRegExpStr = r"^\s*(?P<Filename>.*?)\s+:"  # Filename
		replaceRegExpStr += r"(?P<Options>[dim]{0,3}):\s+"  # RegExp options
		replaceRegExpStr += r"\"(?P<Search>.*?)\"\s+->\s+"  # Search regexp
		replaceRegExpStr += r"\"(?P<Replace>.*?)\"$"  # Replace regexp
		replaceRegExp = re.compile(replaceRegExpStr)

		for item in rawList:
			replaceRegExpMatch = replaceRegExp.match(item)

			if (replaceRegExpMatch is not None):
				replaceTasks.append(ReplaceTask(
					Path(replaceRegExpMatch.group('Filename')),
					# replaceRegExpMatch.group('Options'),
					replaceRegExpMatch.group('Search'),
					replaceRegExpMatch.group('Replace')
				))
			else:
				raise CompilerException("Error in replace rule '{0}'.".format(item))

	def _ExecuteReplaceTasks(self, tasks, text):
		self._LogNormal("  {0}-replace in files...".format(text))
		for task in tasks:
			if not task.FilePath.exists(): raise CompilerException("Can not {0}-replace in file '{1!s}'.".format(text, task.FilePath)) from FileNotFoundError(str(task.FilePath))
			self._LogVerbose("  {0}-replace in file '{1!s}': search for '{2}' replace by '{3}'.".format(text, task.FilePath, task.SearchPattern, task.ReplacePattern))

			# FIXME: current "Search For ... Replace By ...." rules have no regexp options
			options = "i"

			regExpFlags = 0
			if ('i' in options):    regExpFlags |= re.IGNORECASE
			if ('m' in options):    regExpFlags |= re.MULTILINE
			if ('d' in options):    regExpFlags |= re.DOTALL
			# compile regexp
			regExp = re.compile(task.SearchPattern, regExpFlags)
			# open file and read all lines
			with task.FilePath.open('r') as fileHandle:
				FileContent = fileHandle.read()
			# replace
			NewContent = re.sub(regExp, task.ReplacePattern, FileContent)
			# open file to write the replaced data
			with task.FilePath.open('w') as fileHandle:
				fileHandle.write(NewContent)

	def RunAll(self, fqnList, *args, **kwargs):
		for fqn in fqnList:
			entity = fqn.Entity
			# for entity in fqn.GetEntities():
			# try:
			self.Run(entity, *args, **kwargs)
		# except SimulatorException:
		# 	pass

	def Run(self, entity, *args, **kwargs):
		raise NotImplementedError("This method is abstract.")
