# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:				 		Martin Zabel
#                     Patrick Lehmann
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

def log2ceil(arg):
	"""Calculates: ceil(ld(arg)) for integers."""
	if arg == 1: return 0

	tmp, log = 1, 0
	while arg > tmp:
		tmp = tmp * 2
		log = log + 1

	return log

def log2ceilnz(arg):
	"""Calculates: max(1, ceil(ld(arg))) for integers."""
	res = log2ceil(arg)
	if res == 0: return 1
	return res
