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
{	<#
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
	Remove-Module precompile -Verbose:$false

	if ($ExitCode -eq 0)
	{	exit 0	}
	else
	{	Write-Host "[DEBUG]: HARD EXIT" -ForegroundColor Cyan
		exit $ExitCode
	}
}

function Resolve-VHDLVersion
{	<#
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
	if (-not $VHDL93 -and -not $VHDL2008)		# no Version selected
	{	return $true, $true	}									# => compile all versions
	elseif ($VHDL93 -and -not $VHDL2008)
	{	return $true, $false	}
	elseif (-not $VHDL93 -and $VHDL2008)
	{	return $false, $true	}
}

function Get-PrecompiledDirectoryName
{	<#
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

function Get-ActiveHDLDirectoryName
{	<#
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)

	$Command = "$PoCPS1 query CONFIG.DirectoryNames:ActiveHDLFiles"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get Aldec Active-HDL directory name." -ForegroundColor Red
		Write-Host "$Result" -ForegroundColor Red
		Exit-PrecompileScript -1
	}
	return $Result
}

function Get-RivieraPRODirectoryName
{	<#
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)

	$Command = "$PoCPS1 query CONFIG.DirectoryNames:RivieraPROFiles"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get Aldec Riviera-PRO directory name." -ForegroundColor Red
		Write-Host "$Result" -ForegroundColor Red
		Exit-PrecompileScript -1
	}
	return $Result
}

function Get-GHDLDirectoryName
{	<#
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

function Get-ModelSimDirectoryName
{	<#
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)

	$Command = "$PoCPS1 query CONFIG.DirectoryNames:ModelSimFiles"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get Mentor ModelSim directory name." -ForegroundColor Red
		Write-Host "$Result" -ForegroundColor Red
		Exit-PrecompileScript -1
	}
	return $Result
}

function Get-QuestaSimDirectoryName
{	<#
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

function Get-ActiveHDLInstallationDirectory
{	<#
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)

	$Command = "$PoCPS1 query INSTALL.ActiveHDL:InstallationDirectory"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get Active-HDL installation directory." -ForegroundColor Red
		Write-Host "         $Result" -ForegroundColor Yellow
		Write-Host "Run 'poc.ps1 configure' to configure your Active-HDL installation." -ForegroundColor Yellow
		Exit-PrecompileScript -1
	}
	return $Result.Replace("/", "\")
}

function Get-ActiveHDLBinaryDirectory
{	<#
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)

	$Command = "$PoCPS1 query INSTALL.ActiveHDL:BinaryDirectory"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get Active-HDL binary directory." -ForegroundColor Red
		Write-Host "         $Result" -ForegroundColor Yellow
		Write-Host "Run 'poc.ps1 configure' to configure your Active-HDL installation." -ForegroundColor Yellow
		Exit-PrecompileScript -1
	}
	return $Result.Replace("/", "\")
}

function Get-RivieraPROInstallationDirectory
{	<#
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)

	$Command = "$PoCPS1 query INSTALL.Aldec.RivieraPRO:InstallationDirectory"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get Aldec Riviera-PRO installation directory." -ForegroundColor Red
		Write-Host "         $Result" -ForegroundColor Yellow
		Write-Host "Run 'poc.ps1 configure' to configure your Aldec Riviera-PRO installation." -ForegroundColor Yellow
		Exit-PrecompileScript -1
	}
	return $Result.Replace("/", "\")
}

function Get-RivieraPROBinaryDirectory
{	<#
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)

	$Command = "$PoCPS1 query INSTALL.Aldec.RivieraPRO:BinaryDirectory"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get Aldec Riviera-PRO binary directory." -ForegroundColor Red
		Write-Host "         $Result" -ForegroundColor Yellow
		Write-Host "Run 'poc.ps1 configure' to configure your Aldec Riviera-PRO installation." -ForegroundColor Yellow
		Exit-PrecompileScript -1
	}
	return $Result.Replace("/", "\")
}

function Get-GHDLBinaryDirectory
{	<#
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

function Get-ModelSimInstallationDirectory
{	<#
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)

	$Command = "$PoCPS1 query INSTALL.ModelSim:InstallationDirectory"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get ModelSim installation directory." -ForegroundColor Red
		Write-Host "         $Result" -ForegroundColor Yellow
		Write-Host "Run 'poc.ps1 configure' to configure your Mentor ModelSim installation." -ForegroundColor Yellow
		Exit-PrecompileScript -1
	}
	return $Result.Replace("/", "\")
}

function Get-ModelSimBinaryDirectory
{	<#
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)

	$Command = "$PoCPS1 query INSTALL.ModelSim:BinaryDirectory"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get ModelSim binary directory." -ForegroundColor Red
		Write-Host "         $Result" -ForegroundColor Yellow
		Write-Host "Run 'poc.ps1 configure' to configure your Mentor ModelSim installation." -ForegroundColor Yellow
		Exit-PrecompileScript -1
	}
	return $Result.Replace("/", "\")
}

