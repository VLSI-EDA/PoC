# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
#	Authors:						Patrick Lehmann
#
#	PowerShell Module:
#
# Description:
# ------------------------------------
#	TODO:
#		-
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
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================
#
$VHDLStandard = "93"

function Open-Environment
{	$Debug = $false

	# load Xilinx ISE environment if not loaded before
	if (-not (Test-Path env:XILINX))
	{	$ISE_SettingsFile = PoCQuery "Xilinx.ISE:SettingsFile"
		if ($LastExitCode -ne 0)
		{	Write-Host "[ERROR]: ExitCode for '$PoC_Command' was not zero. Aborting execution." -ForegroundColor Red
			Write-Host "       $ISE_SettingsFile" -ForegroundColor Red
			return 1
		}
		elseif ($ISE_SettingsFile -eq "")
		{	Write-Host "ERROR: No Xilinx ISE installation found." -ForegroundColor Red
			Write-Host "Run 'poc.ps1 configure' to configure your Xilinx ISE installation." -ForegroundColor Red
			return 1
		}
		elseif (-not (Test-Path $ISE_SettingsFile -PathType Leaf))
		{	Write-Host "[ERROR]: Xilinx ISE is configured in PoC, but settings file '$ISE_SettingsFile' does not exist." -ForegroundColor Red
			Write-Host "Run 'poc.ps1 configure' to configure your Xilinx ISE installation." -ForegroundColor Red
			return 1
		}
		elseif (-not (($ISE_SettingsFile -like "*.bat") -or ($ISE_SettingsFile -like "*.cmd")))
		{	Write-Host "[ERROR]: Xilinx ISE is configured in PoC, but settings file format is not supported." -ForegroundColor Red
			return 1
		}

		Write-Host "Loading Xilinx ISE environment '$ISE_SettingsFile'" -ForegroundColor Yellow
		if (-not (Get-Module -ListAvailable PSCX))
		{	Write-Host "[ERROR]: PowerShell Community Extensions (PSCX) is not installed." -ForegroundColor Red
			return 1
		}
		Import-Module PSCX
		Invoke-BatchFile -path $ISE_SettingsFile
		return 0
	}
	elseif (-not (Test-Path $env:XILINX))
	{	Write-Host "[ERROR]: Environment variable XILINX is set, but the path does not exist." -ForegroundColor Red
		Write-Host ("  XILINX=" + $env:XILINX) -ForegroundColor Red
		$env:XILINX = $null
		return (Load-Environment)
	}
}

function Close-Environment
{	Write-Host "Unloading Xilinx ISE environment..." -ForegroundColor Yellow
	$env:XILINX =						$null
	$env:XILINX_EDK =				$null
	$env:XILINX_PLANAHEAD =	$null
	$env:XILINX_DSP =				$null
	return 0
}

function Register-Environment
{	Write-Host "ISE: register environment"

	if (Test-Path Alias:tb)
	{	Write-Host "[WARNING] Alias 'tb' is already in use. Use the CmdLet 'Start-Testbench instead.'" -ForegroundColor Yellow	}
	else
	{	Set-Alias -Name tb -Value Start-Testbench -Description "Start a testbench in ISE." -Scope Global												}
}

function Unregister-Environment
{	Write-Host "ISE: unregister environment"

	if (Test-Path Alias:tb)		{	Remove-Item Alias:tb		}
}

function Start-Testbench
{

	Write-Host "ISE: Start a testbench only in VHDL'93"
}

function Set-VHDLStandard
{
	[CmdletBinding()]
	param(
		[String] $std
	)
	Write-Host "ISE: Set-VHDLStandard not supported" -ForegroundColor Red
}


Export-ModuleMember -Function 'Open-Environment'
Export-ModuleMember -Function 'Close-Environment'

Export-ModuleMember -Function 'Register-Environment'
Export-ModuleMember -Function 'Unregister-Environment'
Export-ModuleMember -Function 'Start-Testbench'
Export-ModuleMember -Function 'Set-VHDLStandard'

