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
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module Base.Config")

# load dependencies
from enum import Enum, EnumMeta, unique
from Base.Exceptions import *

@unique
class Vendors(Enum):
	Unknown = 0
	Altera = 1
	Lattice = 2
	MicroSemi = 3
	Xilinx = 4

	def __str__(self):
		return self.name.lower()
	
@unique
class Families(Enum):
	Unknown = 0
	# Xilinx families
	Spartan = 1
	Artix = 2
	Kintex = 3
	Virtex = 4
	Zynq = 5
	# Altera families
	Cyclon = 11
	Stratix = 12

	def __str__(self):
		return self.name.lower()
	
	def __repr__(self):
		if	 (self == Families.Spartan):	return "s"
		elif (self == Families.Artix):		return "a"
		elif (self == Families.Kintex):		return "k"
		elif (self == Families.Virtex):		return "v"
		elif (self == Families.Zynq):			return "z"
	
@unique
class SubTypes(Enum):
	Unknown =		0
	NoSubType = 1
	# Xilinx device subtypes
	X =		101
	T =		102
	XT =	103
	HT =	104
	LX =	105
	SXT =	106
	LXT =	107
	TXT =	108
	FXT =	109
	CXT =	110
	HXT =	111
	# Altera device subtypes
	E =		201
	GS =	202
	GX =	203
	GT =	204

	def __str__(self):
		if (self == SubTypes.Unknown):
			return "??"
		else:
			return self.name.lower()

	def groups(self):
		if	 (self == SubTypes.NoSubType):	return ("",	"")
		elif (self == SubTypes.X):					return ("x",	"")
		elif (self == SubTypes.T):					return ("",		"t")
		elif (self == SubTypes.XT):					return ("x",	"t")
		elif (self == SubTypes.HT):					return ("h",	"t")
		elif (self == SubTypes.LX):					return ("lx",	"")
		elif (self == SubTypes.SXT):				return ("sx",	"t")
		elif (self == SubTypes.LXT):				return ("lx",	"t")
		elif (self == SubTypes.TXT):				return ("tx",	"t")
		elif (self == SubTypes.FXT):				return ("fx",	"t")
		elif (self == SubTypes.CXT):				return ("cx",	"t")
		elif (self == SubTypes.HXT):				return ("hx",	"t")
		else:																return ("??", "?")
	
@unique
class Packages(Enum):
	Unknown = 0
	
	TQG =	1
	
	CPG = 10
	CSG = 11
	
	FF =	20
	FFG =	21
	FTG =	22
	FGG =	23
	FLG =	24
	FT =	25

	RB =	30
	RBG =	31
	RS =	32
	RF =	33
	
	def __str__(self):
		if (self == Packages.Unknown):
			return "??"
		else:
			return self.name.lower()

