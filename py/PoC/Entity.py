# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
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
# Copyright 2007-2015 Technische Universitaet Dresden - Germany
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
	from sys import exit

	print("=" * 80)
	print("{: ^80s}".format("The PoC Library - Python Module Base.Entity"))
	print("=" * 80)
	print()
	print("This is no executable file!")
	exit(1)


from enum import Enum, EnumMeta, unique

from Base.Exceptions import *

@unique
class EntityTypes(Enum):
	Unknown = 0
	Source = 1
	Testbench = 2
	NetList = 3

	def __str__(self):
		if	 (self == EntityTypes.Unknown):		return "??"
		elif (self == EntityTypes.Source):		return "src"
		elif (self == EntityTypes.Testbench):	return "tb"
		elif (self == EntityTypes.NetList):		return "nl"

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

	
class Entity(object):
	host = None
	
	type = None
	name = ""
	parts = []
	
	def __init__(self, host, name):
		self.host = host
	
		# check if a type is given
		#		default = Source (src)
		splitList1 = name.split(':')
		if (len(splitList1) == 1):
			self.type = EntityTypes.Source
			namespacePart = name
		elif (len(splitList1) == 2):
			self.type = EntityTypes(splitList1[0])
			namespacePart = splitList1[1]
		else:
			raise ArgumentException("Argument has to many ':' signs.")
		
		splitList2 = namespacePart.split('.')
#		print("len2: %i" % len(splitList2))
		if (splitList2[0] == "PoC"):
			self.parts = splitList2[1:]
		else:
			self.parts = splitList2
		
#		if (not self.host.pocStructure.has_option('NamespaceDirectoryNames', str(self))):
#			raise PoCException("Namespace or entity '%s' does not exist." % str(self))
		
				
	def Root(self):
		return Entity(self, "PoC")
	
	def isSingleEntity(self):
		pass
	
	def isNamespace(self):
		pass
	
	def getParentNamespace(self):
		pass
	
	def getEntities(self):
		pass
	
	def getSubNamespaces(self):
		pass
	
	def __str__(self):
		return "PoC." + '.'.join(self.parts)
		#return str(self.type) + ":PoC." + '.'.join(self.parts)
