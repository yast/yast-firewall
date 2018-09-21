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
      # @!attribute [r] zone
      #   @return [Array<Y2Firewall::Firewalld::Zone>] Zones
      attr_reader :zones

      # Constructor
      #
      # @param zones [Array<Y2Firewall::Firewalld::Zone>] Zones
      # @param default_zone_button [Y2Firewall::Widgets::DefaultZoneButton] Button to change
      #   the default zone
      def initialize(zones, default_zone_button)
        textdomain "firewall"
        @zones = zones
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
            zone.interfaces.join(", "),
            zone.name == firewall.default_zone ? Yast::UI.Glyph(:CheckMark) : ""
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

      # @macro seeAbstractWidget
      def help
        _(
          "<p>A network zone defines the level of trust for network connections.</p>\n" \
          "<p>You can designate one of them as the <b>default</b> zone by clicking the\n" \
          "<b>Set As Default</b> button.</p>\n\n" \
          "<p>In the <b>Interfaces</b> column you see which interfaces are assigned\n" \
          "to a given zone. Bear in mind that, for the zone which is set as the default\n" \
          "one, you will see the interfaces that are implicitly assigned to it, i.e.,\n" \
          "those interfaces that are not assigned explicitly to that zone but to the\n" \
          "default one.</p>\n\n" \
          "<p>If you want to assign an interface to a given zone, just visit the\n" \
          "<b>Interfaces</b> section.</p>"
        )
      end

    private

      # @return [Y2Firewalld::Widgets::DefaultZoneButton] Button to set a zone as 'default'
      attr_reader :default_zone_button

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
