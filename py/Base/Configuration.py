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
		if self._toolName is None:
			self._ConfigureVendorPath()

	def __str__(self):
		if self._toolName is None: return self._vendor
		return self._toolName

	def ClearSection(self):
		self._host.PoCConfig[self._section] = OrderedDict()

	def _ConfigureVendorPath(self):
		if (not self._AskInstalled("Are {0} products installed on your system?".format(self._vendor))):
			self.ClearSection()
		else:
			self._ConfigureInstallationDirectory()

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

	def _ConfigureInstallationDirectory(self):
		"""
			Asks for installation directory and updates section.
			Checks if entered directory exists and returns Path object.
			If no installation directory was configured before, then _GetDefaultInstallationDir is called.
		"""
		if self._host.PoCConfig.has_option(self._section, 'InstallationDirectory'):
			defaultPath = Path(self._host.PoCConfig[self._section]['InstallationDirectory'])
		else:
			unresolved = self._GetDefaultInstallationDirectory() # may return an unresolved configuration string
			self._host.PoCConfig[self._section]['InstallationDirectory'] = unresolved # create entry
			defaultPath = Path(self._host.PoCConfig[self._section]['InstallationDirectory']) # resolve entry

		directory = input("  {0!s} installation directory [{1!s}]: ".format(self, defaultPath))
		if (directory != ""):
			installPath = Path(directory)
		else:
			installPath = defaultPath

		if (not installPath.exists()):
			raise ConfigurationException("{0!s} installation directory '{1!s}' does not exist.".format(self, installPath))  \
				from NotADirectoryError(str(installPath))

		if directory != "": # update only if user entered something
			self._host.PoCConfig[self._section]['InstallationDirectory'] = installPath.as_posix()
			self._host.PoCConfig.Interpolation.clear_cache()

		return installPath

	def _GetDefaultInstallationDirectory(self):
		"""
			Returns unresolved default installation directory (string) from template.
			Overwrite function in sub-class for automatic search of installation directory.
		"""
		return self._template[self._host.Platform][self._section]['InstallationDirectory']

	def _TestDefaultInstallPath(self, defaults):
		"""Helper function for automatic search of installation directory."""
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

	def _ConfigureVersion(self):
		"""
				Asks for version and updates section. Returns version as string.
				If no version was configured before, then _GetDefaultVersion is called.
			"""
		if self._host.PoCConfig.has_option(self._section, 'Version'):
			defaultVersion = self._host.PoCConfig[self._section]['Version']
		else:
			unresolved = self._GetDefaultVersion()  # may return an unresolved configuration string
			self._host.PoCConfig[self._section]['Version'] = unresolved  # create entry
			defaultVersion = self._host.PoCConfig[self._section]['Version']  # resolve entry

		version = input("  {0!s} version [{1!s}]: ".format(self, defaultVersion))
		if version != "":  # update only if user entered something
			self._host.PoCConfig[self._section]['Version'] = version
			self._host.PoCConfig.Interpolation.clear_cache()
		else:
			version = defaultVersion

		return version

	def _GetDefaultVersion(self):
		"""
			Returns unresolved default version (string) from template.
			Overwrite function in sub-class for automatic search of version.
		"""
		return self._template[self._host.Platform][self._section]['Version']

	def _ConfigureBinaryDirectory(self):
		"""Updates section with value from _template and returns directory as Path object."""
		unresolved = self._template[self._host.Platform][self._section]['BinaryDirectory']
		self._host.PoCConfig[self._section]['BinaryDirectory'] = unresolved # create entry
		defaultPath = Path(self._host.PoCConfig[self._section]['BinaryDirectory'])  # resolve entry
		
		binPath = defaultPath # may be more complex in the future

		if (not binPath.exists()):
			raise ConfigurationException("{0!s} binary directory '{1!s}' does not exist.".format(self, binPath)) \
				from NotADirectoryError(str(binPath))
		
		return binPath

