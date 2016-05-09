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

DEBUG =    False#True
DEBUG2 =  False#True

from enum      import Enum
from colorama  import Fore
from pathlib  import Path

class ParserException(Exception):
	pass

class MismatchingParserResult(StopIteration):              pass
class EmptyChoiseParserResult(MismatchingParserResult):    pass
class MatchingParserResult(StopIteration):                pass

class SourceCodePosition:
	def __init__(self, row, column, absolute):
		self._row =        row
		self._column =    column
		self._absolute =  absolute
	
	@property
	def Row(self):
		return self._row
	
	@Row.setter
	def Row(self, value):
		self._row = value
	
	@property
	def Column(self):
		return self._column
	
	@Column.setter
	def Column(self, value):
		self._column = value
	
	@property
	def Absolute(self):
		return self._absolute
	
	@Absolute.setter
	def Absolute(self, value):
		self._absolute = value

class Token:
	def __init__(self, previousToken, value, start, end=None):
		self._previousToken =  previousToken
		self._value =      value
		self._start =      start
		self._end =        end

	def __len__(self):
		return self._end.Absolute - self._start.Absolute + 1

	@property
	def PreviousToken(self):
		return self._previousToken
		
	@property
	def Value(self):
		return self._value
	
	@property
	def Start(self):
		return self._start
	
	@property
	def End(self):
		return self._end
	
	@property
	def Length(self):
		return len(self)

class CharacterToken(Token):
	def __init__(self, previousToken, value, start):
		if (len(value) != 1):    raise ValueError()
		super().__init__(previousToken, value, start=start, end=start)

	def __len__(self):
		return 1
		
	def __repr(self):
		if (self._value == "\r"):
			return "<CharacterToken char=CR at pos={0}; line={1}; col={2}>".format(self._start.Absolute, self._start.Row, self._start.Column)
		elif (self._value == "\n"):
			return "<CharacterToken char=NL at pos={0}; line={1}; col={2}>".format(self._start.Absolute, self._start.Row, self._start.Column)
		elif (self._value == "\t"):
			return "<CharacterToken char=TAB at pos={0}; line={1}; col={2}>".format(self._start.Absolute, self._start.Row, self._start.Column)
		elif (self._value == " "):
			return "<CharacterToken char=SPACE at pos={0}; line={1}; col={2}>".format(self._start.Absolute, self._start.Row, self._start.Column)
		else:
			return "<CharacterToken char={0} at pos={1}; line={2}; col={3}>".format(self._value, self._start.Absolute, self._start.Row, self._start.Column)
	
	def __str__(self):
		if (self._value == "\r"):
			return "CR"
		elif (self._value == "\n"):
			return "NL"
		elif (self._value == "\t"):
			return "TAB"
		elif (self._value == " "):
			return "SPACE"
		else:
			return self._value

class SpaceToken(Token):
	def __str__(self):
		return "<SpaceToken '{0}'>".format(self._value)

class DelimiterToken(Token):
	def __str__(self):
		return "<DelimiterToken '{0}'>".format(self._value)

class NumberToken(Token):
	def __str__(self):
		return "<NumberToken '{0}'>".format(self._value)

class StringToken(Token):
	def __str__(self):
		return "<StringToken '{0}'>".format(self._value)

