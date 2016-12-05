#!/usr/bin/perl -w
# EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:               Thomas B. Preusser
#
# License:
# ==============================================================================
# Copyright 2007-2016 Technische Universitaet Dresden - Germany
#                     Chair of VLSI-Design, Diagnostics and Architecture
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ==============================================================================
#
# Provides implementations for 'smudge' and 'clean' filters for the sources
# within the PoC repo.
#
#  Synopsis:
#
#   # normalize (smudge|clean) [language] < input > output
#
#
# The basic filter implementations do:
#
#   clean  - remove trailing whitespace, and
#   smudge - replace empty lines with the most recent indentation.
#
#
# Currently, only the 'clean' pass expands extra processing steps for
# the following language specifiers:
#
#   vhdl - VHDL reserved words and standard types are put into lower case, and
#   rest - headline markers 7x'=' are expanded to 8x'=' so as to avoid
#          the misinterpretation as a conflict marker by git.
#
# ==============================================================================
use strict;
use feature 'state';

##############################################################################
# Filter Routines
#
#   Input:  string representing a source line
#   Output: filtered source line
#
#  The filters may maintain internal state to effect filtering.

# Trims trailing whitespace.
sub rtrim {
  $_[0] =~ s/\s*$//r;
}

# Adjusts empty lines (all whitespace) to comprise most recent indentation.
sub whiteindent {
  state $indent = '';
  my($line) = @_;
  return $indent unless $line =~ /^(\s*)\S/;
  $indent = $1;
  return $line;
}

# Lower-cases VHDL reserved words and standard types.
sub vhdlcap {
  state $reserved = join '|', qw/
    abs after alias all and architecture array assert attribute
    begin block body buffer bus
    case component configuration constant
    disconnect downto
    else elsif end entity exit
    file for function
    generate generic group guarded
    if impure in inertial inout is
    label library linkage literal loop
    map mod
    nand new next nor not null
    of on open or others out
    package port postponed procedure process pure
    range record register reject rem report return rol ror
    select severity signal shared sla sll sra srl subtype
    then to transport type
    unaffected units until use
    variable
    wait when while with
    xnor xor

    bit bit_vector boolean character integer natural positive signed
    std_logic std_logic_vector string time unsigned
  /;
  $_[0] =~ s/(--.*$|(['"\\]).*?\2|\b($reserved)\b)/$3? lc $3 : $1/gier;
}

# Fix headline markers in reST, which would coincide with git conflict markers.
sub restfix {
	$_[0] =~ s/(^={7}$)/=$1/r;
}

##############################################################################
# Main: Select Filters and apply them from stdin to stdout.

# Build Filter Chain
my $pass;
my @chain = ();

# open(my $fh, '>>', 'D:\git\PoC\temp\normalize.log');

if($pass = shift) {
	my $lang = @ARGV? lc(shift) : '';
	# print $fh "$lang";
	if($pass eq 'clean') {
		# print $fh " clean xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n";
		push @chain, \&rtrim;
		push @chain, \&vhdlcap if $lang eq 'vhdl';
		push @chain, \&restfix if $lang eq 'rest';
	}
	elsif($pass eq 'smudge') {
		push @chain, \&whiteindent;
	}
}

# Apply Filter Chain
while(<>) {
  chomp;
  my $line = $_;
  $line = $_->($line) for @chain;
  print "$line\n";
	# print $fh "$line\n";
}

# close $fh;
