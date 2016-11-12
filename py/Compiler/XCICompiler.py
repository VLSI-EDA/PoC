# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#
# Python Class:     This XCICompiler compiles xci IPCores to netlists
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
import shutil
from datetime                 import datetime
from os                       import chdir
from pathlib                  import Path
from textwrap                 import dedent

from Base.Project             import ToolChain, Tool
from Base.Compiler            import Compiler as BaseCompiler, CompilerException, SkipableCompilerException, CompileState
from DataBase.Entity               import WildCard
from ToolChains.Xilinx.Vivado import Vivado, VivadoException


__api__ = [
	'Compiler'
]
__all__ = __api__


class Compiler(BaseCompiler):
	_TOOL_CHAIN =     ToolChain.Xilinx_Vivado
	_TOOL =           Tool.Xilinx_IPCatalog

	def __init__(self, host, dryRun, noCleanUp):
		super().__init__(host, dryRun, noCleanUp)

		self._toolChain =    None

		configSection = host.PoCConfig['CONFIG.DirectoryNames']
		self.Directories.Working = host.Directories.Temp / configSection['VivadoIPCatalogFiles']
		self.Directories.Netlist = host.Directories.Root / configSection['NetlistFiles']

		self._PrepareCompiler()

	def _PrepareCompiler(self):
		super()._PrepareCompiler()

		vivadoSection = self.Host.PoCConfig['INSTALL.Xilinx.Vivado']
		binaryPath =    Path(vivadoSection['BinaryDirectory'])
		version =       vivadoSection['Version']
		self._toolChain = Vivado(self.Host.Platform, self.DryRun, binaryPath, version, logger=self.Logger)

	def RunAll(self, fqnList, *args, **kwargs):
		"""Run a list of netlist compilations. Expand wildcards to all selected netlists."""
		self._testSuite.StartTimer()
		self.Logger.BaseIndent = int(len(fqnList) > 1)
		try:
			for fqn in fqnList:
				entity = fqn.Entity
				if (isinstance(entity, WildCard)):
					self.Logger.BaseIndent = 1
					for netlist in entity.GetCoreGenNetlists():
						self.TryRun(netlist, *args, **kwargs)
				else:
					netlist = entity.CGNetlist
					self.TryRun(netlist, *args, **kwargs)
		except KeyboardInterrupt:
			self.LogError("Received a keyboard interrupt.")
		finally:
			self._testSuite.StopTimer()

		self.PrintOverallCompileReport()

		return self._testSuite.IsAllSuccess

	def Run(self, netlist, board):
		super().Run(netlist, board)
		self._prepareTime = self._GetTimeDeltaSinceLastEvent()

		self.LogNormal("Executing pre-processing tasks...")
		self._state = CompileState.PreCopy
		self._RunPreCopy(netlist)
		self._state = CompileState.PrePatch
		self._RunPreReplace(netlist)
		self._preTasksTime = self._GetTimeDeltaSinceLastEvent()

		self.LogNormal("Running Xilinx Core Generator...")
		self._state = CompileState.Compile
		self._RunCompile(netlist, board.Device)
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
		self.Host.PoCConfig['SPECIAL']['OutputDir']	=     self.Directories.Working.as_posix()

	def _RunCompile(self, netlist, device):
		self.LogVerbose("Patching coregen.cgp and .cgc files...")
		# read netlist settings from configuration file
		xciInputFilePath =    netlist.XciFile
		cgcTemplateFilePath =  self.Directories.Netlist / "template.cgc"
		cgpFilePath =          self.Directories.Working / "coregen.cgp"
		cgcFilePath =          self.Directories.Working / "coregen.cgc"
		xciFilePath =          self.Directories.Working / xciInputFilePath.name

		if (self.Host.Platform == "Windows"):
			WorkingDirectory = ".\\temp\\"
		else:
			WorkingDirectory = "./temp/"

		# write CoreGenerator project file
		cgProjectFileContent = dedent("""\
			SET addpads = false
			SET asysymbol = false
			SET busformat = BusFormatAngleBracketNotRipped
			SET createndf = false
			SET designentry = VHDL
			SET device = {Device}
			SET devicefamily = {DeviceFamily}
			SET flowvendor = Other
			SET formalverification = false
			SET foundationsym = false
			SET implementationfiletype = Ngc
			SET package = {Package}
			SET removerpms = false
			SET simulationfiles = Behavioral
			SET speedgrade = {SpeedGrade}
			SET verilogsim = false
			SET vhdlsim = true
			SET workingdirectory = {WorkingDirectory}
			""".format(
			Device=device.ShortName.lower(),
			DeviceFamily=device.FamilyName.lower(),
			Package=(str(device.Package).lower() + str(device.PinCount)),
			SpeedGrade=device.SpeedGrade,
			WorkingDirectory=WorkingDirectory
		))

		self.LogDebug("Writing CoreGen project file to '{0}'.".format(cgpFilePath))
		with cgpFilePath.open('w') as cgpFileHandle:
			cgpFileHandle.write(cgProjectFileContent)

		# write CoreGenerator content? file
		self.LogDebug("Reading CoreGen content file to '{0}'.".format(cgcTemplateFilePath))
		with cgcTemplateFilePath.open('r') as cgcFileHandle:
			cgContentFileContent = cgcFileHandle.read()

		cgContentFileContent = cgContentFileContent.format(
			name="lcd_ChipScopeVIO",
			device=device.ShortName,
			devicefamily=device.FamilyName,
			package=(str(device.Package) + str(device.PinCount)),
			speedgrade=device.SpeedGrade
		)

		self.LogDebug("Writing CoreGen content file to '{0}'.".format(cgcFilePath))
		with cgcFilePath.open('w') as cgcFileHandle:
			cgcFileHandle.write(cgContentFileContent)

		# copy xci file into temporary directory
		self.LogVerbose("Copy CoreGen xci file to '{0}'.".format(xciFilePath))
		self.LogDebug("cp {0!s} {1!s}".format(xciInputFilePath, self.Directories.Working))
		try:
			shutil.copy(str(xciInputFilePath), str(xciFilePath), follow_symlinks=True)
		except OSError as ex:
			raise CompilerException("Error while copying '{0!s}'.".format(xciInputFilePath)) from ex

		# change working directory to temporary CoreGen path
		self.LogDebug("cd {0!s}".format(self.Directories.Working))
		try:
			chdir(str(self.Directories.Working))
		except OSError as ex:
			raise CompilerException("Error while changing to '{0!s}'.".format(self.Directories.Working)) from ex

		# running CoreGen
		# ==========================================================================
		self.LogVerbose("Executing CoreGen...")
		coreGen = self._toolChain.GetCoreGenerator()
		coreGen.Parameters[coreGen.SwitchProjectFile] =  "."		# use current directory and the default project name
		coreGen.Parameters[coreGen.SwitchBatchFile] =    str(xciFilePath)
		coreGen.Parameters[coreGen.FlagRegenerate] =    True

		try:
			coreGen.Generate()
		except VivadoException as ex:
			raise CompilerException("Error while compiling '{0!s}'.".format(netlist)) from ex
		if coreGen.HasErrors:
			raise SkipableCompilerException("Error while compiling '{0!s}'.".format(netlist))

	def _WriteTclFile(self, netlist, device):
		buffer = dedent("""\
			create_project -in_memory -part {part}

			set_param synth.vivado.isSynthRun true
			set_property target_language VHDL [current_project]

			read_ip -quiet {xciFile}go

			synth_design -top {ipCoreName} -part {part} -mode out_of_context

			write_checkpoint -noxdef {top}.dcp

			if { [catch {
				report_utilization -file {top}_synth.rpt -pb {top}_synth.pb
			} _RESULT ] } {
				puts "CRITICAL WARNING: Error reported: $_RESULT"
			}

			if { [catch {
				write_verilog -force -mode synth_stub {xciFilebaseName}_stub.v
			} _RESULT ] } {
				puts "CRITICAL WARNING: Unable to successfully create a Verilog synthesis stub for the sub-design. Error reported: $_RESULT"
			}

			if { [catch {
				write_vhdl -force -mode synth_stub {xciFilebaseName}_stub.vhdl
			} _RESULT ] } {
				puts "CRITICAL WARNING: Unable to successfully create a VHDL synthesis stub for the sub-design. Error reported: $_RESULT"
			}

			if { [catch {
				write_verilog -force -mode funcsim {xciFilebaseName}_sim_netlist.v
			} _RESULT ] } {
				puts "CRITICAL WARNING: Unable to successfully create the Verilog functional simulation sub-design file. Error reported: $_RESULT"
			}

			if { [catch {
				write_vhdl -force -mode funcsim {xciFilebaseName}_sim_netlist.vhdl
			} _RESULT ] } {
				puts "CRITICAL WARNING: Unable to successfully create the VHDL functional simulation sub-design file. Error reported: $_RESULT"
			}
			""").format(
				part=device.FullName2,
				xciFile=xciFile.as_posix(),
				xciFilebaseName=xciFile.BaseName,
				top=netlist.ModuleName,
				ipCoreName="foo.xci"
			)

		self.LogDebug("Writing Vivado TCL file to '{0!s}'".format(netlist.TclFile))
		with netlist.TclFile.open('w') as tclFileHandle:
			tclFileHandle.write(buffer)
