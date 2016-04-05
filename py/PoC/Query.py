# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:				 	Patrick Lehmann
#
# Python Class:			TODO
#
# Description:
# ------------------------------------
#		TODO:
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
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module PoC.Query")


from pathlib							import Path

from Base.Exceptions			import NotConfiguredException, PlatformNotSupportedException
from Base.Configuration		import ConfigurationException


class Query:
	def __init__(self, host):
		self.__host = host

	@property
	def Host(self):
		return self.__host

	@property
	def Platform(self):
		return self.__host.Platform

	@property
	def PoCConfig(self):
		return self.__host.PoCConfig

	def QueryConfiguration(self, query):
		if (query == "PoC:InstallationDirectory"):
			result = self._GetPoCInstallationDirectory()
		elif (query == "ModelSim:InstallationDirectory"):
			result = self._GetModelSimInstallationDirectory()
		elif (query == "Xilinx.ISE:InstallationDirectory"):
			result = self._GetXilinxISEInstallationDirectory()
		elif (query == "Xilinx.ISE:SettingsFile"):
			result = self._GetXilinxISESettingsFile()
		elif (query == "Xilinx.Vivado:InstallationDirectory"):
			result = self._GetXilinxVivadoInstallationDirectory()
		elif (query == "Xilinx.Vivado:SettingsFile"):
			result = self._GetXilinxVivadoSettingsFile()
		else:
			raise ConfigurationException("Query string '{0}' is not supported.".format(query))

		if isinstance(result, Path):	result = str(result)
		return result

	def _GetPoCInstallationDirectory(self):
		if (len(self.PoCConfig.options("PoC")) != 0):
			return Path(self.PoCConfig['PoC']['InstallationDirectory'])
		else:
			raise NotConfiguredException("ERROR: PoC is not configured on this system.")

	def _GetModelSimInstallationDirectory(self):
		if (len(self.PoCConfig.options("Mentor.QuestaSim")) != 0):
			return Path(self.PoCConfig['Mentor.QuestaSim']['InstallationDirectory'])
		elif (len(self.PoCConfig.options("Altera.ModelSim")) != 0):
			return Path(self.PoCConfig['Altera.ModelSim']['InstallationDirectory'])
		else:
			raise NotConfiguredException("ERROR: ModelSim is not configured on this system.")

	def _GetXilinxISEInstallationDirectory(self):
		if (len(self.PoCConfig.options("Xilinx.ISE")) != 0):
			return Path(self.PoCConfig['Xilinx.ISE']['InstallationDirectory'])
		elif (len(self.PoCConfig.options("Xilinx.LabTools")) != 0):
			return Path(self.PoCConfig['Xilinx.LabTools']['InstallationDirectory'])
		else:
			raise NotConfiguredException("ERROR: Xilinx ISE or Xilinx LabTools is not configured on this system.")

	def _GetXilinxISESettingsFile(self):
		iseInstallationDirectoryPath = self._GetXilinxISEInstallationDirectory()
		if (self.Platform == "Windows"):
			return iseInstallationDirectoryPath / "settings64.bat"
		elif (self.Platform == "Linux"):
			return iseInstallationDirectoryPath / "settings64.sh"
		else:
			raise PlatformNotSupportedException(self.Platform)

	def _GetXilinxVivadoInstallationDirectory(self):
		if (len(self.PoCConfig.options("Xilinx.Vivado")) != 0):
			return Path(self.PoCConfig['Xilinx.Vivado']['InstallationDirectory'])
		elif (len(self.PoCConfig.options("Xilinx.HardwareServer")) != 0):
			return Path(self.PoCConfig['Xilinx.HardwareServer']['InstallationDirectory'])
		else:
			raise NotConfiguredException("ERROR: Xilinx Vivado or Xilinx HardwareServer is not configured on this system.")

	def _GetXilinxVivadoSettingsFile(self):
		iseInstallationDirectoryPath = self._GetXilinxVivadoInstallationDirectory()
		if (self.Platform == "Windows"):
			return iseInstallationDirectoryPath / "settings64.bat"
		elif (self.Platform == "Linux"):
			return iseInstallationDirectoryPath / "settings64.sh"
		else:
			raise PlatformNotSupportedException(self.Platform)
