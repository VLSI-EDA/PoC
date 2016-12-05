# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:            Martin Zabel
#
# Cocotb Testbench:   Cache with parallel access to tags and data.
#
# Description:
# ------------------------------------
#	Automated testbench for PoC.cache_par
#
# Supported configuration:
# * REPLACEMENT_POLICY = "LRU"
#
# License:
# ==============================================================================
# Copyright 2016-2016 Technische Universitaet Dresden - Germany
#											Chair of VLSI-Design, Diagnostics and Architecture
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

#import traceback
import random

import cocotb
from cocotb.decorators import coroutine
from cocotb.triggers import Timer, RisingEdge
from cocotb.monitors import BusMonitor
from cocotb.drivers import BusDriver
from cocotb.binary import BinaryValue
from cocotb.regression import TestFactory
from cocotb.scoreboard import Scoreboard
from cocotb.result import TestFailure

from lru_dict import LeastRecentlyUsedDict
from utils import log2ceil

# debug level
DEBUG=0

# ==============================================================================
class InputDriver(BusDriver):
	"""Drives inputs of DUT."""
	_signals = [ "Request", "ReadWrite", "Invalidate", "Replace", "Address", "CacheLineIn" ]

	def __init__(self, dut):
		BusDriver.__init__(self, dut, None, dut.Clock)


class InputTransaction(object):
	"""Transaction to be send by InputDriver"""
	def __init__(self, tb, request=0, readWrite=0, invalidate=0, replace=0, address=0, cacheLineIn=0):
		"tb must be an instance of the Testbench class"
		if (replace==1) and ((request==1) or (invalidate==1)):
			raise ValueError("InputTransaction.__init__ called with request=%d, invalidate=%d, replace=%d"
											 % request, invalidate, replace)

		self.Replace = BinaryValue(replace, 1)
		self.Request = BinaryValue(request, 1)
		self.ReadWrite = BinaryValue(readWrite, 1)
		self.Invalidate = BinaryValue(invalidate, 1)
		self.Address = BinaryValue(address, tb.address_bits, False)
		self.CacheLineIn = BinaryValue(cacheLineIn, tb.data_bits, False)


class OutputTransaction(object):
	"""Transaction to be expected / received by OutputMonitor."""
	def __init__(self, tb=None, cacheLineOut=None, cacheHit=0, cacheMiss=0, oldAddress=None):
		"""For expected transactions, value 'None' means don't care. tb must be an instance of the Testbench class."""
		if cacheLineOut is not None and isinstance(cacheLineOut, int): cacheLineOut = BinaryValue(cacheLineOut, tb.data_bits, False)
		if cacheHit     is not None and isinstance(cacheHit, int):     cacheHit = BinaryValue(cacheHit, 1)
		if cacheMiss    is not None and isinstance(cacheMiss, int):    cacheMiss = BinaryValue(cacheMiss, 1)
		if oldAddress   is not None and isinstance(oldAddress, int):   oldAddress = BinaryValue(oldAddress, tb.address_bits, False)
		self.value = (cacheLineOut, cacheHit, cacheMiss, oldAddress)

	def __eq__(self, other):
		if not isinstance(other, OutputTransaction):
			raise ValueError("Other value in comparison is not an OutputTransaction, was {0!s} instead.".format(type(other)))

		equal = True
		for i, val1 in enumerate(self.value):
			val2 = other.value[i]
			if val1 is not None and val2 is not None:
				if val1 != val2: equal = False
		return equal

	def __ne__(self, other):
		return not self.__eq__(other)

	def __str__(self):
		return ", ".join([str(i) for i in self.value])

# ==============================================================================
class InputMonitor(BusMonitor):
	"""Observes inputs of DUT."""
	_signals = [ "Request", "ReadWrite", "Invalidate", "Replace", "Address", "CacheLineIn" ]

	def __init__(self, dut, callback=None, event=None):
		BusMonitor.__init__(self, dut, None, dut.Clock, dut.Reset, callback=callback, event=event)
		self.name = "in"

	@coroutine
	def _monitor_recv(self):
		clkedge = RisingEdge(self.clock)

		while True:
			# Capture signals at rising-edge of clock.
			yield clkedge
			vec = (self.bus.Request.value.integer,
						 self.bus.ReadWrite.value.integer,
						 self.bus.Invalidate.value.integer,
						 self.bus.Replace.value.integer,
						 self.bus.Address.value.integer,
						 self.bus.CacheLineIn.value.integer)
			self._recv(vec)

