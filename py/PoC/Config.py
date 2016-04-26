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


class BaseEnum(Enum):
	def __str__(self):
		return self.name

	def __repr__(self):
		return str(self).lower()


@unique
class Vendors(BaseEnum):
	Unknown =			0
	Generic =			1
	Altera =			2
	Lattice =			3
	MicroSemi =		4
	Xilinx =			5

	def __str__(self):
		return self.name
	
	def __repr__(self):
		return str(self).lower()


class Families(BaseEnum):
	Unknown =		None
	Generic =		"g"
	# Xilinx families
	Spartan =		"s"
	Artix =			"a"
	Kintex =		"k"
	Virtex =		"v"
	Zynq =			"z"
	# Altera families
	Max =				"m"
	Cyclon =		"c"
	Arria =			"a"
	Stratix =		"s"

	# @CachedReadOnlyProperty
	@property
	def Token(self):
		return self.value


@unique
class Devices(BaseEnum):
	Unknown =									0
	Generic =									1

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

	# Lattice.iCE device
	iCE40 =										200
	# Lattice.MachXO
	MachXO =									210
	MachXO2 =									211
	MachXO3 =									212
	# Lattice.ECP
	ECP2 =										220
	ECP3 =										221
	ECP5 =										222

	# Xilinx.Spartan devices
	Spartan3 =								310
	Spartan6 =								311
	# Spartan7 =								312
	# Xilinx.Artix devices
	Artix7 =									320
	# Xilinx.Kintex devices
	Kintex7 =									330
	KintexUltraScale =				331
	KintexUltraScalePlus =		332
	# Xilinx.Virtex devices
	Virtex2 =									340
	Virtex4 =									341
	Virtex5 =									342
	Virtex6 =									343
	Virtex7 =									344
	VirtexUltraScale =				345
	VirtexUltraScalePlus =		346
	# Xilinx.Zynq devices
	Zynq7000 =								350

		
class SubTypes(BaseEnum):
	Unknown =		None
	Generic =		1
	NoSubType = ("",	"")
	# Altera device subtypes
	LS =				("ls",	"")
	E =					("e",		"")
	GS =				("gs",	"")
	GX =				("gx",	"")
	GT =				("gt",	"")
	# lAttice device subtypes
	U =					("u",		"")
	UM =				("um",	"")
	# Xilinx device subtypes
	X =					("x",		"")
	T =					("",		"t")
	XT =				("x",		"t")
	HT =				("h",		"t")
	LX =				("lx",	"")
	SXT =				("sx",	"t")
	LXT =				("lx",	"t")
	TXT =				("tx",	"t")
	FXT =				("fx",	"t")
	CXT =				("cx",	"t")
	HXT =				("hx",	"t")


	# @CachedReadOnlyProperty
	@property
	def Groups(self):
		return self.value

		
