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
from lib.Parser import CodeDOMObject, SpaceToken, CharacterToken, MismatchingParserResult, MatchingParserResult, Statement


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
		if isinstance(token, SpaceToken):            token = yield

		# match for sign: #
		if (not isinstance(token, CharacterToken)):  raise MismatchingParserResult()
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
# Blocked Statements (Forward declaration)
# ==============================================================================
class BlockedStatement(Statement):
	_allowedStatements = []

	@classmethod
	def AddChoice(cls, value):
		cls._allowedStatements.append(value)

	@classmethod
	def GetParser(cls):
		return cls.GetChoiceParser(cls._allowedStatements)
