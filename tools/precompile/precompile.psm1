# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
#	Authors:						Patrick Lehmann
# 
#	PowerShell Module:	The module provides common CmdLets for the library
#											pre-compilation process.
# 
# Description:
# ------------------------------------
#	This PowerShell module provides CommandLets (CmdLets) to handle the GHDL.exe
#	output streams (stdout and stderr).
#
# ==============================================================================
#	Copyright (C) 2015-2016 Patrick Lehmann
#	
#	GHDL is free software; you can redistribute it and/or modify it under
#	the terms of the GNU General Public License as published by the Free
#	Software Foundation; either version 2, or (at your option) any later
#	version.
#	
#	GHDL is distributed in the hope that it will be useful, but WITHOUT ANY
#	WARRANTY; without even the implied warranty of MERCHANTABILITY or
#	FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
#	for more details.
#	
#	You should have received a copy of the GNU General Public License
#	along with GHDL; see the file COPYING.  If not, write to the Free
#	Software Foundation, 59 Temple Place - Suite 330, Boston, MA
#	02111-1307, USA.
# ==============================================================================

[CmdletBinding()]
param(
	[Parameter(Mandatory=$true)][string]$WorkingDir
)

$Module_WorkingDir = $WorkingDir

function Exit-PrecompileScript
{		<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
		
		.PARAMETER ExitCode
		ExitCode of this script run
	#>
	[CmdletBinding()]
	param(
		[int]$ExitCode = 0
	)
	
	# restore environment
	rm env:GHDL -ErrorAction SilentlyContinue
	
	cd $Module_WorkingDir
	
	# unload modules
	Remove-Module precompile
	
	if ($ExitCode -eq 0)
	{	exit 0	}
	else
	{	Write-Host "[DEBUG]: HARD EXIT" -ForegroundColor Cyan
		exit $ExitCode
	}
}

function Resolve-Simulator
{	<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
		
		.PARAMETER All
		Undocumented
		.PARAMETER GHDL
		Undocumented
		.PARAMETER QuestaSim
		Undocumented
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][bool]$All,
		[Parameter(Mandatory=$true)][bool]$GHDL,
		[Parameter(Mandatory=$true)][bool]$QuestaSim
	)
	if ($All)
	{	return $true, $true				}
	else
	{	return $GHDL, $QuestaSim	}
}

function Resolve-VHDLVersion
{	<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
		
		.PARAMETER VHDL93
		Undocumented
		.PARAMETER VHDL2008
		Undocumented
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][bool]$VHDL93,
		[Parameter(Mandatory=$true)][bool]$VHDL2008
	)
	if (-not ($VHDL93 -and $VHDL2008))
	{	return $true, $true	}
	elseif ($VHDL93 -and -not $VHDL2008)
	{	return $true, $false	}
	elseif (-not $VHDL93 -and $VHDL2008)
	{	return $false, $true	}
}

function Get-PrecompiledDirectoryName
{	<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
		
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)
	
	$Command = "$PoCPS1 query CONFIG.DirectoryNames:PrecompiledFiles"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get precompiled directory name." -ForegroundColor Red
		Write-Host "$Result" -ForegroundColor Red
		Exit-PrecompileScript -1
	}
	return $Result
}

function Get-AlteraDirectoryName
{	<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
		
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)
	
	$Command = "$PoCPS1 query CONFIG.DirectoryNames:AlteraSpecificFiles"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get Altera directory name." -ForegroundColor Red
		Write-Host "$Result" -ForegroundColor Red
		Exit-PrecompileScript -1
	}
	return $Result
}

function Get-LatticeDirectoryName
{	<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
		
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)
	
	$Command = "$PoCPS1 query CONFIG.DirectoryNames:LatticeSpecificFiles"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get Lattice directory name." -ForegroundColor Red
		Write-Host "$Result" -ForegroundColor Red
		Exit-PrecompileScript -1
	}
	return $Result
}

