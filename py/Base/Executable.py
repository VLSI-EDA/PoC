# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#
# Python Module:    Basic abstraction layer for executables.
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
from pathlib                import Path
from subprocess             import Popen				as Subprocess_Popen
from subprocess             import PIPE					as Subprocess_Pipe
from subprocess             import STDOUT				as Subprocess_StdOut

from Base.Exceptions        import CommonException, ExceptionBase
from Base.Logging           import ILogable, Logger


__api__ = [
	'ExecutableException',
	'CommandLineArgument',
	'ExecutableArgument',
	'NamedCommandLineArgument',
	'CommandArgument',        'ShortCommandArgument',         'LongCommandArgument',        'WindowsCommandArgument',
	'StringArgument',
	'StringListArgument',
	'PathArgument',
	'FlagArgument',           'ShortFlagArgument',            'LongFlagArgument',           'WindowsFlagArgument',
	'ValuedFlagArgument',     'ShortValuedFlagArgument',      'LongValuedFlagArgument',     'WindowsValuedFlagArgument',
	'ValuedFlagListArgument', 'ShortValuedFlagListArgument',  'LongValuedFlagListArgument', 'WindowsValuedFlagListArgument',
	'TupleArgument',          'ShortTupleArgument',           'LongTupleArgument',          'WindowsTupleArgument',
	'CommandLineArgumentList',
	'Environment',
	'Executable'
]
__all__ = __api__


class ExecutableException(ExceptionBase):
	"""This exception is raised by all executable abstraction classes."""
	def __init__(self, message=""):
		super().__init__(message)
		self.message = message

class DryRunException(ExecutableException):
	"""This exception is raised if a simulator runs in dry-run mode."""


class CommandLineArgument(type):
	"""Base class (and meta class) for all Arguments classes."""
	_value = None

	# def __new__(mcls, name, bases, nmspc):
	# 	print("CommandLineArgument.new: %s - %s" % (name, nmspc))
	# 	return super(CommandLineArgument, mcls).__new__(mcls, name, bases, nmspc)


class ExecutableArgument(CommandLineArgument):
	"""Represents the executable."""

	@property
	def Value(self):
		return self._value

	@Value.setter
	def Value(self, value):
		if isinstance(value, str):      self._value = value
		elif isinstance(value, Path):   self._value = str(value)
		else:                           raise ValueError("Parameter 'value' is not of type str or Path.")

	def __str__(self):
		if (self._value is None):       return ""
		else:                           return self._value

	def AsArgument(self):
		if (self._value is None):       raise ValueError("Executable argument is still empty.")
		else:                           return self._value


class NamedCommandLineArgument(CommandLineArgument):
	"""Base class for all command line arguments with a name."""
	_name = None  # set in sub-classes

	@property
	def Name(self):
		return self._name


class CommandArgument(NamedCommandLineArgument):
	"""Represents a command name.

	It is usually used to select a sub parser in a CLI argument parser or to hand
	over all following parameters to a separate tool. An example for a command is
	'checkout' in ``git.exe checkout``, which calls ``git-checkout.exe``.
	"""
	_pattern =    "{0}"

	@property
	def Value(self):
		return self._value

	@Value.setter
	def Value(self, value):
		if (value is None):           self._value = None
		elif isinstance(value, bool): self._value = value
		else:                         raise ValueError("Parameter 'value' is not of type bool.")

	def __str__(self):
		if (self._value is None):      return ""
		elif self._value:              return self._pattern.format(self._name)
		else:                          return ""

	def AsArgument(self):
		if (self._value is None):      return None
		elif self._value:              return self._pattern.format(self._name)
		else:                          return None

class ShortCommandArgument(CommandArgument):
	"""Represents a command name with a single dash."""
	_pattern = "-{0}"

class LongCommandArgument(CommandArgument):
	"""Represents a command name with a double dash."""
	_pattern = "--{0}"

class WindowsCommandArgument(CommandArgument):
	"""Represents a command name with a single slash."""
	_pattern = "/{0}"


