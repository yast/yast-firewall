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
require "cwm/common_widgets"
require "cwm/page"
require "y2firewall/firewalld"
require "y2firewall/helpers/interfaces"
require "y2firewall/widgets/interfaces_table"
require "y2firewall/widgets/change_zone_button"

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
            known_interfaces.empty? ? Empty() : change_zone_button
          )
        end

      private

        # @return [Y2Firewall::Widgets::InterfacesTable] Table containing all interfaces
        def interfaces_table
          @interfaces_table ||= InterfacesTable.new(known_interfaces, change_zone_button)
        end

        # @return [Y2Firewall::Widgets::ChangeZoneButton] Buttton to change the zone
        def change_zone_button
          @change_zone_button ||= ChangeZoneButton.new(known_interfaces.first)
        end
      end
    end
  end
end
