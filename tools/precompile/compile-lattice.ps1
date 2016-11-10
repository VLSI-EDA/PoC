# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
#	Authors:            Patrick Lehmann
#
#	PowerShell Script:  Compile Lattice's simulation libraries
#
# Description:
# ------------------------------------
#	This PowerShell script compiles Lattice's simulation libraries into a local
#	directory.
#
# License:
# ==============================================================================
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

# .SYNOPSIS
# This CmdLet pre-compiles the simulation libraries from Lattice Diamond.
#
# .DESCRIPTION
# This CmdLet:
#   (1) Creates a sub-directory 'lattice' in the current working directory
#   (2) Compiles all Lattice Diamond simulation libraries and packages for
#       o GHDL
#       o QuestaSim
#
[CmdletBinding()]
param(
	# Pre-compile all libraries and packages for all simulators
	[switch]$All =				$false,

	# Pre-compile the Lattice Diamond libraries for GHDL
	[switch]$GHDL =				$false,

	# Pre-compile the Lattice Diamond libraries for QuestaSim
	[switch]$Questa =			$false,

	# Set VHDL Standard to '93
	[switch]$VHDL93 =			$false,
	# Set VHDL Standard to '08
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
$VHDL93,$VHDL2008 = Resolve-VHDLVersion $VHDL93 $VHDL2008

$PreCompiledDir =		Get-PrecompiledDirectoryName $PoCPS1
$LatticeDirName =		Get-LatticeDirectoryName $PoCPS1

# GHDL
# ==============================================================================
if ($GHDL)
{	Write-Host "Pre-compiling Lattice's simulation libraries for GHDL" -ForegroundColor Cyan
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan

	$GHDLBinDir =			Get-GHDLBinaryDirectory $PoCPS1
	$GHDLScriptDir =	Get-GHDLScriptDirectory $PoCPS1
	$GHDLDirName =		Get-GHDLDirectoryName $PoCPS1

	# Assemble output directory
	$DestDir="$PoCRootDir\$PrecompiledDir\$GHDLDirName"
	# Create and change to destination directory
	Initialize-DestinationDirectory $DestDir

	$GHDLLatticeScript = "$GHDLScriptDir\compile-lattice.ps1"
	if (-not (Test-Path $GHDLLatticeScript -PathType Leaf))
	{ Write-Host "[ERROR]: Lattice compile script '$GHDLLatticeScript' from GHDL not found." -ForegroundColor Red
		Exit-PrecompileScript -1
	}

	$DiamondInstallDir =	Get-DiamondInstallationDirectory $PoCPS1
	$SourceDir =					"$DiamondInstallDir\cae_library\simulation\vhdl"

	# export GHDL environment variable if not allready set
	if (-not (Test-Path env:GHDL))
	{	$env:GHDL = $GHDLBinDir		}

	if ($VHDL93)
	{	$Command = "$GHDLLatticeScript -All -VHDL93 -Source $SourceDir -Output $DestDir\$LatticeDirName -Verbose:`$$EnableVerbose -Debug:`$$EnableDebug"
		Invoke-Expression $Command
		if ($LastExitCode -ne 0)
		{	Write-Host "[ERROR]: While executing vendor library compile script from GHDL." -ForegroundColor Red
			Exit-PrecompileScript -1
		}
	}
	if ($VHDL2008)
	{	$Command = "$GHDLLatticeScript -All -VHDL2008 -Source $SourceDir -Output $DestDir\$LatticeDirName -Verbose:`$$EnableVerbose -Debug:`$$EnableDebug"
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
{	Write-Host "Pre-compiling Lattice's simulation libraries for QuestaSim" -ForegroundColor Cyan
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan

	$VSimBinDir =			Get-ModelSimBinaryDirectory $PoCPS1
	$VSimDirName =		Get-QuestaSimDirectoryName $PoCPS1

	# Assemble output directory
	$DestDir="$PoCRootDir\$PrecompiledDir\$VSimDirName\$LatticeDirName"
	# Create and change to destination directory
	Initialize-DestinationDirectory $DestDir

	$DiamondBinDir = 		Get-DiamondBinaryDirectory $PoCPS1
	$Diamond_tcl =			"$DiamondBinDir\pnmainc.exe"
	# Open-DiamondEnvironment $PoCPS1

	New-ModelSim_ini

	$Simulator =					"mentor"
	$Language =						"vhdl"
	$Device =							"all"			# all, machxo, ecp, ...

	$VSimBinDir_TclPath = $VSimBinDir.Replace("\", "/")
	"cmpl_libs -lang $Language -sim_vendor $Simulator -sim_path $VSimBinDir_TclPath -device $Device`nexit" | & $Diamond_tcl
	if ($LastExitCode -ne 0)
	{	Write-Host "[ERROR]: While executing vendor library compile script from GHDL." -ForegroundColor Red
		Exit-PrecompileScript -1
	}

	# Close-DiamondEnvironment

	# restore working directory
	cd $WorkingDir
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan
}

Write-Host "[COMPLETE]" -ForegroundColor Green

Exit-PrecompileScript
