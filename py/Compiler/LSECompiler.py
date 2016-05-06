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
from pathlib import Path

from PoC.Entity import WildCard

if __name__ != "__main__":
	# place library initialization code here
	pass
else:
	from lib.Functions import Exit

	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module Compiler.XSTCompiler")


# load dependencies
from lib.Functions							import Init
from Base.Project								import ToolChain, Tool
from Base.Compiler							import Compiler as BaseCompiler, CompilerException, SkipableCompilerException
from ToolChains.Lattice.Diamond	import Diamond, SynthesisArgumentFile


class Compiler(BaseCompiler):
	_TOOL_CHAIN =	ToolChain.Lattice_Diamond
	_TOOL =				Tool.Lattice_LSE

	def __init__(self, host, showLogs, showReport, dryRun, noCleanUp):
		super().__init__(host, showLogs, showReport, dryRun, noCleanUp)

		self._diamond =			None

		configSection = host.PoCConfig['CONFIG.DirectoryNames']
		self.Directories.Working = host.Directories.Temp / configSection['LatticeSynthesisFiles']
		self.Directories.Netlist = host.Directories.Root / configSection['NetlistFiles']
		
		self._PrepareCompiler()

	def _PrepareCompiler(self):
		self._LogVerbose("Preparing Lattice Synthesis Engine (LSE).")
		diamondSection = self.Host.PoCConfig['INSTALL.Lattice.Diamond']
		binaryPath = Path(diamondSection['BinaryDirectory'])
		version = diamondSection['Version']
		self._diamond =		Diamond(self.Host.Platform, binaryPath, version, logger=self.Logger)

	def RunAll(self, fqnList, *args, **kwargs):
		for fqn in fqnList:
			entity = fqn.Entity
			if (isinstance(entity, WildCard)):
				for netlist in entity.GetLatticeNetlists():
					try:
						self.Run(netlist, *args, **kwargs)
					except SkipableCompilerException:
						pass
			else:
				netlist = entity.LatticeNetlist
				try:
					self.Run(netlist, *args, **kwargs)
				except SkipableCompilerException:
					pass

	def Run(self, netlist, board, **_):
		self._LogQuiet("IP core: {0!s}".format(netlist.Parent, **Init.Foreground))

		# setup all needed paths to execute fuse
		self._PrepareCompilerEnvironment(board.Device)
		self._WriteSpecialSectionIntoConfig(board.Device)

		self._CreatePoCProject(netlist, board)
		self._AddFileListFile(netlist.FilesFile)
		if (netlist.RulesFile is not None):
			self._AddRulesFiles(netlist.RulesFile)

		netlist.PrjFile = self.Directories.Working / (netlist.ModuleName + ".prj")

		self._WriteLSEProjectFile(netlist)

		self._LogNormal("Executing pre-processing tasks...")
		self._RunPreCopy(netlist)
		self._RunPreReplace(netlist)

		self._LogNormal("Running Lattice Diamond LSE...")
		self._RunCompile(netlist)

		self._LogNormal("Executing post-processing tasks...")
		self._RunPostCopy(netlist)
		self._RunPostReplace(netlist)
		self._RunPostDelete(netlist)

	def _WriteSpecialSectionIntoConfig(self, device):
		# add the key Device to section SPECIAL at runtime to change interpolation results
		self.Host.PoCConfig['SPECIAL'] = {}
		self.Host.PoCConfig['SPECIAL']['Device'] =				device.ShortName
		self.Host.PoCConfig['SPECIAL']['DeviceSeries'] =	device.Series
		self.Host.PoCConfig['SPECIAL']['OutputDir']	=			self.Directories.Working.as_posix()


	def _WriteLSEProjectFile(self, netlist):
		argumentFile = SynthesisArgumentFile(netlist.PrjFile)
		argumentFile.Architecture =	"\"ECP5UM\""
		argumentFile.TopLevel =			netlist.ModuleName
		argumentFile.LogFile =			self.Directories.Working / (netlist.ModuleName + ".lse.log")

		argumentFile.Write(self.PoCProject)

	def _RunCompile(self, netlist):
		tclShell = self._diamond.GetTclShell()

		# raise NotImplementedError("Next: implement interactive shell")
		self._LogWarning("Execution skipped due to Tcl shell problems.")
		# tclShell.Run()
		# try:
		# 	q2map.Compile()
		# except QuartusException as ex:
		# 	raise CompilerException("Error while compiling '{0!s}'.".format(netlist)) from ex
		# if q2map.HasErrors:
		# 	raise CompilerException("Error while compiling '{0!s}'.".format(netlist))
