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
from lib.Parser     import MismatchingParserResult, MatchingParserResult, GreedyMatchingParserResult, StartOfDocumentToken
from lib.Parser     import SpaceToken, CharacterToken, StringToken, NumberToken
from lib.CodeDOM    import AndExpression, OrExpression, XorExpression, NotExpression, InExpression, NotInExpression, Literal, BinaryExpression
from lib.CodeDOM    import EmptyLine, CommentLine, BlockedStatement as BlockedStatementBase, ExpressionChoice
from lib.CodeDOM    import EqualExpression, UnequalExpression, LessThanExpression, LessThanEqualExpression, GreaterThanExpression, GreaterThanEqualExpression
from lib.CodeDOM    import Statement, BlockStatement, ConditionalBlockStatement, Function, Expression, ListElement
from lib.CodeDOM    import StringLiteral, IntegerLiteral, Identifier

DEBUG =   False#True

# ==============================================================================
# Forward declarations
# ==============================================================================
class BlockedStatement(BlockedStatementBase):
	_allowedStatements = []

class IfThenElseExpressions(ExpressionChoice):
	_allowedExpressions = []

class ListElementExpressions(ExpressionChoice):
	_allowedExpressions = []

# class ListConstructorExpression(ExpressionChoice):
# 	_allowedExpressions = []

class PathExpressions(ExpressionChoice):
	_allowedExpressions = []

# ==============================================================================
# Expressions
# ==============================================================================
NotExpression.__PARSER_EXPRESSIONS__ = IfThenElseExpressions

EqualExpression.__PARSER_LHS_EXPRESSIONS__ = IfThenElseExpressions
EqualExpression.__PARSER_RHS_EXPRESSIONS__ = IfThenElseExpressions

UnequalExpression.__PARSER_LHS_EXPRESSIONS__ = IfThenElseExpressions
UnequalExpression.__PARSER_RHS_EXPRESSIONS__ = IfThenElseExpressions

LessThanExpression.__PARSER_LHS_EXPRESSIONS__ = IfThenElseExpressions
LessThanExpression.__PARSER_RHS_EXPRESSIONS__ = IfThenElseExpressions

LessThanEqualExpression.__PARSER_LHS_EXPRESSIONS__ = IfThenElseExpressions
LessThanEqualExpression.__PARSER_RHS_EXPRESSIONS__ = IfThenElseExpressions

GreaterThanExpression.__PARSER_LHS_EXPRESSIONS__ = IfThenElseExpressions
GreaterThanExpression.__PARSER_RHS_EXPRESSIONS__ = IfThenElseExpressions

GreaterThanEqualExpression.__PARSER_LHS_EXPRESSIONS__ = IfThenElseExpressions
GreaterThanEqualExpression.__PARSER_RHS_EXPRESSIONS__ = IfThenElseExpressions

AndExpression.__PARSER_LHS_EXPRESSIONS__ = IfThenElseExpressions
AndExpression.__PARSER_RHS_EXPRESSIONS__ = IfThenElseExpressions

OrExpression.__PARSER_LHS_EXPRESSIONS__ = IfThenElseExpressions
OrExpression.__PARSER_RHS_EXPRESSIONS__ = IfThenElseExpressions

XorExpression.__PARSER_LHS_EXPRESSIONS__ = IfThenElseExpressions
XorExpression.__PARSER_RHS_EXPRESSIONS__ = IfThenElseExpressions

ListElement.__PARSER_LIST_ELEMENT_EXPRESSIONS__ = ListElementExpressions


