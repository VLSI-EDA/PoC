# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
# Python Class:			TODO
# 
# Authors:					Patrick Lehmann
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
#
# entry point
if __name__ != "__main__":
	# place library initialization code here
	pass
else:
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module Base.SolutionBase")

# load dependencies
from pathlib import Path

from Base.Exceptions import NotConfiguredException, EnvironmentException


class CommandLineProgram(object):
	import platform
	
	# configure hard coded variables here
	__scriptDirectoryName = 			"py"
	__pocPrivateConfigFileName =	"config.private.ini"
	__pocPublicConfigFileName =		"config.public.ini"

	# private fields
	__debug =			False
	__verbose =		False
	__quiet =			False
	__platform = platform.system()			# load platform information (Windows, Linux, ...)

	__directories =	{}
	__files =				{}
	__pocConfig =		None
	
	# constructor
	# ============================================================================
	def __init__(self, debug, verbose, quiet):
		from os import environ
		
		# save flags
		self.__debug =		debug
		self.__verbose =	verbose
		self.__quiet =		quiet
		
		# check for environment variables
		if (environ.get('PoCRootDirectory') is None):			raise EnvironmentException("Shell environment does not provide 'PoCRootDirectory' variable.")

		self.directories['Working'] =			Path.cwd()
		self.directories['PoCRoot'] =			Path(environ.get('PoCRootDirectory'))
		self.directories['ScriptRoot'] =	Path(environ.get('PoCRootDirectory'))
		self.files['PoCPrivateConfig'] =	self.RootDirectory / self.__scriptDirectoryName / self.__pocPrivateConfigFileName
		self.files['PoCPublicConfig'] =		self.RootDirectory / self.__scriptDirectoryName / self.__pocPublicConfigFileName
		
		self.readPoCConfiguration()

	# class properties
	# ============================================================================
	@property
	def debug(self):				return self.__debug
	
	@property
	def verbose(self):			return self.__verbose
	
	@property
	def quiet(self):				return self.__quiet
	
	@property
	def platform(self):			return self.__platform
	
	@property
	def directories(self):	return self.__directories
			
	@property
	def files(self):				return self.__files
	

#	Directories = {
#		"Root"					: Path.cwd()
#		}
#	
#	Files = {
#		"Config"				: None
#	}
	
	__configFileName = "configuration.ini"
	config = None

		
	# read  configuration
	# ============================================================================
	def __readConfiguration(self):
		from configparser import ConfigParser, ExtendedInterpolation
		
		configFilePath = self.Directories["Root"] / self.__configFileName
		self.Files["Configuration"]	= configFilePath
		
		self.printDebug("Reading configuration from '%s'" % str(configFilePath))
		if not configFilePath.exists():	raise NotConfiguredException("Configuration file does not exist. (%s)" % str(configFilePath))
		
		self.config = ConfigParser(interpolation=ExtendedInterpolation())
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
	
	
	# print messages
	# ============================================================================
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
