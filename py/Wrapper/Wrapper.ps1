# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
#	Authors:						Patrick Lehmann
# 
#	PowerShell Script:	Wrapper Script to execute a given Python script
# 
# Description:
# ------------------------------------
#	This is a bash script (callable) which:
#		- checks for a minimum installed Python version
#		- loads vendor environments before executing the Python programs
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

# script settings
$PoC_ExitCode = 0
$PoC_WorkingDir =				Get-Location
$PoC_PythonScriptDir =	"py"
$PoC_FrontEnd =					"$PoC_RootDir\$PoC_PythonScriptDir\PoC.py"
$PoC_WrapperDirectory =	"$PoC_PythonScriptDir\Wrapper"
$PoC_HookDirectory =		"$PoC_WrapperDirectory\Hooks"

# set default values
$PyWrapper_Debug =			$false
$PyWrapper_LoadEnv =		@{
	"Aldec" =							@{
		"PreHookFile" =			"Aldec.pre.ps1";
		"PostHookFile" =		"Aldec.post.ps1";
		"Tools" =						@{
			"ActiveHDL" =			@{
				"Load" =				$false;
				"Commands" =		@("asim");
				"PSModule" =			"Aldec.ActiveHDL.psm1";
				"PreHookFile" =		"Aldec.ActiveHDL.pre.ps1";
				"PostHookFile" =	"Aldec.ActiveHDL.post.ps1"
			# };
			# "RevieraPRO" =		@{
				# "Load" =				$false;
				# "Commands" =		@("rpro");
				# "PSModule" =			"Aldec.RevieraPRO.psm1";
				# "PreHookFile" =		"Aldec.RevieraPRO.pre.ps1";
				# "PostHookFile" =	"Aldec.RevieraPRO.post.ps1"
			}
		}};
	"Altera" =						@{
		"PreHookFile" =			"Altera.pre.ps1";
		"PostHookFile" =		"Altera.post.ps1";
		"Tools" =						@{
			"Quartus" =				@{
				"Load" =				$false;
				"Commands" =		@("quartus");
				"PSModule" =			"Altera.Quartus.psm1";
				"PreHookFile" =		"Altera.Quartus.pre.ps1";
				"PostHookFile" =	"Altera.Quartus.post.ps1"
			}
		}};
	"GHDL_GTKWave" =			@{
		"PreHookFile" =			"";
		"PostHookFile" =		"";
		"Tools" =						@{
			"GHDL" =					@{
				"Load" =				$false;
				"Commands" =		@("ghdl");
				"PSModule" =			"GHDL.psm1";
				"PreHookFile" =		"GHDL.pre.ps1";
				"PostHookFile" =	"GHDL.post.ps1"};
			"GTKWave" =				@{
				"Load" =				$false;
				"Commands" =		@("ghdl");
				"PSModule" =			"GTKWave.psm1";
				"PreHookFile" =		"GTKWave.pre.ps1";
				"PostHookFile" =	"GTKWave.post.ps1"}
		}};
	"Lattice" =						@{
		"PreHookFile" =			"Lattice.pre.ps1";
		"PostHookFile" =		"Lattice.post.ps1";
		"Tools" =						@{
			"Diamond" =				@{
				"Load" =				$false;
				"Commands" =		@("lse");
				"PSModule" =			"Lattice.Diamond.psm1";
				"PreHookFile" =		"Lattice.Diamond.pre.ps1";
				"PostHookFile" =	"Lattice.Diamond.post.ps1"
			};
			"ActiveHDL" =			@{
				"Load" =				$false;
				"Commands" =		@("asim");
				"PSModule" =			"Lattice.ActiveHDL.psm1";
				"PreHookFile" =		"Lattice.ActiveHDL.pre.ps1";
				"PostHookFile" =	"Lattice.ActiveHDL.post.ps1"
			}
		}};
	"Mentor" =						@{
		"PreHookFile" =			"Mentor.pre.ps1";
		"PostHookFile" =		"Mentor.post.ps1";
		"Tools" =						@{
			"PrecisionRTL" =	@{
				"Load" =				$false;
				"Commands" =		@("prtl");
				"PSModule" =			"Mentor.PrecisionRTL.psm1";
				"PreHookFile" =		"Mentor.PrecisionRTL.pre.ps1";
				"PostHookFile" =	"Mentor.PrecisionRTL.post.ps1"};
			"QuestaSim" =			@{
				"Load" =				$false;
				"Commands" =		@("vsim", "qsim");
				"PSModule" =			"Mentor.QuestaSim.psm1";
				"PreHookFile" =		"Mentor.QuestaSim.pre.ps1";
				"PostHookFile" =	"Mentor.QuestaSim.post.ps1"
			}
		}};
	"PowerShell" =				@{
		"PreHookFile" =			"";
		"PostHookFile" =		"";
		"Tools" =						@{
			"Sphinx" =				@{
				"Load" =				$false;
				"Commands" =		@("ps");
				"PSModule" =			"PowerShell.psm1";
				"PreHookFile" =		"PowerShell.pre.ps1";
				"PostHookFile" =	"PowerShell.post.ps1"}
		}};
	"Sphinx" =						@{
		"PreHookFile" =			"";
		"PostHookFile" =		"";
		"Tools" =						@{
			"Sphinx" =				@{
				"Load" =				$false;
				"Commands" =		@("docs");
				"PSModule" =			"Sphinx.psm1";
				"PreHookFile" =		"Sphinx.pre.ps1";
				"PostHookFile" =	"Sphinx.post.ps1"}
		}};
	"Xilinx" =						@{
		"PreHookFile" =			"Xilinx.pre.ps1";
		"PostHookFile" =		"Xilinx.post.ps1";
		"Tools" =						@{
			"ISE" =						@{
				"Load" =				$false;
				"Commands" =		@("isim", "xst", "coregen");
				"PSModule" =			"Xilinx.ISE.psm1";
				"PreHookFile" =		"Xilinx.ISE.pre.ps1";
				"PostHookFile" =	"Xilinx.ISE.post.ps1"
			};
			"Vivado" =				@{
				"Load" =				$false;
				"Commands" =		@("xsim", "vivado");
				"PSModule" =			"Xilinx.Vivado.psm1";
				"PreHookFile" =		"Xilinx.Vivado.pre.ps1";
				"PostHookFile" =	"Xilinx.Vivado.post.ps1"
			};
		} # Tools
	}	# Xilinx
}

