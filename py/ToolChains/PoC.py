# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#										Thomas B. Preusser
#
# Python Class:      PoC specific classes
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
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module ToolChains.PoC")


from os                   import environ
from pathlib              import Path
from subprocess           import check_output, check_call, CalledProcessError

from Base.Configuration   import Configuration as BaseConfiguration


class Configuration(BaseConfiguration):
	_vendor =      "VLSI-EDA"
	_toolName =    "PoC"
	_template =    {
		"ALL": {
			"INSTALL.PoC": {
				"Version":                "1.0.0",
				"InstallationDirectory":  None
			},
			"SOLUTION.Solutions": {}
		}
	}

	def ConfigureForAll(self):
		try:
			latestTagHash = check_output(["git", "rev-list", "--tags", "--max-count=1"], universal_newlines=True).strip()
			latestTagName = check_output(["git", "describe", "--tags", latestTagHash], universal_newlines=True).strip()
			latestTagName = latestTagName
			self._host.LogNormal("  PoC version: {0} (found in git)".format(latestTagName))
			self._host.PoCConfig['INSTALL.PoC']['Version'] = latestTagName
		except CalledProcessError:
			print("WARNING: Can't get version information from latest git tag.")
			pocVersion = self._template['ALL']['INSTALL.PoC']['Version']
			self._host.LogNormal("  PoC version: {0} (found in default configuration)".format(pocVersion))
			self._host.PoCConfig['INSTALL.PoC']['Version'] = pocVersion

		pocInstallationDirectory = Path(environ.get('PoCRootDirectory'))
		self._host.LogNormal("  Installation directory: {0!s} (found in environment variable)".format(pocInstallationDirectory))
		self._host.PoCConfig['INSTALL.PoC']['InstallationDirectory'] = pocInstallationDirectory.as_posix()

	def __CheckForGit(self):
		try:
			check_call(["git", "--version"])
			return True
		except OSError:
			return False

	def __IsUnderGitControl(self):
		try:
			response = check_output(["git", "rev-parse", "--is-inside-work-tree"], universal_newlines=True).strip()
			return (response == "true")
		except OSError:
			return False

	def __GetCurrentBranchName(self):
		try:
			response = check_output(["git", "rev-parse", "--abbrev-ref", "HEAD"], universal_newlines=True).strip()
			return response
		except OSError:
			return False

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