class ListConstructorExpression(Expression):
	def __init__(self):
		super().__init__()
		self._list = []

	@property
	def List(self):
		return self._list

	def AddElement(self, element):
		self._list.append(element)

	@classmethod
	def GetParser(cls):
		if DEBUG: print("init ListConstructorExpressionParser")

		# match for sign "["
		token = yield
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult()
		if (token.Value != "["):                    raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield

		result = cls()
		parser = ListElementExpressions.GetParser()
		parser.send(None)

		try:
			while True:
				parser.send(token)
				token = yield
		except MatchingParserResult as ex:
			result.AddElement(ex.value)

		parser = cls.GetRepeatParser(result.AddElement, ListElement.GetParser)
		parser.send(None)

		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult:
			pass

		# match for optional whitespace
		if isinstance(token, SpaceToken):           token = yield
		# match for delimiter sign: \n
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult("ListConstructorExpressionParser: Expected end of line or comment")
		if (token.Value != "]"):                    raise MismatchingParserResult("ListConstructorExpressionParser: Expected end of line or comment")

		# construct result
		if DEBUG: print("ListConstructorExpressionParser: matched {0}".format(result))
		raise MatchingParserResult(result)

	def __str__(self):
		buffer = "[{0}".format(self._list[0])
		for item in self._list[1:]:
			buffer += ", {0}".format(item)
		buffer += "]"
		return buffer


InExpression.__PARSER_LHS_EXPRESSIONS__ = IfThenElseExpressions
InExpression.__PARSER_RHS_EXPRESSIONS__ = ListConstructorExpression

NotInExpression.__PARSER_LHS_EXPRESSIONS__ = IfThenElseExpressions
NotInExpression.__PARSER_RHS_EXPRESSIONS__ = ListConstructorExpression


class SubDirectoryExpression(BinaryExpression):
	__PARSER_NAME__ =             "SubDirectoryExpressionParser"
	__PARSER_LHS_EXPRESSIONS__ =  PathExpressions
	__PARSER_RHS_EXPRESSIONS__ =  PathExpressions
	__PARSER_OPERATOR__ =         ("/",)

class ConcatenateExpression(BinaryExpression):
	__PARSER_NAME__ =             "ConcatenateExpressionParser"
	__PARSER_LHS_EXPRESSIONS__ =  PathExpressions
	__PARSER_RHS_EXPRESSIONS__ =  PathExpressions
	__PARSER_OPERATOR__ =         ("&",)


class ExistsFunction(Function):
	def __init__(self, expression):
		super().__init__()
		self._expression = expression

	@property
	def Expression(self):
		return self._expression

	@classmethod
	def GetParser(cls):
		if DEBUG: print("init ExistsFunctionParser")

		# match for EXISTS keyword
		token = yield
		# if (not isinstance(token, StringToken)):    raise MismatchingParserResult()
		# if (token.Value != "exists"):               raise MismatchingParserResult()
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult()
		if (token.Value != "?"):                    raise MismatchingParserResult()

		# match for opening (
		token = yield
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult()
		if (token.Value != "{"):                    raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield

		# match for path expressions
		parser = PathExpressions.GetParser()
		parser.send(None)
		pathExpression = None
		try:
			while True:
				parser.send(token)
				token =         yield
		except GreedyMatchingParserResult as ex:
			pathExpression =  ex.value
		except MatchingParserResult as ex:
			pathExpression =  ex.value
			token =           yield

		# match for optional whitespace
		if isinstance(token, SpaceToken):           token = yield
		# match for closing sign: }
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult("ExistsFunctionParser: Expected end of line or comment")
		if (token.Value != "}"):                    raise MismatchingParserResult("ExistsFunctionParser: Expected end of line or comment")

		# construct result
		result = cls(pathExpression)
		if DEBUG: print("ExistsFunctionParser: matched {0}".format(result))
		raise MatchingParserResult(result)

	def __str__(self):
		return "exists{{{0!s}}}".format(self._expression)

