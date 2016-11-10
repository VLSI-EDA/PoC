# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#
# Python Module:    TODO
#
# Description:
# ------------------------------------
#		TODO:
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
from enum               import Enum, unique
from pathlib            import Path
from flags              import Flags

from lib.Functions      import merge
from Base.Exceptions    import CommonException
from Parser.FilesParser import VHDLSourceFileMixIn, VerilogSourceFileMixIn, CocotbSourceFileMixIn
from DataBase.Config         import Board, Device


# TODO: nested filesets

class FileTypes(Flags):
	__no_flags_name__ =   "Unknown"
	__all_flags_name__ =  "Any"
	Text =                ()
	ProjectFile =         ()
	FileListFile =        ()
	RulesFile =           ()
	SourceFile =          ()
	VHDLSourceFile =      ()
	VerilogSourceFile =   ()
	PythonSourceFile =    ()
	CocotbSourceFile =    ()
	ConstraintFile =      ()
	UcfConstraintFile =   ()
	XdcConstraintFile =   ()
	SdcConstraintFile =   ()
	LdcConstraintFile =   ()
	SettingsFile =        ()
	QuartusSettingsFile = ()

	__FILE_EXTENSION_MAPPING__ = {
		Text:                 "txt",
		FileListFile:         "files",
		RulesFile:            "rules",
		VHDLSourceFile:       "vhdl",
		VerilogSourceFile:    "v",
		PythonSourceFile:     "py",
		CocotbSourceFile:     "py",
		UcfConstraintFile:    "ucf",
		XdcConstraintFile:    "xdc",
		SdcConstraintFile:    "sdc",
		LdcConstraintFile:    "ldc",
		QuartusSettingsFile:  "qsf"
	}

	def Extension(self):
		try:
			return self.__FILE_EXTENSION_MAPPING__[self]
		except KeyError:
			raise CommonException("Generic file type.")

	def __str__(self):
		return self.name

@unique
class Environment(Enum):
	Any =         0
	Simulation =  1
	Synthesis =   2


@unique
class ToolChain(Enum):
	Any =                0
	Aldec_ActiveHDL =   10
	Altera_Quartus =    20
	Altera_ModelSim =   21
	Cocotb =            30
	GHDL_GTKWave =      40
	Lattice_Diamond =   50
	Mentor_QuestaSim =  60
	Xilinx_ISE =        70
	Xilinx_PlanAhead =  71
	Xilinx_Vivado =     72


@unique
class Tool(Enum):      # ID     Short Name       Long Name
	Any =                 0
	Aldec_aSim =         ("ASIM",   "Aldec Active-HDL",         "Aldec Active-HDL")
	Altera_Quartus_Map = ("QMAP",   "Quartus Map",              "Altera Quartus Map (quartus_map)")
	Cocotb_QuestaSim =   ("COCO",   "Cocotb",                   "Coroutine Cosimulation Testbench (Cocotb)")
	GHDL =               ("GHDL",   "GHDL",                     "GHDL")
	GTKwave =            ("GTKW",   "GTKWave",                  "GTKWave")
	Lattice_LSE =        ("LSE",    "Lattice LSE",              "Lattice Synthesis Engine (LSE)")
	Mentor_vSim =        ("VSIM",   "Mentor QuestaSim",         "Mentor Graphics QuestaSim (vSim)")
	Xilinx_iSim =        ("XSIM",   "Xilinx iSim",              "Xilinx ISE Simulator (iSim)")
	Xilinx_XST =         ("XST",    "Xilinx XST",               "Xilinx Synthesis Tool (XST)")
	Xilinx_CoreGen =     ("CG",     "Xilinx CoreGen",           "Xilinx Core Generator Tool (CoreGen)")
	Xilinx_xSim =        ("XSIM",   "Xilinx xSim",              "Xilinx Vivado Simulator (xSim)")
	Xilinx_Synth =       ("VIVADO", "Xilinx Vivado Synthesis",  "Xilinx Vivado Synthesis (synth)")
	Xilinx_IPCatalog =   ("XCI",    "Xilinx Vivado IP Catalog", "Xilinx Vivado IP Catalog")

	def __init__(self, *_):
		"""Patch the embedded MAP dictionary"""
		for k, v in self.__class__.__TOOL_ID_MAPPINGS__.items():
			if ((not isinstance(v, self.__class__)) and (v == self.value)):
				self.__class__.__TOOL_ID_MAPPINGS__[k] = self

	__TOOL_ID_MAPPINGS__ = {
		"QMAP":   Altera_Quartus_Map,
		"LSE":    Lattice_LSE,
		"CG":     Xilinx_CoreGen,
		"XST":    Xilinx_XST,
		"XCI":    Xilinx_IPCatalog
	}

	@classmethod
	def Parse(cls, value):
		try:
			return cls.__TOOL_ID_MAPPINGS__[value]
		except KeyError:
			ValueError("Value '{0!s}' cannot be parsed to member of {1}.".format(value, cls.__name__))

	@property
	def ID(self):             return self.value[0]
	@property
	def ShortName(self):      return self.value[1]
	@property
	def LongName(self):       return self.value[2]

	def __str__(self):        return self.ShortName
	def __repr__(self):       return self.ID