class Tokenizer:
	class TokenKind(Enum):
		SpaceChars =      0
		AlphaChars =      1
		NumberChars =      2
		DelimiterChars =  3
		OtherChars =      4

	@classmethod
	def GetCharacterTokenizer(cls, iterable):
		previousToken =  None
		absolute =  0
		column =    0
		row =        1
		for char in iterable:
			absolute +=  1
			column +=    1
			previousToken = CharacterToken(previousToken, char, SourceCodePosition(row, column, absolute))
			yield previousToken
			if (char == "\n"):
				column =  0
				row +=    1
	
	@classmethod
	def GetWordTokenizer(cls, iterable):
		previousToken =  None
		tokenKind =  cls.TokenKind.OtherChars
		start =      SourceCodePosition(1, 1, 1)
		end =        start
		buffer =    ""
		absolute =  0
		column =    0
		row =        1
		for char in iterable:
			absolute +=  1
			column +=    1
			
			if (tokenKind is cls.TokenKind.SpaceChars):
				if ((char == " ") or (char == "\t")):
					buffer += char
				else:
					previousToken = SpaceToken(previousToken, buffer, start, end)
					yield previousToken
					
					if (char in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"):
						buffer = char
						tokenKind = cls.TokenKind.AlphaChars
					elif (char in "0123456789"):
						buffer = char
						tokenKind = cls.TokenKind.NumberChars
					else:
						tokenKind = cls.TokenKind.OtherChars
						previousToken = CharacterToken(previousToken, char, SourceCodePosition(row, column, absolute))
						yield previousToken
			elif (tokenKind is cls.TokenKind.AlphaChars):
				if (char in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"):
					buffer += char
				else:
					previousToken = StringToken(previousToken, buffer, start, end)
					yield previousToken
				
					if (char in " \t"):
						buffer = char
						tokenKind = cls.TokenKind.SpaceChars
					elif (char in "0123456789"):
						buffer = char
						tokenKind = cls.TokenKind.NumberChars
					else:
						tokenKind = cls.TokenKind.OtherChars
						previousToken = CharacterToken(previousToken, char, SourceCodePosition(row, column, absolute))
						yield previousToken
			elif (tokenKind is cls.TokenKind.NumberChars):
				if (char in "0123456789"):
					buffer += char
				else:
					previousToken = NumberToken(previousToken, buffer, start, end)
					yield previousToken
				
					if (char in " \t"):
						buffer = char
						tokenKind = cls.TokenKind.SpaceChars
					elif (char in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"):
						buffer = char
						tokenKind = cls.TokenKind.AlphaChars
					else:
						tokenKind = cls.TokenKind.OtherChars
						previousToken = CharacterToken(previousToken, char, SourceCodePosition(row, column, absolute))
						yield previousToken
			elif (tokenKind is cls.TokenKind.OtherChars):
				if (char in " \t"):
					buffer = char
					tokenKind = cls.TokenKind.SpaceChars
				elif (char in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"):
					buffer = char
					tokenKind = cls.TokenKind.AlphaChars
				elif (char in "0123456789"):
					buffer = char
					tokenKind = cls.TokenKind.NumberChars
				else:
					previousToken = CharacterToken(previousToken, char, SourceCodePosition(row, column, absolute))
					yield previousToken
			else:
				raise ParserException("Unknown state.")
			
			end.Row =        row
			end.Column =    column
			end.Absolute =  absolute
			
			if (char == "\n"):
				column =  0
				row +=    1
		# end for
	
class CodeDOMMeta(type):
	def parse(mcls):
		result = mcls()
		return result
	
	def GetChoiceParser(self, choices):
		if DEBUG: print("init ChoiceParser")
		parsers = []
		for choice in choices:
			# print("create parser for {0}".format(choice.__name__))
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
				except MismatchingParserResult as ex:
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
		
	def GetRepeatParser(self, callback, generator):
		if DEBUG: print("init RepeatParser")
		parser = generator()
		parser.send(None)
		
		while True:
			token = yield
			try:
				parser.send(token)
			except MismatchingParserResult as ex:
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
		# self._name =  None
	
	# @property
	# def Name(self):
		# if (self._name is not None):
			# return self._name
		# else:
			# return self.__class__.__name__

	# @Name.setter
	# def Name(self, value):
		# self._name = value
	
	@classmethod
	def parse(cls, string, printChar):
		parser = cls.GetParser()
		parser.send(None)
		
		try:
			for token in Tokenizer.GetWordTokenizer(string):
				if printChar: print(Fore.LIGHTBLUE_EX + str(token) + Fore.RESET)
				parser.send(token)
			
			# XXX: print("send empty token")
			parser.send(None)
		except MatchingParserResult as ex:
			return ex.value
		except MismatchingParserResult as ex:
			print("ERROR: {0}".format(ex.value))
		
		# print("close root parser")
		# parser.close()
		
class Expressions(CodeDOMObject):
	_allowedExpressions = []

	@classmethod
	def AddChoice(cls, value):
		cls._allowedExpressions.append(value)
	
	@classmethod
	def GetParser(cls):
		if DEBUG: print("return ExpressionsParser")
		return cls.GetChoiceParser(cls._allowedExpressions)
		# parser.send(None)
		
		# try:
			# while True:
				# token = yield
				# parser.send(token)
		# except MatchingParserResult as ex:
			# if DEBUG: print("ExpressionsParser: matched {0}".format(ex.__class__.__name__))
			# raise ex
	
	def __str__(self, indent=0):
		_indent = "  " * indent
		buffer = _indent + "........."
		for stmt in self._statements:
			buffer += "\n{0}".format(stmt.__str__(indent + 1))
		return buffer
		
class Expression(CodeDOMObject):
	pass

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
		
		# match for identifier name
		token = yield
		if DEBUG2: print("IdentifierParser: token={0} expected name".format(token))
		if (not isinstance(token, StringToken)):      raise MismatchingParserResult()
		name = token.Value
		
		# construct result
		result = cls(name)
		if DEBUG: print("IdentifierParser: matched {0}".format(result))
		raise MatchingParserResult(result)
		
	def __str__(self):
		return self._name

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
		if DEBUG2: print("StringLiteralParser: token={0} expected '\"'".format(token))
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != "\""):                      raise MismatchingParserResult()
		
		# match for string value
		value = ""
		while True:
			token = yield
			if isinstance(token, CharacterToken):
				if (token.Value == "\""):
					break
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
		if DEBUG2: print("IntegerLiteralParser: token={0} expected number".format(token))
		if (not isinstance(token, NumberToken)):      raise MismatchingParserResult()
		value = int(token.Value)
		
		# construct result
		result = cls(value)
		if DEBUG: print("IntegerLiteralParser: matched {0}".format(result))
		raise MatchingParserResult(result)
		
	def __str__(self):
		return str(self._value)

class Function(Expression):
	pass

class ExistsFunction(Function):
	def __init__(self, directoryname):
		super().__init__()
		self._path = Path(directoryname)

	@property
	def Path(self):
		return self._path

	@classmethod
	def GetParser(cls):
		if DEBUG: print("init ExistsFunctionParser")
		
		# match for EXISTS keyword
		token = yield
		if DEBUG2: print("ExistsFunctionParser: token={0} expected '('".format(token))
		# if (not isinstance(token, StringToken)):      raise MismatchingParserResult()
		# if (token.Value != "exists"):                  raise MismatchingParserResult()
		
		if (not isinstance(token, CharacterToken)):      raise MismatchingParserResult()
		if (token.Value != "?"):                        raise MismatchingParserResult()
		
		# match for opening (
		token = yield
		if DEBUG2: print("ExistsFunctionParser: token={0} expected '('".format(token))
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != "("):                      raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if DEBUG2: print("ExistsFunctionParser: token={0}".format(token))
		if isinstance(token, SpaceToken):            token = yield
		# match for delimiter sign: "
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("ExistsFunctionParser: Expected double quote sign before VHDL fileName.")
		if (token.Value.lower() != "\""):            raise MismatchingParserResult("ExistsFunctionParser: Expected double quote sign before VHDL fileName.")
		# match for string: path
		path = ""
		while True:
			token = yield
			if isinstance(token, CharacterToken):
				if (token.Value == "\""):
					break
			path += token.Value
		# match for optional whitespace
		token = yield
		if DEBUG2: print("ExistsFunctionParser: token={0}".format(token))
		if isinstance(token, SpaceToken):            token = yield
		# match for delimiter sign: \n
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("ExistsFunctionParser: Expected end of line or comment")
		if (token.Value != ")"):                    raise MismatchingParserResult("ExistsFunctionParser: Expected end of line or comment")
		
		# construct result
		result = cls(path)
		if DEBUG: print("ExistsFunctionParser: matched {0}".format(result))
		raise MatchingParserResult(result)
		
	def __str__(self):
		return "exists(\"{0!s}\")".format(self._path)
		
class ListElement(Expression):
	def __init__(self):
		super().__init__()

	@classmethod
	def GetParser(cls):
		if DEBUG: print("init ListElementParser")
		
		# match for EXISTS keyword
		token = yield
		if DEBUG2: print("ListElementParser: token={0} expected '('".format(token))
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult()
		if (token.Value != ","):                    raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if DEBUG2: print("ListElementParser: token={0}".format(token))
		if isinstance(token, SpaceToken):            token = yield
		
		parser = Expressions.GetParser()
		parser.send(None)
		
		while True:
			parser.send(token)
			token = yield
		
class ListConstructorExpression(Expression):
	def __init__(self):
		super().__init__()
		self._list = []

	@property
	def List(self):
		return self._list
	
	def AddElement(self, element):
		if DEBUG2: print("ListConstructorExpression: adding element {0}".format(element))
		self._list.append(element)

	@classmethod
	def GetParser(cls):
		if DEBUG: print("init ListConstructorExpressionParser")
		
		# match for sign "["
		token = yield
		if DEBUG2: print("ListConstructorExpressionParser: token={0} expected '('".format(token))
		if (not isinstance(token, CharacterToken)):      raise MismatchingParserResult()
		if (token.Value != "["):                        raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if DEBUG2: print("ListConstructorExpressionParser: token={0}".format(token))
		if isinstance(token, SpaceToken):            token = yield
		
		result = cls()
		parser = Expressions.GetParser()
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
		except MatchingParserResult as ex:
			pass
		
		# match for optional whitespace
		# token = yield
		if DEBUG2: print("ListConstructorExpressionParser: token={0}".format(token))
		if isinstance(token, SpaceToken):            token = yield
		# match for delimiter sign: \n
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult("ListConstructorExpressionParser: Expected end of line or comment")
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

	@classmethod
	def GetParser(cls):
		if DEBUG: print("init NotExpressionParser")
		
		# match for "!"
		token = yield
		if DEBUG2: print("NotExpressionParser: token={0} expected '('".format(token))
		# if (not isinstance(token, StringToken)):      raise MismatchingParserResult()
		# if (token.Value != "not"):                    raise MismatchingParserResult()
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != "!"):                      raise MismatchingParserResult()
		
		# match for optional whitespace
		token = yield
		if DEBUG2: print("NotExpressionParser: token={0}".format(token))
		if isinstance(token, SpaceToken):              token = yield
		
		# match for sub expression
		# ==========================================================================
		parser = Expressions.GetParser()
		parser.send(None)
		try:
			while True:
				parser.send(token)
				token = yield
		except MatchingParserResult as ex:
			if DEBUG2: print("NotExpressionParser: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
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
		self._leftChild =    leftChild
		self._rightChild =  rightChild
	
	@property
	def LeftChild(self):
		return self._leftChild
	
	@property
	def RightChild(self):
		return self._rightChild
		
	def __str__(self):
		return "({0} ?? {1})".format(self._leftChild.__str__(), self._rightChild.__str__())

class LogicalExpression(BinaryExpression):
	pass

class CompareExpression(BinaryExpression):
	pass

class EqualExpression(CompareExpression):
	@classmethod
	def GetParser(cls):
		if DEBUG: print("init EqualExpressionParser")
		
		# match for opening (
		token = yield
		if DEBUG2: print("EqualExpressionParser: token={0} expected '('".format(token))
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != "("):                      raise MismatchingParserResult()
		
		# match for optional whitespace
		token = yield
		if DEBUG2: print("EqualExpressionParser: token={0}".format(token))
		if isinstance(token, SpaceToken):
			token = yield
			if DEBUG2: print("EqualExpressionParser: token={0}".format(token))
		
		# match for sub expression
		# ==========================================================================
		parser = Expressions.GetParser()
		parser.send(None)
		try:
			while True:
				parser.send(token)
				token = yield
		except MatchingParserResult as ex:
			if DEBUG2: print("EqualExpressionParser: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			leftChild = ex.value
			
		# match for optional whitespace
		token = yield
		if DEBUG2: print("EqualExpressionParser: token={0}".format(token))
		if isinstance(token, SpaceToken):
			token = yield
			if DEBUG2: print("EqualExpressionParser: token={0}".format(token))
		
		# match for equal sign =
		if DEBUG2: print("EqualExpressionParser: token={0} expected '='".format(token))
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != "="):                      raise MismatchingParserResult()
		
		# match for optional whitespace
		token = yield
		if DEBUG2: print("EqualExpressionParser: token={0}".format(token))
		if isinstance(token, SpaceToken):
			token = yield
			if DEBUG2: print("EqualExpressionParser: token={0}".format(token))
		
		# match for sub expression
		# ==========================================================================
		parser = Expressions.GetParser()
		parser.send(None)
		try:
			while True:
				parser.send(token)
				token = yield
		except MatchingParserResult as ex:
			if DEBUG2: print("EqualExpressionParser: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			rightChild = ex.value
		
		# match for optional whitespace
		token = yield
		if DEBUG2: print("EqualExpressionParser: token={0}".format(token))
		if isinstance(token, SpaceToken):
			token = yield
			if DEBUG2: print("EqualExpressionParser: token={0}".format(token))
		
		# match for closing )
		if DEBUG2: print("EqualExpressionParser: token={0} expected ')'".format(token))
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != ")"):                      raise MismatchingParserResult()
	
		# construct result
		result = cls(leftChild, rightChild)
		if DEBUG: print("EqualExpressionParser: matched {0}".format(result))
		raise MatchingParserResult(result)
		
	def __str__(self):
		return "({0} = {1})".format(self._leftChild.__str__(), self._rightChild.__str__())
		
class UnequalExpression(CompareExpression):
	@classmethod
	def GetParser(cls):
		if DEBUG: print("init UnequalExpressionParser")
		
		# match for opening (
		token = yield
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != "("):                      raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		
		# match for sub expression
		# ==========================================================================
		parser = Expressions.GetParser()
		parser.send(None)
		try:
			while True:
				parser.send(token)
				token = yield
		except MatchingParserResult as ex:
			if DEBUG2: print("UnequalExpressionParser: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			leftChild = ex.value
		
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		# match for equal sign !
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != "!"):                      raise MismatchingParserResult()
		# match for equal sign =
		token = yield
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != "="):                      raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		
		# match for sub expression
		# ==========================================================================
		parser = Expressions.GetParser()
		parser.send(None)
		try:
			while True:
				parser.send(token)
				token = yield
		except MatchingParserResult as ex:
			if DEBUG2: print("UnequalExpressionParser: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			rightChild = ex.value
		
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		# match for closing )
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != ")"):                      raise MismatchingParserResult()
		
		# construct result
		result = cls(leftChild, rightChild)
		if DEBUG: print("UnequalExpressionParser: matched {0}".format(result))
		raise MatchingParserResult(result)
		
	def __str__(self):
		return "({0} != {1})".format(self._leftChild.__str__(), self._rightChild.__str__())
		
