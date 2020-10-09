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
require "cwm/common_widgets"
require "cwm/page"
require "y2firewall/firewalld"
require "y2firewall/helpers/interfaces"
require "y2firewall/widgets/interfaces_table"
require "y2firewall/widgets/change_zone_button"
require "y2firewall/widgets/zone_interfaces_button"

module Y2Firewall
  module Widgets
    module Pages
      # A page for network interfaces
      class Interfaces < CWM::Page
        include Y2Firewall::Helpers::Interfaces

        # Constructor
        #
        # @param _pager [CWM::TreePager]
        def initialize(_pager)
          textdomain "firewall"
        end

        # @macro seeAbstractWidget
        def label
          _("Interfaces")
        end

        # @macro seeCustomWidget
        def contents
          return @contents if @contents

          @contents = VBox(
            Left(Heading(_("Interfaces"))),
            interfaces_table,
            HBox(
              interfaces.empty? ? Empty() : change_zone_button,
              zone_interfaces_button
            )
          )
        end

      private

        # @return [Y2Firewall::Widgets::InterfacesTable] Table containing all interfaces
        def interfaces_table
          @interfaces_table ||= InterfacesTable.new(interfaces, change_zone_button)
        end

        # @return [Y2Firewall::Widgets::ChangeZoneButton] Buttton to change the zone
        def change_zone_button
          @change_zone_button ||= ChangeZoneButton.new(interfaces.first)
        end

        def zone_interfaces_button
          @zone_interfaces_button ||= ZoneInterfacesButton.new
        end

        def interfaces
          known_interfaces + unknown_interfaces
        end
      end
    end
  end
end
