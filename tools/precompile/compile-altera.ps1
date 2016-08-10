# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
#	Authors:            Patrick Lehmann
# 
#	PowerShell Script:  Compile Altera's simulation libraries
# 
# Description:
# ------------------------------------
#	This PowerShell script compiles Altera's simulation libraries into a local
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

# .SYNOPSIS
# This CmdLet pre-compiles the simulation libraries from Altera Quartus.
# 
# .DESCRIPTION
# This CmdLet:
#   (1) Creates a sub-directory 'altera' in the current working directory
#   (2) Compiles all Altera Quartus simulation libraries and packages for
#       o GHDL
#       o QuestaSim
# 
[CmdletBinding()]
param(
	# Pre-compile all libraries and packages for all simulators
	[switch]$All =				$false,
	
	# Pre-compile the Altera Quartus libraries for GHDL
	[switch]$GHDL =				$false,
	
	# Pre-compile the Altera Quartus libraries for QuestaSim
	[switch]$Questa =			$false,
	
	# Set VHDL Standard to '93
	[switch]$VHDL93 =			$false,
	# # Set VHDL Standard to '08
	[switch]$VHDL2008 =		$false,
	
	# Clean up directory before analyzing.
	[switch]$Clean =			$false,
	
	# Show the embedded help page(s)
	[switch]$Help =				$false
)

$PoCRootDir =		"\..\.."

# resolve paths
$WorkingDir =		Get-Location
$PoCRootDir =		Convert-Path (Resolve-Path ($PSScriptRoot + $PoCRootDir))
$PoCPS1 =				"$PoCRootDir\poc.ps1"

Import-Module $PSScriptRoot\precompile.psm1 -Verbose:$false -Scope Local -ArgumentList "$WorkingDir"

# Display help if no command was selected
$Help = $Help -or (-not ($All -or $GHDL -or $Questa))

if ($Help)
{	Get-Help $MYINVOCATION.InvocationName -Detailed
	Exit-PrecompileScript
}

$GHDL,$Questa =			Resolve-Simulator $All $GHDL $Questa
$VHDL93,$VHDL2008 = Resolve-VHDLVersion $VHDL93 $VHDL2008

$PreCompiledDir =		Get-PrecompiledDirectoryName $PoCPS1
$AlteraDirName =		Get-AlteraDirectoryName $PoCPS1

# GHDL
# ==============================================================================
if ($GHDL)
{	Write-Host "Pre-compiling Altera's simulation libraries for GHDL" -ForegroundColor Cyan
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan

	$GHDLBinDir =			Get-GHDLBinaryDirectory $PoCPS1
	$GHDLScriptDir =	Get-GHDLScriptDirectory $PoCPS1
	$GHDLDirName =		Get-GHDLDirectoryName $PoCPS1

	# Assemble output directory
	$DestDir = "$PoCRootDir\$PrecompiledDir\$GHDLDirName"
	# Create and change to destination directory
	Initialize-DestinationDirectory $DestDir
	
	$GHDLAlteraScript = "$GHDLScriptDir\compile-altera.ps1"
	if (-not (Test-Path $GHDLAlteraScript -PathType Leaf))
	{ Write-Host "[ERROR]: Altera compile script from GHDL is not executable." -ForegroundColor Red
		Exit-PrecompileScript -1
	}
	
	$QuartusInstallDir =	Get-QuartusInstallationDirectory $PoCPS1
	$SourceDir =					"$QuartusInstallDir\eda\sim_lib"
	
	# export GHDL environment variable if not allready set
	if (-not (Test-Path env:GHDL))
	{	$env:GHDL = "$GHDLBinDir\ghdl.exe"		}
	
	if ($VHDL93)
	{	$Command = "$GHDLAlteraScript -All -VHDL93 -Source $SourceDir -Output $DestDir\$AlteraDirName"
		Invoke-Expression $Command
		if ($LastExitCode -ne 0)
		{	Write-Host "[ERROR]: While executing vendor library compile script from GHDL." -ForegroundColor Red
			Exit-PrecompileScript -1
		}
	}
	if ($VHDL2008)
	{	$Command = "$GHDLAlteraScript -All -VHDL2008 -Source $SourceDir -Output $DestDir\$AlteraDirName"
		Invoke-Expression $Command
		if ($LastExitCode -ne 0)
		{	Write-Host "[ERROR]: While executing vendor library compile script from GHDL." -ForegroundColor Red
			Exit-PrecompileScript -1
		}
	}
	
	# restore working directory
	cd $WorkingDir
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan
}

# QuestaSim/ModelSim
# ==============================================================================
if ($Questa)
{	Write-Host "Pre-compiling Altera's simulation libraries for QuestaSim" -ForegroundColor Cyan
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan

	$VSimBinDir =			Get-ModelSimBinaryDirectory $PoCPS1
	$VSimDirName =		Get-QuestaSimDirectoryName $PoCPS1

	# Assemble output directory
	$DestDir="$PoCRootDir\$PrecompiledDir\$VSimDirName\$AlteraDirName"
	# Create and change to destination directory
	Initialize-DestinationDirectory $DestDir

	$QuartusBinDir = 	Get-QuartusBinaryDirectory $PoCPS1
	$Quartus_sh =			"$QuartusBinDir\quartus_sh.exe"
	
	New-ModelSim_ini
	
	$Simulator =						"questasim"
	$Language =							"vhdl"
	$TargetArchitectures =	@(
		"all"
	)
	
	# compile common libraries
	$Command = "$Quartus_sh --simlib_comp -tool $Simulator -language $Language -tool_path $VSimBinDir -directory $DestDir -rtl_only"
	Invoke-Expression $Command
	if ($LastExitCode -ne 0)
	{	Write-Host "[ERROR]: While compiling common libraries." -ForegroundColor Red
		Exit-PrecompileScript -1
	}
	
	$VSimBinDir_TclPath =	$VSimBinDir.Replace("\", "/")
	$DestDir_TclPath =		$DestDir.Replace("\", "/")
	foreach ($Family in $TargetArchitectures)
	{	$Command = "$Quartus_sh --simlib_comp -tool $Simulator -language $Language -family $Family -tool_path $VSimBinDir_TclPath -directory $DestDir_TclPath -rtl_only"
		Invoke-Expression $Command
		if ($LastExitCode -ne 0)
		{	Write-Host "[ERROR]: While compiling family '$Family' libraries." -ForegroundColor Red
			Exit-PrecompileScript -1
		}
	}
	
	# restore working directory
	cd $WorkingDir
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan
}

Write-Host "[COMPLETE]" -ForegroundColor Green

Exit-PrecompileScript