class LessThanExpression(CompareExpression):
	@classmethod
	def GetParser(cls):
		if DEBUG: print("init LessThanExpressionParser")
		
		# match for opening (
		token = yield
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != "("):                      raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		
		# match for sub expression
		# ==========================================================================
		parser = Expressions.GetParser()
		parser.send(None)
		try:
			while True:
				parser.send(token)
				token = yield
		except MatchingParserResult as ex:
			if DEBUG2: print("LessThanExpressionParser: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			leftChild = ex.value
		
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		# match for equal sign <
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != "<"):                      raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		
		# match for sub expression
		# ==========================================================================
		parser = Expressions.GetParser()
		parser.send(None)
		try:
			while True:
				parser.send(token)
				token = yield
		except MatchingParserResult as ex:
			if DEBUG2: print("LessThanExpressionParser: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			rightChild = ex.value
		
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		# match for closing )
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != ")"):                      raise MismatchingParserResult()
		
		# construct result
		result = cls(leftChild, rightChild)
		if DEBUG: print("LessThanExpressionParser: matched {0}".format(result))
		raise MatchingParserResult(result)
		
	def __str__(self):
		return "({0} < {1})".format(self._leftChild.__str__(), self._rightChild.__str__())
		
class LessThanEqualExpression(CompareExpression):
	@classmethod
	def GetParser(cls):
		if DEBUG: print("init LessThanEqualExpression")
		
		# match for opening (
		token = yield
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != "("):                      raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		
		# match for sub expression
		# ==========================================================================
		parser = Expressions.GetParser()
		parser.send(None)
		try:
			while True:
				parser.send(token)
				token = yield
		except MatchingParserResult as ex:
			if DEBUG2: print("LessThanEqualExpression: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			leftChild = ex.value
		
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		# match for equal sign <
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != "<"):                      raise MismatchingParserResult()
		# match for equal sign =
		token = yield
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != "="):                      raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		
		# match for sub expression
		# ==========================================================================
		parser = Expressions.GetParser()
		parser.send(None)
		try:
			while True:
				parser.send(token)
				token = yield
		except MatchingParserResult as ex:
			if DEBUG2: print("LessThanEqualExpression: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			rightChild = ex.value
		
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		# match for closing )
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != ")"):                      raise MismatchingParserResult()
		
		# construct result
		result = cls(leftChild, rightChild)
		if DEBUG: print("LessThanEqualExpression: matched {0}".format(result))
		raise MatchingParserResult(result)
		
	def __str__(self):
		return "({0} <= {1})".format(self._leftChild.__str__(), self._rightChild.__str__())
		
