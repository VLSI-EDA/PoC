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
# Copyright 2007-2017 Technische Universitaet Dresden - Germany
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
# This CmdLet pre-compiles the simulation libraries from OSVVM.
#
# .DESCRIPTION
# This CmdLet:
#   (1) Creates a sub-directory 'osvvm' in the current working directory
#   (2) Compiles all OSVVM simulation libraries and packages for
#       o Active-HDL
#       o GHDL
#       o ModelSim/QuestaSim
#
[CmdletBinding()]
param(
	# Pre-compile all libraries and packages for all simulators.
	[switch]$All =				$false,

	# Pre-compile the OSVVM libraries for Active-HDL.
	[switch]$ActiveHDL =	$false,
	# Pre-compile the OSVVM libraries for Riviera-PRO.
	[switch]$RivieraPRO =	$false,
	# Pre-compile the OSVVM libraries for GHDL.
	[switch]$GHDL =				$false,
	# Pre-compile the OSVVM libraries for ModelSim.
	[switch]$ModelSim =		$false,
	# Pre-compile the OSVVM libraries for QuestaSim.
	[switch]$QuestaSim =	$false,

	# Clean up directory before analyzing.
	[switch]$Clean =			$false,

	# Show the embedded help page(s).
	[switch]$Help =				$false
)

$PoCRootDir =						"\..\.."
$OSVVMSourceDirectory =	"lib\osvvm"

# resolve paths
$WorkingDir =		Get-Location
$PoCRootDir =		Convert-Path (Resolve-Path ($PSScriptRoot + $PoCRootDir))
$PoCPS1 =				"$PoCRootDir\poc.ps1"

Import-Module $PSScriptRoot\precompile.psm1 -Verbose:$false -Debug:$false -ArgumentList "$WorkingDir"

# Display help if no command was selected
if ($Help -or (-not ($All -or $ActiveHDL -or $RivieraPRO -or $GHDL -or $ModelSim -or $QuestaSim)))
{	Get-Help $MYINVOCATION.InvocationName -Detailed
	Exit-PrecompileScript
}

# set default values
$EnableDebug =		[bool]$PSCmdlet.MyInvocation.BoundParameters["Debug"]
$EnableVerbose =	[bool]$PSCmdlet.MyInvocation.BoundParameters["Verbose"] -or $EnableDebug

if ($All)
{	$ActiveHDL =	$true
	$RivieraPRO =	$true
	$GHDL =				$true
	$ModelSim =		$true
	$QuestaSim =	$true
}

$PreCompiledDir =		Get-PrecompiledDirectoryName $PoCPS1
# $OSVVMDirName =			"osvvm"
$SourceDirectory =	"$PoCRootDir\$OSVVMSourceDirectory"

$OSVVM_Files = @(
	"NamePkg.vhd",
	"OsvvmGlobalPkg.vhd",
	"VendorCovApiPkg.vhd",
	"TranscriptPkg.vhd",
	"TextUtilPkg.vhd",
	"AlertLogPkg.vhd",
	"MessagePkg.vhd",
	"SortListPkg_int.vhd",
	"RandomBasePkg.vhd",
	"RandomPkg.vhd",
	"CoveragePkg.vhd",
	"MemoryPkg.vhd",
	"ScoreboardGenericPkg.vhd",
	"ScoreboardPkg_slv.vhd",
	"ScoreboardPkg_int.vhd",
	"ResolutionPkg.vhd",
	"TbUtilPkg.vhd",
	"OsvvmContext.vhd"

	"SortListGenericPkg.vhd",
	"SortListPkg.vhd",
	"ScoreboardPkg.vhd"
)

$ResolvedPrecompileDir = Convert-Path ( Resolve-Path "$PoCRootDir\$PrecompiledDir" )

