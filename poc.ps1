# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
#	PowerShell Script:	Wrapper Script to execute <PoC-Root>/py/Configuration.py
# 
#	Authors:						Patrick Lehmann
# 
# Description:
# ------------------------------------
#	This is a PowerShell wrapper script (executable) which:
#		- saves the current working directory as an environment variable
#		- delegates the call to <PoC-Root>/py/Wrapper.ps1
#		-
#
# License:
# ==============================================================================
# Copyright 2007-2014 Technische Universitaet Dresden - Germany
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
$PyWrapper_Script =					"Configuration.py"
$PyWrapper_MinVersion =			"3.4.0"

# save parameters and current working directory
$PyWrapper_Parameters =	$args
$PyWrapper_ScriptDir =	$PSScriptRoot
$PyWrapper_WorkingDir =	Get-Location
$PoC_RootDir_AbsPath =	Convert-Path (Resolve-Path ($PSScriptRoot + "\."))

# set default values
$PyWrapper_Debug =					$false
$PyWrapper_LoadEnv_ISE =		$false
$PyWrapper_LoadEnv_Vivado = $false

# search parameters for specific options like '-D' to enable batch script debug mode
foreach ($i in $PyWrapper_Parameters) {
	$PyWrapper_Debug =				$PyWrapper_Debug -or ($i -clike "-*D*")
}

# invoke main wrapper
. ("$PoC_RootDir_AbsPath\$PyWrapper_PoShScriptDir\Wrapper.ps1")

# restore working directory if changed
Set-Location $PyWrapper_WorkingDir

# return exit status
exit $PoC_ExitCode
