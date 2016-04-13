# Change List
----------------


## 2016

##### New in 0.X (DD.MM.2016)

  - Reworked Python infrastructure
      - New command line interface `poc.sh|ps1 [common options] <command> <entity> [options]`
      - Removed task specific wrapper scripts: `testbench.sh|ps1`, `netlist.sh|ps1`
      - New parser for `*.files` files
          - conditional compiling (if-then-elseif-else)
          - include statement - include other `*.files` files
          - library statement - reference external VHDL libraries
          - prepared for Cocotb testbenches
      - Unbuffered outputs from vendor tools (realtime output to stdout from subprocess)
      - Output filtering from vendor tools
          - verbose message suppression
          - error and warning message highlighting
      - Added a new config.boards.ini file to list known boards (real and virtual ones)
      - Run testbenches for different board or device configurations (see `--board` and `--device` command line options)
      - Finished Aldec Active-HDL support (no GUI support)
      - GHDLSimulator can distinguish different backends 
	- Embedded Cocotb in <PoCRoot>/lib/cocotb
  - precompiled vendor library support
      - Added a new <PoCRoot>/temp/precompiled folder for precompiled vendor libraries
      - QuestaSim supports Altera QuartusII, Xilinx ISE and Xilinx Vivado libraries
      - GHDL supports Altera QuartusII, Xilinx ISE and Xilinx Vivado libraries

##### New in 0.21 (17.02.2016)

##### New in 0.20 (16.01.2016)

##### New in 0.19 (16.01.2016)

## 2015

##### New in 0.18 (16.12.2015)

##### New in 0.17 (08.12.2015)

##### New in 0.16 (01.12.2015)

##### New in 0.15 (13.11.2015)

##### New in 0.14 (28.09.2015)

##### New in 0.13 (04.09.2015)

##### New in 0.12 (25.08.2015)

##### New in 0.11 (07.08.2015)

##### New in 0.10 (23.07.2015)
			
##### New in 0.9 (21.07.2015)

##### New in 0.8 (03.07.2015)

##### New in 0.7 (27.06.2015)

##### New in 0.6 (09.06.2015)

##### New in 0.5 (27.05.2015)
  - Updated Python infrastructure
  - New testbenches:
      - sync_Reset_tb
      - sync_Flag_tb
      - sync_Strobe_tb
      - sync_Vector_tb
      - sync_Command_tb
  - Updated modules:
      - sync_Vector
      - sync_Command
  - Updated packages:
      - physical
      - utils
      - vectors
      - xil

##### New in 0.4 (29.04.2015)
  - New Python infrastructure
      - Added simulators for:
          - GHDL + GTKWave
          - Mentor Graphic QuestaSim
          - Xilinx ISE Simulator
          - Xilinx Vivado Simulator
  - New packages:
      - simulation
  - New modules:
      - PoC.comm - communication modules
          - comm_crc
      - PoC.comm.remote - remote communication modules
          - remote_terminal_control
  - New testbenches:
      - arith_addw_tb
      - arith_counter_bcd_tb
      - arith_prefix_and_tb
      - arith_prefix_or_tb
      - arith_prng_tb
  - Updated packages:
      - board
      - config
      - physical
      - strings
      - utils
  - Updated modules:
      - io_Debounce
      - misc_FrequencyMeasurement
      - sync_Bits
      - sync_Reset
			
##### New in 0.3 (31.03.20015)
  - Added Python infrastructure
      - Added platform wrapper scripts (*.sh, *.ps1)
      - Added IP-core compiler scripts Netlist.py
  - Added Tools
      - Notepad++ syntax file for Xilinx UCF/XCF files
      - Git configuration script to register global aliases
  - New packages:
      - components - hardware described as functions
      - physical - physical types like frequency, memory and baudrate
      - io
  - New modules:
      - PoC.misc
          - misc_FrequencyMeasurement
      - PoC.io - Low-speed I/O interfaces
          - io_7SegmentMux_BCD
          - io_7SegmentMux_HEX
          - io_FanControl
          - io_PulseWidthModulation
          - io_TimingCounter
          - io_Debounce
          - io_GlitchFilter
  - New IP-cores:
      - PoC.xil - Xilinx specific modules
          - xil_ChipScopeICON_1
          - xil_ChipScopeICON_2
          - xil_ChipScopeICON_3
          - xil_ChipScopeICON_4
          - xil_ChipScopeICON_6
          - xil_ChipScopeICON_7
          - xil_ChipScopeICON_8
          - xil_ChipScopeICON_9
          - xil_ChipScopeICON_10
          - xil_ChipScopeICON_11
          - xil_ChipScopeICON_12
          - xil_ChipScopeICON_13
          - xil_ChipScopeICON_14
          - xil_ChipScopeICON_15
  - New constraint files:
      - ML605
      - KC705
      - VC707
      - MetaStability
      - xil_Sync
  - Updated packages:
      - board
      - config
  - Updated modules:
      - xil_BSCAN
					
##### New in 0.2 (09.03.2015)
  - New packages:
      - xil
      - stream
  - New modules:
      - PoC.bus - Modules for busses
          - bus_Arbiter
      - PoC.bus.stream - Modules for the PoC.Stream protocol
          - stream_Buffer
          - stream_DeMux
          - stream_FrameGenerator
          - stream_Mirror
          - stream_Mux
          - stream_Source
      - PoC.misc.sync - Cross-Clock Synchronizers
          - sync_Reset
          - sync_Flag
          - sync_Strobe
          - sync_Vector
          - sync_Command
      - PoC.xil - Xilinx specific modules
          - xil_SyncBits
          - xil_SyncReset
          - xil_BSCAN
          - xil_Reconfigurator
          - xil_SystemMonitor_Virtex6
          - xil_SystemMonitor_Series7
  - Updated packages:
      - utils
      - arith

##### New in 0.1 (19.02.2015)
  - New packages:
      - board - common development board configurations
      - config - extract configuration parameters from device names
      - utils - common utility functions
      - strings - a helper package for string handling
      - vectors - a helper package for std_logic_vector and std_logic_matrix
      - arith
      - fifo
  - New modules
      - PoC.arith - arithmetic modules
          - arith_counter_gray
          - arith_counter_ring
          - arith_div
          - arith_prefix_and
          - arith_prefix_or
          - arith_prng
          - arith_scaler
          - arith_sqrt
      - PoC.fifo - FIFOs
          - fifo_cc_got
          - fifo_cc_got_tempgot
          - fifo_cc_got_tempput
          - fifo_ic_got
          - fifo_glue
          - fifo_shift
      - PoC.mem.ocram - On-Chip RAMs
          - ocram_sp
          - ocram_sdp
          - ocram_esdp
          - ocram_tdp
          - ocram_wb

## 2014

##### New in 0.0 (16.12.2014)
  - Initial commit
