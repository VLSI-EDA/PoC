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
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Class Compiler(PoCCompiler)")

# load dependencies
import re								# used for output filtering
import shutil
from colorama								import Fore as Foreground
from configparser						import NoSectionError
from os											import chdir
from pathlib								import Path
from textwrap								import dedent

from Base.Exceptions				import NotConfiguredException, PlatformNotSupportedException
from Base.Project						import FileTypes, VHDLVersion, Environment, ToolChain, Tool
from Base.Compiler					import Compiler as BaseCompiler, CompilerException
from PoC.Project						import Project as PoCProject, FileListFile
from ToolChains.Xilinx.ISE	import ISE


class Compiler(BaseCompiler):
	_TOOL_CHAIN =	ToolChain.Xilinx_ISE
	_TOOL =				Tool.Xilinx_CoreGen

	def __init__(self, host, showLogs, showReport):
		super(self.__class__, self).__init__(host, showLogs, showReport)

		self._entity =				None
		netlist.ConfigSectionName =		""
		self._device =					None
		self._tempPath =			None
		self._outputPath =		None
		self._ise =						None

		self._PrepareCompilerEnvironment()

	def _PrepareCompilerEnvironment(self):
		self._LogNormal("preparing synthesis environment...")
		self._tempPath =		self.Host.Directories["CoreGenTemp"]
		self._outputPath =	self.Host.Directories["PoCNetList"] / str(self._device)
		super()._PrepareCompilerEnvironment()

	def PrepareCompiler(self, binaryPath, version):
		# create the GHDL executable factory
		self._LogVerbose("  Preparing Xilinx Core Generator Tool (CoreGen).")
		self._ise = ISE(self.Host.Platform, binaryPath, version, logger=self.Logger)
		
	def Run(self, entity, board, **_):
		self._entity =				entity
		self._netlistFQN =		str(entity)  # TODO: implement FQN method on PoCEntity
		self._device =				board.Device
		
		# check testbench database for the given testbench		
		self._LogQuiet("IP-core: {0}{1}{2}".format(Foreground.YELLOW, self._netlistFQN, Foreground.RESET))

		# setup all needed paths to execute fuse
		netlist = entity.XstNetlist
		self._CreatePoCProject(netlist, board)
		# self._AddFileListFile(netlist.FilesFile)

		self._RunPrepareCompile(netlist)
		self._RunPreCopy(netlist)
		self._RunPreReplace(netlist)
		self._RunCompile(netlist)
		self._RunPostCopy(netlist)
		self._RunPostReplace(netlist)

	def _RunPrepareCompile(self, netlist):
		self._LogNormal("  preparing compiler environment for IP-core '{0}' ...".format(netlist.Parent))

		# add the key Device to section SPECIAL at runtime to change interpolation results
		self.Host.netListConfig['SPECIAL'] =							{}
		self.Host.netListConfig['SPECIAL']['Device'] =		str(self._device)
		self.Host.netListConfig['SPECIAL']['OutputDir'] =	self._tempPath.as_posix()

	def _RunCompile(self, netlist):
		# read netlist settings from configuration file
		ipCoreName = self.Host.netListConfig[netlist.ConfigSectionName]['IPCoreName']
		xcoInputFilePath = self.Host.Directories["PoCRoot"] / self.Host.netListConfig[netlist.ConfigSectionName]['CoreGeneratorFile']
		cgcTemplateFilePath = self.Host.Directories["PoCNetList"] / "template.cgc"
		cgpFilePath = self._tempPath / "coregen.cgp"
		cgcFilePath = self._tempPath / "coregen.cgc"
		xcoFilePath = self._tempPath / xcoInputFilePath.name

		if (self.Host.Platform == "Windows"):
			WorkingDirectory = ".\\temp\\"
		else:
			WorkingDirectory = "./temp/"

		# write CoreGenerator project file
		cgProjectFileContent = dedent('''\
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
			'''.format(
			Device=self._device.shortName(),
			DeviceFamily=self._device.familyName(),
			Package=(str(self._device.package) + str(self._device.pinCount)),
			SpeedGrade=self._device.speedGrade,
			WorkingDirectory=WorkingDirectory
		))

		self._LogDebug("Writing CoreGen project file to '{0}'.".format(cgpFilePath))
		with cgpFilePath.open('w') as cgpFileHandle:
			cgpFileHandle.write(cgProjectFileContent)

		# write CoreGenerator content? file
		self._LogDebug("Reading CoreGen content file to '{0}'.".format(cgcTemplateFilePath))
		with cgcTemplateFilePath.open('r') as cgcFileHandle:
			cgContentFileContent = cgcFileHandle.read()

		cgContentFileContent = cgContentFileContent.format(
			name="lcd_ChipScopeVIO",
			device=self._device.shortName(),
			devicefamily=self._device.familyName(),
			package=(str(self._device.package) + str(self._device.pinCount)),
			speedgrade=self._device.speedGrade
		)

		self._LogDebug("Writing CoreGen content file to '{0}'.".format(cgcFilePath))
		with cgcFilePath.open('w') as cgcFileHandle:
			cgcFileHandle.write(cgContentFileContent)

		# copy xco file into temporary directory
		self._LogDebug("Copy CoreGen xco file to '{0}'.".format(xcoFilePath))
		self._LogVerbose("    cp {0} {1}".format(str(xcoInputFilePath), str(self._tempPath)))
		shutil.copy(str(xcoInputFilePath), str(xcoFilePath), follow_symlinks=True)

		# change working directory to temporary CoreGen path
		self._LogVerbose('    cd {0}'.format(str(self._tempPath)))
		chdir(str(self._tempPath))

		# running CoreGen
		# ==========================================================================
		self._LogNormal("  running CoreGen...")
		binaryPath =	self.Host.Directories["ISEBinary"]
		iseVersion =			self.Host.pocConfig['Xilinx.ISE']['Version']
		coreGen = ISE.GetCoreGenerator(self.Host.Platform, binaryPath, iseVersion, logger=self.Logger)
		coreGen.Parameters[coreGen.SwitchProjectFile] =	"."		# use current directory and the default project name
		coreGen.Parameters[coreGen.SwitchBatchFile] =		str(xcoFilePath)
		coreGen.Parameters[coreGen.FlagRegenerate] =		True
		coreGen.Generate()

