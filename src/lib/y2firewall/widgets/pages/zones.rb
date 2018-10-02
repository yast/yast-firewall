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
require "y2firewall/widgets/zones_table"
require "y2firewall/widgets/default_zone_button"

module Y2Firewall
  module Widgets
    module Pages
      # A page for firewall zones:
      #   contains {ZonesTable}, has {Zone} as subpages.
      class Zones < CWM::Page
        include Y2Firewall::Helpers::Interfaces

        # Constructor
        #
        # @param _pager [CWM::TreePager]
        def initialize(_pager)
          textdomain "firewall"
        end

        # @macro seeAbstractWidget
        def label
          _("Zones")
        end

        # @macro seeCustomWidget
        def contents
          return @contents if @contents
          @contents = VBox(
            Left(Heading(_("Zones"))),
            ZonesTable.new(firewall.zones, known_interfaces, default_zone_button),
            firewall.zones.empty? ? Empty() : default_zone_button
          )
        end

      private

        def default_zone_button
          return nil if firewall.zones.empty?
          @default_zone_button ||= DefaultZoneButton.new(firewall.zones.first)
        end

        def firewall
          Y2Firewall::Firewalld.instance
        end
      end
    end
  end
end