@unique
class Packages(BaseEnum):
	Unknown =	0
	Generic =	1
	
	TQG =			10
	
	CPG =			20
	CSG =			21
	
	FF =			30
	FFG =			31
	FTG =			32
	FGG =			33
	FLG =			34
	FT =			35
	
	RB =			40
	RBG =			41
	RS =			42
	RF =			43
	

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
		
		# vendor = GENERIC
		# ==========================================================================
		if   (deviceString[0:2].lower() == "ge"):		self._DecodeGeneric()									# ge - Generic FPGA device
		elif (deviceString[0:2].lower() == "xc"):		self._DecodeXilinx(deviceString)			# xc - Xilinx Commercial
		elif (deviceString[0:2].lower() == "ep"):		self._DecodeAltera(deviceString)			# ep -
		elif (deviceString[0:3].lower() == "ice"):	self._DecodeLatticeICE(deviceString)	# ice - Lattice iCE series
		elif (deviceString[0:3].lower() == "lcm"):	self._DecodeLatticeLCM(deviceString)	# lcm - Lattice MachXO series
		elif (deviceString[0:3].lower() == "lfe"):	self._DecodeLatticeLFE(deviceString)	# lfe - Lattice ECP series
		else:																				raise ConfigurationException("Unknown manufacturer code in device string '{0}'".format(deviceString))

	def _DecodeGeneric(self):
		self.__vendor =		Vendors.Generic
		self.__family =		Families.Artix
		self.__subtype =	SubTypes.Generic
		self.__package =	Packages.Generic

	def _DecodeAltera(self, deviceString):
		self.__vendor = Vendors.Altera
		self.__generation = int(deviceString[2:3])

		familyToken = deviceString[3:4].lower()
		if (familyToken == Families.Max.Token):				self._DecodeAlteraMax()
		elif (familyToken == Families.Cyclon.Token):	self._DecodeAlteraCyclone(deviceString)
		elif (familyToken == Families.Arria.Token):		self._DecodeAlteraArria()
		elif (familyToken == Families.Stratix.Token):	self._DecodeAlteraStratix(deviceString)
		else:																					raise ConfigurationException("Unknown Altera device family.")

	def _DecodeAlteraMax(self):
		self.__family = Families.Max
		raise NotImplementedError("No decode algorithm for Altera Max defined")

	def _DecodeAlteraArria(self):
		self.__family = Families.Arria
		raise NotImplementedError("No decode algorithm for Altera Arria defined")

	def _DecodeAlteraCyclone(self, deviceString):
		self.__family = Families.Cyclon
		if (self.__generation == 1):		raise NotImplementedError("No decode algorithm for Cyclone I defined")
		elif (self.__generation == 2):	raise NotImplementedError("No decode algorithm for Cyclone II defined")
		elif (self.__generation == 3):	self._DecodeCyclone3(deviceString)
		elif (self.__generation == 4):	raise ConfigurationException("A Cyclone IV device was never manufactured.")
		elif (self.__generation == 5):	self._DecodeCyclone5(deviceString)
		else:														raise ConfigurationException("Unknown Altera Cyclone generation.")

	def _DecodeCyclone3(self, deviceString):
		if (deviceString[4:6] == "LS"):
			self.__subtype = SubTypes.LS
			self.__number = int(deviceString[6:9])
		else:
			self.__number = int(deviceString[4:7])

	def _DecodeCyclone5(self, deviceString):
		# if (deviceString[4:5] == "E"):
		# 	self.__subtype = SubTypes.E
		# 	self.__number = int(deviceString[5:8])
		# elif (deviceString[4:6] == "GX"):
		# 	self.__subtype = SubTypes.GX
		# 	self.__number = int(deviceString[6:9])
		# else:
		raise NotImplementedError("No decode algorithm for Cyclone V defined")

	def _DecodeAlteraStratix(self, deviceString):
		self.__family = Families.Stratix
		if (self.__generation == 1):		raise NotImplementedError("No decode algorithm for Stratix I defined")
		elif (self.__generation == 2):	raise NotImplementedError("No decode algorithm for Stratix II defined")
		elif (self.__generation == 3):	raise NotImplementedError("No decode algorithm for Stratix III defined")
		elif (self.__generation == 4):	self._DecodeAlteraStratix4(deviceString)
		elif (self.__generation == 5):	self._DecodeAlteraStratix5(deviceString)
		else:														raise ConfigurationException("Unknown Altera Stratix generation.")

	def _DecodeAlteraStratix4(self, deviceString):
		if (deviceString[4:5] == "E"):
			self.__subtype = SubTypes.E
			self.__number = int(deviceString[5:8])
		elif (deviceString[4:6] == "GX"):
			self.__subtype = SubTypes.GX
			self.__number = int(deviceString[6:9])

		# TODO: EP 4 S GX 230 KF 40 C2
		else:
			raise NotImplementedError("No decode algorithm for Stratix IV GT defined")

	def _DecodeAlteraStratix5(self, deviceString):
		if (deviceString[4:5] == "E"):
			self.__subtype = SubTypes.E
		# self.__number = int(deviceString[5:8])
		elif (deviceString[4:6] == "GS"):
			self.__subtype = SubTypes.GS
		# self.__number = int(deviceString[5:8])
		elif (deviceString[4:6] == "GX"):
			self.__subtype = SubTypes.GX
		# self.__number = int(deviceString[5:8])
		elif (deviceString[4:6] == "GT"):
			self.__subtype = SubTypes.GT
		# self.__number = int(deviceString[5:8])
		print("{RED}Device._DecodeAlteraStratix5(): not fully implemented for Altera Stratix V.{NOCOLOR}".format(**Init.Foreground))

	def _DecodeLatticeICE(self, deviceString):
		self.__vendor = Vendors.Lattice

	def _DecodeLatticeLCM(self, deviceString):
		self.__vendor = Vendors.Lattice

	def _DecodeLatticeLFE(self, deviceString):
		self.__vendor = Vendors.Lattice
		self.__generation = int(deviceString[3:4])

		if   (self.__generation == 3):	self._DecodeLatticeECP3(deviceString)
		elif (self.__generation == 5):	self._DecodeLatticeECP5(deviceString)
		else:														raise ConfigurationException("Unknown Lattice ECP generation.")

		# "ECP5UM-45F"
		print("{RED}Device._DecodeLattice(): not fully implemented for Lattice devices.{NOCOLOR}".format(**Init.Foreground))

	def _DecodeLatticeECP3(self, deviceString):
		self.__subtype =	SubTypes.NoSubType
		self.__number =		int(deviceString[5:8])

	def _DecodeLatticeECP5(self, deviceString):
		familyToken = deviceString[4:6].lower()
		if (familyToken == "u-"):
			self.__subtype =		SubTypes.U
			self.__number =			int(deviceString[6:8])
			self.__speedGrade =	int(deviceString[9:10])
			self.__package =		Packages(deviceString[10:15])
		elif (familyToken == "um"):
			self.__subtype =		SubTypes.UM
			self.__number =			int(deviceString[7:9])
			self.__speedGrade = int(deviceString[10:11])
			self.__package = Packages(deviceString[11:16])
		else:
			raise ConfigurationException("Unknown Lattice ECP5 subtype.")

	def _DecodeXilinx(self, deviceString):
		self.__vendor = Vendors.Xilinx
		self.__generation = int(deviceString[2:3])

		familyToken = deviceString[3:4].lower()
		if   (familyToken == Families.Artix.Token):		self.__family = Families.Artix
		elif (familyToken == Families.Kintex.Token):	self.__family = Families.Kintex
		elif (familyToken == Families.Spartan.Token):	self.__family = Families.Spartan
		elif (familyToken == Families.Virtex.Token):	self.__family = Families.Virtex
		elif (familyToken == Families.Zynq.Token):		self.__family = Families.Zynq
		else:																					raise Exception("Unknown device family.")

		deviceRegExpStr =  r"(?P<st1>[a-z]{0,2})"   # device subtype - part 1
		deviceRegExpStr += r"(?P<no>\d{1,4})"       # device number
		deviceRegExpStr += r"(?P<st2>[t]{0,1})"     # device subtype - part 2
		deviceRegExpStr += r"(?P<sg>[-1-5]{2})"     # speed grade
		deviceRegExpStr += r"(?P<pack>[a-z]{1,3})"  # package
		deviceRegExpStr += r"(?P<pins>\d{1,4})"     # pin count
		deviceRegExp = RegExpCompile(deviceRegExpStr)
		deviceRegExpMatch = deviceRegExp.match(deviceString[4:].lower())

		if (deviceRegExpMatch is not None):
			subtype = deviceRegExpMatch.group('st1') + deviceRegExpMatch.group('st2')
			package = deviceRegExpMatch.group('pack')

			if (subtype != ""):		self.__subtype = SubTypes[subtype.upper()]
			else:									self.__subtype = SubTypes.NoSubType

			self.__number =			int(deviceRegExpMatch.group('no'))
			self.__speedGrade =	int(deviceRegExpMatch.group('sg'))
			self.__package =		Packages[package.upper()]
			self.__pinCount =		int(deviceRegExpMatch.group('pins'))
		else:
			raise ConfigurationException("RegExp mismatch.")

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
		if (self.__vendor is Vendors.Generic):
			return "GENERIC"
		elif (self.__vendor is Vendors.Xilinx):
			subtype = self.__subtype.Groups
			if (self.__family is Families.Zynq):
				number_format = "{num:03d}"
			else:
				number_format = "{num}"
			return ("XC%i%s%s%s%s" % (
				self.__generation,
				self.__family.Token,
				subtype[0],
				number_format.format(num=self.__number),
				subtype[1]
			)).upper()
		elif (self.__vendor is Vendors.Altera):
			print("{YELLOW}Device.ShortName() not implemented for vendor Altera.{NOCOLOR}".format(**Init.Foreground))
			return "EP4SGX230KF40C2"
		elif (self.__vendor is Vendors.Lattice):
			print("{YELLOW}Device.ShortName() not implemented for vendor Lattice.{NOCOLOR}".format(**Init.Foreground))
			return "ECP5UM-45F"
		else:
			raise NotImplementedError("Device.ShortName() not implemented for vendor {0!s}".format(self.__vendor))
	
	# @CachedReadOnlyProperty
	@property
	def FullName(self):
		if (self.__vendor is Vendors.Generic):
			return "GENERIC"
		elif (self.__vendor is Vendors.Xilinx):
			subtype = self.__subtype.Groups
			if (self.__family is Families.Zynq):
				number_format = "{num:03d}"
			else:
				number_format = "{num}"
			return ("XC%i%s%s%s%s%i%s%i" % (
				self.__generation,
				self.__family.Token,
				subtype[0],
				number_format.format(num=self.__number),
				subtype[1],
				self.__speedGrade,
				str(self.__package),
				self.__pinCount
			)).upper()
		elif (self.__vendor is Vendors.Altera):
			print("{YELLOW}Device.FullName() not implemented for vendor Altera.{NOCOLOR}".format(**Init.Foreground))
			return "EP4SGX230KF40C2"
		elif (self.__vendor is Vendors.Lattice):
			print("{YELLOW}Device.FullName() not implemented for vendor Lattice.{NOCOLOR}".format(**Init.Foreground))
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
	
	def GetVariables(self):
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
	def Name(self):			return self.__boardName
	@property
	def Device(self):		return self.__device
	
	def GetVariables(self):
		result = {
			"BoardName" : self.__boardName
		}
		return result
	
	def __str__(self):
		return self.__boardName
	
	def __repr__(self):
		return str(self).lower()
