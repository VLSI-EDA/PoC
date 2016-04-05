# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:					Patrick Lehmann
#
# Python Class:			Altera QuartusII specific classes
#
# Description:
# ------------------------------------
#		TODO:
#		-
#		-
#
# License:
# ==============================================================================
# Copyright 2007-2016 Technische Universitaet Dresden - Germany
#											Chair for VLSI-Design, Diagnostics and Architecture
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#		http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================
#
# entry point
from Base.Project import Project as BaseProject, ProjectFile, ConstraintFile


if __name__ != "__main__":
	# place library initialization code here
	pass
else:
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module ToolChains.Altera.QuartusII")


from collections									import OrderedDict
from pathlib											import Path

# from Base.Executable							import Executable, ExecutableArgument, LongFlagArgument, ShortValuedFlagArgument, ShortTupleArgument, PathArgument
from Base.Configuration						import Configuration as BaseConfiguration, ConfigurationException


class Configuration(BaseConfiguration):
	def manualConfigureForWindows(self) :
		# Ask for installed Altera Quartus-II
		isAlteraQuartusII = input('Is Altera Quartus-II installed on your system? [Y/n/p]: ')
		isAlteraQuartusII = isAlteraQuartusII if isAlteraQuartusII != "" else "Y"
		if (isAlteraQuartusII in ['p', 'P']) :
			pass
		elif (isAlteraQuartusII in ['n', 'N']) :
			self.pocConfig['Altera.QuartusII'] = OrderedDict()
		elif (isAlteraQuartusII in ['y', 'Y']) :
			alteraDirectory = input('Altera installation directory [C:\Altera]: ')
			quartusIIVersion = input('Altera QuartusII version number [15.0]: ')
			print()


			alteraDirectory = alteraDirectory if alteraDirectory != ""  else "C:\Altera"
			quartusIIVersion = quartusIIVersion if quartusIIVersion != ""  else "15.0"

			alteraDirectoryPath = Path(alteraDirectory)
			quartusIIDirectoryPath = alteraDirectoryPath / quartusIIVersion / "quartus"

			if not alteraDirectoryPath.exists() :    raise ConfigurationException(
				"Altera installation directory '%s' does not exist." % alteraDirectory)
			if not quartusIIDirectoryPath.exists() :  raise ConfigurationException(
				"Altera QuartusII version '%s' is not installed." % quartusIIVersion)

			self.pocConfig['Altera']['InstallationDirectory'] = alteraDirectoryPath.as_posix()
			self.pocConfig['Altera.QuartusII']['Version'] = quartusIIVersion
			self.pocConfig['Altera.QuartusII']['InstallationDirectory'] = '${Altera:InstallationDirectory}/${Version}'
			self.pocConfig['Altera.QuartusII']['BinaryDirectory'] = '${InstallationDirectory}/quartus/bin64'

			# Ask for installed Altera ModelSimAltera
			isAlteraModelSim = input('Is ModelSim - Altera Edition installed on your system? [Y/n/p]: ')
			isAlteraModelSim = isAlteraModelSim if isAlteraModelSim != "" else "Y"
			if (isAlteraModelSim in ['p', 'P']) :
				pass
			elif (isAlteraModelSim in ['n', 'N']) :
				self.pocConfig['Altera.ModelSim'] = OrderedDict()
			elif (isAlteraModelSim in ['y', 'Y']) :
				alteraModelSimVersion = input('ModelSim - Altera Edition version number [10.1e]: ')

				alteraModelSimDirectoryPath = alteraDirectoryPath / quartusIIVersion / "modelsim_ase"

				if not alteraModelSimDirectoryPath.exists() :  raise BaseException(
					"ModelSim - Altera Edition installation directory '%s' does not exist." % str(alteraModelSimDirectoryPath))

				self.pocConfig['Altera.ModelSim']['Version'] = alteraModelSimVersion
				self.pocConfig['Altera.ModelSim'][
					'InstallationDirectory'] = '${Altera:InstallationDirectory}/${Altera.QuartusII:Version}/modelsim_ase'
				self.pocConfig['Altera.ModelSim']['BinaryDirectory'] = '${InstallationDirectory}/win32aloem'
			else :
				raise ConfigurationException("unknown option")
		else :
			raise ConfigurationException("unknown option")

	def manualConfigureForLinux(self) :
		# Ask for installed Altera Quartus-II
		isAlteraQuartusII = input('Is Altera Quartus-II installed on your system? [Y/n/p]: ')
		isAlteraQuartusII = isAlteraQuartusII if isAlteraQuartusII != "" else "Y"
		if (isAlteraQuartusII in ['p', 'P']) :
			pass
		elif (isAlteraQuartusII in ['n', 'N']) :
			self.pocConfig['Altera.QuartusII'] = OrderedDict()
		elif (isAlteraQuartusII in ['y', 'Y']) :
			alteraDirectory = input('Altera installation directory [/opt/Altera]: ')
			quartusIIVersion = input('Altera QuartusII version number [15.0]: ')
			print()

			alteraDirectory = alteraDirectory if alteraDirectory != ""  else "/opt/Altera"
			quartusIIVersion = quartusIIVersion if quartusIIVersion != ""  else "15.0"

			alteraDirectoryPath = Path(alteraDirectory)
			quartusIIDirectoryPath = alteraDirectoryPath / quartusIIVersion / "quartus"

			if not alteraDirectoryPath.exists() :    raise ConfigurationException(
				"Altera installation directory '%s' does not exist." % alteraDirectory)
			if not quartusIIDirectoryPath.exists() :  raise ConfigurationException(
				"Altera QuartusII version '%s' is not installed." % quartusIIVersion)

			self.pocConfig['Altera']['InstallationDirectory'] = alteraDirectoryPath.as_posix()
			self.pocConfig['Altera.QuartusII']['Version'] = quartusIIVersion
			self.pocConfig['Altera.QuartusII']['InstallationDirectory'] = '${Altera:InstallationDirectory}/${Version}'
			self.pocConfig['Altera.QuartusII']['BinaryDirectory'] = '${InstallationDirectory}/quartus/bin'

			# Ask for installed Altera ModelSimAltera
			isAlteraModelSim = input('Is ModelSim - Altera Edition installed on your system? [Y/n/p]: ')
			isAlteraModelSim = isAlteraModelSim if isAlteraModelSim != "" else "Y"
			if (isAlteraModelSim in ['p', 'P']) :
				pass
			elif (isAlteraModelSim in ['n', 'N']) :
				self.pocConfig['Altera.ModelSim'] = OrderedDict()
			elif (isAlteraModelSim in ['y', 'Y']) :
				alteraModelSimVersion = input('ModelSim - Altera Edition version number [10.1e]: ')

				alteraModelSimDirectoryPath = alteraDirectoryPath / quartusIIVersion / "modelsim_ase"

				if not alteraModelSimDirectoryPath.exists() :  raise BaseException(
					"ModelSim - Altera Edition installation directory '%s' does not exist." % str(alteraModelSimDirectoryPath))

				self.pocConfig['Altera.ModelSim']['Version'] = alteraModelSimVersion
				self.pocConfig['Altera.ModelSim'][
					'InstallationDirectory'] = '${Altera:InstallationDirectory}/${Altera.QuartusII:Version}/modelsim_ase'
				self.pocConfig['Altera.ModelSim']['BinaryDirectory'] = '${InstallationDirectory}/bin'
			else :
				raise ConfigurationException("unknown option")
		else :
			raise ConfigurationException("unknown option")


class QuartusProject(BaseProject):
	def __init__(self, name):
		super().__init__(name)


class QuartusProjectFile(ProjectFile):
	def __init__(self, file):
		super().__init__(file)


class SynopsysDesignConstraintFile(ConstraintFile):
	def __init__(self, file):
		super().__init__(file)