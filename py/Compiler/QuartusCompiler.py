# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#
# Python Module:    Altera Quartus synthesizer (compiler).
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
from datetime                   import datetime
from pathlib                    import Path

from Base.Project               import ToolChain, Tool
from DataBase.Entity            import WildCard
from ToolChains.Altera.Quartus  import QuartusException, Quartus, QuartusSettings, QuartusProjectFile
from Compiler                   import CompilerException, SkipableCompilerException, CompileState, Compiler as BaseCompiler


__api__ = [
	'Compiler'
]
__all__ = __api__


class Compiler(BaseCompiler):
	TOOL_CHAIN =      ToolChain.Altera_Quartus
	TOOL =            Tool.Altera_Quartus_Map

	def __init__(self, host, dryRun, noCleanUp):
		super().__init__(host, dryRun, noCleanUp)

		configSection = host.PoCConfig['CONFIG.DirectoryNames']
		self.Directories.Working = host.Directories.Temp / configSection['QuartusSynthesisFiles']
		self.Directories.Netlist = host.Directories.Root / configSection['NetlistFiles']

		self._PrepareCompiler()

	def _PrepareCompiler(self):
		super()._PrepareCompiler()

		# XXX: check SectionName if Quartus is configured
		# quartusSection = self.Host.PoCConfig['INSTALL.Altera.Quartus']
		# binaryPath = Path(quartusSection['BinaryDirectory'])
		# version =  quartusSection['Version']

		binaryPath =  Path(self.Host.PoCConfig['INSTALL.Quartus']['BinaryDirectory'])
		version =     self.Host.PoCConfig['INSTALL.Quartus']['Version']
		self._toolChain =    Quartus(self.Host.Platform, self.DryRun, binaryPath, version, logger=self.Logger)

	def RunAll(self, fqnList, *args, **kwargs):
		"""Run a list of netlist compilations. Expand wildcards to all selected netlists."""
		self._testSuite.StartTimer()
		self.Logger.BaseIndent = int(len(fqnList) > 1)
		try:
			for fqn in fqnList:
				entity = fqn.Entity
				if (isinstance(entity, WildCard)):
					self.Logger.BaseIndent = 1
					for netlist in entity.GetQuartusNetlists():
						self.TryRun(netlist, *args, **kwargs)
				else:
					netlist = entity.QuartusNetlist
					self.TryRun(netlist, *args, **kwargs)
		except KeyboardInterrupt:
			self.LogError("Received a keyboard interrupt.")
		finally:
			self._testSuite.StopTimer()

		self.PrintOverallCompileReport()

		return self._testSuite.IsAllSuccess

	def Run(self, netlist, board):
		super().Run(netlist, board)

		# netlist.XstFile = self.Directories.Working / (netlist.ModuleName + ".xst")
		netlist.QsfFile = self.Directories.Working / (netlist.ModuleName + ".qsf")

		self._WriteQuartusProjectFile(netlist, board.Device)
		self._prepareTime = self._GetTimeDeltaSinceLastEvent()

		self.LogNormal("Executing pre-processing tasks...")
		self._state = CompileState.PreCopy
		self._RunPreCopy(netlist)
		self._state = CompileState.PrePatch
		self._RunPreReplace(netlist)
		self._preTasksTime = self._GetTimeDeltaSinceLastEvent()

		self.LogNormal("Running Altera Quartus Map...")
		self._state = CompileState.Compile
		self._RunCompile(netlist)
		self._compileTime = self._GetTimeDeltaSinceLastEvent()

		self.LogNormal("Executing post-processing tasks...")
		self._state = CompileState.PostCopy
		self._RunPostCopy(netlist)
		self._state = CompileState.PostPatch
		self._RunPostReplace(netlist)
		self._state = CompileState.PostDelete
		self._RunPostDelete(netlist)
		self._postTasksTime = self._GetTimeDeltaSinceLastEvent()

		self._endAt = datetime.now()

	def _WriteSpecialSectionIntoConfig(self, device):
		# add the key Device to section SPECIAL at runtime to change interpolation results
		self.Host.PoCConfig['SPECIAL'] = {}
		self.Host.PoCConfig['SPECIAL']['Device'] =        device.ShortName
		self.Host.PoCConfig['SPECIAL']['DeviceSeries'] =  device.Series
		self.Host.PoCConfig['SPECIAL']['OutputDir']	=      self.Directories.Working.as_posix()


	def _WriteQuartusProjectFile(self, netlist, device):
		quartusProjectFile = QuartusProjectFile(netlist.QsfFile)

		quartusSettings = QuartusSettings(netlist.ModuleName, quartusProjectFile)
		quartusSettings.GlobalAssignments['FAMILY'] =              "\"{0}\"".format(device.Series)
		quartusSettings.GlobalAssignments['DEVICE'] =              device.ShortName
		quartusSettings.GlobalAssignments['TOP_LEVEL_ENTITY'] =    netlist.ModuleName
		quartusSettings.GlobalAssignments['VHDL_INPUT_VERSION'] =  "VHDL_2008"
		quartusSettings.Parameters.update(self._GetHDLParameters(netlist.ConfigSectionName))

		# transform files from PoCProject to global assignment commands in a QSF files
		quartusSettings.CopySourceFilesFromProject(self.PoCProject)

		quartusSettings.Write()

	def _RunCompile(self, netlist):
		q2map = self._toolChain.GetMap()
		q2map.Parameters[q2map.ArgProjectName] =  str(netlist.QsfFile)

		try:
			q2map.Compile()
		except QuartusException as ex:
			raise CompilerException("Error while compiling '{0!s}'.".format(netlist)) from ex
		if q2map.HasErrors:
			raise SkipableCompilerException("Error while compiling '{0!s}'.".format(netlist))
