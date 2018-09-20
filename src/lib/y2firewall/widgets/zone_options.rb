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
require "y2firewall/firewalld"

module Y2Firewall
  module Widgets
    # ComboBox which allows to select a zone
    class ZoneOptions < ::CWM::ComboBox
      DEFAULT_ZONE_OPTION = ["", "default"].freeze

      # @!attribute [r] interface
      #  @return [Y2Firewall::Firewalld::Interface] Interface to act on
      attr_reader :interface

      # Constructor
      #
      # @param interface [Y2Firewall::Firewalld::Interface] Interface to act on
      def initialize(interface)
        textdomain "firewall"
        @interface = interface
      end

      # @macro seeAbstractWidget
      def init
        return unless interface.zone
        self.value = interface.zone.name
      end

      # @macro seeAbstractWidget
      def label
        _("Zone")
      end

      # @see CWM::ComboBox#items
      def items
        [DEFAULT_ZONE_OPTION] + zones.map { |z| [z.name, z.name] }
      end

      # @macro seeCommonWidget
      def store
        new_zone = selected_zone
        return if new_zone && new_zone.interfaces.include?(interface.name)

        old_zone = interface.zone
        old_zone.remove_interface(interface.name) if old_zone
        new_zone.add_interface(interface.name) if new_zone
      end

    private

      # Returns the list of known zones
      #
      # @note Just a convenience method which value is 'memoized'.
      #
      # @return [Array<Y2Firewall::Firewalld::Zone>] List of zones.
      def zones
        @zones ||= Y2Firewall::Firewalld.instance.zones
      end

      # Returns the selected zone
      #
      # @return [Y2Firewall::Firewalld::Zone,nil] selected zone
      def selected_zone
        return nil if value.empty?
        Y2Firewall::Firewalld.instance.find_zone(value)
      end
    end
  end
end
