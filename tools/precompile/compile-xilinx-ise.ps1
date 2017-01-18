# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
#	Authors:            Patrick Lehmann
#
#	PowerShell Script:  Compile Xilinx's simulation libraries
#
# Description:
# ------------------------------------
#	This PowerShell script compiles Xilinx's ISE simulation libraries into a local
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
# This CmdLet pre-compiles the simulation libraries from Xilinx ISE.
#
# .DESCRIPTION
# This CmdLet:
#   (1) Creates a sub-directory 'xilinx-ise' in the current working directory
#   (2) Compiles all Xilinx ISE simulation libraries and packages for
#       o Active-HDL
#       o Riviera-PRO
#       o GHDL
#       o ModelSim
#       o QuestaSim
#   (3) Creates a symlink 'xilinx' -> 'xilinx-ise'
#
[CmdletBinding()]
param(
	# Pre-compile all libraries and packages for all simulators.
	[switch]$All =				$false,

	# Pre-compile the Xilinx ISE libraries for Active-HDL.
	[switch]$ActiveHDL =	$false,
	# Pre-compile the Xilinx ISE libraries for Riviera-PRO.
	[switch]$RivieraPRO =	$false,
	# Pre-compile the Xilinx ISE libraries for GHDL.
	[switch]$GHDL =				$false,
	# Pre-compile the Xilinx ISE libraries for ModelSim.
	[switch]$ModelSim =		$false,
	# Pre-compile the Xilinx ISE libraries for QuestaSim.
	[switch]$QuestaSim =			$false,

	# Change the 'xilinx' symlink to 'xilinx-ise'.
	[switch]$ReLink =			$false,

	# Set VHDL Standard to '93.
	[switch]$VHDL93 =			$false,
	# Set VHDL Standard to '08.
	[switch]$VHDL2008 =		$false,

	# Clean up directory before analyzing.
	[switch]$Clean =			$false,

	# Show the embedded help page(s).
	[switch]$Help =				$false
)

$PoCRootDir =		"\..\.."

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
$XilinxDirName =		Get-XilinxDirectoryName $PoCPS1
$XilinxDirName2 =		"$XilinxDirName-ise"

# GHDL
# ==============================================================================
if ($GHDL)
{	Write-Host "Pre-compiling Xilinx's simulation libraries for GHDL" -ForegroundColor Cyan
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan

	$VHDL93,$VHDL2008 = Resolve-VHDLVersion $VHDL93 $VHDL2008
	$GHDLBinDir =				Get-GHDLBinaryDirectory $PoCPS1
	$GHDLScriptDir =		Get-GHDLScriptDirectory $PoCPS1
	$GHDLDirName =			Get-GHDLDirectoryName $PoCPS1

	# Assemble output directory
	$DestDir = "$PoCRootDir\$PrecompiledDir\$GHDLDirName"
	# Create and change to destination directory
	Initialize-DestinationDirectory $DestDir -Verbose:$EnableVerbose -Debug:$EnableDebug

	$GHDLXilinxScript = "$GHDLScriptDir\compile-xilinx-ise.ps1"
	if (-not (Test-Path $GHDLXilinxScript -PathType Leaf))
	{ Write-Host "[ERROR]: Xilinx compile script '$GHDLXilinxScript' from GHDL not found." -ForegroundColor Red
		Exit-PrecompileScript -1
	}

	$ISEInstallDir =	Get-ISEInstallationDirectory $PoCPS1
	$SourceDir =			"$ISEInstallDir\ISE\vhdl\src"

	# export GHDL environment variable if not allready set
	if (-not (Test-Path env:GHDL))

	{	$env:GHDL = $GHDLBinDir		}
	if ($VHDL93)
	{	$Command = "$GHDLXilinxScript -All -VHDL93 -Source $SourceDir -Output $DestDir\$XilinxDirName2 -Verbose:`$$EnableVerbose -Debug:`$$EnableDebug"
		Invoke-Expression $Command
		if ($LastExitCode -ne 0)
		{	Write-Host "[ERROR]: Error while compiling Xilinx ISE libraries." -ForegroundColor Red
			Exit-PrecompileScript -1
		}
	}
	if ($VHDL2008)
	{	$Command = "$GHDLXilinxScript -All -VHDL2008 -Source $SourceDir -Output $DestDir\$XilinxDirName2 -Verbose:`$$EnableVerbose -Debug:`$$EnableDebug"
		Invoke-Expression $Command
		if ($LastExitCode -ne 0)
		{	Write-Host "[ERROR]: Error while compiling Xilinx ISE libraries." -ForegroundColor Red
			Exit-PrecompileScript -1
		}
	}

	if (Test-Path $XilinxDirName -PathType Leaf)
	{	rm $XilinxDirName -ErrorAction SilentlyContinue		}
	# New-Symlink $XilinxDirName2 $XilinxDirName -ErrorAction SilentlyContinue
	# if ($LastExitCode -ne 0)
	# {	Write-Host "[ERROR]: While creating a symlink. Not enough rights?" -ForegroundColor Red
		# Exit-PrecompileScript -1
	# }

	# restore working directory
	cd $WorkingDir
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan
}

