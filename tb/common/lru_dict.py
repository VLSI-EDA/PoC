# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:				 		Martin Zabel
#
# Python Module:		  LRU Dictionary used by various Cocotb Testbenches for LRU components
#
# Description:
# ------------------------------------
#	Provides an ordered dictionary with LRU policy.
#
#	The entries in this dictionary are ordered by the last addition or update
#	of key:value pairs. The maximum size of the dictionary can be specified
#	during object creation.
#
# License:
# ==============================================================================
# Copyright 2007-2016 Technische Universitaet Dresden - Germany
#											Chair of VLSI-Design, Diagnostics and Architecture
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

from collections import OrderedDict

class LeastRecentlyUsedDict(OrderedDict):
	"""
	The entries in this dictionary are ordered by the last addition or update
	of key:value pairs. The maximum size of the dictionary can be specified
	during object creation.

	Based on this StackOverflow answer: http://stackoverflow.com/a/2437645/5466118
	and the example on: https://docs.python.org/2/library/collections.html#ordereddict-examples-and-recipes
	"""

	def __init__(self, *args, **kwds):
		"""
		The optional keyword 'size_limit' specifies the maximum size of the
		dictionary.
		"""
		self._size_limit = kwds.pop("size_limit", None)
		OrderedDict.__init__(self, *args, **kwds)
		self._check_size_limit()

	def __setitem__(self, key, value):
		if key in self:
			del self[key]
		OrderedDict.__setitem__(self, key, value)
		self._check_size_limit()

	def _check_size_limit(self):
		if self._size_limit is not None:
			while len(self) > self._size_limit:
				self.popitem(last=False)

	@property
	def size_limit(self):
		"""Get the size limit."""
		return self._size_limit

	def moveLRU(self, key, value=None):
		"""
		Mark key as least-recently used.
		Does nothing, if key is not within dictionary.
		If no value is specified, then the current value of the key is used.
		"""
		if key in self:
			old = self.copy()
			if value is None:
				value = self[key]

			# build new list
			self.clear()
			self[key] = value
			for k, v in old.iteritems():
				if k == key: continue
				self[k] = v

#d = LeastRecentlyUsedDict(size_limit=5)
#for key in range(4,-1,-1): d[key]=1
#print "old=%s" % d
#d.markLRU(2)
#print "new=%s" % d