class Device:
	# PoCDevice members
	vendor =			Vendors.Unknown
	generation =	0
	family =			Families.Unknown
	subtype =			SubTypes.Unknown
	number =			0
	speedGrade =	0
	package =			Packages.Unknown
	pinCount =		0

	def __init__(self, deviceString):
		import re
		
		# vendor = Xilinx
		if (deviceString[0:2].lower() == "xc"):		# xc - Xilinx Commercial
			self.vendor =			Vendors.Xilinx
			self.generation = int(deviceString[2:3])

			temp = deviceString[3:4].lower()
			if	 (temp == repr(Families.Artix)):		self.family = Families.Artix
			elif (temp == repr(Families.Kintex)):		self.family = Families.Kintex
			elif (temp == repr(Families.Spartan)):	self.family = Families.Spartan
			elif (temp == repr(Families.Virtex)):		self.family = Families.Virtex
			elif (temp == repr(Families.Zynq)):			self.family = Families.Zynq
			else: raise Exception("Unknown device family.")

			deviceRegExpStr =  r"(?P<st1>[a-z]{0,2})"				# device subtype - part 1
			deviceRegExpStr += r"(?P<no>\d{1,4})"						# device number
			deviceRegExpStr += r"(?P<st2>[t]{0,1})"					# device subtype - part 2
			deviceRegExpStr += r"(?P<sg>[-1-5]{2})"					# speed grade
			deviceRegExpStr += r"(?P<pack>[a-z]{1,3})"			# package
			deviceRegExpStr += r"(?P<pins>\d{1,4})"					# pin count
			
			deviceRegExp = re.compile(deviceRegExpStr)
			deviceRegExpMatch = deviceRegExp.match(deviceString[4:].lower())

			if (deviceRegExpMatch is not None):
				subtype = deviceRegExpMatch.group('st1') + deviceRegExpMatch.group('st2')
				package = deviceRegExpMatch.group('pack')
				
				print("SubType: %s" % subtype)
				
				if (subtype != ""):
					self.subtype =	SubTypes[subtype.upper()]
				else:
					self.subtype =	SubTypes.NoSubType
				
				self.number =			int(deviceRegExpMatch.group('no'))
				self.speedGrade =	int(deviceRegExpMatch.group('sg'))
				self.package =		Packages[package.upper()]
				self.pinCount =		int(deviceRegExpMatch.group('pins'))
			else:
				print("Error:")
				print(deviceRegExpMatch)
		
			print(str(self))
		
		# vendor = Altera
		if (deviceString[0:2].lower() == "ep"):
			self.vendor =			Vendors.Altera
			self.generation = int(deviceString[2:3])

			temp = deviceString[3:4].lower()
			if	 (temp == repr(Families.Cyclon)):		self.family = Families.Cyclon
			elif (temp == repr(Families.Stratix)):	self.family = Families.Stratix

#			deviceRegExpStr =  r"(?P<st1>[cfhlstx]{0,2})"			# device subtype - part 1
#			deviceRegExpStr += r"(?P<no>\d{1,4})"							# device number
#			deviceRegExpStr += r"(?P<st2>[t]{0,1})"						# device subtype - part 2
#			deviceRegExpStr += r"(?P<sg>[-1-3]{2})"						# speed grade
#			deviceRegExpStr += r"(?P<pack>[fg]{1,3})"					# package
#			deviceRegExpStr += r"(?P<pins>\d{1,4})"						# pin count
#			
#			deviceRegExp = re.compile(deviceRegExpStr)
#			deviceRegExpMatch = deviceRegExp.match(deviceString[4:].lower())
#
#			if (deviceRegExpMatch is not None):
#				print("dev subtype: %s%s" % (deviceRegExpMatch.group('st1'), deviceRegExpMatch.group('st2')))
	
	def shortName(self):
		if (self.vendor == Vendors.Xilinx):
			subtype = self.subtype.groups()
			return "xc%i%s%s%s%s" % (
				self.generation,
				repr(self.family),
				subtype[0],
				"{num:03d}".format(num=self.number),
				subtype[1]
			)
		elif (self.vendor == Vendors.Altera):
			raise NotImplementedException("shortName() not implemented for vendor Altera")
			return "ep...."
	
	def fullName(self):
		if (self.vendor == Vendors.Xilinx):
			subtype = self.subtype.groups()
			return "xc%i%s%s%s%s%i%s%i" % (
				self.generation,
				repr(self.family),
				subtype[0],
				"{num:03d}".format(num=self.number),
				subtype[1],
				self.speedGrade,
				str(self.package),
				self.pinCount
			)
		elif (self.vendor == Vendors.Altera):
			raise NotImplementedException("fullName() not implemented for vendor Altera")
			return "ep...."
	
	def familyName(self):
		if (self.family == Families.Zynq):
			return str(self.family)
		else:
			return str(self.family) + str(self.generation)
	
	def series(self):
		if (self.generation == 7):
			if self.family in [Families.Artix, Families.Kintex, Families.Virtex, Families.Zynq]:
				return "Series-7"
		else:
			print("here")
			return "%s-%i" % (
				str(self.family),
				self.generation
			)
	
	def __str__(self):
		return self.fullName()
	