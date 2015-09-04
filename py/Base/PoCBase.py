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
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module Base.PoCBase")

# load dependencies
from pathlib import Path
from Base.Exceptions import *

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
		if (environ.get('PoCRootDirectory') == None):			raise EnvironmentException("Shell environment does not provide 'PoCRootDirectory' variable.")
		if (environ.get('PoCScriptDirectory') == None):		raise EnvironmentException("Shell environment does not provide 'PoCScriptDirectory' variable.")
		
		self.directories['Working'] =			Path.cwd()
		self.directories['PoCRoot'] =			Path(environ.get('PoCRootDirectory'))
		self.directories['ScriptRoot'] =	Path(environ.get('PoCRootDirectory'))
		self.files['PoCPrivateConfig'] =	self.directories["PoCRoot"] / self.__scriptDirectoryName / self.__pocPrivateConfigFileName
		self.files['PoCPublicConfig'] =		self.directories["PoCRoot"] / self.__scriptDirectoryName / self.__pocPublicConfigFileName
		
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
	
	# read PoC configuration
	# ============================================================================
	def readPoCConfiguration(self):
		from configparser import ConfigParser, ExtendedInterpolation
	
		pocPrivateConfigFilePath =	self.files['PoCPrivateConfig']
		pocPublicConfigFilePath =		self.files['PoCPublicConfig']
		
		self.printDebug("Reading PoC configuration from '%s' and '%s'" % (str(pocPrivateConfigFilePath), str(pocPublicConfigFilePath)))
		if not pocPrivateConfigFilePath.exists():		raise NotConfiguredException("Private PoC configuration file does not exist. (%s)"	% str(pocPrivateConfigFilePath))
		if not pocPublicConfigFilePath.exists():		raise NotConfiguredException("Public PoC configuration file does not exist. (%s)"		% str(pocPublicConfigFilePath))
		
		self.pocConfig = ConfigParser(interpolation=ExtendedInterpolation())
		self.pocConfig.optionxform = str
		self.pocConfig.read([
			str(self.files['PoCPrivateConfig']),
			str(self.files['PoCPublicConfig'])
		])
		
		# parsing values into class fields
		if (self.directories["PoCRoot"] != Path(self.pocConfig['PoC']['InstallationDirectory'])):
			raise NotConfiguredException("There is a mismatch between PoCRoot and PoC installation directory.")

		# read PoC configuration
		# ============================================================================
		# parsing values into class fields
		self.directories["PoCSource"] =			self.directories["PoCRoot"] / self.pocConfig['PoC.DirectoryNames']['HDLSourceFiles']
		self.directories["PoCTestbench"] =	self.directories["PoCRoot"] / self.pocConfig['PoC.DirectoryNames']['TestbenchFiles']
		self.directories["PoCNetList"] =		self.directories["PoCRoot"] / self.pocConfig['PoC.DirectoryNames']['NetListFiles']
		self.directories["PoCTemp"] =				self.directories["PoCRoot"] / self.pocConfig['PoC.DirectoryNames']['TemporaryFiles']

		self.directories["iSimFiles"] =			self.directories["PoCRoot"] / self.pocConfig['PoC.DirectoryNames']['ISESimulatorFiles']
		self.directories["XSTFiles"] =			self.directories["PoCRoot"] / self.pocConfig['PoC.DirectoryNames']['ISESynthesisFiles']
		#self.directories["QuartusFiles"] =	self.directories["PoCRoot"] / self.pocConfig['PoC.DirectoryNames']['QuartusSynthesisFiles']

		self.directories["iSimTemp"] =			self.directories["PoCTemp"] / self.pocConfig['PoC.DirectoryNames']['ISESimulatorFiles']
		self.directories["xSimTemp"] =			self.directories["PoCTemp"] / self.pocConfig['PoC.DirectoryNames']['VivadoSimulatorFiles']
		self.directories["vSimTemp"] =			self.directories["PoCTemp"] / self.pocConfig['PoC.DirectoryNames']['ModelSimSimulatorFiles']
		self.directories["GHDLTemp"] =			self.directories["PoCTemp"] / self.pocConfig['PoC.DirectoryNames']['GHDLSimulatorFiles']

		self.directories["CoreGenTemp"] =		self.directories["PoCTemp"] / self.pocConfig['PoC.DirectoryNames']['ISECoreGeneratorFiles']
		self.directories["XSTTemp"] =				self.directories["PoCTemp"] / self.pocConfig['PoC.DirectoryNames']['ISESynthesisFiles']
		#self.directories["QuartusTemp"] =	self.directories["PoCTemp"] / self.pocConfig['PoC.DirectoryNames']['QuartusSynthesisFiles']

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
