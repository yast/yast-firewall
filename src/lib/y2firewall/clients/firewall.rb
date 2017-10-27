require "yast"
require "yast2/execute"

module Y2Firewall
  module Clients
    class Firewall
      include Yast::I18n
      include Yast::Logger
      include Yast::UIShortcuts

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

      def log_and_return(&block)
        log.info("----------------------------------------")
        log.info("Firewall client started")

        ret = block.call

        log.info("ret=#{ret}")

        log.info("Firewall client finished")
        log.info("----------------------------------------")
      end
    end
  end
end
