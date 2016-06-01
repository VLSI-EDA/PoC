asim -lib {VHDLLibraryName} -asdb {TestbenchName}.asdb -log {TestbenchName}.asim.log -t 1fs -ieee_nowarn {TestbenchName}
trace -rec add *
run -all
asdb2vcd {TestbenchName}.asdb {TestbenchName}.vcd
bye
