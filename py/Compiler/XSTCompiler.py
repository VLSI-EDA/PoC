# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#
# Python Class:      This XSTCompiler compiles VHDL source files to netlists
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
from datetime                 import datetime
from pathlib                  import Path

from Base.Project             import ToolChain, Tool
from Base.Compiler            import Compiler as BaseCompiler, CompilerException, SkipableCompilerException, CompileState
from PoC.Entity               import WildCard
from ToolChains.Xilinx.Xilinx import XilinxProjectExportMixIn
from ToolChains.Xilinx.ISE    import ISE, ISEException


class Compiler(BaseCompiler, XilinxProjectExportMixIn):
	_TOOL_CHAIN =  ToolChain.Xilinx_ISE
	_TOOL =        Tool.Xilinx_XST

	class __Directories__(BaseCompiler.__Directories__):
		XSTFiles =    None

	def __init__(self, host, dryRun, noCleanUp):
		super().__init__(host, dryRun, noCleanUp)
		XilinxProjectExportMixIn.__init__(self)

		self._toolChain =    None

		configSection = host.PoCConfig['CONFIG.DirectoryNames']
		self.Directories.Working = host.Directories.Temp / configSection['ISESynthesisFiles']
		self.Directories.XSTFiles = host.Directories.Root / configSection['ISESynthesisFiles']
		self.Directories.Netlist = host.Directories.Root / configSection['NetlistFiles']

		self._PrepareCompiler()

	def _PrepareCompiler(self):
		super()._PrepareCompiler()

		iseSection = self.Host.PoCConfig['INSTALL.Xilinx.ISE']
		binaryPath = Path(iseSection['BinaryDirectory'])
		version = iseSection['Version']
		self._toolChain =    ISE(self.Host.Platform, self.DryRun, binaryPath, version, logger=self.Logger)

	def RunAll(self, fqnList, *args, **kwargs):
		"""Run a list of netlist compilations. Expand wildcards to all selected netlists."""
		self._testSuite.StartTimer()
		self.Logger.BaseIndent = int(len(fqnList) > 1)
		try:
			for fqn in fqnList:
				entity = fqn.Entity
				if (isinstance(entity, WildCard)):
					self.Logger.BaseIndent = 1
					for netlist in entity.GetXSTNetlists():
						self.TryRun(netlist, *args, **kwargs)
				else:
					netlist = entity.XSTNetlist
					self.TryRun(netlist, *args, **kwargs)
		except KeyboardInterrupt:
			self.LogError("Received a keyboard interrupt.")
		finally:
			self._testSuite.StopTimer()

		self.PrintOverallCompileReport()

		return self._testSuite.IsAllSuccess

	def Run(self, netlist, board):
		super().Run(netlist, board)

		netlist.XstFile = self.Directories.Working / (netlist.ModuleName + ".xst")
		netlist.PrjFile = self.Directories.Working / (netlist.ModuleName + ".prj")

		self._WriteXilinxProjectFile(netlist.PrjFile, "XST")
		self._WriteXstOptionsFile(netlist, board.Device)
		self._prepareTime = self._GetTimeDeltaSinceLastEvent()

		self.LogNormal("Executing pre-processing tasks...")
		self._state = CompileState.PreCopy
		self._RunPreCopy(netlist)
		self._state = CompileState.PrePatch
		self._RunPreReplace(netlist)
		self._preTasksTime = self._GetTimeDeltaSinceLastEvent()

		self.LogNormal("Running Xilinx Synthesis Tool...")
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
		self.Host.PoCConfig['SPECIAL']['Device'] =        device.FullName
		self.Host.PoCConfig['SPECIAL']['DeviceSeries'] =  device.Series
		self.Host.PoCConfig['SPECIAL']['OutputDir']	=      self.Directories.Working.as_posix()

	def _RunCompile(self, netlist):
		reportFilePath = self.Directories.Working / (netlist.ModuleName + ".log")

		xst = self._toolChain.GetXst()
		xst.Parameters[xst.SwitchIntStyle] =    "xflow"
		xst.Parameters[xst.SwitchXstFile] =      netlist.ModuleName + ".xst"
		xst.Parameters[xst.SwitchReportFile] =  str(reportFilePath)
		try:
			xst.Compile()
		except ISEException as ex:
			raise CompilerException("Error while compiling '{0!s}'.".format(netlist)) from ex
		if xst.HasErrors:
			raise SkipableCompilerException("Error while compiling '{0!s}'.".format(netlist))


	def _WriteXstOptionsFile(self, netlist, device):
		self.LogVerbose("Generating XST options file.")

		# read XST options file template
		self.LogDebug("Reading Xilinx Compiler Tool option file from '{0!s}'".format(netlist.XstTemplateFile))
		if (not netlist.XstTemplateFile.exists()):
			raise CompilerException("XST template files '{0!s}' not found.".format(netlist.XstTemplateFile))\
				from FileNotFoundError(str(netlist.XstTemplateFile))

		with netlist.XstTemplateFile.open('r') as fileHandle:
			xstFileContent = fileHandle.read()

		xstTemplateDictionary = {
			'prjFile':                                                            str(netlist.PrjFile),
			'UseNewParser': self.Host.PoCConfig[netlist.ConfigSectionName]                  ['XSTOption.UseNewParser'],
			'InputFormat': self.Host.PoCConfig[netlist.ConfigSectionName]                   ['XSTOption.InputFormat'],
			'OutputFormat': self.Host.PoCConfig[netlist.ConfigSectionName]                  ['XSTOption.OutputFormat'],
			'OutputName':                                                         netlist.ModuleName,
			'Part':                                                               str(device),
			'TopModuleName':                                                      netlist.ModuleName,
			'OptimizationMode': self.Host.PoCConfig[netlist.ConfigSectionName]              ['XSTOption.OptimizationMode'],
			'OptimizationLevel': self.Host.PoCConfig[netlist.ConfigSectionName]             ['XSTOption.OptimizationLevel'],
			'PowerReduction': self.Host.PoCConfig[netlist.ConfigSectionName]                ['XSTOption.PowerReduction'],
			'IgnoreSynthesisConstraintsFile': self.Host.PoCConfig[netlist.ConfigSectionName]['XSTOption.IgnoreSynthesisConstraintsFile'],
			'SynthesisConstraintsFile':                                           str(netlist.XcfFile),
			'KeepHierarchy': self.Host.PoCConfig[netlist.ConfigSectionName]                 ['XSTOption.KeepHierarchy'],
			'NetListHierarchy': self.Host.PoCConfig[netlist.ConfigSectionName]              ['XSTOption.NetListHierarchy'],
			'GenerateRTLView': self.Host.PoCConfig[netlist.ConfigSectionName]               ['XSTOption.GenerateRTLView'],
			'GlobalOptimization': self.Host.PoCConfig[netlist.ConfigSectionName]            ['XSTOption.Globaloptimization'],
			'ReadCores': self.Host.PoCConfig[netlist.ConfigSectionName]                     ['XSTOption.ReadCores'],
			'SearchDirectories':                                                  '"{0!s}"'.format(self.Directories.Destination),
			'WriteTimingConstraints': self.Host.PoCConfig[netlist.ConfigSectionName]        ['XSTOption.WriteTimingConstraints'],
			'CrossClockAnalysis': self.Host.PoCConfig[netlist.ConfigSectionName]            ['XSTOption.CrossClockAnalysis'],
			'HierarchySeparator': self.Host.PoCConfig[netlist.ConfigSectionName]            ['XSTOption.HierarchySeparator'],
			'BusDelimiter': self.Host.PoCConfig[netlist.ConfigSectionName]                  ['XSTOption.BusDelimiter'],
			'Case': self.Host.PoCConfig[netlist.ConfigSectionName]                          ['XSTOption.Case'],
			'SliceUtilizationRatio': self.Host.PoCConfig[netlist.ConfigSectionName]         ['XSTOption.SliceUtilizationRatio'],
			'BRAMUtilizationRatio': self.Host.PoCConfig[netlist.ConfigSectionName]          ['XSTOption.BRAMUtilizationRatio'],
			'DSPUtilizationRatio': self.Host.PoCConfig[netlist.ConfigSectionName]           ['XSTOption.DSPUtilizationRatio'],
			'LUTCombining': self.Host.PoCConfig[netlist.ConfigSectionName]                  ['XSTOption.LUTCombining'],
			'ReduceControlSets': self.Host.PoCConfig[netlist.ConfigSectionName]             ['XSTOption.ReduceControlSets'],
			'Verilog2001': self.Host.PoCConfig[netlist.ConfigSectionName]                   ['XSTOption.Verilog2001'],
			'FSMExtract': self.Host.PoCConfig[netlist.ConfigSectionName]                    ['XSTOption.FSMExtract'],
			'FSMEncoding': self.Host.PoCConfig[netlist.ConfigSectionName]                   ['XSTOption.FSMEncoding'],
			'FSMSafeImplementation': self.Host.PoCConfig[netlist.ConfigSectionName]         ['XSTOption.FSMSafeImplementation'],
			'FSMStyle': self.Host.PoCConfig[netlist.ConfigSectionName]                      ['XSTOption.FSMStyle'],
			'RAMExtract': self.Host.PoCConfig[netlist.ConfigSectionName]                    ['XSTOption.RAMExtract'],
			'RAMStyle': self.Host.PoCConfig[netlist.ConfigSectionName]                      ['XSTOption.RAMStyle'],
			'ROMExtract': self.Host.PoCConfig[netlist.ConfigSectionName]                    ['XSTOption.ROMExtract'],
			'ROMStyle': self.Host.PoCConfig[netlist.ConfigSectionName]                      ['XSTOption.ROMStyle'],
			'MUXExtract': self.Host.PoCConfig[netlist.ConfigSectionName]                    ['XSTOption.MUXExtract'],
			'MUXStyle': self.Host.PoCConfig[netlist.ConfigSectionName]                      ['XSTOption.MUXStyle'],
			'DecoderExtract': self.Host.PoCConfig[netlist.ConfigSectionName]                ['XSTOption.DecoderExtract'],
			'PriorityExtract': self.Host.PoCConfig[netlist.ConfigSectionName]               ['XSTOption.PriorityExtract'],
			'ShRegExtract': self.Host.PoCConfig[netlist.ConfigSectionName]                  ['XSTOption.ShRegExtract'],
			'ShiftExtract': self.Host.PoCConfig[netlist.ConfigSectionName]                  ['XSTOption.ShiftExtract'],
			'XorCollapse': self.Host.PoCConfig[netlist.ConfigSectionName]                   ['XSTOption.XorCollapse'],
			'AutoBRAMPacking': self.Host.PoCConfig[netlist.ConfigSectionName]               ['XSTOption.AutoBRAMPacking'],
			'ResourceSharing': self.Host.PoCConfig[netlist.ConfigSectionName]               ['XSTOption.ResourceSharing'],
			'ASyncToSync': self.Host.PoCConfig[netlist.ConfigSectionName]                   ['XSTOption.ASyncToSync'],
			'UseDSP48': self.Host.PoCConfig[netlist.ConfigSectionName]                      ['XSTOption.UseDSP48'],
			'IOBuf': self.Host.PoCConfig[netlist.ConfigSectionName]                         ['XSTOption.IOBuf'],
			'MaxFanOut': self.Host.PoCConfig[netlist.ConfigSectionName]                     ['XSTOption.MaxFanOut'],
			'BufG': self.Host.PoCConfig[netlist.ConfigSectionName]                          ['XSTOption.BufG'],
			'RegisterDuplication': self.Host.PoCConfig[netlist.ConfigSectionName]           ['XSTOption.RegisterDuplication'],
			'RegisterBalancing': self.Host.PoCConfig[netlist.ConfigSectionName]             ['XSTOption.RegisterBalancing'],
			'SlicePacking': self.Host.PoCConfig[netlist.ConfigSectionName]                  ['XSTOption.SlicePacking'],
			'OptimizePrimitives': self.Host.PoCConfig[netlist.ConfigSectionName]            ['XSTOption.OptimizePrimitives'],
			'UseClockEnable': self.Host.PoCConfig[netlist.ConfigSectionName]                ['XSTOption.UseClockEnable'],
			'UseSyncSet': self.Host.PoCConfig[netlist.ConfigSectionName]                    ['XSTOption.UseSyncSet'],
			'UseSyncReset': self.Host.PoCConfig[netlist.ConfigSectionName]                  ['XSTOption.UseSyncReset'],
			'PackIORegistersIntoIOBs': self.Host.PoCConfig[netlist.ConfigSectionName]       ['XSTOption.PackIORegistersIntoIOBs'],
			'EquivalentRegisterRemoval': self.Host.PoCConfig[netlist.ConfigSectionName]     ['XSTOption.EquivalentRegisterRemoval'],
			'SliceUtilizationRatioMaxMargin': self.Host.PoCConfig[netlist.ConfigSectionName]['XSTOption.SliceUtilizationRatioMaxMargin']
		}

		xstFileContent = xstFileContent.format(**xstTemplateDictionary)

		hdlParameters=self._GetHDLParameters(netlist.ConfigSectionName)
		if(len(hdlParameters)>0):
			xstFileContent += "-generics {"
			for keyValuePair in hdlParameters.items():
				xstFileContent += " {0}={1}".format(*keyValuePair)
			xstFileContent += " }\n"

		self.LogDebug("Writing Xilinx Compiler Tool option file to '{0!s}'".format(netlist.XstFile))
		with netlist.XstFile.open('w') as fileHandle:
			fileHandle.write(xstFileContent)
