# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
#	Authors:						Patrick Lehmann
#
#	PowerShell Module:
#
# Description:
# ------------------------------------
#	TODO:
#		-
#
# License:
# ==============================================================================
# Copyright 2007-2016 Technische Universitaet Dresden - Germany
#                     Chair of VLSI-Design, Diagnostics and Architecture
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================
#
function Open-Environment
{	$Debug = $false

	Write-Host "Loading module PoC..."
	Import-Module "${env:PoCRootDirectory}\py\Wrapper\PoC.psm1" -Scope Global -ArgumentList @($Py_Interpreter, $Py_Parameters, $PoC_Query)

	return 1
}

function Close-Environment
{	return 0
}

Export-ModuleMember -Function 'Open-Environment'
Export-ModuleMember -Function 'Close-Environment'
