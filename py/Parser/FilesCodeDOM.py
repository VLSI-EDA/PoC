# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
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

from lib.Parser        import MismatchingParserResult, MatchingParserResult
from lib.Parser        import SpaceToken, CharacterToken, StringToken, NumberToken
from lib.Parser        import Statement, BlockStatement, ConditionalBlockStatement, Expressions
from Parser.CodeDOM    import EmptyLine, CommentLine, BlockedStatement as BlockedStatementBase

# ==============================================================================
# Blocked Statements (Forward declaration)
# ==============================================================================
class BlockedStatement(BlockedStatementBase):
	_allowedStatements = []

# ==============================================================================
# File Reference Statements
# ==============================================================================
class VHDLStatement(Statement):
	def __init__(self, libraryName, fileName, commentText):
		super().__init__(commentText)
		self._libraryName =   libraryName
		self._fileName =      fileName

	@property
	def LibraryName(self):  return self._libraryName
	@property
	def FileName(self):     return self._fileName

	@classmethod
	def GetParser(cls):
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield

		# match for VHDL keyword
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("VHDLParser: Expected VHDL keyword.")
		if (token.Value.lower() != "vhdl"):          raise MismatchingParserResult("VHDLParser: Expected VHDL keyword.")

		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult("VHDLParser: Expected whitespace before VHDL library name.")

		# match for library name
		library = ""
		while True:
			token = yield
			if isinstance(token, StringToken):        library += token.Value
			elif isinstance(token, NumberToken):      library += token.Value
			elif (isinstance(token, CharacterToken) and (token.Value == "_")):
				library += token.Value
			else:
				break

		# match for whitespace
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult("VHDLParser: Expected whitespace before VHDL fileName.")

		# match for delimiter sign: "
		token = yield
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("VHDLParser: Expected double quote sign before VHDL fileName.")
		if (token.Value.lower() != "\""):            raise MismatchingParserResult("VHDLParser: Expected double quote sign before VHDL fileName.")

		# match for string: fileName
		fileName = ""
		while True:
			token = yield
			if (isinstance(token, CharacterToken)and (token.Value == "\"")):    break
			fileName += token.Value

		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("VHDLParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
				commentText += token.Value
		else:
			raise MismatchingParserResult("VHDLParser: Expected end of line or comment")
		
		# construct result
		result = cls(library, fileName, commentText)
		raise MatchingParserResult(result)
	
	def __str__(self, indent=0):
		if (self._commentText != ""):
			return "{0}VHDL {1} \"{2}\" # {3}".format(("  " * indent), self._libraryName, self._fileName, self._commentText)
		else:
			return "{0}VHDL {1} \"{2}\"".format(("  " * indent), self._libraryName, self._fileName)


class VerilogStatement(Statement):
	def __init__(self, fileName, commentText):
		super().__init__()
		self._fileName =    fileName
		self._commentText =  commentText
	
	@property
	def FileName(self):
		return self._fileName
	
	@classmethod
	def GetParser(cls):
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):
			token = yield
	
		# match for keyword: VERILOG
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("VerilogParser: Expected VERILOG keyword.")
		if (token.Value.lower() != "verilog"):      raise MismatchingParserResult("VerilogParser: Expected VERILOG keyword.")
		
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult("VerilogParser: Expected whitespace before Verilog fileName.")
		
		# match for delimiter sign: "
		token = yield
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("VerilogParser: Expected double quote sign before Verilog fileName.")
		if (token.Value.lower() != "\""):            raise MismatchingParserResult("VerilogParser: Expected double quote sign before Verilog fileName.")
		
		# match for string: fileName
		fileName = ""
		while True:
			token = yield
			if (isinstance(token, CharacterToken) and (token.Value == "\"")):    break
			fileName += token.Value

		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("VerilogParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
				commentText += token.Value
		else:
			raise MismatchingParserResult("VerilogParser: Expected end of line or comment")
		
		# construct result
		result = cls(fileName, commentText)
		raise MatchingParserResult(result)
		
	def __str__(self, indent=0):
		return "{0}Verilog \"{1}\"".format("  " * indent, self._fileName)


class CocotbStatement(Statement):
	def __init__(self, fileName, commentText):
		super().__init__()
		self._fileName =    fileName
		self._commentText =  commentText
	
	@property
	def FileName(self):
		return self._fileName
		
	@classmethod
	def GetParser(cls):
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield
	
		# match for keyword: COCOTB
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("CocotbParser: Expected COCOTB keyword.")
		if (token.Value.lower() != "cocotb"):        raise MismatchingParserResult("CocotbParser: Expected COCOTB keyword.")
		
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult("CocotbParser: Expected whitespace before Python fileName.")
		
		# match for delimiter sign: "
		token = yield
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("CocotbParser: Expected double quote sign before Python fileName.")
		if (token.Value.lower() != "\""):            raise MismatchingParserResult("CocotbParser: Expected double quote sign before Python fileName.")
		
		# match for string: fileName
		fileName = ""
		while True:
			token = yield
			if (isinstance(token, CharacterToken) and (token.Value == "\"")):    break
			fileName += token.Value

		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield

		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("CocotbParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
				commentText += token.Value
		else:
			raise MismatchingParserResult("CocotbParser: Expected end of line or comment")
		
		# construct result
		result = cls(fileName, commentText)
		raise MatchingParserResult(result)
		
	def __str__(self, indent=0):
		return "{0}Cocotb \"{1}\"".format("  " * indent, self._fileName)


class UcfStatement(Statement):
	def __init__(self, fileName, commentText):
		super().__init__()
		self._fileName =    fileName
		self._commentText =  commentText

	@property
	def FileName(self):
		return self._fileName

	@classmethod
	def GetParser(cls):
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield

		# match for keyword: UCF
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("UcfParser: Expected UCF keyword.")
		if (token.Value.lower() != "ucf"):          raise MismatchingParserResult("UcfParser: Expected UCF keyword.")

		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult("UcfParser: Expected whitespace before UCF fileName.")

		# match for delimiter sign: "
		token = yield
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("UcfParser: Expected double quote sign before UCF fileName.")
		if (token.Value.lower() != "\""):            raise MismatchingParserResult("UcfParser: Expected double quote sign before UCF fileName.")

		# match for string: fileName
		fileName = ""
		while True:
			token = yield
			if (isinstance(token, CharacterToken) and (token.Value == "\"")):    break
			fileName += token.Value

		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield

		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("UcfParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
				commentText += token.Value
		else:
			raise MismatchingParserResult("UcfParser: Expected end of line or comment")

		# construct result
		result = cls(fileName, commentText)
		raise MatchingParserResult(result)

	def __str__(self, indent=0):
		return "{0}UCF \"{1}\"".format("  " * indent, self._fileName)


class XdcStatement(Statement):
	def __init__(self, fileName, commentText):
		super().__init__()
		self._fileName =    fileName
		self._commentText =  commentText

	@property
	def FileName(self):
		return self._fileName

	@classmethod
	def GetParser(cls):
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield

		# match for keyword:     XDC
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("XdcParser: Expected XDC keyword.")
		if (token.Value.lower() != "xdc"):          raise MismatchingParserResult("XdcParser: Expected XDC keyword.")

		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult("XdcParser: Expected whitespace before XDC fileName.")

		# match for delimiter sign: "
		token = yield
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("XdcParser: Expected double quote sign before XDC fileName.")
		if (token.Value.lower() != "\""):            raise MismatchingParserResult("XdcParser: Expected double quote sign before XDC fileName.")

		# match for string: fileName
		fileName = ""
		while True:
			token = yield
			if (isinstance(token, CharacterToken) and (token.Value == "\"")):    break
			fileName += token.Value

		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield

		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("XdcParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
				commentText += token.Value
		else:
			raise MismatchingParserResult("XdcParser: Expected end of line or comment")

		# construct result
		result = cls(fileName, commentText)
		raise MatchingParserResult(result)

	def __str__(self, indent=0):
		return "{0}XDC \"{1}\"".format("  " * indent, self._fileName)


class SdcStatement(Statement):
	def __init__(self, fileName, commentText):
		super().__init__()
		self._fileName =    fileName
		self._commentText =  commentText

	@property
	def FileName(self):
		return self._fileName

	@classmethod
	def GetParser(cls):
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield

		# match for keyword: SDC
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("SdcParser: Expected SDC keyword.")
		if (token.Value.lower() != "sdc"):          raise MismatchingParserResult("SdcParser: Expected SDC keyword.")

		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult("SdcParser: Expected whitespace before SDC fileName.")

		# match for delimiter sign: "
		token = yield
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("SdcParser: Expected double quote sign before SDC fileName.")
		if (token.Value.lower() != "\""):            raise MismatchingParserResult("SdcParser: Expected double quote sign before SDC fileName.")

		# match for string: fileName
		fileName = ""
		while True:
			token = yield
			if (isinstance(token, CharacterToken) and (token.Value == "\"")):    break
			fileName += token.Value

		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield

		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("SdcParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
				commentText += token.Value
		else:
			raise MismatchingParserResult("SdcParser: Expected end of line or comment")

		# construct result
		result = cls(fileName, commentText)
		raise MatchingParserResult(result)

	def __str__(self, indent=0):
		return "{0}Cocotb \"{1}\"".format("  " * indent, self._fileName)


class ReportStatement(Statement):
	def __init__(self, message, commentText):
		super().__init__()
		self._message =    message
		self._commentText =  commentText
	
	@property
	def Message(self):
		return self._message
	
	@classmethod
	def GetParser(cls):
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield
	
		# match for keyword: VERILOG
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("ReportParser: Expected REPORT keyword.")
		if (token.Value.lower() != "report"):        raise MismatchingParserResult("ReportParser: Expected REPORT keyword.")
		
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult("ReportParser: Expected whitespace before report message.")
		
		# match for delimiter sign: "
		token = yield
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("ReportParser: Expected double quote sign before report message.")
		if (token.Value.lower() != "\""):            raise MismatchingParserResult("ReportParser: Expected double quote sign before report message.")
		
		# match for string: message
		message = ""
		while True:
			token = yield
			if (isinstance(token, CharacterToken) and (token.Value == "\"")):    break
			message += token.Value

		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield

		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("ReportParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
				commentText += token.Value
		else:
			raise MismatchingParserResult("ReportParser: Expected end of line or comment")
		
		# construct result
		result = cls(message, commentText)
		raise MatchingParserResult(result)
		
	def __str__(self, indent=0):
		return "{0}report \"{1}\"".format("  " * indent, self._message)


class LibraryStatement(Statement):
	def __init__(self, library, directoryName, commentText):
		super().__init__()
		self._library =      library
		self._directoryName =  directoryName
		self._commentText =  commentText
	
	@property
	def Library(self):
		return self._library
		
	@property
	def DirectoryName(self):
		return self._directoryName
	
	@classmethod
	def GetParser(cls):
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield
		
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("LibraryParser: Expected LIBRARY keyword.")
		if (token.Value.lower() != "library"):      raise MismatchingParserResult("LibraryParser: Expected LIBRARY keyword.")
		
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult("LibraryParser: Expected whitespace before LIBRARY library name.")
		
		# match for library name
		library = ""
		while True:
			token = yield
			if isinstance(token, StringToken):
				library += token.Value
			elif isinstance(token, NumberToken):
				library += token.Value
			elif (isinstance(token, CharacterToken)and (token.Value == "_")):
				library += token.Value
			else:
				break
		
		# match for whitespace
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult("LibraryParser: Expected whitespace before LIBRARY directoryName.")
		
		# match for delimiter sign: "
		token = yield
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("LibraryParser: Expected double quote sign before LIBRARY directoryName.")
		if (token.Value.lower() != "\""):            raise MismatchingParserResult("LibraryParser: Expected double quote sign before LIBRARY directoryName.")
		
		# match for string: directoryName
		directoryName = ""
		while True:
			token = yield
			if (isinstance(token, CharacterToken) and (token.Value == "\"")):    break
			directoryName += token.Value

		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield

		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("LibraryParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
				commentText += token.Value
		else:
			raise MismatchingParserResult("LibraryParser: Expected end of line or comment")
		
		# construct result
		result = cls(library, directoryName, commentText)
		raise MatchingParserResult(result)
	
	def __str__(self, indent=0):
		return "{0}Library {1} \"{2}\"".format("  " * indent, self._library, self._directoryName)


class IncludeStatement(Statement):
	def __init__(self, fileName, commentText):
		super().__init__()
		self._fileName =    fileName
		self._commentText =  commentText
		
	@property
	def FileName(self):
		return self._fileName
	
	@classmethod
	def GetParser(cls):
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield
		
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("IncludeParser: Expected INCLUDE keyword.")
		if (token.Value.lower() != "include"):      raise MismatchingParserResult("IncludeParser: Expected INCLUDE keyword.")
		
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult("IncludeParser: Expected whitespace before INCLUDE fileName.")
		
		# match for delimiter sign: "
		token = yield
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("IncludeParser: Expected double quote sign before include fileName.")
		if (token.Value.lower() != "\""):            raise MismatchingParserResult("IncludeParser: Expected double quote sign before include fileName.")
		
		# match for string: fileName
		fileName = ""
		while True:
			token = yield
			if (isinstance(token, CharacterToken) and (token.Value == "\"")):    break
			fileName += token.Value

		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("IncludeParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
				commentText += token.Value
		else:
			raise MismatchingParserResult("IncludeParser: Expected end of line or comment")
		
		# construct result
		result = cls(fileName, commentText)
		raise MatchingParserResult(result)
	
	def __str__(self, indent=0):
		return "{0}Include \"{1}\"".format("  " * indent, self._fileName)

# ==============================================================================
# Conditional Statements
# ==============================================================================
class IfStatement(ConditionalBlockStatement):
	def __init__(self, expression, commentText):
		super().__init__(expression)
		self._commentText =  commentText

	@classmethod
	def GetParser(cls):
		# match for IF clause
		# ==========================================================================
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield

		if (not isinstance(token, StringToken)):    raise MismatchingParserResult()
		if (token.Value.lower() != "if"):            raise MismatchingParserResult()
		
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult()
		
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
			expressionRoot = ex.value
		
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult()
		
		# match for keyword: THEN
		token = yield
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult()
		if (token.Value.lower() != "then"):          raise MismatchingParserResult()
		
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield

		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("IfStatementParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
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
		except MatchingParserResult:
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
		self._commentText =  commentText

	@classmethod
	def GetParser(cls):
		# match for multiple ELSEIF clauses
		# ==========================================================================
		token = yield
		# match for optional whitespace
		if isinstance(token, SpaceToken):            token = yield

		# match for keyword: ELSEIF
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult()
		if (token.Value.lower() != "elseif"):        raise MismatchingParserResult()
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult()
		
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
			expressionRoot = ex.value
		
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult()
		
		# match for keyword: THEN
		token = yield
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult()
		if (token.Value.lower() != "then"):            raise MismatchingParserResult()
		
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("ElseIfStatementParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
				commentText += token.Value
		else:
			raise MismatchingParserResult("ElseIfStatementParser: Expected end of line or comment")
		
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
		except MatchingParserResult:
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
		self._commentText =  commentText

	@classmethod
	def GetParser(cls):
		# match for ELSE clause
		# ==========================================================================
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield

		# match for keyword: ELSE
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult()
		if (token.Value.lower() != "else"):          raise MismatchingParserResult()
		
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("ElseStatementParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
				commentText += token.Value
		else:
			raise MismatchingParserResult("ElseStatementParser: Expected end of line or comment")
		
		# match for inner statements
		# ==========================================================================
		# construct result
		result = cls(commentText)
		parser = cls.GetRepeatParser(result.AddStatement, BlockedStatement.GetParser)
		parser.send(None)
		
		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult:
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
		self._ifClause =      None
		self._elseIfClauses =  None
		self._elseClause =    None

	@property
	def IfClause(self):             return self._ifClause
	@IfClause.setter
	def IfClause(self, value):      self._ifClause = value
	@property
	def ElseIfClauses(self):        return self._elseIfClauses
	@ElseIfClauses.setter
	def ElseIfClauses(self, value): self._elseIfClauses = value
	@property
	def ElseClause(self):           return self._elseClause
	@ElseClause.setter
	def ElseClause(self, value):    self._elseClause = value

	@classmethod
	def GetParser(cls):
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
			result.IfClause = ex.value
		
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
					if (result.ElseIfClauses is None):
						result.ElseIfClauses = []
					result.ElseIfClauses.append(ex.value)
		except MismatchingParserResult as ex:
			pass

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
			result.ElseClause = ex.value
		except MismatchingParserResult as ex:
			pass

		# match for END IF clause
		# ==========================================================================
		# match for optional whitespace
		if isinstance(token, SpaceToken):            token = yield

		# match for keyword: END
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult()
		if (token.Value.lower() != "end"):          raise MismatchingParserResult()
	
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):      raise MismatchingParserResult()
	
		# match for keyword: IF
		token = yield
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult()
		if (token.Value.lower() != "if"):            raise MismatchingParserResult()
		
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield
		# match for delimiter sign: \n
		# commentText = ""
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("IfElseIfElseStatementParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
				# commentText += token.Value
		else:
			raise MismatchingParserResult("IfElseIfElseStatementParser: Expected end of line or comment")
		
		raise MatchingParserResult(result)
	
	def __str__(self, indent=0):
		_indent = "  " * indent
		buffer = _indent + "IfElseIfElseStatement\n"
		buffer += self.IfClause.__str__(indent + 1)
		if (self.ElseIfClauses is not None):
			for elseIf in self.ElseIfClauses:
				buffer += "\n" + elseIf.__str__(indent + 1)
		if (self.ElseClause is not None):
			buffer += "\n" + self.ElseClause.__str__(indent + 1)
		return buffer

		
class Document(BlockStatement):
	@classmethod
	def GetParser(cls):
		result = cls()
		parser = cls.GetRepeatParser(result.AddStatement, BlockedStatement.GetParser)
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

BlockedStatement.AddChoice(IncludeStatement)
BlockedStatement.AddChoice(LibraryStatement)
BlockedStatement.AddChoice(VHDLStatement)
BlockedStatement.AddChoice(VerilogStatement)
BlockedStatement.AddChoice(UcfStatement)
BlockedStatement.AddChoice(XdcStatement)
BlockedStatement.AddChoice(SdcStatement)
BlockedStatement.AddChoice(CocotbStatement)
BlockedStatement.AddChoice(ReportStatement)
BlockedStatement.AddChoice(IfElseIfElseStatement)
BlockedStatement.AddChoice(CommentLine)
BlockedStatement.AddChoice(EmptyLine)
