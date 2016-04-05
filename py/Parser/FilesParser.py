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

from Parser.Parser				import ParserException
from Parser.Parser				import StringLiteral, IntegerLiteral, Identifier
from Parser.Parser				import AndExpression, OrExpression, XorExpression, NotExpression, InExpression
from Parser.Parser				import EqualExpression, UnequalExpression, LessThanExpression, LessThanEqualExpression, GreaterThanExpression, GreaterThanEqualExpression
from Parser.Parser				import ExistsFunction, ListConstructorExpression
from Parser.FilesCodeDOM	import Document
from Parser.FilesCodeDOM	import VHDLStatement, VerilogStatement, IncludeStatement, LibraryStatement, IfElseIfElseStatement, ReportStatement

class VHDLSourceFile:
	def __init__(self, library, file):
		self._library =	library
		self._file =		file
	
	@property
	def Library(self):
		return self._library
	
	@property
	def File(self):
		return self._file
	
	def __str__(self):
		return "VHDL file: {0} '{1}'".format(self._library, str(self._file))
	
	def __repr__(self):
		return self.__str__()
		
class VerilogSourceFile:
	def __init__(self, file):
		self._file = file
			
	@property
	def File(self):
		return self._file
	
	def __str__(self):
		return "Verilog file: '{0}'".format(str(self._file))
	
	def __repr__(self):
		return self.__str__()
			
class VHDLLibraryReference:
	def __init__(self, name, path):
		self._name = name.lower()
		self._path = path
	
	@property
	def Name(self):
		return self._name
		
	@property
	def Path(self):
		return self._path
	
	def __str__(self):
		return "VHDL library: {0} in '{1}'".format(self._name, str(self._path))
	
	def __repr__(self):
		return self.__str__()

class FilesParserMixIn:
	def __init__(self):
		self._rootDirectory =	None
		self._document =			None
		
		self._files =					[]
		self._includes =			[]
		self._libraries =			[]
		self._warnings =			[]
		
	def _Parse(self):
		self._ReadContent()
		self._document = Document.parse(self._content, printChar=not True)
		# print(Fore.LIGHTBLACK_EX + str(self._document) + Fore.RESET)
		
	def _Resolve(self, statements=None):
		# print("Resolving {0}".format(str(self._file)))
		if (statements is None):
			statements = self._document.Statements
		
		for stmt in statements:
			if isinstance(stmt, VHDLStatement):
				file =						self._rootDirectory / stmt.FileName
				vhdlSrcFile =			self._classVHDLSourceFile(file, stmt.LibraryName)		# stmt.Library, 
				self._files.append(vhdlSrcFile)
			elif isinstance(stmt, VerilogStatement):
				file =						self._rootDirectory / stmt.FileName
				verilogSrcFile =	self._classVerilogSourceFile(file)
				self._files.append(verilogSrcFile)
			elif isinstance(stmt, IncludeStatement):
				# add the include file to the fileset
				file =						self._rootDirectory / stmt.FileName
				includeFile =			self._classFileListFile(file)
				self._fileSet.AddFile(includeFile)
				includeFile.Parse()
				
				self._includes.append(includeFile)
				for srcFile in includeFile.Files:
					self._files.append(srcFile)
				for lib in includeFile.Libraries:
					self._libraries.append(lib)
				for warn in includeFile.Warnings:
					self._warnings.append(warn)
				
				# load, parse, add
			elif isinstance(stmt, LibraryStatement):
				lib =					self._rootDirectory / stmt.DirectoryName
				vhdlLibRef =	VHDLLibraryReference(stmt.Library, lib)
				self._libraries.append(vhdlLibRef)
			elif isinstance(stmt, IfElseIfElseStatement):
				exprValue = self._Evaluate(stmt._ifStatement._expression)
				if (exprValue == True):
					self._Resolve(stmt._ifStatement.Statements)
				elif (stmt._elseIfStatements is not None):
					for elseif in stmt._elseIfStatements:
						exprValue = self._Evaluate(elseif._expression)
						if (exprValue == True):
							self._Resolve(elseif.Statements)
							break
				if ((exprValue == False) and (stmt._elseStatement is not None)):
					self._Resolve(stmt._elseStatement.Statements)
			elif isinstance(stmt, ReportStatement):
				self._warnings.append("WARNING: {0}".format(stmt.Message))
	
	def _Evaluate(self, expr):
		if isinstance(expr, Identifier):
			try:
				return self._variables[expr.Name]
			except KeyError as ex:												raise ParserException("Identifier '{0}' not found.".format(expr.Name)) from ex
		elif isinstance(expr, StringLiteral):
			return expr.Value
		elif isinstance(expr, IntegerLiteral):
			return expr.Value
		elif isinstance(expr, ExistsFunction):
			return (self._rootDirectory / expr.Path).exists()
		elif isinstance(expr, ListConstructorExpression):
			return [self._Evaluate(item) for item in expr.List]
		elif isinstance(expr, NotExpression):
			return not self._Evaluate(expr.Child)
		elif isinstance(expr, InExpression):
			return self._Evaluate(expr.LeftChild) in self._Evaluate(expr.RightChild)
		elif isinstance(expr, AndExpression):
			return self._Evaluate(expr.LeftChild) and self._Evaluate(expr.RightChild)
		elif isinstance(expr, OrExpression):
			return self._Evaluate(expr.LeftChild) or self._Evaluate(expr.RightChild)
		elif isinstance(expr, XorExpression):
			l = self._Evaluate(expr.LeftChild)
			r = self._Evaluate(expr.RightChild)
			return (not l and r) or (l and not r)
		elif isinstance(expr, EqualExpression):
			return self._Evaluate(expr.LeftChild) == self._Evaluate(expr.RightChild)
		elif isinstance(expr, UnequalExpression):
			return self._Evaluate(expr.LeftChild) != self._Evaluate(expr.RightChild)
		elif isinstance(expr, LessThanExpression):
			return self._Evaluate(expr.LeftChild) < self._Evaluate(expr.RightChild)
		elif isinstance(expr, LessThanEqualExpression):
			return self._Evaluate(expr.LeftChild) <= self._Evaluate(expr.RightChild)
		elif isinstance(expr, GreaterThanExpression):
			return self._Evaluate(expr.LeftChild) > self._Evaluate(expr.RightChild)
		elif isinstance(expr, GreaterThanEqualExpression):
			return self._Evaluate(expr.LeftChild) >= self._Evaluate(expr.RightChild)
		else:																						raise ParserException("Unsupported expression type '{0}'".format(type(expr)))

	@property
	def Files(self):			return self._files
	@property
	def Includes(self):		return self._includes
	@property	
	def Libraries(self):	return self._libraries
	@property
	def Warnings(self):		return self._warnings

	def __str__(self):		return "FILES file: '{0}'".format(str(self._file))
	def __repr__(self):		return self.__str__()
