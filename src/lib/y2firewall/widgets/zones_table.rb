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

require "cwm/table"

module Y2Firewall
  module Widgets
    # A table with all {Y2Firewall::Firewalld::Zone}s.
    class ZonesTable < ::CWM::Table
      # @!attribute [r] zones
      #   @return [Array<Y2Firewall::Firewalld::Zone>] Zones
      attr_reader :zones
      # @!attribute [r] interfaces
      #   @return [Array<Y2Firewall::Firewalld::Zone>] Interfaces
      attr_reader :interfaces

      # Constructor
      #
      # @param zones [Array<Y2Firewall::Firewalld::Zone>] Zones
      # @param interfaces [Array<Y2Firewall::Firewalld::Interface>] Interfaces
      # @param default_zone_button [Y2Firewall::Widgets::DefaultZoneButton] Button to change
      #   the default zone
      def initialize(zones, interfaces, default_zone_button)
        textdomain "firewall"
        @zones = zones
        @interfaces = interfaces
        @default_zone_button = default_zone_button
      end

      # @macro seeAbstractWidget
      def opt
        [:notify, :immediate]
      end

      # @macro seeAbstractWidget
      def init
        zone = Y2Firewall::UIState.instance.row_id
        self.value = zone if zone && zones.map(&:name).include?(zone.to_s)
        default_zone_button.zone = selected_zone
      end

      # @see CWM::Table#header
      def header
        [
          _("Name"),
          _("Interfaces"),
          _("Default")
        ]
      end

      # @see CWM::Table#items
      def items
        zones.map do |zone|
          [
            zone.name.to_sym,
            zone.name,
            assigned_interfaces(zone).join(" "),
            default_zone?(zone) ? Yast::UI.Glyph(:CheckMark) : ""
          ]
        end
      end

      # @macro seeAbstractWidget
      def handle(event)
        return nil unless my_event?(event) && event["EventReason"] == "SelectionChanged"
        UIState.instance.select_row(value)
        default_zone_button.zone = selected_zone
        nil
      end

      # Returns the selected interface
      #
      # @return [Y2Firewall::Firewall::Interface] Interface
      def selected_zone
        zones.find { |z| z.name == value.to_s }
      end

    private

      # @return [Y2Firewalld::Widgets::DefaultZoneButton] Button to set a zone as 'default'
      attr_reader :default_zone_button

      # Returns the interfaces assigned to a given zone
      #
      # @note If the given zone is the default one, add the interfaces
      #   which are assigned to it.
      #
      # @param zone [Y2Firewall::Firewalld::Zone] Zone to get interfaces
      # @return [Array<String>] Names of the assigned interfaces
      def assigned_interfaces(zone)
        assigned = zone.interfaces.clone
        assigned += interfaces.reject(&:zone).map(&:name) if default_zone?(zone)
        assigned
      end

      # Returns the default zone
      #
      # @return [Y2Firewall::Firewalld::Zone] Default zone
      def default_zone
        zones.find { |z| z.name == firewall.default_zone }
      end

      # Determines whether the given zone is the default one
      #
      # @param zone [Y2Firewall::Firewalld::Zone] Zone to get interfaces
      # @return [Boolean]
      def default_zone?(zone)
        zone == default_zone
      end

      # Return the current `Y2Firewall::Firewalld` instance
      #
      # This is just a convenience method.
      #
      # @return [Y2Firewall::Firewalld]
      def firewall
        Y2Firewall::Firewalld.instance
      end
    end
  end
end