function Get-XilinxDirectoryName
{	<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
		
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)
	
	$Command = "$PoCPS1 query CONFIG.DirectoryNames:XilinxSpecificFiles"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get Xilinx directory name." -ForegroundColor Red
		Write-Host "$Result" -ForegroundColor Red
		Exit-PrecompileScript -1
	}
	return $Result
}

function Get-GHDLDirectoryName
{	<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
		
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)
	
	$Command = "$PoCPS1 query CONFIG.DirectoryNames:GHDLFiles"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get GHDL directory name." -ForegroundColor Red
		Write-Host "$Result" -ForegroundColor Red
		Exit-PrecompileScript -1
	}
	return $Result
}

function Get-GHDLBinaryDirectory
{	<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
		
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)
	
	$Command = "$PoCPS1 query INSTALL.GHDL:BinaryDirectory"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get GHDL binary directory." -ForegroundColor Red
		Write-Host "         $Result" -ForegroundColor Yellow
		Write-Host "Run 'poc.ps1 configure' to configure your GHDL installation." -ForegroundColor Yellow
		Exit-PrecompileScript -1
	}
	return $Result.Replace("/", "\")
}

function Get-GHDLScriptDirectory
{	<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
		
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)
	
	$Command = "$PoCPS1 query INSTALL.GHDL:ScriptDirectory"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get GHDL script directory." -ForegroundColor Red
		Write-Host "         $Result" -ForegroundColor Yellow
		Write-Host "Run 'poc.ps1 configure' to configure your GHDL installation." -ForegroundColor Yellow
		Exit-PrecompileScript -1
	}
	return $Result.Replace("/", "\")
}

function Get-QuestaSimDirectoryName
{	<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
		
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)
	
	$Command = "$PoCPS1 query CONFIG.DirectoryNames:QuestaSimFiles"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get Mentor QuestaSim directory name." -ForegroundColor Red
		Write-Host "$Result" -ForegroundColor Red
		Exit-PrecompileScript -1
	}
	return $Result
}

function Get-ModelSimBinaryDirectory
{	<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
		
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)
	
	$Command = "$PoCPS1 query ModelSim:BinaryDirectory"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get QuestaSim/ModelSim binary directory." -ForegroundColor Red
		Write-Host "         $Result" -ForegroundColor Yellow
		Write-Host "Run 'poc.ps1 configure' to configure your Mentor QuestaSim/ModelSim installation." -ForegroundColor Yellow
		Exit-PrecompileScript -1
	}
	return $Result.Replace("/", "\")
}

function Get-QuartusInstallationDirectory
{	<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
		
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)
	
	$Command = "$PoCPS1 query INSTALL.Altera.Quartus:InstallationDirectory"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get Altera Quartus installation directory." -ForegroundColor Red
		Write-Host "         $Result" -ForegroundColor Yellow
		Write-Host "Run 'poc.ps1 configure' to configure your Altera Quartus installation." -ForegroundColor Yellow
		Exit-PrecompileScript -1
	}
	return $Result.Replace("/", "\")
}

function Get-QuartusBinaryDirectory
{	<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
		
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)
	
	$Command = "$PoCPS1 query INSTALL.Altera.Quartus:BinaryDirectory"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get Altera Quartus installation directory." -ForegroundColor Red
		Write-Host "         $Result" -ForegroundColor Yellow
		Write-Host "Run 'poc.ps1 configure' to configure your Altera Quartus installation." -ForegroundColor Yellow
		Exit-PrecompileScript -1
	}
	return $Result.Replace("/", "\")
}

function Get-DiamondInstallationDirectory
{	<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
		
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)
	
	$Command = "$PoCPS1 query INSTALL.Lattice.Diamond:InstallationDirectory"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get Lattice Diamond installation directory." -ForegroundColor Red
		Write-Host "         $Result" -ForegroundColor Yellow
		Write-Host "Run 'poc.ps1 configure' to configure your Lattice Diamond installation." -ForegroundColor Yellow
		Exit-PrecompileScript -1
	}
	return $Result.Replace("/", "\")
}

