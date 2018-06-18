$Message = "Testing PoC commands in dryrun mode..."
Write-Host $Message -ForegroundColor Yellow
Add-AppveyorMessage -Message $Message -Category Information

$TestFramework =  "PoC"
# ==============================================================================
$PoCEntity =      "PoC.arith.prng"
$Tools = @(
  "Active-HDL",
  "Riviera-PRO",
  "GHDL",
  "ModelSim",
  "ISE Simulator",
  "Vivado Simulator"
)

foreach ($Tool in $Tools)
{	$TestName = "Dryrun test: {0} run for {1}" -f $Tool,$PoCEntity
	Add-AppveyorTest -Name $TestName -Framework $TestFramework -FileName $PoCEntity -Outcome Running
	$start = Get-Date
	.\PoC.ps1 --dryrun asim PoC.arith.prng
	$end = Get-Date
	Update-AppveyorTest -Name $TestName -Framework $TestFramework -FileName $PoCEntity -Outcome $(if ($LastExitCode -eq 0) {"Passed"} else {"Failed"}) -Duration ($end - $start).TotalMilliseconds
}
# ==============================================================================
