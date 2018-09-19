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
    # A table with all {Y2Firewall::Firewalld::Interface}s.
    class InterfacesTable < ::CWM::Table
      DEFAULT_ZONE_NAME = "default".freeze

      # @!attribute [r] interfaces
      #   @return [Array<Y2Firewall::Firewalld::Interface>] Interfaces
      attr_reader :interfaces

      # Constructor
      #
      # @param interfaces [Array<Y2Firewall::Firewalld::Interfaces>] Interfaces to list
      # @param change_zone_button [Y2Firewall::Widgets::ChangeZoneButton] Button to change assigned
      #   zone
      def initialize(interfaces, change_zone_button)
        textdomain "firewall"
        @interfaces = interfaces
        @change_zone_button = change_zone_button
      end

      # @macro seeAbstractWidget
      def opt
        [:notify, :immediate]
      end

      # @macro seeAbstractWidget
      def init
        interface = Y2Firewall::UIState.instance.row_id
        if interface && interfaces.map(&:name).include?(interface.to_s)
          self.value = interface
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
            iface.name.to_sym,
            iface.name,
            iface.zone ? iface.zone.name : DEFAULT_ZONE_NAME,
            iface.device_name
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
        interfaces.find { |i| i.name == value.to_s }
      end

    private

      # @return [Y2Firewalld::Widgets::ChangeZoneButton] Button to change the assigned zone
      attr_reader :change_zone_button
    end
  end
end
