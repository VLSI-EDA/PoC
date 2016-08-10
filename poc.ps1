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
#
# Change this, if PoC solutions and PoC projects are used
$PoC_RelPath =					"."		# relative path to PoC root directory
$PoC_Solution =					""		# solution name

# save parameters and current working directory
$PyWrapper_WorkingDir =	Get-Location

# Configure PoC environment here
$PoC_PythonDir =				"py"
$PoC_ScriptPy =					"$PoC_PythonDir\PoC.py"
$PoC_WrapperDir =				"py\Wrapper"
$PoC_Module =						"PoC"
$PoC_Wrapper =					"Wrapper.ps1"

# load PoC module
$PoCRootDir =						Convert-Path (Resolve-Path ($PSScriptRoot + "\" + $PoC_RelPath))
Import-Module "$PoCRootDir\$PoC_WrapperDir\$PoC_Module.psm1" -ArgumentList @($PoCRootDir)

# scan script parameters and mark environment to be loaded
$Debug, $PyWrapper_LoadEnv = Get-PoCEnvironmentArray $args
# execute vendor and tool pre-hook files if present
Invoke-OpenEnvironment $PyWrapper_LoadEnv | Out-Null

# print debug messages
if ($Debug -eq $true ) {
	Write-Host "This is the PoC-Library script wrapper operating in debug mode." -ForegroundColor Yellow
	Write-Host ""
	Write-Host "Directories:" -ForegroundColor Yellow
	Write-Host "  PoC Root        $PoC_RootDir" -ForegroundColor Yellow
	Write-Host "  Working         $PyWrapper_WorkingDir" -ForegroundColor Yellow
	Write-Host "Script:" -ForegroundColor Yellow
	Write-Host "  Filename        $PoC_ScriptPy" -ForegroundColor Yellow
	Write-Host "  Solution        $PoC_Solution" -ForegroundColor Yellow
	Write-Host "  Parameters      $args" -ForegroundColor Yellow
	Write-Host "Load Environment:" -ForegroundColor Yellow
	Write-Host "  Lattice Diamond $($PyWrapper_LoadEnv['Lattice']['Tools']['Diamond']['Load'])"	-ForegroundColor Yellow
	Write-Host "  Xilinx ISE      $($PyWrapper_LoadEnv['Xilinx']['Tools']['ISE']['Load'])"			-ForegroundColor Yellow
	Write-Host "  Xilinx Vivado   $($PyWrapper_LoadEnv['Xilinx']['Tools']['Vivado']['Load'])"		-ForegroundColor Yellow
	Write-Host ""
}

# execute script with appropriate Python interpreter and all given parameters
if ($PoC_Solution -eq "")
{	$Command = "$Python_Interpreter $Python_Parameters $PoC_RootDir\$PoC_ScriptPy $args"													}
else
{	$Command = "$Python_Interpreter $Python_Parameters $PoC_RootDir\$PoC_ScriptPy --sln=$PoC_Solution $args"			}

# execute script with appropriate Python interpreter and all given parameters
if ($Debug -eq $true)	{	Write-Host "launching: '$Command'" -ForegroundColor Yellow	}
Invoke-Expression $Command
$PyWrapper_ExitCode = $LastExitCode


Invoke-CloseEnvironment $PyWrapper_LoadEnv | Out-Null

# unload PowerShell module
Remove-Module $PoC_Module
# clean up environment variables
$env:PoCRootDirectory =			$null

# restore working directory if changed
Set-Location $PyWrapper_WorkingDir

# return exit status
exit $PyWrapper_ExitCode
