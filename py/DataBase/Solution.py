# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#
# Python Class:     TODO
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
from collections        import OrderedDict
from textwrap           import dedent

from lib.Decorators     import ILazyLoadable, LazyLoadTrigger
from Base.Exceptions    import CommonException
from Base.Project       import Project as BaseProject, File, FileTypes, VHDLSourceFile, VerilogSourceFile, CocotbSourceFile  #, ProjectFile
from Parser.FilesParser import FilesParserMixIn
from Parser.RulesParser import RulesParserMixIn
from DataBase           import __POC_SOLUTION_KEYWORD__
from DataBase.Entity    import Visibility
from ToolChain          import ConfigurationException


__api__ = [
	'Base',
	'Repository', 'Solution', 'Project',
	'ISEProject', 'VivadoProject', 'QuartusProject', 'LatticeProject', 'VirtualProject',
	'FileListFile', 'RulesFile'
]
__all__ = __api__


class Base(ILazyLoadable):
	"""
	Base class for Repository, Solution and Project.
	It implements ILazyLoadable.
	"""
	def __init__(self, host, sectionPrefix, sectionID, parent):
		ILazyLoadable.__init__(self)

		self._host =          host
		self._id =            sectionID
		self._configSection =  "{0}.{1}".format(sectionPrefix, sectionID)
		self._parent =        parent

		self._Load()

	@property
	def ID(self):                  return self._id
	@property
	def Parent(self):              return self._parent
	@property
	def ConfigSectionName(self):  return self._configSection

	def _Load(self):
		"""Implement this method for early loading."""
		pass


class Repository(Base):
	def __init__(self, host):
		self._solutions =  {}

		kind = "Public"
		if host.PoCConfig.has_option("INSTALL.PoC", "RepositoryKind"):
			kind = host.PoCConfig['INSTALL.PoC']['RepositoryKind']
		self._kind = Visibility.Parse(kind)

		super().__init__(host, "SOLUTION", "Solutions", None)

	@property
	def Kind(self):
		return self._kind

	def _Load(self):
		self._LazyLoadable_Load()

	def __contains__(self, item):
		return (item.lower() in self._solutions)

	def __getitem__(self, item):
		return self._solutions[item.lower()]

	def _LazyLoadable_Load(self):
		super()._LazyLoadable_Load()
		# load solutions
		for slnID in self._host.PoCConfig[self._configSection]:
			if (self._host.PoCConfig[self._configSection][slnID] == __POC_SOLUTION_KEYWORD__):
				self._solutions[slnID.lower()] = Solution(self._host, slnID, self)

	def AddSolution(self, solutionID, solutionName, solutionRootPath):
		solution = Solution(self._host, solutionID, self)
		solution.Name = solutionName
		solution.Path = solutionRootPath

		self._host.PoCConfig[self._configSection][solutionID] = __POC_SOLUTION_KEYWORD__

		self._solutions[solutionID] = solution
		solution.Register()
		solution.CreateFiles()
		return solution

	def RemoveSolution(self, solution):
		if isinstance(solution, str):
			solution = self._solutions[solution.lower()]
		elif (not isinstance(solution, Solution)):
			raise ValueError("Parameter solution is not of type str or Solution.")

		solution.Unregister()
		self._host.PoCConfig.remove_option(self._configSection, solution.ID)

	@property
	@LazyLoadTrigger
	def Solutions(self):
		"""Returns the list of all registered solutions."""
		return self._solutions.values()

	@property
	@LazyLoadTrigger
	def SolutionNames(self):
		"""Returns the identifier list of all registered solutions."""
		return self._solutions.keys()


