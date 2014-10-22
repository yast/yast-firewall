# YaST Firewall - Configures SuSEfirewall2 #

[![Travis Build](https://travis-ci.org/yast/yast-firewall.svg?branch=master)](https://travis-ci.org/yast/yast-firewall)
[![Jenkins Build](http://img.shields.io/jenkins/s/https/ci.opensuse.org/yast-firewall-master.svg)](https://ci.opensuse.org/view/Yast/job/yast-firewall-master/)

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
