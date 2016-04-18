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
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module Compiler.XSTCompiler")


from collections					import OrderedDict
from pathlib							import Path
from os										import environ

from Base.Exceptions						import PlatformNotSupportedException
from Base.Logging								import LogEntry, Severity
from Base.Configuration					import Configuration as BaseConfiguration, ConfigurationException, SkipConfigurationException
from Base.ToolChain							import ToolChainException


class AlteraException(ToolChainException):
	pass

class Configuration(BaseConfiguration):
	_vendor =			"Altera"
	_shortName =	""
	_longName =		"Altera"
	_privateConfiguration = {
		"Windows": {
			"INSTALL.Altera": {
				"InstallationDirectory":	"C:/Altera"
			}
		},
		"Linux": {
			"INSTALL.Altera": {
				"InstallationDirectory":	"/opt/Altera"
			}
		}
	}

	def __init__(self, host):
		super().__init__(host)

	def GetSections(self, Platform):
		pass

	def ConfigureForWindows(self):
		xilinxPath = self.__GetAlteraPath()
		if (xilinxPath is not None):
			print("  Found a Altera installation directory.")
			xilinxPath = self.__ConfirmAlteraPath(xilinxPath)
			if (xilinxPath is None):
				xilinxPath = self.__AskAlteraPath()
		else:
			if (not self.__AskAltera()):
				self.__ClearAlteraSections()
			else:
				xilinxPath = self.__AskAlteraPath()
		if (not xilinxPath.exists()):		raise ConfigurationException("Altera installation directory '{0}' does not exist.".format(xilinxPath))	from NotADirectoryError(xilinxPath)
		self.__WriteAlteraSection(xilinxPath)

	def __GetAlteraPath(self):
		xilinx = environ.get("XILINX")
		if (xilinx is not None):
			return Path(xilinx).parent.parent.parent

		xilinx = environ.get("XILINX_VIVADO")
		if (xilinx is not None):
			return Path(xilinx).parent.parent

		if (self._host.Platform == "Linux"):
			p = Path("/opt/xilinx")
			if (p.exists()):		return p
			p = Path("/opt/Altera")
			if (p.exists()):		return p
		elif (self._host.Platform == "Windows"):
			for drive in "CDEFGH":
				p = Path("{0}:\Altera".format(drive))
				try:
					if (p.exists()):	return p
				except WindowsError:
					pass
		return None

	def __AskAltera(self):
		isAltera = input("  Are Altera products installed on your system? [Y/n/p]: ")
		isAltera = isAltera if isAltera != "" else "Y"
		if (isAltera in ['p', 'P']):		raise SkipConfigurationException()
		elif (isAltera in ['n', 'N']):	return False
		elif (isAltera in ['y', 'Y']):	return True
		else:														raise ConfigurationException("Unsupported choice '{0}'".format(isAltera))

	def __AskAlteraPath(self):
		default = Path(self._privateConfiguration[self._host.Platform]['INSTALL.Altera']['InstallationDirectory'])
		xilinxDirectory = input("  Altera installation directory [{0!s}]: ".format(default))
		if (xilinxDirectory != ""):
			return Path(xilinxDirectory)
		else:
			return default

	def __ConfirmAlteraPath(self, xilinxPath):
		# Ask for installed Altera ISE
		isAlteraPath = input("  Is your Altera software installed in '{0!s}'? [Y/n/p]: ".format(xilinxPath))
		isAlteraPath = isAlteraPath if isAlteraPath != "" else "Y"
		if (isAlteraPath in ['p', 'P']):		raise SkipConfigurationException()
		elif (isAlteraPath in ['n', 'N']):	return None
		elif (isAlteraPath in ['y', 'Y']):	return xilinxPath

	def __ClearAlteraSections(self):
		self._host.PoCConfig['INSTALL.Altera'] = OrderedDict()

	def __WriteAlteraSection(self, xilinxPath):
		self._host.PoCConfig['INSTALL.Altera']['InstallationDirectory'] = xilinxPath.as_posix()

