# Namespace `PoC.sim`

The namespace `PoC.sim` offers simulation helper packages.


## Common Package

The package [`PoC.sim_types`][sim_types.pkg] is VHDL version independent and contains common type declarations
needed for PoC's simulation helpers.

## VHDL-93 Packages:

  - [`PoC.sim_unprotected`][sim_unprotected.pkg.v93] 
  - [`PoC.sim_global`][sim_global.pkg.v93] 
  - [`PoC.sim_simulation`][sim_simulation.pkg.v93] 

## VHDL-2008 Packages:

  - [`PoC.sim_protected`][sim_protected.pkg.v08] 
  - [`PoC.sim_global`][sim_global.pkg.v08] 
  - [`PoC.sim_simulation`][sim_simulation.pkg.v08] 

## Provided Procedures and Functions

**Testbench control**
  - `simInitialize` - initilaizes internal data structures
  - `simFinalize` - finializes all data strutures and writes a report to the simulation's STDOUT stream
  - `simCreateTest(Name)` - creates a test
  - `simRegisterProcess(Name)` - registers an active process
  - `simDeactivateProcess(ProcID)` - deactivates a process
 
**Miscellaneous**
  - `simWriteMessage(Message)` - write to STDOUT

**Assertions**
  - `simFail(Message)` - Marks the testbench as failed and writes a message to STDOUT
  - `simAssertion(Condition, Message)` - If the passed condition result is false, a message is written to STDOUT and the testbench is marked as failed.

**Clock generation**

  - `simGenerateClock(signal Clock, constant Frequency, constant DutyCycle)` - Create a clock signal
  - `simStopAll` - Stop all event generating processes
  - `simIsStopped` - Check if simulation is stopped
	
## Testbench example

```VHDL
library IEEE;
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.NUMERIC_STD.all;

library PoC;
use			PoC.utils.all;
use			PoC.vectors.all;
use			PoC.strings.all;
use			PoC.physical.all;
-- simulation only packages
use			PoC.sim_global.all;
use			PoC.sim_types.all;
use			PoC.simulation.all;

entity my_frist_tb is
end entity;

architecture test of my_frist_tb is
  constant CLOCK_FREQ : FREQ          := 100 MHz;
  constant BITS       : POSITIVE      := 8;
  constant simTestID  : T_SIM_TEST_ID := simCreateTest("Test setup for BITS=" & INTEGER'image(BITS));
  
  signal Clock        : STD_LOGIC;
begin
  -- initialize global simulation status
  simInitialize;
  
  -- generate global testbench clock
  simGenerateClock(Clock, CLOCK_FREQ);
  
  procGenerator : process
    constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Generator for " & INTEGER'image(BITS) & " bits");
  begin
    -- generate stimuli
    
    -- This process is finished
    simDeactivateProcess(simProcessID);
    wait;  -- forever
  end process;
  
  -- Unit under test
  UUT : entity PoC.my_first
    generic map (
      BITS    => BITS
      -- <more generics>
    )
    port map (
      Clock   => Clock,
      -- <more signals>
    );
  
  procChecker : process
    -- from Simulation
    constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Checker for " & INTEGER'image(BITS) & " bits");
  begin
    -- check results
    
    -- This process is finished
    simDeactivateProcess(simProcessID);
    simFinalize;  -- Report overall result
    wait;  -- forever
  end process;
end architecture;
```

 [sim_types.pkg]:							sim_types.pkg.vhdl
 [sim_unprotected.pkg.v93]:		sim_unprotected.pkg.v93.vhdl
 [sim_global.pkg.v93]:				sim_global.pkg.v93.vhdl
 [sim_simulation.pkg.v93]:		sim_simulation.pkg.v93.vhdl
 [sim_protected.pkg.v08]:			sim_protected.pkg.v08.vhdl
 [sim_global.pkg.v08]:				sim_global.pkg.v08.vhdl
 [sim_simulation.pkg.v08]:		sim_simulation.pkg.v08.vhdl
