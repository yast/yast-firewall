# Makefile.am for firewall/src

yncludedir = @yncludedir@/firewall

YCPCFLAGS = -M . -I .

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
	generalfunctions.ycp

module_DATA =		\
	SuSEFirewallUI.ycp \
	SuSEFirewallCMDLine.ycp

desktop_DATA = firewall.desktop


EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(desktop_DATA)

firewall:
	test -L firewall || ln -s . firewall

ycpchook = firewall

include $(top_srcdir)/Makefile.am.common
