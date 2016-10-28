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
from lib.Functions        import Init
from lib.Parser           import ParserException
from lib.CodeDOM          import AndExpression, OrExpression, XorExpression, NotExpression, InExpression, NotInExpression
from lib.CodeDOM          import EqualExpression, UnequalExpression, LessThanExpression, LessThanEqualExpression, GreaterThanExpression, GreaterThanEqualExpression
from lib.CodeDOM          import StringLiteral, IntegerLiteral, Identifier
from Parser.FilesCodeDOM  import Document, InterpolateLiteral, SubDirectoryExpression, ConcatenateExpression
from Parser.FilesCodeDOM  import ExistsFunction, ListConstructorExpression, PathStatement
from Parser.FilesCodeDOM  import IfElseIfElseStatement, ReportStatement
from Parser.FilesCodeDOM  import IncludeStatement, LibraryStatement
from Parser.FilesCodeDOM  import LDCStatement, SDCStatement, UCFStatement, XDCStatement
from Parser.FilesCodeDOM  import VHDLStatement, VerilogStatement, CocotbStatement

# to print the reconstructed files file after parsing, set DEBUG to True
DEBUG = not True

class FileReference:
	def __init__(self, file):
		self._file =    file

	@property
	def File(self):
		return self._file

	def __repr__(self):
		return str(self._file)


class IncludeFileMixIn(FileReference):
	def __str__(self):
		return "Include file: '{0!s}'".format(self._file)


class VHDLSourceFileMixIn(FileReference):
	def __init__(self, file, library):
		super().__init__(file)
		self._library =  library

	@property
	def LibraryName(self):
		return self._library

	def __str__(self):
		return "VHDL file: {0} '{1!s}'".format(self._library, self._file)


class VerilogSourceFileMixIn(FileReference):
	def __str__(self):
		return "Verilog file: '{0!s}'".format(self._file)


class CocotbSourceFileMixIn(FileReference):
	def __str__(self):
		return "Cocotb file: '{0!s}'".format(self._file)


class LDCSourceFileMixIn(FileReference):
	def __str__(self):
		return "LDC file: '{0!s}'".format(self._file)


class SDCSourceFileMixIn(FileReference):
	def __str__(self):
		return "SDC file: '{0!s}'".format(self._file)


class UCFSourceFileMixIn(FileReference):
	def __str__(self):
		return "UCF file: '{0!s}'".format(self._file)


class XDCSourceFileMixIn(FileReference):
	def __str__(self):
		return "XDC file: '{0!s}'".format(self._file)


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

	__repr__ = __str__


