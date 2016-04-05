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
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module Processor.Base")

# load dependencies
from Base.Exceptions import *

class PoCProcessor(object):
	__host = None
	__debug = False
	__verbose = False
	__quiet = False
	showLogs = False
	showReport = False
	dryRun = False

	def __init__(self, host, showLogs, showReport):
		self.__debug = host.getDebug()
		self.__verbose = host.getVerbose()
		self.__quiet = host.getQuiet()
		self.host = host
		self.showLogs = showLogs
		self.showReport = showReport

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


class ProcessorException(ExceptionBase):
	def __init__(self, message=""):
		super().__init__(message)
		self.message = message

#class EndOfReportException(ProcessorException):
#	pass