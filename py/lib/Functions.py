# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
# Authors:				 		Patrick Lehmann
# 
# Python Executable:	Auxillary functions to exit a program and report an error message.
# 
# Description:
# ------------------------------------
#	TODO
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

class Exit(object):
	from sys import exit

	@classmethod
	def versionCheck(cls, version):
		from sys import version_info
		if (version_info < version):
			from colorama		import Fore, Back, Style, init
			init()
			print(Fore.RED + "ERROR:" + Fore.RESET + " Used Python interpreter is to old: %s" % version_info)
			print("Minimal required Python version is %s" % (".".join(version)))
			print(Fore.RESET + Back.RESET + Style.RESET_ALL)
			exit(1)
	
	@classmethod
	def printThisIsNoExecutableFile(cls, message):
		from colorama		import Fore, Back, Style, init
		init()
		print("=" * 80)
		print("{: ^80s}".format(message))
		print("=" * 80)
		print()
		print(Fore.RED + "ERROR:" + Fore.RESET + " This is not a executable file!")
		print(Fore.RESET + Back.RESET + Style.RESET_ALL)
		exit(1)
	
	@classmethod
	def printThisIsNoLibraryFile(cls, message):
		from colorama		import Fore, Back, Style, init
		init()
		print("=" * 80)
		print("{: ^80s}".format(message))
		print("=" * 80)
		print()
		print(Fore.RED + "ERROR:" + Fore.RESET + " This is not a library file!")
		print(Fore.RESET + Back.RESET + Style.RESET_ALL)
		exit(1)
	
	@classmethod
	def printException(cls, ex):
		from traceback	import print_tb
		from colorama		import Fore, Back, Style, init
		init()
		print(Fore.RED + "FATAL:" + Fore.RESET + " %s" % ex.__str__())
		print("-" * 80)
		print_tb(ex.__traceback__)
		print("-" * 80)
		print(Fore.RESET + Back.RESET + Style.RESET_ALL)
		exit(1)
	
	@classmethod
	def printNotImplementedException(cls, ex):
		from colorama import Fore, Back, Style, init
		init()
		print(Fore.RED + "ERROR:" + Fore.RESET + " %s" % ex.message)
		print(Fore.RESET + Back.RESET + Style.RESET_ALL)
		exit(1)
	
	@classmethod
	def printBaseException(cls, ex):
		from colorama import Fore, Back, Style, init
		init()
		print(Fore.RED + "ERROR:" + Fore.RESET + " %s" % ex.message)
		print(Fore.RESET + Back.RESET + Style.RESET_ALL)
		exit(1)
	
	@classmethod
	def printPlatformNotSupportedException(cls, ex):
		from colorama import Fore, Back, Style, init
		init()
		print(Fore.RED + "ERROR:" + Fore.RESET + " Unsupported platform '%s'" % ex.message)
		print(Fore.RESET + Back.RESET + Style.RESET_ALL)
		exit(1)
		
	@classmethod
	def printEnvironmentException(cls, ex):
		from colorama import Fore, Back, Style, init
		init()
		print(Fore.RED + "ERROR:" + Fore.RESET + " %s" % ex.message)
		print()
		print("Please run this script with it's provided wrapper or manually load the required environment before executing this script.")
		print(Fore.RESET + Back.RESET + Style.RESET_ALL)
		exit(1)
	
	@classmethod
	def printNotConfiguredException(cls, ex):
		from colorama import Fore, Back, Style, init
		init()
		print(Fore.RED + "ERROR:" + Fore.RESET + " %s" % ex.message)
		print()
		print("Please run " + Fore.YELLOW + "'poc.[sh/cmd] --configure'" + Fore.RESET + " in PoC root directory.")
		print(Fore.RESET + Back.RESET + Style.RESET_ALL)
		exit(1)
