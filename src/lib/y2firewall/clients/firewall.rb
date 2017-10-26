require 'yast'
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
        log.info("----------------------------------------")
        log.info("Firewall client started")

        @ret = nil

        if Yast::WFM.Args.size > 0
          Yast.import "SuSEFirewallCMDLine"
          Yast::SuSEFirewallCMDLine.Run
        else
          if Yast::UI.TextMode()
            Yast::Popup.Error(_("Your display can't support the 'firewall-config' UI.\n") +
                              _("Either use the Yast2 command line or the 'firewall-cmd' utility.") )
          else
            if Yast::PackageSystem.CheckAndInstallPackages(["firewall-config"])
              @ret = Yast::Execute.locally("/usr/bin/firewall-config")
            end
          end
        end

        log.debug("ret=#{@ret}")

        log.info("Firewall client finished")
        log.info("----------------------------------------")

        @ret
      end
    end
  end
end