class StringArgument(CommandLineArgument):
	"""Represents a simple string argument."""
	_pattern =  "{0}"

	@property
	def Value(self):
		return self._value

	@Value.setter
	def Value(self, value):
		if (value is None):            self._value = None
		elif isinstance(value, str):  self._value = value
		else:
			try:                        self._value = str(value)
			except Exception as ex:      raise ValueError("Parameter 'value' cannot be converted to type str.") from ex

	def __str__(self):
		if (self._value is None):      return ""
		elif self._value:              return self._pattern.format(self._value)
		else:                          return ""

	def AsArgument(self):
		if (self._value is None):      return None
		elif self._value:              return self._pattern.format(self._value)
		else:                          return None

class StringListArgument(CommandLineArgument):
	"""Represents a list of string arguments."""
	_pattern =  "{0}"

	@property
	def Value(self):
		return self._value

	@Value.setter
	def Value(self, value):
		if (value is None):           self._value = None
		elif isinstance(value, (tuple, list)):
			self._value = []
			try:
				for item in value:        self._value.append(str(item))
			except TypeError as ex:     raise ValueError("Item '{0}' in parameter 'value' cannot be converted to type str.".format(item)) from ex
		else:                         raise ValueError("Parameter 'value' is no list or tuple.")

	def __str__(self):
		if (self._value is None):     return ""
		elif self._value:             return " ".join([self._pattern.format(item) for item in self._value])
		else:                         return ""

	def AsArgument(self):
		if (self._value is None):      return None
		elif self._value:              return [self._pattern.format(item) for item in self._value]
		else:                          return None

class PathArgument(CommandLineArgument):
	"""Represents a path argument.

	The output format can be forced to the POSIX format with :py:data:`_PosixFormat`.
	"""
	_PosixFormat = False

	@property
	def Value(self):
		return self._value

	@Value.setter
	def Value(self, value):
		if (value is None):              self._value = None
		elif isinstance(value, Path):    self._value = value
		else:                            raise ValueError("Parameter 'value' is not of type Path.")

	def __str__(self):
		if (self._value is None):        return ""
		elif (self._PosixFormat):        return "\"" + self._value.as_posix() + "\""
		else:                            return "\"" + str(self._value) + "\""

	def AsArgument(self):
		if (self._value is None):        return None
		elif (self._PosixFormat):        return self._value.as_posix()
		else:                            return str(self._value)


class FlagArgument(NamedCommandLineArgument):
	"""Base class for all FlagArgument classes, which represents a simple flag argument.

	A simple flag is a single boolean value (absent/present or off/on) with no data.
	"""
	_pattern =    "{0}"

	@property
	def Value(self):
		return self._value

	@Value.setter
	def Value(self, value):
		if (value is None):           self._value = None
		elif isinstance(value, bool): self._value = value
		else:                         raise ValueError("Parameter 'value' is not of type bool.")

	def __str__(self):
		if (self._value is None):     return ""
		elif self._value:             return self._pattern.format(self._name)
		else:                         return ""

	def AsArgument(self):
		if (self._value is None):     return None
		elif self._value:             return self._pattern.format(self._name)
		else:                         return None

class ShortFlagArgument(FlagArgument):
	"""Represents a flag argument with a single dash.

	Example: ``-optimize``
	"""
	_pattern = "-{0}"

class LongFlagArgument(FlagArgument):
	"""Represents a flag argument with a double dash.

	Example: ``--optimize``
	"""
	_pattern = "--{0}"

class WindowsFlagArgument(FlagArgument):
	"""Represents a flag argument with a single slash.

	Example: ``/optimize``
	"""
	_pattern = "/{0}"


class ValuedFlagArgument(NamedCommandLineArgument):
	"""Class and base class for all ValuedFlagArgument classes, which represents a flag argument with data.

	A valued flag is a flag name followed by a value. The default delimiter sign is equal (``=``). Name and
	value are passed as one arguments to the executable even if the delimiter sign is a whitespace character.

	Example: ``width=100``
	"""
	_pattern = "{0}={1}"

	@property
	def Value(self):
		return self._value

	@Value.setter
	def Value(self, value):
		if (value is None):           self._value = None
		elif isinstance(value, str):  self._value = value
		else:
			try:                        self._value = str(value)
			except Exception as ex:     raise ValueError("Parameter 'value' cannot be converted to type str.") from ex

	def __str__(self):
		if (self._value is None):     return ""
		elif self._value:             return self._pattern.format(self._name, self._value)
		else:                         return ""

	def AsArgument(self):
		if (self._value is None):     return None
		elif self._value:             return self._pattern.format(self._name, self._value)
		else:                         return None

