#!/usr/bin/python3
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

from subprocess import check_output
from shutil import copyfile
from pathlib import Path

hook_root   = Path(check_output(['git', 'rev-parse', '--show-toplevel'], universal_newlines=True).strip()) / 'tools/git/hooks'
target_root = Path(check_output(['git', 'rev-parse', '--git-dir'], universal_newlines=True).strip()) / 'hooks'

runner = hook_root / 'run-hook.py'
hooks  = [ hook.stem for hook in hook_root.glob('*.d') if hook.is_dir() ]

for hook in hooks:
	print('Creating Hook "' + hook + '" ... ')
	link = target_root / hook
	if link.exists():
		# Just print a message that the hook is already taken
		if link.is_symlink() and link.resolve() == runner.resolve():
			print('already set')
		else:
			print('OCCUPIED - NOT set')
	else:
		# Try and report installation of PoC hook
		try:
			# prefered symlink
			link.symlink_to(runner)
			print('done')
		except OSError as e:
			if getattr(e, 'winerror', None) == 1314:
				try:
					# copy as a backup solution
					copyfile(runner, link)
				except OSError as e2:
					e = e2
			print(e)
