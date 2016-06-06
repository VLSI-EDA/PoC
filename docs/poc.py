
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
		self.EntitySourceCodeRange =  entitySourceCodeRange
		self.Authors =                []
		self.Summary =                ""  # summary
		self.Description =            ""  # description
		self.SeeAlso =                ""  # seeAlso


class Extract:
	def __init__(self):
		self.sourceDirectory =     Path("../src")
		self.outputDirectory =     Path("PoC")
		self.relSourceDirectory =  Path("../../src")

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
				if (stem not in ["Altera", "altera", "Lattice", "lattice", "Xilinx", "xilinx"]):
					print("cd {0}".format(stem))
					result[stem] = self.recursion(item)
			elif item.is_file():
				if (item.suffix == ".vhdl"):
					if (not item.stem.endswith(("Altera", "altera", "Lattice", "lattice", "Xilinx", "xilinx"))):
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
		relPath =     sourceFile.File.relative_to(self.sourceDirectory)
		outputFile =  self.outputDirectory / relPath.with_suffix(".rst")
		relSourceFile = ("../" * (len(relPath.parents) - 1)) / self.relSourceDirectory / relPath

		print("Writing reST file '{0!s}'.".format(outputFile))

		# print("  Authors: {0}".format(", ".join(sourceFile.Authors)))
		# print("  Summary: {0}".format(sourceFile.Summary))
		# print("  Entity '{0}' at {1}..{2}.".format(sourceFile.EntityName, sourceFile.EntitySourceCodeRange.StartRow, sourceFile.EntitySourceCodeRange.EndRow))

		if (sourceFile.SeeAlso != ""):
			seeAlsoBox = ".. seealso::\n   \n"
			for line in sourceFile.SeeAlso.splitlines():
				seeAlsoBox += "   {line}\n".format(line=line)
		else:
			seeAlsoBox = ""

		outputContent = self.templateContent.format(
			EntityName=sourceFile.EntityName,
			EntityNameUnderline="#" * len(sourceFile.EntityName),
			EntityDescription=sourceFile.Description,
			EntityFilePath=relSourceFile.as_posix(),
			EntityDeclarationFromTo="{0}-{1}".format(sourceFile.EntitySourceCodeRange.StartRow, sourceFile.EntitySourceCodeRange.EndRow),
			SeeAlsoBox=seeAlsoBox
		)

		with outputFile.open('w') as restructuredTextHandle:
			restructuredTextHandle.write(outputContent)

	def ExtractComments(self, sourceFile):
		print("  Reading '{0!s}'...".format(sourceFile))

		entityStartRegExpStr = r"(?i)\s*entity\s+(?P<EntityName>\w+)\s+is"
		entityEndRegExpStr =   r"(?i)\s*end\s+entity(?:\s+\w+)?\s*;"

		entityStartRegExp = re_compile(entityStartRegExpStr)
		entityEndRegExp =   re_compile(entityEndRegExpStr)

		class State(Enum):
			StartOfDocument =   0
			StartOfComments =   1
			Authors =           2
			Summary =           3
			Description =       4
			DescriptionLine =   5
			SeeAlso =           6
			License =           10
			EntityStart =       20
			EntityEnd =         21


		state = State.StartOfDocument

		result = SourceFile(SourceCodeRange(sourceFile, 0, 0))

		entityName =          ""
		entityStartLine =     0
		entityEndLine =       0

		authorsContent =      ""
		summary =             ""
		descriptionContent =  ""
		seeAlsoContent =      ""

		with sourceFile.open('r') as vhdlFileHandle:
			lineNumber = 0
			for line in vhdlFileHandle:
				lineNumber += 1

				if (state is State.StartOfDocument):
					if line.startswith("-- ============================================================================"):
						state =           State.StartOfComments

				elif (state is State.StartOfComments):
					if line.startswith("-- Authors:"):
						state =           State.Authors
						authorsContent =  line[11:].lstrip()

				elif (state is State.Authors):
					if line.startswith("-- Entity:"):
						state =           State.Summary
						summary =         line[10:-1].lstrip()
					else:
						authorsContent += line[3:].lstrip()

				elif (state is State.Summary):
					if line.startswith("-- Description:"):
						state = State.DescriptionLine

				elif (state is State.DescriptionLine):
					if line.startswith("-- ------------------------------------"):
						state = State.Description

				elif (state is State.Description):
					if line.startswith("-- SeeAlso:"):
						state = State.SeeAlso
					elif line.startswith("-- License:"):
						state = State.License
					else:
						descriptionContent += line[3:]

				elif (state is State.SeeAlso):
					if line.startswith("-- License:"):
						state =           State.License
					else:
						seeAlsoContent += line[3:]

				elif (state is State.License):
					entityStartMatch = entityStartRegExp.match(line)
					if (entityStartMatch is not None):
						entityName = entityStartMatch.group("EntityName")
						entityStartLine = lineNumber
						state =           State.EntityStart

				elif (state is State.EntityStart):
					entityEndMatch =    entityEndRegExp.match(line)
					if (entityEndMatch is not None):
						entityEndLine =   lineNumber
						state =           State.EntityEnd
						break

			else:
				raise Exception("No entity found. LastState = {0}".format(state.name))

		if (state is not State.EntityEnd):
			raise Exception("Last state not reached. LastState = {0}".format(state.name))

		result.Authors =      [author for author in authorsContent.splitlines()]
		result.Summary =      summary
		result.Description =  descriptionContent
		result.SeeAlso =      seeAlsoContent
		result.EntityName =   entityName
		result.EntitySourceCodeRange.StartRow = entityStartLine
		result.EntitySourceCodeRange.EndRow = entityEndLine

		return result


if (__name__ == "__main__"):
	e = Extract()
	e.Run()