function Get-DiamondBinaryDirectory
{	<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
		
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)
	
	$Command = "$PoCPS1 query INSTALL.Lattice.Diamond:BinaryDirectory"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get Lattice Diamond installation directory." -ForegroundColor Red
		Write-Host "         $Result" -ForegroundColor Yellow
		Write-Host "Run 'poc.ps1 configure' to configure your Lattice Diamond installation." -ForegroundColor Yellow
		Exit-PrecompileScript -1
	}
	return $Result.Replace("/", "\")
}

function Get-ISEInstallationDirectory
{	<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
		
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)
	
	$Command = "$PoCPS1 query INSTALL.Xilinx.ISE:InstallationDirectory"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get Xilinx ISE installation directory." -ForegroundColor Red
		Write-Host "         $Result" -ForegroundColor Yellow
		Write-Host "Run 'poc.ps1 configure' to configure your Xilinx ISE installation." -ForegroundColor Yellow
		Exit-PrecompileScript -1
	}
	return $Result.Replace("/", "\")
}

function Get-ISEBinaryDirectory
{	<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
		
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)
	
	$Command = "$PoCPS1 query INSTALL.Xilinx.ISE:BinaryDirectory"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get Xilinx ISE installation directory." -ForegroundColor Red
		Write-Host "         $Result" -ForegroundColor Yellow
		Write-Host "Run 'poc.ps1 configure' to configure your Xilinx ISE installation." -ForegroundColor Yellow
		Exit-PrecompileScript -1
	}
	return $Result.Replace("/", "\")
}

function Get-VivadoInstallationDirectory
{	<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
		
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)
	
	$Command = "$PoCPS1 query INSTALL.Xilinx.Vivado:InstallationDirectory"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get Xilinx Vivado installation directory." -ForegroundColor Red
		Write-Host "         $Result" -ForegroundColor Yellow
		Write-Host "Run 'poc.ps1 configure' to configure your Xilinx Vivado installation." -ForegroundColor Yellow
		Exit-PrecompileScript -1
	}
	return $Result.Replace("/", "\")
}

function Get-VivadoBinaryDirectory
{	<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
		
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)
	
	$Command = "$PoCPS1 query INSTALL.Xilinx.Vivado:BinaryDirectory"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get Xilinx Vivado installation directory." -ForegroundColor Red
		Write-Host "         $Result" -ForegroundColor Yellow
		Write-Host "Run 'poc.ps1 configure' to configure your Xilinx Vivado installation." -ForegroundColor Yellow
		Exit-PrecompileScript -1
	}
	return $Result.Replace("/", "\")
}


function Initialize-DestinationDirectory
{	<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
		
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[string]$DestinationDirectory
	)

	if (-not (Test-Path $DestinationDirectory -PathType Container))
	{	mkdir $DestinationDirectory -ErrorAction SilentlyContinue | Out-Null
		if (-not $?)
		{	Write-Host "[ERROR]: Cannot create output directory '$DestinationDirectory'." -ForegroundColor Red
			Exit-PrecompileScript -1
		}
	}
	cd $DestinationDirectory
	if (-not $?)
	{	Write-Host "[ERROR]: Cannot change to output directory '$DestinationDirectory'." -ForegroundColor Red
		Exit-PrecompileScript -1
	}
}

function New-ModelSim_ini
{	<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
	#>
	$ModelSim_ini = "modelsim.ini"
	"[Library]" | Out-File $ModelSim_ini -Encoding ascii
	if (-not $?)
	{	Write-Host "[ERROR]: Cannot create initial modelsim.ini." -ForegroundColor Red
		Exit-PrecompileScript -1
	}
	if (Test-Path "..\modelsim.ini")
	{	"others = ../modelsim.ini" | Out-File $ModelSim_ini -Append -Encoding ascii		}
}

