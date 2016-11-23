# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
#	Authors:          Patrick Lehmann
#										Thomas B. Preußer
#
#	Python Script:    Extract embedded ReST documentation from VHDL primary units
#
# Description:
# ------------------------------------
#	undocumented
#
# License:
# ==============================================================================
# Copyright 2007-2016 Technische Universitaet Dresden - Germany
#											Chair of VLSI-Design, Diagnostics and Architecture
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
from enum           import Enum
from pathlib        import Path
from re             import compile as re_compile
from textwrap       import dedent

def setup(app):
	pass

class SourceCodeRange:
	def __init__(self, file, startRow, endRow):
		self.SourceFile = file
		self.StartRow =   startRow
		self.EndRow =     endRow


class SourceFile:
	def __init__(self, entitySourceCodeRange):    #, entityName, entitySourceCodeRange, summary, description, seeAlso):
		self.File =                   entitySourceCodeRange.SourceFile
		self.EntityName =             ""  # entityName
		self.EntityFullName =         ""  # entityName
		self.EntitySourceCodeRange =  entitySourceCodeRange
		self.Authors =                []
		self.Summary =                ""  # summary
		self.Description =            ""  # description
		self.SeeAlso =                ""  # seeAlso


class Extract:
	def __init__(self):
		self.sourceDirectory =       Path("../src")
		self.outputDirectory =       Path("IPCores")
		self.relSourceDirectory =    Path("../../src")
		self.relTestbenchDirectory = Path("../../tb")

		self.templateFile =     Path("Entity.template")
		self.templateContent =  ""

	def Run(self):
		result = self.recursion(self.sourceDirectory)

		print("Reading template file...")
		with self.templateFile.open('r') as templateFileHandle:
			self.templateContent = templateFileHandle.read()

		print("Writing reStructuredText files...")
		self.recursion2(result)

	def recursion(self, sourceDirectory):
		result = {}

		for item in sourceDirectory.iterdir():
			if item.is_dir():
				stem = item.stem
				if ((stem not in ["Altera", "altera", "Lattice", "lattice", "Xilinx", "xilinx"]) and not stem.startswith(("cvs_", "old_"))):
					print("cd {0}".format(stem))
					result[stem] = self.recursion(item)
			elif item.is_file():
				if (item.suffix == ".vhdl"):
					if (not item.stem.endswith(("Altera", "altera", "Lattice", "lattice", "Xilinx", "xilinx")) and not item.stem.startswith(("cvs_", "old_"))):
						try:
							result[item.stem] = self.ExtractComments(item)
						except Exception as ex:
							print("    " + str(ex))

		return result

	def recursion2(self, result):
		for item in result.values():
			if isinstance(item, dict):
				self.recursion2(item)
			elif isinstance(item, SourceFile):
				self.writeReST(item)

	def writeReST(self, sourceFile):
		sourceRelPath =     sourceFile.File.relative_to(self.sourceDirectory)
		outputFile =  self.outputDirectory / sourceRelPath.with_suffix(".rst")
		relSourceFile = ("../" * (len(sourceRelPath.parents) - 1)) / self.relSourceDirectory / sourceRelPath

		testbenchRelPath = Path(sourceRelPath.with_name(sourceRelPath.stem + "_tb.vhdl"))

		print("Writing reST file '{0!s}'.".format(outputFile))

		# print("  Authors: {0}".format(", ".join(sourceFile.Authors)))
		# print("  Summary: {0}".format(sourceFile.Summary))
		# print("  Entity '{0}' at {1}..{2}.".format(sourceFile.EntityName, sourceFile.EntitySourceCodeRange.StartRow, sourceFile.EntitySourceCodeRange.EndRow))

		if (sourceFile.SeeAlso != ""):
			seeAlsoBox = ".. seealso::\n\n"
			for line in sourceFile.SeeAlso.splitlines():
				if line == "": seeAlsoBox += "\n"
				else: seeAlsoBox += "   {line}\n".format(line=line)
		else:
			seeAlsoBox = ""

		outputContent = self.templateContent.format(
			EntityName=sourceFile.EntityName,
			EntityFullName=sourceFile.EntityFullName,
			EntityNameUnderline="#" * len(sourceFile.EntityFullName),
			EntityDescription=sourceFile.Description,
			EntityFilePath=relSourceFile.as_posix(),
			EntityDeclarationFromTo="{0}-{1}".format(sourceFile.EntitySourceCodeRange.StartRow, sourceFile.EntitySourceCodeRange.EndRow),
			SourceRelPath=sourceRelPath.as_posix(),
			TestbenchRelPath=testbenchRelPath.as_posix(),
			SeeAlsoBox=seeAlsoBox
		)

		with outputFile.open('w') as restructuredTextHandle:
			restructuredTextHandle.write(outputContent)

	def ExtractComments(self, sourceFile):
		"""
		Extracts the documentation from the header of a PoC VHDL source.

		* The documentation header starts with a separator line matching /^--\s*={16,}$/.
		* The documentation header continues through all immediately following comment lines.
		* The contained information is added to the currently active section.
		* A specific section is opened by a line matching /^--\s*(?P<Section>\w+):/ with
		  <Section> as one of Authors|Entity|Description|SeeAlso|License.
		* An underline /^-- -+$/ immediately following a section opening is ignored.
		* After the documentation header, the entity name is extracted from the entity declaration.
		"""
		class State(Enum):
			BeforeDocHeader  = 0
			InDocHeader      = 1
			BeforeEntityDecl = 2
			InEntityDecl     = 3
			Done             = 4

		sectionStrip = {
			'Authors':     True,
			'Entity':      True,
			'Description': False,
			'SeeAlso':     False,
			'License':     False
		}
		sections = {
			'Authors':     '',
			'Entity':      '',
			'Description': '',
			'SeeAlso':     '',
			'License':     ''
		}

		headerStartRE  = re_compile(r'^--\s*={16,}$')
		sectionStartRE = re_compile(r'^--\s*(?P<Section>'+('|'.join(sections.keys()))+r'):\s*(?P<Content>.*)$')
		underlineRE    = re_compile(r'^-- -+$')
		commentStripRE = re_compile(r'^-- ?')

		entityStartRE = re_compile(r"(?i)entity\s+(?P<EntityName>\w+)\s+is")
		entityEndRE   = re_compile(r"(?i)end\s+(?P<EntityName>\w+)(\s+\w+)?\s*;")

		entityName =          ""
		entityStartLine =     0
		entityEndLine =       0

		# Parse the Source File
		print("  Reading '{0!s}'...".format(sourceFile))
		state = State.BeforeDocHeader
		with sourceFile.open('r') as vhdlFileHandle:
			lineNumber = 0
			for line in vhdlFileHandle:
				lineNumber += 1

				# Parse Documentation Header into Sections
				if state is State.BeforeDocHeader:
					if headerStartRE.match(line):
						section = None
						state   = State.InDocHeader

				elif state is State.InDocHeader:
					if not line.startswith('--'):
						state = State.BeforeEntityDecl
					else:
						m = sectionStartRE.match(line)
						if m:
							section = m.group('Section')
							sections[section] += m.group('Content')
						elif sections[section] != '' or not underlineRE.match(line):
							line = commentStripRE.sub('', line)
							sections[section] += line.lstrip() if sectionStrip[section] else line

				# Parse Entity Declaration
				if state is State.BeforeDocHeader or state is State.BeforeEntityDecl:
					m = entityStartRE.match(line)
					if m:
						entityName      = m.group("EntityName")
						entityStartLine = lineNumber
						state           = State.InEntityDecl

				elif state is State.InEntityDecl:
					m = entityEndRE.match(line)
					if m:
						name = m.group('EntityName')
						if name == 'entity' or name == entityName:
							entityEndLine = lineNumber
							state         = State.Done
							break

		if state is not State.Done:
			raise Exception("No entity found. LastState = {0}".format(state.name))

		# Construct Result Object
		result = SourceFile(SourceCodeRange(sourceFile, 0, 0))
		result.Authors =        [author for author in sections['Authors'].splitlines()]
		result.Summary =        sections['Entity']
		result.Description =    sections['Description']
		result.SeeAlso =        sections['SeeAlso']
		result.EntityName =     entityName
		result.EntityFullName = "PoC." + ".".join(sourceFile.parts[2:-1]) + "." + sourceFile.stem[len(sourceFile.parts[-2])+1:]
		result.EntitySourceCodeRange.StartRow = entityStartLine
		result.EntitySourceCodeRange.EndRow = entityEndLine
		return result

if (__name__ == "__main__"):
	e = Extract()
	e.Run()