# GHDL
# ==============================================================================
if ($GHDL)
{	Write-Host "Pre-compiling OSVVM's simulation libraries for GHDL" -ForegroundColor Cyan
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan

	$GHDLBinDir =			Get-GHDLBinaryDirectory $PoCPS1
	$GHDLScriptDir =	Get-GHDLScriptDirectory $PoCPS1
	$GHDLDirName =		Get-GHDLDirectoryName $PoCPS1

	# Assemble output directory
	$DestDir = $ResolvedPrecompileDir + "\$GHDLDirName"
	# Create and change to destination directory
	Initialize-DestinationDirectory $DestDir -Verbose:$EnableVerbose -Debug:$EnableDebug

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

# Active-HDL
# ==============================================================================
if ($ActiveHDL)
{	Write-Host "Pre-compiling OSVVM's simulation libraries for Active-HDL" -ForegroundColor Cyan
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan

	$ActiveHDLBinDir =	Get-ActiveHDLBinaryDirectory $PoCPS1 -Verbose:$EnableVerbose -Debug:$EnableDebug
	$ActiveHDLDirName =	Get-ActiveHDLDirectoryName $PoCPS1 -Verbose:$EnableVerbose -Debug:$EnableDebug

	# Assemble output directory
	$DestDir = $ResolvedPrecompileDir + "\$ActiveHDLDirName"
	# Create and change to destination directory
	Initialize-DestinationDirectory $DestDir -Verbose:$EnableVerbose -Debug:$EnableDebug

	$Library = "osvvm"
	$SourceFiles = $OSVVM_Files | % { "$SourceDirectory\$_" }

	# Compile libraries with vcom, executed in destination directory
	Write-Host "Creating library '$Library' with vlib/vmap..." -ForegroundColor Yellow
	$InvokeExpr = "$ActiveHDLBinDir\vlib.exe " + $Library + " 2>&1"
	$ErrorRecordFound = Invoke-Expression $InvokeExpr | Restore-NativeCommandStream | Write-ColoredActiveHDLVLibLine $SuppressWarnings "  " -Verbose:$EnableVerbose -Debug:$EnableDebug
	$InvokeExpr = "$ActiveHDLBinDir\vmap.exe -del " + $Library + " 2>&1"
	$ErrorRecordFound = Invoke-Expression $InvokeExpr | Restore-NativeCommandStream | Write-ColoredActiveHDLVMapLine $SuppressWarnings "  " -Verbose:$EnableVerbose -Debug:$EnableDebug
	$InvokeExpr = "$ActiveHDLBinDir\vmap.exe " + $Library + " $DestDir\$Library 2>&1"
	$ErrorRecordFound = Invoke-Expression $InvokeExpr | Restore-NativeCommandStream | Write-ColoredActiveHDLVMapLine $SuppressWarnings "  " -Verbose:$EnableVerbose -Debug:$EnableDebug

	Write-Host "Compiling library '$Library' with vcom..." -ForegroundColor Yellow
	$ErrorCount += 0
	foreach ($File in $SourceFiles)
	{	Write-Host "Compiling '$File'..." -ForegroundColor DarkCyan
		$InvokeExpr = "$ActiveHDLBinDir\vcom.exe -2008 -work $Library " + $File + " 2>&1"
		$ErrorRecordFound = Invoke-Expression $InvokeExpr | Restore-NativeCommandStream | Write-ColoredActiveHDLVComLine $SuppressWarnings "  " -Verbose:$EnableVerbose -Debug:$EnableDebug
		if (($LastExitCode -ne 0) -or $ErrorRecordFound)
		{	$ErrorCount += 1
			if ($HaltOnError)
			{	break		}
		}
	}

	# restore working directory
	cd $WorkingDir
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan
	Write-Host "Compiling OSVVM packages with Active-HDL " -NoNewline
	if ($ErrorCount -gt 0)
	{	Write-Host "[FAILED]" -ForegroundColor Red				}
	else
	{	Write-Host "[SUCCESSFUL]" -ForegroundColor Green	}
}

# Riviera-PRO
# ==============================================================================
if ($RivieraPRO)
{	Write-Host "Pre-compiling OSVVM's simulation libraries for Riviera-PRO" -ForegroundColor Cyan
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan

	Write-Host "Not yet supported." -ForegroundColor Red
}

# QuestaSim/ModelSim
# ==============================================================================
if ($ModelSim -or $QuestaSim)
{	Write-Host "Pre-compiling OSVVM's simulation libraries for ModelSim/QuestaSim" -ForegroundColor Cyan
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan

	$VSimBinDir =		Get-ModelSimBinaryDirectory $PoCPS1 -Verbose:$EnableVerbose -Debug:$EnableDebug
	$VSimDirName =	Get-ModelSimDirectoryName $PoCPS1 -Verbose:$EnableVerbose -Debug:$EnableDebug

	# Assemble output directory
	$DestDir =			$ResolvedPrecompileDir + "\$VSimDirName"
	$ModelSimINI =	"$DestDir\modelsim.ini"
	# Create and change to destination directory
	Initialize-DestinationDirectory $DestDir -Verbose:$EnableVerbose -Debug:$EnableDebug

	$Library = "osvvm"
	$SourceFiles = $OSVVM_Files | % { "$SourceDirectory\$_" }

	# Compile libraries with vcom, executed in destination directory
	Write-Host "Creating library '$Library' with vlib/vmap..." -ForegroundColor Yellow
	$InvokeExpr = "$VSimBinDir\vlib.exe " + $Library + " 2>&1"
	$ErrorRecordFound = Invoke-Expression $InvokeExpr | Restore-NativeCommandStream | Write-ColoredModelSimVLibLine $SuppressWarnings "  " -Verbose:$EnableVerbose -Debug:$EnableDebug
	$InvokeExpr = "$VSimBinDir\vmap.exe -modelsimini $ModelSimINI -del " + $Library + " 2>&1"
	$ErrorRecordFound = Invoke-Expression $InvokeExpr | Restore-NativeCommandStream | Write-ColoredModelSimVMapLine $SuppressWarnings "  " -Verbose:$EnableVerbose -Debug:$EnableDebug
	$InvokeExpr = "$VSimBinDir\vmap.exe -modelsimini $ModelSimINI " + $Library + " $DestDir\$Library 2>&1"
	$ErrorRecordFound = Invoke-Expression $InvokeExpr | Restore-NativeCommandStream | Write-ColoredModelSimVMapLine $SuppressWarnings "  " -Verbose:$EnableVerbose -Debug:$EnableDebug

	Write-Host "Compiling library '$Library' with vcom..." -ForegroundColor Yellow
	$ErrorCount += 0
	foreach ($File in $SourceFiles)
	{	Write-Host "Compiling '$File'..." -ForegroundColor DarkCyan
		$InvokeExpr = "$VSimBinDir\vcom.exe -suppress 1246 -2008 -modelsimini $ModelSimINI -work $Library " + $File + " 2>&1"
		$EnableDebug -and		(Write-Host "  Invoke-Expression $InvokeExpr | Restore-NativeCommandStream | Write-ColoredModelSimVComLine $SuppressWarnings `"  `" -Verbose:$EnableVerbose -Debug:$EnableDebug" -ForegroundColor DarkGray	) | Out-Null
		$ErrorRecordFound = Invoke-Expression $InvokeExpr | Restore-NativeCommandStream | Write-ColoredModelSimVComLine $SuppressWarnings "  " -Verbose:$EnableVerbose -Debug:$EnableDebug
		if (($LastExitCode -ne 0) -or $ErrorRecordFound)
		{	$ErrorCount += 1
			if ($HaltOnError)
			{	break		}
		}
	}

	# restore working directory
	cd $WorkingDir
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan
	Write-Host "Compiling OSVVM packages with ModelSim/QuestaSim " -NoNewline
	if ($ErrorCount -gt 0)
	{	Write-Host "[FAILED]" -ForegroundColor Red				}
	else
	{	Write-Host "[SUCCESSFUL]" -ForegroundColor Green	}
}

Exit-PrecompileScript
