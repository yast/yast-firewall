# Makefile.am for firewall/src

yncludedir = @yncludedir@/firewall

module_DATA = SuSEFirewall.ycp

client_DATA =		\
	firewall.ycp	\
	firewall_auto.ycp	\
	firewall_proposal.ycp

ynclude_DATA =		\
	complex.ycp	\
	dialogs.ycp	\
	wizards.ycp

desktop_DATA = firewall.desktop


EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(desktop_DATA)

autocode: liste liste2ycp.pl
	cp -a SuSEFirewall.ycp SuSEFirewall.ycp.tmp
	./liste2ycp.pl < SuSEFirewall.ycp.tmp > SuSEFirewall.ycp
	rm SuSEFirewall.ycp.tmp

include $(top_srcdir)/Makefile.am.common
