# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:					Patrick Lehmann
#
# Python Class:			Mentor specific classes
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
if __name__ != "__main__":
	# place library initialization code here
	pass
else:
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("PoC Library - Python Module ToolChains.Mentor.QuestaSim")

from Base.Configuration import Configuration as BaseConfiguration
from Base.ToolChain			import ToolChainException


class MentorException(ToolChainException):
	pass


class Configuration(BaseConfiguration):
	_vendor =			"Mentor"
	_toolName =		None  # automatically configure only vendor path
	_section =		"INSTALL.Mentor"
	_template = {
		"Windows": {
			_section: {
				"InstallationDirectory": "C:/Mentor"
			}
		},
		"Linux":   {
			_section: {
				"InstallationDirectory": "/opt/QuestaSim"
			}
		}
	}

	def _GetDefaultInstallationDirectory(self):
		path = self._TestDefaultInstallPath({"Windows": "Mentor", "Linux": "Mentor"})
		if path is None: return super()._GetDefaultInstallationDirectory()
		return str(path)


	# 
	# 
	# def manualConfigureForWindows(self) :
	# 	# Ask for installed Mentor Graphic tools
	# 	isMentor = input('Is a Mentor Graphics tool installed on your system? [Y/n/p]: ')
	# 	isMentor = isMentor if isMentor != "" else "Y"
	# 	if (isMentor in ['p', 'P']) :
	# 		pass
	# 	elif (isMentor in ['n', 'N']) :
	# 		self.pocConfig['Mentor'] = OrderedDict()
	# 	elif (isMentor in ['y', 'Y']) :
	# 		mentorDirectory = input('Mentor Graphics installation directory [C:\Mentor]: ')
	# 		print()
	# 
	# 		mentorDirectory = mentorDirectory if mentorDirectory != ""  else "C:\Altera"
	# 		QuartusVersion = QuartusVersion if QuartusVersion != ""  else "15.0"
	# 
	# 		mentorDirectoryPath = Path(mentorDirectory)
	# 
	# 		if not mentorDirectoryPath.exists() :    raise BaseException(
	# 			"Mentor Graphics installation directory '%s' does not exist." % mentorDirectory)
	# 
	# 		self.pocConfig['Mentor']['InstallationDirectory'] = mentorDirectoryPath.as_posix()
	# 
	# 		# Ask for installed Mentor QuestaSIM
	# 		isQuestaSim = input('Is Mentor QuestaSIM installed on your system? [Y/n/p]: ')
	# 		isQuestaSim = isQuestaSim if isQuestaSim != "" else "Y"
	# 		if (isQuestaSim in ['p', 'P']) :
	# 			pass
	# 		elif (isQuestaSim in ['n', 'N']) :
	# 			self.pocConfig['Mentor.QuestaSIM'] = OrderedDict()
	# 		elif (isQuestaSim in ['y', 'Y']) :
	# 			QuestaSimDirectory = input(
	# 				'QuestaSIM installation directory [{0}\QuestaSim64\\10.2c]: '.format(str(mentorDirectory)))
	# 			QuestaSimVersion = input('QuestaSIM version number [10.4c]: ')
	# 			print()
	# 
	# 			QuestaSimDirectory = QuestaSimDirectory if QuestaSimDirectory != ""  else str(
	# 				mentorDirectory) + "\QuestaSim64\\10.4c"
	# 			QuestaSimVersion = QuestaSimVersion if QuestaSimVersion != ""    else "10.4c"
	# 
	# 			QuestaSimDirectoryPath = Path(QuestaSimDirectory)
	# 			QuestaSimExecutablePath = QuestaSimDirectoryPath / "win64" / "vsim.exe"
	# 
	# 			if not QuestaSimDirectoryPath.exists() :    raise ConfigurationException(
	# 				"QuestaSIM installation directory '%s' does not exist." % QuestaSimDirectory)
	# 			if not QuestaSimExecutablePath.exists() :  raise ConfigurationException("QuestaSIM is not installed.")
	# 
	# 			self.pocConfig['Mentor']['InstallationDirectory'] = MentorDirectoryPath.as_posix()
	# 
	# 			self.pocConfig['Mentor.QuestaSIM']['Version'] = QuestaSimVersion
	# 			self.pocConfig['Mentor.QuestaSIM']['InstallationDirectory'] = QuestaSimDirectoryPath.as_posix()
	# 			self.pocConfig['Mentor.QuestaSIM']['BinaryDirectory'] = '${InstallationDirectory}/win64'
	# 		else :
	# 			raise ConfigurationException("unknown option")
	# 	else :
	# 		raise ConfigurationException("unknown option")
	# 
	# def manualConfigureForLinux(self) :
	# 	# Ask for installed Mentor QuestaSIM
	# 	isQuestaSim = input('Is mentor QuestaSIM installed on your system? [Y/n/p]: ')
	# 	isQuestaSim = isQuestaSim if isQuestaSim != "" else "Y"
	# 	if (isQuestaSim in ['p', 'P']) :
	# 		pass
	# 	elif (isQuestaSim in ['n', 'N']) :
	# 		self.pocConfig['Mentor.QuestaSIM'] = OrderedDict()
	# 	elif (isQuestaSim in ['y', 'Y']) :
	# 		QuestaSimDirectory = input('QuestaSIM installation directory [/opt/QuestaSim/10.2c]: ')
	# 		QuestaSimVersion = input('QuestaSIM version number [10.2c]: ')
	# 		print()
	# 
	# 		QuestaSimDirectory = QuestaSimDirectory if QuestaSimDirectory != ""  else "/opt/QuestaSim/10.2c"
	# 		QuestaSimVersion = QuestaSimVersion if QuestaSimVersion != ""    else "10.2c"
	# 
	# 		QuestaSimDirectoryPath = Path(QuestaSimDirectory)
	# 		QuestaSimExecutablePath = QuestaSimDirectoryPath / "bin" / "vsim"
	# 
	# 		if not QuestaSimDirectoryPath.exists() :    raise ConfigurationException(
	# 			"QuestaSIM installation directory '%s' does not exist." % QuestaSimDirectory)
	# 		if not QuestaSimExecutablePath.exists() :  raise ConfigurationException("QuestaSIM is not installed.")
	# 
	# 		self.pocConfig['Mentor.QuestaSIM']['Version'] = QuestaSimVersion
	# 		self.pocConfig['Mentor.QuestaSIM']['InstallationDirectory'] = QuestaSimDirectoryPath.as_posix()
	# 		self.pocConfig['Mentor.QuestaSIM']['BinaryDirectory'] = '${InstallationDirectory}/bin'
	# 	else :
	# 		raise ConfigurationException("unknown option")
