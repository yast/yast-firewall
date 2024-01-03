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
    # Combo box widget for selecting the zone which interfaces will be modified
    class ZoneInterfacesSelector < ::CWM::ComboBox
      extend Yast::I18n
      # @!attribute [rw] interfaces_input
      attr_accessor :interfaces_input

      # Constructor
      #
      # @param interfaces_input [CWM::InputField] input field for modifying the
      #   selected zone interfaces
      def initialize(interfaces_input)
        super()
        textdomain "firewall"
        @interfaces_input = interfaces_input
      end

      # @macro seeAbstractWidget
      def init
        self.value = Y2Firewall::Firewalld.instance.default_zone
        interfaces_input.value = selected_zone ? selected_zone.interfaces.join(" ") : ""
      end

      # @macro seeAbstractWidget
      def opt
        [:notify]
      end

      # @macro seeAbstractWidget
      def label
        _("Zone")
      end

      # @see CWM::ComboBox#items
      def items
        zones.map { |z| [z.name, z.name] }
      end

      # @macro seeAbstractWidget
      def handle
        interfaces_input.value = selected_zone ? selected_zone.interfaces.join(" ") : ""
        nil
      end

      # @macro seeAbstractWidget
      def store
        return unless selected_zone

        selected_zone.interfaces = interfaces_input.items_from_ui
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
        return nil if !value || value.empty?

        Y2Firewall::Firewalld.instance.find_zone(value)
      end
    end

    # An input field widget.
    # The {#label} method is mandatory.
    #
    # @example input field widget child
    class ZoneInterfaces < CWM::InputField
      def initialize
        super()
        textdomain "firewall"
      end

      # @macro seeAbstractWidget
      def label
        _("Interfaces:")
      end

      # Split the current input field value by any combination of commas
      # and/or spaces.
      #
      # @return [Array<String>] the current value splitted by any combination
      #   of commas and/or spaces
      def items_from_ui
        value.split(/ *[, ] */)
      end
    end
  end
end
