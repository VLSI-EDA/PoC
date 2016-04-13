# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
# Authors:					Patrick Lehmann
# 
# Python Class:			TODO
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
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module PoC.Config")

# load dependencies
from enum									import Enum, EnumMeta, unique
from re										import compile as RegExpCompile

# from lib.Decorators				import CachedReadOnlyProperty
from lib.Functions				import Init
from Base.Configuration		import ConfigurationException


@unique
class Vendors(Enum):
	Unknown =			0
	Altera =			1
	Lattice =			2
	MicroSemi =		3
	Xilinx =			4

	def __str__(self):
		return self.name
	
	def __repr__(self):
		return str(self).lower()
	
@unique
class Families(Enum):
	Unknown =		0
	# Xilinx families
	Spartan =		1
	Artix =			2
	Kintex =		3
	Virtex =		4
	Zynq =			5
	# Altera families
	Cyclon =		11
	Stratix =		12

	def __str__(self):
		return self.name
	
	def __repr__(self):
		return str(self).lower()

	# @CachedReadOnlyProperty
	@property
	def Token(self):
		if   (self == Families.Spartan):	return "s"
		elif (self == Families.Artix):		return "a"
		elif (self == Families.Kintex):		return "k"
		elif (self == Families.Virtex):		return "v"
		elif (self == Families.Zynq):			return "z"

@unique
class Devices(Enum):
	Unknown =									0
	
	# Xilinx.Spartan devices
	Spartan3 =								10
	Spartan6 =								11
	Spartan7 =								12
	# Xilinx.Artix devices
	Artix7 =									20
	# Xilinx.Kintex devices
	Kintex7 =									30
	# Xilinx.Virtex devices
	Virtex2 =									40
	Virtex4 =									41
	Virtex5 =									42
	Virtex6 =									43
	Virtex7 =									44
	VirtexUltraScale =				45
	VirtexUltraScalePlus =		46
	# Xilinx.Zynq devices
	Zynq7000 =								50
	
	# Altera.Max devices
	Max2 =										100
	Max4 =										101
	Max5 =										102
	Max10 =										103
	# Altera.Cyclone devices
	Cyclone3 =								110
	Cyclone4 =								111
	Cyclone5 =								112
	# Altera.Arria devices
	Arria2 =									120
	Arria5 =									121
	# Altera.Stratix devices
	Stratix2 =								130
	Stratix4 =								131
	Stratix5 =								132
	Stratix10 =								133

	def __str__(self):
		return self.name
	
	def __repr__(self):
		return str(self).lower()

	# @CachedReadOnlyProperty
	@property
	def Token(self):
		if   (self == Families.Spartan):	return "s"
		elif (self == Families.Artix):		return "a"
		elif (self == Families.Kintex):		return "k"
		elif (self == Families.Virtex):		return "v"
		elif (self == Families.Zynq):			return "z"
		
@unique
class SubTypes(Enum):
	Unknown =		0
	NoSubType = 1
	# Xilinx device subtypes
	X =					101
	T =					102
	XT =				103
	HT =				104
	LX =				105
	SXT =				106
	LXT =				107
	TXT =				108
	FXT =				109
	CXT =				110
	HXT =				111
	# Altera device subtypes
	E =					201
	GS =				202
	GX =				203
	GT =				204

	def __str__(self):
		if (self == SubTypes.Unknown):
			return "??"
		else:
			return self.name
	
	def __repr__(self):
		return str(self).lower()
	
	# @CachedReadOnlyProperty
	@property
	def Groups(self):
		if   (self == SubTypes.NoSubType):	return ("",	"")
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
	Unknown =	0
	
	TQG =			1
	
	CPG =			10
	CSG =			11
	
	FF =			20
	FFG =			21
	FTG =			22
	FGG =			23
	FLG =			24
	FT =			25
	
	RB =			30
	RBG =			31
	RS =			32
	RF =			33
	
	def __str__(self):
		if (self is Packages.Unknown):
			return "??"
		else:
			return self.name
			
	def __repr__(self):
		return str(self).lower()