IfThenElseExpressions.AddChoice(Identifier)
IfThenElseExpressions.AddChoice(StringLiteral)
IfThenElseExpressions.AddChoice(IntegerLiteral)
IfThenElseExpressions.AddChoice(NotExpression)
IfThenElseExpressions.AddChoice(ExistsFunction)
IfThenElseExpressions.AddChoice(AndExpression)
IfThenElseExpressions.AddChoice(OrExpression)
IfThenElseExpressions.AddChoice(XorExpression)
IfThenElseExpressions.AddChoice(EqualExpression)
IfThenElseExpressions.AddChoice(UnequalExpression)
IfThenElseExpressions.AddChoice(LessThanExpression)
IfThenElseExpressions.AddChoice(LessThanEqualExpression)
IfThenElseExpressions.AddChoice(GreaterThanExpression)
IfThenElseExpressions.AddChoice(GreaterThanEqualExpression)
IfThenElseExpressions.AddChoice(InExpression)
IfThenElseExpressions.AddChoice(NotInExpression)

ListElementExpressions.AddChoice(Identifier)
ListElementExpressions.AddChoice(StringLiteral)
ListElementExpressions.AddChoice(IntegerLiteral)


# ==============================================================================
# File Reference Statements
# ==============================================================================
class VHDLStatement(Statement):
	def __init__(self, libraryName, pathExpression, commentText):
		super().__init__(commentText)
		self._libraryName =     libraryName
		self._pathExpression =  pathExpression

	@property
	def LibraryName(self):    return self._libraryName
	@property
	def PathExpression(self): return self._pathExpression

	@classmethod # mccabe:disable=MC0001
	def GetParser(cls):
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for VHDL keyword
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("VHDLParser: Expected VHDL keyword.")
		if (token.Value.lower() != "vhdl"):         raise MismatchingParserResult("VHDLParser: Expected VHDL keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult("VHDLParser: Expected whitespace before VHDL library name.")
		# match for identifier: 		library
		parser = Identifier.GetParser()
		parser.send(None)
		library = None
		try:
			while True:
				token = yield
				parser.send(token)
		except GreedyMatchingParserResult as ex:
			library = ex.value.Name
		except MatchingParserResult as ex:
			library = ex.value.Name
			token =   yield

		# match for whitespace
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult("VHDLParser: Expected whitespace before VHDL fileName.")

		# match for a path: pathExpression
		parser = PathExpressions.GetParser()
		parser.send(None)
		pathExpression = None
		try:
			while True:
				token =         yield
				parser.send(token)
		except GreedyMatchingParserResult as ex:
			pathExpression =  ex.value
		except MatchingParserResult as ex:
			pathExpression =  ex.value
			token =           yield

		# match for optional whitespace
		if isinstance(token, SpaceToken):           token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult("VHDLParser: Expected end of line or comment")
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
		result = cls(library, pathExpression, commentText)
		raise MatchingParserResult(result)

	def __str__(self, indent=0):
		if (self._commentText != ""):
			return "{0}VHDL {1} {2!s} # {3}".format(("  " * indent), self._libraryName, self._pathExpression, self._commentText)
		else:
			return "{0}VHDL {1} {2!s}".format(("  " * indent), self._libraryName, self._pathExpression)


class VerilogStatement(Statement):
	def __init__(self, pathExpression, commentText):
		super().__init__()
		self._pathExpression =  pathExpression
		self._commentText =     commentText

	@property
	def PathExpression(self):
		return self._pathExpression

	@classmethod
	def GetParser(cls):
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for keyword: VERILOG
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("VerilogParser: Expected VERILOG keyword.")
		if (token.Value.lower() != "verilog"):      raise MismatchingParserResult("VerilogParser: Expected VERILOG keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult("VerilogParser: Expected whitespace before Verilog fileName.")

		# match for string: fileName; use a StringLiteralParser to parse the pattern
		parser = PathExpressions.GetParser()
		parser.send(None)
		pathExpression = None
		try:
			while True:
				token = yield
				parser.send(token)
		except GreedyMatchingParserResult as ex:
			pathExpression = ex.value
		except MatchingParserResult as ex:
			pathExpression = ex.value
			token = yield

		# match for optional whitespace
		if isinstance(token, SpaceToken):           token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult("VerilogParser: Expected end of line or comment")
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
		result = cls(pathExpression, commentText)
		raise MatchingParserResult(result)

	def __str__(self, indent=0):
		return "{0}Verilog {1!s}".format("  " * indent, self._pathExpression)


class CocotbStatement(Statement):
	def __init__(self, pathExpression, commentText):
		super().__init__()
		self._pathExpression =  pathExpression
		self._commentText =     commentText

	@property
	def PathExpression(self):
		return self._pathExpression

	@classmethod
	def GetParser(cls):
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for keyword: COCOTB
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("CocotbParser: Expected COCOTB keyword.")
		if (token.Value.lower() != "cocotb"):       raise MismatchingParserResult("CocotbParser: Expected COCOTB keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult("CocotbParser: Expected whitespace before Python fileName.")

		# match for string: fileName; use a StringLiteralParser to parse the pattern
		parser = PathExpressions.GetParser()
		parser.send(None)
		pathExpression = None
		try:
			while True:
				token = yield
				parser.send(token)
		except GreedyMatchingParserResult as ex:
			pathExpression = ex.value
		except MatchingParserResult as ex:
			pathExpression = ex.value
			token = yield

		# match for optional whitespace
		if isinstance(token, SpaceToken):           token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult("CocotbParser: Expected end of line or comment")
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
		result = cls(pathExpression, commentText)
		raise MatchingParserResult(result)

	def __str__(self, indent=0):
		return "{0}Cocotb {1!s}".format("  " * indent, self._pathExpression)


class ConstraintStatement(Statement):
	__PARSER_NAME__ =    None
	__PARSER_KEYWORD__ = None

	def __init__(self, pathExpression, commentText):
		super().__init__()
		self._pathExpression =  pathExpression
		self._commentText =     commentText

	@property
	def PathExpression(self):
		return self._pathExpression

	@classmethod
	def GetParser(cls):
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for keyword: __PARSER_KEYWORD__
		if (not isinstance(token, StringToken)):            raise MismatchingParserResult(cls.__PARSER_NAME__ + ": Expected UCF keyword.")
		if (token.Value.lower() != cls.__PARSER_KEYWORD__): raise MismatchingParserResult(cls.__PARSER_NAME__ + ": Expected UCF keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult(cls.__PARSER_NAME__ + ": Expected whitespace before UCF fileName.")

		# match for string: fileName; use a StringLiteralParser to parse the pattern
		parser = PathExpressions.GetParser()
		parser.send(None)
		pathExpression = None
		try:
			while True:
				token = yield
				parser.send(token)
		except GreedyMatchingParserResult as ex:
			pathExpression = ex.value
		except MatchingParserResult as ex:
			pathExpression = ex.value
			token = yield

		# match for optional whitespace
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

		# construct result
		result = cls(pathExpression, commentText)
		raise MatchingParserResult(result)

	def __str__(self, indent=0):
		return "{indent}{kw} {filename!s}".format(indent="  " * indent, kw=self.__PARSER_KEYWORD__, filename=self._pathExpression)


class LDCStatement(ConstraintStatement):
	__PARSER_NAME__ =    "LdcParser"
	__PARSER_KEYWORD__ = "ldc"


class SDCStatement(ConstraintStatement):
	__PARSER_NAME__ =    "SdcParser"
	__PARSER_KEYWORD__ = "sdc"


class UCFStatement(ConstraintStatement):
	__PARSER_NAME__ =    "UcfParser"
	__PARSER_KEYWORD__ = "ucf"


class XDCStatement(ConstraintStatement):
	__PARSER_NAME__ =    "XdcParser"
	__PARSER_KEYWORD__ = "xdc"


class InterpolateLiteral(Literal):
	def __init__(self, sectionName, optionName):
		super().__init__()
		self._sectionName = sectionName
		self._optionName =  optionName

	@property
	def SectionName(self):
		return self._sectionName

	@property
	def OptionName(self):
		return self._optionName

	@classmethod
	def GetParser(cls):
		if DEBUG: print("init InterpolateLiteralParser")

		# match for opening ${
		token = yield
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult("InterpolateLiteralParser: ")
		if (token.Value != "$"):                       raise MismatchingParserResult("InterpolateLiteralParser: ")
		token = yield
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult("InterpolateLiteralParser: ")
		if (token.Value != "{"):                       raise MismatchingParserResult("InterpolateLiteralParser: ")

		# match for interpolate value
		value = {False: "", True: ""}
		foundDelimiter = False
		while True:
			token = yield
			if isinstance(token, CharacterToken):
				if (token.Value == ":"):
					if (foundDelimiter == False):
						foundDelimiter = True
					else:
						raise MismatchingParserResult("InterpolateLiteralParser: ")
				elif (token.Value == "}"):
					break
				elif (token.Value in "._-"):
					value[foundDelimiter] += token.Value
				else:
					raise MismatchingParserResult("InterpolateLiteralParser: ")
			elif isinstance(token, (StringToken, NumberToken)):
				value[foundDelimiter] += token.Value
			else:
				raise MismatchingParserResult("InterpolateLiteralParser: ")

		if (foundDelimiter == True):
			sectionName = value[False]
			optionName =  value[True]
		else:
			sectionName = None
			optionName =  value[False]

		# construct result
		result = cls(sectionName, optionName)
		if DEBUG: print("InterpolateLiteralParser: matched {0}".format(result))
		raise MatchingParserResult(result)

	def __str__(self):
		if (self._sectionName is None):
			return "${{{optionName}}}".format(optionName=self._optionName)
		else:
			return "${{{sectionName}:{optionName}}}".format(sectionName=self._sectionName, optionName=self._optionName)


PathExpressions.AddChoice(Identifier)
PathExpressions.AddChoice(StringLiteral)
PathExpressions.AddChoice(InterpolateLiteral)
PathExpressions.AddChoice(SubDirectoryExpression)
PathExpressions.AddChoice(ConcatenateExpression)


class PathStatement(Statement):
	def __init__(self, variable, pathExpression, commentText):
		super().__init__()
		self._variable =        variable
		self._pathExpression =  pathExpression
		self._commentText =     commentText

	@property
	def Variable(self):
		return self._variable

	@property
	def PathExpression(self):
		return self._pathExpression

	@classmethod # mccabe:disable=MC0001
	def GetParser(cls):
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for keyword: path
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("PathParser: Expected UCF keyword.")
		if (token.Value.lower() != "path"):         raise MismatchingParserResult("PathParser: Expected UCF keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult("PathParser: Expected whitespace before variable.")
		# match for identifier: variable
		parser = Identifier.GetParser()
		parser.send(None)
		variable = None
		try:
			while True:
				token =   yield
				parser.send(token)
		except GreedyMatchingParserResult as ex:
			variable =  ex.value.Name
		except MatchingParserResult as ex:
			variable =  ex.value.Name
			token =     yield

		# match for optional whitespace
		if isinstance(token, SpaceToken):           token = yield
		# match for delimiter sign: =
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult("PathParser: Expected '=' sign before expression.")
		if (token.Value.lower() != "="):            raise MismatchingParserResult("PathParser: Expected '=' sign before expression.")
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield

		# match for expression
		# ==========================================================================
		parser = PathExpressions.GetParser()
		parser.send(None)
		pathExpression = None
		try:
			while True:
				parser.send(token)
				token = yield
		except GreedyMatchingParserResult as ex:
			pathExpression = ex.value
		except MatchingParserResult as ex:
			pathExpression = ex.value
			token = yield

		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult("PathParser: Expected end of line or comment")
		if (token.Value == "\n"):
			pass
		elif (token.Value == "#"):
			# match for any until line end
			while True:
				token = yield
				if (isinstance(token, CharacterToken) and (token.Value == "\n")):    break
				commentText += token.Value
		else:
			raise MismatchingParserResult("PathParser: Expected end of line or comment")

		# construct result
		result = cls(variable, pathExpression, commentText)
		raise MatchingParserResult(result)

	def __str__(self, indent=0):
		return "{indent}Path {var} := {expr!s}".format(indent="  " * indent, var=self._variable, expr=self._pathExpression)

	__repr__ = __str__

class ReportStatement(Statement):
	def __init__(self, message, commentText):
		super().__init__()
		self._message =     message
		self._commentText = commentText

	@property
	def Message(self):
		return self._message

	@classmethod
	def GetParser(cls):
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for keyword: VERILOG
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("ReportParser: Expected REPORT keyword.")
		if (token.Value.lower() != "report"):       raise MismatchingParserResult("ReportParser: Expected REPORT keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult("ReportParser: Expected whitespace before report message.")

		# match for string: fileName; use a StringLiteralParser to parse the pattern
		parser = StringLiteral.GetParser()
		parser.send(None)

		message = None
		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult as ex:
			message = ex.value.Value

		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult("ReportParser: Expected end of line or comment")
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
		return "{0}Report \"{1}\"".format("  " * indent, self._message)


class LibraryStatement(Statement):
	def __init__(self, library, pathExpression, commentText):
		super().__init__()
		self._library =         library
		self._pathExpression =  pathExpression
		self._commentText =     commentText

	@property
	def Library(self):
		return self._library

	@property
	def PathExpression(self):
		return self._pathExpression

	@classmethod # mccabe:disable=MC0001
	def GetParser(cls):
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for keyword: LIBRARY
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("LibraryParser: Expected LIBRARY keyword.")
		if (token.Value.lower() != "library"):      raise MismatchingParserResult("LibraryParser: Expected LIBRARY keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult("LibraryParser: Expected whitespace before LIBRARY library name.")
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
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult("LibraryParser: Expected whitespace before LIBRARY directoryName.")

		# match for string: fileName; use a StringLiteralParser to parse the pattern
		parser = PathExpressions.GetParser()
		parser.send(None)
		pathExpression = None
		try:
			while True:
				token = yield
				parser.send(token)
		except GreedyMatchingParserResult as ex:
			pathExpression = ex.value
		except MatchingParserResult as ex:
			pathExpression = ex.value
			token = yield

		# match for optional whitespace
		if isinstance(token, SpaceToken):           token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult("LibraryParser: Expected end of line or comment")
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
		result = cls(library, pathExpression, commentText)
		raise MatchingParserResult(result)

	def __str__(self, indent=0):
		return "{0}Library {1} {2!s}".format("  " * indent, self._library, self._pathExpression)


class IncludeStatement(Statement):
	def __init__(self, pathExpression, commentText):
		super().__init__()
		self._pathExpression =  pathExpression
		self._commentText =     commentText

	@property
	def PathExpression(self):
		return self._pathExpression

	@classmethod
	def GetParser(cls):
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for keyword: INCLUDE
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult("IncludeParser: Expected INCLUDE keyword.")
		if (token.Value.lower() != "include"):      raise MismatchingParserResult("IncludeParser: Expected INCLUDE keyword.")
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult("IncludeParser: Expected whitespace before INCLUDE fileName.")

		# match for string: fileName; use a StringLiteralParser to parse the pattern
		parser = PathExpressions.GetParser()
		parser.send(None)
		pathExpression = None
		try:
			while True:
				token = yield
				parser.send(token)
		except GreedyMatchingParserResult as ex:
			pathExpression = ex.value
		except MatchingParserResult as ex:
			pathExpression = ex.value
			token = yield

		# match for optional whitespace
		if isinstance(token, SpaceToken):           token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult("IncludeParser: Expected end of line or comment")
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
		result = cls(pathExpression, commentText)
		raise MatchingParserResult(result)

	def __str__(self, indent=0):
		return "{0}Include {1!s}".format("  " * indent, self._pathExpression)

# ==============================================================================
# Conditional Statements
# ==============================================================================
class IfStatement(ConditionalBlockStatement):
	def __init__(self, expression, commentText):
		super().__init__(expression)
		self._commentText = commentText

	@classmethod # mccabe:disable=MC0001
	def GetParser(cls):
		# match for IF clause
		# ==========================================================================
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for keyword: IF
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult()
		if (token.Value.lower() != "if"):           raise MismatchingParserResult()
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult()

		# match for expression
		# ==========================================================================
		parser = IfThenElseExpressions.GetParser()
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
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult()
		# match for keyword: THEN
		token = yield
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult()
		if (token.Value.lower() != "then"):         raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult("IfStatementParser: Expected end of line or comment")
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
		buffer = ("  " * indent) + "IfClause " + self._expression.__str__()
		for stmt in self._statements:
			buffer += "\n{0}".format(stmt.__str__(indent + 1))
		return buffer


class ElseIfStatement(ConditionalBlockStatement):
	def __init__(self, expression, commentText):
		super().__init__(expression)
		self._commentText = commentText

	@classmethod # mccabe:disable=MC0001
	def GetParser(cls):
		# match for multiple ELSEIF clauses
		# ==========================================================================
		token = yield
		# match for optional whitespace
		if isinstance(token, SpaceToken):           token = yield
		# match for keyword: ELSEIF
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult()
		if (token.Value.lower() != "elseif"):       raise MismatchingParserResult()
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult()

		# match for expression
		# ==========================================================================
		parser = IfThenElseExpressions.GetParser()
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
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult()
		# match for keyword: THEN
		token = yield
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult()
		if (token.Value.lower() != "then"):         raise MismatchingParserResult()
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
		buffer = ("  " * indent) + "ElseIfClause" + self._expression.__str__()
		for stmt in self._statements:
			buffer += "\n{0}".format(stmt.__str__(indent + 1))
		return buffer


class ElseStatement(BlockStatement):
	def __init__(self, commentText):
		super().__init__()
		self._commentText = commentText

	@classmethod
	def GetParser(cls):
		# match for ELSE clause
		# ==========================================================================
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for keyword: ELSE
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult()
		if (token.Value.lower() != "else"):         raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for delimiter sign: \n
		commentText = ""
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult("ElseStatementParser: Expected end of line or comment")
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
		buffer = ("  " * indent) + "ElseClause"
		for stmt in self._statements:
			buffer += "\n{0}".format(stmt.__str__(indent + 1))
		return buffer


class IfElseIfElseStatement(Statement):
	def __init__(self):
		super().__init__()
		self._ifClause =      None
		self._elseIfClauses = None
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

	@classmethod # mccabe:disable=MC0001
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
		if isinstance(token, SpaceToken):           token = yield
		# match for keyword: END
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult()
		if (token.Value.lower() != "end"):          raise MismatchingParserResult()
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult()
		# match for keyword: IF
		token = yield
		if (not isinstance(token, StringToken)):    raise MismatchingParserResult()
		if (token.Value.lower() != "if"):           raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield
		# match for delimiter sign: \n
		# commentText = ""
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult("IfElseIfElseStatementParser: Expected end of line or comment")
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

BlockedStatement.AddChoice(IncludeStatement)
BlockedStatement.AddChoice(LibraryStatement)
BlockedStatement.AddChoice(VHDLStatement)
BlockedStatement.AddChoice(VerilogStatement)
BlockedStatement.AddChoice(CocotbStatement)
BlockedStatement.AddChoice(LDCStatement)
BlockedStatement.AddChoice(SDCStatement)
BlockedStatement.AddChoice(UCFStatement)
BlockedStatement.AddChoice(XDCStatement)
BlockedStatement.AddChoice(PathStatement)
BlockedStatement.AddChoice(ReportStatement)
BlockedStatement.AddChoice(IfElseIfElseStatement)
BlockedStatement.AddChoice(CommentLine)
BlockedStatement.AddChoice(EmptyLine)
