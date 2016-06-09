
Using PoC
#########

PoC can be used in several ways:

* Stand-Alone IP Core Library:
    Download PoC as archive file (\*.zip) from GitHub as latest branch copy or
    as tagged release file. IP cores can be copyed into one or more destination
    projects or the projects link to the selected IP core source files.
    
    Advantages:
    
    * Simple and fast setup, configuring PoC is optional.
    * Needs less disk space than a Git repository.
    * After a configuration, PoC's additional features: simulation, synthesis,
      etc. can be used.
    
    Disadvantages:
    
    * Manual updating via download and file overwrites.
    * Updated IP cores need to be copyed again into the destination project.
    * Using different PoC versions in different projects is not possible.
    * No possibility to contribute bugfixes and extensions via Git pull requests.
    
* Stand-Alone IP Core Library cloned from Git:
    Download PoC via ``git clone`` from GitHub as latest branch copy. IP cores
    can be copyed into one or more destination projects or the projects link to
    the selected IP core source files.
    
    Advantages:
    
    * Simple and fast setup, configuring PoC is optional.
    * Access to the newest commits on a branch: New IP cores, new features, bugfixes.
    * Fast and simple updates via ``git pull``.
    * After a configuration, PoC's additional features: simulation, synthesis,
      etc. can be used.
    * Contribute bugfixes and extensions via Git pull requests.
			
    Disadvantages:
    
    * Updated IP cores need to be copyed again into the destination project.
    * Using different PoC versions in different projects is not possible

* Embedded IP Core Library as Git Submodule:
    Integrate PoC as a Git submodule into the destination projects Git repository.
    
    Advantages:
    
    * Simple and fast setup, configuring PoC is optional, but recommended.
    * Access to the newest commits on a branch: New IP cores, new features, bugfixes.
    * Fast and simple updates via ``git pull``.
    * After a configuration, PoC's additional features: simulation, synthesis,
      etc. can be used.
    * Moreover, some PoC infrastructure features can be used in the hosting
      repository and project as well.
    * Contribute bugfixes and extensions via Git pull requests.
    * Version linking between hosting Git and PoC.
			

.. toctree::
   :hidden:
   
   AddingIPCores
   Simulation
   Synthesis
   ProjectManagement
   Miscelaneous
