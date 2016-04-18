
#from Base.Exceptions	import CommonException
from Base.Exceptions		import CommonException
from Base.Project				import Project as BaseProject, File, FileTypes, VHDLSourceFile, VerilogSourceFile, CocotbSourceFile  #, ProjectFile
from Parser.FilesParser	import FilesParserMixIn
from Parser.RulesParser	import RulesParserMixIn


class Project(BaseProject):
	def __init__(self, name):
		super().__init__(name)

#class PoCProjectFile(ProjectFile):
#	def __init__(self, file):
#		ProjectFile.__init__(self, file)

class FileListFile(File, FilesParserMixIn):
	_FileType = FileTypes.FileListFile

	def __init__(self, file, project = None, fileSet = None):
		super().__init__(file, project=project, fileSet=fileSet)
		FilesParserMixIn.__init__(self)

		self._variables =								None

		# self.__classInclude
		self._classFileListFile =				FileListFile
		self._classVHDLSourceFile =			VHDLSourceFile
		self._classVerilogSourceFile =	VerilogSourceFile
		self._classCocotbSourceFile =		CocotbSourceFile

	def Parse(self):
		# print("FileListFile.Parse:")
		if (self._fileSet is None):											raise CommonException("File '{0!s}' is not associated to a fileset.".format(self._file))
		if (self._project is None):											raise CommonException("File '{0!s}' is not associated to a project.".format(self._file))
		if (self._project.RootDirectory is None):				raise CommonException("No RootDirectory configured for this project.")

		# prepare FilesParserMixIn environment
		self._rootDirectory = self.Project.RootDirectory
		self._variables =			self.Project.GetVariables()
		self._Parse()
		self._Resolve()

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

		self._variables =								None

	def Parse(self):
		# print("RulesFile.Parse:")
		if (self._fileSet is None):											raise CommonException("File '{0!s}' is not associated to a fileset.".format(self._file))
		if (self._project is None):											raise CommonException("File '{0!s}' is not associated to a project.".format(self._file))
		if (self._project.RootDirectory is None):				raise CommonException("No RootDirectory configured for this project.")

		# prepare FilesParserMixIn environment
		self._rootDirectory = self.Project.RootDirectory
		self._variables =			self.Project.GetVariables()
		self._Parse()
		self._Resolve()

	def __str__(self):
		return "FileList file: '{0!s}".format(self._file)