# search parameters for specific options like '-D' to enable batch script debug mode
# TODO: restrict to first n=2? parameters
foreach ($param in $PyWrapper_Parameters)
{	if ($param -cmatch "^-\w*D\w*")
	{	$PyWrapper_Debug = $true
		continue
	}
	$breakIt = $false
	foreach ($VendorName in $PyWrapper_LoadEnv.Keys)
	{	foreach ($ToolName in $PyWrapper_LoadEnv[$VendorName]['Tools'].Keys)
		{	foreach ($Command in $PyWrapper_LoadEnv[$VendorName]['Tools'][$ToolName]['Commands'])
			{	if ($param -ceq $Command)
				{	$PyWrapper_LoadEnv[$VendorName]['Tools'][$ToolName]['Load']	= $true
					$breakIt = $true
					break
				}
			}
			if ($breakIt) {	break	}
		}
		if ($breakIt) {	break	}
	}
}

# publish PoC directories as environment variables
$env:PoCRootDirectory =			$PoC_RootDir
$env:PoCWorkingDirectory =	$PoC_WorkingDir

if ($PyWrapper_Debug -eq $true ) {
	Write-Host "This is the PoC-Library script wrapper operating in debug mode." -ForegroundColor Yellow
	Write-Host ""
	Write-Host "Directories:" -ForegroundColor Yellow
	Write-Host "  PoC Root        $PoC_RootDir" -ForegroundColor Yellow
	Write-Host "  Working         $PoC_WorkingDir" -ForegroundColor Yellow
	Write-Host "Script:" -ForegroundColor Yellow
	Write-Host "  Filename        $PoC_Script" -ForegroundColor Yellow
	Write-Host "  Solution        $PoC_Solution" -ForegroundColor Yellow
	Write-Host "  Parameters      $PyWrapper_Parameters" -ForegroundColor Yellow
	Write-Host "Load Environment:" -ForegroundColor Yellow
	Write-Host "  Xilinx ISE      $($PyWrapper_LoadEnv['Xilinx']['Tools']['ISE']['Load'])"			-ForegroundColor Yellow
	Write-Host "  Xilinx Vivado   $($PyWrapper_LoadEnv['Xilinx']['Tools']['Vivado']['Load'])"		-ForegroundColor Yellow
	Write-Host ""
}

# find suitable python version or abort execution
$Python_VersionTest = 'py.exe -3 -c "import sys; sys.exit(not (0x03050000 < sys.hexversion < 0x04000000))"'
Invoke-Expression $Python_VersionTest | Out-Null
if ($LastExitCode -eq 0) {
    $Python_Interpreter = "py.exe"
		$Python_Parameters =	(, "-3")
 	if ($PyWrapper_Debug -eq $true) { Write-Host "PythonInterpreter: '$Python_Interpreter $Python_Parameters'" -ForegroundColor Yellow }
} else {
    Write-Host "ERROR: No suitable Python interpreter found." -ForegroundColor Red
    Write-Host "The script requires Python $PyWrapper_MinVersion." -ForegroundColor Yellow
    $PoC_ExitCode = 1
}

