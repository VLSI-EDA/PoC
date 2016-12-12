# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#
# Python Class:     Synopsys specific classes
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
from ToolChain                import ToolChainException, VendorConfiguration


__api__ = [
	'SynopsysException',
	'Configuration',
	'SynopsysDesignConstraintFile'
]
__all__ = __api__


class SynopsysException(ToolChainException):
	pass


class Configuration(VendorConfiguration):
	"""Configuration routines for Synopsys as a vendor.

	This configuration provides a common installation directory setup for all
	Synopsys tools installed on a system.
	"""
	_vendor =               "Synopsys"                  #: The name of the tools vendor.
	_section  =             "INSTALL.Synopsys"          #: The name of the configuration section. Pattern: ``INSTALL.Vendor.ToolName``.
	_template = {
		"Windows": {
			_section: {
				"InstallationDirectory": "C:/Synopsys"
			}
		},
		"Linux": {
			_section: {
				"InstallationDirectory": "/opt/Synopsys"
			}
		}
	}                                                   #: The template for the configuration sections represented as nested dictionaries.

	def _GetDefaultInstallationDirectory(self):
		# synopsys = environ.get("QUARTUS_ROOTDIR")				# on Windows: D:\Synopsys\13.1\quartus
		# if (synopsys is not None):
		# 	return Path(synopsys).parent.parent

		return self._TestDefaultInstallPath({"Windows": "Synopsys", "Linux": "Synopsys"}).as_posix()


class SynopsysDesignConstraintFile(ConstraintFile):
	_FileType = FileTypes.SdcConstraintFile

	def __str__(self):
		return "SDC file: '{0!s}".format(self._file)
