
arith_scaler
############

A flexible scaler for fixed-point values. The scaler is implemented for a set
of multiplier and divider values. Each individual scaling operation can
arbitrarily select one value from each these sets.

The computation calculates: ``unsigned(arg) * MULS(msel) / DIVS(dsel)``
rounded to the nearest (tie upwards) fixed-point result of the same precision
as ``arg``.

The computation is started by asserting ``start`` to high for one cycle. If a
computation is running, it will be restarted. The completion of a calculation
is signaled via ``done``. ``done`` is high when no computation is in progress.
The result of the last scaling operation is stable and can be read from
``res``. The weight of the LSB of ``res`` is the same as the LSB of ``arg``.
Make sure to tap a sufficient number of result bits in accordance to the
highest scaling ratio to be used in order to avoid a truncation overflow.


.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/arith/arith_scaler.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 52-69


	 