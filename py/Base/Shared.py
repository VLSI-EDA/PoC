# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#
# Python Class:     Base class for ***
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
from datetime import datetime

from PoC.TestCase import TestSuite


if __name__ != "__main__":
	# place library initialization code here
	pass
else:
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Class PoCCompiler")


# load dependencies
import shutil
from os                 import chdir

from lib.Parser         import ParserException
from Base.Exceptions    import CommonException, SkipableCommonException
from Base.Logging       import ILogable
from Base.Project       import ToolChain, Tool, VHDLVersion, Environment
from PoC.Solution       import VirtualProject, FileListFile
from PoC.TestCase				import TestSuite


# local helper function
def to_time(seconds):
	"""Convert n seconds to a str with pattern {min}:{sec:02}."""
	minutes = int(seconds / 60)
	seconds = seconds - (minutes * 60)
	return "{min}:{sec:02}".format(min=minutes, sec=seconds)


class Shared(ILogable):
	_ENVIRONMENT =    Environment.Any
	_TOOL_CHAIN =     ToolChain.Any
	_TOOL =           Tool.Any
	_vhdlVersion =    VHDLVersion.VHDL2008

	class __Directories__:
		Working = None
		PoCRoot = None

	def __init__(self, host, dryRun):
		if isinstance(host, ILogable):
			ILogable.__init__(self, host.Logger)
		else:
			ILogable.__init__(self, None)

		self._host =            host
		self._dryRun =          dryRun

		self._pocProject =      None
		self._directories =     self.__Directories__()

		self._testSuite =       None
		self._startAt =         datetime.now()
		self._endAt =           None
		self._lastEvent =       self._startAt
		self._prepareTime =     None

	# class properties
	# ============================================================================
	@property
	def Host(self):         return self._host
	@property
	def DryRun(self):       return self._dryRun
	@property
	def VHDLVersion(self):  return self._vhdlVersion
	@property
	def PoCProject(self):   return self._pocProject
	@property
	def Directories(self):  return self._directories

	def _GetTimeDeltaSinceLastEvent(self):
		now = datetime.now()
		result = now - self._lastEvent
		self._lastEvent = now
		return result

	def _Prepare(self):
		self._LogNormal("Preparing {0}.".format(self._TOOL.LongName))

	def _PrepareEnvironment(self):
		# create fresh temporary directory
		self._LogVerbose("Creating fresh temporary directory.")
		if (self.Directories.Working.exists()):
			self._LogDebug("Purging temporary directory: {0!s}".format(self.Directories.Working))
			for item in self.Directories.Working.iterdir():
				try:
					if item.is_dir():
						shutil.rmtree(str(item))
					elif item.is_file():
						item.unlink()
				except OSError as ex:
					raise CommonException("Error while deleting '{0!s}'.".format(item)) from ex
		else:
			self._LogDebug("Creating temporary directory: {0!s}".format(self.Directories.Working))
			try:
				self.Directories.Working.mkdir(parents=True)
			except OSError as ex:
				raise CommonException("Error while creating '{0!s}'.".format(self.Directories.Working)) from ex

		# change working directory to temporary path
		self._LogVerbose("Changing working directory to temporary directory.")
		self._LogDebug("cd \"{0!s}\"".format(self.Directories.Working))
		try:
			chdir(str(self.Directories.Working))
		except OSError as ex:
			raise CommonException("Error while changing to '{0!s}'.".format(self.Directories.Working)) from ex

	def _CreatePoCProject(self, projectName, board):
		# create a PoCProject and read all needed files
		self._LogVerbose("Creating PoC project '{0}'".format(projectName))
		pocProject = VirtualProject(projectName)

		# configure the project
		pocProject.RootDirectory =  self.Host.Directories.Root
		pocProject.Environment =    self._ENVIRONMENT
		pocProject.ToolChain =      self._TOOL_CHAIN
		pocProject.Tool =           self._TOOL
		pocProject.VHDLVersion =    self._vhdlVersion
		pocProject.Board =          board

		self._pocProject = pocProject

	def _AddFileListFile(self, fileListFilePath):
		self._LogVerbose("Reading filelist '{0!s}'".format(fileListFilePath))
		# add the *.files file, parse and evaluate it
		# if (not fileListFilePath.exists()):    raise SimulatorException("Files file '{0!s}' not found.".format(fileListFilePath)) from FileNotFoundError(str(fileListFilePath))

		try:
			fileListFile = self._pocProject.AddFile(FileListFile(fileListFilePath))
			fileListFile.Parse(self._host)
			fileListFile.CopyFilesToFileSet()
			fileListFile.CopyExternalLibraries()
			self._pocProject.ExtractVHDLLibrariesFromVHDLSourceFiles()
		except (ParserException, CommonException) as ex:
			raise SkipableCommonException("Error while parsing '{0!s}'.".format(fileListFilePath)) from ex

		self._LogDebug("=" * 78)
		self._LogDebug("Pretty printing the PoCProject...")
		self._LogDebug(self._pocProject.pprint(2))
		self._LogDebug("=" * 78)
		if (len(fileListFile.Warnings) > 0):
			for warn in fileListFile.Warnings:
				self._LogWarning(warn)
			raise SkipableCommonException("Found critical warnings while parsing '{0!s}'".format(fileListFilePath))
