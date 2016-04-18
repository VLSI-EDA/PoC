# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
# Authors:					Patrick Lehmann
#
# Python Module:		TODO
# 
# Description:
# ------------------------------------
#		TODO:
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
from lib.Parser			import MismatchingParserResult, MatchingParserResult, EmptyChoiseParserResult
from lib.Parser			import SpaceToken, CharacterToken, StringToken, NumberToken
from lib.Parser			import Statement, BlockStatement
from Parser.CodeDOM	import EmptyLine, CommentLine, BlockedStatement as BlockStatementBase


# ==============================================================================
# Blocked Statements (Forward declaration)
# ==============================================================================
class InFileStatements(BlockStatementBase):
	_allowedStatements = []

class ProcessStatements(BlockStatementBase):
	_allowedStatements = []

class DocumentStatements(BlockStatementBase):
	_allowedStatements = []


# ==============================================================================
# File Reference Statements
# ==============================================================================
class CopyStatement(Statement):
	def __init__(self, source, destination, commentText):
		super().__init__()
		self._sourcePath =			source
		self._destinationPath =	destination
		self._commentText =			commentText

	@property
	def SourcePath(self):				return self._sourcePath
	@property
	def DestinationPath(self):	return self._destinationPath
	
	@classmethod
	def GetParser(cls):
		# match for optional whitespacex
		token = yield
		if isinstance(token, SpaceToken):						token = yield
		# match for COPY keyword
		if (not isinstance(token, StringToken)):		raise MismatchingParserResult("CopyParser: Expected COPY keyword.")
		if (token.Value.lower() != "copy"):					raise MismatchingParserResult("CopyParser: Expected COPY keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):			raise MismatchingParserResult("CopyParser: Expected whitespace before source filename.")
		# match for delimiter sign: "
		token = yield
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("CopyParser: Expected double quote sign before source fileName.")
		if (token.Value.lower() != "\""):            raise MismatchingParserResult("CopyParser: Expected double quote sign before source fileName.")
		# match for string: source filename
		sourceFile = ""
		while True:
			token = yield
			if (isinstance(token, CharacterToken) and (token.Value == "\"")):		break
			sourceFile += token.Value
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):			raise MismatchingParserResult("CopyParser: Expected whitespace before TO keyword.")
		# match for TO keyword
		token = yield
		if (not isinstance(token, StringToken)):		raise MismatchingParserResult("CopyParser: Expected TO keyword.")
		if (token.Value.lower() != "to"):						raise MismatchingParserResult("CopyParser: Expected TO keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):			raise MismatchingParserResult("CopyParser: Expected whitespace before destination directory.")
		# match for delimiter sign: "
		token = yield
		if (not isinstance(token, CharacterToken)):	raise MismatchingParserResult("CopyParser: Expected double quote sign before destination directory.")
		if (token.Value.lower() != "\""):						raise MismatchingParserResult("CopyParser: Expected double quote sign before destination directory.")
		# match for string: fileName
		destinationDirectory = ""
		while True:
			token = yield
			if (isinstance(token, CharacterToken) and (token.Value == "\"")):		break
			destinationDirectory += token.Value
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):						token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):	raise MismatchingParserResult("CopyParser: Expected end of line or comment")
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


