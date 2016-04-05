# EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:         			Patrick Lehmann
#
# Python Sub Module:  	TODO:
#
# Description:
# ------------------------------------
#    TODO:
#
#
# License:
# ==============================================================================
# Copyright 2007-2016 Technische Universitaet Dresden - Germany
#                     Chair for VLSI-Design, Diagnostics and Architecture
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================
#
# entry point
if __name__ != "__main__":
	# place library initialization code here
	pass
else:
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("The PoC-Library - Repository Service Tool")

from .Aldec.ActiveHDL		import Configuration as ActiveHDL_Configuration
from .Altera.QuartusII	import Configuration as Quartus_Configuration
from .GHDL							import Configuration as GHDL_Configuration
from .GTKWave						import Configuration as GTKW_Configuration
from .Lattice.Diamond		import Configuration as Diamond_Configuration
from .Mentor.QuestaSim	import Configuration as Questa_Configuration
from .PoC								import Configuration as PoC_Configuration
from .Xilinx.ISE				import Configuration as ISE_Configuration
from .Xilinx.Vivado			import Configuration as Vivado_Configuration

Configurations = [
	PoC_Configuration,
	ISE_Configuration,
	Vivado_Configuration,
	Quartus_Configuration,
	Questa_Configuration,
	Diamond_Configuration,
	ActiveHDL_Configuration,
	GHDL_Configuration,
	GTKW_Configuration
]