class GreaterThanExpression(CompareExpression):
	@classmethod
	def GetParser(cls):
		if DEBUG: print("init GreaterThanExpression")
		
		# match for opening (
		token = yield
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != "("):                      raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		
		# match for sub expression
		# ==========================================================================
		parser = Expressions.GetParser()
		parser.send(None)
		try:
			while True:
				parser.send(token)
				token = yield
		except MatchingParserResult as ex:
			if DEBUG2: print("GreaterThanExpression: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			leftChild = ex.value
		
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		# match for equal sign >
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != ">"):                      raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		
		# match for sub expression
		# ==========================================================================
		parser = Expressions.GetParser()
		parser.send(None)
		try:
			while True:
				parser.send(token)
				token = yield
		except MatchingParserResult as ex:
			if DEBUG2: print("GreaterThanExpression: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			rightChild = ex.value
		
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		# match for closing )
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != ")"):                      raise MismatchingParserResult()
		
		# construct result
		result = cls(leftChild, rightChild)
		if DEBUG: print("GreaterThanExpression: matched {0}".format(result))
		raise MatchingParserResult(result)
		
	def __str__(self):
		return "({0} != {1})".format(self._leftChild.__str__(), self._rightChild.__str__())
		
class GreaterThanEqualExpression(CompareExpression):
	@classmethod
	def GetParser(cls):
		if DEBUG: print("init GreaterThanEqualExpression")
		
		# match for opening (
		token = yield
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != "("):                      raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		
		# match for sub expression
		# ==========================================================================
		parser = Expressions.GetParser()
		parser.send(None)
		try:
			while True:
				parser.send(token)
				token = yield
		except MatchingParserResult as ex:
			if DEBUG2: print("GreaterThanEqualExpression: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			leftChild = ex.value
		
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		# match for equal sign >
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != ">"):                      raise MismatchingParserResult()
		# match for equal sign =
		token = yield
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != "="):                      raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		
		# match for sub expression
		# ==========================================================================
		parser = Expressions.GetParser()
		parser.send(None)
		try:
			while True:
				parser.send(token)
				token = yield
		except MatchingParserResult as ex:
			if DEBUG2: print("GreaterThanEqualExpression: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			rightChild = ex.value
		
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		# match for closing )
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != ")"):                      raise MismatchingParserResult()
		
		# construct result
		result = cls(leftChild, rightChild)
		if DEBUG: print("GreaterThanEqualExpression: matched {0}".format(result))
		raise MatchingParserResult(result)
		
	def __str__(self):
		return "({0} >= {1})".format(self._leftChild.__str__(), self._rightChild.__str__())
		
