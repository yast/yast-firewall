# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2017 SUSE LLC
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
require "yast2/execute"

module Y2Firewall
  module Clients
    # Firewalld client which is responsible of run the cmdline or the gui
    # client depending on the given arguments.
    class Firewall
      include Yast::I18n
      include Yast::Logger
      include Yast::UIShortcuts

      # Constructor
      def initialize
        Yast.import "UI"
        Yast.import "Popup"
        Yast.import "PackageSystem"

        textdomain "firewall"
      end

      def run
        log_and_return do
          if !Yast::WFM.Args.empty?
            Yast.import "SuSEFirewallCMDLine"
            Yast::SuSEFirewallCMDLine.Run
            nil
          elsif Yast::UI.TextMode()
            Yast::Popup.Error(
              _("Your display can't support the 'firewall-config' UI.\n") +
              _("Either use the Yast2 command line or the 'firewall-cmd' utility.")
            )
            false
          elsif Yast::PackageSystem.CheckAndInstallPackages(["firewall-config"])
            Yast::Execute.locally("/usr/bin/firewall-config")
          end
        end
      end

    private

      # It logs the start and finish of the given block call returning the
      # result of the call.
      def log_and_return(&block)
        log.info("----------------------------------------")
        log.info("Firewall client started")

        ret = block.call

        log.info("ret=#{ret}")

        log.info("Firewall client finished")
        log.info("----------------------------------------")

        ret
      end
    end
  end
end
