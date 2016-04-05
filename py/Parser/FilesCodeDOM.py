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
DEBUG =		False#True
DEBUG2 =	False#True

from Parser.Parser		import MismatchingParserResult, MatchingParserResult
from Parser.Parser		import CodeDOMObject
from Parser.Parser		import SpaceToken, CharacterToken, StringToken, NumberToken
from Parser.Parser		import Statement, BlockStatement, ConditionalBlockStatement, Expressions


class EmptyLine(CodeDOMObject):
	def __init__(self):
		super().__init__()

	@classmethod
	def GetParser(cls):
		if DEBUG: print("init EmptyLine")
	
		# match for optional whitespace
		token = yield
		if DEBUG2: print("EmptyLine: token={0}".format(token))
		if isinstance(token, SpaceToken):
			token = yield
			if DEBUG2: print("EmptyLine: token={0}".format(token))
	
		# match for delimiter sign: \n
		if (not isinstance(token, CharacterToken)):	raise MismatchingParserResult()
		if (token.Value.lower() != "\n"):						raise MismatchingParserResult()
		
		# construct result
		result = cls()
		if DEBUG: print("EmptyLine: matched {0}".format(result))
		raise MatchingParserResult(result)
	
	def __str__(self, indent=0):
		_indent = "  " * indent
		return _indent + "<empty>"

class CommentLine(CodeDOMObject):
	def __init__(self, commentText):
		super().__init__()
		self._commentText = commentText
	
	@property
	def Text(self):
		return self._commentText

	@classmethod
	def GetParser(cls):
		if DEBUG: print("init CommentLineParser")
	
		# match for optional whitespace
		token = yield
		if DEBUG2: print("CommentLineParser: token={0} end if".format(token))
		if isinstance(token, SpaceToken):
			token = yield
			if DEBUG2: print("CommentLineParser: token={0}".format(token))
	
		# match for sign: #
		if DEBUG2: print("CommentLineParser: token={0} expected '#'".format(token))
		if (not isinstance(token, CharacterToken)):	raise MismatchingParserResult()
		if (token.Value.lower() != "#"):						raise MismatchingParserResult()
	
		# match for any until line end
		commentText = ""
		while True:
			token = yield
			if DEBUG2: print("CommentLineParser: token={0} collecting...".format(repr(token)))
			if isinstance(token, CharacterToken):
				if (token.Value == "\n"):
					break
			commentText += token.Value
		
		# construct result
		result = cls(commentText)
		if DEBUG: print("CommentLineParser: matched {0}".format(result))
		raise MatchingParserResult(result)
	
	def __str__(self, indent=0):
		_indent = "  " * indent
		return "{0}#{1}".format(_indent, self._commentText)

# ==============================================================================
# Blocked Statements (Forward declaration)
# ==============================================================================
class BlockedStatement(Statement):
	_allowedStatements = []

	@classmethod
	def AddChoice(cls, value):
		cls._allowedStatements.append(value)
	
	@classmethod
	def GetParser(cls):
		if DEBUG: print("return BlockedStatementParser")
		return cls.GetChoiceParser(cls._allowedStatements)
		
