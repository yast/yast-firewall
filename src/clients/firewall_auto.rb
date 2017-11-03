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
# File:	clients/firewall_auto.ycp
# Package:	SuSE firewall configuration
# Summary:	Client for autoinstallation
# Authors:	Anas Nashif <nashif@suse.de>
#		Lukas Ocilka <locilka@suse.cz>
#
# $Id$
#
# This is a client for autoinstallation. It takes its arguments,
# goes through the configuration and return the setting.
# Does not do any changes to the configuration.

# @param function to execute
# @param map/list of firewall settings
# @return [Hash] edited settings, Summary or boolean on success depending on called function
# @example map mm = $[ "FAIL_DELAY" : "77" ];
# @example map ret = WFM::CallFunction ("firewall_auto", [ "Summary", mm ]);
module Yast
  class FirewallAutoClient < Client
    def main
      Yast.import "UI"

      textdomain "firewall"

      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("Firewall auto started")

      Yast.import "Map"
      Yast.import "SuSEFirewall"

      Yast.include self, "firewall/wizards.rb"
      Yast.include self, "firewall/summary.rb"

      @ret = nil
      @func = ""
      @param = {}

      # Check arguments
      if Ops.greater_than(Builtins.size(WFM.Args), 0) &&
          Ops.is_string?(WFM.Args(0))
        @func = Convert.to_string(WFM.Args(0))
        if Ops.greater_than(Builtins.size(WFM.Args), 1) &&
            Ops.is_map?(WFM.Args(1))
          @param = Convert.to_map(WFM.Args(1))
        end
      end
      Builtins.y2debug("func=%1", @func)
      Builtins.y2debug("param=%1", @param)

      # Create a summary
      if @func == "Summary"
        @ret = InitBoxSummary(SuSEFirewall.GetKnownFirewallZones)
      # Reset configuration
      elsif @func == "Reset"
        SuSEFirewall.Import({})
        @ret = {}
        SuSEFirewall.SetEnableService(SuSEFirewall.GetStartService || false)
      # Return required packages for module to operate
      elsif @func == "Packages"
        @ret = { "install" => [ "SuSEfirewall2" ] }
      # Change configuration (run FirewallAutoSequence)
      elsif @func == "Change"
        @ret = FirewallAutoSequence()
        SuSEFirewall.SetStartService(SuSEFirewall.GetEnableService)
      # Import configuration
      elsif @func == "Import"
        @ret = SuSEFirewall.Import(
          Convert.convert(@param, :from => "map", :to => "map <string, any>")
        )
      # Read firewall data
      elsif @func == "Read"
        @ret = SuSEFirewall.Read
        SuSEFirewall.SetEnableService(SuSEFirewall.GetStartService)
      # Return actual state
      elsif @func == "Export"
        @ret = SuSEFirewall.Export
      # Return actual state
      elsif @func == "GetModified"
        @ret = SuSEFirewall.GetModified
      elsif @func == "SetModified"
        SuSEFirewall.SetModified
        @ret = true
      # Write given settings
      elsif @func == "Write"
        Yast.import "Progress"
        old_progress = Progress.set(false)
        @ret = SuSEFirewall.Write
        Progress.set(old_progress)
      else
        Builtins.y2error("Unknown function: %1", @func)
        @ret = false
      end

      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("Firewall auto finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret)

      # EOF
    end
  end
end

Yast::FirewallAutoClient.new.main
