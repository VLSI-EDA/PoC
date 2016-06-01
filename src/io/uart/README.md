# Namespace `PoC.io.uart`

The namespace `PoC.io.uart` offers a Universal Asynchronous Receiver Transmitter (UART) implementation.

 [pmod]: https://www.digilentinc.com/Pmods/Digilent-Pmod_%20Interface_Specification.pdf

## Package

The package [`PoC.uart`][uart.pkg] holds all component declarations for this namespace.


## Entities

 -  [`uart_bclk`][uart_bclk] - bit-clock generator for 8x oversampling
 -  [`uart_rx`][uart_rx] - the receiver
 -  [`uart_tx`][uart_tx] - the transmitter
 -  [`uart_fifo`][uart_fifo] - a UART with FIFO interface and internal send and receive FIFOs 


 [uart.pkg]:			uart.pkg.vhdl

 [uart_bclk]:			uart_bclk.vhdl
 [uart_rx]:			  uart_rx.vhdl
 [uart_tx]:			  uart_tx.vhdl
 [uart_fifo]:		  uart_fifo.vhdl
