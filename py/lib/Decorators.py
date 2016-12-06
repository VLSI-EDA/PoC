# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:            Patrick Lehmann
#											Thomas B. Preusser
#
# Python functions:    Auxillary functions to exit a program and report an error message.
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
import functools

from lib.SphinxExtensions import DocumentMemberAttribute


__api__ = [
	'MethodAlias',
	'ILazyLoadable',
	'LazyLoadTrigger',
	'CachedReadOnlyProperty'
]
__all__ = __api__


class MethodAlias:
	"""``MethodAlias`` creates a local method, which is an alias to another method
	local or inherited method.
	"""

	@DocumentMemberAttribute()
	def __init__(self, method):
		self.method = method

	@DocumentMemberAttribute()
	def __call__(self, func):
		return self.method


class ILazyLoadable:
	def __init__(self):
		self.__IsLoaded = False

	def _LazyLoadable_Load(self):
		self.__IsLoaded =  True

	@property
	def LazyLoadable_IsLoaded(self):
		return self.__IsLoaded


class LazyLoadTrigger:
	def __init__(self, func):
		self.func = func

	def __call__(self, inst, *args, **kwargs):
		if (inst.LazyLoadable_IsLoaded is False):
			inst._LazyLoadable_Load()
		return self.func(inst, *args, **kwargs)

	def __repr__(self):
		return self.func.__doc__


class CachedReadOnlyProperty:
	def __init__(self, func):
		self.func =    func
		self.__cache =  None

	def __call__(self, *args):
		if self.__cache is None:
			result = self.func(*args)
			self.__cache = result
		return self.__cache

	def __repr__(self):
		return self.func.__doc__

	def __get__(self, obj, _):
		functools.partial(self.__call__, obj)

# def property(function):
#   import sys
#   import builtins
#
# 	keys = 'fget', 'fset', 'fdel'
# 	func_locals = {'doc' : function.__doc__}
# 	def probe_func(frame, event, arg):
# 		if event == 'return':
# 			locals = frame.f_locals
# 			func_locals.update(dict((k, locals.get(k)) for k in keys))
# 			sys.settrace(None)
# 		return probe_func
# 	sys.settrace(probe_func)
# 	function()
# 	return builtins.property(**func_locals)
