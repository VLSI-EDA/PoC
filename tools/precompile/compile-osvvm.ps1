# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
#	Authors:            Patrick Lehmann
#
#	PowerShell Script:  Compile OSVVM's simulation packages
#
# Description:
# ------------------------------------
#	This PowerShell script compiles OSVVM's simulation packages into a local
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
# This CmdLet pre-compiles the simulation libraries from OSVVM.
#
# .DESCRIPTION
# This CmdLet:
#   (1) Creates a sub-directory 'osvvm' in the current working directory
#   (2) Compiles all OSVVM simulation libraries and packages for
#       o GHDL
#       o QuestaSim
#
[CmdletBinding()]
param(
	# Pre-compile all libraries and packages for all simulators
	[switch]$All =				$false,

	# Pre-compile the OSVVM libraries for GHDL
	[switch]$GHDL =				$false,

	# Pre-compile the OSVVM libraries for QuestaSim
	[switch]$Questa =			$false,

	# Clean up directory before analyzing.
	[switch]$Clean =			$false,

	# Show the embedded help page(s)
	[switch]$Help =				$false
)

$PoCRootDir =						"\..\.."
$OSVVMSourceDirectory =	"lib\osvvm"

# resolve paths
$WorkingDir =		Get-Location
$PoCRootDir =		Convert-Path (Resolve-Path ($PSScriptRoot + $PoCRootDir))
$PoCPS1 =				"$PoCRootDir\poc.ps1"

# set default values
$EnableVerbose =			$PSCmdlet.MyInvocation.BoundParameters["Verbose"]
$EnableDebug =				$PSCmdlet.MyInvocation.BoundParameters["Debug"]
if ($EnableVerbose -eq $null)	{	$EnableVerbose =	$false	}
if ($EnableDebug	 -eq $null)	{	$EnableDebug =		$false	}
if ($EnableDebug	 -eq $true)	{	$EnableVerbose =	$true		}

Import-Module $PSScriptRoot\precompile.psm1 -Verbose:$false -Debug:$false -ArgumentList "$WorkingDir"

# Display help if no command was selected
$Help = $Help -or (-not ($All -or $GHDL -or $Questa))

if ($Help)
{	Get-Help $MYINVOCATION.InvocationName -Detailed
	Exit-PrecompileScript
}

$GHDL,$Questa =			Resolve-Simulator $All $GHDL $Questa

$PreCompiledDir =		Get-PrecompiledDirectoryName $PoCPS1
$OSVVMDirName =			"osvvm"
$SourceDirectory =	"$PoCRootDir\$OSVVMSourceDirectory"

# GHDL
# ==============================================================================
if ($GHDL)
{	Write-Host "Pre-compiling OSVVM's simulation libraries for GHDL" -ForegroundColor Cyan
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan

	$GHDLBinDir =			Get-GHDLBinaryDirectory $PoCPS1
	$GHDLScriptDir =	Get-GHDLScriptDirectory $PoCPS1
	$GHDLDirName =		Get-GHDLDirectoryName $PoCPS1

	# Assemble output directory
	$DestDir = Convert-Path (Resolve-Path "$PoCRootDir\$PrecompiledDir\$GHDLDirName")
	# Create and change to destination directory
	Initialize-DestinationDirectory $DestDir

	$GHDLOSVVMScript = "$GHDLScriptDir\compile-osvvm.ps1"
	if (-not (Test-Path $GHDLOSVVMScript -PathType Leaf))
	{ Write-Host "[ERROR]: OSVVM compile script '$GHDLOSVVMScript' from GHDL not found." -ForegroundColor Red
		Exit-PrecompileScript -1
	}

	# export GHDL environment variable if not allready set
	if (-not (Test-Path env:GHDL))
	{	$env:GHDL = $GHDLBinDir		}

	$Command = "$GHDLOSVVMScript -All -Source $SourceDirectory -Output $DestDir -Verbose:`$$EnableVerbose -Debug:`$$EnableDebug"
	Invoke-Expression $Command
	if ($LastExitCode -ne 0)
	{	Write-Host "[ERROR]: While executing vendor library compile script from GHDL." -ForegroundColor Red
		Exit-PrecompileScript -1
	}


	# restore working directory
	cd $WorkingDir
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan
}

# QuestaSim/ModelSim
# ==============================================================================
if ($Questa)
{	Write-Host "Pre-compiling OSVVM's simulation libraries for QuestaSim" -ForegroundColor Cyan
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan

	$VSimBinDir =			Get-ModelSimBinaryDirectory $PoCPS1
	$VSimDirName =		Get-QuestaSimDirectoryName $PoCPS1

	# Assemble output directory
	$DestDir = Convert-Path (Resolve-Path "$PoCRootDir\$PrecompiledDir\$VSimDirName\$OSVVMDirName")
	# Create and change to destination directory
	Initialize-DestinationDirectory $DestDir
	cd ..

	$Library = "osvvm"
	$Files = @(
		"NamePkg.vhd",
		"OsvvmGlobalPkg.vhd",
		"TextUtilPkg.vhd",
		"TranscriptPkg.vhd",
		"AlertLogPkg.vhd",
		"MemoryPkg.vhd",
		"MessagePkg.vhd",
		"SortListPkg_int.vhd",
		"RandomBasePkg.vhd",
		"RandomPkg.vhd",
		"CoveragePkg.vhd",
		"OsvvmContext.vhd"
	)
	$SourceFiles = $Files | % { "$SourceDirectory\$_" }

	# Compile libraries with vcom, executed in destination directory
	Write-Host "Creating library '$Library' with vlib/vmap..." -ForegroundColor Yellow
	& "$VSimBinDir\vlib.exe" $Library
	& "$VSimBinDir\vmap.exe" -del $Library
	& "$VSimBinDir\vmap.exe" $Library "$DestDir"

	Write-Host "Compiling library '$Library' with vcom..." -ForegroundColor Yellow
	$ErrorCount += 0
	foreach ($File in $SourceFiles)
	{	Write-Host "Compiling '$File'..." -ForegroundColor Cyan
		$InvokeExpr = "$VSimBinDir\vcom.exe -2008 -work $Library " + $File + " 2>&1"
		Invoke-Expression $InvokeExpr
		if ($LastExitCode -ne 0)
		{	$ErrorCount += 1
			if ($HaltOnError)
			{	break		}
		}
	}

	# restore working directory
	cd $WorkingDir
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan
}

Write-Host "[COMPLETE]" -ForegroundColor Green

Exit-PrecompileScript
