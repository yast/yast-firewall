#
# Makefile.am for y2c_firewall/src
#

yncludedir = @yncludedir@/firewall

module_DATA = SuSEFirewall.ycp

client_DATA =		\
	firewall.ycp	\
	firewall_auto.ycp

ynclude_DATA =		\
	ui.ycp

config_DATA = firewall.y2cc

scrconf_DATA = cfg_firewall2.scr

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(config_DATA) $(scrconf_DATA) $(module_DATA)