class ReplaceStatement(Statement):
	def __init__(self, searchPattern, replacePattern, caseInsensitive, multiLine, dotAll, commentText):
		super().__init__()
		self._searchPattern =		searchPattern
		self._replacePattern =	replacePattern
		self._caseInsensitive =	caseInsensitive
		self._multiLine =				multiLine
		self._dotAll =					dotAll
		self._commentText =			commentText

	@property
	def SearchPattern(self):		return self._searchPattern
	@property
	def ReplacePattern(self):		return self._replacePattern
	@property
	def CaseSensitive(self):		return self._caseInsensitive
	@property
	def MultiLine(self):				return self._multiLine
	@property
	def DotAll(self):						return self._dotAll
	
	@classmethod
	def GetParser(cls):
		multiLine =				False
		dotAll =					False
		caseInsensitive =	False
		
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):						token = yield
		# match for keyword: REPLACE
		if (not isinstance(token, StringToken)):		raise MismatchingParserResult("ReplaceParser: Expected REPLACE keyword.")
		if (token.Value.lower() != "replace"):			raise MismatchingParserResult("ReplaceParser: Expected REPLACE keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult("ReplaceParser: Expected whitespace before search pattern.")
		# match for delimiter sign: "
		token = yield
		if (not isinstance(token, CharacterToken)):	raise MismatchingParserResult("ReplaceParser: Expected double quote sign before search pattern.")
		if (token.Value.lower() != "\""):						raise MismatchingParserResult("ReplaceParser: Expected double quote sign before search pattern.")
		# match for string: searchPattern
		searchPattern = ""
		wasEscapeSign =	False
		while True:
			token = yield
			if isinstance(token, CharacterToken):
				if (token.Value == "\""):
					if (wasEscapeSign == True):
						wasEscapeSign =		False
						searchPattern +=	"\""
						continue
					else:
						break
				elif (token.Value == "\\"):
					if (wasEscapeSign == True):
						wasEscapeSign = False
						searchPattern += "\""
						continue
					else:
						wasEscapeSign =	True
						continue
			searchPattern +=	token.Value
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult("ReplaceParser: Expected whitespace before WITH keyword.")
		# match for WITH keyword
		token = yield
		if (not isinstance(token, StringToken)):		raise MismatchingParserResult("ReplaceParser: Expected WITH keyword.")
		if (token.Value.lower() != "with"):					raise MismatchingParserResult("ReplaceParser: Expected WITH keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult("ReplaceParser: Expected whitespace before replace pattern.")
		# match for delimiter sign: "
		token = yield
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("ReplaceParser: Expected double quote sign before replace pattern.")
		if (token.Value.lower() != "\""):            raise MismatchingParserResult("ReplaceParser: Expected double quote sign before replace pattern.")
		# match for string: replacePattern
		replacePattern = ""
		wasEscapeSign = False
		while True:
			token = yield
			if isinstance(token, CharacterToken):
				if (token.Value == "\""):
					if (wasEscapeSign == True):
						wasEscapeSign = False
						replacePattern += "\""
						continue
					else:
						break
				elif (token.Value == "\\"):
					if (wasEscapeSign == True):
						wasEscapeSign = False
						replacePattern += "\\"
						continue
					else:
						wasEscapeSign = True
						continue
			replacePattern += token.Value
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):						token = yield
		# match for line end, comment or OPTIONS keyword
		if isinstance(token, StringToken):
			if (token.Value.lower() == "options"):
				# match for whitespace
				token = yield
				if (not isinstance(token, SpaceToken)):		raise MismatchingParserResult("ReplaceParser: Expected whitespace before MULTILINE, DOTALL or CASEINSENSITIVE keyword.")
				for _ in range(3):
					# match for 				MULTILINE, DOTALL or CASEINSENSITIVE keyword
					token = yield
					if (not isinstance(token, StringToken)):	raise MismatchingParserResult("ReplaceParser: Expected MULTILINE, DOTALL or CASEINSENSITIVE keyword.")
					if (token.Value.lower() == "multiline"):
						multiLine =				True
					elif (token.Value.lower() == "dotall"):
						dotAll =					True
					elif (token.Value.lower() == "caseinsensitive"):
						caseInsensitive =	True
					else:
						raise MismatchingParserResult("ReplaceParser: Expected MULTILINE, DOTALL or CASEINSENSITIVE keyword.")
					# match for optional whitespace
					token = yield
					if isinstance(token, SpaceToken):							token = yield
					if (not isinstance(token, CharacterToken)):		raise MismatchingParserResult("ReplaceParser: Expected more options, end of line or comment.")
					if (token.Value == ","):
						# match for optional whitespace, before going into the next iteration
						token = yield
						if isinstance(token, SpaceToken):						token = yield
						continue
					else:
						break
					
		# match for delimiter sign: \n or #
		commentText = ""
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("ReplaceParser: Expected end of line or comment")
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

# ==============================================================================
# Block Statements
# ==============================================================================
class FileStatement(BlockStatement):
	def __init__(self, file, commentText):
		super().__init__()
		self._filePath =		file
		self._commentText =	commentText

	@property
	def FilePath(self):		return self._filePath

	@classmethod
	def GetParser(cls):
		# match for IN ... FILE clause
		# ==========================================================================
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):						token = yield
		# match for keyword: FILE
		if (not isinstance(token, StringToken)):		raise MismatchingParserResult("FileParser: Expected FILE keyword.")
		if (token.Value.lower() != "file"):					raise MismatchingParserResult("FileParser: Expected FILE keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult("FileParser: Expected whitespace before filename.")
		# match for delimiter sign: "
		token = yield
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("FileParser: Expected double quote sign before fileName.")
		if (token.Value.lower() != "\""):            raise MismatchingParserResult("FileParser: Expected double quote sign before fileName.")
		# match for string: source filename
		replaceFilename = ""
		while True:
			token = yield
			if (isinstance(token, CharacterToken) and (token.Value == "\"")):    break
			replaceFilename += token.Value
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("FileParser: Expected end of line or comment")
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
		if isinstance(token, SpaceToken):            token = yield
		# match for keyword: END
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("FileParser: Expected END keyword.")
		if (token.Value.lower() != "end"):          raise MismatchingParserResult("FileParser: Expected END keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult("FileParser: Expected whitespace before FILE keyword.")
		# match for keyword: FILE
		token = yield
		if (not isinstance(token, StringToken)):     raise MismatchingParserResult("FileParser: Expected FILE keyword.")
		if (token.Value.lower() != "file"):  				 raise MismatchingParserResult("FileParser: Expected FILE keyword.")
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield
		# match for delimiter sign: \n
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("FileParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
		else:
			raise MismatchingParserResult("FileParser: Expected end of line or comment")

		result._commentText = commentText

		raise MatchingParserResult(result)

	def __str__(self, indent=0):
		_indent = "  " * indent
		buffer = _indent + "FileParser"
		for stmt in self._statements:
			buffer += "\n{0}{1}".format(_indent, stmt.__str__(indent + 1))
		return buffer

class PreProcessRulesStatement(BlockStatement):
	def __init__(self, commentText):
		super().__init__()
		self._commentText =	commentText

	@classmethod
	def GetParser(cls):
		# match for PREPROCESSRULES clause
		# ==========================================================================
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):						token = yield
		# match for keyword: PREPROCESSRULES
		if (not isinstance(token, StringToken)):				raise MismatchingParserResult("PreProcessRulesParser: Expected PREPROCESSRULES keyword.")
		if (token.Value.lower() != "preprocessrules"):	raise MismatchingParserResult("PreProcessRulesParser: Expected PREPROCESSRULES keyword.")
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):						token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):	raise MismatchingParserResult("PreProcessRulesParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
				commentText += token.Value
		else:
			raise MismatchingParserResult("PreProcessRulesParser: Expected end of line or comment")

		# match for inner statements
		# ==========================================================================
		# construct result
		result = cls(commentText)
		parser = cls.GetRepeatParser(result.AddStatement, ProcessStatements.GetParser)
		parser.send(None)

		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult:
			pass

		# match for END PREPROCESSRULES
		# ==========================================================================
		# match for optional whitespace
		if isinstance(token, SpaceToken):						token = yield
		# match for keyword: END
		if (not isinstance(token, StringToken)):		raise MismatchingParserResult("PreProcessRulesParser: Expected END keyword.")
		if (token.Value.lower() != "end"):					raise MismatchingParserResult("PreProcessRulesParser: Expected END keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):			raise MismatchingParserResult("PreProcessRulesParser: Expected whitespace before PREPROCESSRULES keyword.")
		# match for keyword: PREPROCESSRULES
		token = yield
		if (not isinstance(token, StringToken)):				raise MismatchingParserResult("PreProcessRulesParser: Expected PREPROCESSRULES keyword.")
		if (token.Value.lower() != "preprocessrules"):	raise MismatchingParserResult("PreProcessRulesParser: Expected PREPROCESSRULES keyword.")
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield
		# match for delimiter sign: \n
		# commentText = ""
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("PreProcessRulesParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
			# commentText += token.Value
		else:
			raise MismatchingParserResult("PreProcessRulesParser: Expected end of line or comment")

		raise MatchingParserResult(result)

	def __str__(self, indent=0):
		_indent = "  " * indent
		buffer = _indent + "PreProcessRulesParser"
		for stmt in self._statements:
			buffer += "\n{0}{1}".format(_indent, stmt.__str__(indent + 1))
		return buffer


class PostProcessStatement(BlockStatement):
	def __init__(self, commentText):
		super().__init__()
		self._commentText =	commentText

	@classmethod
	def GetParser(cls):
		# match for POSTPRECESSRULES clause
		# ==========================================================================
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):						token = yield
		# match for keyword: POSTPRECESSRULES
		if (not isinstance(token, StringToken)):				raise MismatchingParserResult("PostProcessRulesParser: Expected POSTPRECESSRULES keyword.")
		if (token.Value.lower() != "postprocessrules"):	raise MismatchingParserResult("PostProcessRulesParser: Expected POSTPRECESSRULES keyword.")
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):						token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):	raise MismatchingParserResult("PostProcessRulesParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
				commentText += token.Value
		else:
			raise MismatchingParserResult("PostProcessRulesParser: Expected end of line or comment")

		# match for inner statements
		# ==========================================================================
		# construct result
		result = cls(commentText)
		parser = cls.GetRepeatParser(result.AddStatement, ProcessStatements.GetParser)
		parser.send(None)

		try:
			while True:
				token = yield
				parser.send(token)
		except EmptyChoiseParserResult:
			print("ERROR in *.rules file -> fix me 2")
		except MatchingParserResult:
			pass

		# match for END POSTPROCESSRULES
		# ==========================================================================
		# match for optional whitespace
		if isinstance(token, SpaceToken):            token = yield
		# match for keyword: END
		if (not isinstance(token, StringToken)):     raise MismatchingParserResult("PostProcessRulesParser: Expected END keyword.")
		if (token.Value.lower() != "end"):           raise MismatchingParserResult("PostProcessRulesParser: Expected END keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult("PostProcessRulesParser: Expected whitespace before POSTPROCESSRULES keyword.")
		# match for keyword: POSTPROCESSRULES
		token = yield
		if (not isinstance(token, StringToken)):         raise MismatchingParserResult("PostProcessRulesParser: Expected POSTPROCESSRULES keyword.")
		if (token.Value.lower() != "postprocessrules"):  raise MismatchingParserResult("PostProcessRulesParser: Expected POSTPROCESSRULES keyword.")
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield
		# match for delimiter sign: \n
		# commentText = ""
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("PostProcessRulesParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
			# commentText += token.Value
		else:
			raise MismatchingParserResult("PostProcessRulesParser: Expected end of line or comment")

		raise MatchingParserResult(result)

	def __str__(self, indent=0):
		_indent = "  " * indent
		buffer = _indent + "PostProcessRulesStatement"
		for stmt in self._statements:
			buffer += "\n{0}{1}".format(_indent, stmt.__str__(indent + 1))
		return buffer


class Document(BlockStatement):
	@classmethod
	def GetParser(cls):
		result = cls()
		parser = cls.GetRepeatParser(result.AddStatement, DocumentStatements.GetParser)
		parser.send(None)
		
		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult as ex:
			raise MatchingParserResult(result)
	
	def __str__(self, indent=0):
		buffer = "  " * indent + "Document"
		for stmt in self._statements:
			buffer += "\n{0}".format(stmt.__str__(indent + 1))
		return buffer

InFileStatements.AddChoice(ReplaceStatement)
InFileStatements.AddChoice(CommentLine)
InFileStatements.AddChoice(EmptyLine)

ProcessStatements.AddChoice(CopyStatement)
ProcessStatements.AddChoice(FileStatement)
ProcessStatements.AddChoice(CommentLine)
ProcessStatements.AddChoice(EmptyLine)

DocumentStatements.AddChoice(PreProcessRulesStatement)
DocumentStatements.AddChoice(PostProcessStatement)
DocumentStatements.AddChoice(CommentLine)
DocumentStatements.AddChoice(EmptyLine)
