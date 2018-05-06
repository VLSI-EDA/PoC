# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:            Patrick Lehmann
#											Thomas B. Preusser
#
# Python functions:   Auxillary functions to exit a program and report an error message.
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
from functools    import reduce
from operator     import or_
from sys          import version_info


__api__ = [
	'merge', 'merge_with',
	'CallByRefParam',
	'Init',
	'Exit'
]
__all__ = __api__


def merge(*dicts):
	"""Merge 2 or more dictionaries."""
	return {k : reduce(lambda d,x: x.get(k, d), dicts, None) for k in reduce(or_, map(lambda x: x.keys(), dicts), set()) }

def merge_with(f, *dicts):
	"""Merge 2 or more dictionaries. Apply function f to each element during merge."""
	return {k : reduce(lambda x: f(*x) if (len(x) > 1) else x[0])([ d[k] for d in dicts if k in d ]) for k in reduce(or_, map(lambda x: x.keys(), dicts), set()) }


class CallByRefParam:
	"""Implements a "call by reference" parameter.

	.. seealso::

	   :py:class:`CallByRefBoolParam`
	     A special "call by reference" implementation for boolean reference types.
	   :py:class:`CallByRefIntParam`
	     A special "call by reference" implementation for integer reference types.
	"""
	def __init__(self, value=None):
		self.value = value

	def __ilshift__(self, other):
		self.value = other
		return self

	def __eq__(self, other):  return self.value == other
	def __ne__(self, other):  return self.value != other
	def __repr__(self):       return repr(self.value)
	def __str__(self):        return str(self.value)


class CallByRefBoolParam(CallByRefParam):
	"""A special "call by reference" implementation for boolean reference types."""
	# unary operators
	def __neg__(self):         return not self.value

	# binary operators - logical
	def __and__(self, other):  return self.value and other
	def __or__(self, other):   return self.value or  other

	# binary inplace operators
	def __iand__(self, other):
		self.value = self.value and other
		return self
	def __ior__(self, other):
		self.value = self.value or other
		return self

	# type conversion operators
	def __bool__(self): return self.value
	def __int__(self):  return int(self.value)

class CallByRefIntParam(CallByRefParam):
	"""A special "call by reference" implementation for integer reference types."""

	# unary operators
	def __neg__(self):            return not self.value

	# binary operators - arithmetic
	def __add__(self, other):     return self.value +  other
	def __sub__(self, other):     return self.value -  other
	def __truediv__(self, other): return self.value /  other
	def __mul__(self, other):     return self.value *  other
	def __mod__(self, other):     return self.value %  other
	def __pow__(self, other):     return self.value ** other

	# binary operators - comparison
	def __eq__(self, other):  return self.value == other
	def __ne__(self, other):  return self.value != other
	def __lt__(self, other):  return self.value <  other
	def __le__(self, other):  return self.value <= other
	def __gt__(self, other):  return self.value >  other
	def __ge__(self, other):  return self.value >= other

	# type conversion operators
	def __bool__(self):       return bool(self.value)
	def __int__(self):        return self.value


class Init:
	@classmethod
	def init(cls):
		from colorama import init, Back as Background
		init()#strip=False)
		# print(Background.BLACK, end="")

	from colorama import Fore as Foreground
	Foreground = {
		"RED":          Foreground.LIGHTRED_EX,
		"DARK_RED":		  Foreground.RED,
		"GREEN":        Foreground.LIGHTGREEN_EX,
		"DARK_GREEN":   Foreground.GREEN,
		"YELLOW":       Foreground.LIGHTYELLOW_EX,
		"DARK_YELLOW":  Foreground.YELLOW,
		"MAGENTA":      Foreground.LIGHTMAGENTA_EX,
		"BLUE":         Foreground.LIGHTBLUE_EX,
		"CYAN":         Foreground.LIGHTCYAN_EX,
		"DARK_CYAN":    Foreground.CYAN,
		"GRAY":         Foreground.WHITE,
		"DARK_GRAY":    Foreground.LIGHTBLACK_EX,
		"WHITE":        Foreground.LIGHTWHITE_EX,
		"NOCOLOR":      Foreground.RESET,

		"HEADLINE":     Foreground.LIGHTMAGENTA_EX,
		"ERROR":        Foreground.LIGHTRED_EX,
		"WARNING":      Foreground.LIGHTYELLOW_EX
	}

