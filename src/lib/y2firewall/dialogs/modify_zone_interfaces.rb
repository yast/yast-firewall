# encoding: utf-8

# Copyright (c) [2018] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require "cwm"
require "cwm/popup"
require "y2firewall/widgets/modify_zone_interfaces"

module Y2Firewall
  module Dialogs
    # This dialog allows the user to modify the interfaces belonging to a
    # specific zone.
    class ModifyZoneInterfaces < ::CWM::Popup
      # Constructor
      def initialize
        textdomain "firewall"
      end

      # @macro seeAbstractWidget
      def title
        _("Modify Interfaces")
      end

      # @macro seeCustomWidget
      def contents
        VBox(
          zone_chooser(zone_interfaces),
          zone_interfaces
        )
      end

    private

      # @return [Array<Yast::Term>] List of buttons to display
      def buttons
        [ok_button, cancel_button]
      end

      # Returns a combo box to select the zone
      #
      # @note The widget is 'memoized'.
      #
      # @param interfaces_input [CWM::InputField] input field for modifying the
      #   selected zone interfaces
      # @return [Y2Firewall::Widgets::ZoneInterfacesSelector]
      def zone_chooser(interfaces_input)
        @zone_chooser ||= Y2Firewall::Widgets::ZoneInterfacesSelector.new(interfaces_input)
      end

      # Returns a input field to modify the zone interfaces
      #
      # @note The widget is 'memoized'.
      #
      # @return [Y2Firewall::Widgets::ZoneInterfaces]
      def zone_interfaces
        @zone_interfaces ||= Y2Firewall::Widgets::ZoneInterfaces.new
      end
    end
  end
end
