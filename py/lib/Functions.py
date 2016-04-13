# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
# Authors:						Patrick Lehmann
# 
# Python functions:		Auxillary functions to exit a program and report an error message.
# 
# Description:
# ------------------------------------
#		TODO:
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

from functools	import reduce
from operator		import or_
from sys				import version_info

from lib.ConfigParser import ExtendedSectionProxy


def merge(*dicts):
	return {k : reduce(lambda d,x: x.get(k, d), dicts, None) for k in reduce(or_, map(lambda x: x.keys(), dicts), set()) }

def merge_with(f, *dicts):
	return {k : reduce(lambda x: f(*x) if (len(x) > 1) else x[0])([ d[k] for d in dicts if k in d ]) for k in reduce(or_, map(lambda x: x.keys(), dicts), set()) }


class Init:
	@classmethod
	def init(cls):
		from colorama import init
		init()

	from colorama import Fore as Foreground
	Foreground = {
		"RED":			Foreground.LIGHTRED_EX,
		"GREEN":		Foreground.LIGHTGREEN_EX,
		"YELLOW":		Foreground.LIGHTYELLOW_EX,
		"MAGENTA":	Foreground.LIGHTMAGENTA_EX,
		"BLUE":			Foreground.LIGHTBLUE_EX,
		"CYAN":			Foreground.LIGHTCYAN_EX,
		"RESET":		Foreground.RESET,

		"HEADLINE":	Foreground.LIGHTMAGENTA_EX,
		"ERROR":		Foreground.LIGHTRED_EX,
		"WARNING":	Foreground.LIGHTYELLOW_EX
	}


class Exit:
	@classmethod
	def exit(cls, returnCode=0):
		from colorama		import Fore as Foreground, Back as Background, Style
		print(Foreground.RESET + Background.RESET + Style.RESET_ALL, end="")
		exit(returnCode)

	@classmethod
	def versionCheck(cls, version):
		if (version_info < version):
			Init.init()
			print("{RED}ERROR:{RESET} Used Python interpreter is to old ({version}).".format(version=version_info, **Init.Foreground))
			print("  Minimal required Python version is {version}".format(version=".".join(version)))
			cls.exit(1)

	@classmethod
	def printThisIsNoExecutableFile(cls, message):
		Init.init()
		print("=" * 80)
		print("{: ^80s}".format(message))
		print("=" * 80)
		print()
		print("{RED}ERROR:{RESET} This is not a executable file!".format(**Init.Foreground))
		cls.exit(1)

	@classmethod
	def printThisIsNoLibraryFile(cls, message):
		Init.init()
		print("=" * 80)
		print("{: ^80s}".format(message))
		print("=" * 80)
		print()
		print("{RED}ERROR:{RESET} This is not a library file!".format(**Init.Foreground))
		cls.exit(1)

	@classmethod
	def printException(cls, ex):
		from traceback	import print_tb, walk_tb
		Init.init()
		print("{RED}FATAL: An unknown or unhandled exception reached the topmost exception handler!{RESET}".format(message=ex.__str__(), **Init.Foreground))
		print("{YELLOW}  Exception type:{RESET}    {type}".format(type=ex.__class__.__name__, **Init.Foreground))
		print("{YELLOW}  Exception message:{RESET} {message}".format(message=ex.__str__(), **Init.Foreground))
		frame,sourceLine = [x for x in walk_tb(ex.__traceback__)][-1]
		filename = frame.f_code.co_filename
		funcName = frame.f_code.co_name
		print("{YELLOW}  Caused by:{RESET}         {function} in file '{filename}' at line {line}".format(function=funcName, filename=filename, line=sourceLine, **Init.Foreground))
		print("-" * 80)
		print_tb(ex.__traceback__)
		print("-" * 80)
		Exit.exit(1)

	@classmethod
	def printNotImplementedError(cls, ex):
		from traceback	import walk_tb
		Init.init()
		frame, _ = [x for x in walk_tb(ex.__traceback__)][-1]
		filename = frame.f_code.co_filename
		funcName = frame.f_code.co_name
		print("{RED}Not implemented:{RESET} {function} in file '{filename}': {message}".format(function=funcName, filename=filename, message=str(ex), **Init.Foreground))
		Exit.exit(1)

	@classmethod
	def printExceptionbase(cls, ex):
		Init.init()
		print("{RED}ERROR:{RESET} {message}".format(message=ex.message, **Init.Foreground))
		Exit.exit(1)

	@classmethod
	def printPlatformNotSupportedException(cls, ex):
		Init.init()
		print("{RED}ERROR:{RESET} Unsupported platform '{message}'".format(message=ex.message, **Init.Foreground))
		Exit.exit(1)

	@classmethod
	def printEnvironmentException(cls, ex):
		Init.init()
		print("{RED}ERROR:{RESET} {message}".format(message=ex.message, **Init.Foreground))
		print("  Please run this script with it's provided wrapper or manually load the required environment before executing this script.")
		Exit.exit(1)

	@classmethod
	def printNotConfiguredException(cls, ex):
		Init.init()
		print("{RED}ERROR:{RESET} {message}".format(message=ex.message, **Init.Foreground))
		print("  Please run {YELLOW}'poc.[sh/cmd] configure'{RESET} in PoC root directory.".format(**Init.Foreground))
		Exit.exit(1)

