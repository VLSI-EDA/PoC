# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:					Patrick Lehmann
#
# Python Class:			TODO
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
#
# entry point
if __name__ != "__main__":
	# place library initialization code here
	pass
else:
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module Compiler.XSTCompiler")


from collections					import OrderedDict
from pathlib							import Path
from os										import environ

from Base.Exceptions						import PlatformNotSupportedException
from Base.Logging								import LogEntry, Severity
from Base.Configuration					import Configuration as BaseConfiguration, ConfigurationException, SkipConfigurationException
from Base.Project								import FileTypes, VHDLVersion
from Base.ToolChain							import ToolChainException


class XilinxException(ToolChainException):
	pass

class Configuration(BaseConfiguration):
	_vendor =			"Xilinx"
	_shortName =	""
	_longName =		"Xilinx"
	_privateConfiguration = {
		"Windows": {
			"INSTALL.Xilinx": {
				"InstallationDirectory":	"C:/Xilinx"
			}
		},
		"Linux": {
			"INSTALL.Xilinx": {
				"InstallationDirectory":	"/opt/Xilinx"
			}
		}
	}

	def __init__(self, host):
		super().__init__(host)

	def GetSections(self, Platform):
		pass

	def ConfigureForWindows(self):
		xilinxPath = self.__GetXilinxPath()
		if (xilinxPath is not None):
			print("  Found a Xilinx installation directory.")
			xilinxPath = self.__ConfirmXilinxPath(xilinxPath)
			if (xilinxPath is None):
				xilinxPath = self.__AskXilinxPath()
		else:
			if (not self.__AskXilinx()):
				self.__ClearXilinxSections()
			else:
				xilinxPath = self.__AskXilinxPath()
		if (not xilinxPath.exists()):		raise ConfigurationException("Xilinx installation directory '{0}' does not exist.".format(xilinxPath))	from NotADirectoryError(xilinxPath)
		self.__WriteXilinxSection(xilinxPath)

	def __GetXilinxPath(self):
		xilinx = environ.get("XILINX")
		if (xilinx is not None):
			return Path(xilinx).parent.parent.parent

		xilinx = environ.get("XILINX_VIVADO")
		if (xilinx is not None):
			return Path(xilinx).parent.parent

		if (self._host.Platform == "Linux"):
			p = Path("/opt/xilinx")
			if (p.exists()):		return p
			p = Path("/opt/Xilinx")
			if (p.exists()):		return p
		elif (self._host.Platform == "Windows"):
			for drive in "CDEFGH":
				p = Path("{0}:\Xilinx".format(drive))
				try:
					if (p.exists()):	return p
				except OSError:
					pass
		return None

	def __AskXilinx(self):
		isXilinx = input("  Are Xilinx products installed on your system? [Y/n/p]: ")
		isXilinx = isXilinx if isXilinx != "" else "Y"
		if (isXilinx in ['p', 'P']):		raise SkipConfigurationException()
		elif (isXilinx in ['n', 'N']):	return False
		elif (isXilinx in ['y', 'Y']):	return True
		else:														raise ConfigurationException("Unsupported choice '{0}'".format(isXilinx))

	def __AskXilinxPath(self):
		default = Path(self._privateConfiguration[self._host.Platform]['INSTALL.Xilinx']['InstallationDirectory'])
		xilinxDirectory = input("  Xilinx installation directory [{0!s}]: ".format(default))
		if (xilinxDirectory != ""):
			return Path(xilinxDirectory)
		else:
			return default

	def __ConfirmXilinxPath(self, xilinxPath):
		# Ask for installed Xilinx ISE
		isXilinxPath = input("  Is your Xilinx software installed in '{0!s}'? [Y/n/p]: ".format(xilinxPath))
		isXilinxPath = isXilinxPath if isXilinxPath != "" else "Y"
		if (isXilinxPath in ['p', 'P']):		raise SkipConfigurationException()
		elif (isXilinxPath in ['n', 'N']):	return None
		elif (isXilinxPath in ['y', 'Y']):	return xilinxPath

	def __ClearXilinxSections(self):
		self._host.PoCConfig['INSTALL.Xilinx'] = OrderedDict()

	def __WriteXilinxSection(self, xilinxPath):
		self._host.PoCConfig['INSTALL.Xilinx']['InstallationDirectory'] = xilinxPath.as_posix()


class XilinxProjectExportMixIn:
	def __init__(self):
		pass

	def _GenerateXilinxProjectFileContent(self, tool, vhdlVersion=VHDLVersion.VHDL93):
		projectFileContent = ""
		for file in self._pocProject.Files(fileType=FileTypes.VHDLSourceFile):
			if (not file.Path.exists()):								raise XilinxException("Can not add '{0!s}' to {1} project file.".format(file.Path, tool)) from FileNotFoundError(str(file.Path))
			# create one VHDL line for each VHDL file
			if (vhdlVersion == VHDLVersion.VHDL2008):		projectFileContent += "vhdl2008 {0} \"{1!s}\"\n".format(file.LibraryName, file.Path)
			else:																				projectFileContent += "vhdl {0} \"{1!s}\"\n".format(file.LibraryName, file.Path)

		return projectFileContent

	def _WriteXilinxProjectFile(self, projectFilePath, tool, vhdlVersion=VHDLVersion.VHDL93):
		projectFileContent = self._GenerateXilinxProjectFileContent(tool, vhdlVersion)
		self._LogDebug("  Writing {0} project file to '{1!s}'".format(tool, projectFilePath))
		with projectFilePath.open('w') as prjFileHandle:
			prjFileHandle.write(projectFileContent)
