# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:				 	Patrick Lehmann
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


class ConfigurationException(BaseException):
	pass

class SkipConfigurationException(BaseException):
	pass

class RegisterSubClassesMeta(type):
	def __new__(mcls, name, bases, members):
		#print("RegisterSubClassesMeta.new: {0} - ".format(name, members))
		#print()
		inst = super().__new__(mcls, name, bases, members)
		if (len(bases) > 0):
			baseClass = bases[0]
			print(baseClass)
			if issubclass(baseClass, ISubClassRegistration):
				#print("interface match")
				baseClass.RegisterSubClass(inst)
		return inst

class ISubClassRegistration(metaclass=RegisterSubClassesMeta):
	_subclasses = []

	@classmethod
	def RegisterSubClass(cls, subcls):
		print("Register: {0}".format(str(subcls)))
		cls._subclasses.append(subcls)

	@property
	def SubClasses(self):
		return self._subclasses

class ConfigurationBase:		#(ISubClassRegistration):
	_privateConfiguration =	{}
	_vendor =								"Unknown"
	_longName =							"Unknown"

	@property
	def Name(self):
		return self._longName

	def IsSupportedPlatform(self, Platform):
		result = (Platform in self._privateConfiguration)
		if (not result):
			return ("ALL" in self._privateConfiguration)
		else:
			return True

	def ManualConfigureForWindows(self):
		raise NotImplementedError()

	def ManualConfigureForLinux(self):
		raise NotImplementedError()
