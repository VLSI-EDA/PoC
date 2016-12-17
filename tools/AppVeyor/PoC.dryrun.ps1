Write-Host "Testing PoC commands in dryrun mode..."
Add-AppveyorMessage -Message "Testing PoC commands in dryrun mode..." -Category Information

# ==============================================================================
Add-AppveyorTest -Name "Dryrun test: Active-HDL run for PoC.arith.prng" -Framework "PoC" -FileName "PoC.arith.prng" -Outcome Running
$start = Get-Date
.\PoC.ps1 --dryrun asim PoC.arith.prng
$end = Get-Date
Update-AppveyorTest -Name "Dryrun test: Active-HDL run for PoC.arith.prng" -Framework "PoC" -FileName "PoC.arith.prng" -Outcome $(if ($LastExitCode -eq 0) {"Passed"} else {"Failed"}) -Duration ($end - $start).TotalSeconds

# ==============================================================================
Add-AppveyorTest -Name "Dryrun test: Riviera-PRO run for PoC.arith.prng" -Framework "PoC" -FileName "PoC.arith.prng" -Outcome Running
$start = Get-Date
.\PoC.ps1 --dryrun rpro PoC.arith.prng
$end = Get-Date
Update-AppveyorTest -Name "Dryrun test: Riviera-PRO run for PoC.arith.prng" -Framework "PoC" -FileName "PoC.arith.prng" -Outcome $(if ($LastExitCode -eq 0) {"Passed"} else {"Failed"}) -Duration ($end - $start).TotalSeconds

# ==============================================================================
Add-AppveyorTest -Name "Dryrun test: GHDL run for PoC.arith.prng" -Framework "PoC" -FileName "PoC.arith.prng" -Outcome Running
$start = Get-Date
.\PoC.ps1 --dryrun ghdl PoC.arith.prng
$end = Get-Date
Update-AppveyorTest -Name "Dryrun test: GHDL run for PoC.arith.prng" -Framework "PoC" -FileName "PoC.arith.prng" -Outcome $(if ($LastExitCode -eq 0) {"Passed"} else {"Failed"}) -Duration ($end - $start).TotalSeconds

# ==============================================================================
Add-AppveyorTest -Name "Dryrun test: ModelSim run for PoC.arith.prng" -Framework "PoC" -FileName "PoC.arith.prng" -Outcome Running
$start = Get-Date
.\PoC.ps1 --dryrun vsim PoC.arith.prng
$end = Get-Date
Update-AppveyorTest -Name "Dryrun test: ModelSim run for PoC.arith.prng" -Framework "PoC" -FileName "PoC.arith.prng" -Outcome $(if ($LastExitCode -eq 0) {"Passed"} else {"Failed"}) -Duration ($end - $start).TotalSeconds

# ==============================================================================
Add-AppveyorTest -Name "Dryrun test: ISE Simulator run for PoC.arith.prng" -Framework "PoC" -FileName "PoC.arith.prng" -Outcome Running
$start = Get-Date
.\PoC.ps1 --dryrun isim PoC.arith.prng
$end = Get-Date
Update-AppveyorTest -Name "Dryrun test: ISE Simulator run for PoC.arith.prng" -Framework "PoC" -FileName "PoC.arith.prng" -Outcome $(if ($LastExitCode -eq 0) {"Passed"} else {"Failed"}) -Duration ($end - $start).TotalSeconds

# ==============================================================================
Add-AppveyorTest -Name "Dryrun test: Vivado Simulator run for PoC.arith.prng" -Framework "PoC" -FileName "PoC.arith.prng" -Outcome Running
$start = Get-Date
.\PoC.ps1 --dryrun xsim PoC.arith.prng
$end = Get-Date
Update-AppveyorTest -Name "Dryrun test: Vivado Simulator run for PoC.arith.prng" -Framework "PoC" -FileName "PoC.arith.prng" -Outcome $(if ($LastExitCode -eq 0) {"Passed"} else {"Failed"}) -Duration ($end - $start).TotalSeconds
