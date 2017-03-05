# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
#	Authors:            Patrick Lehmann
#
#	PowerShell Script:  Compile UVVM's simulation packages
#
# Description:
# ------------------------------------
#	This PowerShell script compiles UVVM's simulation packages into a local
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
# This CmdLet pre-compiles the simulation libraries from UVVM.
#
# .DESCRIPTION
# This CmdLet:
#   (1) Creates a sub-directory 'uvvm' in the current working directory
#   (2) Compiles all UVVM simulation libraries and packages for
#       o Active-HDL
#       o GHDL
#       o QuestaSim
#
[CmdletBinding()]
param(
	# Pre-compile all libraries and packages for all simulators.
	[switch]$All =				$false,

	# Pre-compile the UVVM libraries for Active-HDL.
	[switch]$ActiveHDL =	$false,
	# Pre-compile the UVVM libraries for Riviera-PRO.
	[switch]$RivieraPRO =	$false,
	# Pre-compile the UVVM libraries for GHDL.
	[switch]$GHDL =				$false,
	# Pre-compile the UVVM libraries for ModelSim.
	[switch]$ModelSim =		$false,
	# Pre-compile the UVVM libraries for QuestaSim.
	[switch]$QuestaSim =	$false,

	# Clean up directory before analyzing.
	[switch]$Clean =			$false,

	# Show the embedded help page(s).
	[switch]$Help =				$false
)

$PoCRootDir =						"\..\.."
$UVVMSourceDirectory =	"lib\uvvm"

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
$UVVMDirName =			"uvvm"
$SourceDirectory =	"$PoCRootDir\$UVVMSourceDirectory"

$UVVM_Util_Files = @(
	"uvvm_util\src\types_pkg.vhd",
	"uvvm_util\src\adaptations_pkg.vhd",
	"uvvm_util\src\string_methods_pkg.vhd",
	"uvvm_util\src\protected_types_pkg.vhd",
	"uvvm_util\src\hierarchy_linked_list_pkg.vhd",
	"uvvm_util\src\alert_hierarchy_pkg.vhd",
	"uvvm_util\src\license_pkg.vhd",
	"uvvm_util\src\methods_pkg.vhd",
	"uvvm_util\src\bfm_common_pkg.vhd",
	"uvvm_util\src\uvvm_util_context.vhd"
)
$UVVM_VVC_Files = @(
	"uvvm_vvc_framework\src\ti_vvc_framework_support_pkg.vhd",
	"uvvm_vvc_framework\src\ti_generic_queue_pkg.vhd",
	"uvvm_vvc_framework\src\ti_data_queue_pkg.vhd",
	"uvvm_vvc_framework\src\ti_data_fifo_pkg.vhd",
	"uvvm_vvc_framework\src\ti_data_stack_pkg.vhd"
	"uvvm_vvc_framework\src\ti_uvvm_engine.vhd"
)
$VIP_Files = @{
	"AXILite" = @{
		"Library" =	"bitvis_vip_axilite";
		"Files" =		@(
			"bitvis_vip_axilite\src\axilite_bfm_pkg.vhd",
			"bitvis_vip_axilite\src\vvc_cmd_pkg.vhd",
			"uvvm_vvc_framework\src_target_dependent\td_target_support_pkg.vhd",
			"uvvm_vvc_framework\src_target_dependent\td_vvc_framework_common_methods_pkg.vhd",
			"bitvis_vip_axilite\src\vvc_methods_pkg.vhd",
			"uvvm_vvc_framework\src_target_dependent\td_queue_pkg.vhd",
			"uvvm_vvc_framework\src_target_dependent\td_vvc_entity_support_pkg.vhd",
			"bitvis_vip_axilite\src\axilite_vvc.vhd"
		)
	};
	"AXIStream" = @{
		"Library" =	"bitvis_vip_axistream";
		"Files" =		@(
			"bitvis_vip_axistream\src\axistream_bfm_pkg.vhd",
			"bitvis_vip_axistream\src\vvc_cmd_pkg.vhd",
			"uvvm_vvc_framework\src_target_dependent\td_target_support_pkg.vhd",
			"uvvm_vvc_framework\src_target_dependent\td_vvc_framework_common_methods_pkg.vhd",
			"bitvis_vip_axistream\src\vvc_methods_pkg.vhd",
			"uvvm_vvc_framework\src_target_dependent\td_queue_pkg.vhd",
			"uvvm_vvc_framework\src_target_dependent\td_vvc_entity_support_pkg.vhd",
			"bitvis_vip_axistream\src\axistream_vvc.vhd"
		)
	};
	"I2C" = @{
		"Library" =	"bitvis_vip_i2c";
		"Files" =		@(
			"bitvis_vip_i2c\src\i2c_bfm_pkg.vhd",
			"bitvis_vip_i2c\src\vvc_cmd_pkg.vhd",
			"uvvm_vvc_framework\src_target_dependent\td_target_support_pkg.vhd",
			"uvvm_vvc_framework\src_target_dependent\td_vvc_framework_common_methods_pkg.vhd",
			"bitvis_vip_i2c\src\vvc_methods_pkg.vhd",
			"uvvm_vvc_framework\src_target_dependent\td_queue_pkg.vhd",
			"uvvm_vvc_framework\src_target_dependent\td_vvc_entity_support_pkg.vhd",
			"bitvis_vip_i2c\src\i2c_vvc.vhd"
		)
	};
	"SBI" = @{
		"Library" =	"bitvis_vip_sbi";
		"Files" =		@(
			"bitvis_vip_sbi/src/sbi_bfm_pkg.vhd",
			"bitvis_vip_sbi/src/vvc_cmd_pkg.vhd",
			"uvvm_vvc_framework/src_target_dependent/td_target_support_pkg.vhd",
			"uvvm_vvc_framework/src_target_dependent/td_vvc_framework_common_methods_pkg.vhd",
			"bitvis_vip_sbi/src/vvc_methods_pkg.vhd",
			"uvvm_vvc_framework/src_target_dependent/td_queue_pkg.vhd",
			"uvvm_vvc_framework/src_target_dependent/td_vvc_entity_support_pkg.vhd",
			"bitvis_vip_sbi/src/sbi_vvc.vhd"
		)
	};
	"UART" = @{
		"Library" =	"bitvis_vip_uart";
		"Files" =		@(
			"bitvis_vip_uart\src\uart_bfm_pkg.vhd",
			"bitvis_vip_uart\src\vvc_cmd_pkg.vhd",
			"uvvm_vvc_framework\src_target_dependent\td_target_support_pkg.vhd",
			"uvvm_vvc_framework\src_target_dependent\td_vvc_framework_common_methods_pkg.vhd",
			"bitvis_vip_uart\src\vvc_methods_pkg.vhd",
			"uvvm_vvc_framework\src_target_dependent\td_queue_pkg.vhd",
			"uvvm_vvc_framework\src_target_dependent\td_vvc_entity_support_pkg.vhd",
			"bitvis_vip_uart\src\uart_rx_vvc.vhd",
			"bitvis_vip_uart\src\uart_tx_vvc.vhd",
			"bitvis_vip_uart\src\uart_vvc.vhd"
		)
	}
}