class VHDLVersion(Enum):
	Any =                 0
	VHDL87 =             87
	VHDL93 =             93
	VHDL2002 =         2002
	VHDL2008 =         2008

	def __init__(self, *_):
		"""Patch the embedded MAP dictionary"""
		for k, v in self.__class__.__VHDL_VERSION_MAPPINGS__.items():
			if ((not isinstance(v, self.__class__)) and (v == self.value)):
				self.__class__.__VHDL_VERSION_MAPPINGS__[k] = self

	__VHDL_VERSION_MAPPINGS__ = {
		87:     VHDL87,
		93:     VHDL93,
		2:      VHDL2002,
		8:      VHDL2008,
		1987:   VHDL87,
		1993:   VHDL93,
		2002:   VHDL2002,
		2008:   VHDL2008,
		"87":   VHDL87,
		"93":   VHDL93,
		"02":   VHDL2002,
		"08":   VHDL2008,
		"1987": VHDL87,
		"1993": VHDL93,
		"2002": VHDL2002,
		"2008": VHDL2008
	}

	@classmethod
	def Parse(cls, value):
		try:
			return cls.__VHDL_VERSION_MAPPINGS__[value]
		except KeyError:
			ValueError("Value '{0!s}' cannot be parsed to member of {1}.".format(value, cls.__name__))

	def __lt__(self, other):    return self.value <  other.value
	def __le__(self, other):    return self.value <= other.value
	def __gt__(self, other):    return self.value >  other.value
	def __ge__(self, other):    return self.value >= other.value
	def __ne__(self, other):    return self.value != other.value
	def __eq__(self, other):
		if ((self is VHDLVersion.Any) or (other is VHDLVersion.Any)):
			return True
		else:
			return (self.value == other.value)

	def __str__(self):
		return "VHDL'" + str(self.value)[-2:]

	def __repr__(self):
		return str(self.value)


