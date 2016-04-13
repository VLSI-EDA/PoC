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
from pathlib import Path

from lib.Functions import Init
from lib.Parser import MismatchingParserResult, MatchingParserResult
from lib.Parser import SpaceToken, CharacterToken, StringToken, NumberToken
from lib.Parser import Statement, BlockStatement
from Parser.CodeDOM import EmptyLine, CommentLine, BlockedStatement as BlockStatementBase


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
		self._sourcePath =			Path(source)
		self._destinationPath =	Path(destination)
		self._commentText =			commentText

	@property
	def SourcePath(self):				return self._sourcePath
	@property
	def DestinationPath(self):	return self._destinationPath
	
	@classmethod
	def GetParser(cls):
		# match for optional whitespace
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
		sourceFilename = ""
		while True:
			token = yield
			if (isinstance(token, CharacterToken) and (token.Value == "\"")):		break
			sourceFilename += token.Value

		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):			raise MismatchingParserResult("CopyParser: Expected whitespace before TO keyword.")
		# match for TO keyword
		token = yield
		if (not isinstance(token, StringToken)):		raise MismatchingParserResult("CopyParser: Expected TO keyword.")
		if (token.Value.lower() != "to"):						raise MismatchingParserResult("CopyParser: Expected TO keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):			raise MismatchingParserResult("CopyParser: Expected whitespace before destination filename.")
		# match for delimiter sign: "
		token = yield
		if (not isinstance(token, CharacterToken)):	raise MismatchingParserResult("CopyParser: Expected double quote sign before destination filename.")
		if (token.Value.lower() != "\""):						raise MismatchingParserResult("CopyParser: Expected double quote sign before destination filename.")

		# match for string: fileName
		destinationFilename = ""
		while True:
			token = yield
			if (isinstance(token, CharacterToken) and (token.Value == "\"")):		break
			destinationFilename += token.Value

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
		result = cls(sourceFilename, destinationFilename, commentText)
		raise MatchingParserResult(result)
	
	def __str__(self, indent=0):
		if (self._commentText != ""):
			return "{0}Copy {1} To {2}   # {3}".format(("  " * indent), self._sourcePath, self._destinationPath, self._commentText)
		else:
			return "{0}VHDL {1} \"{2}\"".format(("  " * indent), self._libraryName, self._fileName)


class ReplaceStatement(Statement):
	def __init__(self, searchPattern, replacePattern, commentText):
		super().__init__()
		self._searchPattern =		searchPattern
		self._replacePattern =	replacePattern
		self._commentText =			commentText

	@property
	def SearchPattern(self):		return self._searchPattern
	@property
	def ReplacePattern(self):		return self._replacePattern
	
	@classmethod
	def GetParser(cls):
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):						token = yield
		# match for keyword: SEARCH
		if (not isinstance(token, StringToken)):		raise MismatchingParserResult("ReplaceParser: Expected SEARCH keyword.")
		if (token.Value.lower() != "search"):				raise MismatchingParserResult("ReplaceParser: Expected SEARCH keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):			raise MismatchingParserResult("ReplaceParser: Expected whitespace before FOR keyword.")
		# match for keyword: 	FOR
		token = yield
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("ReplaceParser: Expected FOR keyword.")
		if (token.Value.lower() != "for"):          raise MismatchingParserResult("ReplaceParser: Expected FOR keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult("ReplaceParser: Expected whitespace before search pattern.")
		# match for delimiter sign: "
		token = yield
		if (not isinstance(token, CharacterToken)):	raise MismatchingParserResult("ReplaceParser: Expected double quote sign before search pattern.")
		if (token.Value.lower() != "\""):						raise MismatchingParserResult("ReplaceParser: Expected double quote sign before search pattern.")
		# match for string: searchPattern
		searchPattern = ""
		while True:
			token = yield
			if (isinstance(token, CharacterToken) and (token.Value == "\"")):    break
			searchPattern += token.Value
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult("ReplaceParser: Expected whitespace before REPLACE keyword.")
		# match for REPLACE keyword
		token = yield
		if (not isinstance(token, StringToken)):     raise MismatchingParserResult("ReplaceParser: Expected REPLACE keyword.")
		if (token.Value.lower() != "replace"):       raise MismatchingParserResult("ReplaceParser: Expected REPLACE keyword.")# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult("ReplaceParser: Expected whitespace before BY keyword.")
		# match for BY keyword
		token = yield
		if (not isinstance(token, StringToken)):     raise MismatchingParserResult("ReplaceParser: Expected BY keyword.")
		if (token.Value.lower() != "by"):            raise MismatchingParserResult("ReplaceParser: Expected BY keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult("ReplaceParser: Expected whitespace before destination filename.")
		# match for delimiter sign: "
		token = yield
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("ReplaceParser: Expected double quote sign before destination filename.")
		if (token.Value.lower() != "\""):            raise MismatchingParserResult("ReplaceParser: Expected double quote sign before destination filename.")
		# match for string: replacePattern
		replacePattern = ""
		while True:
			token = yield
			if (isinstance(token, CharacterToken) and (token.Value == "\"")):    break
			replacePattern += token.Value
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield
		# match for delimiter sign: \n
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
		result = cls(searchPattern, replacePattern, commentText)
		raise MatchingParserResult(result)
		
	def __str__(self, indent=0):
		return "{0}Replace {1} by {2}".format("  " * indent, self._searchPattern, self._replacePattern)

# ==============================================================================
# Block Statements
# ==============================================================================
class InFileStatement(BlockStatement):
	def __init__(self, file, commentText):
		super().__init__()
		self._filePath =		Path(file)
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
		# match for keyword: IN
		if (not isinstance(token, StringToken)):		raise MismatchingParserResult("InFileParser: Expected IN keyword.")
		if (token.Value.lower() != "in"):						raise MismatchingParserResult("InFileParser: Expected IN keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult("InFileParser: Expected whitespace before source filename.")
		# match for delimiter sign: "
		token = yield
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("InFileParser: Expected double quote sign before source fileName.")
		if (token.Value.lower() != "\""):            raise MismatchingParserResult("InFileParser: Expected double quote sign before source fileName.")
		# match for string: source filename
		replaceFilename = ""
		while True:
			token = yield
			if (isinstance(token, CharacterToken) and (token.Value == "\"")):    break
			replaceFilename += token.Value
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult("InFileParser: Expected whitespace before TO keyword.")
		# match for FILE keyword
		token = yield
		if (not isinstance(token, StringToken)):     raise MismatchingParserResult("InFileParser: Expected FILE keyword.")
		if (token.Value.lower() != "file"):          raise MismatchingParserResult("InFileParser: Expected FILE keyword.")
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("InFileParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
				commentText += token.Value
		else:
			raise MismatchingParserResult("InFileParser: Expected end of line or comment")
		
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
		except MatchingParserResult:
			pass
		
		# match for END FILE clause
		# ==========================================================================
		# match for optional whitespace
		if isinstance(token, SpaceToken):            token = yield
		# match for keyword: END
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("InFileParser: Expected END keyword.")
		if (token.Value.lower() != "end"):          raise MismatchingParserResult("InFileParser: Expected END keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult("InFileParser: Expected whitespace before FILE keyword.")
		# match for keyword: PREPROCESSRULES
		token = yield
		if (not isinstance(token, StringToken)):     raise MismatchingParserResult("InFileParser: Expected FILE keyword.")
		if (token.Value.lower() != "file"):  				 raise MismatchingParserResult("InFileParser: Expected FILE keyword.")
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield
		# match for delimiter sign: \n
		# commentText = ""
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("InFileParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
			# commentText += token.Value
		else:
			raise MismatchingParserResult("InFileParser: Expected end of line or comment")
		
		raise MatchingParserResult(result)

	def __str__(self, indent=0):
		_indent = "  " * indent
		buffer = _indent + "InFileParser"
		for stmt in self._statements:
			buffer += "\n{0}{1}".format(_indent, stmt.__str__(indent + 1))
		return buffer

class PreProcessRulesStatement(BlockStatement):
	def __init__(self, commentText):
		super().__init__()
		self._commentText =	commentText

	@classmethod
	def GetParser(cls):
		# match for ELSE clause
		# ==========================================================================
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):						token = yield

		# match for keyword: ELSE
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

		# match for END PREPROCESSRULES clause
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
		# match for ELSE clause
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
		except MatchingParserResult:
			pass

		# match for END POSTPROCESSRULES clause
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
ProcessStatements.AddChoice(InFileStatement)
ProcessStatements.AddChoice(CommentLine)
ProcessStatements.AddChoice(EmptyLine)

DocumentStatements.AddChoice(PreProcessRulesStatement)
DocumentStatements.AddChoice(PostProcessStatement)
DocumentStatements.AddChoice(CommentLine)
DocumentStatements.AddChoice(EmptyLine)