class ShortValuedFlagArgument(ValuedFlagArgument):
	"""Represents a :py:class:`ValuedFlagArgument` with a single dash.

	Example: ``-optimizer=on``
	"""
	_pattern = "-{0}={1}"

class LongValuedFlagArgument(ValuedFlagArgument):
	"""Represents a :py:class:`ValuedFlagArgument` with a double dash.

	Example: ``--optimizer=on``
	"""
	_pattern = "--{0}={1}"

class WindowsValuedFlagArgument(ValuedFlagArgument):
	"""Represents a :py:class:`ValuedFlagArgument` with a single slash.

	Example: ``/optimizer:on``
	"""
	_pattern = "/{0}:{1}"


class ValuedFlagListArgument(NamedCommandLineArgument):
	"""Class and base class for all ValuedFlagListArgument classes, which represents a list of :py:class:`ValuedFlagArgument` instances.

	Each list item gets translated into a :py:class:`ValuedFlagArgument`, with the same flag name, but differing values. Each
	:py:class:`ValuedFlagArgument` is passed as a single argument to the executable, even if the delimiter sign is a whitespace
	character.

	Example: ``file=file1.txt file=file2.txt``
	"""
	_pattern = "{0}={1}"

	@property
	def Value(self):
		return self._value

	@Value.setter
	def Value(self, value):
		if (value is None):                    self._value = None
		elif isinstance(value, (tuple,list)):  self._value = value
		else:                                  raise ValueError("Parameter 'value' is not of type tuple or list.")

	def __str__(self):
		if (self._value is None):     return ""
		elif (len(self._value) > 0):  return " ".join([self._pattern.format(self._name, item) for item in self._value])
		else:                         return ""

	def AsArgument(self):
		if (self._value is None):     return None
		elif (len(self._value) > 0):  return [self._pattern.format(self._name, item) for item in self._value]
		else:                         return None

class ShortValuedFlagListArgument(ValuedFlagListArgument):
	"""Represents a :py:class:`ValuedFlagListArgument` with a single dash.

	Example: ``-file=file1.txt -file=file2.txt``
	"""
	_pattern = "-{0}={1}"

class LongValuedFlagListArgument(ValuedFlagListArgument):
	"""Represents a :py:class:`ValuedFlagListArgument` with a double dash.

	Example: ``--file=file1.txt --file=file2.txt``
	"""
	_pattern = "--{0}={1}"

class WindowsValuedFlagListArgument(ValuedFlagListArgument):
	"""Represents a :py:class:`ValuedFlagListArgument` with a single slash.

	Example: ``/file:file1.txt /file:file2.txt``
	"""
	_pattern = "/{0}:{1}"


class TupleArgument(NamedCommandLineArgument):
	"""Class and base class for all TupleArgument classes, which represents a switch with separate data.

	A tuple switch is a command line argument followed by a separate value. Name and value are passed as
	two arguments to the executable.

	Example: ``width 100``
	"""
	_switchPattern =  "{0}"
	_valuePattern =   "{0}"

	@property
	def Value(self):
		return self._value

	@Value.setter
	def Value(self, value):
		if (value is None):           self._value = None
		elif isinstance(value, str):  self._value = value
		else:
			try:                        self._value = str(value)
			except TypeError as ex:     raise ValueError("Parameter 'value' cannot be converted to type str.") from ex

	def __str__(self):
		if (self._value is None):     return ""
		elif self._value:             return self._switchPattern.format(self._name) + " \"" + self._valuePattern.format(self._value) + "\""
		else:                         return ""

	def AsArgument(self):
		if (self._value is None):     return None
		elif self._value:             return [self._switchPattern.format(self._name), self._valuePattern.format(self._value)]
		else:                         return None

