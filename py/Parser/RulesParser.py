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
from lib.Parser           import ParserException
from Parser.RulesCodeDOM  import Document, PreProcessRulesStatement, PostProcessStatement, CopyStatement, ReplaceStatement, FileStatement, DeleteStatement, \
	AppendLineStatement


class Rule:
	pass


class CopyRuleMixIn(Rule):
	def __init__(self, sourcePath, destinationPath):
		self._source =      sourcePath
		self._destination = destinationPath

	@property
	def SourcePath(self):       return self._source
	@property
	def DestinationPath(self):  return self._destination

	def __str__(self):
		return "Copy rule: {0!s} => {1!s}".format(self._source, self._destination)


class DeleteRuleMixIn(Rule):
	def __init__(self, filePath):
		self._source =      filePath

	@property
	def FilePath(self):    return self._source

	def __str__(self):
		return "Delete rule: {0!s}".format(self._source)


class ReplaceRuleMixIn(Rule):
	def __init__(self, filePath, searchPattern, replacePattern, multiLine, dotAll, caseInSensitive):
		self._filePath =        filePath
		self._searchPattern =   searchPattern
		self._replacePattern =  replacePattern
		self._multiLine =       multiLine
		self._dotAll =          dotAll
		self._caseInsensitive = caseInSensitive

	@property
	def FilePath(self):                     return self._filePath
	@property
	def SearchPattern(self):                return self._searchPattern
	@property
	def ReplacePattern(self):               return self._replacePattern
	@property
	def RegExpOption_MultiLine(self):       return self._multiLine
	@property
	def RegExpOption_DotAll(self):          return self._dotAll
	@property
	def RegExpOption_CaseInsensitive(self): return self._caseInsensitive

	def __str__(self):
		return "Replace rule: in '{0!s}' replace '{1}' with '{2}'".format(self._filePath, self._searchPattern, self._replacePattern)

class AppendLineRuleMixIn(Rule):
	def __init__(self, filePath, appendPattern):
		self._filePath =        filePath
		self._appendPattern =   appendPattern

	@property
	def FilePath(self):                     return self._filePath
	@property
	def AppendPattern(self):                return self._appendPattern

	def __str__(self):
		return "AppendLine rule: in '{0!s}' append '{1}'".format(self._filePath, self._appendPattern)


class RulesParserMixIn:
	_classCopyRule =            CopyRuleMixIn
	_classDeleteRule =          DeleteRuleMixIn
	_classReplaceRule =         ReplaceRuleMixIn
	_classAppendLineRule =      AppendLineRuleMixIn

	def __init__(self):
		self._rootDirectory =     None
		self._document =          None
		
		self._preProcessRules =   []
		self._postProcessRules =  []

	def _Parse(self):
		self._ReadContent() #only available via late binding
		self._document = Document.Parse(self._content, printChar=not True) #self._content only available via late binding
		# print("{DARK_GRAY}{0!s}{NOCOLOR}".format(self._document, **Init.Foreground))
		
	def _Resolve(self):
		# print("Resolving {0}".format(str(self._file)))
		for stmt in self._document.Statements:
			if isinstance(stmt, PreProcessRulesStatement):
				for ruleStatement in stmt.Statements:
					self._ResolveRule(ruleStatement, self._preProcessRules)
			elif isinstance(stmt, PostProcessStatement):
				for ruleStatement in stmt.Statements:
					self._ResolveRule(ruleStatement, self._postProcessRules)
			else:
				ParserException("Found unknown statement type '{0}'.".format(stmt.__class__.__name__))

	def _ResolveRule(self, ruleStatement, lst):
		if isinstance(ruleStatement, CopyStatement):
			sourceFile =      ruleStatement.SourcePath
			destinationFile =  ruleStatement.DestinationPath
			rule =            self._classCopyRule(sourceFile, destinationFile)
			lst.append(rule)
		elif isinstance(ruleStatement, DeleteStatement):
			file =            ruleStatement.FilePath
			rule =            self._classDeleteRule(file)
			lst.append(rule)
		elif isinstance(ruleStatement, FileStatement):
			# FIXME: Currently, all replace and append rules are stored in individual rule instances.
			# FIXME: This prevents the system from creating a single task of multiple sub-rules -> just one open/close would be required
			filePath =        ruleStatement.FilePath
			for nestedStatement in ruleStatement.Statements:
				if isinstance(nestedStatement, ReplaceStatement):
					rule =          self._classReplaceRule(filePath, nestedStatement.SearchPattern, nestedStatement.ReplacePattern, nestedStatement.MultiLine, nestedStatement.DotAll, nestedStatement.CaseInsensitive)
					lst.append(rule)
				elif isinstance(nestedStatement, AppendLineStatement):
					rule =          self._classAppendLineRule(filePath, nestedStatement.AppendPattern)
					lst.append(rule)
				else:
					ParserException("Found unknown statement type '{0}'.".format(nestedStatement.__class__.__name__))
		else:
			ParserException("Found unknown statement type '{0}'.".format(ruleStatement.__class__.__name__))

	@property
	def PreProcessRules(self):    return self._preProcessRules
	@property
	def PostProcessRules(self):   return self._postProcessRules

	def __str__(self):    return "RULES file: '{0!s}'".format(self._file) #self._file only available via late binding
	def __repr__(self):    return self.__str__()
