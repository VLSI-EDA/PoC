# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:          Patrick Lehmann
#
# Python Class:     Derived and extended configparser from Python standard library
#
# Description:
# ------------------------------------
#		- Improved interpolation algorithm
#		- Added an interpolation cache
#		- Added recursive interpolation (indirect addressing): ${key1.${key2:opt2}:opt1}
#		- Added %{keyword} interpolation, to access the section name: %{parent}
#		- Added support for multiple DEFAULT sections [CONFIG.DEFAULT] for all [CONFIG.**] sections
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
import re
from collections  import OrderedDict as _default_dict, ChainMap as _ChainMap
from configparser import ConfigParser, SectionProxy, Interpolation, MAX_INTERPOLATION_DEPTH, DEFAULTSECT, _UNSET, ConverterMapping
from configparser import NoSectionError, InterpolationDepthError, InterpolationSyntaxError, NoOptionError, InterpolationMissingOptionError

class ExtendedSectionProxy(SectionProxy):
	def __getitem__(self, key):
		if not self._parser.has_option(self._name, key):
			raise KeyError(self._name + ":" + key)
		return self._parser.get(self._name, key)

# Monkey patching ... (a.k.a. duck punshing
import configparser
configparser.SectionProxy = ExtendedSectionProxy


class ExtendedInterpolation(Interpolation):
	_KEYCRE = re.compile(r"\$\{(?P<ref>[^}]+)\}")
	_KEYCRE2 = re.compile(r"\$\[(?P<ref>[^\]]+)\}")

	def __init__(self):
		self._cache = dict()

	def clear_cache(self):
		self._cache = dict()

	def before_get(self, parser, section, option, value, defaults):
		# print("before_get: {0}:{1} = '{2}'".format(section, option, value))
		try:
			result = self.GetCached(section, option)
		except KeyError:
			result = self.interpolate(parser, section, option, value, defaults)
			self.UpdateCache(section, option, result)
		# print("before_get: => '{0}'\n".format(result))
		return result

	def before_set(self, parser, section, option, value):
		tmp_value = value.replace("$$", "") # escaped dollar signs
		tmp_value = self._KEYCRE.sub("", tmp_value) # valid syntax
		if '$' in tmp_value:
			raise ValueError("invalid interpolation syntax in {0!r} at position {1}".format(value, tmp_value.find("$")))
		return value

	def interpolate(self, parser, section, option, value, _, depth=0):
		if depth > MAX_INTERPOLATION_DEPTH:      raise InterpolationDepthError(option, section, value)

		# short cut operations if empty or a normal string
		if (value == ""):
			# print("interpol: SHORT -> empty string")
			return ""
		elif (("$" not in value) and ("%" not in value)):
			# print("interpol: SHORT -> {0}".format(value))
			return value

		# print("interpol: PREPARE section={0} option={1} value='{2}'".format(section, option, value))
		rawValue =    value
		rest = ""

		while (len(rawValue) > 0):
			beginPos = rawValue.find("%")
			if (beginPos < 0):
				rest += rawValue
				rawValue = ""
			else:
				rest += rawValue[:beginPos]
				if (rawValue[beginPos + 1] == "%"):
					rest += "%"
					rawValue = rawValue[1:]
				elif (rawValue[beginPos + 1] == "{"):
					endPos = rawValue.find("}", beginPos)
					if (endPos < 0):
						raise InterpolationSyntaxError(option, section, "bad interpolation variable reference {0!r}".format(rawValue))
					path =      rawValue[beginPos + 2:endPos]
					rawValue =  rawValue[endPos + 1:]
					rest +=      self.GetSpecial(section, option, path)

		# print("interpol: BEGIN   section={0} option={1} value='{2}'".format(section, option, rest))
		result =  ""
		while (len(rest) > 0):
			# print("interpol: LOOP    rest='{0}'".format(rest))
			beginPos = rest.find("$")
			if (beginPos < 0):
				result += rest
				rest =    ""
			else:
				result += rest[:beginPos]
				if (rest[beginPos + 1] == "$"):
					result +=  "$"
					rest =    rest[1:]
				elif (rest[beginPos + 1] == "{"):
					endPos =  rest.find("}", beginPos)
					nextPos =  rest.rfind("$", beginPos, endPos)
					if (endPos < 0):  raise InterpolationSyntaxError(option, section, "bad interpolation variable reference {0!r}".format(rest))
					if ((nextPos > 0) and (nextPos < endPos)):  # an embedded $-sign
						path = rest[nextPos+2:endPos]
						# print("interpol: path='{0}'".format(path))
						innervalue = self.GetValue(parser, section, option, path)
						# innervalue = self.interpolate(parser, section, option, path, map, depth + 1)
						# print("interpol: innervalue='{0}'".format(innervalue))
						rest = rest[beginPos:nextPos] + innervalue + rest[endPos + 1:]
						# print("interpol: new rest='{0}'".format(rest))
					else:
						path =    rest[beginPos+2:endPos]
						rest =    rest[endPos+1:]
						result +=  self.GetValue(parser, section, option, path)

					# print("interpol: LOOP END - result='{0}'".format(result))

		# print("interpol: RESULT => '{0}'".format(result))
		return result

	def GetSpecial(self, section, option, path):
		parts = section.split(".")
		if (path == "Root"):
			return parts[0]
		elif (path == "Parent"):
			return ".".join(parts[1:-1])
		elif (path == "ParentWithRoot"):
			return ".".join(parts[:-1])
		elif (path == "GrantParent"):
			return ".".join(parts[1:-2])
		elif (path == "Path"):
			return ".".join(parts[1:])
		elif (path == "PathWithRoot"):
			return section
		elif (path == "Name"):
			return parts[-1]
		else:
			raise InterpolationSyntaxError(option, section, "Unknown keyword '{0}'in special operator.".format(path))

	def GetValue(self, parser, section, option, path):
		path = path.split(":")
		if (len(path) == 1):
			sec = section
			opt = parser.optionxform(path[0])
		elif (len(path) == 2):
			sec = path[0]
			opt = parser.optionxform(path[1])
		else:
			raise InterpolationSyntaxError(option, section, "More than one ':' found.")

		try:
			return self.GetCached(sec, opt)
		except KeyError:
			pass

		try:
			value = parser.get(sec, opt, raw=True)
			# print("GetValue: successful parser access: '{0}'".format(value))
		except (KeyError, NoSectionError, NoOptionError) as ex:
			raise InterpolationMissingOptionError(option, section, "", ":".join(path)) from ex

		if (("$" in value) or ("%" in value)):
			value = self.interpolate(parser, sec, opt, value, {})

		self.UpdateCache(sec, opt, value)
		return value

	def GetCached(self, section, option):
		# print("GetCached: {0}:{1}".format(section, option))
		if (section not in self._cache):
			raise KeyError(section)
		sect = self._cache[section]
		if (option not in sect):
			raise KeyError("{0}:{1}".format(section, option))

		value = sect[option]
		# print("GetCached: found: {0}".format(value))
		return value

	def UpdateCache(self, section, option, value):
		# print("UpdateCache: {0}:{1} <- {2}".format(section, option, value))
		if (section in self._cache):
			sect = self._cache[section]
			if (option in sect):        raise Exception("This value is already cached.")
			sect[option] = value
		else:
			self._cache[section] = {option : value}