function Get-QuestaSimInstallationDirectory
{	<#
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)

	$Command = "$PoCPS1 query INSTALL.Mentor.QuestaSim:InstallationDirectory"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get QuestaSim installation directory." -ForegroundColor Red
		Write-Host "         $Result" -ForegroundColor Yellow
		Write-Host "Run 'poc.ps1 configure' to configure your Mentor QuestaSim installation." -ForegroundColor Yellow
		Exit-PrecompileScript -1
	}
	return $Result.Replace("/", "\")
}

function Get-QuestaSimBinaryDirectory
{	<#
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)

	$Command = "$PoCPS1 query INSTALL.Mentor.QuestaSim:BinaryDirectory"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get QuestaSim binary directory." -ForegroundColor Red
		Write-Host "         $Result" -ForegroundColor Yellow
		Write-Host "Run 'poc.ps1 configure' to configure your Mentor QuestaSim installation." -ForegroundColor Yellow
		Exit-PrecompileScript -1
	}
	return $Result.Replace("/", "\")
}

function Get-QuartusInstallationDirectory
{	<#
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)

	$Command = "$PoCPS1 query INSTALL.Quartus:InstallationDirectory"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get Quartus installation directory." -ForegroundColor Red
		Write-Host "         $Result" -ForegroundColor Yellow
		Write-Host "Run 'poc.ps1 configure' to configure your Quartus installation." -ForegroundColor Yellow
		Exit-PrecompileScript -1
	}
	return $Result.Replace("/", "\")
}

function Get-QuartusBinaryDirectory
{	<#
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PoCPS1
	)

	$Command = "$PoCPS1 query INSTALL.Quartus:BinaryDirectory"
	$Result = Invoke-Expression $Command
	if (($LastExitCode -ne 0) -or ($Result -eq ""))
	{	Write-Host "[ERROR]: Cannot get Quartus installation directory." -ForegroundColor Red
		Write-Host "         $Result" -ForegroundColor Yellow
		Write-Host "Run 'poc.ps1 configure' to configure your Quartus installation." -ForegroundColor Yellow
		Exit-PrecompileScript -1
	}
	return $Result.Replace("/", "\")
}

function Get-DiamondInstallationDirectory
{	<#
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
		.PARAMETER PoCPS1
		PoC's front-end script
	#>
	[CmdletBinding()]
	param(
		[string]$DestinationDirectory
	)
	# set default values
	$EnableDebug =		[bool]$PSCmdlet.MyInvocation.BoundParameters["Debug"]
	$EnableVerbose =	[bool]$PSCmdlet.MyInvocation.BoundParameters["Verbose"] -or $EnableDebug

	if (-not (Test-Path $DestinationDirectory -PathType Container))
	{	$EnableDebug -and		(Write-Host "  mkdir $DestinationDirectory -ErrorAction SilentlyContinue | Out-Null" -ForegroundColor DarkGray	) | Out-Null
		mkdir $DestinationDirectory -ErrorAction SilentlyContinue | Out-Null
		if (-not $?)
		{	Write-Host "[ERROR]: Cannot create output directory '$DestinationDirectory'." -ForegroundColor Red
			Exit-PrecompileScript -1
		}
	}
	$EnableDebug -and		(Write-Host "  cd $DestinationDirectory" -ForegroundColor DarkGray	) | Out-Null
	cd $DestinationDirectory
	if (-not $?)
	{	Write-Host "[ERROR]: Cannot change to output directory '$DestinationDirectory'." -ForegroundColor Red
		Exit-PrecompileScript -1
	}
}

function New-ModelSim_ini
{	[CmdletBinding()]
	param(
		[string]$ModelSim_ini = "modelsim.ini"
	)
	# set default values
	$EnableDebug =		[bool]$PSCmdlet.MyInvocation.BoundParameters["Debug"]
	$EnableVerbose =	[bool]$PSCmdlet.MyInvocation.BoundParameters["Verbose"] -or $EnableDebug

	# $ModelSim_ini = "modelsim.ini"
	$EnableVerbose -and		(Write-Host "Writing new '$ModelSim_ini'..." -ForegroundColor Gray	) | Out-Null
	"[Library]" | Out-File $ModelSim_ini -Encoding ascii
	if (-not $?)
	{	Write-Host "[ERROR]: Cannot create initial $ModelSim_ini." -ForegroundColor Red
		Exit-PrecompileScript -1
	}
	if (Test-Path "..\$ModelSim_ini")
	{	"others = ../$ModelSim_ini" | Out-File $ModelSim_ini -Append -Encoding ascii		}
}