class Device:
	def __init__(self, deviceString):
		# Device members
		self.__vendor =			Vendors.Unknown
		self.__family =			Families.Unknown
		self.__device =			Devices.Unknown
		self.__generation =	0
		self.__subtype =		SubTypes.Unknown
		self.__number =			0
		self.__speedGrade =	0
		self.__package =		Packages.Unknown
		self.__pinCount =		0
		
		if (not isinstance(deviceString, str)):
			raise ValueError("Parameter 'deviceString' is not of type str.")
		if ((deviceString is None) or (deviceString == "")):
			raise ValueError("Parameter 'deviceString' is empty.")
		
		# vendor = Xilinx
		if (deviceString[0:2].lower() == "xc"):		# xc - Xilinx Commercial
			self.__vendor =			Vendors.Xilinx
			self.__generation = int(deviceString[2:3])

			temp = deviceString[3:4].lower()
			if   (temp == Families.Artix.Token):		self.__family = Families.Artix
			elif (temp == Families.Kintex.Token):		self.__family = Families.Kintex
			elif (temp == Families.Spartan.Token):	self.__family = Families.Spartan
			elif (temp == Families.Virtex.Token):		self.__family = Families.Virtex
			elif (temp == Families.Zynq.Token):			self.__family = Families.Zynq
			else: raise Exception("Unknown device family.")

			deviceRegExpStr =  r"(?P<st1>[a-z]{0,2})"				# device subtype - part 1
			deviceRegExpStr += r"(?P<no>\d{1,4})"						# device number
			deviceRegExpStr += r"(?P<st2>[t]{0,1})"					# device subtype - part 2
			deviceRegExpStr += r"(?P<sg>[-1-5]{2})"					# speed grade
			deviceRegExpStr += r"(?P<pack>[a-z]{1,3})"			# package
			deviceRegExpStr += r"(?P<pins>\d{1,4})"					# pin count
			
			deviceRegExp = RegExpCompile(deviceRegExpStr)
			deviceRegExpMatch = deviceRegExp.match(deviceString[4:].lower())

			if (deviceRegExpMatch is not None):
				subtype = deviceRegExpMatch.group('st1') + deviceRegExpMatch.group('st2')
				package = deviceRegExpMatch.group('pack')
				
				# print("SubType: %s" % subtype)
				
				if (subtype != ""):
					self.__subtype =	SubTypes[subtype.upper()]
				else:
					self.__subtype =	SubTypes.NoSubType
				
				self.__number =			int(deviceRegExpMatch.group('no'))
				self.__speedGrade =	int(deviceRegExpMatch.group('sg'))
				self.__package =		Packages[package.upper()]
				self.__pinCount =		int(deviceRegExpMatch.group('pins'))
			else:
				raise BaseException("RegExp mismatch.")
		
			# print(str(self))
		
		# vendor = Altera
		elif (deviceString[0:2].lower() == "ep"):
			self.__vendor =			Vendors.Altera
			self.__generation = int(deviceString[2:3])

			temp = deviceString[3:4].lower()
			if   (temp == Families.Cyclon.Token):		self.__family = Families.Cyclon
			elif (temp == Families.Stratix.Token):	self.__family = Families.Stratix

