.. _INT:PoC.Mem:

PoC.Mem Interface
#################

PoC.Mem is a single-cycle, pipelined memory interface used by various
memory controllers and related components like caches. Memory accesses
are always word aligned, and during writes a mask defines which bytes
are actually written to the memory (if supported by the memory
controller).


Configuration
*************

Each entity may have an individual configuration, especially if it has
two PoC.Mem interfaces or if it adapts between PoC.Mem and another
interface.

The typical configuration parameters are:

+--------------------+------------------------------------------------+
| Parameter          | Description                                    |
+====================+================================================+
| ADDR_BITS or       | Number of address bits. Each address identifies|
| A_BITS             | exactly one memory word.                       |
+--------------------+------------------------------------------------+
| DATA_BITS or       | Size of a memory word in bits. DATA_BITS must  |
| D_BITS             | be divisible by 8.                             |
+--------------------+------------------------------------------------+

A memory word consists of DATA_BITS/8 bytes.

Individual bytes are only addressed during writes by the write
mask. The write mask has one mask-bit for each byte in a memory word.

For example, a 1 KiByte memory with a 32-bit datapath has the
following configuration:

* 4 bytes per memory word,
* ADDR_BITS=8 because :math:`\log_2(1\,\mbox{KiByte} / 4\,\mbox{bytes}) = 8`, and
* DATA_BITS=32 which is the datapath size in bits.


Interface signals
*****************

The following signal names are typically prefixed in the port list of
a concrete entity to separate the PoC.Mem interface from other
interfaces of the entity. Moreover, clock and reset may be shared
with other interfaces of the entity.

The PoC.Mem interface consists of the following signals:

+--------------------+------------------------------------------------+
| Signal             | Description                                    |
+====================+================================================+
| clk                | The clock. All other signals are synchronous   |
|                    | to the rising edge of this clock.              |
+--------------------+------------------------------------------------+
| rst                | High-active synchronous reset.                 |
+--------------------+------------------------------------------------+
| rdy                | High-active ready for request.                 |
+--------------------+------------------------------------------------+
| req                | High-active request.                           |
+--------------------+------------------------------------------------+
| write              | '1' if write request, '0' if read request      |
+--------------------+------------------------------------------------+
| addr               | The (word) address.                            |
+--------------------+------------------------------------------------+
| wdata              | The data to be written to the memory.          |
+--------------------+------------------------------------------------+
| wmask              | Write-mask, for each byte: '0' = write byte,   |
| (optional)         | '1' = mask byte from write. Signal/port is     |
|                    | omitted if write mask is not supported.        |
+--------------------+------------------------------------------------+
| rstb               | High-active read-strobe.                       |
+--------------------+------------------------------------------------+
| rdata              | The read-data returned from the memory.        |
+--------------------+------------------------------------------------+

The interface is actually splitted into two parts:

* the request part: signals ``rdy``, ``req``, ``write``, ``addr``,
  ``wdata`` and ``wmask``, and

* the read-reply part: signals ``rstb`` and ``rdata``.


Operation
*********

The request and the read-reply part operate indepent of each other to
support pipelined reading from memory. The pipeline depth is defined
by the actual memory controller. If a user application does support
only a specific number of outstanding reads, then the application must
limit the number of issued reads on its own.


Requests
++++++++

If ``req`` is low, then no request is issued to the memory in the current
clock cycle. The state of the signals ``write``, ``addr``, ``wdata``
and ``wmask`` doesn't care.

If ``req`` is high, then a request is issued to the memory in the current
clock cycle as given by ``write``, ``addr``, ``wdata`` and
``wmask``. The request will be accepted by the memory, if ``rdy`` is
high in the same clock cycle, otherwise the request will be ignored.
``wdata`` and ``wmask`` doesn't care if a read request is issued.

``rdy`` does not depend on ``req`` in the current clock cycle. ``rdy``
may go low in the following clock cycle after a request has been
issued or a synchronous reset has been applied.


Read Replies
++++++++++++

If ``rstb`` is high in the current clock cycle, then ``rdata``
delivers the requested read data (read reply). Otherwise, if ``rstb``
is low, then ``rdata`` is unknown. The user application has to
immediatly handle the incoming read data, because it cannot
signal ready or acknowledge.

After issuing a read request, the memory responds with a read reply in
the following clock cycle (i.e. synchronous read) or any later clock
cycle depending on the pipeline depth. For each read request, a read
reply is generated. Read requests are not reordered.
