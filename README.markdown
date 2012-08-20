# YaST Firewall - Configures SuSEfirewall2 #

This repository contains basic set of shared libraries and so-called SCR agents
used for reading and writing configuration files and some even for executing
commands on the system.

YaST Firewall configures SuSEfirewall2 in /etc/sysconfig/SuSEfirewall2 and
handles also services defined in /etc/sysconfig/SuSEfirewall2.d/services/.

Shared functionality is in another repository:
https://github.com/yast/yast-yast2/tree/master/library/network

## Installation ##

    make -f Makefile.cvs
    make
    sudo make install

## Running Testsuites ##

    make check

## Links ##

  * See more at http://en.opensuse.org/openSUSE:YaST_development
