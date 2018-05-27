# PoC VHDL Coding Guide

## Licensing
PoC is published under the [Apache License, Version 2.0](LICENSE.md).
Please, make sure you are able and willing to submit your contributions to
this license.

## Naming
1. VHDL sources have the file extension `.vhdl`.
2. Prepend the name of an entity with its containing package using snake case,
   e.g.: `arith_addw` for the wide adder in package `arith`. Each module is
   implemented in its own source file, the name of which is `<entity>.vhdl`.
3. Synthesizable module implementations are provided through an
   architecture named `rtl`.
4. The name of a testbench entity copies the name of the tested module or
   package, to which `_tb` is appended. Its implementing architecture is
   named `tb`.

## Formatting

### Header
* Include the configuration header to automatically configure common editors
  to the tab width of two spaces:
```vhdl
-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
```
* Document your package or module within a documentation header:
 * starting with a separator line matching `/^--\s*={16,}$/`,
 * containing the appropriate sections of
   `Authors|Entity|Description|SeeAlso`, and
 * providing the license statement:
```vhdl
-- ===========================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
-- 	     	             Chair for VLSI-Design, Diagnostics and Architecture
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--              http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- ===========================================================================
```
  
### Whitespace
* Indent with one tab character per indentation level.
* Assume a tab width of two spaces.
* Eliminate all trailing whitespace.

## Coding Style

### Capitalization
1. Both snake and camel case are acceptable for signal and variable names as
   well as for labels. Be consistent in the capitalization when naming any such
   instance.
2. Use all lower case for VHDL keywords (e.g. `process`, `case`, ...)
   and common standard types (e.g. `integer`, `std_logic_vector`).
3. Use all upper case for constants and generic parameters.

### Signal Initialization
1. Specify an initializer for all signals that are to represent sequential
   logic, i.e. some state. If their initial state is irrelevant, initialize
   them to a don't-care value as appropriate, e.g. `(others => '-')`. Typically
   the same initial state should be assigned upon a reset condition.
2. Combinational signals never have a user-specified initializer.

### Expressions
1. Always use parentheses within expressions as soon as operator precedence
   is relevant and not trivial.
2. Avoid extraneous parentheses around expressions already framed by their
   syntactical contexts, such as `if ... then` or `while ... loop`.
3. Evaluate `boolean` expressions directly without comparing them to
   a `boolean` literal: use plain `B` instead of `B = true` and `not B`
   rather than `B = false`.

### Instantiations
1. Do not use the positional binding of generic parameters or ports.
2. Prefer the instantiation of components if their declarations are
   readily available through designated packages.
