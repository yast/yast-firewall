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
require "cwm/page"
require "y2firewall/firewalld"
require "ui/service_status"

module Y2Firewall
  module Widgets
    module Pages
      # A page for firewall service startup
      class Startup < CWM::Page
        # Constructor
        #
        # @param _pager [CWM::TreePager]
        def initialize(_pager)
          textdomain "firewall"
        end

        # @macro seeAbstractWidget
        def label
          _("Startup")
        end

        # @macro seeCustomWidget
        def contents
          VBox(
            status_widget.widget,
            VStretch()
          )
        end

        # @return [Symbol, nil] returns :swap_mode if the service is started
        #   or stopped and returns nil othwerwise
        def handle(input)
          result = status_widget.handle_input(input["ID"])
          return :swap_mode if result == :start || result == :stop

          nil
        end

        def store
          system_service.start_mode = status_widget.enabled_flag? ? :on_boot : :manual
          system_service.reload if status_widget.reload_flag?
        end

      private

        # This is a generic widget in SLE15; may not be appropriate.
        # For SLE15-SP1, use CWM::ServiceWidget
        def status_widget
          @status_widget ||= ::UI::ServiceStatus.new(system_service.service)
        end

        # Convenience method to obtain the firewall system service
        #
        # @return [Yast2::SystemService]
        def system_service
          Y2Firewall::Firewalld.instance.system_service
        end
      end
    end
  end
end