function Open-ISEEnvironment
{	<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
		
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)
	
	# load Xilinx ISE environment if not loaded before
	if (-not (Test-Path env:XILINX))
	{	$Command = "$PoCPS1 query Xilinx.ISE:SettingsFile"
		$ISE_SettingsFile = Invoke-Expression $Command
		if (($LastExitCode -ne 0) -or ($ISE_SettingsFile -eq ""))
		{	Write-Host "[ERROR]: Cannot get Xilinx ISE settings file." -ForegroundColor Red
			Write-Host "         $ISE_SettingsFile" -ForegroundColor Yellow
			Write-Host "Run 'poc.ps1 configure' to configure your Xilinx ISE installation." -ForegroundColor Yellow
			Exit-PrecompileScript -1
		}
		
		if (-not (Test-Path $ISE_SettingsFile -PathType Leaf))
		{	Write-Host "[ERROR]: Xilinx ISE is configured in PoC, but settings file '$ISE_SettingsFile' does not exist." -ForegroundColor Red
			Write-Host "Run 'poc.ps1 configure' to configure your Xilinx ISE installation." -ForegroundColor Red
			Exit-PrecompileScript -1
		}
		elseif (($ISE_SettingsFile -like "*.bat") -or ($ISE_SettingsFile -like "*.cmd"))
		{	Write-Host "Loading Xilinx ISE environment '$ISE_SettingsFile'" -ForegroundColor Yellow
			if (-not (Get-Module -ListAvailable PSCX))
			{	Write-Host "ERROR: PowerShell Community Extensions (PSCX) is not installed." -ForegroundColor Red
				Exit-PrecompileScript -1
			}
			Import-Module PSCX
			Invoke-BatchFile -path $ISE_SettingsFile
			
			if (-not (Test-Path env:XILINX))
			{	Write-Host "[ERROR]: No Xilinx ISE environment loaded." -ForegroundColor Red
				Exit-PrecompileScript -1
			}
			return
		}
		else
		{	Write-Host "[ERROR]: Xilinx ISE is configured in PoC, but settings file format is not supported." -ForegroundColor Red
			Exit-PrecompileScript -1
		}
	}
}

function Close-ISEEnvironment
{	<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
	#>
	
	Write-Host "Unloading Xilinx ISE environment..." -ForegroundColor Yellow
	$env:XILINX =						$null
	$env:XILINX_EDK =				$null
	$env:XILINX_PLANAHEAD =	$null
	$env:XILINX_DSP =				$null
}

function Open-VivadoEnvironment
{	<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
		
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)
	
	# load Xilinx Vivado environment if not loaded before
	if (-not (Test-Path env:XILINX_VIVADO))
	{	$Command = "$PoCPS1 query Xilinx.Vivado:SettingsFile"
		$Vivado_SettingsFile = Invoke-Expression $Command
		if (($LastExitCode -ne 0) -or ($Vivado_SettingsFile -eq ""))
		{	Write-Host "[ERROR]: Cannot get Xilinx Vivado settings file." -ForegroundColor Red
			Write-Host "         $Vivado_SettingsFile" -ForegroundColor Yellow
			Write-Host "Run 'poc.ps1 configure' to configure your Xilinx Vivado installation." -ForegroundColor Yellow
			Exit-PrecompileScript -1
		}
		
		if (-not (Test-Path $Vivado_SettingsFile -PathType Leaf))
		{	Write-Host "[ERROR]: Xilinx Vivado is configured in PoC, but settings file '$Vivado_SettingsFile' does not exist." -ForegroundColor Red
			Write-Host "Run 'poc.ps1 configure' to configure your Xilinx Vivado installation." -ForegroundColor Red
			Exit-PrecompileScript -1
		}
		elseif (($Vivado_SettingsFile -like "*.bat") -or ($Vivado_SettingsFile -like "*.cmd"))
		{	Write-Host "Loading Xilinx Vivado environment '$Vivado_SettingsFile'" -ForegroundColor Yellow
			if (-not (Get-Module -ListAvailable PSCX))
			{	Write-Host "ERROR: PowerShell Community Extensions (PSCX) is not installed." -ForegroundColor Red
				Exit-PrecompileScript -1
			}
			Import-Module PSCX
			Invoke-BatchFile -path $Vivado_SettingsFile
			
			if (-not (Test-Path env:XILINX_VIVADO))
			{	Write-Host "[ERROR]: No Xilinx Vivado environment loaded." -ForegroundColor Red
				Exit-PrecompileScript -1
			}
			return
		}
		else
		{	Write-Host "[ERROR]: Xilinx Vivado is configured in PoC, but settings file format is not supported." -ForegroundColor Red
			Exit-PrecompileScript -1
		}
	}
}