# Supported pre-compilations by Xilinx ISE (Active-HDL, Riviera-PRO, ModelSim, QuestaSim)
# ==============================================================================
foreach ($tool in @("ActiveHDL", "RivieraPRO", "ModelSim", "QuestaSim"))
{	if (Get-Variable $tool -ValueOnly)
	{	switch ($tool)
		{	"ActiveHDL"
			{	Write-Host "Pre-compiling Xilinx's simulation libraries for Active-HDL..." -ForegroundColor Cyan
				$ToolBinDir =			Get-ActiveHDLBinaryDirectory $PoCPS1
				$ToolDirName =		Get-ActiveHDLDirectoryName $PoCPS1
				$Simulator =			"active_hdl"
				break;
			}
			"RivieraPRO"
			{	Write-Host "Pre-compiling Xilinx's simulation libraries for Riviera-PRO..." -ForegroundColor Cyan
				$ToolBinDir =			Get-RivieraPROBinaryDirectory $PoCPS1
				$ToolDirName =		Get-RivieraPRODirectoryName $PoCPS1
				$Simulator =			"riviera"
				break;
			}
			"ModelSim"
			{	Write-Host "Pre-compiling Xilinx's simulation libraries for ModelSim..." -ForegroundColor Cyan
				$ToolBinDir =			Get-ModelSimBinaryDirectory $PoCPS1
				$ToolDirName =		Get-ModelSimDirectoryName $PoCPS1
				$Simulator =			"mti_se"  # mti_se   mti_pe    mti_de
				break;
			}
			"QuestaSim"
			{	Write-Host "Pre-compiling Xilinx's simulation libraries for QuestaSim..." -ForegroundColor Cyan
				$ToolBinDir =			Get-QuestaSimBinaryDirectory $PoCPS1
				$ToolDirName =		Get-QuestaSimDirectoryName $PoCPS1
				$Simulator =			"questa"
				break;
			}
		}
		Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan

		# Assemble output directory
		$DestDir="$PoCRootDir\$PrecompiledDir\$ToolDirName\$XilinxDirName2"
		# Create and change to destination directory
		Initialize-DestinationDirectory $DestDir -Verbose:$EnableVerbose -Debug:$EnableDebug

		$ISEBinDir = 		Get-ISEBinaryDirectory $PoCPS1
		$ISE_compxlib =	"$ISEBinDir\compxlib.exe"
		Open-ISEEnvironment $PoCPS1

		switch ($tool)
		{	"ModelSim"
			{	New-ModelSim_ini	}
			"QuestaSim"
			{	New-ModelSim_ini	}
		}

		$Language =						"all"
		$TargetArchitecture =	"all"

		$Command = "$ISE_compxlib -64bit -s $Simulator -l $Language -dir $DestDir -p $ToolBinDir -arch $TargetArchitecture -lib unisim -lib simprim -lib xilinxcorelib -intstyle ise"
		$EnableDebug -and		(Write-Host "  $Command" -ForegroundColor DarkGray	) | Out-Null
		Invoke-Expression $Command
		if (-not $?)
		{	Write-Host "[ERROR]: Error while compiling Xilinx ISE libraries." -ForegroundColor Red
			Exit-PrecompileScript -1
		}

		rm $XilinxDirName -ErrorAction SilentlyContinue
		# New-Symlink $XilinxDirName2 $XilinxDirName -ErrorAction SilentlyContinue
		# if ($LastExitCode -ne 0)
		# {	Write-Host "[ERROR]: While creating a symlink. Not enough rights?" -ForegroundColor Red
			# Exit-PrecompileScript -1
		# }

		Close-ISEEnvironment

		# restore working directory
		cd $WorkingDir
		Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan
	}
}

Write-Host "[COMPLETE]" -ForegroundColor Green

Exit-PrecompileScript
