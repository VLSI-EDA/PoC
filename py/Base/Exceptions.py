# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#
# Python Module:    This module contains exception base classes and common exceptions for PoC.
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
from lib.SphinxExtensions import DocumentMemberAttribute


__api__ = [
	'ExceptionBase',
	'EnvironmentException',
	'PlatformNotSupportedException',
	'NotConfiguredException',
	'SkipableException',
	'CommonException',
	'SkipableCommonException'
]
__all__ = __api__


class ExceptionBase(Exception):
	"""Base exception derived from :py:exc:`Exception` for all
	custom exceptions in PoC.
	"""
	@DocumentMemberAttribute()
	def __init__(self, message=""):
		"""Exception initializer

		:type  message:   str
		:param message:   The exception message.
		"""
		super().__init__()
		self.message = message

	@DocumentMemberAttribute()
	def __str__(self):
		"""Returns the exception's message text."""
		return self.message

	@DocumentMemberAttribute(False)
	def with_traceback(self, tb):
		super().with_traceback(tb)

	# @DocumentMemberAttribute(False)
	# @MethodAlias(Exception.with_traceback)
	# def with_traceback(self): pass

class EnvironmentException(ExceptionBase):
	"""``EnvironmentException`` is raised when an expected environment variable is
	missing for PoC.
	"""

class PlatformNotSupportedException(ExceptionBase):
	"""``PlatformNotSupportedException`` is raise if the platform is not supported
	by PoC, or the selected tool flow is not supported on the host system by PoC.
	"""

class NotConfiguredException(ExceptionBase):
	"""``NotConfiguredException`` is raise if PoC or the requested tool chain
	setting is not configured in PoC.
	"""

class SkipableException(ExceptionBase):
	"""Base class for all skipable exceptions."""

class CommonException(ExceptionBase):
	pass

class SkipableCommonException(CommonException, SkipableException):
	"""``SkipableCommonException`` is a :py:exc:`CommonException`, which can be
	skipped.
	"""
