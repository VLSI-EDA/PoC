# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#
# Python Module:
#
# Description:
# ------------------------------------
#   - TODO
#
# License:
# ==============================================================================
# Copyright 2007-2016 Patrick Lehmann - Dresden, Germany
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
from lib.SphinxExtensions   import DocumentMemberAttribute


def skip_member_handler(app, what, name, obj, skip, options):
	# try:
		# print("skip_member_handler: ", obj)
	# except:
		# print("skip_member_handler: ERROR")

	try:
		attributes = DocumentMemberAttribute.GetAttributes(obj)
		if (len(attributes) > 0):
			# print("*#"*20)
			# try:
				# print("skip_member_handler: ", obj)
			# except:
				# print("skip_member_handler: ERROR")

			return not attributes[0].value
	except:
		pass
	return None

def setup(app):
	app.connect('autodoc-skip-member', skip_member_handler)
