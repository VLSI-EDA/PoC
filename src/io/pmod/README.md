# Namespace `PoC.io.pmod`

The namespace `PoC.io.pmod` offers different modules, for the Digilent Periphery Modules (Pmod).
See the [Digilent Pmod™ Interface Specification][pmod] specification for more details.

 [pmod]: https://www.digilentinc.com/Pmods/Digilent-Pmod_%20Interface_Specification.pdf

## Package

The package [`PoC.pmod`][pmod.pkg] holds all component declarations for this namespace.


## Entities

 -  [`pmod_KYPD`][pmod_KYPD] - a 16-button (4x4) keypad
 -  [`pmod_SSD`][pmod_SSD] - a 2 digit 7-segment display (SSD)
 -  [`pmod_USBUART`][pmod_USBUART] - a USB to UART bridge (FTDI FT232RQ)


 [pmod.pkg]:			pmod.pkg.vhdl

 [pmod_KYPD]:			pmod_KYPD.vhdl
 [pmod_SSD]:			pmod_SSD.vhdl
 [pmod_USBUART]:	pmod_USBUART.vhdl
