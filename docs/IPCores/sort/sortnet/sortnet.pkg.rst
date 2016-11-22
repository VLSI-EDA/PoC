.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/sort/sortnet/sortnet.pkg.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      |gh-src| :pocsrc:`Sourcecode <sort/sortnet/sortnet.pkg.vhdl>`

.. _PKG:sortnet:

PoC.sort.sortnet Package
========================

.. code-block:: VHDL

   type T_SORTNET_IMPL is (
     SORT_SORTNET_IMPL_ODDEVEN_SORT,
     SORT_SORTNET_IMPL_ODDEVEN_MERGESORT,
     SORT_SORTNET_IMPL_BITONIC_SORT
   );

.. c:type:: T_SORTNET_IMPL

   SORT_SORTNET_IMPL_ODDEVEN_SORT
     Instantiate a :ref:`IP:sortnet_OddEvenSort` sorting network.

   SORT_SORTNET_IMPL_ODDEVEN_MERGESORT
     Instantiate a :ref:`IP:sortnet_OddEvenMergeSort` sorting network.

   SORT_SORTNET_IMPL_BITONIC_SORT
     Instantiate a :ref:`IP:sortnet_BitonicSort` sorting network.


.. only:: latex

   Source file: :pocsrc:`sortnet.pkg.vhdl <sort/sortnet/sortnet.pkg.vhdl>`
