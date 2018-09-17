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
require "cwm/table"
require "y2firewall/ui_state"

module Y2Firewall
  module Widgets
    # A table with all {Y2Firewall::Firewalld::Zone}s.
    class InterfacesTable < ::CWM::Table
      DEFAULT_ZONE_NAME = "default".freeze

      # @!attribute [r] interfaces
      #   @return [Array<Hash>] Interfaces
      attr_reader :interfaces

      # Constructor
      #
      # @param zones [Array<Y2Firewall::Firewalld::Zone>] Zones
      def initialize(interfaces, change_zone_button)
        textdomain "firewall"
        @interfaces = interfaces
        @change_zone_button = change_zone_button
      end

      def opt
        [:notify, :immediate]
      end

      def init
        interface = UIState.instance.row_id
        if interface && interfaces.include?(interface)
          self.value = interface.to_sym
        end
        change_zone_button.interface = selected_interface
      end

      # @see CWM::Table#header
      def header
        [
          _("Device"),
          _("Zone"),
          _("Name")
        ]
      end

      # @see CWM::Table#items
      def items
        interfaces.map do |iface|
          [
            iface["id"].to_sym,
            iface["id"],
            iface["zone"] || DEFAULT_ZONE_NAME,
            iface["name"]
          ]
        end
      end

      # @macro seeAbstractWidget
      def handle(event)
        return nil unless event["EventReason"] == "SelectionChanged"
        UIState.instance.select_row(value)
        change_zone_button.interface = selected_interface
        nil
      end

      def selected_interface
        interfaces.find { |i| i["id"] == value.to_s }
      end

    private

      # @return [Y2Firewalld::Widgets::ChangeZoneButton] Button to change the assigned zone
      attr_reader :change_zone_button
    end
  end
end
