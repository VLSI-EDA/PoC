# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
# Authors:          Patrick Lehmann
#
# Python Module:    TODO
# 
# Description:
# ------------------------------------
#		TODO:
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
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================
#
from lib.Parser     import MismatchingParserResult, MatchingParserResult, EmptyChoiseParserResult, StartOfDocumentToken
from lib.Parser     import SpaceToken, CharacterToken, StringToken
from lib.CodeDOM    import EmptyLine, CommentLine, BlockedStatement as BlockStatementBase, StringLiteral
from lib.CodeDOM    import Statement, BlockStatement


# ==============================================================================
# Blocked Statements (Forward declaration)
# ==============================================================================
class InFileStatements(BlockStatementBase):
	_allowedStatements = []

class PreProcessStatements(BlockStatementBase):
	_allowedStatements = []

class PostProcessStatements(BlockStatementBase):
	_allowedStatements = []

class DocumentStatements(BlockStatementBase):
	_allowedStatements = []


# ==============================================================================
# File Reference Statements
# ==============================================================================
class CopyStatement(Statement):
	def __init__(self, source, destination, commentText):
		super().__init__()
		self._sourcePath =      source
		self._destinationPath = destination
		self._commentText =     commentText

	@property
	def SourcePath(self):       return self._sourcePath
	@property
	def DestinationPath(self):  return self._destinationPath
	
	@classmethod
	def GetParser(cls):
		# match for optional whitespacex
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for COPY keyword
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("CopyParser: Expected COPY keyword.")
		if (token.Value.lower() != "copy"):         raise MismatchingParserResult("CopyParser: Expected COPY keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult("CopyParser: Expected whitespace before source filename.")

		# match for string: 		sourceFile; use a StringLiteralParser to parse the pattern
		parser = StringLiteral.GetParser()
		parser.send(None)

		sourceFile = None
		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult as ex:
			sourceFile = ex.value.Value

		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult("CopyParser: Expected whitespace before TO keyword.")
		# match for TO keyword
		token = yield
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("CopyParser: Expected TO keyword.")
		if (token.Value.lower() != "to"):           raise MismatchingParserResult("CopyParser: Expected TO keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult("CopyParser: Expected whitespace before destination directory.")

		# match for string: 		destinationDirectory; use a StringLiteralParser to parse the pattern
		parser = StringLiteral.GetParser()
		parser.send(None)

		destinationDirectory = None
		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult as ex:
			destinationDirectory = ex.value.Value

		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult("CopyParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
				commentText += token.Value
		else:
			raise MismatchingParserResult("CopyParser: Expected end of line or comment")
		
		# construct result
		result = cls(sourceFile, destinationDirectory, commentText)
		raise MatchingParserResult(result)
	
	def __str__(self, indent=0):
		if (self._commentText != ""):
			return "{0}Copy \"{1!s}\" To \"{2!s}\"    # {3}".format(("  " * indent), self._sourcePath, self._destinationPath, self._commentText)
		else:
			return "{0}Copy \"{1!s}\" To \"{2!s}\"".format(("  " * indent), self._sourcePath, self._destinationPath)

class DeleteStatement(Statement):
	def __init__(self, file, commentText):
		super().__init__()
		self._filePath =    file
		self._commentText = commentText

	@property
	def FilePath(self):   return self._filePath

	@classmethod
	def GetParser(cls):
		# match for optional whitespacex
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for DELETE keyword
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("DeleteParser: Expected DELETE keyword.")
		if (token.Value.lower() != "delete"):       raise MismatchingParserResult("DeleteParser: Expected DELETE keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult("DeleteParser: Expected whitespace before filename.")

		# match for string: file; use a StringLiteralParser to parse the pattern
		parser = StringLiteral.GetParser()
		parser.send(None)

		file = None
		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult as ex:
			file = ex.value.Value

		# match for optional whitespace
		if isinstance(token, SpaceToken):           token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult("DeleteParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
				commentText += token.Value
		else:
			raise MismatchingParserResult("DeleteParser: Expected end of line or comment")

		# construct result
		result = cls(file, commentText)
		raise MatchingParserResult(result)

	def __str__(self, indent=0):
		if (self._commentText != ""):
			return "{0}Delete \"{1!s}\"    # {2}".format(("  " * indent), self._filePath, self._commentText)
		else:
			return "{0}Delete \"{1!s}\"".format(("  " * indent), self._filePath)


class ReplaceStatement(Statement):
	def __init__(self, searchPattern, replacePattern, caseInsensitive, multiLine, dotAll, commentText):
		super().__init__()
		self._searchPattern =   searchPattern
		self._replacePattern =  replacePattern
		self._caseInsensitive = caseInsensitive
		self._multiLine =       multiLine
		self._dotAll =          dotAll
		self._commentText =     commentText

	@property
	def SearchPattern(self):    return self._searchPattern
	@property
	def ReplacePattern(self):   return self._replacePattern
	@property
	def CaseInsensitive(self):  return self._caseInsensitive
	@property
	def MultiLine(self):        return self._multiLine
	@property
	def DotAll(self):           return self._dotAll
	
	@classmethod
	def GetParser(cls):
		multiLine =       False
		dotAll =          False
		caseInsensitive = False
		
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for keyword: REPLACE
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("ReplaceParser: Expected REPLACE keyword.")
		if (token.Value.lower() != "replace"):      raise MismatchingParserResult("ReplaceParser: Expected REPLACE keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult("ReplaceParser: Expected whitespace before search pattern.")

		# match for string: searchPattern; use a StringLiteralParser to parse the pattern
		parser = StringLiteral.GetParser()
		parser.send(None)
		searchPattern = None
		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult as ex:
			searchPattern = ex.value.Value

		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult("ReplaceParser: Expected whitespace before WITH keyword.")
		# match for WITH keyword
		token = yield
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("ReplaceParser: Expected WITH keyword.")
		if (token.Value.lower() != "with"):         raise MismatchingParserResult("ReplaceParser: Expected WITH keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult("ReplaceParser: Expected whitespace before replace pattern.")

		# match for string: replacePattern; use a StringLiteralParser to parse the pattern
		parser = StringLiteral.GetParser()
		parser.send(None)

		replacePattern = None
		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult as ex:
			replacePattern = ex.value.Value

		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for line end, comment or OPTIONS keyword
		if isinstance(token, StringToken):
			if (token.Value.lower() == "options"):
				# match for whitespace
				token = yield
				if (not isinstance(token, SpaceToken)): raise MismatchingParserResult("ReplaceParser: Expected whitespace before MULTILINE, DOTALL or CASEINSENSITIVE keyword.")
				for _ in range(3):
					# match for 				MULTILINE, DOTALL or CASEINSENSITIVE keyword
					token = yield
					if (not isinstance(token, StringToken)):  raise MismatchingParserResult("ReplaceParser: Expected MULTILINE, DOTALL or CASEINSENSITIVE keyword.")
					if (token.Value.lower() == "multiline"):
						multiLine =        True
					elif (token.Value.lower() == "dotall"):
						dotAll =          True
					elif (token.Value.lower() == "caseinsensitive"):
						caseInsensitive =  True
					else:
						raise MismatchingParserResult("ReplaceParser: Expected MULTILINE, DOTALL or CASEINSENSITIVE keyword.")
					# match for optional whitespace
					token = yield
					if isinstance(token, SpaceToken):              token = yield
					if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult("ReplaceParser: Expected more options, end of line or comment.")
					if (token.Value == ","):
						# match for optional whitespace, before going into the next iteration
						token = yield
						if isinstance(token, SpaceToken):            token = yield
						continue
					else:
						break
					
		# match for delimiter sign: \n or #
		commentText = ""
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult("ReplaceParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
				commentText += token.Value
		else:
			raise MismatchingParserResult("ReplaceParser: Expected end of line or comment")

		# construct result
		result = cls(searchPattern, replacePattern, caseInsensitive, multiLine, dotAll, commentText)
		raise MatchingParserResult(result)

	def __str__(self, indent=0):
		return "{0}Replace {1} by {2}".format("  " * indent, self._searchPattern, self._replacePattern)

class AppendLineStatement(Statement):
	def __init__(self, appendPattern, commentText):
		super().__init__()
		self._appendPattern =   appendPattern
		self._commentText =     commentText

	@property
	def AppendPattern(self):   return self._appendPattern
	@property

	@classmethod
	def GetParser(cls):
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for keyword: APPENDLINE
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("AppendLineParser: Expected APPENDLINE keyword.")
		if (token.Value.lower() != "appendline"):   raise MismatchingParserResult("AppendLineParser: Expected APPENDLINE keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult("AppendLineParser: Expected whitespace before append pattern.")

		# match for string: appendPattern; use a StringLiteralParser to parse the pattern
		parser = StringLiteral.GetParser()
		parser.send(None)
		appendPattern = None
		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult as ex:
			appendPattern = ex.value.Value

		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult("AppendLineParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
				commentText += token.Value
		else:
			raise MismatchingParserResult("AppendLineParser: Expected end of line or comment")

		# construct result
		result = cls(appendPattern, commentText)
		raise MatchingParserResult(result)

	def __str__(self, indent=0):
		return "{0}AppendLine {1}".format("  " * indent, self._appendPattern)

# ==============================================================================
# Block Statements
# ==============================================================================
class FileStatement(BlockStatement):
	def __init__(self, file, commentText):
		super().__init__()
		self._filePath =    file
		self._commentText =  commentText

	@property
	def FilePath(self):    return self._filePath

	@classmethod
	def GetParser(cls):
		# match for IN ... FILE clause
		# ==========================================================================
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for keyword: FILE
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("FileParser: Expected FILE keyword.")
		if (token.Value.lower() != "file"):         raise MismatchingParserResult("FileParser: Expected FILE keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult("FileParser: Expected whitespace before filename.")

		# match for string: replaceFilename; use a StringLiteralParser to parse the pattern
		parser = StringLiteral.GetParser()
		parser.send(None)

		replaceFilename = None
		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult as ex:
			replaceFilename = ex.value.Value

		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult("FileParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
				commentText += token.Value
		else:
			raise MismatchingParserResult("FileParser: Expected end of line or comment")
		
		# match for inner statements
		# ==========================================================================
		# construct result
		result = cls(replaceFilename, commentText)
		parser = cls.GetRepeatParser(result.AddStatement, InFileStatements.GetParser)
		parser.send(None)

		try:
			while True:
				token = yield
				parser.send(token)
		except EmptyChoiseParserResult:
			print("ERROR in *.rules file -> fix me")
		except MatchingParserResult:
			pass
		
		# match for END FILE clause
		# ==========================================================================
		# match for optional whitespace
		if isinstance(token, SpaceToken):           token = yield
		# match for keyword: END
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("FileParser: Expected END keyword.")
		if (token.Value.lower() != "end"):          raise MismatchingParserResult("FileParser: Expected END keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult("FileParser: Expected whitespace before FILE keyword.")
		# match for keyword: FILE
		token = yield
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("FileParser: Expected FILE keyword.")
		if (token.Value.lower() != "file"):         raise MismatchingParserResult("FileParser: Expected FILE keyword.")
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for delimiter sign: \n
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult("FileParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
		else:
			raise MismatchingParserResult("FileParser: Expected end of line or comment")

		result.CommentText = commentText

		raise MatchingParserResult(result)

	def __str__(self, indent=0):
		_indent = "  " * indent
		buffer = _indent + "FileParser"
		for stmt in self._statements:
			buffer += "\n{0}{1}".format(_indent, stmt.__str__(indent + 1))
		return buffer


class ProcessRulesBlockStatement(BlockStatement):
	__PARSER_NAME__ =       None
	__PARSER_BLOCK_NAME__ = None
	__PARSER_STATEMENTS__ = None

	def __init__(self, commentText):
		super().__init__()
		self._commentText = commentText

	@classmethod
	def GetParser(cls):
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for keyword: __PARSER_BLOCK_NAME__
		if (not isinstance(token, StringToken)):                raise MismatchingParserResult(cls.__PARSER_NAME__ + ": Expected " + cls.__PARSER_BLOCK_NAME__ + " keyword.")
		if (token.Value.lower() != cls.__PARSER_BLOCK_NAME__):  raise MismatchingParserResult(cls.__PARSER_NAME__ + ": Expected " + cls.__PARSER_BLOCK_NAME__ + " keyword.")
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult(cls.__PARSER_NAME__ + ": Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
				commentText += token.Value
		else:
			raise MismatchingParserResult(cls.__PARSER_NAME__ + ": Expected end of line or comment")

		# match for inner statements
		# ==========================================================================
		# construct result
		result = cls(commentText)
		parser = cls.GetRepeatParser(result.AddStatement, cls.__PARSER_STATEMENTS__.GetParser)
		parser.send(None)

		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult:
			pass

		# match for END __PARSER_BLOCK_NAME__
		# ==========================================================================
		# match for optional whitespace
		if isinstance(token, SpaceToken):           token = yield
		# match for keyword: END
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult(cls.__PARSER_NAME__ + ": Expected END keyword.")
		if (token.Value.lower() != "end"):          raise MismatchingParserResult(cls.__PARSER_NAME__ + ": Expected END keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult(cls.__PARSER_NAME__ + ": Expected whitespace before " + cls.__PARSER_BLOCK_NAME__ + " keyword.")
		# match for keyword: __PARSER_BLOCK_NAME__
		token = yield
		if (not isinstance(token, StringToken)):                raise MismatchingParserResult(cls.__PARSER_NAME__ + ": Expected " + cls.__PARSER_BLOCK_NAME__ + " keyword.")
		if (token.Value.lower() != cls.__PARSER_BLOCK_NAME__):  raise MismatchingParserResult(cls.__PARSER_NAME__ + ": Expected " + cls.__PARSER_BLOCK_NAME__ + " keyword.")
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for delimiter sign: \n
		# commentText = ""
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult(cls.__PARSER_NAME__ + ": Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
			# commentText += token.Value
		else:
			raise MismatchingParserResult(cls.__PARSER_NAME__ + ": Expected end of line or comment")

		raise MatchingParserResult(result)

	def __str__(self, indent=0):
		_indent = "  " * indent
		buffer = _indent + self.__PARSER_NAME__
		for stmt in self._statements:
			buffer += "\n{0}{1}".format(_indent, stmt.__str__(indent + 1))
		return buffer


class PreProcessRulesStatement(ProcessRulesBlockStatement):
	__PARSER_NAME__ =       "PreProcessRulesParser"
	__PARSER_BLOCK_NAME__ = "preprocessrules"
	__PARSER_STATEMENTS__ = PreProcessStatements


class PostProcessStatement(ProcessRulesBlockStatement):
	__PARSER_NAME__ =       "PreProcessRulesParser"
	__PARSER_BLOCK_NAME__ = "preprocessrules"
	__PARSER_STATEMENTS__ = PostProcessStatements


class Document(BlockStatement):
	@classmethod
	def GetParser(cls):
		result = cls()
		parser = cls.GetRepeatParser(result.AddStatement, DocumentStatements.GetParser)
		parser.send(None)

		token = yield
		if (not isinstance(token, StartOfDocumentToken)):
			raise MismatchingParserResult("Expected a StartOfDocumentToken, got {0!s}.".format(token))

		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult:
			raise MatchingParserResult(result)
	
	def __str__(self, indent=0):
		buffer = "  " * indent + "Document"
		for stmt in self._statements:
			buffer += "\n{0}".format(stmt.__str__(indent + 1))
		return buffer


InFileStatements.AddChoice(ReplaceStatement)
InFileStatements.AddChoice(AppendLineStatement)
InFileStatements.AddChoice(CommentLine)
InFileStatements.AddChoice(EmptyLine)

PreProcessStatements.AddChoice(CopyStatement)
PreProcessStatements.AddChoice(FileStatement)
PreProcessStatements.AddChoice(CommentLine)
PreProcessStatements.AddChoice(EmptyLine)

PostProcessStatements.AddChoice(CopyStatement)
PostProcessStatements.AddChoice(DeleteStatement)
PostProcessStatements.AddChoice(FileStatement)
PostProcessStatements.AddChoice(CommentLine)
PostProcessStatements.AddChoice(EmptyLine)

DocumentStatements.AddChoice(PreProcessRulesStatement)
DocumentStatements.AddChoice(PostProcessStatement)
DocumentStatements.AddChoice(CommentLine)
DocumentStatements.AddChoice(EmptyLine)
