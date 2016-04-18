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
from PoC.Entity import WildCard

if __name__ != "__main__":
	# place library initialization code here
	pass
else:
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Class Compiler(PoCCompiler)")

# load dependencies
import re								# used for output filtering
import shutil
from configparser						import NoSectionError
from os											import chdir
from pathlib								import Path
from textwrap								import dedent

from lib.Functions					import Init
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
		self._device =				None
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

	def RunAll(self, fqnList, *args, **kwargs):
		for fqn in fqnList:
			entity = fqn.Entity
			if (isinstance(entity, WildCard)):
				for testbench in entity.GetCGNetlist():
					try:
						self.Run(testbench, *args, **kwargs)
					except CompilerException:
						pass
			else:
				testbench = entity.CGNetlist
				try:
					self.Run(testbench, *args, **kwargs)
				except CompilerException:
					pass

	def Run(self, netlist, board, **_):
		self._LogQuiet("IP core: {YELLOW}{0!s}{RESET}".format(netlist.Parent, **Init.Foreground))

		self._device =				board.Device

		# setup all needed paths to execute fuse
		self._CreatePoCProject(netlist, board)
		if (netlist.RulesFile is not None):
			self._AddRulesFiles(netlist.RulesFile)

		self._RunPrepareCompile(netlist)
		self._RunPreCopy(netlist)
		self._RunPreReplace(netlist)
		self._RunCompile(netlist)
		self._RunPostCopy(netlist)
		self._RunPostReplace(netlist)

	def _RunPrepareCompile(self, netlist):
		self._LogNormal("  preparing compiler environment for IP-core '{0}' ...".format(netlist.Parent))

		# add the key Device to section SPECIAL at runtime to change interpolation results
		self.Host.PoCConfig['SPECIAL'] =							{}
		self.Host.PoCConfig['SPECIAL']['Device'] =		str(self._device)
		self.Host.PoCConfig['SPECIAL']['OutputDir'] =	self._tempPath.as_posix()

	def _RunCompile(self, netlist):
		# read netlist settings from configuration file
		xcoInputFilePath =		netlist.XcoFile
		cgcTemplateFilePath =	self.Host.Directories["PoCNetlist"] / "template.cgc"
		cgpFilePath =					self._tempPath / "coregen.cgp"
		cgcFilePath =					self._tempPath / "coregen.cgc"
		xcoFilePath =					self._tempPath / xcoInputFilePath.name

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
			Device=self._device.ShortName.lower(),
			DeviceFamily=self._device.FamilyName.lower(),
			Package=(str(self._device.Package).lower() + str(self._device.PinCount)),
			SpeedGrade=self._device.SpeedGrade,
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
			device=self._device.ShortName,
			devicefamily=self._device.FamilyName,
			package=(str(self._device.Package) + str(self._device.PinCount)),
			speedgrade=self._device.SpeedGrade
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
		coreGen = self._ise.GetCoreGenerator()
		coreGen.Parameters[coreGen.SwitchProjectFile] =	"."		# use current directory and the default project name
		coreGen.Parameters[coreGen.SwitchBatchFile] =		str(xcoFilePath)
		coreGen.Parameters[coreGen.FlagRegenerate] =		True
		coreGen.Generate()