function Close-VivadoEnvironment
{	<#
		.SYNOPSIS
		Undocumented
		
		.DESCRIPTION
		Undocumented
	#>
	
	Write-Host "Unloading Xilinx Vivado environment..." -ForegroundColor Yellow
	$env:XILINX_VIVADO =		$null
}

function Restore-NativeCommandStream
{	<#
		.SYNOPSIS
		This CmdLet gathers multiple ErrorRecord objects and reconstructs outputs
		as a single line.
		
		.DESCRIPTION
		This CmdLet collects multiple ErrorRecord objects and emits one string
		object per line.
		
		.PARAMETER InputObject
		A object stream is required as an input.
	#>
	[CmdletBinding()]
	param(
		[Parameter(ValueFromPipeline=$true)]
		$InputObject
	)

	begin
	{	$LineRemainer = ""	}

	process
	{	if (-not $InputObject)
		{	Write-Host "Empty pipeline!"	}
		elseif ($InputObject -is [System.Management.Automation.ErrorRecord])
		{	if ($InputObject.FullyQualifiedErrorId -eq "NativeCommandError")
			{	Write-Output $InputObject.Tostring()		}
			elseif ($InputObject.FullyQualifiedErrorId -eq "NativeCommandErrorMessage")
			{	$NewLine = $LineRemainer + $InputObject.Tostring()
				while (($NewLinePos = $NewLine.IndexOf("`n")) -ne -1)
				{	Write-Output $NewLine.Substring(0, $NewLinePos)
					$NewLine = $NewLine.Substring($NewLinePos + 1)
				}
				$LineRemainer = $NewLine
			}
		}
		elseif ($InputObject -is [string])
		{	Write-Output $InputObject		}
		else
		{	Write-Host "Unsupported object in pipeline stream"		}
	}

	end
	{	if ($LineRemainer -ne "")
		{	Write-Output $LineRemainer	}
	}
}

function Write-ColoredGHDLLine
{	<#
		.SYNOPSIS
		This CmdLet colors GHDL output lines.
		
		.DESCRIPTION
		This CmdLet colors GHDL output lines. Warnings are prefixed with 'WARNING: '
		in yellow and errors are prefixed with 'ERROR: ' in red.
		
		.PARAMETER InputObject
		A object stream is required as an input.
		
		.PARAMETER SuppressWarnings
		Skip warning messages. (Show errors only.)
	#>
	[CmdletBinding()]
	param(
		[Parameter(ValueFromPipeline=$true)]
		$InputObject,
		
		[Parameter(Position=1)]
		[switch]$SuppressWarnings = $false
	)

	begin
	{	$ErrorRecordFound = $false	}
	
	process
	{	if (-not $InputObject)
		{	Write-Host "Empty pipeline!"	}
		elseif ($InputObject -is [string])
		{	if ($InputObject.Contains("warning"))
			{	if (-not $SuppressWarnings)
				{	Write-Host "WARNING: "	-NoNewline -ForegroundColor Yellow
					Write-Host $InputObject
				}
			}
			else
			{	$ErrorRecordFound	= $true
				Write-Host "ERROR: "		-NoNewline -ForegroundColor Red
				Write-Host $InputObject
			}
		}
		else
		{	Write-Host "Unsupported object in pipeline stream"		}
	}

	end
	{	$ErrorRecordFound		}
}