class Project:
	def __init__(self, name):
		self._name =                  name
		self._rootDirectory =         None
		self._fileSets =              {}
		self._defaultFileSet =        None
		self._vhdlLibraries =         {}
		self._externalVHDLLibraries = []

		self._board =                 None
		self._device =                None
		self._environment =           Environment.Any
		self._toolChain =             ToolChain.Any
		self._tool =                  Tool.Any
		self._vhdlVersion =           VHDLVersion.Any

		self.CreateFileSet("default", setDefault=True)

	@property
	def Name(self):
		return self._name

	@property
	def RootDirectory(self):
		return self._rootDirectory

	@RootDirectory.setter
	def RootDirectory(self, value):
		if isinstance(value, str):  value = Path(value)
		self._rootDirectory = value

	@property
	def Board(self):
		return self._board

	@Board.setter
	def Board(self, value):
		if isinstance(value, str):
			value = Board(value)
		elif (not isinstance(value, Board)):            raise ValueError("Parameter 'board' is not of type Board.")
		self._board =   value
		self._device =  value.Device

	@property
	def Device(self):
		return self._device

	@Device.setter
	def Device(self, value):
		if isinstance(value, (str, Device)):
			board = Board("custom", value)
		else:                                            raise ValueError("Parameter 'device' is not of type str or Device.")
		self._board =   board
		self._device =  board.Device

	@property
	def Environment(self):        return self._environment
	@Environment.setter
	def Environment(self, value): self._environment = value

	@property
	def ToolChain(self):          return self._toolChain
	@ToolChain.setter
	def ToolChain(self, value):   self._toolChain = value

	@property
	def Tool(self):               return self._tool
	@Tool.setter
	def Tool(self, value):        self._tool = value

	@property
	def VHDLVersion(self):        return self._vhdlVersion
	@VHDLVersion.setter
	def VHDLVersion(self, value): self._vhdlVersion = value


	def CreateFileSet(self, name, setDefault=True):
		fs =                      FileSet(name, project=self)
		self._fileSets[name] =    fs
		if (setDefault is True):
			self._defaultFileSet =  fs

	def AddFileSet(self, fileSet):
		if (not isinstance(fileSet, FileSet)):
			raise ValueError("Parameter 'fileSet' is not of type Base.Project.FileSet.")
		if (fileSet in self.FileSets):
			raise CommonException("Project already contains this fileSet.")
		if (fileSet.Name in self._fileSets.keys()):
			raise CommonException("Project already contains a fileset named '{0}'.".format(fileSet.Name))
		fileSet.Project = self
		self._fileSets[fileSet.Name] = fileSet

		# TODO: assign all files to this project

	@property
	def FileSets(self):
		return [i for i in self._fileSets.values()]

	@property
	def DefaultFileSet(self):
		return self._defaultFileSet

	@DefaultFileSet.setter
	def DefaultFileSet(self, value):
		if isinstance(value, str):
			if (value not in self._fileSets.keys()):      raise CommonException("Fileset '{0}' is not in this project.".format(value))
			self._defaultFileSet = self._fileSets[value]
		elif isinstance(value, FileSet):
			if (value not in self.FileSets):              raise CommonException("Fileset '{0}' is not associated to this project.".format(value))
			self._defaultFileSet = value
		else:                                           raise ValueError("Unsupported parameter type for 'value'.")

	def AddFile(self, file, fileSet = None):
		# print("Project.AddFile: file={0}".format(file))
		if (not isinstance(file, File)):                raise ValueError("Parameter 'file' is not of type Base.Project.File.")
		if (fileSet is None):
			if (self._defaultFileSet is None):            raise CommonException("Neither the parameter 'file' set nor a default file set is given.")
			fileSet = self._defaultFileSet
		elif isinstance(fileSet, str):
			fileSet = self._fileSets[fileSet]
		elif isinstance(fileSet, FileSet):
			if (fileSet not in self.FileSets):            raise CommonException("Fileset '{0}' is not associated to this project.".format(fileSet.Name))
		else:                                           raise ValueError("Unsupported parameter type for 'fileSet'.")
		fileSet.AddFile(file)
		return file

	def AddSourceFile(self, file, fileSet = None):
		# print("Project.AddSourceFile: file={0}".format(file))
		if (not isinstance(file, SourceFile)):          raise ValueError("Parameter 'file' is not of type Base.Project.SourceFile.")
		if (fileSet is None):
			if (self._defaultFileSet is None):            raise CommonException("Neither the parameter 'file' set nor a default file set is given.")
			fileSet = self._defaultFileSet
		elif isinstance(fileSet, str):
			fileSet = self._fileSets[fileSet]
		elif isinstance(fileSet, FileSet):
			if (fileSet not in self.FileSets):            raise CommonException("Fileset '{0}' is not associated to this project.".format(fileSet.Name))
		else:                                           raise ValueError("Unsupported parameter type for 'fileSet'.")
		fileSet.AddSourceFile(file)
		return file

	def Files(self, fileType=FileTypes.Any, fileSet=None):
		if (fileSet is None):
			if (self._defaultFileSet is None):            raise CommonException("Neither the parameter 'fileSet' set nor a default file set is given.")
			fileSet = self._defaultFileSet
		# print("init Project.Files generator")
		for file in fileSet.Files:
			if (file.FileType in fileType):
				yield file

	def ExtractVHDLLibrariesFromVHDLSourceFiles(self):
		for file in self.Files(fileType=FileTypes.VHDLSourceFile):
			libraryName = file.LibraryName.lower()
			if libraryName not in self._vhdlLibraries:
				self._vhdlLibraries[libraryName] = library =  VHDLLibrary(libraryName)
			else:
				library = self._vhdlLibraries[libraryName]
			library.AddFile(file)
			file.VHDLLibrary = library

	@property
	def VHDLLibraries(self):          return self._vhdlLibraries.values()
	@property
	def ExternalVHDLLibraries(self):  return self._externalVHDLLibraries

	def AddExternalVHDLLibraries(self, library):
		self._externalVHDLLibraries.append(library)

	def GetVariables(self):
		result = {
			"ProjectName":      self._name,
			"RootDirectory":    str(self._rootDirectory),
			"Environment":      self._environment.name,
			"ToolChain":        self._toolChain.name,
			"Tool":             self._tool.name,
			"VHDLVersion":      self._vhdlVersion.value
		}
		return merge(result, self._board.GetVariables(), self._device.GetVariables())

	def pprint(self, indent=0):
		_indent = "  " * indent
		buffer =  "Project: {0}\n".format(self.Name)
		buffer +=  _indent + "o-Settings:\n"
		buffer +=  _indent + "| o-Board: {0}\n".format(self._board.Name)
		buffer +=  _indent + "| o-Device: {0}\n".format(self._device.Name)
		for fileSet in self.FileSets:
			buffer += _indent + "o-FileSet: {0}\n".format(fileSet.Name)
			for file in fileSet.Files:
				buffer += _indent + "| o-{0}\n".format(file.FileName)
		buffer += _indent + "o-VHDL Libraries:\n"
		for lib in self.VHDLLibraries:
			buffer += _indent + "| o-{0}\n".format(lib.Name)
			for file in lib.Files:
				buffer += _indent + "| | o-{0}\n".format(file.Path)
		buffer += _indent + "o-External VHDL libraries:"
		for lib in self._externalVHDLLibraries:
			buffer += "\n{0}| o-{1} -> {2}".format(_indent, lib.Name, lib.Path)
		return buffer

	def __str__(self):
		return self._name

