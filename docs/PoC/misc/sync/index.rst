sync
====

The namespace ``PoC.misc.sync`` offers different clock-domain-crossing (CDC)
synchronizer circuits. All synchronizers are based on the basic 2 flip-flop
synchonizer called :doc:`sync_Bits </PoC/misc/sync/sync_Bits>`. PoC has two
platform specific implementations for Altera and Xilinx, which are choosen,
if the appropriate ``MY_DEVICE`` constant is configured in :doc:`my_config.vhdl </PoC/common/my_config_template>`.

**Decision Table:**

+----------+-------------------------------------------------+---------------------------------------------------+--------------------+-----------------------------------------------+-----------------------------------------------+
| Behavior | Flag [#f1]_                                     | Strobe [#f2]_                                     | Continuous Data    | Reset [#f4]_                                  | Pulse [#f3]_                                  |
+==========+=================================================+===================================================+====================+===============================================+===============================================+
|   1 Bit  | :doc:`sync_Bits </PoC/misc/sync/sync_Bits>`     | :doc:`sync_Strobe </PoC/misc/sync/sync_Strobe>`   | fifo_ic_got [#f5]_ | :doc:`sync_Reset </PoC/misc/sync/sync_Reset>` | :doc:`sync_Pulse </PoC/misc/sync/sync_Pulse>` |
+----------+-------------------------------------------------+---------------------------------------------------+--------------------+-----------------------------------------------+-----------------------------------------------+
|   n Bit  | :doc:`sync_Vector </PoC/misc/sync/sync_Vector>` | :doc:`sync_Command </PoC/misc/sync/sync_Command>` | fifo_ic_got [#f5]_ |                                               |                                               |
+----------+-------------------------------------------------+---------------------------------------------------+--------------------+-----------------------------------------------+-----------------------------------------------+

.. rubric:: Basic 2 Flip-Flop Synchronizer

The basic 2 flip-flop synchronizer is called :doc:`sync_Bits </PoC/misc/sync/sync_Bits>`. It's
possible to configure the bit count of indivital bits. If a vector shall be
synchronized, use one of the special synchronizers like `sync_Vector`. The
vendor specific implementations are named ``sync_Bits_Altera`` and
``sync_Bits_Xilinx`` respectivily.

A second variant of the 2-FF synchronizer is called :doc:`sync_Reset </PoC/misc/sync/sync_Reset>`.
It's for ``Reset``-signals, implementing asynchronous assertion and synchronous
deassertion. The vendor specific implementations are named ``sync_Reset_Altera``
and ``sync_Reset_Xilinx`` respectivily.

A third variant of a 2-FF synchronizer is called :doc:`sync_Pulse </PoC/misc/sync/sync_Pulse>`.
It's for very short ``Pulsed``-signals. It uses an addition asynchronous capture FF to latch the
very short pulse. The vendor specific implementations are named ``sync_Pulse_Altera`` and
``sync_Pulse_Xilinx`` respectivily.

.. rubric:: Special Synchronizers

Based on the 2-FF synchronizer, several "high-level" synchronizers are build.

* :doc:`sync_Strobe </PoC/misc/sync/sync_Strobe>` synchronizer ``strobe``-signals
  across clock-domain-boundaries. A busy signal indicates the synchronization
  status and can be used as a internal gate-signal to disallow new incoming
  strobes. A ``strobe``-signal is only for one clock period active.
* :doc:`sync_Command </PoC/misc/sync/sync_Command>` like ``sync_Strobe``, it synchronizes
  a one clock period active signal across the clock-domain-boundary, but the
  input has multiple bits. After the multi bit strobe (Command) was transfered,
  the output goes to its idle value.
* :doc:`sync_Vector </PoC/misc/sync/sync_Vector>` synchronizes a complete vector
  across the clock-domain-boundary. A changed detection on the input vector
  causes a register to latch the current state. The changed event is transfered
  to the new clock-domain and triggers a register to store the latched content,
  but in the new clock domain.

.. seealso::

   :doc:`PoC.fifo.ic_got </PoC/fifo/fifo_ic_got>`
      For a cross-clock capable FIFO.

.. rubric:: Footnotes

.. [#f1] A *flag* or *status* signal is a continuous, long time stable signal.
.. [#f2] A *strobe* signal is active for only one cycle.
.. [#f3] A *pulse* signal is a very short event.
.. [#f4] To be documented
.. [#f5] See the ``PoC.fifo`` namespace for cross-clock capable FIFOs.

.. toctree::
   :hidden:

   sync_Bits
   sync_Command
   sync_Pulse
   sync_Reset
   sync_Strobe
   sync_Vector