function Write-ColoredActiveHDLLine
{	<#
		.SYNOPSIS
		This CmdLet colors GHDL output lines.
		
		.DESCRIPTION
		This CmdLet colors GHDL output lines. Warnings are prefixed with 'WARNING: '
		in yellow and errors are prefixed with 'ERROR: ' in red.
		
		.PARAMETER InputObject
		A object stream is required as an input.
		
		.PARAMETER SuppressWarnings
		Skip warning messages. (Show errors only.)
	#>
	[CmdletBinding()]
	param(
		[Parameter(ValueFromPipeline=$true)]
		$InputObject,
		
		[Parameter(Position=1)]
		[switch]$SuppressWarnings = $false
	)

	begin
	{	$ErrorRecordFound = $false	}
	
	process
	{	if (-not $InputObject)
		{	Write-Host "Empty pipeline!"	}
		elseif ($InputObject -is [string])
		{	if ($InputObject.Contains("WARNING"))
			{	if (-not $SuppressWarnings)
				{	Write-Host "WARNING: "	-NoNewline -ForegroundColor Yellow
					Write-Host $InputObject
				}
			}
			elseif ($InputObject.Contains("ERROR"))
			{	if (-not $SuppressWarnings)
				{	Write-Host "ERROR: "	-NoNewline -ForegroundColor Red
					Write-Host $InputObject
				}
			}
			else
			{	$ErrorRecordFound	= $true
				Write-Host $InputObject
			}
		}
		else
		{	Write-Host "Unsupported object in pipeline stream"		}
	}

	end
	{	$ErrorRecordFound		}
}

Export-ModuleMember -Function 'Exit-PrecompileScript'

Export-ModuleMember -Function 'Resolve-Simulator'
Export-ModuleMember -Function 'Resolve-VHDLVersion'

# Directory names
Export-ModuleMember -Function 'Get-PrecompiledDirectoryName'
Export-ModuleMember -Function 'Get-AlteraDirectoryName'
Export-ModuleMember -Function 'Get-GHDLDirectoryName'
Export-ModuleMember -Function 'Get-LatticeDirectoryName'
Export-ModuleMember -Function 'Get-QuestaSimDirectoryName'
Export-ModuleMember -Function 'Get-XilinxDirectoryName'

# Tool directories
Export-ModuleMember -Function 'Get-QuartusInstallationDirectory'
Export-ModuleMember -Function 'Get-QuartusBinaryDirectory'
Export-ModuleMember -Function 'Get-DiamondInstallationDirectory'
Export-ModuleMember -Function 'Get-DiamondBinaryDirectory'
Export-ModuleMember -Function 'Get-GHDLBinaryDirectory'
Export-ModuleMember -Function 'Get-GHDLScriptDirectory'
Export-ModuleMember -Function 'Get-ModelSimBinaryDirectory'
Export-ModuleMember -Function 'Get-ISEInstallationDirectory'
Export-ModuleMember -Function 'Get-ISEBinaryDirectory'
Export-ModuleMember -Function 'Get-VivadoInstallationDirectory'
Export-ModuleMember -Function 'Get-VivadoBinaryDirectory'

Export-ModuleMember -Function 'Initialize-DestinationDirectory'

Export-ModuleMember -Function 'New-ModelSim_ini'

Export-ModuleMember -Function 'Open-ISEEnvironment'
Export-ModuleMember -Function 'Close-ISEEnvironment'
Export-ModuleMember -Function 'Open-VivadoEnvironment'
Export-ModuleMember -Function 'Close-VivadoEnvironment'

Export-ModuleMember -Function 'Restore-NativeCommandStream'
Export-ModuleMember -Function 'Write-ColoredGHDLLine'
Export-ModuleMember -Function 'Write-ColoredActiveHDLLine'
