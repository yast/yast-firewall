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
require "ui/service_status"

module Y2Firewall
  module Widgets
    module Pages
      class Startup < CWM::Page
         # Constructor
        #
        # @param pager [CWM::TreePager]
        def initialize(pager)
          textdomain "firewall"
          Yast.import "SystemdService"

          @service = Yast::SystemdService.find("firewalld")
          # This is a generic widget in SLE15; may not be appropriate.
          # For SLE15-SP1, use CWM::ServiceWidget
          @status_widget = ::UI::ServiceStatus.new(@service)
        end

        # @macro seeAbstractWidget
        def label
          "Startup" # FIXME
        end

        # @macro seeCustomWidget
        def contents
          VBox(
            @status_widget.widget,
            VStretch()
          )
        end
      end

      class AllowedServices < CWM::Page
        # Constructor
        #
        # @param pager [CWM::TreePager]
        def initialize(pager)
          textdomain "firewall"
        end

        # @macro seeAbstractWidget
        def label
          "FIXME Services"
        end

        # @macro seeCustomWidget
        def contents
          Label("HELLO 2")
        end
      end

      class AllowedServicesForZone < CWM::Page
        # Constructor
        #
        # @param pager [CWM::TreePager]
        def initialize(zone, pager)
          textdomain "firewall"
          @zone = zone
          self.widget_id = "asz:" + zone
        end

        # @macro seeAbstractWidget
        def label
          "FIXME Services for #{@zone}"
        end

        # @macro seeCustomWidget
        def contents
          Label("HELLO #{@zone}")
        end
      end
    end
  end
end
