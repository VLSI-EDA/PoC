
Naming Conversions
##################

Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.
At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor
sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et
accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet


# Module Names and Namespaces 

PoC uses namespaces and sub-namespaces to categorize all VHDL and Verilog modules.
So a FIFO module with a common clock interface and a ‘got’ semantic is called
`PoC.fifo.cc_got`.

    File name components    | Description
    =========================================================
    Root namespace          | PoC
    Sub-namespace           | fifo
    Common clock interface  | cc
    Got semantic            | got
    =========================================================
    File location           | <PoCRoot>\src\fifo\
    File name               | fifo_cc_got.vhdl
    VHDL entity name        | fifo_cc_got


Other implementation variants are:

-	`_dc` – dependent clock / related clock
-	`_ic` – independent clock / cross clock
-	`_got_tempgot` – got interface extended by a temporary got interface
-	`_got_tempput` – got interface extended by a temporary put interface


**Another example: `PoC.mem.ocram.tdp`**

    File name components      | Description
    =========================================================
    Root namespace            | PoC
    Sub-namespace             | mem.ocram
    True-dual-port interface  | tdp
    =========================================================
    File location             | <PoCRoot>\src\mem\ocram\
    File name                 | ocram_tdp.vhdl
    VHDL entity name          | ocram_tdp

So not all sub-namespace parts are include as a prefix in the name, only
the last one.



