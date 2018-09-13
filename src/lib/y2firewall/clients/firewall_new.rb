# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2018 SUSE LLC
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact SUSE.
#
# To contact SUSE about this file by physical or electronic mail, you may find
# current contact information at www.suse.com.
# ------------------------------------------------------------------------------

require "yast"
require "yast/i18n"
require "yast2/popup"
require "cwm/tree_pager"
require "y2firewall/dialogs/main"

module Y2Firewall
  # YaST "clients" are the CLI entry points
  module Clients
    # The entry point for starting the firewall UI.
    class FirewallNew
      include Yast::I18n
      include Yast::Logger

      # Constructor
      def initialize
        textdomain "firewall"

        Yast.import "UI"
        Yast.import "Popup"
        Yast.import "PackageSystem"
      end

      # Runs the client
      def run
        if Yast::PackageSystem.CheckAndInstallPackages(["firewalld"])
          Dialogs::Main.new.run
        end
      end
    end
  end
end