#			deviceRegExpStr =  r"(?P<st1>[cfhlstx]{0,2})"			# device subtype - part 1
#			deviceRegExpStr += r"(?P<no>\d{1,4})"							# device number
#			deviceRegExpStr += r"(?P<st2>[t]{0,1})"						# device subtype - part 2
#			deviceRegExpStr += r"(?P<sg>[-1-3]{2})"						# speed grade
#			deviceRegExpStr += r"(?P<pack>[fg]{1,3})"					# package
#			deviceRegExpStr += r"(?P<pins>\d{1,4})"						# pin count
#			
#			deviceRegExp = RegExpCompile(deviceRegExpStr)
#			deviceRegExpMatch = deviceRegExp.match(deviceString[4:].lower())
#
#			if (deviceRegExpMatch is not None):
#				print("dev subtype: %s%s" % (deviceRegExpMatch.group('st1'), deviceRegExpMatch.group('st2')))
			print("{RED}Device.__init__(): not fully implemented for Altera devices.{RESET}".format(**Init.Foreground))

		elif (deviceString[0:3].lower() == "lfe"):  # lfe - Lattice ECP series
			self.__vendor = Vendors.Lattice
			self.__generation = int(deviceString[3:4])

			print("{RED}Device.__init__(): not fully implemented for Lattice devices.{RESET}".format(**Init.Foreground))
		else:
			raise ConfigurationException("Can not decode device string '{0}'".format(deviceString))


	@property
	def Vendor(self):			return str(self.__vendor)
	@property
	def Family(self):			return str(self.__family)
	@property
	def Device(self):			return str(self.__device)
	@property
	def Generation(self):	return self.__generation
	@property
	def Number(self):			return self.__number
	@property
	def SpeedGrade(self):	return self.__speedGrade
	@property
	def PinCount(self):		return self.__pinCount
	@property
	def Package(self):		return self.__package
	@property
	def Name(self):				return self.FullName.upper()

	# @CachedReadOnlyProperty
	@property
	def ShortName(self):
		if (self.__vendor is Vendors.Xilinx):
			subtype = self.__subtype.Groups
			return "xc%i%s%s%s%s" % (
				self.__generation,
				self.__family.Token,
				subtype[0],
				"{num:03d}".format(num=self.__number),
				subtype[1]
			)
		elif (self.__vendor is Vendors.Altera):
			print("{YELLOW}Device.ShortName() not implemented for vendor Altera.{RESET}".format(**Init.Foreground))
			return "EP4SGX230KF40C2"
		elif (self.__vendor is Vendors.Lattice):
			print("{YELLOW}Device.ShortName() not implemented for vendor Lattice.{RESET}".format(**Init.Foreground))
			return "ECP5UM-45F"
		else:
			raise NotImplementedError("Device.ShortName() not implemented for vendor {0!s}".format(self.__vendor))
	
	# @CachedReadOnlyProperty
	@property
	def FullName(self):
		if (self.__vendor is Vendors.Xilinx):
			subtype = self.__subtype.Groups
			return "xc%i%s%s%s%s%i%s%i" % (
				self.__generation,
				self.__family.Token,
				subtype[0],
				"{num:03d}".format(num=self.__number),
				subtype[1],
				self.__speedGrade,
				str(self.__package),
				self.__pinCount
			)
		elif (self.__vendor is Vendors.Altera):
			print("{YELLOW}Device.FullName() not implemented for vendor Altera.{RESET}".format(**Init.Foreground))
			return "EP4SGX230KF40C2"
		elif (self.__vendor is Vendors.Lattice):
			print("{YELLOW}Device.FullName() not implemented for vendor Lattice.{RESET}".format(**Init.Foreground))
			return "ECP5UM-45F"
		else:
			raise NotImplementedError("Device.FullName() not implemented for vendor {0!s}".format(self.__vendor))

	# @CachedReadOnlyProperty
	@property
	def FamilyName(self):
		if (self.__family is Families.Zynq):
			return str(self.__family)
		else:
			return str(self.__family) + str(self.__generation)
	
	# @CachedReadOnlyProperty
	@property
	def Series(self):
		if (self.__generation == 7):
			if self.__family in [Families.Artix, Families.Kintex, Families.Virtex, Families.Zynq]:
				return "Series-7"
		else:
			return "{0}-{1}".format(str(self.__family), self.__generation)
	
	def _GetVariables(self):
		result = {
			"DeviceShortName" :		self.ShortName,
			"DeviceFullName" :		self.FullName,
			"DeviceVendor" :			self.Vendor,
			"DeviceFamily" :			self.Family,
			"DeviceGeneration" :	self.Generation,
			"DeviceNumber" :			self.Number,
			"DeviceSpeedGrade" :	self.SpeedGrade,
			"DevicePackage" :			self.Package,
			"DevicePinCount" :		self.PinCount
		}
		return result
	
	def __str__(self):
		return self.FullName

class Board:
	def __init__(self, host, boardName=None, device=None):
		# Board members
		self.__boardName =	boardName
		self.__device =			None

		if (boardName is None):
			boardName = "default"
		elif (boardName == ""):
			raise ValueError("Parameter 'board' is empty.")
		elif (not isinstance(boardName, str)):
			raise ValueError("Parameter 'board' is not of type str.")
		else:
			boardName = boardName.lower()

		if (boardName == "custom"):
			if (device is None):
				raise ValueError("Parameter 'device' is None.")
			elif isinstance(device, Device):
				self.__device = device
			else:
				self.__device = Device(device)
		else:
			boardSection = None
			for board in host.PoCConfig['BOARDS']:
				if (board.lower() == boardName):
					boardSection = host.PoCConfig['BOARDS'][board]
					break
			if (boardSection is None):
				raise ConfigurationException("Unknown board '{0}'".format(boardSection))

			deviceName = host.PoCConfig[boardSection]['FPGA']
			self.__device = Device(deviceName)

	@property
	def Name(self):
		return self.__boardName
	
	@property
	def Device(self):
		return self.__device
	
	def _GetVariables(self):
		result = {
			"BoardName" : self.__boardName
		}
		return result
	
	def __str__(self):
		return self.__boardName
	
	def __repr__(self):
		return str(self).lower()