class Solution(Base):
	__SOLUTION_CONFIG_FILE__ =  "solution.config.ini"
	__SOLUTION_DEFAULT_FILE__ =  "solution.defaults.ini"

	def __init__(self, host, slnID, parent):
		super().__init__(host, "SOLUTION", slnID, parent)

		self._name =      None
		self._path =      None
		self._projects =  {}

	def Register(self):
		self._host.PoCConfig[self._configSection] = OrderedDict()
		self._host.PoCConfig[self._configSection]['Name'] = self._name
		self._host.PoCConfig[self._configSection]['Path'] = self._path.as_posix()

	def Unregister(self):
		self._host.PoCConfig.remove_section(self._configSection)

	def CreateFiles(self):
		solutionConfigPath = self._path / ".poc"
		if (not self._path.is_absolute()):
			solutionConfigPath = self._host.Directories.Root / solutionConfigPath
		try:
			solutionConfigPath.mkdir(parents=True)
		except OSError as ex:
			raise ConfigurationException("Error while creating '{0!s}'.".format(solutionConfigPath)) from ex

		solutionConfigFile = solutionConfigPath / self.__SOLUTION_CONFIG_FILE__
		with solutionConfigFile.open('w') as fileHandle:
			fileContent = dedent("""\
				[SOLUTION.{slnID}]
				DefaultLibrary =
				""".format(slnID=self._id))
			fileHandle.write(fileContent)

		solutionDefaultFile = solutionConfigPath / self.__SOLUTION_DEFAULT_FILE__
		with solutionDefaultFile.open('w') as fileHandle:
			fileContent = dedent("""\
				[SOLUTION.DEFAULTS]
				""")
			fileHandle.write(fileContent)

	def _LazyLoadable_Load(self):
		super()._LazyLoadable_Load()
		self._name = self._host.PoCConfig[self._configSection]['Name']
		self._path = self._host.Directories.Root / self._host.PoCConfig[self._configSection]['Path']

		solutionConfigPath = self._path / ".poc"
		if (not self._path.is_absolute()):
			solutionConfigPath = self._host.Directories.Root / solutionConfigPath

		configFiles = [
			solutionConfigPath / self.__SOLUTION_CONFIG_FILE__,
			solutionConfigPath / self.__SOLUTION_DEFAULT_FILE__
		]

		for configFile in configFiles:
			if (not configFile.exists()):
				raise ConfigurationException("Solution configuration file '{0!s}' not found.".format(configFile)) from FileNotFoundError(str(configFile))

			self._host.PoCConfig.read(str(configFile))

		# load projects
		for option in self._host.PoCConfig[self._configSection]:
			project = None
			if (self._host.PoCConfig[self._configSection][option] == "ISEProject"):
				project = ISEProject(self._host, option, self)
			elif (self._host.PoCConfig[self._configSection][option] == "VivadoProject"):
				project = VivadoProject(self._host, option, self)
			elif (self._host.PoCConfig[self._configSection][option] == "QuartusProject"):
				project = QuartusProject(self._host, option, self)
			elif (self._host.PoCConfig[self._configSection][option] == "LatticeProject"):
				project = LatticeProject(self._host, option, self)

			if (project is not None):
				self._projects[option.lower()] = project

	@property
	@LazyLoadTrigger
	def Name(self):
		"""Gets the name of this solution."""
		return self._name
	@Name.setter
	def Name(self, value):
		"""Sets the name of this solution."""
		self._name = value

	@property
	@LazyLoadTrigger
	def Path(self):
		"""Gets the path to the solution."""
		return self._path
	@Path.setter
	def Path(self, value):
		"""Sets the path of the solution."""
		self._path = value

	@property
	@LazyLoadTrigger
	def Projects(self):
		"""Gets a list of all registered projects."""
		return self._projects.values()

	@property
	@LazyLoadTrigger
	def ProjectNames(self):
		"""Gets a list of identifiers of all registered projects."""
		return self._projects.keys()


class Project(Base):
	def __init__(self, host, prjID, parent):
		super().__init__(host, "PROJECT", prjID, parent)

		self._name = None

	@property
	@LazyLoadTrigger
	def Name(self):
		"""Gets the name of this solution."""
		return self._name
	@Name.setter
	def Name(self, value):
		"""Sets the name of this solution."""
		self._name = value

class ISEProject(Project):
	pass


class VivadoProject(Project):
	pass


class QuartusProject(Project):
	pass


class LatticeProject(Project):
	pass


class VirtualProject(BaseProject):
	pass


class FileListFile(File, FilesParserMixIn):
	_FileType = FileTypes.FileListFile

	def __init__(self, file, project = None, fileSet = None):
		super().__init__(file, project=project, fileSet=fileSet)
		FilesParserMixIn.__init__(self)

		self._variables =               None

		self._classFileListFile =       FileListFile
		self._classVHDLSourceFile =     VHDLSourceFile
		self._classVerilogSourceFile =  VerilogSourceFile
		self._classCocotbSourceFile =   CocotbSourceFile

	def Parse(self, host):
		if (self._fileSet is None):                 raise CommonException("File '{0!s}' is not associated to a fileset.".format(self._file))
		if (self._project is None):                 raise CommonException("File '{0!s}' is not associated to a project.".format(self._file))
		if (self._project.RootDirectory is None):   raise CommonException("No RootDirectory configured for this project.")

		# prepare FilesParserMixIn environment
		self._rootDirectory = self.Project.RootDirectory
		self._variables =     self.Project.GetVariables()
		self._Parse()
		self._Resolve(host)

	def CopyFilesToFileSet(self):
		for file in self._files:
			self._fileSet.AddFile(file)

	def CopyExternalLibraries(self):
		for lib in self._libraries:
			self._project.AddExternalVHDLLibraries(lib)

	def __str__(self):
		return "FileList file: '{0!s}".format(self._file)


class RulesFile(File, RulesParserMixIn):
	_FileType = FileTypes.RulesFile

	def __init__(self, file, project = None, fileSet = None):
		super().__init__(file, project=project, fileSet=fileSet)
		RulesParserMixIn.__init__(self)

		self._variables =                None

	def Parse(self):
		if (self._fileSet is None):                      raise CommonException("File '{0!s}' is not associated to a fileset.".format(self._file))
		if (self._project is None):                      raise CommonException("File '{0!s}' is not associated to a project.".format(self._file))
		if (self._project.RootDirectory is None):        raise CommonException("No RootDirectory configured for this project.")

		# prepare FilesParserMixIn environment
		self._rootDirectory = self.Project.RootDirectory
		self._variables =      self.Project.GetVariables()
		self._Parse()
		self._Resolve()

	def __str__(self):
		return "FileList file: '{0!s}".format(self._file)
