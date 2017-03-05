# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
#
# Python Module:    GHDL simulator.
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
# load dependencies
from pathlib                import Path

from Base.Exceptions        import NotConfiguredException
from Base.Executable        import DryRunException
from Base.Logging           import Severity
from Base.Project           import FileTypes, VHDLVersion, ToolChain, Tool
from Simulator              import VHDL_TESTBENCH_LIBRARY_NAME, SimulatorException, SkipableSimulatorException, SimulationSteps, Simulator as BaseSimulator
from ToolChain.GHDL         import GHDL, GHDLException, GHDLReanalyzeException
from ToolChain.GTKWave      import GTKWave
from ToolChain.GNU          import LCov, GenHtml


__api__ = [
	'Simulator'
]
__all__ = __api__


class Simulator(BaseSimulator):
	"""This class encapsulates the GHDL simulator."""

	TOOL_CHAIN =      ToolChain.GHDL_GTKWave
	TOOL =            Tool.GHDL

	class __Directories__(BaseSimulator.__Directories__):
		GTKWBinary = None

	def __init__(self, host, dryRun, simulationSteps):
		"""Constructor"""
		super().__init__(host, dryRun, simulationSteps)

		ghdlFilesDirectoryName =        host.PoCConfig['CONFIG.DirectoryNames']['GHDLFiles']
		self.Directories.Working =      host.Directories.Temp / ghdlFilesDirectoryName
		self.Directories.PreCompiled =  host.Directories.PreCompiled / ghdlFilesDirectoryName

		self._withCoverage =            False

		self._PrepareSimulationEnvironment()
		self._PrepareSimulator()

		if (self._toolChain.Backend == "mcode"):
			# A separate elaboration step is not implemented in GHDL (mcode)
			self._simulationSteps &= ~SimulationSteps.Elaborate

		if (SimulationSteps.ShowWaveform in self._simulationSteps):
			# prepare paths for GTKWave, if configured
			sectionName = 'INSTALL.GTKWave'
			if (len(host.PoCConfig.options(sectionName)) != 0):
				self.Directories.GTKWBinary = Path(host.PoCConfig[sectionName]['BinaryDirectory'])
			else:
				raise NotConfiguredException("No GHDL compatible waveform viewer is configured on this system.")

	def _PrepareSimulator(self):
		"""Create the GHDL executable factory instance."""
		self.LogVerbose("Preparing GHDL simulator.")
		ghdlSection =     self.Host.PoCConfig['INSTALL.GHDL']
		binaryPath =      Path(ghdlSection['BinaryDirectory'])
		version =         ghdlSection['Version']
		backend =         ghdlSection['Backend']
		self._toolChain = GHDL(self.Host.Platform, self.DryRun, binaryPath, version, backend, logger=self.Logger)

	def Run(self, testbench, board, vhdlVersion, vhdlGenerics=None, withCoverage=False):
		self._withCoverage = withCoverage

		super().Run(testbench, board, vhdlVersion, vhdlGenerics)

	def _RunAnalysis(self, testbench):
		""""""

		# create a GHDLAnalyzer instance
		ghdl = self._toolChain.GetGHDLAnalyze()
		ghdl.Parameters[ghdl.FlagVerbose] =           (self.Logger.LogLevel is Severity.Debug)
		ghdl.Parameters[ghdl.FlagExplicit] =          True
		ghdl.Parameters[ghdl.FlagRelaxedRules] =      True
		ghdl.Parameters[ghdl.FlagWarnBinding] =       True
		ghdl.Parameters[ghdl.FlagNoVitalChecks] =     True
		ghdl.Parameters[ghdl.FlagMultiByteComments] = True
		ghdl.Parameters[ghdl.FlagSynBinding] =        True
		ghdl.Parameters[ghdl.FlagPSL] =               True

		if (self._withCoverage is True):
			ghdl.Parameters[ghdl.FlagDebug] =           True
			ghdl.Parameters[ghdl.FlagProfileArcs] =     True
			ghdl.Parameters[ghdl.FlagTestCoverage] =    True

		self._SetVHDLVersionAndIEEEFlavor(ghdl)
		self._SetExternalLibraryReferences(ghdl)

		# run GHDL analysis for each VHDL file
		for file in self._pocProject.Files(fileType=FileTypes.VHDLSourceFile):
			if (not file.Path.exists()):                  raise SkipableSimulatorException("Cannot analyse '{0!s}'.".format(file.Path)) from FileNotFoundError(str(file.Path))

			ghdl.Parameters[ghdl.SwitchVHDLLibrary] =     file.LibraryName
			ghdl.Parameters[ghdl.ArgSourceFile] =         file.Path
			try:
				ghdl.Analyze()
			except DryRunException:
				pass
			except GHDLReanalyzeException as ex:
				raise SkipableSimulatorException("Error while analysing '{0!s}'.".format(file.Path)) from ex
			except GHDLException as ex:
				raise SimulatorException("Error while analysing '{0!s}'.".format(file.Path)) from ex
			if ghdl.HasErrors:
				raise SkipableSimulatorException("Error while analysing '{0!s}'.".format(file.Path))

	def _SetVHDLVersionAndIEEEFlavor(self, ghdl):
		""""""

		ghdl.Parameters[ghdl.SwitchIEEEFlavor] =  "synopsys"

		if (self._vhdlVersion is VHDLVersion.VHDL93):
			ghdl.Parameters[ghdl.SwitchVHDLVersion] = "93c"
		else:
			ghdl.Parameters[ghdl.SwitchVHDLVersion] = repr(self._vhdlVersion)[-2:]

	def _SetExternalLibraryReferences(self, ghdl):
		""""""

		# add external library references
		externalLibraryReferences = []
		for extLibrary in self._pocProject.ExternalVHDLLibraries:
			path = str(extLibrary.Path)
			if (path not in externalLibraryReferences):
				externalLibraryReferences.append(path)
		ghdl.Parameters[ghdl.ArgListLibraryReferences] = externalLibraryReferences

	# running elaboration
	# ==========================================================================
	def _RunElaboration(self, testbench):
		""""""

		if (self._toolChain.Backend == "mcode"):
			return

		# create a GHDLElaborate instance
		ghdl = self._toolChain.GetGHDLElaborate()
		ghdl.Parameters[ghdl.FlagVerbose] =           (self.Logger.LogLevel is Severity.Debug)
		ghdl.Parameters[ghdl.SwitchVHDLLibrary] =     VHDL_TESTBENCH_LIBRARY_NAME
		ghdl.Parameters[ghdl.ArgTopLevel] =           testbench.ModuleName
		ghdl.Parameters[ghdl.FlagExplicit] =          True

		if (self._withCoverage is True):
			ghdl.Parameters[ghdl.SwitchLinkerOption] =  ("-L/opt/ghdl/0.34-dev-gcc4/lib/gcc/x86_64-unknown-linux-gnu/4.9.4", "-lgcov", "--coverage")

		self._SetVHDLVersionAndIEEEFlavor(ghdl)
		self._SetExternalLibraryReferences(ghdl)

		try:
			ghdl.Elaborate()
		except DryRunException:
			pass
		except GHDLException as ex:
			raise SimulatorException("Error while elaborating '{0}.{1}'.".format(VHDL_TESTBENCH_LIBRARY_NAME, testbench.ModuleName)) from ex
		if ghdl.HasErrors:
			raise SkipableSimulatorException("Error while elaborating '{0}.{1}'.".format(VHDL_TESTBENCH_LIBRARY_NAME, testbench.ModuleName))

	def _RunSimulation(self, testbench):
		""""""

		# create a GHDLRun instance
		ghdl = self._toolChain.GetGHDLRun()
		ghdl.Parameters[ghdl.FlagVerbose] =             (self.Logger.LogLevel is Severity.Debug)
		ghdl.Parameters[ghdl.FlagExplicit] =            True
		ghdl.Parameters[ghdl.FlagRelaxedRules] =        True
		ghdl.Parameters[ghdl.FlagWarnBinding] =         True
		ghdl.Parameters[ghdl.FlagNoVitalChecks] =       True
		ghdl.Parameters[ghdl.FlagMultiByteComments] =   True
		ghdl.Parameters[ghdl.FlagSynBinding] =          True
		ghdl.Parameters[ghdl.FlagPSL] =                 True
		ghdl.Parameters[ghdl.SwitchVHDLLibrary] =       VHDL_TESTBENCH_LIBRARY_NAME
		ghdl.Parameters[ghdl.ArgTopLevel] =             testbench.ModuleName

		self._SetVHDLVersionAndIEEEFlavor(ghdl)
		self._SetExternalLibraryReferences(ghdl)

		# configure RUNOPTS
		ghdl.RunOptions[ghdl.SwitchIEEEAsserts] = "disable-at-0"		# enable, disable, disable-at-0
		# set dump format to save simulation results to *.vcd file
		if (SimulationSteps.ShowWaveform in self._simulationSteps):
			configSection = self.Host.PoCConfig[testbench.ConfigSectionName]
			testbench.WaveformOptionFile = Path(configSection['ghdlWaveformOptionFile'])
			testbench.WaveformFileFormat = configSection['ghdlWaveformFileFormat']

			if (testbench.WaveformFileFormat == "vcd"):
				waveformFilePath = self.Directories.Working / (testbench.ModuleName + ".vcd")
				ghdl.RunOptions[ghdl.SwitchVCDWaveform] =     waveformFilePath
			elif (testbench.WaveformFileFormat == "vcdgz"):
				waveformFilePath = self.Directories.Working / (testbench.ModuleName + ".vcd.gz")
				ghdl.RunOptions[ghdl.SwitchVCDGZWaveform] =   waveformFilePath
			elif (testbench.WaveformFileFormat == "fst"):
				waveformFilePath = self.Directories.Working / (testbench.ModuleName + ".fst")
				ghdl.RunOptions[ghdl.SwitchFSTWaveform] =     waveformFilePath
			elif (testbench.WaveformFileFormat == "ghw"):
				waveformFilePath = self.Directories.Working / (testbench.ModuleName + ".ghw")
				ghdl.RunOptions[ghdl.SwitchGHDLWaveform] =    waveformFilePath
			else:                                           raise SimulatorException("Unknown waveform file format for GHDL.")

			testbench.WaveformFile = waveformFilePath
			if testbench.WaveformOptionFile.exists():
				ghdl.RunOptions[ghdl.SwitchWaveformOptionFile] =  testbench.WaveformOptionFile

		try:
			testbench.Result = ghdl.Run()
		except DryRunException:
			pass

	def _RunView(self, testbench):
		"""foo"""

		if (not testbench.WaveformFile.exists()):
			raise SkipableSimulatorException("Waveform file '{0!s}' not found.".format(testbench.WaveformFile)) \
				from FileNotFoundError(str(testbench.WaveformFile))

		gtkwBinaryPath =    self.Directories.GTKWBinary
		gtkwVersion =       self.Host.PoCConfig['INSTALL.GTKWave']['Version']
		gtkw = GTKWave(self.Host.Platform, self.DryRun, gtkwBinaryPath, gtkwVersion, logger=self.Logger)
		gtkw.Parameters[gtkw.SwitchDumpFile] = str(testbench.WaveformFile)

		# if GTKWave savefile exists, load it's settings
		configSection =     self.Host.PoCConfig[testbench.ConfigSectionName]
		gtkwSaveFilePath =  self.Host.Directories.Root / configSection['gtkwSaveFile']
		if gtkwSaveFilePath.exists():
			self.LogDebug("Found waveform save file: '{0!s}'".format(gtkwSaveFilePath))
			gtkw.Parameters[gtkw.SwitchSaveFile] = str(gtkwSaveFilePath)
		else:
			self.LogDebug("Didn't find waveform save file: '{0!s}'".format(gtkwSaveFilePath))

		# run GTKWave GUI
		try:
			gtkw.View()
		except DryRunException:
			pass

		# clean-up *.gtkw files
		if gtkwSaveFilePath.exists():
			self.LogVerbose("Cleaning up GTKWave save file...")
			removeKeys =  ("[dumpfile]", "[savefile]")
			buffer =      ""
			with gtkwSaveFilePath.open('r') as gtkwHandle:
				# search for these keys in the first 10 header lines
				for lineNumber,line in enumerate(gtkwHandle):
					if (not line.startswith(removeKeys)):   buffer += line
					if (lineNumber > 10):                   break
				# copy remaining lines without processing
				for line in gtkwHandle:
					buffer += line
			with gtkwSaveFilePath.open('w') as gtkwHandle:
				gtkwHandle.write(buffer)

	def _RunCoverage(self, testbench):
		if (self._withCoverage is False):
			pass
			# self.LogError("No coverage information collected.")
			# return

		coverageStatisticsFile =            "coverage.info"
		coverageStatisticsOutputDirectory = "html"

		lCov = LCov(self.Host.Platform, self.DryRun, logger=self.Logger)
		lCov.Parameters[lCov.FlagCapture] =       True
		lCov.Parameters[lCov.SwitchDirectory] =   "."
		lCov.Parameters[lCov.SwitchOutputFile] =  coverageStatisticsFile
		lCov.Execute()

		genHtml = GenHtml(self.Host.Platform, self.DryRun, logger=self.Logger)
		genHtml.Parameters[genHtml.SwitchOutputDirectory] = coverageStatisticsOutputDirectory
		genHtml.Parameters[genHtml.SwitchInputFiles] =      [coverageStatisticsFile]
		genHtml.Execute()
