# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:					Patrick Lehmann
#
# Python Class:			Mentor QuestaSim specific classes
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
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module ToolChains.Synopsys.Synopsys")

from Base.Configuration	import Configuration as BaseConfiguration
from Base.Project				import ConstraintFile, FileTypes
from Base.ToolChain			import ToolChainException


class SynopsysException(ToolChainException):
	pass


class Configuration(BaseConfiguration):
	_vendor =			"Synopsys"
	_toolName =		None  # automatically configure only vendor path
	_section =		"INSTALL.Synopsys"
	_template = {
		"Windows": {
			_section: {
				"InstallationDirectory": "C:/Synopsys"
			}
		},
		"Linux":   {
			_section: {
				"InstallationDirectory": "/opt/Synopsys"
			}
		}
	}

	def _GetDefaultInstallationDirectory(self):
		# synopsys = environ.get("QUARTUS_ROOTDIR")				# on Windows: D:\Synopsys\13.1\quartus
		# if (synopsys is not None):
		# 	return Path(synopsys).parent.parent

		return str(self._TestDefaultInstallPath({"Windows": "Synopsys", "Linux": "Synopsys"}))


class SynopsysDesignConstraintFile(ConstraintFile):
	_FileType = FileTypes.SdcConstraintFile

	def __str__(self):
		return "SDC file: '{0!s}".format(self._file)