class ShortTupleArgument(TupleArgument):
	"""Represents a :py:class:`TupleArgument` with a single dash in front of the switch name.

	Example: ``-file file1.txt``
	"""
	_switchPattern = "-{0}"

class LongTupleArgument(TupleArgument):
	"""Represents a :py:class:`TupleArgument` with a double dash in front of the switch name.

	Example: ``--file file1.txt``
	"""
	_switchPattern = "--{0}"

class WindowsTupleArgument(TupleArgument):
	"""Represents a :py:class:`TupleArgument` with a single slash in front of the switch name.

	Example: ``/file file1.txt``
	"""
	_switchPattern = "/{0}"


class CommandLineArgumentList(list):
	"""Represent a list of all available commands, flags and switch of an executable."""
	def __init__(self, *args):
		super().__init__()
		for arg in args:
			self.append(arg)

	def __getitem__(self, key):
		i = self.index(key)
		return super().__getitem__(i).Value

	def __setitem__(self, key, value):
		i = self.index(key)
		super().__getitem__(i).Value = value

	def __delitem__(self, key):
		i = self.index(key)
		super().__getitem__(i).Value = None

	def ToArgumentList(self):
		result = []
		for item in self:
			arg = item.AsArgument()
			if (arg is None):           pass
			elif isinstance(arg, str):  result.append(arg)
			elif isinstance(arg, list): result += arg
			else:                       raise TypeError()
		return result


class Environment:
	def __init__(self):
		self.Variables = {}


class Executable(ILogable):
	"""Represent an executable."""
	_POC_BOUNDARY = "====== POC BOUNDARY ======"

	def __init__(self, platform : str, dryrun : bool, executablePath : Path, environment : Environment = None, logger : Logger =None):
		super().__init__(logger)

		self._platform =    platform
		self._dryrun =      dryrun
		self._environment = environment #if (environment is not None) else Environment()
		self._process =     None

		if isinstance(executablePath, str):             executablePath = Path(executablePath)
		elif (not isinstance(executablePath, Path)):    raise ValueError("Parameter 'executablePath' is not of type str or Path.")
		if (not executablePath.exists()):
			if dryrun:  self.LogDryRun("File check for '{0!s}' failed. [SKIPPING]".format(executablePath))
			else:       raise CommonException("Executable '{0!s}' not found.".format(executablePath)) from FileNotFoundError(str(executablePath))

		# prepend the executable
		self._executablePath =    executablePath
		self._iterator =          None

	@property
	def Path(self):
		return self._executablePath

	def StartProcess(self, parameterList):
		# start child process
		# parameterList.insert(0, str(self._executablePath))
		if (not self._dryrun):
			if (self._environment is not None):
				envVariables = self._environment.Variables
			else:
				envVariables = None

			try:
				self._process = Subprocess_Popen(
					parameterList,
					stdin=Subprocess_Pipe,
					stdout=Subprocess_Pipe,
					stderr=Subprocess_StdOut,
					env=envVariables,
					universal_newlines=True,
					bufsize=256
				)
			except OSError as ex:
				raise CommonException("Error while accessing '{0!s}'.".format(self._executablePath)) from ex
		else:
			self.LogDryRun("Start process: {0}".format(" ".join(parameterList)))

	def Send(self, line, end="\n"):
		self._process.stdin.write(line + end)
		self._process.stdin.flush()

	def SendBoundary(self):
		self.Send("puts \"{0}\"".format(self._POC_BOUNDARY))

	def Terminate(self):
		self._process.terminate()

	def GetReader(self):
		if (not self._dryrun):
			try:
				for line in iter(self._process.stdout.readline, ""):
					yield line[:-1]
			except Exception as ex:
				raise ex
			# finally:
				# self._process.terminate()
		else:
			raise DryRunException()

	def ReadUntilBoundary(self, indent=0):
		__indent = "  " * indent
		if (self._iterator is None):
			self._iterator = iter(self.GetReader())

		for line in self._iterator:
			print(__indent + line)
			if (self._POC_BOUNDARY in line):
				break
		self.LogDebug("Quartus II is ready")
