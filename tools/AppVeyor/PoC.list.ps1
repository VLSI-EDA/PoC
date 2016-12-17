$Message = "Testing PoC list-*** commands..."
Write-Host $Message -ForegroundColor Yellow
Add-AppveyorMessage -Message $Message -Category Information

$TestFramework = "PoC"
# ==============================================================================
$PoCEntity =  "PoC.*"
$Commands =   @(
	"list-testbench",
	"list-netlist"
)

foreach ($Command in $Commands)
{	$TestName = "Command test: {0} for pattern {1}" -f $Command,$PoCEntity
	Add-AppveyorTest -Name $TestName -Framework $TestFramework -FileName $PoCEntity -Outcome Running
	$start = Get-Date
	.\PoC.ps1 $Command $PoCEntity
	$end = Get-Date
	Update-AppveyorTest -Name $TestName -Framework $TestFramework -FileName $PoCEntity -Outcome $(if ($LastExitCode -eq 0) {"Passed"} else {"Failed"}) -Duration ($end - $start).TotalSeconds
}
# ==============================================================================
