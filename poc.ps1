# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
#	Authors:						Patrick Lehmann
# 
#	PowerShell Script:	Wrapper Script to execute <PoC-Root>/py/PoC.py
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
$PyWrapper_PoShScriptDir =	"py"
$PyWrapper_Script =					"PoC.py"
$PyWrapper_MinVersion =			"3.5.0"

# save parameters and current working directory
$PyWrapper_Parameters =	$args
$PyWrapper_ScriptDir =	$PSScriptRoot
$PyWrapper_WorkingDir =	Get-Location
$PoC_RootDir_AbsPath =	Convert-Path (Resolve-Path ($PSScriptRoot + "\."))

# invoke main wrapper
. ("$PoC_RootDir_AbsPath\$PyWrapper_PoShScriptDir\Wrapper.ps1")

# restore working directory if changed
Set-Location $PyWrapper_WorkingDir

# return exit status
exit $PoC_ExitCode
