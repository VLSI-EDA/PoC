# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#
# Python Class:     Mentor ModelSim specific classes
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
from lib.Functions              import Init
from ToolChain                  import ConfigurationException
from ToolChain.Mentor.ModelSim  import ModelSimException, Configuration as ModelSim_Configuration


__api__ = [
	'QuestaSimException',
	'Configuration'
]
__all__ = __api__


class QuestaSimException(ModelSimException):
	pass


class Configuration(ModelSim_Configuration):
	_vendor =               "Mentor"                    #: The name of the tools vendor.
	_toolName =             "Mentor QuestaSim"          #: The name of the tool.
	_section  =             "INSTALL.Mentor.QuestaSim"  #: The name of the configuration section. Pattern: ``INSTALL.Vendor.ToolName``.
	_multiVersionSupport =  True                        #: Mentor QuestaSim supports multiple versions installed on the same system.
	_template = {
		"Windows": {
			_section: {
				"Version":                "10.5c",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Mentor:InstallationDirectory}/QuestaSim/${Version}"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/win64"),
				"AdditionalVComOptions":  ("${${SectionName}:AdditionalVComOptions}", ""),
				"AdditionalVSimOptions":  ("${${SectionName}:AdditionalVSimOptions}", "")
			}
		},
		"Linux": {
			_section: {
				"Version":                "10.5c",
				"SectionName":            ("%{PathWithRoot}#${Version}",              None),
				"InstallationDirectory":  ("${${SectionName}:InstallationDirectory}", "${INSTALL.Mentor:InstallationDirectory}/${Version}/questasim"),
				"BinaryDirectory":        ("${${SectionName}:BinaryDirectory}",       "${InstallationDirectory}/bin"),
				"AdditionalVComOptions":  ("${${SectionName}:AdditionalVComOptions}", ""),
				"AdditionalVSimOptions":  ("${${SectionName}:AdditionalVSimOptions}", "")
			}
		}
	}                                                   #: The template for the configuration sections represented as nested dictionaries.

	def ConfigureForAll(self):
		try:
			if (not self._AskInstalled("Is Mentor QuestaSim installed on your system?")):
				self.ClearSection()
			else:
				# Configure QuestaSim version
				version = self._ConfigureVersion()
				if self._multiVersionSupport:
					self.PrepareVersionedSections()
					sectionName = self._host.PoCConfig[self._section]['SectionName']
					self._host.PoCConfig[sectionName]['Version'] = version

				self._ConfigureInstallationDirectory()
				binPath = self._ConfigureBinaryDirectory()
				self._CheckQuestaSimVersion(binPath, version)
				self._host.LogNormal("{DARK_GREEN}Mentor Graphics QuestaSim is now configured.{NOCOLOR}".format(**Init.Foreground), indent=1)
		except ConfigurationException:
			self.ClearSection()
			raise

	def _CheckQuestaSimVersion(self, binPath, version):
		self._CheckModelSimVersion(binPath, version)
