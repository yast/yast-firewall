#
# Makefile.am for y2c_firewall/src
#
# $Id$
#

clientsdir = $(YAST2DIR)/clients
includedir = $(YAST2DIR)/include/firewall
menudir = $(YAST2DIR)/menuentries

clients_DATA =		\
	firewall.ycp	\
	firewall_write.ycp

include_DATA =		\
	io.ycp		\
	ui.ycp

menu_DATA = menuentry_firewall2.y2cc

EXTRA_DIST = $(clients_DATA) $(include_DATA) $(menu_DATA)
