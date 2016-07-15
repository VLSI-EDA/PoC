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

function Open-Environment
{	[CmdletBinding()]
	param(
		[String]		$Py_Interpreter,
		[String[]]	$Py_Parameters,
		[String]		$PoC_Query
	)
	$Debug = $false
	
	# load Xilinx Vivado environment if not loaded before
	if (-not (Test-Path env:XILINX_VIVADO))
	{	$Query = "Xilinx.Vivado:SettingsFile"
		$PoC_Command = "$Py_Interpreter $Py_Parameters $PoC_Query query $Query"
		if ($Debug -eq $true)
		{	Write-Host "Inquire Vivado settings file: command='$PoC_Command'" -ForegroundColor Yellow }

		# execute python script to receive Vivado settings filename
		$Vivado_SettingsFile = Invoke-Expression $PoC_Command
		if ($LastExitCode -ne 0)
		{	Write-Host "ERROR: ExitCode for '$PoC_Command' was not zero. Aborting execution." -ForegroundColor Red
			Write-Host "       $Vivado_SettingsFile" -ForegroundColor Red
			return 1
		}
		
		if ($Debug -eq $true)
		{ Write-Host "Vivado settings file: '$Vivado_SettingsFile'" -ForegroundColor Yellow }
		
		if ($Vivado_SettingsFile -eq "")
		{	Write-Host "ERROR: No Xilinx Vivado installation found." -ForegroundColor Red
			Write-Host "Run 'poc.ps1 configure' to configure your Xilinx Vivado installation." -ForegroundColor Red
			return 1
		}
		elseif (-not (Test-Path $Vivado_SettingsFile -PathType Leaf))
		{	Write-Host "ERROR: Xilinx Vivado is configured in PoC, but settings file '$Vivado_SettingsFile' does not exist." -ForegroundColor Red
			Write-Host "Run 'poc.ps1 configure' to configure your Xilinx Vivado installation." -ForegroundColor Red
			return 1
		}
		elseif (($Vivado_SettingsFile -like "*.bat") -or ($Vivado_SettingsFile -like "*.cmd"))
		{	Write-Host "Loading Xilinx Vivado environment '$Vivado_SettingsFile'" -ForegroundColor Yellow
			if (-not (Get-Module -ListAvailable PSCX))
			{	Write-Host "ERROR: PowerShell Community Extensions (PSCX) is not installed." -ForegroundColor Red
				return 1
			}
			Import-Module PSCX
			Invoke-BatchFile -path $Vivado_SettingsFile
			return 0
		}
		else
		{	Write-Host "ERROR: Xilinx Vivado is configured in PoC, but settings file format is not supported." -ForegroundColor Red
			return 1
		}
	}
	elseif (-not (Test-Path $env:XILINX_VIVADO))
	{	Write-Host "ERROR: Environment variable XILINX_VIVADO is set, but the path does not exist." -ForegroundColor Red
		Write-Host ("  XILINX_VIVADO=" + $env:XILINX_VIVADO) -ForegroundColor Red
		$env:XILINX_VIVADO = $null
		Load-Environment $Py_Interpreter $Py_Parameters $PoC_Query
	}
}

function Close-Environment
{	Write-Host "Unloading Xilinx Vivado environment..." -ForegroundColor Yellow
	$env:XILINX_VIVADO =		$null
	return 0
}

Export-ModuleMember -Function 'Open-Environment'
Export-ModuleMember -Function 'Close-Environment'
