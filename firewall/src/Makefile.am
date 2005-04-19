# Makefile.am for firewall/src

yncludedir = @yncludedir@/firewall

client_DATA =		\
	firewall.ycp	\
	firewall_auto.ycp	\
	firewall_proposal.ycp

ynclude_DATA =		\
	complex.ycp	\
	dialogs.ycp	\
	wizards.ycp	\
	subdialogs.ycp	\
	uifunctions.ycp	\
	helps.ycp	\
	summary.ycp	\
	cmdline.ycp	\
	generalfunctions.ycp

desktop_DATA = firewall.desktop


EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
