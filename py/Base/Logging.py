# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
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
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module Base.PoCBase")

from colorama								import Fore as Foreground
from enum										import Enum, unique
	
@unique
class Severity(Enum):
	Fatal =			30
	Error =			25
	Quiet =			20
	Warning =		15
	Info =			10
	Normal =		 4
	Verbose =		 2
	Debug =			 1
	All =				 0
	
	def __eq__(self, other):		return self.value ==	other.value
	def __ne__(self, other):		return self.value !=	other.value
	def __lt__(self, other):		return self.value <		other.value
	def __le__(self, other):		return self.value <=	other.value
	def __gt__(self, other):		return self.value >		other.value
	def __ge__(self, other):		return self.value >=	other.value
	

class LogEntry:
	def __init__(self, message, severity=Severity.Normal):
		self._severity =	severity
		self._message =		message
		self._indent =		0
	
	@property
	def Severity(self):
		return self._severity
	
	@property
	def Message(self):
		return ("  " * self._indent) + self._message

	def Indent(self, indent):
		self._indent += indent
	
	def __str__(self):
		if (self._severity is Severity.Fatal):			return "FATAL: " +		self._message
		elif (self._severity is Severity.Error):		return "ERROR: " +		self._message
		elif (self._severity is Severity.Warning):	return "WARNING: " +	self._message
		elif (self._severity is Severity.Info):			return "INFO: " +			self._message
		elif (self._severity is Severity.Quiet):		return 								self._message
		elif (self._severity is Severity.Normal):		return 								self._message
		elif (self._severity is Severity.Verbose):	return "VERBOSE: " +	self._message
		elif (self._severity is Severity.Debug):		return "DEBUG: " +		self._message

class Logger:
	def __init__(self, host, logLevel, printToStdOut=True):
		self._host =					host
		self._logLevel =			logLevel
		self._printToStdOut =	printToStdOut
		self._entries =				[]
	
	@property
	def LogLevel(self):
		return self._logLevel
	@LogLevel.setter
	def LogLevel(self, value):
		self._logLevel = value
	
	def Write(self, entry):
		if (entry.Severity >= self._logLevel):
			self._entries.append(entry)
			if self._printToStdOut:
				if (entry.Severity is Severity.Fatal):			print("{0}{1}{2}".format(Foreground.RED, entry.Message, Foreground.RESET))
				elif (entry.Severity is Severity.Error):		print("{0}{1}{2}".format(Foreground.LIGHTRED_EX, entry.Message, Foreground.RESET))
				elif (entry.Severity is Severity.Quiet):		print(entry.Message + "......")
				elif (entry.Severity is Severity.Warning):	print("{0}{1}{2}".format(Foreground.LIGHTYELLOW_EX, entry.Message, Foreground.RESET))
				elif (entry.Severity is Severity.Info):			print("{0}{1}{2}".format(Foreground.CYAN, entry.Message, Foreground.RESET))
				elif (entry.Severity is Severity.Normal):		print(entry.Message)
				elif (entry.Severity is Severity.Verbose):	print("{0}{1}{2}".format(Foreground.WHITE, entry.Message, Foreground.RESET))
				elif (entry.Severity is Severity.Debug):		print("{0}{1}{2}".format(Foreground.LIGHTBLACK_EX, entry.Message, Foreground.RESET))

			return True
		else:
			return False

	def TryWrite(self, entry):
		return (entry.Severity >= self._logLevel)
	
	def WriteFatal(self, message):
		return self.Write(LogEntry(message, Severity.Fatal))
	
	def WriteError(self, message):
		return self.Write(LogEntry(message, Severity.Error))
	
	def WriteWarning(self, message):
		return self.Write(LogEntry(message, Severity.Warning))
	
	def WriteInfo(self, message):
		return self.Write(LogEntry(message, Severity.Info))
	
	def WriteQuiet(self, message):
		return self.Write(LogEntry(message, Severity.Quiet))
	
	def WriteNormal(self, message):
		return self.Write(LogEntry(message, Severity.Normal))
	
	def WriteVerbose(self, message):
		return self.Write(LogEntry(message, Severity.Verbose))
	
	def WriteDebug(self, message):
		return self.Write(LogEntry(message, Severity.Debug))
	
		
class ILogable:
	def __init__(self, logger=None):
		self.__logger = logger

	@property
	def Logger(self):
		return self.__logger

	def _Log(self, entry):
		if self.__logger is not None:
			return self.__logger.Write(entry)
		return False

	def _TryLog(self, entry):
		if self.__logger is not None:
			return self.__logger.TryWrite(entry)
		return False

	def _LogFatal(self, message):
		if self.__logger is not None:
			return self.__logger.WriteFatal(message)
		return False

	def _LogError(self, message):
		if self.__logger is not None:
			return self.__logger.WriteError(message)
		return False
	
	def _LogWarning(self, message):
		if self.__logger is not None:
			return self.__logger.WriteWarning(message)
		return False
	
	def _LogInfo(self, message):
		if self.__logger is not None:
			return self.__logger.WriteInfo(message)
		return False
	
	def _LogQuiet(self, message):
		if self.__logger is not None:
			return self.__logger.WriteQuiet(message)
		return False
	
	def _LogNormal(self, message):
		if self.__logger is not None:
			return self.__logger.WriteNormal(message)
		return False
	
	def _LogVerbose(self, message):
		if self.__logger is not None:
			return self.__logger.WriteVerbose(message)
		return False
	
	def _LogDebug(self, message):
		if self.__logger is not None:
			return self.__logger.WriteDebug(message)
		return False
