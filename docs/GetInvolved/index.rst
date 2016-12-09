
Get Involved
############

A first step might be to use and explore PoC and it's infrastructure in an own
project. Moreover, we encurage to read our online help which covers all aspects
from quickstart example up to detailed IP core documentation. While using PoC,
you might discover issues or missing feature. Please report them as
`listed below <#report-a-bug>`_. If you have an interresting project, please
send us feedback or get listed on our :doc:`Who uses PoC? </WhatIsPoC/WhoUsesPoC>`
page.

If you are more familiar with PoC and it's components, you might start asking
youself how components internally work. Please read our more advanced topics in
the online help, read our inline source code comments or start a discussion on
`Gitter <#talk-to-us-on-gitter>`_ to ask us directly.

Now you should be very familiar with our work and you might be interessted in
developing own components and contribute them to the main repository. See the
`next section <#contribute-to-poc>`_ for detailed instructions on the Git fork,
commit, push and pull-request flow.

PoC ships some :doc:`third-party libraries </Miscelaneous/ThirdParty>`. If you
are interessted in getting your library or components shipped as part of PoC or
as a third-party components, please contact us.


Report a Bug
************

.. image:: https://img.shields.io/github/issues/VLSI-EDA/PoC.svg
   :target: https://github.com/VLSI-EDA/PoC/issues
.. image:: https://img.shields.io/github/issues-closed/VLSI-EDA/PoC.svg
   :target: https://github.com/VLSI-EDA/PoC/issues

Please report issues of any kind in our Git provider's issue tracker. This allows
us to categorize issues into groups and assign developers to them. You can track
the issue's state and see how it's getting solved. All enhancements and feature
requests are tracked on GitHub at
`GitHub Issues <https://github.com/VLSI-EDA/PoC/issues>`_.


Feature Request
***************

Please report missing features of any kind. We are allways looking forward to
provide a full feature set. Please use our Git provider's issue tracker to report
enhancements and feature requests, so you can track the request's status and
implementation. All enhancements and feature requests are tracked on GitHub at
`GitHub Issues <https://github.com/VLSI-EDA/PoC/issues>`_.


Talk to us on Gitter
********************

.. image:: https://badges.gitter.im/VLSI-EDA/PoC.svg
   :target: https://gitter.im/VLSI-EDA/PoC

You can chat with us on `Gitter <https://gitter.im/>`_ in our Giiter Room
`VLSI-EDA/PoC <https://gitter.im/VLSI-EDA/PoC>`_. You can use Gitter for free
with your existing GitHub or Twitter account.


Contributers License Agreement
******************************

We require all contributers to sign a Contributor License Agreement (CLA). If
you don't know whatfore a CLA is needed and how it prevents legal issues on both
sides, read `this short blog <https://www.clahub.com/pages/why_cla>`_ post. PoC
uses the :doc:`Apache Contributor License Agreement </References/Licenses/ApacheLicense2.0_ICLA>`
to match the :doc:`Apache License 2.0 </References/Licenses/ApacheLicense2.0>`.

So to get started, `sign the Contributor License Agreement (CLA) <https://www.clahub.com/agreements/VLSI-EDA/PoC>`_
at `CLAHub.com <https://www.clahub.com/>`_. You can authenticate yourself with
an existing GitHub account.


Contribute to PoC
*****************

.. image:: https://img.shields.io/github/contributors/VLSI-EDA/PoC.svg

Contibuting source code via Git is very easy. We don't provide direct write
access to our repositories. Git offers the fork and pull-request philosophy,
which means: You clone a repository, provide your changes in your own repository
and notify us about outstanding changes via a pull-requests. We will then review
your proposed changes and integrate them into our repository.


*Steps 1 to 5 are done only once for setting up a forked repository.*

1. Fork the PoC Repository
==========================

.. image:: https://img.shields.io/github/forks/VLSI-EDA/PoC.svg
   :target: https://github.com/VLSI-EDA/PoC/network/members

Git repositories can be cloned on a Git provider's server. This procedure is
called *forking*. This allows Git providers to track the repository's network,
check if repositories are related to each other and notify if pull-requests are
available.

Fork our repository ``VLSI-EDA/PoC`` on GitHub into your or your's Git
organisation's account. In the following the forked repository is referenced as
``<username>/PoC``.

2. Clone the new Fork
=====================