class AndExpression(LogicalExpression):
	@classmethod
	def GetParser(cls):
		if DEBUG: print("init AndExpressionParser")
		
		# match for opening (
		token = yield
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != "("):                      raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		
		# match for sub expression
		# ==========================================================================
		parser = Expressions.GetParser()
		parser.send(None)
		try:
			while True:
				parser.send(token)
				token = yield
		except MatchingParserResult as ex:
			if DEBUG2: print("AndExpressionParser: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			leftChild = ex.value
		
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):        raise MismatchingParserResult()
		# match for AND keyword
		token = yield
		if (not isinstance(token, StringToken)):      raise MismatchingParserResult()
		if (token.Value.lower() != "and"):            raise MismatchingParserResult()
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):        raise MismatchingParserResult()
		
		# match for sub expression
		# ==========================================================================
		parser = Expressions.GetParser()
		parser.send(None)
		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult as ex:
			if DEBUG2: print("AndExpressionParser: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			rightChild = ex.value
		
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		# match for closing )
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != ")"):                      raise MismatchingParserResult()
		
		# construct result
		result = cls(leftChild, rightChild)
		if DEBUG: print("AndExpressionParser: matched {0}".format(result))
		raise MatchingParserResult(result)
		
	def __str__(self):
		return "({0} and {1})".format(self._leftChild.__str__(), self._rightChild.__str__())