class Exit:
	@classmethod
	def exit(cls, returnCode=0):
		from colorama    import Fore as Foreground, Back as Background, Style
		print(Foreground.RESET + Background.RESET + Style.RESET_ALL, end="")
		exit(returnCode)

	@classmethod
	def versionCheck(cls, version):
		if (version_info < version):
			Init.init()
			print("{RED}ERROR:{NOCOLOR} Used Python interpreter is to old ({version}).".format(version=version_info, **Init.Foreground))
			print("  Minimal required Python version is {version}".format(version=".".join(version)))
			cls.exit(1)

	@classmethod
	def printException(cls, ex):
		from traceback  import print_tb, walk_tb
		Init.init()
		print("{RED}FATAL: An unknown or unhandled exception reached the topmost exception handler!{NOCOLOR}".format(**Init.Foreground))
		print("{YELLOW}  Exception type:{NOCOLOR}      {typename}".format(typename=ex.__class__.__name__, **Init.Foreground))
		print("{YELLOW}  Exception message:{NOCOLOR}   {message!s}".format(message=ex, **Init.Foreground))
		frame,sourceLine = [x for x in walk_tb(ex.__traceback__)][-1]
		filename = frame.f_code.co_filename
		funcName = frame.f_code.co_name
		print("{YELLOW}  Caused in:{NOCOLOR}           {function} in file '{filename}' at line {line}".format(function=funcName, filename=filename, line=sourceLine, **Init.Foreground))
		if (ex.__cause__ is not None):
			print("{DARK_YELLOW}    Caused by type:{NOCOLOR}    {typename}".format(typename=ex.__cause__.__class__.__name__, **Init.Foreground))
			print("{DARK_YELLOW}    Caused by message:{NOCOLOR} {message!s}".format(message=ex.__cause__, **Init.Foreground))
		print(("{RED}" + ("-" * 80) + "{NOCOLOR}").format(**Init.Foreground))
		print_tb(ex.__traceback__)
		print(("{RED}" + ("-" * 80) + "{NOCOLOR}").format(**Init.Foreground))
		print(("{RED}Please report this bug at GitHub: https://github.com/VLSI-EDA/PoC/issues{NOCOLOR}").format(**Init.Foreground))
		print(("{RED}" + ("-" * 80) + "{NOCOLOR}").format(**Init.Foreground))
		Exit.exit(1)

	@classmethod
	def printNotImplementedError(cls, ex):
		from traceback  import walk_tb
		Init.init()
		frame, _ = [x for x in walk_tb(ex.__traceback__)][-1]
		filename = frame.f_code.co_filename
		funcName = frame.f_code.co_name
		print("{RED}NOT IMPLEMENTED:{NOCOLOR} {function} in file '{filename}': {message!s}".format(function=funcName, filename=filename, message=ex, **Init.Foreground))
		print(("{RED}" + ("-" * 80) + "{NOCOLOR}").format(**Init.Foreground))
		print(("{RED}Please report this bug at GitHub: https://github.com/VLSI-EDA/PoC/issues{NOCOLOR}").format(**Init.Foreground))
		print(("{RED}" + ("-" * 80) + "{NOCOLOR}").format(**Init.Foreground))
		Exit.exit(1)

	@classmethod
	def printExceptionBase(cls, ex):
		Init.init()
		print("{RED}FATAL: A known but unhandled exception reached the topmost exception handler!{NOCOLOR}".format(**Init.Foreground))
		print("{RED}ERROR:{NOCOLOR} {message}".format(message=ex.message, **Init.Foreground))
		print(("{RED}" + ("-" * 80) + "{NOCOLOR}").format(**Init.Foreground))
		print(("{RED}Please report this bug at GitHub: https://github.com/VLSI-EDA/PoC/issues{NOCOLOR}").format(**Init.Foreground))
		print(("{RED}" + ("-" * 80) + "{NOCOLOR}").format(**Init.Foreground))
		Exit.exit(1)

	@classmethod
	def printPlatformNotSupportedException(cls, ex):
		Init.init()
		print("{RED}ERROR:{NOCOLOR} Unsupported platform '{message}'".format(message=ex.message, **Init.Foreground))
		Exit.exit(1)

	@classmethod
	def printEnvironmentException(cls, ex):
		Init.init()
		print("{RED}ERROR:{NOCOLOR} {message}".format(message=ex.message, **Init.Foreground))
		print("  Please run this script with it's provided wrapper ('poc.[sh/ps1]') or manually load the required environment before executing this script.")
		Exit.exit(1)

	@classmethod
	def printNotConfiguredException(cls, ex):
		Init.init()
		print("{RED}ERROR:{NOCOLOR} {message}".format(message=ex.message, **Init.Foreground))
		print("  Please run {YELLOW}'poc.[sh/ps1] configure'{NOCOLOR} in PoC's root directory.".format(**Init.Foreground))
		Exit.exit(1)
