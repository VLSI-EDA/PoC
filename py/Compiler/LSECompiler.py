# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
# Authors:					Patrick Lehmann
# 
# Python Class:			This PoCXCOCompiler compiles xco IPCores to netlists
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


# load dependencies
from Base.Exceptions						import NotConfiguredException, PlatformNotSupportedException
from Base.Project								import VHDLVersion, Environment, ToolChain, Tool
from Base.Compiler							import Compiler as BaseCompiler, CompilerException
from ToolChains.Lattice.Diamond	import Diamond, SynthesisArgumentFile


class Compiler(BaseCompiler):
	_TOOL_CHAIN =	ToolChain.Lattice_Diamond
	_TOOL =				Tool.Lattice_LSE

	def __init__(self, host, showLogs, showReport):
		super(self.__class__, self).__init__(host, showLogs, showReport)

		self._diamond =		None

	def PrepareCompiler(self, binaryPath, version):
		# create the GHDL executable factory
		self._LogVerbose("  Preparing Lattice Synthesis Engine (LSE).")
		self._diamond =		Diamond(self.Host.Platform, binaryPath, version, logger=self.Logger)

	def Run(self, entity, board, **_):
		# self._entity =			entity 					 # TODO: find usages
		# self._device =			board.Device

		# setup all needed paths to execute fuse
		netlist = entity.QuartusNetlist
		self._PrepareCompilerEnvironment(board.Device)
		self._WriteSpecialSectionIntoConfig(board.Device)

		self._CreatePoCProject(netlist, board)
		self._AddFileListFile(netlist.FilesFile)
		if (netlist.RulesFile is not None):
			self._AddRulesFiles(netlist.RulesFile)

		self._LogQuiet("IP-core: {0!s}".format(netlist.Parent))

		netlist.QsfFile = self._tempPath / (netlist.ModuleName + ".prj")

		self._WriteQuartusProjectFile(netlist)

		self._LogNormal("  running Diamond LSE...")
		self._RunPrepareCompile(netlist)
		self._RunPreCopy(netlist)
		self._RunPreReplace(netlist)
		self._RunCompile(netlist, board.Device)
		self._RunPostCopy(netlist)
		self._RunPostReplace(netlist)

	def _PrepareCompilerEnvironment(self, device):
		self._LogNormal("preparing synthesis environment...")
		self._tempPath =		self.Host.Directories["LatticeTemp"]
		self._outputPath =	self.Host.Directories["PoCNetList"] / str(device)
		super()._PrepareCompilerEnvironment()

	def _WriteSpecialSectionIntoConfig(self, device):
		# add the key Device to section SPECIAL at runtime to change interpolation results
		self.Host.PoCConfig['SPECIAL'] = {}
		self.Host.PoCConfig['SPECIAL']['Device'] =				device.ShortName
		self.Host.PoCConfig['SPECIAL']['DeviceSeries'] =	device.Series
		self.Host.PoCConfig['SPECIAL']['OutputDir']	=			self._tempPath.as_posix()


	def _WriteQuartusProjectFile(self, netlist):
		argumentFile = SynthesisArgumentFile(netlist.QsfFile)
		argumentFile.Architecture =	"\"ECP5UM\""
		argumentFile.TopLevel =			netlist.ModuleName
		argumentFile.LogFile =			self._tempPath / (netlist.ModuleName + ".lse.log")

		argumentFile.Write(self.PoCProject)

	def _RunPrepareCompile(self, netlist):
		pass

	def _RunCompile(self, netlist, device):
		tclShell = self._diamond.GetTclShell()

		# raise NotImplementedError("Next: implement interactive shell")
		tclShell.Run()
