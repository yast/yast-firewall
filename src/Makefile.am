# Makefile.am for firewall/src

yncludedir = @yncludedir@/firewall

module_DATA = SuSEFirewall.ycp

client_DATA =		\
	firewall.ycp	\
	firewall_auto.ycp

ynclude_DATA =		\
	complex.ycp	\
	dialogs.ycp	\
	wizards.ycp

config_DATA = firewall.y2cc

desktop_DATA = firewall.desktop


EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(config_DATA)  $(module_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
