# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
#	Authors:						Patrick Lehmann
#
#	PowerShell Script:	Wrapper Script to execute <PoC-Root>/lib/pyIPCMI/pyIPCMI.py
#
# Description:
# ------------------------------------
#	This is a bash wrapper script (executable) which:
#		- saves the current working directory as an environment variable
#		- delegates the call to <PoC-Root>/lib/pyIPCMI/Wrapper/wrapper.sh
#
# License:
# ==============================================================================
# Copyright 2017-2018 Patrick Lehmann - Bötzingen, Germany
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
#
# Change this, if pyIPCMI solutions and pyIPCMI projects are used
$Library_RelPath =      "."   # relative path to PoC root directory
$Library =              "PoC" # library name
$Solution =             ""    # solution name
$Project =              ""    # project name

# Configure pyIPCMI environment here
$pyIPCMI_Dir =          "lib\pyIPCMI"
$pyIPCMI_PSModule =     "pyIPCMI"


# save parameters and current working directory
$Wrapper_WorkingDirectory = Get-Location
$Library_RootDirectory =    Convert-Path (Resolve-Path ($PSScriptRoot + "\" + $Library_RelPath))

# load pyIPCMI module
Import-Module "$Library_RootDirectory\$pyIPCMI_Dir\$pyIPCMI_PSModule.psm1" -ArgumentList @(
	$Library_RootDirectory,
	$Library,
	$pyIPCMI_Dir,
	$pyIPCMI_PSModule,
	$Solution
)

# scan script parameters and mark environment to be loaded
$Debug, $PyWrapper_LoadEnv = Get-PyIPCMIEnvironmentArray $args
# execute vendor and tool pre-hook files if present
Invoke-OpenEnvironment $PyWrapper_LoadEnv | Out-Null

# print debug messages
if ($Debug -eq $true ) {
	Write-Host "This is the PoC-Library script wrapper operating in debug mode." -ForegroundColor Yellow
	Write-Host ""
	Write-Host "Directories:" -ForegroundColor Yellow
	Write-Host "  Library Root    $Library_RootDirectory" -ForegroundColor Yellow
	Write-Host "  pyIPCMI Root    $pyIPCMI_RootDirectory" -ForegroundColor Yellow
	Write-Host "  Working         $Wrapper_WorkingDirectory" -ForegroundColor Yellow
	Write-Host "Script:" -ForegroundColor Yellow
	Write-Host "  Filename        $pyIPCMI_FrontEndPy" -ForegroundColor Yellow
	Write-Host "  Library         $Library" -ForegroundColor Yellow
	Write-Host "  Solution        $Solution" -ForegroundColor Yellow
	Write-Host "  Project         $Project" -ForegroundColor Yellow
	Write-Host "  Parameters      $args" -ForegroundColor Yellow
	Write-Host "Load Environment:" -ForegroundColor Yellow
	Write-Host "  Lattice Diamond $($PyWrapper_LoadEnv['Lattice']['Tools']['Diamond']['Load'])"	-ForegroundColor Yellow
	Write-Host "  Xilinx ISE      $($PyWrapper_LoadEnv['Xilinx']['Tools']['ISE']['Load'])"			-ForegroundColor Yellow
	Write-Host "  Xilinx Vivado   $($PyWrapper_LoadEnv['Xilinx']['Tools']['Vivado']['Load'])"		-ForegroundColor Yellow
	Write-Host ""
}

# execute script with appropriate Python interpreter and all given parameters
if ($Solution -eq "")
{	$Command = "$Python_Interpreter $Python_Parameters $pyIPCMI_FrontEndPy $args"													}
else
{	$Command = "$Python_Interpreter $Python_Parameters $pyIPCMI_FrontEndPy --sln=$Solution $args"			}

# execute script with appropriate Python interpreter and all given parameters
if ($Debug -eq $true)	{	Write-Host "launching: '$Command'" -ForegroundColor Yellow	}
Invoke-Expression $Command
$PyWrapper_ExitCode = $LastExitCode


Invoke-CloseEnvironment $PyWrapper_LoadEnv | Out-Null

# unload PowerShell module
Remove-Module $pyIPCMI_PSModule
# clean up environment variables
$env:LibraryRootDirectory =   $null
$env:Library =                $null
$env:pyIPCMIRootDirectory =   $null
$env:pyIPCMIConfigDirectory = $null
$env:pyIPCMIFrontEnd =        $null

# restore working directory if changed
Set-Location $Wrapper_WorkingDirectory

# return exit status
exit $PyWrapper_ExitCode