function Open-ISEEnvironment
{	<#
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
{	Write-Host "Unloading Xilinx ISE environment..." -ForegroundColor Yellow
	$env:XILINX =						$null
	$env:XILINX_EDK =				$null
	$env:XILINX_PLANAHEAD =	$null
	$env:XILINX_DSP =				$null
}

function Open-VivadoEnvironment
{	<#
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
{	Write-Host "Unloading Xilinx Vivado environment..." -ForegroundColor Yellow
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
		.PARAMETER Indent
		Indentation string.
	#>
	[CmdletBinding()]
	param(
		[Parameter(ValueFromPipeline=$true)]
		$InputObject,

		[Parameter(Position=1)]
		[switch]$SuppressWarnings = $false,
		[Parameter(Position=2)]
		[string]$Indent = ""
	)

	begin
	{	$ErrorRecordFound = $false	}

	process
	{	if ($InputObject -is [String])
		{	if ($InputObject -match ":\d+:\d+:warning:\s")
			{	if (-not $SuppressWarnings)
				{	Write-Host "${Indent}WARNING: "	-NoNewline -ForegroundColor Yellow
					Write-Host $InputObject
				}
			}
			elseif ($InputObject -match ":\d+:\d+:\s")
			{	$ErrorRecordFound	= $true
				Write-Host "${Indent}ERROR: "		-NoNewline -ForegroundColor Red
				Write-Host $InputObject
			}
			elseif ($InputObject -match ":error:\s")
			{	$ErrorRecordFound	= $true
				Write-Host "${Indent}ERROR: "		-NoNewline -ForegroundColor Red
				Write-Host $InputObject
			}
			else
			{	Write-Host "${Indent}$InputObject"		}
		}
		else
		{	Write-Host "Unsupported object in pipeline stream"		}
	}

	end
	{	$ErrorRecordFound		}
}

function Write-ColoredActiveHDLVLibLine
{	<#
		.SYNOPSIS
		This CmdLet colors Active-HDL output lines.

		.DESCRIPTION
		This CmdLet colors Active-HDL output lines. Warnings are prefixed with 'WARNING: '
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
		[switch]$SuppressWarnings = $false,
		[Parameter(Position=2)]
		[string]$Indent = ""
	)

	begin
	{	# set default values
		$EnableDebug =			[bool]$PSCmdlet.MyInvocation.BoundParameters["Debug"]
		$EnableVerbose =		[bool]$PSCmdlet.MyInvocation.BoundParameters["Verbose"] -or $EnableDebug
		$ErrorRecordFound =	$false
	}

	process
	{	if (-not $InputObject)
		{	Write-Host "Empty pipeline!"	}
		elseif ($InputObject -is [string])
		{	if ($InputObject.StartsWith("vlib "))
			{	if ($EnableVerbose)		{	Write-Host "${Indent}$InputObject" -ForegroundColor Gray				}		}
			elseif ($InputObject.StartsWith("** Warning:") -and -not $SuppressWarnings)
			{	Write-Host "${Indent}WARNING: "	-NoNewline -ForegroundColor Yellow
				Write-Host $InputObject.Substring(12)
			}
			elseif ($InputObject.StartsWith("** Fatal:") -or $InputObject.StartsWith("# ** Fatal:"))
			{	Write-Host "${Indent}ERROR: "	-NoNewline -ForegroundColor Red
				Write-Host $InputObject.Substring(10)
			}
			elseif ($InputObject.StartsWith("** Error:") -or $InputObject.StartsWith("# ** Error:"))
			{	Write-Host "${Indent}FATAL: "	-NoNewline -ForegroundColor Red
				Write-Host $InputObject.Substring(10)
			}
			elseif ($InputObject.StartsWith("QuestaSim-64 vlib"))
			{	if ($EnableDebug)			{	Write-Host "${Indent}$InputObject" -ForegroundColor DarkGray		}		}
			else
			{	$ErrorRecordFound	= $true
				Write-Host "${Indent}$InputObject"
			}
		}
		else
		{	Write-Host "Unsupported object in pipeline stream"		}
	}

	end
	{	$ErrorRecordFound		}
}
function Write-ColoredActiveHDLVMapLine
{	<#
		.SYNOPSIS
		This CmdLet colors Active-HDL output lines.

		.DESCRIPTION
		This CmdLet colors Active-HDL output lines. Warnings are prefixed with 'WARNING: '
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
		[switch]$SuppressWarnings = $false,
		[Parameter(Position=2)]
		[string]$Indent = ""
	)

	begin
	{	# set default values
		$EnableDebug =			[bool]$PSCmdlet.MyInvocation.BoundParameters["Debug"]
		$EnableVerbose =		[bool]$PSCmdlet.MyInvocation.BoundParameters["Verbose"] -or $EnableDebug
		$ErrorRecordFound =	$false
	}

	process
	{	if (-not $InputObject)
		{	Write-Host "Empty pipeline!"	}
		elseif ($InputObject -is [string])
		{	if ($InputObject.StartsWith("vmap "))
			{	if ($EnableVerbose)		{	Write-Host "${Indent}$InputObject" -ForegroundColor Gray				}		}
			elseif ($InputObject.StartsWith("** Warning:") -and -not $SuppressWarnings)
			{	Write-Host "${Indent}WARNING: "	-NoNewline -ForegroundColor Yellow
				Write-Host $InputObject.Substring(12)
			}
			elseif ($InputObject.StartsWith("** Fatal:") -or $InputObject.StartsWith("# ** Fatal:"))
			{	Write-Host "${Indent}ERROR: "	-NoNewline -ForegroundColor Red
				Write-Host $InputObject.Substring(10)
			}
			elseif ($InputObject.StartsWith("** Error:") -or $InputObject.StartsWith("# ** Error:"))
			{	Write-Host "${Indent}FATAL: "	-NoNewline -ForegroundColor Red
				Write-Host $InputObject.Substring(10)
			}
			elseif ($InputObject.StartsWith("QuestaSim-64 vmap"))
			{	if ($EnableDebug)			{	Write-Host "${Indent}$InputObject" -ForegroundColor DarkGray		}		}
			else
			{	$ErrorRecordFound	= $true
				Write-Host "${Indent}$InputObject"
			}
		}
		else
		{	Write-Host "Unsupported object in pipeline stream"		}
	}

	end
	{	$ErrorRecordFound		}
}
function Write-ColoredActiveHDLVComLine
{	<#
		.SYNOPSIS
		This CmdLet colors ActiveHDL output lines.

		.DESCRIPTION
		This CmdLet colors Active-HDL output lines. Warnings are prefixed with 'WARNING: '
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
		[switch]$SuppressWarnings = $false,
		[Parameter(Position=2)]
		[string]$Indent = ""
	)

	begin
	{	# set default values
		$EnableDebug =		[bool]$PSCmdlet.MyInvocation.BoundParameters["Debug"]
		$EnableVerbose =	[bool]$PSCmdlet.MyInvocation.BoundParameters["Verbose"] -or $EnableDebug
		$ErrorRecordFound = $false
	}

	process
	{	if (-not $InputObject)
		{	Write-Host "Empty pipeline!"	}
		elseif ($InputObject -is [string])
		{	if ($InputObject.StartsWith("Aldec, Inc."))
			{	if ($EnableVerbose)		{	Write-Host "${Indent}$InputObject" -ForegroundColor Gray				}		}
			elseif ($InputObject.StartsWith("VLM Initialized"))
			{	if ($EnableVerbose)		{	Write-Host "${Indent}$InputObject" -ForegroundColor Gray				}		}
			elseif ($InputObject.StartsWith("COMP96 File:"))
			{	if ($EnableVerbose)		{	Write-Host "${Indent}$InputObject" -ForegroundColor Gray				}		}
			elseif ($InputObject.Contains("WARNING"))
			{	if (-not $SuppressWarnings)
				{	Write-Host "${Indent}WARNING: "	-NoNewline -ForegroundColor Yellow
					Write-Host $InputObject
				}
			}
			elseif ($InputObject.Contains("ERROR"))
			{	$ErrorRecordFound	= $true
				Write-Host "${Indent}ERROR: "	-NoNewline -ForegroundColor Red
				Write-Host $InputObject
			}
			elseif ($InputObject -match "COMP96\sCompile\s(?:success|failure)\s(\d+)\sErrors\s(\d+)\sWarnings\s+Analysis\stime\s:\s+(\d+\.\d+)\s\[(\w+)\]")
			{	if ($EnableVerbose)
				{	if ($Matches[1] -eq 0)
					{	Write-Host "${Indent}Errors: 0" -NoNewline -ForegroundColor Gray 							}
					else
					{ Write-Host "${Indent}Errors: $($Matches[1])" -NoNewline -ForegroundColor Red		}
					Write-Host ", " -NoNewline
					if ($Matches[2] -eq 0)
					{	Write-Host "Warnings: 0" -ForegroundColor Gray 																}
					else
					{ Write-Host "Warnings: $($Matches[2])" -ForegroundColor Yellow									}
				}
				else
				{	if ($Matches[1] -gt 0)	{ Write-Host "${Indent}Errors:   $($Matches[1])" -ForegroundColor Red				}
					if ($Matches[2] -gt 0)	{	Write-Host "${Indent}Warnings: $($Matches[2])" -ForegroundColor Yellow	}
				}
			}
			else
			{	Write-Host "${Indent}$InputObject"									}
		}
		else
		{	Write-Host "Unsupported object in pipeline stream"		}
	}

	end
	{	$ErrorRecordFound		}
}