class ExtendedConfigParser(ConfigParser):
	_DEFAULT_INTERPOLATION = ExtendedInterpolation()

	def __init__(self, defaults=None, dict_type=_default_dict, allow_no_value=False, *, delimiters=('=', ':'), comment_prefixes=('#', ';'), inline_comment_prefixes=None,
								strict=True, empty_lines_in_values=True, default_section=DEFAULTSECT, interpolation=_UNSET, converters=_UNSET):
		# replacement of ConfigParser.__init__, do not call super-class constructor
		self._dict =      dict_type
		self._defaults =  dict_type()
		self._sections =  dict_type()
		self._proxies =    dict_type()
		self._cache =      dict()

		self._comment_prefixes =        tuple(comment_prefixes or ())
		self._inline_comment_prefixes =  tuple(inline_comment_prefixes or ())
		self._strict = strict
		self._allow_no_value = allow_no_value
		self._empty_lines_in_values = empty_lines_in_values
		self.default_section = default_section

		self._converters = ConverterMapping(self)
		if (converters is not _UNSET):
			self._converters.update(converters)

		self._proxies[default_section] = SectionProxy(self, default_section)

		if defaults:
			for key, value in defaults.items():
				self._defaults[self.optionxform(key)] = value

		self._delimiters = tuple(delimiters)
		if delimiters == ('=', ':'):
			self._optcre =                self.OPTCRE_NV if allow_no_value else self.OPTCRE
		else:
			d = "|".join(re.escape(d) for d in delimiters)
			if allow_no_value:            self._optcre = re.compile(self._OPT_NV_TMPL.format(delim=d), re.VERBOSE)
			else:                         self._optcre = re.compile(self._OPT_TMPL.format(delim=d), re.VERBOSE)

		if (interpolation is None):     self._interpolation = Interpolation()
		elif (interpolation is _UNSET): self._interpolation = ExtendedInterpolation()
		else:                           self._interpolation = interpolation

	@property
	def Interpolation(self):
		return self._interpolation

	def _unify_values(self, section, variables):
		"""Create a sequence of lookups with 'variables' taking priority over
		the 'section' which takes priority over the DEFAULTSECT.

		"""
		try:
			sectiondict = self._sections[section]
		except KeyError:
			if section != self.default_section:
				raise NoSectionError(section)
			else:
				sectiondict = {}

		# Update with the entry specific variables
		vardict = {}
		if variables:
			for key, value in variables.items():
				if value is not None:
					value = str(value)
				vardict[self.optionxform(key)] = value
		prefix = section.split(".",1)[0] + ".DEFAULT"
		# print("searched for {0}".format(prefix))
		try:
			defaultdict = self._sections[prefix]
			return _ChainMap(vardict, sectiondict, defaultdict, self._defaults)
		except KeyError:
			return _ChainMap(vardict, sectiondict, self._defaults)

	def has_option(self, section, option):
		"""Check for the existence of a given option in a given section.
		If the specified `section' is None or an empty string, DEFAULT is
		assumed. If the specified `section' does not exist, returns False."""
		option = self.optionxform(option)
		if ((not section) or (section == self.default_section)):
			sect = self._defaults
		else:
			prefix = section.split(".", 1)[0] + ".DEFAULT"
			if ((prefix in self) and (option in self._sections[prefix])):
				return True
			if (section not in self._sections):
				return False
			else:
				sect = self._sections[section]
		return option in sect