class FileSet:
	def __init__(self, name, project = None):
		# print("FileSet.__init__: name={0}  project={0}".format(name, project))
		self._name =    name
		self._project = project
		self._files =   []

	@property
	def Name(self):
		return self._name

	@property
	def Project(self):
		return self._project

	@Project.setter
	def Project(self, value):
		if not isinstance(value, Project):              raise ValueError("Parameter 'value' is not of type Base.Project.Project.")
		self._project = value

	@property
	def Files(self):
		return self._files

	def AddFile(self, file):
		# print("FileSet.AddFile: file={0}".format(file))
		if isinstance(file, str):
			file = Path(file)
			file = File(file, project=self._project, fileSet=self)
		elif isinstance(file, Path):
			file = File(file, project=self._project, fileSet=self)
		elif isinstance(file, SourceFile):
			self.AddSourceFile(file)
			return
		elif (not isinstance(file, File)):              raise ValueError("Unsupported parameter type for 'file'.")
		file.FileSet = self
		file.Project = self._project

		for f in self._files:
			if (f.FileName == file.FileName):  break
		else:
			self._files.append(file)

	def AddSourceFile(self, file):
		# print("FileSet.AddSourceFile: file={0}".format(file))
		if isinstance(file, str):
			file = Path(file)
			file = SourceFile(file, project=self._project, fileSet=self)
		elif isinstance(file, Path):
			file = SourceFile(file, project=self._project, fileSet=self)
		elif (not isinstance(file, SourceFile)):        raise ValueError("Unsupported parameter type for 'file'.")
		file.FileSet = self
		file.Project = self._project

		for f in self._files:
			if (f.FileName == file.FileName):  break
		else:
			self._files.append(file)

	def __str__(self):
		return self._name

