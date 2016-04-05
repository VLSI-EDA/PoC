# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
# Authors:				 	Patrick Lehmann
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

# entry point
if __name__ != "__main__":
	# place library initialization code here
	pass
else:
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module Base.Entity")


# load dependencies
from enum import Enum, EnumMeta, unique

from Base.Exceptions			import *
from Base.Configuration		import ConfigurationException


@unique
class EntityTypes(Enum):
	Unknown = 0
	Source = 1
	Testbench = 2
	NetList = 3

	def __str__(self):
		if	 (self is EntityTypes.Unknown):		return "??"
		elif (self is EntityTypes.Source):		return "src"
		elif (self is EntityTypes.Testbench):	return "tb"
		elif (self is EntityTypes.NetList):		return "nl"

def _PoCEntityTypes_parser(cls, value):
	if not isinstance(value, str):
		return Enum.__new__(cls, value)
	else:
		# map strings to enum values, default to Unknown
		return {
			'src':			EntityTypes.Source,
			'tb':				EntityTypes.Testbench,
			'nl':				EntityTypes.NetList
		}.get(value,	EntityTypes.Unknown)

# override __new__ method in EntityTypes with _PoCEntityTypes_parser
setattr(EntityTypes, '__new__', _PoCEntityTypes_parser)


class PathElement:
	def __init__(self, name, parent):
		self._name =		name
		self._parent =	parent

	@property
	def Name(self):
		return self._name

	@property
	def Parent(self):
		return self._parent

	def __str__(self):
		return "{0}.{1}".format(str(self._parent), self._name)

class Namespace(PathElement):
	pass

class Root(Namespace):
	def __init__(self):
		super().__init__("PoC", None)

	def __str__(self):
		return self._name

class Entity(PathElement):
	def __init__(self, name, parent):
		super().__init__(name, parent)

		self.__isStar = (name == "*")

	@property
	def IsStar(self):
		return self.__isStar


class FQN:
	def __init__(self, host, fqn, defaultType=EntityTypes.Source):
		self.__host =		host
		self.__type =		None
		self.__parts =	[]

		if (fqn is None):			raise ValueError("Parameter 'fqn' is None.")
		if (fqn == ""):				raise ValueError("Parameter 'fqn' is empty.")

		# extract EntityType
		splitList1 = fqn.split(':')
		if (len(splitList1) == 1):
			self.__type =	defaultType
			entity =			fqn
		elif (len(splitList1) == 2):
			self.__type =	EntityTypes(splitList1[0])
			entity =			splitList1[1]
		else:
			raise ValueError("Argument 'fqn' has to many ':' signs.")

		# extract parts
		parts = entity.split('.')
		if (parts[0].lower() == "poc"):
			parts = parts[1:]

		# check and resolve parts
		self.__parts.append(Root())
		path = "PoC"
		length =		len(parts)
		for pos,part in enumerate(parts):
			path += "." + part.lower()
			if (pos == length - 1):
				self.__parts.append(Entity(part, self.__parts[-1]))
			elif (not self.__host.PoCConfig.has_option('PoC.NamespacePrefixes', part.lower())):
				raise ConfigurationException("Sub namespace '{0}' does not exist.".format(part))
			elif (not self.__host.PoCConfig.has_option('PoC.NamespaceDirectoryNames', path)):
				raise ConfigurationException("Namespace path '{0}' does not exist.".format(path))
			else:
				self.__parts.append(Namespace(part, self.__parts[-1]))

	def Root(self):
		return Entity(self, "PoC")
	
	@property
	def Entity(self):
		return self.__parts[-1]

	def GetEntities(self):
		if (self.__type is EntityTypes.Testbench):
			config = self.__host.TBConfig
		elif (self.__type is EntityTypes.NetList):
			config = self.__host.NLConfig

		entity = self.__parts[-1]
		if (not entity.IsStar):
			yield entity
		else:
			subns = self.__parts[-2]
			path =	str(subns) + "."
			for sectionName in config:
				if sectionName.startswith(path):
					if self.__host.PoCConfig.has_option('PoC.NamespacePrefixes', sectionName):
						continue
					fqn = FQN(self.__host, sectionName)
					yield fqn.Entity

	def __str__(self):
		return ".".join([p.Name for p in self.__parts])