function Write-ColoredModelSimVLibLine
{	<#
		.SYNOPSIS
		This CmdLet colors ModelSim output lines.

		.DESCRIPTION
		This CmdLet colors ModelSim output lines. Warnings are prefixed with 'WARNING: '
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
		[switch]$SuppressWarnings = $false,
		[Parameter(Position=2)]
		[string]$Indent = ""
	)

	begin
	{	# set default values
		$EnableDebug =			[bool]$PSCmdlet.MyInvocation.BoundParameters["Debug"]
		$EnableVerbose =		[bool]$PSCmdlet.MyInvocation.BoundParameters["Verbose"] -or $EnableDebug
		$ErrorRecordFound = $false
	}

	process
	{	if (-not $InputObject)
		{	Write-Host "Empty pipeline!"	}
		elseif ($InputObject -is [string])
		{	if ($InputObject.StartsWith("vlib "))
			{	if ($EnableVerbose)		{	Write-Host "${Indent}$InputObject" -ForegroundColor Gray				}		}
			elseif ($InputObject.StartsWith("** Warning:") -and -not $SuppressWarnings)
			{	Write-Host "${Indent}WARNING: "	-NoNewline -ForegroundColor Yellow
				Write-Host $InputObject.Substring(12)
			}
			elseif ($InputObject.StartsWith("** Fatal:") -or $InputObject.StartsWith("# ** Fatal:"))
			{	Write-Host "${Indent}ERROR: "	-NoNewline -ForegroundColor Red
				Write-Host $InputObject.Substring(10)
			}
			elseif ($InputObject.StartsWith("** Error:") -or $InputObject.StartsWith("# ** Error:"))
			{	Write-Host "${Indent}FATAL: "	-NoNewline -ForegroundColor Red
				Write-Host $InputObject.Substring(10)
			}
			elseif ($InputObject.StartsWith("QuestaSim-64 vlib"))
			{	if ($EnableDebug)			{	Write-Host "${Indent}$InputObject" -ForegroundColor DarkGray		}		}
			else
			{	$ErrorRecordFound	= $true
				Write-Host "${Indent}$InputObject"
			}
		}
		else
		{	Write-Host "Unsupported object in pipeline stream"		}
	}

	end
	{	$ErrorRecordFound		}
}
function Write-ColoredModelSimVMapLine
{	<#
		.SYNOPSIS
		This CmdLet colors ModelSim output lines.

		.DESCRIPTION
		This CmdLet colors ModelSim output lines. Warnings are prefixed with 'WARNING: '
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
		[switch]$SuppressWarnings = $false,
		[Parameter(Position=2)]
		[string]$Indent = ""
	)

	begin
	{	# set default values
		$EnableDebug =		[bool]$PSCmdlet.MyInvocation.BoundParameters["Debug"]
		$EnableVerbose =	[bool]$PSCmdlet.MyInvocation.BoundParameters["Verbose"] -or $EnableDebug
		$ErrorRecordFound = $false
	}

	process
	{	if (-not $InputObject)
		{	Write-Host "Empty pipeline!"	}
		elseif ($InputObject -is [string])
		{	if ($InputObject.StartsWith("vmap "))
			{	if ($EnableVerbose)		{	Write-Host "${Indent}$InputObject" -ForegroundColor Gray				}		}
			elseif ($InputObject.StartsWith("** Warning:") -and -not $SuppressWarnings)
			{	Write-Host "${Indent}WARNING: "	-NoNewline -ForegroundColor Yellow
				Write-Host $InputObject.Substring(12)
			}
			elseif ($InputObject.StartsWith("** Fatal:") -or $InputObject.StartsWith("# ** Fatal:"))
			{	Write-Host "${Indent}ERROR: "	-NoNewline -ForegroundColor Red
				Write-Host $InputObject.Substring(10)
			}
			elseif ($InputObject.StartsWith("** Error:") -or $InputObject.StartsWith("# ** Error:"))
			{	Write-Host "${Indent}FATAL: "	-NoNewline -ForegroundColor Red
				Write-Host $InputObject.Substring(10)
			}
			elseif ($InputObject.StartsWith("QuestaSim-64 vmap"))
			{	if ($EnableDebug)			{	Write-Host "${Indent}$InputObject" -ForegroundColor DarkGray		}		}
			else
			{	$ErrorRecordFound	= $true
				Write-Host "${Indent}$InputObject"
			}
		}
		else
		{	Write-Host "Unsupported object in pipeline stream"		}
	}

	end
	{	$ErrorRecordFound		}
}
function Write-ColoredModelSimVComLine
{	<#
		.SYNOPSIS
		This CmdLet colors ModelSim output lines.

		.DESCRIPTION
		This CmdLet colors ModelSim output lines. Warnings are prefixed with 'WARNING: '
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
		[switch]$SuppressWarnings = $false,
		[Parameter(Position=2)]
		[string]$Indent = ""
	)

	begin
	{	# set default values
		$EnableDebug =		[bool]$PSCmdlet.MyInvocation.BoundParameters["Debug"]
		$EnableVerbose =	[bool]$PSCmdlet.MyInvocation.BoundParameters["Verbose"] -or $EnableDebug
		$ErrorRecordFound = $false
	}

	process
	{	if (-not $InputObject)
		{	Write-Host "Empty pipeline!"	}
		elseif ($InputObject -is [string])
		{	if ($InputObject.StartsWith("vcom "))
			{	if ($EnableVerbose)		{	Write-Host "${Indent}$InputObject" -ForegroundColor Gray				}		}
			elseif ($InputObject.StartsWith("-- Loading "))
			{	if ($EnableVerbose)		{	Write-Host "${Indent}$InputObject" -ForegroundColor Gray				}		}
			elseif ($InputObject.StartsWith("-- Compiling "))
			{	if ($EnableVerbose)		{	Write-Host "${Indent}$InputObject" -ForegroundColor Gray				}		}
			elseif ($InputObject.StartsWith("** Warning:") -and -not $SuppressWarnings)
			{	Write-Host "${Indent}WARNING: "	-NoNewline -ForegroundColor Yellow
				Write-Host $InputObject.Substring(12)
			}
			elseif ($InputObject.StartsWith("** Fatal:") -or $InputObject.StartsWith("# ** Fatal:"))
			{	Write-Host "${Indent}ERROR: "	-NoNewline -ForegroundColor Red
				Write-Host $InputObject.Substring(10)
			}
			elseif ($InputObject.StartsWith("** Error:") -or $InputObject.StartsWith("# ** Error:"))
			{	Write-Host "${Indent}FATAL: "	-NoNewline -ForegroundColor Red
				Write-Host $InputObject.Substring(10)
			}
			elseif ($InputObject.StartsWith("Start time:"))
			{	if ($EnableVerbose)		{	Write-Host "${Indent}$InputObject" -ForegroundColor Gray				}		}
			elseif ($InputObject.StartsWith("End time:"))
			{	if ($EnableVerbose)		{	Write-Host "${Indent}$InputObject" -ForegroundColor Gray				}		}
			elseif ($InputObject.StartsWith("QuestaSim-64 vcom"))
			{	if ($EnableDebug)			{	Write-Host "${Indent}$InputObject" -ForegroundColor DarkGray		}		}
			elseif ($InputObject -match "Errors: (\d+), Warnings: (\d+)")
			{	if ($EnableVerbose)
				{	if ($Matches[1] -eq 0)
					{	Write-Host "${Indent}Errors: 0" -NoNewline -ForegroundColor Gray 							}
					else
					{ Write-Host "${Indent}Errors: $($Matches[1])" -NoNewline -ForegroundColor Red		}
					Write-Host ", " -NoNewline
					if ($Matches[2] -eq 0)
					{	Write-Host "Warnings: 0" -ForegroundColor Gray 																}
					else
					{ Write-Host "Warnings: $($Matches[2])" -ForegroundColor Yellow									}
				}
				else
				{	if ($Matches[1] -gt 0)	{ Write-Host "${Indent}Errors:   $($Matches[1])" -ForegroundColor Red				}
					if ($Matches[2] -gt 0)	{	Write-Host "${Indent}Warnings: $($Matches[2])" -ForegroundColor Yellow	}
				}
			}
			else
			{	$ErrorRecordFound	= $true
				Write-Host "${Indent}$InputObject"
			}
		}
		else
		{	Write-Host "Unsupported object in pipeline stream"		}
	}

	end
	{	$ErrorRecordFound		}
}

