.. include:: shields.inc

.. raw:: latex

   \part{Introduction}

This library is published and maintained by **Chair for VLSI Design, Diagnostics
and Architecture** - Faculty of Computer Science, Technische Universität Dresden,
Germany |br|
`https://tu-dresden.de/ing/informatik/ti/vlsi <https://tu-dresden.de/ing/informatik/ti/vlsi>`_

.. only:: html

   .. image:: /_static/logos/tu-dresden.jpg
      :scale: 10
      :alt: Technische Universität Dresden

.. only:: latex

   .. image:: /_static/logos/tu-dresden.jpg
      :scale: 80
      :alt: Technische Universität Dresden

--------------------------------------------------------------------------------

.. only:: html

   |SHIELD:svg:GH-Logo|
   |SHIELD:svg:Travis-CI|
   |SHIELD:svg:AppVeyor|
   |SHIELD:svg:Landscape|
   |SHIELD:svg:Requirements|
   |br|
   |SHIELD:svg:Gitter:PoC|
   |SHIELD:svg:Gitter:News|
   |br|
   |SHIELD:svg:GH-Tag|
   |SHIELD:svg:GH-Release|
   |SHIELD:svg:License-Code|
   |SHIELD:svg:License-Docs|
   |hr|

.. only:: latex

   .. image:: https://img.shields.io/badge/-VLSI--EDA/PoC-323131.png?style=flat&logo=data%3Aimage%2Fpng%3Bbase64%2CiVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAMAAABEpIrGAAABKVBMVEX%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FOe9X6AAAAYnRSTlMAAQIDBAcIDA0PEBESFBUWGBkeHyEoMTIzNDU4OTw%2BP0JGWVxeX2BiY2RlZ2hvc3R1eHp%2Bio%2BXm52epKmqq62usLe5wcLDxMnQ0dLW2tvc3t%2Fh4uPo6uvs8fLz9fb3%2Bvv8%2FsuNaVkAAAF7SURBVHgBjdHZW9NAFAXwE0iElCARZCkuIotEUFyQBSJERBEILaAo6d6e%2F%2F%2BPcO58aZslD%2Fxe5mHuPfOdbzA06R1e1sn65aE3ibw5v8OBjj%2BHNHuvx5Tenp1av2bOdSJkKWKBaAmxhYiFogVoEzckw%2BModXcckryZgDigsgLLu1MVT09V1TvPwgqVAyhlinmpMjsCZWRWCsxTlAEEFIvIWKQIALdLsYaMNYqui02KPw4ynN8Um%2FAp1pGzTuEj1Ek2cmz9dogmlVsUuKXSBEUFBaoUoKihQI0iPqaQMxWvnlOsImeV4hz7FBcmMswLin0sU9tBxg61ZYw3qB25SHhyRK0xDuySX179INtfN8qjOvz5u6BNjbsAplvsbVm%2FqAQGFOMb%2B1rTULZJPnsqf%2FMC2kv2bUOYZ%2BR3lLzPr0ehPWbszITmVsn3GCqRWtVFbKZC%2Fvz45tOj1EBlBgPOCUUpOXDiIMF4%2Bzc98G%2FDQNrY1tW9Bc26v%2Fowhof6D6AkqSgsdGGuAAAAAElFTkSuQmCC
      :target: https://www.github.com/VLSI-EDA/PoC
      :alt: Source Code on GitHub

.. #
   |SHIELD:png:GH-Logo|
   |SHIELD:png:Travis-CI|
   |SHIELD:png:AppVeyor|
   |SHIELD:png:Landscape|
   |SHIELD:png:Requirements|
   |br|
   |SHIELD:png:Gitter:PoC|
   |SHIELD:png:Gitter:News|
   |br|
   |SHIELD:png:GH-Tag|
   |SHIELD:png:GH-Release|
   |SHIELD:png:License-Code|
   |SHIELD:png:License-Docs|

The PoC-Library Documentation
#############################

PoC - "Pile of Cores" provides implementations for often required hardware
functions such as Arithmetic Units, Caches, Clock-Domain-Crossing Circuits,
FIFOs, RAM wrappers, and I/O Controllers. The hardware modules are typically
provided as VHDL or Verilog source code, so it can be easily re-used in a
variety of hardware designs.

All hardware modules use a common set of VHDL packages to share new VHDL types,
sub-programs and constants. Additionally, a set of simulation helper packages
eases the writing of testbenches. Because PoC hosts a huge amount of IP cores,
all cores are grouped into sub-namespaces to build a better hierachy.

Various simulation and synthesis tool chains are supported to interoperate with
PoC. To generalize all supported free and commercial vendor tool chains, PoC is
shipped with a Python based infrastructure to offer a command line based frontend.


.. only:: html

   News
   ****

.. only:: latex

   .. rubric:: News

See :ref:`Change Log <CHANGE>` for latest updates.


.. only:: html

   Cite the PoC-Library
   ********************

.. only:: latex

   .. rubric:: Cite the PoC-Library

The PoC-Library hosted at `GitHub.com <https://www.github.com>`_. Please use the
following `biblatex <https://www.ctan.org/pkg/biblatex>`_ entry to cite us:

.. code-block:: tex

   # BibLaTex example entry
   @online{poc,
     title={{PoC - Pile of Cores}},
     author={{Chair of VLSI Design, Diagnostics and Architecture}},
     organization={{Technische Universität Dresden}},
     year={2016},
     url={https://github.com/VLSI-EDA/PoC},
     urldate={2016-10-28},
   }

------------------------------------

.. |docdate| date:: %b %d, %Y - %H:%M

.. only:: html

   This document was generated on |docdate|.


.. toctree::
   :caption: Introduction
   :hidden:

   WhatIsPoC/index
   QuickStart
   GetInvolved/index
   References/Licenses/License

.. raw:: latex

   \part{Main Documentation}

.. toctree::
   :caption: Main Documentation
   :hidden:

   UsingPoC/index
   Interfaces/index
   IPCores/index
   Miscelaneous/ThirdParty
   ConstraintFiles/index
   ToolChains/index
   Examples/index

.. raw:: latex

   \part{References}

.. toctree::
   :caption: References
   :hidden:

   References/CommandReference
   References/Database
   PyInfrastructure/index
   More ... <References/more>

.. raw:: latex

   \part{Appendix}

.. toctree::
   :caption: Appendix
   :hidden:

   ChangeLog/index
   genindex

.. ifconfig:: visibility in ('PoCInternal')

   .. raw:: latex

      \part{Main Internal}

   .. toctree::
      :caption: Internal
      :hidden:

      Internal/ToDo
      Internal/Sphinx
