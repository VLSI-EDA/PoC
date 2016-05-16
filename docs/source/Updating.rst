Updating PoC
********************************************************************************

**The PoC-Library** can be updated by using ``git fetch``::

    cd <GitRoot>\PoC
    git fetch
    # review the commit tree and messages, using the 'treea' alias
    git tree --all
    # if all changes are OK, do a fast-forward merge
    git merge
