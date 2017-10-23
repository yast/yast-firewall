require 'yast'
require "yast2/execute"

module Y2Firewall
  module Clients
    class Firewall
      extend Yast::I18n
      extend Yast::Logger

      def self.run
        Yast.import "Popup"

        @ret = false

        if Yast::WFM.Args.size > 0 || Yast::UI.TextMode()
          Yast::Popup.Error(
            _("Your display can't support the 'firewall-config' UI.\n" \
              "Use the 'firewall-cmd' utility.")
          )
        else
          Yast.import "PackageSystem"
          if Yast::PackageSystem.CheckAndInstallPackages(["firewall-config"])
            @ret = Yast::Execute.locally("/usr/bin/firewall-config")
          end
        end

        log.debug("ret=#{@ret}")

        log.info("Firewall module finished")
        log.info("----------------------------------------")

        @ret
      end
    end
  end
end
