# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#                   Thomas B. Preusser
#
# Python Class:     Mentor Graphics ModelSim specific classes
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
#                     Chair of VLSI-Design, Diagnostics and Architecture
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
# load dependencies
from re                           import compile as RegExpCompile
from subprocess                   import check_output

from Base.Configuration           import ConfigurationException
from ToolChains.Mentor.Mentor     import MentorException
from ToolChains.Mentor.QuestaSim  import Configuration as QuestaSim_Configuration


__api__ = [
	'ModelSimException',
	'Configuration'
]
__all__ = __api__


class ModelSimException(MentorException):
	pass


class Configuration(QuestaSim_Configuration):
	_vendor =    "Mentor"
	_toolName =  "ModelSim PE"
	_section =   "INSTALL.Mentor.ModelSimPE"
	_template = {
		"Windows": {
			_section: {
				"Version":                "10.4a",
				"InstallationDirectory":  "${INSTALL.Mentor:InstallationDirectory}/ModelSim PE/${Version}",
				"BinaryDirectory":        "${InstallationDirectory}/win32pe_edu"
			}
		},
		"Linux": {
			_section: {
				"Version":                "10.4a",
				"InstallationDirectory":  "${INSTALL.Mentor:InstallationDirectory}/ModelSim PE/${Version}",
				"BinaryDirectory":        "${InstallationDirectory}/linux32pe"
			}
		}
	}

	def CheckDependency(self):
		# return True if Mentor is configured
		return (len(self._host.PoCConfig['INSTALL.Mentor']) != 0)

	def ConfigureForAll(self):
		try:
			if (not self._AskInstalled("Is Mentor ModelSim PE installed on your system?")):
				self.ClearSection()
			else:
				version = self._ConfigureVersion()
				self._ConfigureInstallationDirectory()
				binPath = self._ConfigureBinaryDirectory()
				self.__CheckQuestaSimVersion(binPath, version)
		except ConfigurationException:
			self.ClearSection()
			raise

	def __GetModelSimVersion(self, binPath):
		if (self._host.Platform == "Windows"):
			vsimPath = binPath / "vsim.exe"
		else:
			vsimPath = binPath / "vsim"

		if not vsimPath.exists():
			raise ConfigurationException("Executable '{0!s}' not found.".format(vsimPath)) from FileNotFoundError(
				str(vsimPath))

		# get version and backend
		try:
			output = check_output([str(vsimPath), "-version"], universal_newlines=True)
		except OSError as ex:
			raise ConfigurationException("Error while accessing '{0!s}'.".format(vsimPath)) from ex

		version = None
		versionRegExpStr = r"^.* vsim (.+?) "
		versionRegExp = RegExpCompile(versionRegExpStr)
		for line in output.split('\n'):
			if version is None:
				match = versionRegExp.match(line)
				if match is not None:
					version = match.group(1)

		print(self._section, version)

		self._host.PoCConfig[self._section]['Version'] = version
