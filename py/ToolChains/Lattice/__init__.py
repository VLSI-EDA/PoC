# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#
# Python Class:     Lattice Diamond specific classes
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
from Base.Project             import ConstraintFile, FileTypes
from ToolChains               import ToolChainException, VendorConfiguration


__api__ = [
	'LatticeException',
	'Configuration',
	'LatticeDesignConstraintFile'
]
__all__ = __api__


class LatticeException(ToolChainException):
	pass


class Configuration(VendorConfiguration):
	"""Configuration routines for Lattice as a vendor.

	This configuration provides a common installation directory setup for all
	Lattice tools installed on a system.
	"""
	_vendor =               "Lattice"                   #: The name of the tools vendor.
	_section  =             "INSTALL.Lattice"           #: The name of the configuration section. Pattern: ``INSTALL.Vendor.ToolName``.
	_template = {
		"Windows": {
			_section: {
				"InstallationDirectory": "C:/Lattice"
			}
		},
		"Linux": {
			_section: {
				"InstallationDirectory": "/usr/local"
			}
		}
	}                                                   #: The template for the configuration sections represented as nested dictionaries.

	def _GetDefaultInstallationDirectory(self):
		path = self._TestDefaultInstallPath({"Windows": "Lattice", "Linux": "lattice"})
		if path is None: return super()._GetDefaultInstallationDirectory()
		return path.as_posix()


class LatticeDesignConstraintFile(ConstraintFile):
	_FileType = FileTypes.LdcConstraintFile

	def __str__(self):
		return "LDC file: '{0!s}".format(self._file)
