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
# License:
# ==============================================================================
# Copyright 2007-2016 Patrick Lehmann - Dresden, Germany
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
from lib.Functions import Init
from lib.Parser    import MismatchingParserResult, MatchingParserResult, EmptyChoiseParserResult, GreedyMatchingParserResult
from lib.Parser    import SpaceToken, CharacterToken, StringToken, NumberToken, Tokenizer


__api__ = [
	'CodeDOMMeta',
	'CodeDOMObject',
	'Expression',
	'UnaryExpression',
	'NotExpression',
	'BinaryExpression',
	'LogicalExpression',
	'CompareExpression',
	'EqualExpression',
	'UnequalExpression',
	'LessThanExpression',
	'LessThanEqualExpression',
	'GreaterThanExpression',
	'GreaterThanEqualExpression',
	'AndExpression',
	'OrExpression',
	'XorExpression',
	'InExpression',
	'NotInExpression',
	'Function',
	'ListElement',
	'Literal',
	'StringLiteral',
	'IntegerLiteral',
	'Identifier',
	'Statement',
	'BlockStatement',
	'ConditionalBlockStatement',
	'EmptyLine',
	'CommentLine',
	'BlockedStatement',
	'ExpressionChoice'
]
__all__ = __api__


DEBUG =   False#True

# ==============================================================================
# Base classes
# ==============================================================================
class CodeDOMMeta(type):
	def parse(mcls):
		result = mcls()
		return result

	@staticmethod
	def GetChoiceParser(choices):
		if DEBUG: print("init ChoiceParser")
		parsers = []
		for choice in choices:
			parser = choice.GetParser()
			parser.send(None)
			tup = (choice, parser)
			parsers.append(tup)

		removeList =  []
		while True:
			token = yield
			for parser in parsers:
				try:
					parser[1].send(token)
				except MismatchingParserResult:
					removeList.append(parser)
				except MatchingParserResult as ex:
					if DEBUG: print("ChoiceParser: found a matching choice")
					raise ex

			for parser in removeList:
				if DEBUG: print("deactivating parser for {0}".format(parser[0].__name__))
				parsers.remove(parser)
			removeList.clear()

			if (len(parsers) == 0):
				break

		if DEBUG: print("ChoiceParser: list of choices is empty -> no match found")
		raise EmptyChoiseParserResult("ChoiceParser: ")

	@staticmethod
	def GetRepeatParser(callback, generator):
		if DEBUG: print("init RepeatParser")
		parser = generator()
		parser.send(None)

		while True:
			token = yield
			try:
				parser.send(token)
			except EmptyChoiseParserResult:
				break
			except MismatchingParserResult:
				break
			except MatchingParserResult as ex:
				if DEBUG: print("RepeatParser: found a statement")
				callback(ex.value)

				parser = generator()
				parser.send(None)

		if DEBUG: print("RepeatParser: repeat end")
		raise MatchingParserResult()


class CodeDOMObject(metaclass=CodeDOMMeta):
	def __init__(self):
		super().__init__()

	@classmethod
	def Parse(cls, string, printChar):
		parser = cls.GetParser()
		parser.send(None)

		try:
			for token in Tokenizer.GetWordTokenizer(string):
				if printChar: print("{BLUE}{token!s}{NOCOLOR}".format(token=token, **Init.Foreground))
				parser.send(token)

			# FIXME: print("send empty token")
			parser.send(None)
		except MatchingParserResult as ex:
			return ex.value
		except MismatchingParserResult as ex:
			print("ERROR: {0}".format(ex.value))

		# print("close root parser")
		# parser.close()

# ==============================================================================
# Expressions
# ==============================================================================
class Expression(CodeDOMObject):
	pass

class UnaryExpression(Expression):
	def __init__(self, child):
		super().__init__()
		self._child = child

	@property
	def Child(self):
		return self._child