# GHDL
# ==============================================================================
if ($GHDL)
{	Write-Host "Pre-compiling UVVM's simulation libraries for GHDL" -ForegroundColor Cyan
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan

	$GHDLBinDir =			Get-GHDLBinaryDirectory $PoCPS1
	$GHDLScriptDir =	Get-GHDLScriptDirectory $PoCPS1
	$GHDLDirName =		Get-GHDLDirectoryName $PoCPS1

	# Assemble output directory
	$DestDir = "$PoCRootDir\$PrecompiledDir\$GHDLDirName\$UVVMDirName"
	# Create and change to destination directory
	Initialize-DestinationDirectory $DestDir -Verbose:$EnableVerbose -Debug:$EnableDebug

	$GHDLUVVMScript = "$GHDLScriptDir\compile-uvvm.ps1"
	if (-not (Test-Path $GHDLUVVMScript -PathType Leaf))
	{ Write-Host "[ERROR]: UVVM compile script '$GHDLUVVMScript' from GHDL not found." -ForegroundColor Red
		Exit-PrecompileScript -1
	}

	# export GHDL environment variable if not allready set
	if (-not (Test-Path env:GHDL))
	{	$env:GHDL = $GHDLBinDir		}

	$Command = "$GHDLUVVMScript -All -SuppressWarnings -Source $SourceDirectory -Output $DestDir -Verbose:`$$EnableVerbose -Debug:`$$EnableDebug"
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
{	Write-Host "Pre-compiling UVVM's simulation libraries for Active-HDL" -ForegroundColor Cyan
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan

	$ActiveHDLBinDir =		Get-ActiveHDLBinaryDirectory $PoCPS1
	$ActiveHDLDirName =	Get-ActiveHDLDirectoryName $PoCPS1

	# Assemble output directory
	$ActiveHDLDestDir =	"$PoCRootDir\$PrecompiledDir\$ActiveHDLDirName"
	$DestDir =			"$ActiveHDLDestDir\$UVVMDirName"
	$ModelSimINI =	"$ActiveHDLDestDir\modelsim.ini"
	# Create and change to destination directory
	Initialize-DestinationDirectory $DestDir -Verbose:$EnableVerbose -Debug:$EnableDebug


	$Library = "uvvm_util"
	$SourceFiles = $UVVM_Util_Files | % { "$SourceDirectory\$_" }

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


	$Library = "uvvm_vvc_framework"
	$SourceFiles = $UVVM_VVC_Files | % { "$SourceDirectory\$_" }

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

	foreach ($vip in $VIP_Files.Keys)
	{	$Library =			$VIP_Files[$vip]["Library"]
		$SourceFiles =	$VIP_Files[$vip]["Files"] | % { "$SourceDirectory\$_" }

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
	}

	# restore working directory
	cd $WorkingDir
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan
	Write-Host "Compiling UVVM packages with Active-HDL " -NoNewline
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
if ($ModelSim)
{	Write-Host "Pre-compiling UVVM's simulation libraries for QuestaSim" -ForegroundColor Cyan
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan

	$VSimBinDir =		Get-ModelSimBinaryDirectory $PoCPS1
	$VSimDirName =	Get-ModelSimDirectoryName $PoCPS1

	# Assemble output directory
	$VSimDestDir =	"$PoCRootDir\$PrecompiledDir\$VSimDirName"
	$DestDir =			"$VSimDestDir\$UVVMDirName"
	$ModelSimINI =	"$VSimDestDir\modelsim.ini"
	# Create and change to destination directory
	Initialize-DestinationDirectory $DestDir -Verbose:$EnableVerbose -Debug:$EnableDebug


	$Library = "uvvm_util"
	$SourceFiles = $UVVM_Util_Files | % { "$SourceDirectory\$_" }

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
		$InvokeExpr = "$VSimBinDir\vcom.exe -suppress 1346,1236 -2008 -modelsimini $ModelSimINI -work $Library " + $File + " 2>&1"
		$ErrorRecordFound = Invoke-Expression $InvokeExpr | Restore-NativeCommandStream | Write-ColoredModelSimVComLine $SuppressWarnings "  " -Verbose:$EnableVerbose -Debug:$EnableDebug
		if (($LastExitCode -ne 0) -or $ErrorRecordFound)
		{	$ErrorCount += 1
			if ($HaltOnError)
			{	break		}
		}
	}


	$Library = "uvvm_vvc_framework"
	$SourceFiles = $UVVM_VVC_Files | % { "$SourceDirectory\$_" }

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
		$InvokeExpr = "$VSimBinDir\vcom.exe -suppress 1346,1236 -2008 -modelsimini $ModelSimINI -work $Library " + $File + " 2>&1"
		$ErrorRecordFound = Invoke-Expression $InvokeExpr | Restore-NativeCommandStream | Write-ColoredModelSimVComLine $SuppressWarnings "  " -Verbose:$EnableVerbose -Debug:$EnableDebug
		if (($LastExitCode -ne 0) -or $ErrorRecordFound)
		{	$ErrorCount += 1
			if ($HaltOnError)
			{	break		}
		}
	}


	foreach ($vip in $VIP_Files.Keys)
	{	$Library =			$VIP_Files[$vip]["Library"]
		$SourceFiles =	$VIP_Files[$vip]["Files"] | % { "$SourceDirectory\$_" }

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
			$InvokeExpr = "$VSimBinDir\vcom.exe -suppress 1346,1236 -2008 -modelsimini $ModelSimINI -work $Library " + $File + " 2>&1"
			$ErrorRecordFound = Invoke-Expression $InvokeExpr | Restore-NativeCommandStream | Write-ColoredModelSimVComLine $SuppressWarnings "  " -Verbose:$EnableVerbose -Debug:$EnableDebug
			if (($LastExitCode -ne 0) -or $ErrorRecordFound)
			{	$ErrorCount += 1
				if ($HaltOnError)
				{	break		}
			}
		}
	}


	# restore working directory
	cd $WorkingDir
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan
	Write-Host "Compiling UVVM packages with ModelSim/QuestaSim " -NoNewline
	if ($ErrorCount -gt 0)
	{	Write-Host "[FAILED]" -ForegroundColor Red				}
	else
	{	Write-Host "[SUCCESSFUL]" -ForegroundColor Green	}
}


Exit-PrecompileScript