class VHDLLibrary:
	def __init__(self, name, project = None):
		self._name =    name
		self._project = project
		self._files =   []

	@property
	def Name(self):
		return self._name

	@property
	def Project(self):
		return self._project

	@Project.setter
	def Project(self, value):
		if not isinstance(value, Project):              raise ValueError("Parameter 'value' is not of type Base.Project.Project.")
		self._project = value

	@property
	def Files(self):
		return self._files

	def AddFile(self, file):
		if (not isinstance(file, VHDLSourceFile)):      raise ValueError("Unsupported parameter type for 'file'.")
		file.VHDLLibrary = self

		for f in self._files:
			if (f.FileName == file.FileName):  break
		else:
			self._files.append(file)

	def __str__(self):
		return self._name


class File:
	_FileType = FileTypes.Unknown

	def __init__(self, file, project = None, fileSet = None):
		self._handle =  None
		self._content =  None

		if isinstance(file, str):
			file = Path(file)
		self._file =    file
		self._project = project
		self._fileSet = fileSet

	@property
	def Project(self):
		return self._project

	@Project.setter
	def Project(self, value):
		if not isinstance(value, Project):              raise ValueError("Parameter 'value' is not of type Base.Project.Project.")
		# print("File.Project(setter): value={0}".format(value))
		self._project = value

	@property
	def FileSet(self):
		return self._fileSet

	@FileSet.setter
	def FileSet(self, value):
		if (value is None):                              raise ValueError("'value' is None")
		# print("File.FileSet(setter): value={0}".format(value))
		self._fileSet = value
		self._project = value.Project

	@property
	def FileType(self):
		return self._FileType

	@property
	def FileName(self):
		return str(self._file)

	@property
	def Path(self):
		return self._file

	def Open(self):
		if (not self._file.exists()):    raise CommonException("File '{0!s}' not found.".format(self._file)) from FileNotFoundError(str(self._file))
		try:
			self._handle = self._file.open('r')
		except Exception as ex:
			raise CommonException("Error while opening file '{0!s}'.".format(self._file)) from ex

	def ReadFile(self):
		if self._handle is None:
			self.Open()
		try:
			self._content = self._handle.read()
		except Exception as ex:
			raise CommonException("Error while reading file '{0!s}'.".format(self._file)) from ex

	# interface method for FilesParserMixIn
	def _ReadContent(self):
		self.ReadFile()

	def __str__(self):
		return str(self._file)


class ProjectFile(File):
	_FileType = FileTypes.ProjectFile

	def __str__(self):
		return "Project file: '{0!s}".format(self._file)


class SourceFile(File):
	_FileType = FileTypes.SourceFile

	def __str__(self):
		return "Source file: '{0!s}".format(self._file)

class ConstraintFile(File):
	_FileType = FileTypes.ConstraintFile

	def __str__(self):
		return "Constraint file: '{0!s}".format(self._file)

class SettingsFile(File):
	_FileType = FileTypes.SettingsFile

	def __str__(self):
		return "Settings file: '{0!s}".format(self._file)


class VHDLSourceFile(SourceFile, VHDLSourceFileMixIn):
	_FileType = FileTypes.VHDLSourceFile

	def __init__(self, file, vhdlLibraryName, project = None, fileSet = None):
		super().__init__(file, project=project, fileSet=fileSet)
		VHDLSourceFileMixIn.__init__(self, file, vhdlLibraryName.lower())

	def Parse(self):
		self._Parse()# only available via late binding

	def __str__(self):
		return "VHDL file: '{0!s}".format(self._file)

class VerilogSourceFile(SourceFile, VerilogSourceFileMixIn):
	_FileType = FileTypes.VerilogSourceFile

	def __init__(self, file, project = None, fileSet = None):
		super().__init__(file, project=project, fileSet=fileSet)
		VerilogSourceFileMixIn.__init__(self, file)

	def __str__(self):
		return "Verilog file: '{0!s}".format(self._file)


class PythonSourceFile(SourceFile):
	_FileType = FileTypes.PythonSourceFile

	def __str__(self):
		return "Python file: '{0!s}".format(self._file)


class CocotbSourceFile(PythonSourceFile, CocotbSourceFileMixIn):
	_FileType = FileTypes.CocotbSourceFile

	def __init__(self, file, project=None, fileSet=None):
		super().__init__(file, project=project, fileSet=fileSet)
		CocotbSourceFileMixIn.__init__(self, file)

	def __str__(self):
		return "Cocotb file: '{0!s}".format(self._file)

