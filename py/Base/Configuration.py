# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:					Patrick Lehmann
#										Martin Zabel
#
# Python Class:			TODO:
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
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module Base.Configuration")


from collections					import OrderedDict
from pathlib							import Path

from Base.Exceptions			import ExceptionBase


class ConfigurationException(ExceptionBase):
	pass

class SkipConfigurationException(ExceptionBase):
	pass

# class RegisterSubClassesMeta(type):
# 	def __new__(mcs, name, bases, members):
# 		#print("RegisterSubClassesMeta.new: {0} - ".format(name, members))
# 		#print()
# 		inst = super().__new__(mcs, name, bases, members)
# 		if (len(bases) > 0):
# 			baseClass = bases[0]
# 			print(baseClass)
# 			if issubclass(baseClass, ISubClassRegistration):
# 				#print("interface match")
# 				baseClass.RegisterSubClass(inst)
# 		return inst
#
# class ISubClassRegistration(metaclass=RegisterSubClassesMeta):
# 	_subclasses = []
#
# 	@classmethod
# 	def RegisterSubClass(cls, subcls):
# 		print("Register: {0}".format(str(subcls)))
# 		cls._subclasses.append(subcls)
#
# 	@property
# 	def SubClasses(self):
# 		return self._subclasses

class Configuration:		#(ISubClassRegistration):
	_vendor =								"Unknown"
	_toolName =							"Unknown"
	_template =	{}

	def __init__(self, host):
		self._host =	host

	@property
	def ToolName(self):
		return self._toolName

	def IsSupportedPlatform(self):
		if (self._host.Platform not in self._template):
			return ("ALL" in self._template)
		else:
			return True

	@classmethod
	def GetSections(cls, platform):
		if ("ALL" in cls._template):
			for sectionName in cls._template['ALL']:
				yield sectionName
		if (platform in cls._template):
			for sectionName in cls._template[platform]:
				yield sectionName

	def CheckDependency(self):
		return True

	def ConfigureForDarwin(self):
		self.ConfigureForAll()

	def ConfigureForLinux(self):
		self.ConfigureForAll()

	def ConfigureForWindows(self):
		self.ConfigureForAll()

	def ConfigureForAll(self):
		self._host.PoCConfig.Interpolation.clear_cache()

	def __str__(self):
		return self._toolName

	def _AskInstalled(self, question):
		isInstalled = input("  " + question + " [Y/n/p]: ")
		isInstalled = isInstalled if isInstalled != "" else "Y"
		if (isInstalled in ['p', 'P']):
			raise SkipConfigurationException()
		elif (isInstalled in ['n', 'N']):
			return False
		elif (isInstalled in ['y', 'Y']):
			return True
		else:
			raise ConfigurationException("Unsupported choice '{0}'".format(isInstalled))

	def _AskInstallPath(self, section, defaultPath):
		directory = input("  {0} installation directory [{1!s}]: ".format(self.ToolName, defaultPath))
		if (directory != ""):
			installPath = Path(directory)
		else:
			installPath = defaultPath

		if (not installPath.exists()):
			raise ConfigurationException("{0} installation directory '{1!s}' does not exist.".format(self.ToolName, installPath))  \
				from NotADirectoryError(str(installPath))

		return installPath

	def _TestDefaultInstallPath(self, defaults):
		if (self._host.Platform == "Linux"):
			p = Path("/opt") / defaults["Linux"]
			if (p.exists()):    return p
			p = Path("/opt") / defaults["Linux"].lower()
			if (p.exists()):    return p
		elif (self._host.Platform == "Windows"):
			for drive in "CDEFGH":
				p = Path("{0}:/{1}".format(drive, defaults["Windows"]))
				try:
					if (p.exists()):  return p
				except OSError:
					pass
		return None

	def _ClearSection(self, section):
		self._host.PoCConfig[section] = OrderedDict()


	def _WriteInstallationDirectory(self, section, installPath):
		self._host.PoCConfig[section]['InstallationDirectory'] = installPath.as_posix()