# ==============================================================================
class OutputMonitor(BusMonitor):
	"""Observes outputs of DUT."""
	_signals = [ "CacheLineOut", "CacheHit", "CacheMiss", "OldAddress" ]

	def __init__(self, dut, tb, callback=None, event=None):
		"""tb must be an instance of the Testbench class."""
		BusMonitor.__init__(self, dut, None, dut.Clock, dut.Reset, callback=callback, event=event)
		self.name = "out"
		self.tb = tb

	@coroutine
	def _monitor_recv(self):
		clkedge = RisingEdge(self.clock)

		while True:
			# Capture signals at rising-edge of clock.
			yield clkedge

			self._recv(OutputTransaction(self.tb, self.bus.CacheLineOut.value, self.bus.CacheHit.value,
																		self.bus.CacheMiss.value,	self.bus.OldAddress.value))

# ==============================================================================
class Testbench(object):
	class MyScoreboard(Scoreboard):
		def compare(self, got, exp, log, **_):
			if got != exp:
				self.errors += 1
				log.error("Received transaction differed from expected output.")
				log.warning("Expected: {0!s}.\nReceived: {1!s}.".format(exp, got))
				if self._imm:
					raise TestFailure("Received transaction differed from expected transaction.")


	def __init__(self, dut):
		self.dut = dut
		self.stopped = False
		self.address_bits = dut.ADDRESS_BITS.value
		self.data_bits = dut.DATA_BITS.value

		cache_lines = dut.CACHE_LINES.value      # total number of cache lines
		self.associativity = dut.ASSOCIATIVITY.value
		self.cache_sets = cache_lines / self.associativity # number of cache sets

		self.index_bits = log2ceil(self.cache_sets)
		tag_bits = self.address_bits - self.index_bits

		self.index_mask = 2**self.index_bits-1
		self.tag_mask = 2**tag_bits-1

		if DEBUG: print("Testbench: {0}, {1}, {2}".format(self.index_bits, self.index_mask, self.tag_mask))

		replacement_policy = dut.REPLACEMENT_POLICY.value
		if replacement_policy != "LRU":
			raise TestFailure("Unsupported configuration: REPLACEMENT_POLICY=%s" % replacement_policy)

		# TODO: create LRU dictionary for each cache set
		self.lrus = tuple([LeastRecentlyUsedDict(size_limit=self.associativity) for _ in range(self.cache_sets)])

		init_val = OutputTransaction(self)

		self.input_drv = InputDriver(dut)
		self.output_mon = OutputMonitor(dut, self)

		# Create a scoreboard on the outputs
		self.expected_output = [ init_val ]
		self.scoreboard = Testbench.MyScoreboard(dut)
		self.scoreboard.add_interface(self.output_mon, self.expected_output)

		# Reconstruct the input transactions from the pins
		# and send them to our 'model'
		self.input_mon = InputMonitor(dut, callback=self.model)

	def model(self, transaction):
		'''Model the DUT based on the input transaction.'''
		request, readWrite, invalidate, replace, address, cacheLineIn = transaction
		if DEBUG >= 1: print("=== model called with stopped={0!r}, Request={1}, ReadWrite={2}, Invalidate={3}, Replace={4}, Address={5}, CacheLineIn={6}".
												 format(self.stopped, request, readWrite, invalidate, replace, address, cacheLineIn))

		index = address & self.index_mask
		#tag = (address >> self.index_bits) & self.tag_mask

		# expected outputs, None means ignore
		cacheLineOut, cacheHit, cacheMiss, oldAddress = None, 0, 0, None
		if not self.stopped:
			if request == 1:
				if address in self.lrus[index]:
					cacheHit = 1
					if readWrite == 1:
						self.lrus[index][address] = cacheLineIn
					else:
						cacheLineOut = self.lrus[index][address]
						self.lrus[index][address] = cacheLineOut # move to recently-used position

					if invalidate == 1:
						del self.lrus[index][address]

				else:
					cacheMiss = 1

			elif replace == 1:
				# check if a valid cache line will be replaced
				if len(self.lrus[index]) == self.associativity:
					oldAddress, cacheLineOut = self.lrus[index].iteritems().next()

				# actual replace
				self.lrus[index][address] = cacheLineIn

			if DEBUG >= 1: print("=== model: lrus[{0}] = {1!s}".format(index, self.lrus[index].items()))
			# convert all not None values to BinaryValue
			self.expected_output.append( OutputTransaction(self, cacheLineOut, cacheHit, cacheMiss, oldAddress) )

	def stop(self):
		"""
		Stop generation of expected output transactions.
		One more clock cycle must be executed afterwards, so that, output of
		D-FF can be checked.
		"""
		self.stopped = True


