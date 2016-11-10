# EMACS settings: -*-   tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# ============================================================================
# Tcl Include: Vivado Workflow Utility Procedures
#
# Authors:   Thomas B. Preusser
#
# Description
# -----------
# This is a collection of generic utility Tcl procedures.
#
# License:
# ============================================================================
# Copyright 2007-2016 Technische Universitaet Dresden - Germany
#                     Chair of VLSI-Design, Diagnostics and Architecture
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

# Extracts a the values of the named constants from a VHDL configuration
# packaged and associates them with a variable of the same name within the
# calling scope.
#
# Note: This implementation will fail on string values containing ';'.
proc read_vhdl_config {config_vhdl names} {
	# Read config file into string
  set fd [open $config_vhdl r]
  set data [list [read $fd]]
  close $fd

	# Build list of values assigned to passed configuration variable names
	foreach name $names {
		if { [regexp -nocase [string tolower "constant\\s*$name\\s*:\\s*\\w+\\s*:=\\s*(\[^;]+?)\\s*;"] $data all val] } {
			uplevel set $name "{$val}"
		}
	}
}

# Strips the specified unit string from the passed value.
proc strip_unit {val unit} {
  return [lindex [regexp -inline "(.*)\\s+$unit" $val] 1]
}
