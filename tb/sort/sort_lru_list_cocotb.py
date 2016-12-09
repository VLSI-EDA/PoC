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
from cocotb.result import TestFailure

from lru_dict import LeastRecentlyUsedDict

# ==============================================================================
class InputDriver(BusDriver):
	"""Drives inputs of DUT."""
	_signals = [ "Insert", "Remove", "DataIn" ]

	def __init__(self, dut):
		BusDriver.__init__(self, dut, None, dut.Clock)

class InputTransaction(object):
	"""Creates transaction to be send by InputDriver"""
	def __init__(self, insert, remove, datain):
		self.Insert = BinaryValue(insert, 1)
		self.Remove = BinaryValue(remove, 1)
		self.DataIn  = BinaryValue(datain, 8, False)

# ==============================================================================
class InputMonitor(BusMonitor):
	"""Observes inputs of DUT."""
	_signals = [ "Insert", "Remove", "DataIn" ]

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
	_signals = [ "Valid", "DataOut" ]

	def __init__(self, dut, callback=None, event=None):
		BusMonitor.__init__(self, dut, None, dut.Clock, dut.Reset, callback=callback, event=event)
		self.name = "out"

	@coroutine
	def _monitor_recv(self):
		clkedge = RisingEdge(self.clock)

		while True:
			# Capture signals at rising-edge of clock.
			yield clkedge
			vec = tuple([getattr(self.bus,i).value.integer for i in self._signals])
			self._recv(vec)

# ==============================================================================
class Testbench(object):
	class MyScoreboard(Scoreboard):
		def compare(self, got, exp, log, **_):
			"""Compare Valid before DataOut."""
			got_valid, got_elem = got
			exp_valid, exp_elem = exp

			if got_valid != exp_valid:
				self.errors += 1
				log.error("Received transaction differed from expected output.")
				log.warning("Expected: Valid=%d.\nReceived: Valid=%d." % (exp_valid, got_valid))
				if self._imm:
					raise TestFailure("Received transaction differed from expected transaction.")

			elif got_valid == 1:
				if got_elem != exp_elem:
					self.errors += 1
					log.error("Received transaction differed from expected output.")
					log.warning("Expected: Valid=%d, DataOut=%d.\n"
											"Received: Valid=%d, DataOut=%d." %
											(exp_valid, exp_elem, got_valid, got_elem))
					if self._imm:
						raise TestFailure("Received transaction differed from expected transaction.")


	def __init__(self, dut, init_val):
		self.dut = dut
		self.stopped = False
		elements = dut.ELEMENTS.value;
		self.lru = LeastRecentlyUsedDict(size_limit=elements)

		if elements != 16:
			raise TestFailure("Unsupported number of elements.")

		self.input_drv = InputDriver(dut)
		self.output_mon = OutputMonitor(dut)

		# Create a scoreboard on the outputs
		self.expected_output = [ init_val ]
		self.scoreboard = Testbench.MyScoreboard(dut)
		self.scoreboard.add_interface(self.output_mon, self.expected_output)

		# Reconstruct the input transactions from the pins
		# and send them to our 'model'
		self.input_mon = InputMonitor(dut, callback=self.model)

	def model(self, transaction):
		'''Model the DUT based on the input transaction.'''
		insert, remove, datain = transaction
		keyin = datain & 0x0f
		#print "=== model called with stopped=%r, Insert=%d, Remove=%d, KeyIn=%d, DataIn=%d" % (self.stopped, insert, remove, keyin, datain)
		if not self.stopped:
			if insert == 1:
				self.lru[keyin] = datain
			#elif free == 1:
			#	self.lru.moveLRU(keyin, datain)
			elif remove == 1:
				if keyin in self.lru: del self.lru[keyin]

			#print "=== model: lru=%s" % self.lru.items()
			if len(self.lru) < 1:
				#print "=== model: to few elements, yet."
				self.expected_output.append( (0, 0) )
			else:
				dataout = self.lru.itervalues().next()
				#print "=== model: LRU element=%d" % dataout
				self.expected_output.append( (1, dataout) )

	def stop(self):
		"""
		Stop generation of expected output transactions.
		One more clock cycle must be executed afterwards, so that, output of
		D-FF can be checked.
		"""
		self.stopped = True


# ==============================================================================
def random_input_gen(n=5000):
	"""
	Generate random input data to be applied by InputDriver.
	Returns up to n instances of InputTransaction.
	"""
	for _ in range(n):
		command, datain = random.randint(1,100), random.randint(0, 255)
		insert, remove = 0, 0
		# 80% insert, 10% remove, 10% idle
		if command > 20: insert = 1
		elif command > 10: remove = 1
		#print "=== random_input_gen: insert=%d, datain=%d" % (insert, free, datain)
		yield InputTransaction(insert, remove, datain)

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
	tb = Testbench(dut, (0, 0))
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
