# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#
# Python Class:      TODO
#
# Description:
# ------------------------------------
#		TODO:
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
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module PoC.Query")


from pathlib              import Path

from Base.Exceptions      import NotConfiguredException, PlatformNotSupportedException
from Base.Configuration    import ConfigurationException


class Query:
	def __init__(self, host):
		self.__host = host

	@property
	def Host(self):        return self.__host
	@property
	def Platform(self):    return self.__host.Platform
	@property
	def PoCConfig(self):  return self.__host.PoCConfig

	def QueryConfiguration(self, query):
		if (query == "ModelSim:InstallationDirectory"):
			result = self._GetModelSimInstallationDirectory()
		elif (query == "Xilinx.ISE:SettingsFile"):
			result = self._GetXilinxISESettingsFile()
		elif (query == "Xilinx.Vivado:SettingsFile"):
			result = self._GetXilinxVivadoSettingsFile()
		else:
			parts = query.split(":")
			if (len(parts) == 2):
				sectionName = parts[0]
				optionName = parts[1]
				result =  self.PoCConfig["INSTALL." + sectionName][optionName]
			else:
				raise ConfigurationException("Syntax error in query string '{0}'".format(query))

		if isinstance(result, Path):  result = str(result)
		return result

	def _GetModelSimInstallationDirectory(self):
		if (len(self.PoCConfig.options('INSTALL.Mentor.QuestaSim')) != 0):
			return Path(self.PoCConfig['INSTALL.Mentor.QuestaSim']['InstallationDirectory'])
		elif (len(self.PoCConfig.options('INSTALL.Altera.ModelSim')) != 0):
			return Path(self.PoCConfig['INSTALL.Altera.ModelSim']['InstallationDirectory'])
		else:
			raise NotConfiguredException("ERROR: ModelSim is not configured on this system.")

	def _GetXilinxISESettingsFile(self):
		iseInstallationDirectoryPath = Path(self.PoCConfig['INSTALL.Xilinx.ISE']['InstallationDirectory'])
		if (self.Platform == "Windows"):
			return iseInstallationDirectoryPath / "settings64.bat"
		elif (self.Platform == "Linux"):
			return iseInstallationDirectoryPath / "settings64.sh"
		else:
			raise PlatformNotSupportedException(self.Platform)

	def _GetXilinxVivadoSettingsFile(self):
		iseInstallationDirectoryPath = Path(self.PoCConfig['INSTALL.Xilinx.Vivado']['InstallationDirectory'])
		if (self.Platform == "Windows"):
			return iseInstallationDirectoryPath / "settings64.bat"
		elif (self.Platform == "Linux"):
			return iseInstallationDirectoryPath / "settings64.sh"
		else:
			raise PlatformNotSupportedException(self.Platform)
