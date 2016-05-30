#!/usr/bin/python
# EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:               Thomas B. Preusser
#
# License:
# ==============================================================================
# Copyright 2007-2016 Technische Universitaet Dresden - Germany
#                     Chair for VLSI-Design, Diagnostics and Architecture
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================

import sys
import os
from subprocess import check_output

git_root  = check_output(['git', 'rev-parse', '--show-toplevel'], universal_newlines=True).strip()
hook_root = os.path.join(git_root, 'tools/git/hooks')
hooks = [ hook[:-2] for hook in os.listdir(hook_root) if (hook.endswith('.d') and os.path.isdir(os.path.join(hook_root, hook))) ]

runner			= os.path.join(hook_root, 'run-hook.py')
target_root	= os.path.join(git_root, '.git/hooks')
for hook in hooks:
	sys.stdout.write('Creating Hook "' + hook + '" ... ')
	try:
		os.symlink(runner, os.path.join(target_root, hook))
		print('done')
	except OSError as e:
		print(e)
