# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
#	Authors:				 	Patrick Lehmann
# 
#	Bash Script:			Compile Xilinx's simulation libraries
# 
# Description:
# ------------------------------------
#	This is a bash script compiles Xilinx's simulation libraries into a local
#	directory.
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

$PoC_RootDir =				"\..\.."
$Simulator =					"questa"															# questa, ...
$Language =						"vhdl"																# all, vhdl, verilog
$TargetArchitecture =	"all"																	# all, virtex5, virtex6, virtex7, ...

# resolve paths
$PoC_RootDir =				Convert-Path (Resolve-Path ($PSScriptRoot + $PoC_RootDir))

# load Xilinx ISE environment
$Command = "$PoC_RootDir\poc.ps1 --ise-settingsfile"
$ISE_SettingsFile = Invoke-Expression $Command
if (($LastExitCode -ne 0) -or ($ISE_SettingsFile -eq ""))
{	Write-Host "ERROR: No Xilinx ISE installation found." -ForegroundColor Red
	Write-Host "Run '.\poc.ps1 --configure' to configure your Xilinx ISE installation." -ForegroundColor Red
	exit 1
}
else
{	Write-Host "Loading Xilinx ISE environment '$ISE_SettingsFile'" -ForegroundColor Yellow
	if (($ISE_SettingsFile -like "*.bat") -or ($ISE_SettingsFile -like "*.cmd"))
	{	Import-Module PSCX
		Invoke-BatchFile -path $ISE_SettingsFile
	}
	else
	{	. $ISE_SettingsFile			}
}
if (-not (Test-Path env:XILINX))
{	Write-Host "ERROR: No Xilinx ISE environment loaded." -ForegroundColor Red
	exit 1
}

Write-Host "Recompiling Xilinx's simulation libraries for QuestaSim" -ForegroundColor Cyan
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan

# Output directory
$Command = "$PoC_RootDir\poc.ps1 --poc-installdir"
$DestDir = Invoke-Expression $Command
if (($LastExitCode -ne 0) -or ($DestDir -eq ""))
{	Write-Host "ERROR: No PoC installation found." -ForegroundColor Red
	exit 1
}
$DestDir += "\temp\QuestaSim"

# Path to the simulators bin directory
$Command = "$PoC_RootDir\poc.ps1 --modelsim-installdir"
$SimulatorDir = Invoke-Expression $Command
if (($LastExitCode -ne 0) -or ($SimulatorDir -eq ""))
{	Write-Host "ERROR: No QuestaSim installation found." -ForegroundColor Red
	Write-Host "Run '.\poc.ps1 --configure' to configure your Mentor QuestaSim installation." -ForegroundColor Red
	exit 1
}
$SimulatorDir += "\win64"

$Command = $env:XILINX + "\bin\nt64\compxlib.exe -s $Simulator -l $Language -dir $DestDir -p $SimulatorDir -arch $TargetArchitecture -lib unisim -lib simprim -lib xilinxcorelib -intstyle ise"
Invoke-Expression $Command

Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "[COMPLETE]" -ForegroundColor Green