# execute vendor and tool pre-hook files if present
$breakIt = $false
foreach ($VendorName in $PyWrapper_LoadEnv.Keys)
{	foreach ($ToolName in $PyWrapper_LoadEnv[$VendorName]['Tools'].Keys)
	{	if ($PyWrapper_LoadEnv[$VendorName]['Tools'][$ToolName]['Load'])
		{	# if exists, source the vendor pre-hook file
			$VendorPreHookFile = "$PoC_RootDir\$PoC_HookDirectory\$($PyWrapper_LoadEnv[$VendorName]['PreHookFile'])"
			if (Test-Path $VendorPreHookFile -PathType Leaf)
			{	. ($VendorPreHookFile)	}
			
			# if exists, source the tool pre-hook file
			$ToolPreHookFile = "$PoC_RootDir\$PoC_HookDirectory\$($PyWrapper_LoadEnv[$VendorName]['Tools'][$ToolName]['PreHookFile'])"
			if (Test-Path $ToolPreHookFile -PathType Leaf)
			{	. ($ToolPreHookFile)		}
			
			$ModuleFile = "$PoC_RootDir\$PoC_WrapperDirectory\$($PyWrapper_LoadEnv[$VendorName]['Tools'][$ToolName]['PSModule'])"
			if (Test-Path $ModuleFile -PathType Leaf)
			{	$ModuleName = (Get-Item $ModuleFile).BaseName
				# unload module if still loaded
				if (Get-Module $ModuleName)
				{ Remove-Module $ModuleName }
				# load module
				Import-Module $ModuleFile
				# invoke Open-Environment hook
				$PoC_ExitCode = Open-Environment $Python_Interpreter $Python_Parameters $PoC_FrontEnd
			}
			
			$breakIt = $true
			break
		}
	}
	if ($breakIt) {	break	}
}

# execute script with appropriate Python interpreter and all given parameters
if ($PoC_ExitCode -eq 0) {
	$Python_Script =						"$PoC_RootDir\$PoC_PythonScriptDir\$PoC_Script"
	if ($PoC_Solution -eq "") {
		$Python_ScriptParameters =	$PyWrapper_Parameters
	} else {
		$Python_ScriptParameters =	"--sln=$PoC_Solution " + $PyWrapper_Parameters
	}
	# execute script with appropriate Python interpreter and all given parameters
	if ($PyWrapper_Debug -eq $true) {
		Write-Host "launching: '$Python_Interpreter $Python_Parameters $Python_Script $Python_ScriptParameters'" -ForegroundColor Yellow
		Write-Host "------------------------------------------------------------" -ForegroundColor Yellow
	}

	# launching Python script
	Invoke-Expression "$Python_Interpreter $Python_Parameters $Python_Script $Python_ScriptParameters"
	$PoC_ExitCode = $LastExitCode
}

# execute vendor and tool post-hook files if present
foreach ($VendorName in $PyWrapper_LoadEnv.Keys)
{	foreach ($ToolName in $PyWrapper_LoadEnv[$VendorName]['Tools'].Keys)
	{	if ($PyWrapper_LoadEnv[$VendorName]['Tools'][$ToolName]['Load'])
		{	# if exists, source the tool pre-hook file
			$ToolPostHookFile = "$PoC_RootDir\$PoC_HookDirectory\$($PyWrapper_LoadEnv[$VendorName]['Tools'][$ToolName]['PostHookFile'])"
			if (Test-Path $ToolPostHookFile -PathType Leaf)
			{	. ($ToolPostHookFile)		}
			
			# if exists, source the vendor pre-hook file
			$VendorPostHookFile = "$PoC_RootDir\$PoC_HookDirectory\$($PyWrapper_LoadEnv[$VendorName]['PostHookFile'])"
			if (Test-Path $VendorPostHookFile -PathType Leaf)
			{	. ($VendorPostHookFile)	}
			
			$ModuleFile = "$PoC_RootDir\$PoC_WrapperDirectory\$($PyWrapper_LoadEnv[$VendorName]['Tools'][$ToolName]['PSModule'])"
			if (Test-Path $ModuleFile -PathType Leaf)
			{	$ModuleName = (Get-Item $ModuleFile).BaseName
				if (Get-Module $ModuleName)
				{ $PoC_ExitCode = Close-Environment
					Remove-Module $ModuleName
				}
			}
		}
	}
}

# clean up environment variables
$env:PoCRootDirectory =			$null
$env:PoCWorkingDirectory =	$null
