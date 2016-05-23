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
from enum       import Enum


class ParserException(Exception):
	pass

class MismatchingParserResult(StopIteration):             pass
class EmptyChoiseParserResult(MismatchingParserResult):   pass
class MatchingParserResult(StopIteration):                pass
class GreedyMatchingParserResult(MatchingParserResult):   pass


class SourceCodePosition:
	def __init__(self, row, column, absolute):
		self._row =       row
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
		self._previousToken =   previousToken
		self._value =           value
		self._start =           start
		self._end =             end

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

	__CHARACTER_TRANSLATION__ = {
		"\r":    "CR",
		"\n":    "NL",
		"\t":    "TAB",
		" ":     "SPACE"
	}

	def __repr(self):
		return "<CharacterToken char={char} at pos={pos}; line={line}; col={col}>".format(
						char=self.__str__(), pos=self._start.Absolute, line=self._start.Row, col=self._start.Column)

	def __str__(self):
		if (self._value in self.__CHARACTER_TRANSLATION__):
			return self.__CHARACTER_TRANSLATION__[self._value]
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
		NumberChars =     2
		DelimiterChars =  3
		OtherChars =      4

	@classmethod
	def GetCharacterTokenizer(cls, iterable):
		previousToken =  None
		absolute =    0
		column =      0
		row =         1
		for char in iterable:
			absolute += 1
			column +=   1
			previousToken = CharacterToken(previousToken, char, SourceCodePosition(row, column, absolute))
			yield previousToken
			if (char == "\n"):
				column =  0
				row +=    1
	
	@classmethod
	def GetWordTokenizer(cls, iterable):
		previousToken =  None
		tokenKind =   cls.TokenKind.OtherChars
		start =       SourceCodePosition(1, 1, 1)
		end =         start
		buffer =      ""
		absolute =    0
		column =      0
		row =         1
		for char in iterable:
			absolute += 1
			column +=   1
			
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
			
			end.Row =       row
			end.Column =    column
			end.Absolute =  absolute
			
			if (char == "\n"):
				column =  0
				row +=    1
		# end for
