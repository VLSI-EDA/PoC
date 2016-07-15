# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
# 
# Python Class:     This PoCXCOCompiler compiles xco IPCores to netlists
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
from Base.Exceptions import PlatformNotSupportedException


if __name__ != "__main__":
	# place library initialization code here
	pass
else:
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module Compiler.XSTCompiler")


# load dependencies
from pathlib                      import Path

from Base.Compiler                import Compiler as BaseCompiler, CompilerException, SkipableCompilerException
from Base.Project                 import ToolChain, Tool, VHDLVersion
from PoC.Entity                   import WildCard
from ToolChains.Lattice.Diamond   import Diamond, SynthesisArgumentFile
from ToolChains.Lattice.Lattice import LatticeException


class Compiler(BaseCompiler):
	_TOOL_CHAIN =  ToolChain.Lattice_Diamond
	_TOOL =        Tool.Lattice_LSE

	def __init__(self, host, dryRun, noCleanUp):
		super().__init__(host, dryRun, noCleanUp)

		self._toolChain =       None
		self._vhdlVersion =     VHDLVersion.VHDL2008

		configSection = host.PoCConfig['CONFIG.DirectoryNames']
		self.Directories.Working = host.Directories.Temp / configSection['LatticeSynthesisFiles']
		self.Directories.Netlist = host.Directories.Root / configSection['NetlistFiles']
		
		self._PrepareCompiler()

	def _PrepareCompiler(self):
		self._LogVerbose("Preparing Lattice Synthesis Engine (LSE).")
		diamondSection = self.Host.PoCConfig['INSTALL.Lattice.Diamond']
		if (self.Host.Platform == "Linux"):
			binaryPath = Path(diamondSection['BinaryDirectory2'])		# ispFPGA directory
		elif (self.Host.Platform == "Windows"):
			binaryPath = Path(diamondSection['BinaryDirectory2'])		# ispFPGA directory
		else:
			raise PlatformNotSupportedException(self.Host.Platform)

		version = diamondSection['Version']
		self._toolChain =    Diamond(self.Host.Platform, binaryPath, version, logger=self.Logger)

	def RunAll(self, fqnList, *args, **kwargs):
		for fqn in fqnList:
			entity = fqn.Entity
			if (isinstance(entity, WildCard)):
				for netlist in entity.GetLatticeNetlists():
					self.TryRun(netlist, *args, **kwargs)
			else:
				netlist = entity.LatticeNetlist
				self.TryRun(netlist, *args, **kwargs)

	def Run(self, netlist, board):
		super().Run(netlist, board)

		netlist.PrjFile = self.Directories.Working / (netlist.ModuleName + ".prj")

		lseArgumentFile = self._WriteLSEProjectFile(netlist, board)

		self._LogNormal("Executing pre-processing tasks...")
		self._RunPreCopy(netlist)
		self._RunPreReplace(netlist)

		self._LogNormal("Running Lattice Diamond LSE...")
		self._RunCompile(netlist, lseArgumentFile)			# attach to netlist

		self._LogNormal("Executing post-processing tasks...")
		self._RunPostCopy(netlist)
		self._RunPostReplace(netlist)
		self._RunPostDelete(netlist)

	def _WriteLSEProjectFile(self, netlist, board):
		device = board.Device
		argumentFile = SynthesisArgumentFile(netlist.PrjFile)
		argumentFile.Architecture = "\"{0}\"".format(device.Series)
		argumentFile.Device =       "\"{0}\"".format(device.ShortName)
		argumentFile.SpeedGrade =   str(device.SpeedGrade)
		argumentFile.Package =      "{0!s}{1!s}".format(device.Package, device.PinCount)
		argumentFile.TopLevel =     netlist.ModuleName
		argumentFile.LogFile =      self.Directories.Working / (netlist.ModuleName + ".lse.log")
		argumentFile.VHDLVersion =  self._vhdlVersion

		vhdlGenerics = self.Host.PoCConfig[netlist.ConfigSectionName]['VHDLGenerics']
		if (len(vhdlGenerics) > 0):
			for keyValuePair in vhdlGenerics.split(";"):
				argumentFile.HDLParams.append(keyValuePair.split("="))

		argumentFile.Write(self.PoCProject)
		return argumentFile

	def _RunCompile(self, netlist, lseArgumentFile):
		synth = self._toolChain.GetSynthesizer()
		synth.Parameters[synth.SwitchProjectFile] = netlist.ModuleName + ".prj"

		try:
			synth.Compile(lseArgumentFile.LogFile)
		except LatticeException as ex:
			raise CompilerException("Error while compiling '{0!s}'.".format(netlist)) from ex
		if synth.HasErrors:
			raise 		SkipableCompilerException("Error while compiling '{0!s}'.".format(netlist))