# ==============================================================================
def random_input_gen(tb,n=100000):
	"""
	Generate random input data to be applied by InputDriver.
	Returns up to n instances of InputTransaction.
	tb must an instance of the Testbench class.
	"""
	address_high  = 2**tb.address_bits-1
	data_high = 2**tb.data_bits-1

	# it is forbidden to replace a cache line when the new address is already within the cache
	# we cannot directly access the content of the LRU list in the testbench because this function is called asynchronously
	lru_tags = tuple([LeastRecentlyUsedDict(size_limit=tb.associativity) for _ in range(tb.cache_sets)])

	for i in range(n):
		if DEBUG and (i % 1000 == 0): print("Generating transaction #{0} ...".format(i))

		command = random.randint(1,60)
		request, readWrite, invalidate, replace = 0, 0, 0, 0
		# 10% for each possible command
		if   command > 50: request = 1; readWrite = 0; invalidate = 0
		elif command > 40: request = 1; readWrite = 1; invalidate = 0
		elif command > 30: request = 1; readWrite = 0; invalidate = 1
		elif command > 20: request = 1; readWrite = 1; invalidate = 1
		elif command > 10: replace = 1

		# Upon request, check if address is in LRU list.
		while True:
			address = random.randint(0,address_high)
			index = address & tb.index_mask
			tag = (address >> tb.index_bits) &  tb.tag_mask
			#print "while loop: %d, %d, %d" % (address, index, tag)
			if (replace == 0) or (tag not in lru_tags[index]): break

		# Update LRU list
		if request == 1:
			if tag in lru_tags[index]:
				if invalidate == 1:
					del lru_tags[index][tag] # free cache line
				else:
					lru_tags[index][tag] = 1 # tag access
		elif replace == 1:
			lru_tags[index][tag] = 1 # allocate cache line

		if DEBUG >= 2: print("=== random_input_gen: request={0}, readWrite={1}, invalidate={2}, replace={3}, address={4}".format(request, readWrite, invalidate, replace, address))
		if DEBUG >= 2: print("=== random_input_gen: lru_tags[{0}]={1!s}".format(index, lru_tags[index].items()))

		yield InputTransaction(tb, request, readWrite, invalidate, replace, address, random.randint(0,data_high))

@cocotb.coroutine
def clock_gen(signal):
	while True:
		signal <= 0
		yield Timer(5000) # ps
		signal <= 1
		yield Timer(5000) # ps

@cocotb.coroutine
def run_test(dut):
	cocotb.fork(clock_gen(dut.Clock))
	tb = Testbench(dut)
	dut.Reset <= 0

	input_gen = random_input_gen(tb)

	# Issue first transaction immediately.
	yield tb.input_drv.send(input_gen.next(), False)

	# Issue next transactions.
	for t in input_gen:
		yield tb.input_drv.send(t)

	# Wait for rising-edge of clock to execute last transaction from above.
	# Apply idle command in following clock cycle, but stop generation of expected output data.
	# Finish clock cycle to capture the resulting output from the last transaction above.
	yield tb.input_drv.send(InputTransaction(tb))
	tb.stop()
	yield RisingEdge(dut.Clock)

	# Print result of scoreboard.
	raise tb.scoreboard.result

factory = TestFactory(run_test)
factory.generate_tests()
