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
# Python package:	    pyAttribute Implementation
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
__api__ = [
	'Attribute',
	'AttributeHelperMixin'
]
__all__ = __api__

# TODO: implement class, method, function attributes
# TODO: implement unique attributes
# TODO: add an attacheHelper methods option
# TODO: implement a static HasAttribute method

class Attribute:
	__AttributesMemberName__ = "__pyattr__"
	_debug = False

	def __call__(self, func):
		self._AppendAttribute(func, self)
		return func

	@staticmethod
	def _AppendAttribute(func, attribute):
		# inherit attributes and append myself or create a new attributes list
		if (Attribute.__AttributesMemberName__ in func.__dict__):
			func.__dict__[Attribute.__AttributesMemberName__].append(attribute)
		else:
			func.__setattr__(Attribute.__AttributesMemberName__, [attribute])

	def __str__(self):
		return self.__name__

	@classmethod
	def GetMethods(cls, cl):
		methods = {}
		for funcname, func in cl.__class__.__dict__.items():
			if hasattr(func, '__dict__'):
				if (Attribute.__AttributesMemberName__ in func.__dict__):
					attributes = func.__dict__[Attribute.__AttributesMemberName__]
					if isinstance(attributes, list):
						for attribute in attributes:
							if isinstance(attribute, cls):
								methods[funcname] = func
		return methods.items()

	@classmethod
	def GetAttributes(cls, method):
		if (Attribute.__AttributesMemberName__ in method.__dict__):
			attributes = method.__dict__[Attribute.__AttributesMemberName__]
			if isinstance(attributes, list):
				return [attribute for attribute in attributes if isinstance(attribute, cls)]
		return list()


class AttributeHelperMixin:
	def GetMethods(self):
		return {
				funcname: func
				for funcname, func in self.__class__.__dict__.items()
				if hasattr(func, '__dict__')
			}.items()

	@staticmethod
	def HasAttribute(method): # TODO: add a tuple based type filer
		if (Attribute.__AttributesMemberName__ in method.__dict__):
			attributeList = method.__dict__[Attribute.__AttributesMemberName__]
			return (isinstance(attributeList, list) and (len(attributeList) != 0))
		else:
			return False

	@staticmethod
	def GetAttributes(method): # TODO: add a tuple based type filer
		if (Attribute.__AttributesMemberName__ in method.__dict__):
			attributeList = method.__dict__[Attribute.__AttributesMemberName__]
			if isinstance(attributeList, list):
				return attributeList
		return list()
