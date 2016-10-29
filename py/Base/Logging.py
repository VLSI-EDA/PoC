# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Thomas B. Preusser
#
# Python Class:      TODO
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
#                     Chair for VLSI-Design, Diagnostics and Architecture
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
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


from enum             import Enum, unique

from lib.Functions    import Init


@unique
class Severity(Enum):
	Fatal =     30
	Error =     25
	Quiet =     20
	Warning =   15
	Info =      10
	DryRun =     5
	Normal =     4
	Verbose =    2
	Debug =      1
	All =        0

	def __init__(self, *_):
		"""Patch the embedded MAP dictionary"""
		for k,v in self.__class__.__VHDL_SEVERITY_LEVEL_MAP__.items():
			if ((not isinstance(v, self.__class__)) and (v == self.value)):
				self.__class__.__VHDL_SEVERITY_LEVEL_MAP__[k] = self

	def __hash__(self):
		return hash(self.name)

	def __eq__(self, other):    return self.value ==  other.value
	def __ne__(self, other):    return self.value !=  other.value
	def __lt__(self, other):    return self.value <		other.value
	def __le__(self, other):    return self.value <=  other.value
	def __gt__(self, other):    return self.value >		other.value
	def __ge__(self, other):    return self.value >=  other.value

	__VHDL_SEVERITY_LEVEL_MAP__ =  {
		"failure": Fatal,
		"error":   Error,
		"warning": Warning,
		"note":    Info
	}

	@classmethod
	def ParseVHDLSeverityLevel(cls, severity, fallback=None):
		return cls.__VHDL_SEVERITY_LEVEL_MAP__.get(severity, fallback)


class LogEntry:
	def __init__(self, message, severity=Severity.Normal, indent=0):
		self._severity =  severity
		self._message =    message
		self._indent =    indent

	_Log_MESSAGE_FORMAT__ = {
		Severity.Fatal:     "FATAL: {message}",
		Severity.Error:     "ERROR: {message}",
		Severity.Warning:   "WARNING: {message}",
		Severity.Info:      "INFO: {message}",
		Severity.Quiet:     "{message}",
		Severity.Normal:    "{message}",
		Severity.Verbose:   "VERBOSE: {message}",
		Severity.Debug:     "DEBUG: {message}",
		Severity.DryRun:    "DRYRUN: {message}"
	}

	@property
	def Severity(self):   return self._severity
	@property
	def Indent(self):     return self._indent
	@property
	def Message(self):    return ("  " * self._indent) + self._message

	def IndentBy(self, indent):
		self._indent += indent

	def __str__(self):
		return self._Log_MESSAGE_FORMAT__[self._severity].format(message=self._message)

class Logger:
	def __init__(self, host, logLevel, printToStdOut=True):
		self._host =            host
		self._LogLevel =        logLevel
		self._printToStdOut =   printToStdOut
		self._entries =         []
		self._baseIndent =      0

	@property
	def LogLevel(self):             return self._LogLevel
	@LogLevel.setter
	def LogLevel(self, value):      self._LogLevel = value

	@property
	def BaseIndent(self):           return self._baseIndent
	@BaseIndent.setter
	def BaseIndent(self, value):    self._baseIndent = value

	_Log_MESSAGE_FORMAT__ = {
		Severity.Fatal:   "{DARKRED}{message}{NOCOLOR}",
		Severity.Error:   "{RED}{message}{NOCOLOR}",
		Severity.Quiet:   "{WHITE}{message}{NOCOLOR}",
		Severity.Warning: "{YELLOW}{message}{NOCOLOR}",
		Severity.Info:    "{WHITE}{message}{NOCOLOR}",
		Severity.DryRun:  "{DARK_CYAN}{message}{NOCOLOR}",
		Severity.Normal:  "{WHITE}{message}{NOCOLOR}",
		Severity.Verbose: "{GRAY}{message}{NOCOLOR}",
		Severity.Debug:   "{DARK_GRAY}{message}{NOCOLOR}"
	}

	def Write(self, entry):
		if (entry.Severity >= self._LogLevel):
			self._entries.append(entry)
			if self._printToStdOut:
				print(self._Log_MESSAGE_FORMAT__[entry.Severity].format(message=entry.Message, **Init.Foreground))
			return True
		else:
			return False

	def TryWrite(self, entry):
		return (entry.Severity >= self._LogLevel)

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

	def WriteNormal(self, message, indent=0):
		return self.Write(LogEntry(message, Severity.Normal, self._baseIndent + indent))

	def WriteVerbose(self, message, indent=1):
		return self.Write(LogEntry(message, Severity.Verbose, self._baseIndent + indent))

	def WriteDebug(self, message, indent=2):
		return self.Write(LogEntry(message, Severity.Debug, self._baseIndent + indent))

	def WriteDryRun(self, message, indent=2):
		return self.Write(LogEntry(message, Severity.DryRun, self._baseIndent + indent))


class ILogable:
	def __init__(self, logger=None):
		self._Logger = logger

	@property
	def Logger(self):
		return self._Logger

	def Log(self, entry):
		if self._Logger is not None:
			return self._Logger.Write(entry)
		return False

	def _TryLog(self, *args, **kwargs):
		if self._Logger is not None:
			return self._Logger.TryWrite(*args, **kwargs)
		return False

	def LogFatal(self, *args, **kwargs):
		if self._Logger is not None:
			return self._Logger.WriteFatal(*args, **kwargs)
		return False

	def LogError(self, *args, **kwargs):
		if self._Logger is not None:
			return self._Logger.WriteError(*args, **kwargs)
		return False

	def LogWarning(self, *args, **kwargs):
		if self._Logger is not None:
			return self._Logger.WriteWarning(*args, **kwargs)
		return False

	def LogInfo(self, *args, **kwargs):
		if self._Logger is not None:
			return self._Logger.WriteInfo(*args, **kwargs)
		return False

	def LogQuiet(self, *args, **kwargs):
		if self._Logger is not None:
			return self._Logger.WriteQuiet(*args, **kwargs)
		return False

	def LogNormal(self, *args, **kwargs):
		if self._Logger is not None:
			return self._Logger.WriteNormal(*args, **kwargs)
		return False

	def LogVerbose(self, *args, **kwargs):
		if self._Logger is not None:
			return self._Logger.WriteVerbose(*args, **kwargs)
		return False

	def LogDebug(self, *args, **kwargs):
		if self._Logger is not None:
			return self._Logger.WriteDebug(*args, **kwargs)
		return False

	def LogDryRun(self, *args, **kwargs):
		if self._Logger is not None:
			return self._Logger.WriteDryRun(*args, **kwargs)
		return False
