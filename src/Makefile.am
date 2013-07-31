# Sources for firewall

module_DATA = \
  modules/SuSEFirewallUI.rb \
  modules/SuSEFirewallCMDLine.rb

client_DATA = \
  clients/firewall_auto.rb \
  clients/firewall_proposal.rb \
  clients/firewall.rb

yncludedir = @yncludedir@/firewall
ynclude_DATA = \
  include/firewall/wizards.rb \
  include/firewall/uifunctions.rb \
  include/firewall/subdialogs.rb \
  include/firewall/summary.rb \
  include/firewall/dialogs.rb \
  include/firewall/complex.rb \
  include/firewall/helps.rb \
  include/firewall/generalfunctions.rb

schemafilesdir = $(schemadir)/autoyast/rnc
schemafiles_DATA = \
  autoyast-rnc/firewall.rnc

desktop_DATA = \
  desktop/firewall.desktop

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(schemafiles_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common