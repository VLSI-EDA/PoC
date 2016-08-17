# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
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
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module Base.Executable")

# load dependencies
from pathlib                import Path
from subprocess              import Popen				as Subprocess_Popen
from subprocess              import PIPE					as Subprocess_Pipe
from subprocess              import STDOUT				as Subprocess_StdOut

from Base.Exceptions        import CommonException
from Base.Logging            import ILogable


class ExecutableException(BaseException):
	def __init__(self, message=""):
		super().__init__(message)
		self.message = message

class CommandLineArgument(type):
	_value = None

	# def __new__(mcls, name, bases, nmspc):
	# 	print("CommandLineArgument.new: %s - %s" % (name, nmspc))
	# 	return super(CommandLineArgument, mcls).__new__(mcls, name, bases, nmspc)

class ExecutableArgument(CommandLineArgument):
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
	_name = None  # set in sub-classes

	@property
	def Name(self):
		return self._name


class CommandArgument(NamedCommandLineArgument):
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

class ShortCommandArgument(CommandArgument):    _pattern = "-{0}"
class LongCommandArgument(CommandArgument):     _pattern = "--{0}"
class WindowsCommandArgument(CommandArgument):  _pattern = "/{0}"


class StringArgument(CommandLineArgument):
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

class ShortFlagArgument(FlagArgument):    _pattern = "-{0}"
class LongFlagArgument(FlagArgument):     _pattern = "--{0}"
class WindowsFlagArgument(FlagArgument):  _pattern = "/{0}"

class ValuedFlagArgument(NamedCommandLineArgument):
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

class ShortValuedFlagArgument(ValuedFlagArgument):  _pattern = "-{0}={1}"
class LongValuedFlagArgument(ValuedFlagArgument):   _pattern = "--{0}={1}"

class ValuedFlagListArgument(NamedCommandLineArgument):
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

class ShortValuedFlagListArgument(ValuedFlagListArgument):  _pattern = "-{0}={1}"
class LongValuedFlagListArgument(ValuedFlagListArgument):   _pattern = "--{0}={1}"

class TupleArgument(NamedCommandLineArgument):
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

class ShortTupleArgument(TupleArgument):    _switchPattern = "-{0}"
class LongTupleArgument(TupleArgument):     _switchPattern = "--{0}"

class CommandLineArgumentList(list):
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


class Executable(ILogable):
	_POC_BOUNDARY = "====== POC BOUNDARY ======"

	def __init__(self, platform, dryrun, executablePath, logger=None):
		super().__init__(logger)

		self._platform =  platform
		self._dryrun =    dryrun
		self._process =   None

		if isinstance(executablePath, str):             executablePath = Path(executablePath)
		elif (not isinstance(executablePath, Path)):    raise ValueError("Parameter 'executablePath' is not of type str or Path.")
		if (not executablePath.exists()):
			if dryrun:  self._LogDryRun("File check for '{0!s}' failed. [SKIPPING]".format(executablePath))
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
			try:
				self._process = Subprocess_Popen(parameterList, stdin=Subprocess_Pipe, stdout=Subprocess_Pipe, stderr=Subprocess_StdOut, universal_newlines=True, bufsize=256)
			except OSError as ex:
				raise CommonException("Error while accessing '{0!s}'.".format(self._executablePath)) from ex
		else:
			self._LogDryRun("Start process: {0}".format(" ".join(parameterList)))

	def Send(self, line, end="\n"):
		self._process.stdin.write(line + end)
		self._process.stdin.flush()

	def SendBoundary(self):
		self.Send("puts \"{0}\"".format(self._POC_BOUNDARY))

	def Terminate(self):
		self._process.terminate()

	def GetReader(self):
		try:
			for line in iter(self._process.stdout.readline, ""):
				yield line[:-1]
		except Exception as ex:
			raise ex
		# finally:
			# self._process.terminate()

	def ReadUntilBoundary(self, indent=0):
		__indent = "  " * indent
		if (self._iterator is None):
			self._iterator = iter(self.GetReader())

		for line in self._iterator:
			print(__indent + line)
			if (self._POC_BOUNDARY in line):
				break
		self._LogDebug("Quartus II is ready")