Clone this new fork to your machine. See :ref:`Downloading via Git clone <USING:Download>`
for more details on how to clone PoC. If you have already cloned PoC, then you
can setup the new fork as an additional *remote*. You should set ``VLSI-EDA/PoC``
as fetch target and the new fork ``<username>/PoC`` as push target.

**Shell Commands for Cloning:**

.. code-block:: PowerShell

   cd GitRoot
   git clone --recursive "ssh://git@github.com:<username>/PoC.git" PoC
   cd PoC
   git remote rename origin github
   git remote add upstream "ssh://git@github.com:VLSI-EDA/PoC.git"
   git fetch --prune --tags

**Shell Commands for Editing an existing Clone:**

.. code-block:: PowerShell

   cd PoCRoot
   git remote rename github upstream
   git remote add github "ssh://git@github.com:<username>/PoC.git"
   git fetch --prune --tags

*These commands work for Git submodules too.*


3. Checkout a Branch
====================
Checkout the ``master`` or ``release`` branch and maybe stash outstanding changes.

.. code-block:: PowerShell

   cd PoCRoot
   git checkout release


4. Setup PoC for Developers
===========================
Run PoC's :ref:`configuration routines <USING:PoCConfig>` and setup the
developer tools.

.. code-block:: PowerShell

   cd PoCRoot
   .\PoC.ps1 configure git

5. Create your own ``master`` Branch
====================================
Each developer has his own ``master`` branch. So create one and check it out.

.. code-block:: PowerShell

   cd PoCRoot
   git branch <username>/master
   git checkout <username>/master
   git push github <username>/master

If PoC's branches are moving forward, you can update your own master branch by
merging changes into your branch.

6. Create your Feature Branch
=============================

Each new feature or bugfix is developed on a feature branch. Examples for
branch names:

+-----------------+--------------------------------------+
| Branch name     | Description                          |
+=================+======================================+
| bugfix-utils    | Fixes a bug in ``utils.vhdl``.       |
+-----------------+--------------------------------------+
| docs-spelling   | Fixes the documentation.             |
+-----------------+--------------------------------------+
| spi-controller  | A new SPI controller implementation. |
+-----------------+--------------------------------------+


.. code-block:: PowerShell

   cd PoCRoot
   git branch <username>/<feature>
   git checkout <username>/<feature>
   git push github <username>/<feature>

7. Commit and Push Changes
==========================

Commit your porposed changes onto your feature branch and push all changes to GitHub.

.. code-block:: PowerShell

   cd PoCRoot
   # git add ....
   git commit -m "Fixed a bug in function bounds() in utils.vhdl."
   git push github <username>/<feature>

8. Create a Pull-Request
========================

.. image:: https://img.shields.io/github/issues-pr/VLSI-EDA/PoC.svg
   :target: https://github.com/VLSI-EDA/PoC/pulls
.. image:: https://img.shields.io/github/issues-pr-closed/VLSI-EDA/PoC.svg
   :target: https://github.com/VLSI-EDA/PoC/pulls

Go to your forked repository and klick on "Compare and Pull-Request" or go to
our PoC repository and create a new `pull request <https://github.com/VLSI-EDA/PoC/pulls>`_.

If this is your first Pull-Request, you need to sign our Contributers License
Agreement (CLA).

9. Keep your ``master`` up-to-date
===================================

.. TODO:: undocumented


Give us Feedback
****************

Please send us feedback about the PoC documentation, our IP cores or your user
story on how you use PoC.


List of Contributers
********************

=========================  ============================================================
Contributor [#f1]_         Contact E-Mail
=========================  ============================================================
Genßler, Paul              paul.genssler@tu-dresden.de
Köhler, Steffen            steffen.koehler@tu-dresden.de
Lehmann, Patrick [#f2]_    patrick.lehmann@tu-dresden.de; paebbels@gmail.com
Preußer, Thomas B. [#f2]_  thomas.preusser@tu-dresden.de; thomas.preusser@utexas.edu
Reichel, Peter             peter.reichel@eas.iis.fraunhofer.de; peter@peterreichel.info
Schirok, Jan               janschirok@gmx.net
Voß, Jens                  jens.voss@mailbox.tu-dresden.de
Zabel, Martin [#f2]_       martin.zabel@tu-dresden.de
=========================  ============================================================

--------------------------------------------------------------------------------

.. rubric:: Footnotes

.. [#f1] In alphabetical order.
.. [#f2] Maintainer.
