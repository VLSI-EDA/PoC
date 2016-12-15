Write-Host "Testing PoC commands in dryrun mode..."
Add-AppveyorMessage -Message "Testing PoC commands in dryrun mode..."
.\PoC.ps1 --dryrun asim PoC.arith.prng
.\PoC.ps1 --dryrun rpro PoC.arith.prng
.\PoC.ps1 --dryrun ghdl PoC.arith.prng
.\PoC.ps1 --dryrun isim PoC.arith.prng
.\PoC.ps1 --dryrun vsim PoC.arith.prng
.\PoC.ps1 --dryrun xsim PoC.arith.prng
