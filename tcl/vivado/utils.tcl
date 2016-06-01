# EMACS settings: -*-   tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# ============================================================================
# Authors:					Thomas B. Preusser
#
# Tcl Include:			Vivado Workflow Utility Procedures
#
# Description
# -----------
# This is a collection of Tcl procedures that aim at easing the scripted
# Vivado workflow.
#
# License:
# ============================================================================
# Copyright 2007-2016 Technische Universitaet Dresden - Germany
#                     Chair for VLSI-Design, Diagnostics and Architecture
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#               http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ============================================================================

# Called with the name of a bus[0 to N-1] and a list of package pins,
# this procedure assigns the first N pins to the respective bus ports.
proc assign_bus_pins {bus pins} {
  for {set i 0} {$i < [llength $pins]} {incr i} {
    set PORT [get_ports -quiet "$bus[$i]"]
    if { [llength $PORT] == 0 } { break }
    set_property PACKAGE_PIN [lindex $pins $i] $PORT
  }
}