class OrExpression(LogicalExpression):
	@classmethod
	def GetParser(cls):
		if DEBUG: print("init OrExpressionParser")
		
		# match for opening (
		token = yield
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != "("):                      raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		
		# match for sub expression
		# ==========================================================================
		parser = Expressions.GetParser()
		parser.send(None)
		try:
			while True:
				parser.send(token)
				token = yield
		except MatchingParserResult as ex:
			if DEBUG2: print("OrExpressionParser: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			leftChild = ex.value
		
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):        raise MismatchingParserResult()
		# match for OR keyword
		token = yield
		if (not isinstance(token, StringToken)):      raise MismatchingParserResult()
		if (token.Value.lower() != "or"):              raise MismatchingParserResult()
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):        raise MismatchingParserResult()
		
		# match for sub expression
		# ==========================================================================
		parser = Expressions.GetParser()
		parser.send(None)
		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult as ex:
			if DEBUG2: print("OrExpressionParser: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			rightChild = ex.value
		
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		# match for closing )
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != ")"):                      raise MismatchingParserResult()
		
		# construct result
		result = cls(leftChild, rightChild)
		if DEBUG: print("OrExpressionParser: matched {0}".format(result))
		raise MatchingParserResult(result)
		
	def __str__(self):
		return "({0} or {1})".format(self._leftChild.__str__(), self._rightChild.__str__())
		