class NotExpression(UnaryExpression):
	def __init__(self, child):
		super().__init__(child)

	__PARSER_EXPRESSIONS__ =  None

	@classmethod
	def GetParser(cls):
		if DEBUG: print("init NotExpressionParser")
		child = None

		# match for "!"
		token = yield
		# if (not isinstance(token, StringToken)):    raise MismatchingParserResult()
		# if (token.Value != "not"):                  raise MismatchingParserResult()
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult()
		if (token.Value != "!"):                    raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield

		# match for sub expression
		# ==========================================================================
		parser = cls.__PARSER_EXPRESSIONS__.GetParser()
		parser.send(None)
		try:
			while True:
				parser.send(token)
				token = yield
		except MatchingParserResult as ex:
			child = ex.value

		# construct result
		result = cls(child)
		if DEBUG: print("NotExpressionParser: matched {0}".format(result))
		raise MatchingParserResult(result)

	def __str__(self):
		return "not {0}".format(self._child.__str__())

class BinaryExpression(Expression):
	def __init__(self, leftChild, rightChild):
		super().__init__()
		self._leftChild =   leftChild
		self._rightChild =  rightChild

	@property
	def LeftChild(self):
		return self._leftChild

	@property
	def RightChild(self):
		return self._rightChild

	__PARSER_NAME__ =             None
	__PARSER_LHS_EXPRESSIONS__ =  None
	__PARSER_RHS_EXPRESSIONS__ =  None
	__PARSER_OPERATOR__ =         None

	@classmethod
	def GetParser(cls):
		if DEBUG: print("init " + cls.__PARSER_NAME__)
		leftChild =   None
		rightChild =  None

		# match for opening (
		token = yield
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult()
		if (token.Value != "("):                    raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield

		# match for sub expression
		# ==========================================================================
		parser = cls.__PARSER_LHS_EXPRESSIONS__.GetParser()
		parser.send(None)
		try:
			while True:
				parser.send(token)
				token =   yield
		except GreedyMatchingParserResult as ex:
			leftChild = ex.value
		except MatchingParserResult as ex:
			leftChild = ex.value
			token =     yield

		# match for optional whitespace
		if isinstance(token, SpaceToken):           token = yield
		# match for operator keyword or sign(s)
		if isinstance(cls.__PARSER_OPERATOR__, str):
			if (not isinstance(token, StringToken)):      raise MismatchingParserResult()
			if (token.Value != cls.__PARSER_OPERATOR__):  raise MismatchingParserResult()
			token = yield
			if (not isinstance(token, SpaceToken)):       raise MismatchingParserResult()
			token = yield
		elif isinstance(cls.__PARSER_OPERATOR__, tuple):
			for sign in cls.__PARSER_OPERATOR__:
				if (not isinstance(token, CharacterToken)): raise MismatchingParserResult()
				if (token.Value != sign):                   raise MismatchingParserResult()
				token = yield
				# match for optional whitespace
				if isinstance(token, SpaceToken):           token = yield
		elif isinstance(cls.__PARSER_OPERATOR__, list):
			for kw in cls.__PARSER_OPERATOR__[:-1]:
				if (not isinstance(token, StringToken)):    raise MismatchingParserResult()
				if (token.Value != kw):                     raise MismatchingParserResult()
				token = yield
				if (not isinstance(token, SpaceToken)):     raise MismatchingParserResult()
				token = yield
			kw = cls.__PARSER_OPERATOR__[-1]
			if (not isinstance(token, StringToken)):      raise MismatchingParserResult()
			if (token.Value != kw):                       raise MismatchingParserResult()
			token = yield
			if (not isinstance(token, SpaceToken)):       raise MismatchingParserResult()
			token = yield

		# match for sub expression
		# ==========================================================================
		parser = cls.__PARSER_RHS_EXPRESSIONS__.GetParser()
		parser.send(None)
		try:
			while True:
				parser.send(token)
				token =     yield
		except GreedyMatchingParserResult as ex:
			rightChild =  ex.value
		except MatchingParserResult as ex:
			rightChild =  ex.value
			token =       yield

		# match for optional whitespace
		if isinstance(token, SpaceToken):           token = yield
		# match for closing )
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult()
		if (token.Value != ")"):                    raise MismatchingParserResult()

		# construct result
		result = cls(leftChild, rightChild)
		if DEBUG: print(cls.__PARSER_NAME__ + ": matched {0}".format(result))
		raise MatchingParserResult(result)

	def __str__(self):
		if   isinstance(self.__PARSER_OPERATOR__, tuple): op = "".join(self.__PARSER_OPERATOR__)
		elif isinstance(self.__PARSER_OPERATOR__, list):  op = " ".join(self.__PARSER_OPERATOR__)
		else:                                             op = self.__PARSER_OPERATOR__

		return "({left!s} {op} {right!s})".format(left=self._leftChild, op=op, right=self._rightChild)

