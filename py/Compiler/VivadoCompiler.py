# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
# Authors:          Patrick Lehmann
# 
# Python Class:      This SynthCompiler compiles VHDL source files to design checkpoints
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
if __name__ != "__main__":
	# place library initialization code here
	pass
else:
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module Compiler.XSTCompiler")


# load dependencies
from pathlib                  import Path

from Base.Project              import ToolChain, Tool
from Base.Compiler            import Compiler as BaseCompiler, CompilerException
from PoC.Entity                import WildCard
from ToolChains.Xilinx.Xilinx  import XilinxProjectExportMixIn
from ToolChains.Xilinx.Vivado  import Vivado


class Compiler(BaseCompiler):
	_TOOL_CHAIN =  ToolChain.Xilinx_Vivado
	_TOOL =        Tool.Xilinx_Synth

	def __init__(self, host, dryRun, noCleanUp):
		super().__init__(host, dryRun, noCleanUp)

		self._device =      None
		self._toolChain =    None

		configSection = host.PoCConfig['CONFIG.DirectoryNames']
		self.Directories.Working = host.Directories.Temp / configSection['VivadoSynthesisFiles']
		self.Directories.XSTFiles = host.Directories.Root / configSection['VivadoSynthesisFiles']
		self.Directories.Netlist = host.Directories.Root / configSection['NetlistFiles']

		self._PrepareCompiler()

	def _PrepareCompiler(self):
		self._LogVerbose("Preparing Xilinx Vivado Synthesis (Synth).")
		iseSection = self.Host.PoCConfig['INSTALL.Xilinx.Vivado']
		binaryPath = Path(iseSection['BinaryDirectory'])
		version = iseSection['Version']
		self._toolChain =    Vivado(self.Host.Platform, binaryPath, version, logger=self.Logger)

	def RunAll(self, fqnList, *args, **kwargs):
		for fqn in fqnList:
			entity = fqn.Entity
			if (isinstance(entity, WildCard)):
				for netlist in entity.GetVivadoNetlist():
					self.TryRun(netlist, *args, **kwargs)
			else:
				netlist = entity.VivadoNetlist
				self.TryRun(netlist, *args, **kwargs)

	def Run(self, netlist, board):
		super().Run(netlist, board)

		self._device =        board.Device
		
		self._LogNormal("Executing pre-processing tasks...")
		self._RunPreCopy(netlist)
		self._RunPreReplace(netlist)

		self._LogNormal("Running Xilinx Vivado Synthesis...")
		self._RunCompile(netlist)

		self._LogNormal("Executing post-processing tasks...")
		self._RunPostCopy(netlist)
		self._RunPostReplace(netlist)
		self._RunPostDelete(netlist)
		
	def _PrepareCompilerEnvironment(self, device):
		self._LogNormal("Preparing synthesis environment...")
		self.Directories.Destination = self.Directories.Netlist / str(device)
		super()._PrepareCompilerEnvironment()

	def _WriteSpecialSectionIntoConfig(self, device):
		# add the key Device to section SPECIAL at runtime to change interpolation results
		self.Host.PoCConfig['SPECIAL'] = {}
		self.Host.PoCConfig['SPECIAL']['Device'] =        device.FullName
		self.Host.PoCConfig['SPECIAL']['DeviceSeries'] =  device.Series
		self.Host.PoCConfig['SPECIAL']['OutputDir']	=      self.Directories.Working.as_posix()

	def _RunCompile(self, netlist):
		reportFilePath = self.Directories.Working / (netlist.ModuleName + ".log")

		synth = self._toolChain.GetSynth()
		synth.Parameters[synth.SwitchIntStyle] =    "xflow"
		synth.Parameters[synth.SwitchSynthFile] =      netlist.ModuleName + ".synth"
		synth.Parameters[synth.SwitchReportFile] =  str(reportFilePath)
		synth.Compile()
