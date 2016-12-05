# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Thomas B. Preusser
#
# Python Class:     Contains PoC's logging (console output) mechanism.
#
# License:
# ==============================================================================
# Copyright 2007-2016 Technische Universitaet Dresden - Germany
#                     Chair of VLSI-Design, Diagnostics and Architecture
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
# load dependencies
from enum             import Enum, unique

from lib.Functions    import Init


__api__ = [
	'Severity',
	'LogEntry',
	'Logger',
	'ILogable'
]
__all__ = __api__


@unique
class Severity(Enum):
	"""Logging message severity levels."""
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
		"""Patch the embedded MAP dictionary."""
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
		"""Translate a VHDL severity level into logging severity level."""
		return cls.__VHDL_SEVERITY_LEVEL_MAP__.get(severity, fallback)


class LogEntry:
	"""Represents a single line log message with a severity and indentation level."""
	def __init__(self, message, severity=Severity.Normal, indent=0, appendLinebreak=True):
		self._severity =        severity
		self._message =         message
		self._indent =          indent
		self.AppendLinebreak =  appendLinebreak

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
	def Severity(self):
		"""Return the log message's severity level."""
		return self._severity

	@property
	def Indent(self):
		"""Return the log message's indentation level."""
		return self._indent

	@property
	def Message(self):
		"""Return the indented log message."""
		return ("  " * self._indent) + self._message

	def IndentBy(self, indent):
		"""Increase a log message's indentation level."""
		self._indent += indent

	def __str__(self):
		return self._Log_MESSAGE_FORMAT__[self._severity].format(message=self._message)


class Logger:
	def __init__(self, logLevel, printToStdOut=True):
		"""Class nitializer."""
		self._LogLevel =        logLevel
		self._printToStdOut =   printToStdOut
		self._entries =         []
		self._baseIndent =      0

	@property
	def LogLevel(self):
		"""Return the currently logged minimal severity level."""
		return self._LogLevel
	@LogLevel.setter
	def LogLevel(self, value):
		"""Set the logged minimal severity level."""
		self._LogLevel = value

	@property
	def BaseIndent(self):           return self._baseIndent
	@BaseIndent.setter
	def BaseIndent(self, value):    self._baseIndent = value

	_Log_MESSAGE_FORMAT__ = {
		Severity.Fatal:   "{DARK_RED}{message}{NOCOLOR}",
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
				print(self._Log_MESSAGE_FORMAT__[entry.Severity].format(message=entry.Message, **Init.Foreground), end="\n" if entry.AppendLinebreak else "")
			return True
		else:
			return False

	def TryWrite(self, entry):
		return (entry.Severity >= self._LogLevel)

	def WriteFatal(self, message, indent=0, appendLinebreak=True):
		return self.Write(LogEntry(message, Severity.Fatal, self._baseIndent + indent, appendLinebreak))

	def WriteError(self, message, indent=0, appendLinebreak=True):
		return self.Write(LogEntry(message, Severity.Error, self._baseIndent + indent, appendLinebreak))

	def WriteWarning(self, message, indent=0, appendLinebreak=True):
		return self.Write(LogEntry(message, Severity.Warning, self._baseIndent + indent, appendLinebreak))

	def WriteInfo(self, message, indent=0, appendLinebreak=True):
		return self.Write(LogEntry(message, Severity.Info, self._baseIndent + indent, appendLinebreak))

	def WriteQuiet(self, message, indent=0, appendLinebreak=True):
		return self.Write(LogEntry(message, Severity.Quiet, self._baseIndent + indent, appendLinebreak))

	def WriteNormal(self, message, indent=0, appendLinebreak=True):
		return self.Write(LogEntry(message, Severity.Normal, self._baseIndent + indent, appendLinebreak))

	def WriteVerbose(self, message, indent=1, appendLinebreak=True):
		return self.Write(LogEntry(message, Severity.Verbose, self._baseIndent + indent, appendLinebreak))

	def WriteDebug(self, message, indent=2, appendLinebreak=True):
		return self.Write(LogEntry(message, Severity.Debug, self._baseIndent + indent, appendLinebreak))

	def WriteDryRun(self, message, indent=2, appendLinebreak=True):
		return self.Write(LogEntry(message, Severity.DryRun, self._baseIndent + indent, appendLinebreak))


class ILogable:
	"""A mixin class to provide local logging methods."""
	def __init__(self, logger=None):
		"""MixIn initializer."""
		self._logger = logger

		# FIXME: Alter methods if a logger is present or set dummy methods

	@property
	def Logger(self):
		"""Return the local logger instance."""
		return self._logger

	def Log(self, entry, condition=True):
		"""Write an entry to the local logger."""
		if ((self._logger is not None) and condition):
			return self._logger.Write(entry)
		return False

	def _TryLog(self, *args, condition=True, **kwargs):
		if ((self._logger is not None) and condition):
			return self._logger.TryWrite(*args, **kwargs)
		return False

	def LogFatal(self, *args, condition=True, **kwargs):
		if ((self._logger is not None) and condition):
			return self._logger.WriteFatal(*args, **kwargs)
		return False

	def LogError(self, *args, condition=True, **kwargs):
		if ((self._logger is not None) and condition):
			return self._logger.WriteError(*args, **kwargs)
		return False

	def LogWarning(self, *args, condition=True, **kwargs):
		if ((self._logger is not None) and condition):
			return self._logger.WriteWarning(*args, **kwargs)
		return False

	def LogInfo(self, *args, condition=True, **kwargs):
		if ((self._logger is not None) and condition):
			return self._logger.WriteInfo(*args, **kwargs)
		return False

	def LogQuiet(self, *args, condition=True, **kwargs):
		if ((self._logger is not None) and condition):
			return self._logger.WriteQuiet(*args, **kwargs)
		return False

	def LogNormal(self, *args, condition=True, **kwargs):
		if ((self._logger is not None) and condition):
			return self._logger.WriteNormal(*args, **kwargs)
		return False

	def LogVerbose(self, *args, condition=True, **kwargs):
		if ((self._logger is not None) and condition):
			return self._logger.WriteVerbose(*args, **kwargs)
		return False

	def LogDebug(self, *args, condition=True, **kwargs):
		if ((self._logger is not None) and condition):
			return self._logger.WriteDebug(*args, **kwargs)
		return False

	def LogDryRun(self, *args, condition=True, **kwargs):
		if ((self._logger is not None) and condition):
			return self._logger.WriteDryRun(*args, **kwargs)
		return False