class XorExpression(LogicalExpression):
	@classmethod
	def GetParser(cls):
		if DEBUG: print("init XorExpressionParser")
		
		# match for opening (
		token = yield
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != "("):                      raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		
		# match for sub expression
		# ==========================================================================
		parser = Expressions.GetParser()
		parser.send(None)
		try:
			while True:
				parser.send(token)
				token = yield
		except MatchingParserResult as ex:
			if DEBUG2: print("XorExpression: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			leftChild = ex.value
		
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):        raise MismatchingParserResult()
		# match for XOR keyword
		token = yield
		if (not isinstance(token, StringToken)):      raise MismatchingParserResult()
		if (token.Value.lower() != "xor"):            raise MismatchingParserResult()
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):        raise MismatchingParserResult()
		
		# match for sub expression
		# ==========================================================================
		parser = Expressions.GetParser()
		parser.send(None)
		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult as ex:
			if DEBUG2: print("XorExpression: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			rightChild = ex.value
		
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		# match for closing )
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != ")"):                      raise MismatchingParserResult()
		
		# construct result
		result = cls(leftChild, rightChild)
		if DEBUG: print("XorExpressionParser: matched {0}".format(result))
		raise MatchingParserResult(result)
		
	def __str__(self):
		return "({0} xor {1})".format(self._leftChild.__str__(), self._rightChild.__str__())
		
