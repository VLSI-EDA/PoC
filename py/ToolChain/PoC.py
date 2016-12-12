# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#										Thomas B. Preusser
#
# Python Class:     PoC specific classes
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
from os                   import environ
from pathlib              import Path
from subprocess           import CalledProcessError

from Base.Exceptions      import EnvironmentException
from ToolChain            import ToolConfiguration
from ToolChain.Git        import Git


__api__ = [
	'Configuration'
]
__all__ = __api__


class Configuration(ToolConfiguration):
	_vendor =               "VLSI-EDA"                  #: The name of the tools vendor.
	_toolName =             "PoC"                       #: The name of the tool.
	_section  =             "INSTALL.PoC"               #: The name of the configuration section. Pattern: ``INSTALL.Vendor.ToolName``.
	_template =    {
		"ALL": {
			_section: {
				"Version":                "1.1.1",
				"InstallationDirectory":  "",
				"RepositoryKind":         "Public",
				"IsGitRepository":        "True",
				"GitRemoteBranch":        "master",
				"MultiVersionSupport":    "True",
				"HasInstalledGitHooks":   "False",
				"HasInstalledGitFilters": "False"
			},
			"SOLUTION.Solutions":   {}
		}
	}                                                   #: The template for the configuration sections represented as nested dictionaries.

	def ConfigureForAll(self):
		pocInstallationDirectory = Path(environ.get('PoCRootDirectory'))
		if (not pocInstallationDirectory.exists()):
			raise EnvironmentException("Path '{0!s}' in environment variable 'PoCRootDirectory' does not exist.".format(pocInstallationDirectory))
		elif (not pocInstallationDirectory.is_dir()):
			raise EnvironmentException("Path '{0!s}' in environment variable 'PoCRootDirectory' is not a directory.".format(pocInstallationDirectory)) \
				from NotADirectoryError(str(pocInstallationDirectory))

		self._host.LogNormal("  Installation directory: {0!s} (found in environment variable)".format(pocInstallationDirectory))
		self._host.PoCConfig['INSTALL.PoC']['InstallationDirectory'] = pocInstallationDirectory.as_posix()

	def RunPostConfigurationTasks(self):
		success = False
		if (len(self._host.PoCConfig['INSTALL.Git']) != 0):
			try:
				binaryDirectoryPath = Path(self._host.PoCConfig['INSTALL.Git']['BinaryDirectory'])
				git = Git(self._host.Platform, self._host.DryRun, binaryDirectoryPath, "", logger=self._host.Logger)

				gitDescribe =   git.GetGitDescribe()
				gitDescribe.DescribeParameters[gitDescribe.SwitchAbbrev] =  0
				gitDescribe.DescribeParameters[gitDescribe.SwitchTags] =    "" # specify no hash
				latestTagName = gitDescribe.Execute().strip()

				self._host.LogNormal("  PoC version: {0} (found in git)".format(latestTagName))
				self._host.PoCConfig['INSTALL.PoC']['Version'] = latestTagName
				success = True
			except CalledProcessError:
				pass

		if not success:
			self._host.LogWarning("Can't get version information from latest Git tag.")
			pocVersion = self._template['ALL']['INSTALL.PoC']['Version']
			self._host.LogNormal("  PoC version: {0} (found in default configuration)".format(pocVersion))
			self._host.PoCConfig['INSTALL.PoC']['Version'] = pocVersion

	# LOCAL = git rev-parse @
	# PS G:\git\PoC> git rev-parse "@"
	# 9c05494ef52c276dabec69dbf734a22f65939305

	# REMOTE = git rev-parse @{u}
	# PS G:\git\PoC> git rev-parse "@{u}"
	# 0ff166a40010c1b85a5ab655eea0148474f680c6

	# MERGEBASE = git merge-base @ @{u}
	# PS G:\git\PoC> git merge-base "@" "@{u}"
	# 0ff166a40010c1b85a5ab655eea0148474f680c6

	# if (local == remote):   return "Up-to-date"
	# elif (local == base):   return "Need to pull"
	# elif (remote == base):  return "Need to push"
	# else:                   return "divergent"