class FilesParserMixIn:
	_classIncludeFile =         IncludeFileMixIn
	_classVHDLSourceFile =      VHDLSourceFileMixIn
	_classVerilogSourceFile =   VerilogSourceFileMixIn
	_classCocotbSourceFile =    CocotbSourceFileMixIn
	_classLDCSourceFile =       LDCSourceFileMixIn
	_classSDCSourceFile =       SDCSourceFileMixIn
	_classUCFSourceFile =       UCFSourceFileMixIn
	_classXDCSourceFile =       XDCSourceFileMixIn

	def __init__(self):
		self._rootDirectory = None
		self._document =      None

		self._files =         []
		self._includes =      []
		self._libraries =     []
		self._warnings =      []

	def _Parse(self):
		self._ReadContent() #only available via late binding
		self._document = Document.Parse(self._content, printChar=not True) #self._content only available via late binding

		if DEBUG:
			print("{DARK_GRAY}{line}{NOCOLOR}".format(line="*"*80, **Init.Foreground))
			print("{DARK_GRAY}{doc!s}{NOCOLOR}".format(doc=self._document, **Init.Foreground))
			print("{DARK_GRAY}{line}{NOCOLOR}".format(line="*"*80, **Init.Foreground))

	# FIXME: is there a better way to passthrough/access host?
	def _Resolve(self, host, statements=None): # mccabe:disable=MC0001
		if (statements is None):
			statements = self._document.Statements

		for stmt in statements:
			if isinstance(stmt, VHDLStatement):
				path = self._EvaluatePath(host, stmt.PathExpression)
				file = self._rootDirectory / path
				vhdlSrcFile =     self._classVHDLSourceFile(file, stmt.LibraryName)
				self._files.append(vhdlSrcFile)
			elif isinstance(stmt, VerilogStatement):
				path = self._EvaluatePath(host, stmt.PathExpression)
				file = self._rootDirectory / path
				verilogSrcFile =  self._classVerilogSourceFile(file)
				self._files.append(verilogSrcFile)
			elif isinstance(stmt, CocotbStatement):
				path = self._EvaluatePath(host, stmt.PathExpression)
				file = self._rootDirectory / path
				cocotbSrcFile =   self._classCocotbSourceFile(file)
				self._files.append(cocotbSrcFile)
			elif isinstance(stmt, LDCStatement):
				path = self._EvaluatePath(host, stmt.PathExpression)
				file = self._rootDirectory / path
				ldcSrcFile =      self._classLDCSourceFile(file)
				self._files.append(ldcSrcFile)
			elif isinstance(stmt, SDCStatement):
				path = self._EvaluatePath(host, stmt.PathExpression)
				file = self._rootDirectory / path
				sdcSrcFile =      self._classSDCSourceFile(file)
				self._files.append(sdcSrcFile)
			elif isinstance(stmt, UCFStatement):
				path = self._EvaluatePath(host, stmt.PathExpression)
				file = self._rootDirectory / path
				ucfSrcFile =      self._classUCFSourceFile(file)
				self._files.append(ucfSrcFile)
			elif isinstance(stmt, XDCStatement):
				path = self._EvaluatePath(host, stmt.PathExpression)
				file = self._rootDirectory / path
				xdcSrcFile =      self._classXDCSourceFile(file)
				self._files.append(xdcSrcFile)
			elif isinstance(stmt, IncludeStatement):
				# add the include file to the fileset
				path =            self._EvaluatePath(host, stmt.PathExpression)
				file =            self._rootDirectory / path
				includeFile =     self._classFileListFile(file) #self._classFileListFile only available via late binding
				self._fileSet.AddFile(includeFile) #self._fileSet only available via late binding
				includeFile.Parse(host)

				self._includes.append(includeFile)
				for srcFile in includeFile.Files:
					self._files.append(srcFile)
				for lib in includeFile.Libraries:
					self._libraries.append(lib)
				for warn in includeFile.Warnings:
					self._warnings.append(warn)
			elif isinstance(stmt, LibraryStatement):
				path =        self._EvaluatePath(host, stmt.PathExpression)
				lib =         self._rootDirectory / path
				vhdlLibRef =  VHDLLibraryReference(stmt.Library, lib)
				self._libraries.append(vhdlLibRef)
			elif isinstance(stmt, PathStatement):
				path =        self._EvaluatePath(host, stmt.PathExpression)
				self._variables[stmt.Variable] = path
			elif isinstance(stmt, IfElseIfElseStatement):
				exprValue = self._Evaluate(host, stmt.IfClause.Expression)
				if (exprValue is True):
					self._Resolve(host, stmt.IfClause.Statements)
				elif (stmt.ElseIfClauses is not None):
					for elseif in stmt.ElseIfClauses:
						exprValue = self._Evaluate(host, elseif.Expression)
						if (exprValue is True):
							self._Resolve(host, elseif.Statements)
							break
				if ((exprValue is False) and (stmt.ElseClause is not None)):
					self._Resolve(host, stmt.ElseClause.Statements)
			elif isinstance(stmt, ReportStatement):
				self._warnings.append("WARNING: {0}".format(stmt.Message))
			else:
				ParserException("Found unknown statement type '{0!s}'.".format(type(stmt)))

	def _Evaluate(self, host, expr): # mccabe:disable=MC0001
		if isinstance(expr, Identifier):
			try:
				return self._variables[expr.Name] #self._variables only available via late binding
			except KeyError as ex:
				raise ParserException("Identifier '{0}' not found.".format(expr.Name)) from ex
		elif isinstance(expr, StringLiteral):
			return expr.Value
		elif isinstance(expr, IntegerLiteral):
			return expr.Value
		elif isinstance(expr, ExistsFunction):
			path = self._EvaluatePath(host, expr.Expression)
			return (self._rootDirectory / path).exists()
		elif isinstance(expr, ListConstructorExpression):
			return [self._Evaluate(host, item) for item in expr.List]
		elif isinstance(expr, NotExpression):
			return not self._Evaluate(host, expr.Child)
		elif isinstance(expr, InExpression):
			return self._Evaluate(host, expr.LeftChild) in self._Evaluate(host, expr.RightChild)
		elif isinstance(expr, NotInExpression):
			return self._Evaluate(host, expr.LeftChild) not in self._Evaluate(host, expr.RightChild)
		elif isinstance(expr, AndExpression):
			return self._Evaluate(host, expr.LeftChild) and self._Evaluate(host, expr.RightChild)
		elif isinstance(expr, OrExpression):
			return self._Evaluate(host, expr.LeftChild) or self._Evaluate(host, expr.RightChild)
		elif isinstance(expr, XorExpression):
			l = self._Evaluate(host, expr.LeftChild)
			r = self._Evaluate(host, expr.RightChild)
			return (not l and r) or (l and not r)
		elif isinstance(expr, EqualExpression):
			return self._Evaluate(host, expr.LeftChild) == self._Evaluate(host, expr.RightChild)
		elif isinstance(expr, UnequalExpression):
			return self._Evaluate(host, expr.LeftChild) != self._Evaluate(host, expr.RightChild)
		elif isinstance(expr, LessThanExpression):
			return self._Evaluate(host, expr.LeftChild) < self._Evaluate(host, expr.RightChild)
		elif isinstance(expr, LessThanEqualExpression):
			return self._Evaluate(host, expr.LeftChild) <= self._Evaluate(host, expr.RightChild)
		elif isinstance(expr, GreaterThanExpression):
			return self._Evaluate(host, expr.LeftChild) > self._Evaluate(host, expr.RightChild)
		elif isinstance(expr, GreaterThanEqualExpression):
			return self._Evaluate(host, expr.LeftChild) >= self._Evaluate(host, expr.RightChild)
		else:
			raise ParserException("Unsupported expression type '{0!s}'".format(type(expr)))

	def _EvaluatePath(self, host, expr):
		if isinstance(expr, Identifier):
			try:
				return self._variables[expr.Name]  # self._variables only available via late binding
			except KeyError as ex:
				raise ParserException("Identifier '{0}' not found.".format(expr.Name)) from ex
		elif isinstance(expr, StringLiteral):
			return expr.Value
		elif isinstance(expr, IntegerLiteral):
			return str(expr.Value)
		elif isinstance(expr, InterpolateLiteral):
			config = host.PoCConfig
			return config.Interpolation.interpolate(config, "CONFIG.DirectoryNames", "xxxx", str(expr), {})
		elif isinstance(expr, SubDirectoryExpression):
			l = self._EvaluatePath(host, expr.LeftChild)
			r = self._EvaluatePath(host, expr.RightChild)
			return l + "/" + r
		elif isinstance(expr, ConcatenateExpression):
			l = self._EvaluatePath(host, expr.LeftChild)
			r = self._EvaluatePath(host, expr.RightChild)
			return l + r
		else:
			raise ParserException("Unsupported path expression type '{0!s}'".format(type(expr)))

	@property
	def Files(self):      return self._files
	@property
	def Includes(self):   return self._includes
	@property
	def Libraries(self):  return self._libraries
	@property
	def Warnings(self):   return self._warnings

	def __str__(self):    return "FILES file: '{0!s}'".format(self._file) #self._file only available via late binding
	__repr__ = __str__
