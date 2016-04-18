# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:					Patrick Lehmann
#
# Python Class:			Xilinx LabTools specific classes
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
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module ToolChains.Xilinx.LabTools")


from collections					import OrderedDict
from pathlib							import Path

# from Base.Executable							import Executable, ExecutableArgument, LongFlagArgument, ShortValuedFlagArgument, ShortTupleArgument, PathArgument
from Base.Configuration import Configuration as BaseConfiguration, ConfigurationException


class Configuration(BaseConfiguration):
	__vendor =		"Xilinx"
	__shortName = "LabTools"
	__LongName =	"Xilinx LabTools"
	__privateConfiguration = {
		"Windows": {
			"INSTALL.Xilinx.LabTools": {
				"Version":								"14.7",
				"InstallationDirectory":	"${INSTALL.Xilinx:InstallationDirectory}/${Version}/LabTools",
				"BinaryDirectory":				"${InstallationDirectory}/LabTools/bin/nt64"
			}
		},
		"Linux": {
			"INSTALL.Xilinx.LabTools": {
				"Version":								"14.7",
				"InstallationDirectory":	"${INSTALL.Xilinx:InstallationDirectory}/${Version}/LabTools",
				"BinaryDirectory":				"${InstallationDirectory}/LabTools/bin/lin64"
			}
		}
	}

	def __init__(self):
		super().__init__()

	def IsSupportedPlatform(self, Platform):
		return (Platform in self.__privateConfiguration)

	def GetSections(self, Platform):
		pass

	def manualConfigureForWindows(self):
		# Ask for installed Xilinx LabTools
		isXilinxLabTools = input('Is Xilinx LabTools installed on your system? [Y/n/p]: ')
		isXilinxLabTools = isXilinxLabTools if isXilinxLabTools != "" else "Y"
		if (isXilinxLabTools in ['p', 'P']):
			pass
		elif (isXilinxLabTools in ['n', 'N']):
			self.pocConfig['Xilinx.LabTools'] = OrderedDict()
		elif (isXilinxLabTools in ['y', 'Y']):
			xilinxDirectory = input('Xilinx installation directory [C:\Xilinx]: ')
			labToolsVersion = input('Xilinx LabTools version number [14.7]: ')
			print()

			xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "C:\Xilinx"
			labToolsVersion = labToolsVersion if labToolsVersion != "" else "14.7"

			xilinxDirectoryPath = Path(xilinxDirectory)
			labToolsDirectoryPath = xilinxDirectoryPath / labToolsVersion / "LabTools/LabTools"

			if not xilinxDirectoryPath.exists():    raise ConfigurationException(
				"Xilinx installation directory '%s' does not exist." % xilinxDirectory)
			if not labToolsDirectoryPath.exists():  raise ConfigurationException(
				"Xilinx LabTools version '%s' is not installed." % labToolsVersion)

			self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
			self.pocConfig['Xilinx.LabTools']['Version'] = labToolsVersion
			self.pocConfig['Xilinx.LabTools']['InstallationDirectory'] = '${Xilinx:InstallationDirectory}/${Version}/LabTools'
			self.pocConfig['Xilinx.LabTools']['BinaryDirectory'] = '${InstallationDirectory}/LabTools/bin/nt64'
		else:
			raise ConfigurationException("unknown option")

	def manualConfigureForLinux(self):
		# Ask for installed Xilinx LabTools
		isXilinxLabTools = input('Is Xilinx LabTools installed on your system? [Y/n/p]: ')
		isXilinxLabTools = isXilinxLabTools if isXilinxLabTools != "" else "Y"
		if (isXilinxLabTools in ['p', 'P']):
			pass
		elif (isXilinxLabTools in ['n', 'N']):
			self.pocConfig['Xilinx.LabTools'] = OrderedDict()
		elif (isXilinxLabTools in ['y', 'Y']):
			xilinxDirectory = input('Xilinx installation directory [/opt/Xilinx]: ')
			labToolsVersion = input('Xilinx LabTools version number [14.7]: ')
			print()

			xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "/opt/Xilinx"
			labToolsVersion = labToolsVersion if labToolsVersion != "" else "14.7"

			xilinxDirectoryPath = Path(xilinxDirectory)
			labToolsDirectoryPath = xilinxDirectoryPath / labToolsVersion / "LabTools/LabTools"

			if not xilinxDirectoryPath.exists():    raise ConfigurationException(
				"Xilinx installation directory '%s' does not exist." % xilinxDirectory)
			if not labToolsDirectoryPath.exists():  raise ConfigurationException(
				"Xilinx LabTools version '%s' is not installed." % labToolsVersion)

			self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
			self.pocConfig['Xilinx.LabTools']['Version'] = labToolsVersion
			self.pocConfig['Xilinx.LabTools']['InstallationDirectory'] = '${Xilinx:InstallationDirectory}/${Version}/LabTools'
			self.pocConfig['Xilinx.LabTools']['BinaryDirectory'] = '${InstallationDirectory}/LabTools/bin/lin64'
		else:
			raise ConfigurationException("unknown option")
