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
require "ui/text_helpers"
require "y2firewall/dialogs/main"

Yast.import "UI"
Yast.import "Popup"
Yast.import "PackageSystem"

module Y2Firewall
  module Clients
    # Firewalld client which is responsible for running the cmdline or the gui
    # client depending on the given arguments.
    class Firewall
      include Yast::I18n
      extend Yast::I18n
      include UI::TextHelpers
      include Yast::Logger
      include Yast::UIShortcuts

      # Constructor
      def initialize
        textdomain "firewall"
      end

      # TRANSLATORS: firewall-config and firewall-cmd are the names of software utilities,
      # so they should not be translated.
      NOT_SUPPORTED = N_("YaST does not support the command line for " \
        "configuring the firewall.\nInstead, please use the firewalld " \
        "command line clients \"firewalld-cmd\" or \"firewall-offline-cmd\".")

      def run
        log_and_return do
          return :abort unless Yast::PackageSystem.CheckAndInstallPackages(["firewalld"])

          if !Yast::WFM.Args.empty?
            warn _(NOT_SUPPORTED)
            false
          else
            Dialogs::Main.new.run
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
