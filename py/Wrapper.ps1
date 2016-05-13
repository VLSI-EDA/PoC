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
$PoC_PythonScriptDir =	"py"
$PoC_HookDirectory =		"tools\Hooks"

$PoC_WorkingDir = Get-Location

# set default values
$PyWrapper_Debug =			$false
$PyWrapper_LoadEnv =		@{
	"Aldec" =							@{
		"PreHookFile" =			"Aldec.pre.ps1";
		"PostHookFile" =		"Aldec.post.ps1";
		"Tools" =						@{
			"ActiveHDL" =			@{"Load" = $false; "Commands" = @("asim");										"PreHookFile" = "Aldec.ActiveHDL.pre.ps1";			"PostHookFile" = "Aldec.ActiveHDL.post.ps1"};
			"RevieraPRO" =		@{"Load" = $false; "Commands" = @("rpro");										"PreHookFile" = "Aldec.RevieraPRO.pre.ps1";			"PostHookFile" = "Aldec.RevieraPRO.post.ps1"}
		}};
	"Altera" =						@{
		"PreHookFile" =			"Altera.pre.ps1";
		"PostHookFile" =		"Altera.post.ps1";
		"Tools" =						@{
			"Quartus" =				@{"Load" = $false; "Commands" = @("quartus");									"PreHookFile" = "Altera.Quartus.pre.ps1";				"PostHookFile" = "Altera.Quartus.post.ps1"}
			# "ModelSim" =			@{"Load" = $false; "Commands" = @("vsim");										"PreHookFile" = "Altera.ModelSim.pre.ps1"}
		}};
	"GHDL_GTKWave" =			@{
		"PreHookFile" =			"";
		"PostHookFile" =		"";
		"Tools" =						@{
			"GHDL" =					@{"Load" = $false; "Commands" = @("ghdl");										"PreHookFile" = "GHDL.pre.ps1";									"PostHookFile" = "GHDL.post.ps1"};
			"GTKWave" =				@{"Load" = $false; "Commands" = @("ghdl");										"PreHookFile" = "GTKWave.pre.ps1";							"PostHookFile" = "GTKWave.post.ps1"}
		}};
	"Lattice" =						@{
		"PreHookFile" =			"Lattice.pre.ps1";
		"PostHookFile" =		"Lattice.post.ps1";
		"Tools" =						@{
			"Diamond" =				@{"Load" = $false; "Commands" = @("lse");											"PreHookFile" = "Lattice.Diamond.pre.ps1";			"PostHookFile" = "Lattice.Diamond.post.ps1"};
			"ActiveHDL" =			@{"Load" = $false; "Commands" = @("asim");										"PreHookFile" = "Lattice.ActiveHDL.pre.ps1";		"PostHookFile" = "Lattice.ActiveHDL.post.ps1"}
		}};
	"Mentor" =						@{
		"PreHookFile" =			"Mentor.pre.ps1";
		"PostHookFile" =		"Mentor.post.ps1";
		"Tools" =						@{
			"PrecisionRTL" =	@{"Load" = $false; "Commands" = @("prtl");										"PreHookFile" = "Mentor.PrecisionRTL.pre.ps1";	"PostHookFile" = "Mentor.PrecisionRTL.post.ps1"};
			"QuestaSim" =			@{"Load" = $false; "Commands" = @("vsim", "qsim");						"PreHookFile" = "Mentor.QuestaSim.pre.ps1";			"PostHookFile" = "Mentor.QuestaSim.post.ps1"}
		}};
	"Xilinx" =						@{
		"PreHookFile" =			"Xilinx.pre.ps1";
		"PostHookFile" =		"Xilinx.post.ps1";
		"Tools" =						@{
			"ISE" =						@{"Load" = $false; "Commands" = @("isim", "xst", "coregen");	"PreHookFile" = "Xilinx.ISE.pre.ps1";						"PostHookFile" = "Xilinx.ISE.post.ps1"};
			"Vivado" =				@{"Load" = $false; "Commands" = @("xsim", "synth");						"PreHookFile" = "Xilinx.Vivado.pre.ps1";				"PostHookFile" = "Xilinx.Vivado.post.ps1"}
		}}
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
	{	foreach ($ToolName in $PyWrapper_LoadEnv[$VendorName]["Tools"].Keys)
		{	foreach ($Command in $PyWrapper_LoadEnv[$VendorName]["Tools"][$ToolName]["Commands"])
			{	if ($param -ceq $Command)
				{	$PyWrapper_LoadEnv[$VendorName]["Tools"][$ToolName]["Load"]	= $true
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
$env:PoCRootDirectory =			$PoC_RootDir_AbsPath
$env:PoCWorkingDirectory =	$PoC_WorkingDir

if ($PyWrapper_Debug -eq $true ) {
	Write-Host "This is the PoC Library script wrapper operating in debug mode." -ForegroundColor Yellow
	Write-Host ""
	Write-Host "Directories:" -ForegroundColor Yellow
	Write-Host "  Script root:   $PyWrapper_ScriptDir" -ForegroundColor Yellow
	Write-Host "  PoC root:      $PoC_RootDir_AbsPath" -ForegroundColor Yellow
	Write-Host "  working:       $PoC_WorkingDir" -ForegroundColor Yellow
	Write-Host "Script:" -ForegroundColor Yellow
	Write-Host "  Filename:      $PyWrapper_Script" -ForegroundColor Yellow
	Write-Host "  Solution:      $PyWrapper_Solution" -ForegroundColor Yellow
	Write-Host "  Parameters:    $PyWrapper_Parameters" -ForegroundColor Yellow
	Write-Host "Load Environment:" -ForegroundColor Yellow
	Write-Host "  Xilinx ISE:    $(PyWrapper_LoadEnv["Xilinx"]["Tools"]["ISE"]["Load"])"			-ForegroundColor Yellow
	Write-Host "  Xilinx VIVADO: $(PyWrapper_LoadEnv["Xilinx"]["Tools"]["Vivado"]["Load"])"		-ForegroundColor Yellow
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
foreach ($VendorName in $PyWrapper_LoadEnv.Keys)
{	foreach ($ToolName in $PyWrapper_LoadEnv[$VendorName]["Tools"].Keys)
	{	if ($PyWrapper_LoadEnv[$VendorName]["Tools"][$ToolName]["Load"])
		{	# if exists, source the vendor pre-hook file
			$VendorPreHookFile = $PoC_RootDir_AbsPath + "\" + $PoC_HookDirectory + "\" + $PyWrapper_LoadEnv[$VendorName]["PreHookFile"]
			if (Test-Path $VendorPreHookFile -PathType Leaf)
			{	. ($VendorPreHookFile)	}
			# if exists, source the tool pre-hook file
			$ToolPreHookFile = $PoC_RootDir_AbsPath + "\" + $PoC_HookDirectory + "\" + $PyWrapper_LoadEnv[$VendorName]["Tools"][$ToolName]["PreHookFile"]
			if (Test-Path $ToolPreHookFile -PathType Leaf)
			{	. ($ToolPreHookFile)		}
		}
	}
}


if (($PoC_ExitCode -eq 0) -and $PyWrapper_LoadEnv["Xilinx"]["Tools"]["ISE"]["Load"]) {
	# load Xilinx ISE environment if not loaded before
	if (-not (Test-Path env:XILINX)) {
		$PoC_Command = "$Python_Interpreter $Python_Parameters $PoC_RootDir_AbsPath\$PoC_PythonScriptDir\PoC.py query Xilinx.ISE:SettingsFile"
		if ($PyWrapper_Debug -eq $true) { Write-Host "Getting ISE settings file: command='$PoC_Command'" -ForegroundColor Yellow }

		# execute python script to receive ISE settings filename
		$PoC_ISE_SettingsFile = Invoke-Expression $PoC_Command
		if ($LastExitCode -eq 0) {
			if ($PyWrapper_Debug -eq $true) { Write-Host "ISE settings file: '$PoC_ISE_SettingsFile'" -ForegroundColor Yellow }
			if ($PoC_ISE_SettingsFile -eq "") {
				Write-Host "ERROR: No Xilinx ISE installation found." -ForegroundColor Red
				Write-Host "Run 'poc.ps1 --configure' to configure your Xilinx ISE installation." -ForegroundColor Red
				$PoC_ExitCode = 1
			} elseif (-not (Test-Path $PoC_ISE_SettingsFile -PathType Leaf)) {
				Write-Host "ERROR: Xilinx ISE is configured in PoC, but settings file '$PoC_ISE_SettingsFile' does not exist." -ForegroundColor Red
				Write-Host "Run 'poc.ps1 --configure' to configure your Xilinx ISE installation." -ForegroundColor Red
				$PoC_ExitCode = 1
			} elseif (($PoC_ISE_SettingsFile -like "*.bat") -or ($PoC_ISE_SettingsFile -like "*.cmd")) {
				Write-Host "Loading Xilinx ISE environment '$PoC_ISE_SettingsFile'" -ForegroundColor Yellow
				Import-Module PSCX
				Invoke-BatchFile -path $PoC_ISE_SettingsFile
			} else {
				Write-Host "ERROR: Xilinx ISE is configured in PoC, but settings file format is not supported." -ForegroundColor Red
				$PoC_ExitCode = 1
			}
		} else {
			Write-Host "ERROR: ExitCode for '$PoC_Command' was not zero. Aborting script execution" -ForegroundColor Red
			Write-Host $PoC_ISE_SettingsFile -ForegroundColor Red
			$PoC_ExitCode = 1
		}
	}
}

if (($PoC_ExitCode -eq 0) -and $PyWrapper_LoadEnv["Xilinx"]["Tools"]["Vivado"]["Load"]) {
	# load Xilinx Vivado environment if not loaded before
	if (-not (Test-Path env:XILINX_VIVADO)) {
		$PoC_Command = "$Python_Interpreter $Python_Parameters $PoC_RootDir_AbsPath\$PoC_PythonScriptDir\PoC.py query Xilinx.Vivado:SettingsFile"
		if ($PyWrapper_Debug -eq $true) { Write-Host "Getting Vivado settings file: command='$PoC_Command'" -ForegroundColor Yellow }

		# execute python script to receive Vivado settings filename
		$PoC_Vivado_SettingsFile = Invoke-Expression $PoC_Command
		if ($LastExitCode -eq 0) {
			if ($PyWrapper_Debug -eq $true) { Write-Host "Vivado settings file: '$PoC_Vivado_SettingsFile'" -ForegroundColor Yellow }
			if ($PoC_Vivado_SettingsFile -eq "") {
				Write-Host "ERROR: No Xilinx Vivado installation found." -ForegroundColor Red
				Write-Host "Run 'poc.ps1 --configure' to configure your Xilinx Vivado installation." -ForegroundColor Red
				$PoC_ExitCode = 1
			} elseif (-not (Test-Path $PoC_Vivado_SettingsFile -PathType Leaf)) {
				Write-Host "ERROR: Xilinx Vivado is configured in PoC, but settings file '$PoC_Vivado_SettingsFile' does not exist." -ForegroundColor Red
				Write-Host "Run 'poc.ps1 --configure' to configure your Xilinx Vivado installation." -ForegroundColor Red
				$PoC_ExitCode = 1
			} elseif (($PoC_Vivado_SettingsFile -like "*.bat") -or ($PoC_Vivado_SettingsFile -like "*.cmd")) {
				Write-Host "Loading Xilinx Vivado environment '$PoC_Vivado_SettingsFile'" -ForegroundColor Yellow
				Import-Module PSCX
				Invoke-BatchFile -path $PoC_Vivado_SettingsFile
			} else {
				Write-Host "ERROR: Xilinx Vivado is configured in PoC, but settings file format is not supported." -ForegroundColor Red
				$PoC_ExitCode = 1
			}
		} else {
			Write-Host "ERROR: ExitCode for '$PoC_Command' was not zero. Aborting script execution" -ForegroundColor Red
			$PoC_ExitCode = 1
		}
	}
}

# execute script with appropriate Python interpreter and all given parameters
if ($PoC_ExitCode -eq 0) {
	$Python_Script =						"$PoC_RootDir_AbsPath\$PoC_PythonScriptDir\$PyWrapper_Script"
	if ($PyWrapper_Solution -eq "") {
		$Python_ScriptParameters =	$PyWrapper_Parameters
	} else {
		$Python_ScriptParameters =	"--sln=$PyWrapper_Solution " + $PyWrapper_Parameters
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
{	foreach ($ToolName in $PyWrapper_LoadEnv[$VendorName]["Tools"].Keys)
	{	if ($PyWrapper_LoadEnv[$VendorName]["Tools"][$ToolName]["Load"])
		{	# if exists, source the vendor pre-hook file
			$VendorPostHookFile = $PoC_RootDir_AbsPath + "\" + $PoC_HookDirectory + "\" + $PyWrapper_LoadEnv[$VendorName]["PostHookFile"]
			if (Test-Path $VendorPostHookFile -PathType Leaf)
			{	. ($VendorPostHookFile)	}
			# if exists, source the tool pre-hook file
			$ToolPostHookFile = $PoC_RootDir_AbsPath + "\" + $PoC_HookDirectory + "\" + $PyWrapper_LoadEnv[$VendorName]["Tools"][$ToolName]["PostHookFile"]
			if (Test-Path $ToolPostHookFile -PathType Leaf)
			{	. ($ToolPostHookFile)		}
		}
	}
}

# clean up environment variables
$env:PoCRootDirectory =			$null
$env:PoCWorkingDirectory =	$null