class LogicalExpression(BinaryExpression):
	pass

class CompareExpression(LogicalExpression):
	pass

class EqualExpression(CompareExpression):
	__PARSER_NAME__ =             "EqualExpressionParser"
	__PARSER_OPERATOR__ =         ("=",)


class UnequalExpression(CompareExpression):
	__PARSER_NAME__ =             "UnequalExpressionParser"
	__PARSER_OPERATOR__ =         ("!", "=")


class LessThanExpression(CompareExpression):
	__PARSER_NAME__ =             "LessThanExpressionParser"
	__PARSER_OPERATOR__ =         ("<",)


class LessThanEqualExpression(CompareExpression):
	__PARSER_NAME__ =             "LessThanEqualExpressionParser"
	__PARSER_OPERATOR__ =         ("<", "=")


class GreaterThanExpression(CompareExpression):
	__PARSER_NAME__ =             "GreaterThanExpressionParser"
	__PARSER_OPERATOR__ =         (">",)


class GreaterThanEqualExpression(CompareExpression):
	__PARSER_NAME__ =             "GreaterThanEqualExpressionParser"
	__PARSER_OPERATOR__ =         (">", "=")


class AndExpression(LogicalExpression):
	__PARSER_NAME__ =             "AndExpressionParser"
	__PARSER_OPERATOR__ =         "and"


class OrExpression(LogicalExpression):
	__PARSER_NAME__ =             "OrExpressionParser"
	__PARSER_OPERATOR__ =         "or"


class XorExpression(LogicalExpression):
	__PARSER_NAME__ =             "XorExpressionParser"
	__PARSER_OPERATOR__ =         "xor"


class InExpression(LogicalExpression):
	__PARSER_NAME__ =             "InExpressionParser"
	__PARSER_OPERATOR__ =         "in"


class NotInExpression(LogicalExpression):
	__PARSER_NAME__ =             "NotInExpressionParser"
	__PARSER_OPERATOR__ =         ["not", "in"]


class Function(Expression):
	pass


class ListElement(Expression):
	def __init__(self):
		super().__init__()

	__PARSER_LIST_ELEMENT_EXPRESSIONS__ = None

	@classmethod
	def GetParser(cls):
		if DEBUG: print("init ListElementParser")

		# match for EXISTS keyword
		token = yield
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult()
		if (token.Value != ","):                    raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield

		parser = cls.__PARSER_LIST_ELEMENT_EXPRESSIONS__.GetParser()
		parser.send(None)

		while True:
			parser.send(token)
			token = yield

# ==============================================================================
# Literals
# ==============================================================================
class Literal(Expression):
	pass

class StringLiteral(Literal):
	def __init__(self, value):
		super().__init__()
		self._value = value

	@property
	def Value(self):
		return self._value

	@classmethod
	def GetParser(cls):
		if DEBUG: print("init StringLiteralParser")

		# match for opening "
		token = yield
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != "\""):                      raise MismatchingParserResult()
		# match for string: value
		value = ""
		wasEscapeSign = False
		while True:
			token = yield
			if isinstance(token, CharacterToken):
				if (token.Value == "\""):
					if (wasEscapeSign is True):
						wasEscapeSign = False
						value += "\""
						continue
					else:
						break
				elif (token.Value == "\\"):
					if (wasEscapeSign is True):
						wasEscapeSign = False
						value += "\\"
						continue
					else:
						wasEscapeSign = True
						continue
			value += token.Value

		# construct result
		result = cls(value)
		if DEBUG: print("StringLiteralParser: matched {0}".format(result))
		raise MatchingParserResult(result)

	def __str__(self):
		return "\"{0}\"".format(self._value)

class IntegerLiteral(Literal):
	def __init__(self, value):
		super().__init__()
		self._value = value

	@property
	def Value(self):
		return self._value

	@classmethod
	def GetParser(cls):
		if DEBUG: print("init IntegerLiteralParser")

		# match for opening "
		token = yield
		if (not isinstance(token, NumberToken)):      raise MismatchingParserResult()
		value = int(token.Value)

		# construct result
		result = cls(value)
		if DEBUG: print("IntegerLiteralParser: matched {0}".format(result))
		raise MatchingParserResult(result)

	def __str__(self):
		return str(self._value)


