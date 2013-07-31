# encoding: utf-8

# ***************************************************************************
#
# Copyright (c) 2000 - 2012 Novell, Inc.
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#
# ***************************************************************************
#
# File:	clients/firewall.ycp
# Package:	Firewall configuration
# Summary:	Firewall configuration dialogs
# Authors:	Lukas Ocilka <locilka@suse.cz>
#
# $Id$
#
# File includes helps for yast2-firewall dialogs.
module Yast
  class FirewallClient < Client
    def main
      Yast.import "UI"
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("Firewall module started")

      textdomain "firewall"

      Yast.import "SuSEFirewall"
      Yast.import "Mode"

      Yast.include self, "firewall/wizards.rb"

      @ret = nil

      # bnc #388773
      # Explicitely enable offering to install the firewall packages
      # if they are missing
      SuSEFirewall.SetInstallPackagesIfMissing(true)

      # there are some arguments - starting commandline
      if Ops.greater_than(Builtins.size(WFM.Args), 0)
        Yast.import "SuSEFirewallCMDLine"
        SuSEFirewallCMDLine.Run 
        # GUI or TextUI
      else
        # installation has other sequence
        if Mode.installation
          @ret = FirewallInstallationSequence()
        else
          @ret = FirewallSequence()
        end
      end

      Builtins.y2debug("ret=%1", @ret)

      Builtins.y2milestone("Firewall module finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret) 

      # EOF
    end
  end
end

Yast::FirewallClient.new.main
