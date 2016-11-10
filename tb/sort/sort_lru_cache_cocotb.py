# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
#
# ==============================================================================
# Authors:				 		Martin Zabel
#
# Cocotb Testbench:		Least-Recently Used Sort Algorithm
#
# Description:
# ------------------------------------
#	Automated testbench for PoC.sort_LeastRecentlyUsed
#
# License:
# ==============================================================================
# Copyright 2007-2016 Technische Universitaet Dresden - Germany
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

from lru_dict import LeastRecentlyUsedDict

# ==============================================================================
class InputDriver(BusDriver):
	"""Drives inputs of DUT."""
	_signals = [ "Insert", "Free", "KeyIn" ]

	def __init__(self, dut):
		BusDriver.__init__(self, dut, None, dut.Clock)

class InputTransaction(object):
	"""Creates transaction to be send by InputDriver"""
	def __init__(self, insert, invalidate, keyin):
		self.Insert = BinaryValue(insert, 1)
		self.Free = BinaryValue(invalidate, 1)
		self.KeyIn = BinaryValue(keyin, 5, False)

# ==============================================================================
class InputMonitor(BusMonitor):
	"""Observes inputs of DUT."""
	_signals = [ "Insert", "Free", "KeyIn" ]

	def __init__(self, dut, callback=None, event=None):
		BusMonitor.__init__(self, dut, None, dut.Clock, dut.Reset, callback=callback, event=event)
		self.name = "in"

	@coroutine
	def _monitor_recv(self):
		clkedge = RisingEdge(self.clock)

		while True:
			# Capture signals at rising-edge of clock.
			yield clkedge
			vec = tuple([getattr(self.bus,i).value.integer for i in self._signals])
			self._recv(vec)

# ==============================================================================
class OutputMonitor(BusMonitor):
	"""Observes outputs of DUT."""
	_signals = [ "KeyOut" ]

	def __init__(self, dut, callback=None, event=None):
		BusMonitor.__init__(self, dut, None, dut.Clock, dut.Reset, callback=callback, event=event)
		self.name = "out"

	@coroutine
	def _monitor_recv(self):
		clkedge = RisingEdge(self.clock)

		while True:
			# Capture signals at rising-edge of clock.
			yield clkedge
			vec = self.bus.KeyOut.value.integer
			self._recv(vec)

# ==============================================================================
class Testbench(object):
	def __init__(self, dut):
		self.dut = dut
		self.stopped = False
		elements = dut.ELEMENTS.value;
		self.lru = LeastRecentlyUsedDict(size_limit=elements)

		# initial state of LRU list
		for keyin in range(elements-1, -1, -1):
			self.lru[keyin] = 1

		init_val = elements-1

		self.input_drv = InputDriver(dut)
		self.output_mon = OutputMonitor(dut)

		# Create a scoreboard on the outputs
		self.expected_output = [ init_val ]
		self.scoreboard = Scoreboard(dut)
		self.scoreboard.add_interface(self.output_mon, self.expected_output)

		# Reconstruct the input transactions from the pins
		# and send them to our 'model'
		self.input_mon = InputMonitor(dut, callback=self.model)

	def model(self, transaction):
		'''Model the DUT based on the input transaction.'''
		insert, free, keyin = transaction
		#print "=== model called with stopped=%r, Insert=%d, Free=%d, KeyIn=%d" % (self.stopped, insert, free, keyin)
		if not self.stopped:
			if insert == 1:
				self.lru[keyin] = 1
			elif free == 1:
				self.lru.moveLRU(keyin)

			#print "=== model: lru=%s" % self.lru.items()
			keyout = self.lru.iterkeys().next()
			#print "=== model: KeyOut=%d" % keyout
			self.expected_output.append(keyout)

	def stop(self):
		"""
		Stop generation of expected output transactions.
		One more clock cycle must be executed afterwards, so that, output of
		D-FF can be checked.
		"""
		self.stopped = True


# ==============================================================================
def random_input_gen(n=2000):
	"""
	Generate random input data to be applied by InputDriver.
	Returns up to n instances of InputTransaction.
	"""
	for _ in range(n):
		command = random.randint(1,100)
		insert, free = 0, 0
		# 89% insert, 1% free, 10% idle
		if command > 11: insert = 1
		elif command > 10: free = 1
		#print "=== random_input_gen: command=%d, insert=%d, free=%d" % (command, insert, free)
		yield InputTransaction(insert, free, random.randint(0, 31))

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

	input_gen = random_input_gen()

	# Issue first transaction immediately.
	yield tb.input_drv.send(input_gen.next(), False)

	# Issue next transactions.
	for t in input_gen:
		yield tb.input_drv.send(t)

	# Wait for rising-edge of clock to execute last transaction from above.
	# Apply idle command in following clock cycle, but stop generation of expected output data.
	# Finish clock cycle to capture the resulting output from the last transaction above.
	yield tb.input_drv.send(InputTransaction(0, 0, 0))
	tb.stop()
	yield RisingEdge(dut.Clock)

	# Print result of scoreboard.
	raise tb.scoreboard.result

factory = TestFactory(run_test)
factory.generate_tests()
