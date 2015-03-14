# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
#	Authors:				 		Patrick Lehmann
# 
#	PowerShell Script:	Wrapper Script to execute a given python script
# 
# Description:
# ------------------------------------
#	This is a PowerShell script (callable) which:
#		- 
#		- 
#		-
#
# License:
# ==============================================================================
# Copyright 2007-2015 Technische Universitaet Dresden - Germany
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

# script settings
$PoC_ExitCode = 0
$PoC_PythonScriptDir = "py"


$PoC_WorkingDir = Get-Location

# publish PoC directories as environment variables
$env:PoCScriptDirectory =		$PyWrapper_ScriptDir
$env:PoCRootDirectory =			$PoC_RootDir_AbsPath
$env:PoCWorkingDirectory =	$PoC_WorkingDir

if ($PyWrapper_Debug -eq $true ) {
	Write-Host "This is the PoC Library script wrapper operating in debug mode." -ForegroundColor Yellow
	Write-Host ""
	Write-Host "Directories:" -ForegroundColor Yellow
	Write-Host "  Script root:   $PyWrapper_ScriptDir" -ForegroundColor Yellow
	Write-Host "  PoC root:      $PoC_RootDir_AbsPath" -ForegroundColor Yellow
	Write-Host "  working:       $PoC_WorkingDir" -ForegroundColor Yellow
	Write-Host "Script:" -ForegroundColor Yellow
	Write-Host "  Filename:      $PyWrapper_Script" -ForegroundColor Yellow
	Write-Host "  Parameters:    $PyWrapper_Parameters" -ForegroundColor Yellow
	Write-Host "Load Environment:" -ForegroundColor Yellow
	Write-Host "  Xilinx ISE:    $PyWrapper_LoadEnv_ISE" -ForegroundColor Yellow
	Write-Host "  Xilinx VIVADO: $PyWrapper_LoadEnv_Vivado" -ForegroundColor Yellow
	Write-Host ""
}

# find suitable python version or abort execution
$Python_VersionTest = 'py.exe -3 -c "import sys; sys.exit(not (0x03040000 < sys.hexversion < 0x04000000))"'
Invoke-Expression $Python_VersionTest | Out-Null
if ($LastExitCode -eq 0) {
    $Python_Interpreter = "py.exe"
		$Python_Parameters =	(, "-3")
 	if ($PyWrapper_Debug -eq $true) { Write-Host "PythonInterpreter: '$Python_Interpreter $Python_Parameters'" -ForegroundColor Yellow }
} else {
    Write-Host "ERROR: No suitable Python interpreter found." -ForegroundColor Red
    Write-Host "The script requires Python $PyWrapper_MinVersion." -ForegroundColor Yellow
    $PoC_ExitCode = 1
}

if ($PoC_ExitCode -eq 0) {
	# load Xilinx ISE environment if not loaded before
	if ($PyWrapper_LoadEnv_ISE -eq $true) {
		if (-not (Test-Path env:XILINX)) {
			$PoC_Command = "$Python_Interpreter $Python_Parameters $PoC_RootDir_AbsPath\$PoC_PythonScriptDir\Configuration.py --ise-settingsfile"
			if ($PyWrapper_Debug -eq $true) { Write-Host "Getting ISE settings file: command='$PoC_Command'" -ForegroundColor Yellow }

			# execute python script to receive ISE settings filename
			$PoC_ISE_SettingsFile = Invoke-Expression $PoC_Command
			if ($LastExitCode -eq 0) {
				if ($PyWrapper_Debug -eq $true) { Write-Host "ISE settings file: '$PoC_ISE_SettingsFile'" }
				if ($PoC_ISE_SettingsFile -eq "") {
					Write-Host "ERROR: No Xilinx ISE installation found." -ForegroundColor Red
					Write-Host "Run 'poc.ps1 --configure' to configure your Xilinx ISE installation." -ForegroundColor Red
					$PoC_ExitCode = 1
				} else {
					Write-Host "Loading Xilinx ISE environment '$PoC_ISE_SettingsFile'" -ForegroundColor Yellow
					if (($PoC_ISE_SettingsFile -like "*.bat") -or ($PoC_ISE_SettingsFile -like "*.cmd")) {
						Import-Module PSCX
						Invoke-BatchFile -path $PoC_ISE_SettingsFile
					} else {
						. $PoC_ISE_SettingsFile
					}
				}
			} else {
				Write-Host "ERROR: ExitCode for '$PoC_Command' was not zero. Aborting script execution" -ForegroundColor Red
				Write-Host $PoC_ISE_SettingsFile -ForegroundColor Red
				$PoC_ExitCode = 1
			}
		}
	}
}

if ($PoC_ExitCode -eq 0) {
	# load Xilinx Vivado environment if not loaded before
	if ($PyWrapper_LoadEnv_Vivado -eq $true) {
		if (-not (Test-Path env:XILINX)) {
			$PoC_Command = "$Python_Interpreter $Python_Parameters $PoC_RootDir_AbsPath\$PoC_PythonScriptDir\Configuration.py --vivado-settingsfile"
			if ($PyWrapper_Debug -eq $true) { Write-Host "Getting Vivado settings file: command='$PoC_Command'" -ForegroundColor Yellow }

			# execute python script to receive ISE settings filename
			$PoC_Vivado_SettingsFile = Invoke-Expression $PoC_Command
			if ($LastExitCode -eq 0) {
				if ($PyWrapper_Debug -eq $true) { Write-Host "Vivado settings file: '$PoC_Vivado_SettingsFile'" }
				if ($PoC_Vivado_SettingsFile -eq "") {
					Write-Host "ERROR: No Xilinx Vivado installation found." -ForegroundColor Red
					Write-Host "Run 'poc.ps1 --configure' to configure your Xilinx Vivado installation." -ForegroundColor Red
					$PoC_ExitCode = 1
				} else {
					Write-Host "Loading Xilinx Vivado environment '$PoC_Vivado_SettingsFile'" -ForegroundColor Yellow
					if (($PoC_Vivado_SettingsFile -like "*.bat") -or ($PoC_Vivado_SettingsFile -like "*.cmd")) {
						Import-Module PSCX
						Invoke-BatchFile -path $PoC_Vivado_SettingsFile
					} else {
						. $PoC_Vivado_SettingsFile
					}
				}
			} else {
				Write-Host "ERROR: ExitCode for '$PoC_Command' was not zero. Aborting script execution" -ForegroundColor Red
				$PoC_ExitCode = 1
			}
		}
	}
}

# execute script with appropriate python interpreter and all given parameters
if ($PoC_ExitCode -eq 0) {
	$Python_Script =						"$PoC_RootDir_AbsPath\$PoC_PythonScriptDir\$PyWrapper_Script"
	$Python_ScriptParameters =	$PyWrapper_Parameters
	
	# execute script with appropriate python interpreter and all given parameters
	if ($PyWrapper_Debug -eq $true) {
		Write-Host "launching: '$Python_Interpreter $Python_Parameters $Python_Script $Python_ScriptParameters'" -ForegroundColor Yellow
		Write-Host "------------------------------------------------------------" -ForegroundColor Yellow
	}

	# launching python script
	Invoke-Expression "$Python_Interpreter $Python_Parameters $Python_Script $Python_ScriptParameters"
}

# clean up environment variables
$env:PoCScriptDirectory =		$null
$env:PoCRootDirectory =			$null
$env:PoCWorkingDirectory =	$null
