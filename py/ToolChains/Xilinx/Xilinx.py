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


from Base.Project		import FileTypes, VHDLVersion
from Base.ToolChain	import ToolChainException

class XilinxException(ToolChainException):
	pass

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

