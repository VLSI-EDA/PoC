# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:					Patrick Lehmann
#
# Python Class:			TODO
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
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module  ToolChains.Aldec.Aldec")

from Base.Configuration		import Configuration as BaseConfiguration
from Base.ToolChain				import ToolChainException


class AldecException(ToolChainException):
	pass


class Configuration(BaseConfiguration):
	_vendor =			"Aldec"
	_toolName =		None  # automatically configure only vendor path
	_section  =		"INSTALL.Aldec"
	_template = {
		"Windows": {
			_section: {
				"InstallationDirectory":	"C:/Aldec"
			}
		},
		"Linux": {
			_section: {
			#	"InstallationDirectory":	"/opt/Aldec"
			}
		}
	}

	def _GetDefaultInstallationDirectory(self):
		path = self._TestDefaultInstallPath({"Windows": "Aldec", "Linux": "Aldec"})
		if path is None: return super()._GetDefaultInstallationDirectory()
		return str(path)
