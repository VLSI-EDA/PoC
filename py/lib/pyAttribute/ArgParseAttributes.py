# EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# =============================================================================
#                 _   _   _        _ _           _
#  _ __  _   _   / \ | |_| |_ _ __(_) |__  _   _| |_ ___
# | '_ \| | | | / _ \| __| __| '__| | '_ \| | | | __/ _ \
# | |_) | |_| |/ ___ \ |_| |_| |  | | |_) | |_| | ||  __/
# | .__/ \__, /_/   \_\__|\__|_|  |_|_.__/ \__,_|\__\___|
# |_|    |___/
#
# =============================================================================
# Authors:						Patrick Lehmann
#
# Python module:	    pyAttributes for ArgParse
#
# License:
# ============================================================================
# Copyright 2007-2016 Patrick Lehmann - Dresden, Germany
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
# ============================================================================
#
# load dependencies
from argparse   import ArgumentParser
from .          import Attribute, AttributeHelperMixin


__api__ = [
	'CommandGroupAttribute',
	'DefaultAttribute',
	'CommandAttribute',
	'ArgumentAttribute',
	'SwitchArgumentAttribute',
	'CommonArgumentAttribute',
	'CommonSwitchArgumentAttribute',
	'ArgParseMixin'
]
__all__ = __api__


class CommandGroupAttribute(Attribute):
	__groupName = ""

	def __init__(self, groupName):
		super().__init__()
		self.__groupName = groupName

	@property
	def GroupName(self):
		return self.__groupName


class DefaultAttribute(Attribute):
	__handler = None

	def __call__(self, func):
		self.__handler = func
		return super().__call__(func)

	@property
	def Handler(self):
		return self.__handler


class CommandAttribute(Attribute):
	__command = ""
	__handler = None
	__kwargs =  None

	def __init__(self, command, **kwargs):
		super().__init__()
		self.__command =  command
		self.__kwargs =   kwargs

	def __call__(self, func):
		self.__handler =  func
		return super().__call__(func)

	@property
	def Command(self):
		return self.__command

	@property
	def Handler(self):
		return self.__handler

	@property
	def KWArgs(self):
		return self.__kwargs


class ArgumentAttribute(Attribute):
	__args =    None
	__kwargs =  None

	def __init__(self, *args, **kwargs):
		super().__init__()
		self.__args =   args
		self.__kwargs = kwargs

	@property
	def Args(self):
		return self.__args

	@property
	def KWArgs(self):
		return self.__kwargs


class SwitchArgumentAttribute(ArgumentAttribute):
	def __init__(self, *args, **kwargs):
		kwargs['action'] =  "store_const"
		kwargs['const'] =   True
		kwargs['default'] = False
		super().__init__(*args, **kwargs)


class CommonArgumentAttribute(ArgumentAttribute):
	pass


class CommonSwitchArgumentAttribute(SwitchArgumentAttribute):
	pass


class ArgParseMixin(AttributeHelperMixin):
	__mainParser =  None
	__subParser =   None
	__subParsers =  {}

	def __init__(self, **kwargs):
		super().__init__()

		# create a commandline argument parser
		self.__mainParser = ArgumentParser(**kwargs)
		self.__subParser = self.__mainParser.add_subparsers(help='sub-command help')

		for _, func in CommonArgumentAttribute.GetMethods(self):
			for comAttribute in CommonArgumentAttribute.GetAttributes(func):
				self.__mainParser.add_argument(*(comAttribute.Args), **(comAttribute.KWArgs))

		for _, func in CommonSwitchArgumentAttribute.GetMethods(self):
			for comAttribute in CommonSwitchArgumentAttribute.GetAttributes(func):
				self.__mainParser.add_argument(*(comAttribute.Args), **(comAttribute.KWArgs))

		for _, func in self.GetMethods():
			defAttributes = DefaultAttribute.GetAttributes(func)
			if (len(defAttributes) != 0):
				defAttribute = defAttributes[0]
				self.__mainParser.set_defaults(func=defAttribute.Handler)
				continue

			cmdAttributes = CommandAttribute.GetAttributes(func)
			if (len(cmdAttributes) != 0):
				cmdAttribute = cmdAttributes[0]
				subParser = self.__subParser.add_parser(cmdAttribute.Command, **(cmdAttribute.KWArgs))
				subParser.set_defaults(func=cmdAttribute.Handler)

				for argAttribute in ArgumentAttribute.GetAttributes(func):
					subParser.add_argument(*(argAttribute.Args), **(argAttribute.KWArgs))

				self.__subParsers[cmdAttribute.Command] = subParser
				continue

	def Run(self):
		try:
			from argcomplete  import autocomplete
			autocomplete(self.__mainParser)
		except ImportError:
			pass

		# parse command line options and process split arguments in callback functions
		args = self.__mainParser.parse_args()
		# because func is a function (unbound to an object), it MUST be called with self as a first parameter
		args.func(self, args)

	@property
	def MainParser(self):
		return self.__mainParser

	@property
	def SubParsers(self):
		return self.__subParsers