class InExpression(LogicalExpression):
	@classmethod
	def GetParser(cls):
		if DEBUG: print("init InExpressionParser")
		
		# match for opening (
		token = yield
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != "("):                      raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		
		# match for sub expression
		# ==========================================================================
		parser = Expressions.GetParser()
		parser.send(None)
		try:
			while True:
				parser.send(token)
				token = yield
		except MatchingParserResult as ex:
			if DEBUG2: print("InExpressionParser: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			leftChild = ex.value
		
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):        raise MismatchingParserResult()
		# match for IN keyword
		token = yield
		if (not isinstance(token, StringToken)):      raise MismatchingParserResult()
		if (token.Value.lower() != "in"):            raise MismatchingParserResult()
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):        raise MismatchingParserResult()
		
		# match for sub expression
		# ==========================================================================
		parser = ListConstructorExpression.GetParser()
		parser.send(None)
		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult as ex:
			if DEBUG2: print("InExpressionParser: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			rightChild = ex.value
		
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		# match for closing )
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != ")"):                      raise MismatchingParserResult()
		
		# construct result
		result = cls(leftChild, rightChild)
		if DEBUG: print("InExpressionParser: matched {0}".format(result))
		raise MatchingParserResult(result)
		
	def __str__(self):
		return "({0} in {1})".format(self._leftChild.__str__(), self._rightChild.__str__())

class NotInExpression(LogicalExpression):
	@classmethod
	def GetParser(cls):
		if DEBUG: print("init NotInExpressionParser")

		# match for opening (
		token = yield
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != "("):                      raise MismatchingParserResult()
		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield

		# match for sub expression
		# ==========================================================================
		parser = Expressions.GetParser()
		parser.send(None)
		try:
			while True:
				parser.send(token)
				token = yield
		except MatchingParserResult as ex:
			if DEBUG2: print("NotInExpressionParser: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			leftChild = ex.value

		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):        raise MismatchingParserResult()
		# match for NOT keyword
		token = yield
		if (not isinstance(token, StringToken)):      raise MismatchingParserResult()
		if (token.Value.lower() != "not"):            raise MismatchingParserResult()
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):        raise MismatchingParserResult()
		# match for IN keyword
		token = yield
		if (not isinstance(token, StringToken)):      raise MismatchingParserResult()
		if (token.Value.lower() != "in"):              raise MismatchingParserResult()
		# match for whitespace
		token = yield
		if (not isinstance(token, SpaceToken)):        raise MismatchingParserResult()

		# match for sub expression
		# ==========================================================================
		parser = ListConstructorExpression.GetParser()
		parser.send(None)
		try:
			while True:
				token = yield
				parser.send(token)
		except MatchingParserResult as ex:
			if DEBUG2: print("NotInExpressionParser: matched {0} got {1}".format(ex.__class__.__name__, ex.value))
			rightChild = ex.value

		# match for optional whitespace
		token = yield
		if isinstance(token, SpaceToken):              token = yield
		# match for closing )
		if (not isinstance(token, CharacterToken)):    raise MismatchingParserResult()
		if (token.Value != ")"):                      raise MismatchingParserResult()

		# construct result
		result = cls(leftChild, rightChild)
		if DEBUG: print("NotInExpressionParser: matched {0}".format(result))
		raise MatchingParserResult(result)

	def __str__(self):
		return "({0} not in {1})".format(self._leftChild.__str__(), self._rightChild.__str__())

Expressions.AddChoice(Identifier)
Expressions.AddChoice(StringLiteral)
Expressions.AddChoice(IntegerLiteral)
Expressions.AddChoice(NotExpression)
Expressions.AddChoice(ExistsFunction)
Expressions.AddChoice(AndExpression)
Expressions.AddChoice(OrExpression)
Expressions.AddChoice(XorExpression)
Expressions.AddChoice(EqualExpression)
Expressions.AddChoice(UnequalExpression)
Expressions.AddChoice(LessThanExpression)
Expressions.AddChoice(LessThanEqualExpression)
Expressions.AddChoice(GreaterThanExpression)
Expressions.AddChoice(GreaterThanEqualExpression)
Expressions.AddChoice(InExpression)
Expressions.AddChoice(NotInExpression)

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
