# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#
# Python Class:     This ISECompiler compiles any IPCores for the ISE tool chain
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
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module Compiler.XCOCompiler")


# load dependencies
from Base.Project           import ToolChain, Tool
from Base.Compiler          import Compiler as BaseCompiler
from PoC.Entity             import WildCard, FQN, EntityTypes
from Compiler.XCOCompiler   import Compiler as XCOCompiler
from Compiler.XSTCompiler   import Compiler as XSTCompiler


class Compiler(BaseCompiler):
	_TOOL_CHAIN =  ToolChain.Xilinx_ISE
	_TOOL =        Tool.Any

	def __init__(self, host, dryRun, noCleanUp):
		super().__init__(host, dryRun, noCleanUp)

		self._PrepareCompiler()

	def _PrepareCompiler(self):
		self._LogVerbose("Preparing Meta-Compiler for the Xilinx ISE tool chain.")

	def RunAll(self, fqnList, *args, **kwargs):
		for fqn in fqnList:
			entity = fqn.Entity
			if (isinstance(entity, WildCard)):
				for ent in entity.GetEntities():
					self.Run(ent, args, kwargs)
			else:
				self.Run(entity, args, kwargs)

	def Run(self, entity, args, kwargs):
		self._LogVerbose("Checking '{0!s}' for dependencies...".format(entity))
		dependencies =  []
		for dependency in entity.Dependencies:
			toolName, entityName = dependency.split(":")
			dependencyFQN = FQN(self.Host, entityName, defaultLibrary="PoC", defaultType=EntityTypes.NetList)
			tool = Tool.Parse(toolName)
			dependencies.append((tool, dependencyFQN))
			self._LogVerbose("  IP core: {1!s} compile with {0!s}".format(dependencyFQN, tool))

		for tool,fqn in dependencies:
			if (tool is Tool.Xilinx_CoreGen):
				compiler = XCOCompiler(self.Host, self.DryRun, self.NoCleanUp)
				compiler.RunAll([fqn], *args, **kwargs)
			elif (tool is Tool.Xilinx_XST):
				compiler = XSTCompiler(self.Host, self.DryRun, self.NoCleanUp)
				compiler.RunAll([fqn], *args, **kwargs)
