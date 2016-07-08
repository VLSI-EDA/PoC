
sync_Strobe
###########

	This module synchronizes multiple high-active bits from clock-domain
	'Clock1' to clock-domain 'Clock2'. The clock-domain boundary crossing is
	done by a T-FF, two synchronizer D-FFs and a reconstructive XOR. A busy
	flag is additionally calculated and can be used to block new inputs. All
	bits are independent from each other. Multiple consecutive strobes are
	suppressed by a rising edge detection.
	ATTENTION:
		Use this synchronizer only for one-cycle high-active signals (strobes).
	CONSTRAINTS:
		General:
			This module uses sub modules which need to be constrained. Please
			attend to the notes of the instantiated sub modules.


.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/misc/sync/sync_Strobe.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 52-64

Source file: `misc/sync/sync_Strobe.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/misc/sync/sync_Strobe.vhdl>`_


 