class Identifier(Expression):
	def __init__(self, name):
		super().__init__()
		self._name = name

	@property
	def Name(self):
		return self._name

	@classmethod
	def GetParser(cls):
		if DEBUG: print("init IdentifierParser")

		name = ""
		while True:
			token = yield
			if isinstance(token, StringToken):
				name += token.Value
			elif isinstance(token, NumberToken):
				if (name != ""):
					name += token.Value
				else:
					raise MismatchingParserResult("IdentifierParser: Expected identifier name. Got a number.")
			elif (isinstance(token, CharacterToken) and (token.Value == "_")):
				name += token.Value
			elif (name == ""):
				raise MismatchingParserResult("IdentifierParser: Expected identifier name.")
			else:
				break

		# construct result
		result = cls(name)
		if DEBUG: print("IdentifierParser: matched {0}".format(result))
		raise GreedyMatchingParserResult(result)

	def __str__(self):
		return self._name

# ==============================================================================
# Statements
# ==============================================================================
class Statement(CodeDOMObject):
	def __init__(self, commentText=""):
		super().__init__()
		self._commentText = commentText

	@property
	def CommentText(self):        return self._commentText
	@CommentText.setter
	def CommentText(self, value): self._commentText = value


class BlockStatement(Statement):
	def __init__(self, commentText=""):
		super().__init__(commentText)
		self._statements = []

	def AddStatement(self, stmt):
		self._statements.append(stmt)

	@property
	def Statements(self):
		return self._statements

	def __str__(self, indent=0):
		_indent = "  " * indent
		buffer = _indent + "BlockStatement"
		for stmt in self._statements:
			buffer += "\n{0}".format(stmt.__str__(indent + 1))
		return buffer


class ConditionalBlockStatement(BlockStatement):
	def __init__(self, expression, commentText=""):
		super().__init__(commentText)
		self._expression = expression

	@property
	def Expression(self):
		return self._expression

	def __str__(self, indent=0):
		_indent = "  " * indent
		buffer = _indent + "ConditionalBlockStatement " + self._expression.__str__()
		for stmt in self._statements:
			buffer += "\n{0}".format(stmt.__str__(indent + 1))
		return buffer

# ==============================================================================
# Empty and comment lines
# ==============================================================================
class EmptyLine(CodeDOMObject):
	def __init__(self):
		super().__init__()

	@classmethod
	def GetParser(cls):
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):            token = yield

		# match for delimiter sign: \n
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult()
		if (token.Value.lower() != "\n"):            raise MismatchingParserResult()

		# construct result
		result = cls()
		raise MatchingParserResult(result)

	def __str__(self, indent=0):
		return "  " * indent + "<empty>"


class CommentLine(CodeDOMObject):
	def __init__(self, commentText):
		super().__init__()
		self._commentText = commentText

	@property
	def Text(self):
		return self._commentText

	@classmethod
	def GetParser(cls):
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):           token = yield

		# match for sign: #
		if (not isinstance(token, CharacterToken)): raise MismatchingParserResult()
		if (token.Value.lower() != "#"):            raise MismatchingParserResult()

		# match for any until line end
		commentText = ""
		while True:
			token = yield
			if isinstance(token, CharacterToken):
				if (token.Value == "\n"):      break
			commentText += token.Value

		# construct result
		result = cls(commentText)
		raise MatchingParserResult(result)

	def __str__(self, indent=0):
		return "{0}#{1}".format("  " * indent, self._commentText)

# ==============================================================================
# Forward declarations
# ==============================================================================
class BlockedStatement(CodeDOMObject):
	_allowedStatements = []

	@classmethod
	def AddChoice(cls, value):
		cls._allowedStatements.append(value)

	@classmethod
	def GetParser(cls):
		return cls.GetChoiceParser(cls._allowedStatements)


class ExpressionChoice(CodeDOMObject):
	_allowedExpressions = []

	@classmethod
	def AddChoice(cls, value):
		cls._allowedExpressions.append(value)

	@classmethod
	def GetParser(cls):
		return cls.GetChoiceParser(cls._allowedExpressions)