# ==============================================================================
# File Reference Statements
# ==============================================================================
class VHDLStatement(Statement):
	def __init__(self, libraryName, fileName, commentText):
		super().__init__()
		self._libraryName =	libraryName
		self._fileName =		fileName
		self._commentText =	commentText
	
	@property
	def LibraryName(self):
		return self._libraryName
		
	@property
	def FileName(self):
		return self._fileName
	
	@classmethod
	def GetParser(cls):
		if DEBUG: print("init VHDLParser")
	
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):						token = yield
		# match for VHDL keyword
		if (not isinstance(token, StringToken)):		raise MismatchingParserResult("VHDLParser: Expected VHDL keyword.")
		if (token.Value.lower() != "vhdl"):					raise MismatchingParserResult("VHDLParser: Expected VHDL keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):			raise MismatchingParserResult("VHDLParser: Expected whitespace before VHDL library name.")
		# match for library name
		library = ""
		while True:
			token = yield
			if isinstance(token, StringToken):				library += token.Value
			elif isinstance(token, NumberToken):			library += token.Value
			elif isinstance(token, CharacterToken):
				if (token.Value == "_"):
					library += token.Value
				else:
					break
			else:
				break
		# match for whitespace
		if (not isinstance(token, SpaceToken)):			raise MismatchingParserResult("VHDLParser: Expected whitespace before VHDL fileName.")
		# match for delimiter sign: "
		token = yield
		if (not isinstance(token, CharacterToken)):	raise MismatchingParserResult("VHDLParser: Expected double quote sign before VHDL fileName.")
		if (token.Value.lower() != "\""):						raise MismatchingParserResult("VHDLParser: Expected double quote sign before VHDL fileName.")
		# match for string: fileName
		fileName = ""
		while True:
			token = yield
			if isinstance(token, CharacterToken):
				if (token.Value == "\""):
					break
			fileName += token.Value
		# match for optional whitespace
		token = yield
		if DEBUG2: print("VHDLParser: token={0}".format(token))
		if isinstance(token, SpaceToken):						token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):	raise MismatchingParserResult("VHDLParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if isinstance(token, CharacterToken):
					if (token.Value == "\n"): break
				commentText += token.Value
		else:
			raise MismatchingParserResult("VHDLParser: Expected end of line or comment")
		
		# construct result
		result = cls(library, fileName, commentText)
		if DEBUG: print("VHDLParser: matched {0}".format(result))
		raise MatchingParserResult(result)
	
	def __str__(self, indent=0):
		if (self._commentText != ""):
			return "{0}VHDL {1} \"{2}\" # {3}".format(("  " * indent), self._libraryName, self._fileName, self._commentText)
		else:
			return "{0}VHDL {1} \"{2}\"".format(("  " * indent), self._libraryName, self._fileName)
	
class VerilogStatement(Statement):
	def __init__(self, fileName, commentText):
		super().__init__()
		self._fileName =		fileName
		self._commentText =	commentText
	
	@property
	def FileName(self):
		return self._fileName
	
	@classmethod
	def GetParser(cls):
		if DEBUG: print("init VerilogParser")
	
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):
			token = yield
	
		# match for keyword: VERILOG
		if (not isinstance(token, StringToken)):		raise MismatchingParserResult("VerilogParser: Expected VERILOG keyword.")
		if (token.Value.lower() != "verilog"):			raise MismatchingParserResult("VerilogParser: Expected VERILOG keyword.")
		
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):			raise MismatchingParserResult("VerilogParser: Expected whitespace before Verilog fileName.")
		
		# match for delimiter sign: "
		token = yield
		if (not isinstance(token, CharacterToken)):	raise MismatchingParserResult("VerilogParser: Expected double quote sign before Verilog fileName.")
		if (token.Value.lower() != "\""):						raise MismatchingParserResult("VerilogParser: Expected double quote sign before Verilog fileName.")
		
		# match for string: fileName
		fileName = ""
		while True:
			token = yield
			if isinstance(token, CharacterToken):
				if (token.Value == "\""):
					break
			fileName += token.Value
		# match for optional whitespace
		token = yield
		if DEBUG2: print("VerilogParser: token={0}".format(token))
		if isinstance(token, SpaceToken):						token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):	raise MismatchingParserResult("VerilogParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if isinstance(token, CharacterToken):
					if (token.Value == "\n"): break
				commentText += token.Value
		else:
			raise MismatchingParserResult("VerilogParser: Expected end of line or comment")
		
		# construct result
		result = cls(fileName, commentText)
		if DEBUG: print("VerilogParser: matched {0}".format(result))
		raise MatchingParserResult(result)
		
	def __str__(self, indent=0):
		_indent = "  " * indent
		return "{0}Verilog \"{1}\"".format(_indent, self._fileName)
	
class CocotbStatement(Statement):
	def __init__(self, fileName, moduleName, commentText):
		super().__init__()
		self._fileName =		fileName
		self._moduleName =	moduleName
		self._commentText =	commentText
	
	@property
	def FileName(self):
		return self._fileName
		
	@property
	def ModuleName(self):
		return self._moduleName
	
	@classmethod
	def GetParser(cls):
		if DEBUG: print("init CocotbParser")
	
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):						token = yield
	
		# match for keyword: COCOTB
		if (not isinstance(token, StringToken)):		raise MismatchingParserResult("CocotbParser: Expected COCOTB keyword.")
		if (token.Value.lower() != "cocotb"):				raise MismatchingParserResult("CocotbParser: Expected COCOTB keyword.")
		
		print("found cocotb")
		
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):			raise MismatchingParserResult("CocotbParser: Expected whitespace before Verilog fileName.")
		
		# match for delimiter sign: "
		token = yield
		if (not isinstance(token, CharacterToken)):	raise MismatchingParserResult("CocotbParser: Expected double quote sign before Verilog fileName.")
		if (token.Value.lower() != "\""):						raise MismatchingParserResult("CocotbParser: Expected double quote sign before Verilog fileName.")
		
		# match for string: fileName
		fileName = ""
		while True:
			token = yield
			if isinstance(token, CharacterToken):
				if (token.Value == "\""):
					break
			fileName += token.Value
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):			raise MismatchingParserResult("CocotbParser: Expected whitespace before CoCoTB module name.")
		# match for module name
		moduleName = ""
		while True:
			token = yield
			if isinstance(token, StringToken):				moduleName += token.Value
			elif isinstance(token, NumberToken):			moduleName += token.Value
			elif isinstance(token, CharacterToken):
				if (token.Value == "_"):
					moduleName += token.Value
				else:
					break
			else:
				break
		
		# match for optional whitespace
		if isinstance(token, SpaceToken):						token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):	raise MismatchingParserResult("CocotbParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if isinstance(token, CharacterToken):
					if (token.Value == "\n"): break
				commentText += token.Value
		else:
			raise MismatchingParserResult("CocotbParser: Expected end of line or comment")
		
		# construct result
		result = cls(fileName, moduleName, commentText)
		if DEBUG: pass
		print("CocotbParser: matched {0}".format(result))
		raise MatchingParserResult(result)
		
	def __str__(self, indent=0):
		_indent = "  " * indent
		return "{0}CoCoTB \"{1}\"::{2}".format(_indent, self._fileName, self._moduleName)
		
class ReportStatement(Statement):
	def __init__(self, message, commentText):
		super().__init__()
		self._message =		message
		self._commentText =	commentText
	
	@property
	def Message(self):
		return self._message
	
	@classmethod
	def GetParser(cls):
		if DEBUG: print("init ReportParser")
	
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):
			token = yield
	
		# match for keyword: VERILOG
		if (not isinstance(token, StringToken)):		raise MismatchingParserResult("ReportParser: Expected VERILOG keyword.")
		if (token.Value.lower() != "report"):			raise MismatchingParserResult("ReportParser: Expected VERILOG keyword.")
		
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):			raise MismatchingParserResult("ReportParser: Expected whitespace before report message.")
		
		# match for delimiter sign: "
		token = yield
		if (not isinstance(token, CharacterToken)):	raise MismatchingParserResult("ReportParser: Expected double quote sign before report message.")
		if (token.Value.lower() != "\""):						raise MismatchingParserResult("ReportParser: Expected double quote sign before report message.")
		
		# match for string: message
		message = ""
		while True:
			token = yield
			if isinstance(token, CharacterToken):
				if (token.Value == "\""):
					break
			message += token.Value
		# match for optional whitespace
		token = yield
		if DEBUG2: print("ReportParser: token={0}".format(token))
		if isinstance(token, SpaceToken):						token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):	raise MismatchingParserResult("ReportParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if isinstance(token, CharacterToken):
					if (token.Value == "\n"): break
				commentText += token.Value
		else:
			raise MismatchingParserResult("ReportParser: Expected end of line or comment")
		
		# construct result
		result = cls(message, commentText)
		if DEBUG: print("ReportParser: matched {0}".format(result))
		raise MatchingParserResult(result)
		
	def __str__(self, indent=0):
		_indent = "  " * indent
		return "{0}report \"{1}\"".format(_indent, self._message)

class LibraryStatement(Statement):
	def __init__(self, library, directoryName, commentText):
		super().__init__()
		self._library =			library
		self._directoryName =	directoryName
		self._commentText =	commentText
	
	@property
	def Library(self):
		return self._library
		
	@property
	def DirectoryName(self):
		return self._directoryName
	
	@classmethod
	def GetParser(cls):
		if DEBUG: print("init LibraryParser")
	
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):
			token = yield
		
		if DEBUG2: print("LibraryParser: token={0} expected VHDL keyword".format(repr(token)))
		if (not isinstance(token, StringToken)):		raise MismatchingParserResult("LibraryParser: Expected LIBRARY keyword.")
		if (token.Value.lower() != "library"):			raise MismatchingParserResult("LibraryParser: Expected LIBRARY keyword.")
		
		# match for whitespace
		token = yield
		if DEBUG2: print("LibraryParser: token={0} expected WHITESPACE".format(repr(token)))
		if (not isinstance(token, SpaceToken)):			raise MismatchingParserResult("LibraryParser: Expected whitespace before LIBRARY library name.")
		
		# match for library name
		library = ""
		while True:
			token = yield
			if DEBUG2: print("LibraryParser: token={0} collecting...".format(repr(token)))
			if isinstance(token, StringToken):
				library += token.Value
			elif isinstance(token, NumberToken):
				library += token.Value
			elif isinstance(token, CharacterToken):
				# if (token.Value in [_]):
				if (token.Value == "_"):
					library += token.Value
				else:
					break
			else:
				break
		
		# match for whitespace
		if DEBUG2: print("LibraryParser: token={0} expected WHITESPACE".format(repr(token)))
		if (not isinstance(token, SpaceToken)):			raise MismatchingParserResult("LibraryParser: Expected whitespace before LIBRARY directoryName.")
		
		# match for delimiter sign: "
		token = yield
		if DEBUG2: print("LibraryParser: token={0} expected double quote".format(repr(token)))
		if (not isinstance(token, CharacterToken)):	raise MismatchingParserResult("LibraryParser: Expected double quote sign before LIBRARY directoryName.")
		if (token.Value.lower() != "\""):						raise MismatchingParserResult("LibraryParser: Expected double quote sign before LIBRARY directoryName.")
		
		# match for string: directoryName
		directoryName = ""
		while True:
			token = yield
			if isinstance(token, CharacterToken):
				if (token.Value == "\""):
					break
			directoryName += token.Value
		# match for optional whitespace
		token = yield
		if DEBUG2: print("VerilogParser: token={0}".format(token))
		if isinstance(token, SpaceToken):						token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):	raise MismatchingParserResult("VerilogParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if isinstance(token, CharacterToken):
					if (token.Value == "\n"): break
				commentText += token.Value
		else:
			raise MismatchingParserResult("VerilogParser: Expected end of line or comment")
		
		# construct result
		result = cls(library, directoryName, commentText)
		if DEBUG: print("LibraryParser: matched {0}".format(result))
		raise MatchingParserResult(result)
	
	def __str__(self, indent=0):
		_indent = "  " * indent
		return "{0}Library {1} \"{2}\"".format(_indent, self._library, self._directoryName)
		
class IncludeStatement(Statement):
	def __init__(self, fileName, commentText):
		super().__init__()
		self._fileName =		fileName
		self._commentText =	commentText
		
	@property
	def FileName(self):
		return self._fileName
	
	@classmethod
	def GetParser(cls):
		if DEBUG: print("init IncludeParser")
	
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):
			token = yield
		
		if DEBUG2: print("IncludeParser: token={0} expected VHDL keyword".format(repr(token)))
		if (not isinstance(token, StringToken)):		raise MismatchingParserResult("IncludeParser: Expected INCLUDE keyword.")
		if (token.Value.lower() != "include"):			raise MismatchingParserResult("IncludeParser: Expected INCLUDE keyword.")
		
		# match for whitespace
		token = yield
		if DEBUG2: print("IncludeParser: token={0} expected WHITESPACE".format(repr(token)))
		if (not isinstance(token, SpaceToken)):			raise MismatchingParserResult("IncludeParser: Expected whitespace before INCLUDE fileName.")
		
		# match for delimiter sign: "
		token = yield
		if DEBUG2: print("IncludeParser: token={0} expected double quote".format(repr(token)))
		if (not isinstance(token, CharacterToken)):	raise MismatchingParserResult("IncludeParser: Expected double quote sign before include fileName.")
		if (token.Value.lower() != "\""):						raise MismatchingParserResult("IncludeParser: Expected double quote sign before include fileName.")
		
		# match for string: fileName
		fileName = ""
		while True:
			token = yield
			if isinstance(token, CharacterToken):
				if (token.Value == "\""):
					break
			fileName += token.Value
		# match for optional whitespace
		token = yield
		if DEBUG2: print("VerilogParser: token={0}".format(token))
		if isinstance(token, SpaceToken):						token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):	raise MismatchingParserResult("VerilogParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if isinstance(token, CharacterToken):
					if (token.Value == "\n"): break
				commentText += token.Value
		else:
			raise MismatchingParserResult("VerilogParser: Expected end of line or comment")
		
		# construct result
		result = cls(fileName, commentText)
		if DEBUG: print("IncludeParser: matched {0}".format(result))
		raise MatchingParserResult(result)
	
	def __str__(self, indent=0):
		_indent = "  " * indent
		return "{0}Include \"{1}\"".format(_indent, self._fileName)

# ==============================================================================
# Conditional Statements
# ==============================================================================
class IfStatement(ConditionalBlockStatement):
	def __init__(self, expression, commentText):
		super().__init__(expression)
		self._commentText =	commentText

	@classmethod
	def GetParser(cls):
		if DEBUG: print("init IfStatementParser")
	
		# match for IF clause
		# ==========================================================================
		# match for optional whitespace
		token = yield
		if DEBUG2: print("IfStatementParser: token={0} if".format(token))
		if isinstance(token, SpaceToken):
			token = yield
			if DEBUG2: print("IfStatementParser: token={0}".format(token))
		
		if DEBUG2: print("IfStatementParser: token={0}".format(token))
		if (not isinstance(token, StringToken)):		raise MismatchingParserResult()
		if (token.Value.lower() != "if"):						raise MismatchingParserResult()
		
		# match for whitespace
		token = yield
		if DEBUG2: print("IfStatementParser: token={0}".format(token))
		if (not isinstance(token, SpaceToken)):			raise MismatchingParserResult()
		
		# match for expression
		# ==========================================================================
		parser = Expressions.GetParser()
		parser.send(None)
		
		expressionRoot = None
		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult as ex:
			if DEBUG2: print("IfStatementParser: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			expressionRoot = ex.value
		
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):			raise MismatchingParserResult()
		
		# match for keyword: THEN
		token = yield
		if DEBUG2: print("IfStatementParser: token={0}".format(token))
		if (not isinstance(token, StringToken)):		raise MismatchingParserResult()
		if (token.Value.lower() != "then"):						raise MismatchingParserResult()
		
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):						token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):	raise MismatchingParserResult("IfStatementParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if isinstance(token, CharacterToken):
					if (token.Value == "\n"): break
				commentText += token.Value
		else:
			raise MismatchingParserResult("IfStatementParser: Expected end of line or comment")
		
		# match for inner statements
		# ==========================================================================
		# construct result
		result = cls(expressionRoot, commentText)
		parser = cls.GetRepeatParser(result.AddStatement, BlockedStatement.GetParser)
		parser.send(None)
		
		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult as ex:
			pass
			if DEBUG2: print("IfStatementParser: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			
		if DEBUG: print("IfStatementParser: matched {0}".format(result))
		raise MatchingParserResult(result)
	
	def __str__(self, indent=0):
		_indent = "  " * indent
		buffer = _indent + "IfStatement " + self._expression.__str__()
		for stmt in self._statements:
			buffer += "\n{0}{1}".format(_indent, stmt.__str__(indent + 1))
		return buffer

class ElseIfStatement(ConditionalBlockStatement):
	def __init__(self, expression, commentText):
		super().__init__(expression)
		self._commentText =	commentText

	@classmethod
	def GetParser(cls):
		if DEBUG: print("init ElseIfStatementParser")
	
		# match for multiple ELSEIF clauses
		# ==========================================================================
		token = yield
		# match for optional whitespace
		if DEBUG2: print("ElseIfStatementParser: token={0} elseif".format(token))
		if isinstance(token, SpaceToken):
			token = yield
			if DEBUG2: print("ElseIfStatementParser: token={0}".format(token))
		
		# match for keyword: ELSEIF
		if (not isinstance(token, StringToken)):		raise MismatchingParserResult()
		if (token.Value.lower() != "elseif"):				raise MismatchingParserResult()
		# match for whitespace
		token = yield
		if DEBUG2: print("ElseIfStatementParser: token={0}".format(token))
		if (not isinstance(token, SpaceToken)):			raise MismatchingParserResult()
		
		# match for expression
		# ==========================================================================
		parser = Expressions.GetParser()
		parser.send(None)
		
		expressionRoot = None
		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult as ex:
			if DEBUG2: print("ElseIfStatementParser: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			expressionRoot = ex.value
		
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):			raise MismatchingParserResult()
		
		# match for keyword: THEN
		token = yield
		if DEBUG2: print("ElseIfStatementParser: token={0}".format(token))
		if (not isinstance(token, StringToken)):		raise MismatchingParserResult()
		if (token.Value.lower() != "then"):						raise MismatchingParserResult()
		
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):						token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):	raise MismatchingParserResult("ElseIfStatementParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if isinstance(token, CharacterToken):
					if (token.Value == "\n"): break
				commentText += token.Value
		else:
			raise MismatchingParserResult("ElseIfStatementParser: Expected end of line or comment")
		
		# match for inner statements
		# ==========================================================================
		# construct result
		result = cls(expressionRoot, commentText)
		parser = cls.GetRepeatParser(result.AddStatement, BlockedStatement.GetParser)
		parser.send(None)
		
		statementList = None
		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult as ex:
			pass
			if DEBUG2: print("ElseIfStatementParser: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
		
		if DEBUG: print("ElseIfStatementParser: matched {0}".format(result))
		raise MatchingParserResult(result)
	
	def __str__(self, indent=0):
		_indent = "  " * indent
		buffer = _indent + "ElseIfStatement" + self._expression.__str__()
		for stmt in self._statements:
			buffer += "\n{0}{1}".format(_indent, stmt.__str__(indent + 1))
		return buffer
		
class ElseStatement(BlockStatement):
	def __init__(self, commentText):
		super().__init__()
		self._commentText =	commentText

	@classmethod
	def GetParser(cls):
		if DEBUG: print("init ElseStatementParser")
	
		# match for ELSE clause
		# ==========================================================================
		# match for optional whitespace
		token = yield
		if DEBUG2: print("ElseStatementParser: token={0} else".format(token))
		if isinstance(token, SpaceToken):
			token = yield
			if DEBUG2: print("ElseStatementParser: token={0}".format(token))
	
		# match for keyword: ELSE
		if (not isinstance(token, StringToken)):		raise MismatchingParserResult()
		if (token.Value.lower() != "else"):					raise MismatchingParserResult()
		
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):						token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):	raise MismatchingParserResult("ElseStatementParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if isinstance(token, CharacterToken):
					if (token.Value == "\n"): break
				commentText += token.Value
		else:
			raise MismatchingParserResult("ElseStatementParser: Expected end of line or comment")
		
		# match for inner statements
		# ==========================================================================
		# construct result
		result = cls(commentText)
		parser = cls.GetRepeatParser(result.AddStatement, BlockedStatement.GetParser)
		parser.send(None)
		
		statementList = None
		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult as ex:
			pass
			if DEBUG2: print("ElseStatementParser: matched {0} got {1}".format(ex.__class__.__name__, ex.value))

		if DEBUG: print("ElseStatementParser: matched {0}".format(result))
		raise MatchingParserResult(result)
	
	def __str__(self, indent=0):
		_indent = "  " * indent
		buffer = _indent + "ElseStatement"
		for stmt in self._statements:
			buffer += "\n{0}{1}".format(_indent, stmt.__str__(indent + 1))
		return buffer
		
class IfElseIfElseStatement(Statement):
	def __init__(self):
		super().__init__()
		self._ifStatement =				None
		self._elseIfStatements =	None
		self._elseStatement =			None

	@classmethod
	def GetParser(cls):
		if DEBUG: print("init IfElseIfElseStatementParser")
		
		# construct result
		result = cls()
	
		# match for IF clause
		# ==========================================================================
		parser = IfStatement.GetParser()
		parser.send(None)
		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult as ex:
			if DEBUG: print("IfElseIfElseStatementParser: matched {0} got {1} for IF clause".format(ex.__class__.__name__, ex.value))
			result._ifStatement = ex.value
		
		# match for multiple ELSEIF clauses
		# ==========================================================================
		try:
			while True:
				parser = ElseIfStatement.GetParser()
				parser.send(None)
				
				try:
					parser.send(token)
					while True:
						token = yield
						parser.send(token)
				except MatchingParserResult as ex:
					if DEBUG: print("IfElseIfElseStatementParser: matched {0} got {1} for ELSEIF clause".format(ex.__class__.__name__, ex.value))
					if (result._elseIfStatements is None):
						result._elseIfStatements = []
					result._elseIfStatements.append(ex.value)
		except MismatchingParserResult as ex:
			if DEBUG: print("IfElseIfElseStatementParser: mismatch {0} in ELSEIF clause. Message: {1}".format(ex.__class__.__name__, ex.value))
		
		# match for ELSE clause
		# ==========================================================================
		# match for inner statements
		parser = ElseStatement.GetParser()
		parser.send(None)
			
		try:
			parser.send(token)
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult as ex:
			if DEBUG: print("IfElseIfElseStatementParser: matched {0} got {1} for ELSE clause".format(ex.__class__.__name__, ex.value))
			result._elseStatement = ex.value
		except MismatchingParserResult as ex:
			if DEBUG: print("IfElseIfElseStatementParser: mismatch {0} in ELSE clause. Message: {1}".format(ex.__class__.__name__, ex.value))
		
		# match for END IF clause
		# ==========================================================================
		# match for optional whitespace
		if DEBUG2: print("IfElseIfElseStatementParser: token={0} end if".format(token))
		if isinstance(token, SpaceToken):
			token = yield
			if DEBUG2: print("IfElseIfElseStatementParser: token={0}".format(token))
	
		# match for keyword: END
		if DEBUG2: print("IfElseIfElseStatementParser: token={0} expected 'end'".format(token))
		if (not isinstance(token, StringToken)):		raise MismatchingParserResult()
		if (token.Value.lower() != "end"):					raise MismatchingParserResult()
	
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):			raise MismatchingParserResult()
	
		# match for keyword: IF
		token = yield
		if DEBUG2: print("IfElseIfElseStatementParser: token={0}".format(token))
		if (not isinstance(token, StringToken)):		raise MismatchingParserResult()
		if (token.Value.lower() != "if"):						raise MismatchingParserResult()
		
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):						token = yield
		# match for delimiter sign: \n
		# commentText = ""
		if (not isinstance(token, CharacterToken)):	raise MismatchingParserResult("IfElseIfElseStatementParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if isinstance(token, CharacterToken):
					if (token.Value == "\n"): break
				# commentText += token.Value
		else:
			raise MismatchingParserResult("IfElseIfElseStatementParser: Expected end of line or comment")
		
		if DEBUG: print("IfElseIfElseStatementParser: matched {0}".format(result))
		raise MatchingParserResult(result)
	
	def __str__(self, indent=0):
		_indent = "  " * indent
		buffer = _indent + "IfElseIfElseStatement\n"
		buffer += self._ifStatement.__str__(indent + 1)
		if (self._elseIfStatements is not None):
			for elseIf in self._elseIfStatements:
				buffer += "\n" + elseIf.__str__(indent + 1)
		if (self._elseStatement is not None):
			buffer += "\n" + self._elseStatement.__str__(indent + 1)
		return buffer

		
class Document(BlockStatement):
	@classmethod
	def GetParser(cls):
		if DEBUG: print("init DocumentParser")
		
		result = cls()
		parser = cls.GetRepeatParser(result.AddStatement, BlockedStatement.GetParser)
		parser.send(None)
		
		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult as ex:
			if DEBUG: print("DocumentParser: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			raise MatchingParserResult(result)
	
	def __str__(self, indent=0):
		_indent = "  " * indent
		buffer = _indent + "Document"
		for stmt in self._statements:
			buffer += "\n{0}".format(stmt.__str__(indent + 1))
		return buffer

BlockedStatement.AddChoice(IncludeStatement)
BlockedStatement.AddChoice(LibraryStatement)
BlockedStatement.AddChoice(VHDLStatement)
BlockedStatement.AddChoice(VerilogStatement)
BlockedStatement.AddChoice(CocotbStatement)
BlockedStatement.AddChoice(ReportStatement)
BlockedStatement.AddChoice(IfElseIfElseStatement)
BlockedStatement.AddChoice(CommentLine)
BlockedStatement.AddChoice(EmptyLine)
