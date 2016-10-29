#! /usr/bin/env bash
# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
#	Authors:				 	Patrick Lehmann
#                   Martin Zabel
#
#	Bash Script:			Wrapper Script to execute <PoC-Root>/py/PoC.py
#
# Description:
# ------------------------------------
#	This is a bash wrapper script (executable) which:
#		- saves the current working directory as an environment variable
#		- delegates the call to <PoC-Root>/py/wrapper.sh
#
# License:
# ==============================================================================
# Copyright 2007-2016 Technische Universitaet Dresden - Germany
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

# configure wrapper here
PyWrapper_BashScriptDir="py/Wrapper"
PyWrapper_Script=PoC.py
PyWrapper_MinVersion=3.5.0

PyWrapper_RelPath="."
PyWrapper_Solution=""

# work around for Darwin (Mac OS)
READLINK=readlink; if [[ $(uname) == "Darwin" ]]; then READLINK=greadlink; fi

# resolve script directory
# solution is from http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do													# resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$($READLINK "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"			# if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# save parameters and script directory
PyWrapper_Parameters=$@
PyWrapper_WorkingDir=$(pwd)
PoC_RootDir_RelPath="$SCRIPT_DIR/."
PoC_RootDir=$(cd "$PoC_RootDir_RelPath/$PyWrapper_RelPath" && pwd)

# invoke main wrapper
source "$PoC_RootDir/$PyWrapper_BashScriptDir/wrapper.sh"

# return exit status
exit $PoC_ExitCode
