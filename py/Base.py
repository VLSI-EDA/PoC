# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
# Python Class:			TODO
# 
# Authors:				 	Patrick Lehmann
# 
# Description:
# ------------------------------------
#		TODO:
#		- 
#		- 
#
# License:
# ==============================================================================
# Copyright 2007-2014 Technische Universitaet Dresden - Germany
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

	print("========================================================================")
	print("                  SATAController - Python Class Base                    ")
	print("========================================================================")
	print()
	print("This is no executable file!")
	exit(1)


from enum import Enum, EnumMeta, unique
import configparser
from pathlib import Path
import re


class Base(object):
	from platform import system
	
	__debug = False
	__verbose = False
	__quiet = False
	platform = system()

	Directories = {
		"Root"					: Path.cwd()
		}
	
	Files = {
		"Config"				: None
	}
	
	__configFileName = "configuration.ini"
	config = None
	
	def __init__(self, debug, verbose, quiet):
		self.__debug = debug
		self.__verbose = verbose
		self.__quiet = quiet

		self.__readConfiguration()
		
	# read  configuration
	# ============================================================================
	def __readConfiguration(self):
		configFilePath = self.Directories["Root"] / self.__configFileName
		self.Files["Configuration"]	= configFilePath
		
		self.printDebug("Reading configuration from '%s'" % str(configFilePath))
		if not configFilePath.exists():
			raise NotConfiguredException("Configuration file does not exist. (%s)" % str(configFilePath))
		
		self.config = configparser.ConfigParser(interpolation=configparser.ExtendedInterpolation())
		self.config.optionxform = str
		self.config.read(str(configFilePath))
		
		# parsing values into class fields
		self.Directories["SolutionRoot"] = Path(self.config['Solution']['InstallationDirectory'])

		self.Directories["Source"] =			self.Directories["SolutionRoot"] / self.config['DirectoryNames']['HDLSourceFiles']
		self.Directories["Testbench"] =		self.Directories["SolutionRoot"] / self.config['DirectoryNames']['TestbenchFiles']
		self.Directories["NetList"] =			self.Directories["SolutionRoot"] / self.config['DirectoryNames']['NetListFiles']
		self.Directories["Temp"] =				self.Directories["SolutionRoot"] / self.config['DirectoryNames']['TemporaryFiles']
		self.Directories["Project"] =			self.Directories["SolutionRoot"] / self.config['DirectoryNames']['ProjectFiles']
		
#		self.Directories["iSimFiles"] =		self.Directories["Root"] / self.structure['DirectoryNames']['ISESimulatorFiles']
#		self.Directories["XSTFiles"] =		self.Directories["Root"] / self.structure['DirectoryNames']['ISESynthesisFiles']
#		#self.Directories["QuartusFiles"] =	self.Directories["Root"] / self.structure['DirectoryNames']['QuartusSynthesisFiles']
#		
#		self.Directories["iSimTemp"] =			self.Directories["Temp"] / self.structure['DirectoryNames']['ISESimulatorFiles']
#		self.Directories["xSimTemp"] =			self.Directories["Temp"] / self.structure['DirectoryNames']['VivadoSimulatorFiles']
#		self.Directories["vSimTemp"] =			self.Directories["Temp"] / self.structure['DirectoryNames']['ModelSimSimulatorFiles']
#		self.Directories["GHDLTemp"] =			self.Directories["Temp"] / self.structure['DirectoryNames']['GHDLSimulatorFiles']
#		
#		self.Directories["CoreGenTemp"] =		self.Directories["Temp"] / self.structure['DirectoryNames']['ISECoreGeneratorFiles']
#		self.Directories["XSTTemp"] =				self.Directories["Temp"] / self.structure['DirectoryNames']['ISESynthesisFiles']
#		#self.Directories["QuartusTemp"] =	self.Directories["Temp"] / self.structure['DirectoryNames']['QuartusSynthesisFiles']
	
	def getDebug(self):
		return self.__debug
		
	def getVerbose(self):
		return self.__verbose
	
	def getQuiet(self):
		return self.__quiet
	
	def printDebug(self, message):
		if (self.__debug):
			print("DEBUG: " + message)
	
	def printVerbose(self, message):
		if (self.__verbose):
			print(message)
	
	def printNonQuiet(self, message):
		if (not self.__quiet):
			print(message)


class Extractor(object):
	pass
			
class NotImplementedException(Exception):
	def __init__(self, message):
		super().__init__()
		self.message = message
	
class ArgumentException(Exception):
	def __init__(self, message):
		super().__init__()
		self.message = message
		
class BaseException(Exception):
	def __init__(self, message=""):
		super().__init__()
		self.message = message

	def __str__(self):
		return self.message
		
class EnvironmentException(BaseException):
	def __init__(self, message=""):
		super().__init__(message)
		self.message = message

class PlatformNotSupportedException(BaseException):
	def __init__(self, message=""):
		super().__init__(message)
		self.message = message

class NotConfiguredException(BaseException):
	def __init__(self, message=""):
		super().__init__(message)
		self.message = message