function Write-ColoredQuestaSimVLibLine
{	<#
		.SYNOPSIS
		This CmdLet colors QuestaSim output lines.

		.DESCRIPTION
		This CmdLet colors QuestaSim output lines. Warnings are prefixed with 'WARNING: '
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
		[switch]$SuppressWarnings = $false,
		[Parameter(Position=2)]
		[string]$Indent = ""
	)

	begin
	{	# set default values
		$EnableDebug =		[bool]$PSCmdlet.MyInvocation.BoundParameters["Debug"]
		$EnableVerbose =	[bool]$PSCmdlet.MyInvocation.BoundParameters["Verbose"] -or $EnableDebug
		$ErrorRecordFound = $false
	}

	process
	{	if (-not $InputObject)
		{	Write-Host "Empty pipeline!"	}
		elseif ($InputObject -is [string])
		{	if ($InputObject.StartsWith("vlib "))
			{	if ($EnableVerbose)		{	Write-Host "${Indent}$InputObject" -ForegroundColor Gray				}		}
			elseif ($InputObject.StartsWith("** Warning:") -and -not $SuppressWarnings)
			{	Write-Host "${Indent}WARNING: "	-NoNewline -ForegroundColor Yellow
				Write-Host $InputObject.Substring(12)
			}
			elseif ($InputObject.StartsWith("** Fatal:") -or $InputObject.StartsWith("# ** Fatal:"))
			{	Write-Host "${Indent}ERROR: "	-NoNewline -ForegroundColor Red
				Write-Host $InputObject.Substring(10)
			}
			elseif ($InputObject.StartsWith("** Error:") -or $InputObject.StartsWith("# ** Error:"))
			{	Write-Host "${Indent}FATAL: "	-NoNewline -ForegroundColor Red
				Write-Host $InputObject.Substring(10)
			}
			elseif ($InputObject.StartsWith("QuestaSim-64 vlib"))
			{	if ($EnableDebug)			{	Write-Host "${Indent}$InputObject" -ForegroundColor DarkGray		}		}
			else
			{	$ErrorRecordFound	= $true
				Write-Host "${Indent}$InputObject"
			}
		}
		else
		{	Write-Host "Unsupported object in pipeline stream"		}
	}

	end
	{	$ErrorRecordFound		}
}
function Write-ColoredQuestaSimVMapLine
{	<#
		.SYNOPSIS
		This CmdLet colors QuestaSim output lines.

		.DESCRIPTION
		This CmdLet colors QuestaSim output lines. Warnings are prefixed with 'WARNING: '
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
		[switch]$SuppressWarnings = $false,
		[Parameter(Position=2)]
		[string]$Indent = ""
	)

	begin
	{	# set default values
		$EnableDebug =		[bool]$PSCmdlet.MyInvocation.BoundParameters["Debug"]
		$EnableVerbose =	[bool]$PSCmdlet.MyInvocation.BoundParameters["Verbose"] -or $EnableDebug
		$ErrorRecordFound = $false
	}

	process
	{	if (-not $InputObject)
		{	Write-Host "Empty pipeline!"	}
		elseif ($InputObject -is [string])
		{	if ($InputObject.StartsWith("vmap "))
			{	if ($EnableVerbose)		{	Write-Host "${Indent}$InputObject" -ForegroundColor Gray				}		}
			elseif ($InputObject.StartsWith("** Warning:") -and -not $SuppressWarnings)
			{	Write-Host "${Indent}WARNING: "	-NoNewline -ForegroundColor Yellow
				Write-Host $InputObject.Substring(12)
			}
			elseif ($InputObject.StartsWith("** Fatal:") -or $InputObject.StartsWith("# ** Fatal:"))
			{	Write-Host "${Indent}ERROR: "	-NoNewline -ForegroundColor Red
				Write-Host $InputObject.Substring(10)
			}
			elseif ($InputObject.StartsWith("** Error:") -or $InputObject.StartsWith("# ** Error:"))
			{	Write-Host "${Indent}FATAL: "	-NoNewline -ForegroundColor Red
				Write-Host $InputObject.Substring(10)
			}
			elseif ($InputObject.StartsWith("QuestaSim-64 vmap"))
			{	if ($EnableDebug)			{	Write-Host "${Indent}$InputObject" -ForegroundColor DarkGray		}		}
			else
			{	$ErrorRecordFound	= $true
				Write-Host "${Indent}$InputObject"
			}
		}
		else
		{	Write-Host "Unsupported object in pipeline stream"		}
	}

	end
	{	$ErrorRecordFound		}
}
function Write-ColoredQuestaSimVComLine
{	<#
		.SYNOPSIS
		This CmdLet colors QuestaSim output lines.

		.DESCRIPTION
		This CmdLet colors QuestaSim output lines. Warnings are prefixed with 'WARNING: '
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
		[switch]$SuppressWarnings = $false,
		[Parameter(Position=2)]
		[string]$Indent = ""
	)

	begin
	{	# set default values
		$EnableDebug =		[bool]$PSCmdlet.MyInvocation.BoundParameters["Debug"]
		$EnableVerbose =	[bool]$PSCmdlet.MyInvocation.BoundParameters["Verbose"] -or $EnableDebug
		$ErrorRecordFound = $false
	}

	process
	{	if (-not $InputObject)
		{	Write-Host "Empty pipeline!"	}
		elseif ($InputObject -is [string])
		{	if ($InputObject.StartsWith("vcom "))
			{	if ($EnableVerbose)		{	Write-Host "${Indent}$InputObject" -ForegroundColor Gray				}		}
			elseif ($InputObject.StartsWith("-- Loading "))
			{	if ($EnableVerbose)		{	Write-Host "${Indent}$InputObject" -ForegroundColor Gray				}		}
			elseif ($InputObject.StartsWith("-- Compiling "))
			{	if ($EnableVerbose)		{	Write-Host "${Indent}$InputObject" -ForegroundColor Gray				}		}
			elseif ($InputObject.StartsWith("** Warning:") -and -not $SuppressWarnings)
			{	Write-Host "${Indent}WARNING: "	-NoNewline -ForegroundColor Yellow
				Write-Host $InputObject.Substring(12)
			}
			elseif ($InputObject.StartsWith("** Fatal:") -or $InputObject.StartsWith("# ** Fatal:"))
			{	Write-Host "${Indent}ERROR: "	-NoNewline -ForegroundColor Red
				Write-Host $InputObject.Substring(10)
			}
			elseif ($InputObject.StartsWith("** Error:") -or $InputObject.StartsWith("# ** Error:"))
			{	Write-Host "${Indent}FATAL: "	-NoNewline -ForegroundColor Red
				Write-Host $InputObject.Substring(10)
			}
			elseif ($InputObject.StartsWith("Start time:"))
			{	if ($EnableVerbose)		{	Write-Host "${Indent}$InputObject" -ForegroundColor Gray				}		}
			elseif ($InputObject.StartsWith("End time:"))
			{	if ($EnableVerbose)		{	Write-Host "${Indent}$InputObject" -ForegroundColor Gray				}		}
			elseif ($InputObject.StartsWith("QuestaSim-64 vcom"))
			{	if ($EnableDebug)			{	Write-Host "${Indent}$InputObject" -ForegroundColor DarkGray		}		}
			elseif ($InputObject -match "Errors: (\d+), Warnings: (\d+)")
			{	if ($EnableVerbose)
				{	if ($Matches[1] -eq 0)
					{	Write-Host "${Indent}Errors: 0" -NoNewline -ForegroundColor Gray 							}
					else
					{ Write-Host "${Indent}Errors: $($Matches[1])" -NoNewline -ForegroundColor Red		}
					Write-Host ", " -NoNewline
					if ($Matches[2] -eq 0)
					{	Write-Host "Warnings: 0" -ForegroundColor Gray 																}
					else
					{ Write-Host "Warnings: $($Matches[2])" -ForegroundColor Yellow									}
				}
				else
				{	if ($Matches[1] -gt 0)	{ Write-Host "${Indent}Errors:   $($Matches[1])" -ForegroundColor Red				}
					if ($Matches[2] -gt 0)	{	Write-Host "${Indent}Warnings: $($Matches[2])" -ForegroundColor Yellow	}
				}
			}
			else
			{	$ErrorRecordFound	= $true
				Write-Host "${Indent}$InputObject"
			}
		}
		else
		{	Write-Host "Unsupported object in pipeline stream"		}
	}

	end
	{	$ErrorRecordFound		}
}

