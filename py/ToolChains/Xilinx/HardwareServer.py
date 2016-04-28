# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:					Patrick Lehmann
#
# Python Class:			Xilinx Hardware Server specific classes
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
if __name__ != "__main__" :
	# place library initialization code here
	pass
else :
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module ToolChains.Xilinx.HardwareServer")


from collections					import OrderedDict
from pathlib							import Path

from Base.Configuration import Configuration as BaseConfiguration, ConfigurationException
# from Base.Executable import Executable, ExecutableArgument, LongFlagArgument, ShortValuedFlagArgument, ShortTupleArgument, PathArgument


class Configuration(BaseConfiguration):
	__vendor =		"Xilinx"
	__toolName =	"Xilinx HardwareServer"
	__template = {
		"Windows": {
			"INSTALL.Xilinx.HardwareServer": {
				"Version":								"2015.4",
				"InstallationDirectory":	"${INSTALL.Xilinx:InstallationDirectory}/Vivado/${Version}",
				"BinaryDirectory":				"${InstallationDirectory}/bin"
			}
		},
		"Linux": {
			"INSTALL.Xilinx.HardwareServer": {
				"Version":								"2015.4",
				"InstallationDirectory":	"${INSTALL.Xilinx:InstallationDirectory}/Vivado/${Version}",
				"BinaryDirectory":				"${InstallationDirectory}/bin"
			}
		}
	}

	def __init__(self):
		super().__init__()

	def IsSupportedPlatform(self, Platform):
		return (Platform in self.__template)

	def manualConfigureForWindows(self) :
		# Ask for installed Xilinx HardwareServer
		isXilinxHardwareServer = input('Is Xilinx HardwareServer installed on your system? [Y/n/p]: ')
		isXilinxHardwareServer = isXilinxHardwareServer if isXilinxHardwareServer != "" else "Y"
		if (isXilinxHardwareServer in ['p', 'P']) :
			pass
		elif (isXilinxHardwareServer in ['n', 'N']) :
			self.pocConfig['Xilinx.HardwareServer'] = OrderedDict()
		elif (isXilinxHardwareServer in ['y', 'Y']) :
			xilinxDirectory = input('Xilinx installation directory [C:\Xilinx]: ')
			hardwareServerVersion = input('Xilinx HardwareServer version number [2015.2]: ')
			print()

			xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "C:\Xilinx"
			hardwareServerVersion = hardwareServerVersion if hardwareServerVersion != "" else "2015.2"

			xilinxDirectoryPath = Path(xilinxDirectory)
			hardwareServerDirectoryPath = xilinxDirectoryPath / "HardwareServer" / hardwareServerVersion

			if not xilinxDirectoryPath.exists() :          raise ConfigurationException(
				"Xilinx installation directory '%s' does not exist." % xilinxDirectory)
			if not hardwareServerDirectoryPath.exists() :  raise ConfigurationException(
				"Xilinx HardwareServer version '%s' is not installed." % hardwareServerVersion)

			self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
			self.pocConfig['Xilinx.HardwareServer']['Version'] = hardwareServerVersion
			self.pocConfig['Xilinx.HardwareServer'][
				'InstallationDirectory'] = '${Xilinx:InstallationDirectory}/HardwareServer/${Version}'
			self.pocConfig['Xilinx.HardwareServer']['BinaryDirectory'] = '${InstallationDirectory}/bin'
		else :
			raise ConfigurationException("unknown option")

def manualConfigureForLinux(self) :
	# Ask for installed Xilinx HardwareServer
	isXilinxHardwareServer = input('Is Xilinx HardwareServer installed on your system? [Y/n/p]: ')
	isXilinxHardwareServer = isXilinxHardwareServer if isXilinxHardwareServer != "" else "Y"
	if (isXilinxHardwareServer in ['p', 'P']) :
		pass
	elif (isXilinxHardwareServer in ['n', 'N']) :
		self.pocConfig['Xilinx.HardwareServer'] = OrderedDict()
	elif (isXilinxHardwareServer in ['y', 'Y']) :
		xilinxDirectory = input('Xilinx installation directory [/opt/Xilinx]: ')
		hardwareServerVersion = input('Xilinx HardwareServer version number [2015.2]: ')
		print()

		xilinxDirectory = xilinxDirectory if xilinxDirectory != "" else "/opt/Xilinx"
		hardwareServerVersion = hardwareServerVersion if hardwareServerVersion != "" else "2015.2"

		xilinxDirectoryPath = Path(xilinxDirectory)
		hardwareServerDirectoryPath = xilinxDirectoryPath / "HardwareServer" / hardwareServerVersion

		if not xilinxDirectoryPath.exists() :          raise ConfigurationException(
			"Xilinx installation directory '%s' does not exist." % xilinxDirectory)
		if not hardwareServerDirectoryPath.exists() :  raise ConfigurationException(
			"Xilinx HardwareServer version '%s' is not installed." % hardwareServerVersion)

		self.pocConfig['Xilinx']['InstallationDirectory'] = xilinxDirectoryPath.as_posix()
		self.pocConfig['Xilinx.HardwareServer']['Version'] = hardwareServerVersion
		self.pocConfig['Xilinx.HardwareServer'][
			'InstallationDirectory'] = '${Xilinx:InstallationDirectory}/HardwareServer/${Version}'
		self.pocConfig['Xilinx.HardwareServer']['BinaryDirectory'] = '${InstallationDirectory}/bin'
	else :
		raise ConfigurationException("unknown option")