Export-ModuleMember -Function 'Exit-PrecompileScript'

Export-ModuleMember -Function 'Resolve-VHDLVersion'

# Directory names
Export-ModuleMember -Function 'Get-PrecompiledDirectoryName'
Export-ModuleMember -Function 'Get-AlteraDirectoryName'
Export-ModuleMember -Function 'Get-IntelDirectoryName'
Export-ModuleMember -Function 'Get-LatticeDirectoryName'
Export-ModuleMember -Function 'Get-XilinxDirectoryName'
Export-ModuleMember -Function 'Get-ActiveHDLDirectoryName'
Export-ModuleMember -Function 'Get-RivieraPRODirectoryName'
Export-ModuleMember -Function 'Get-GHDLDirectoryName'
Export-ModuleMember -Function 'Get-ModelSimDirectoryName'
Export-ModuleMember -Function 'Get-QuestaSimDirectoryName'

# Tool directories
Export-ModuleMember -Function 'Get-ActiveHDLInstallationDirectory'
Export-ModuleMember -Function 'Get-ActiveHDLBinaryDirectory'
Export-ModuleMember -Function 'Get-RivieraPROInstallationDirectory'
Export-ModuleMember -Function 'Get-RivieraPROBinaryDirectory'
Export-ModuleMember -Function 'Get-QuartusInstallationDirectory'
Export-ModuleMember -Function 'Get-QuartusBinaryDirectory'
Export-ModuleMember -Function 'Get-DiamondInstallationDirectory'
Export-ModuleMember -Function 'Get-DiamondBinaryDirectory'
Export-ModuleMember -Function 'Get-GHDLBinaryDirectory'
Export-ModuleMember -Function 'Get-GHDLScriptDirectory'
Export-ModuleMember -Function 'Get-ModelSimInstallationDirectory'
Export-ModuleMember -Function 'Get-ModelSimBinaryDirectory'
Export-ModuleMember -Function 'Get-QuestaSimInstallationDirectory'
Export-ModuleMember -Function 'Get-QuestaSimBinaryDirectory'
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
Export-ModuleMember -Function 'Write-ColoredActiveHDLVLibLine'
Export-ModuleMember -Function 'Write-ColoredActiveHDLVMapLine'
Export-ModuleMember -Function 'Write-ColoredActiveHDLVComLine'
Export-ModuleMember -Function 'Write-ColoredGHDLLine'
Export-ModuleMember -Function 'Write-ColoredModelSimVLibLine'
Export-ModuleMember -Function 'Write-ColoredModelSimVMapLine'
Export-ModuleMember -Function 'Write-ColoredModelSimVComLine'
Export-ModuleMember -Function 'Write-ColoredQuestaSimVLibLine'
Export-ModuleMember -Function 'Write-ColoredQuestaSimVMapLine'
Export-ModuleMember -Function 'Write-ColoredQuestaSimVComLine'
