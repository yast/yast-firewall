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

require "cwm/dialog"
require "y2firewall/widgets/zone_options"

module Y2Firewall
  module Dialogs
    # This dialog allows the user to select which zone should be an interface assigned to.
    class ChangeZone < ::CWM::Dialog
      # @!attribute [r] interface
      #   @return [Hash] Interface to change the zone
      attr_reader :interface

      # Constructor
      #
      # @param interface [Hash] Interface to act on
      def initialize(interface)
        @interface = interface
      end

      # @macro seeAbstractWidget
      def label
        _("Change Zone")
      end

      # @macro seeCustomWidget
      def contents
        VBox(zone_options)
      end

      # Returns the selected zone
      #
      # @return [Y2Firewall::Firewalld::Zone] selected zone
      def selected_zone
        Y2Firewall::Firewalld.instance.find_zone(zone_options.value)
      end

      # Updates firewall configuration when the 'next' button is pressed
      #
      # @note This method assigns the interface to the selected zone.
      def next_handler
        return true if selected_zone.interfaces.include?(interface["id"])

        Y2Firewall::Firewalld.instance.zones.each do |zone|
          zone.remove_interface(interface["id"])
        end
        selected_zone.add_interface(interface["id"])

        true
      end

      # Returns the 'next' button label
      #
      # @return [String] Button label
      #
      # @see CWM::Dialog#next_button
      # @see Yast::Label
      def next_button
        Yast::Label.AcceptButton
      end

      # Returns the 'abort' button label
      #
      # @return [String] Button label
      #
      # @see CWM::Dialog#abort_button
      # @see Yast::Label
      def abort_button
        Yast::Label.CancelButton
      end

      # Disables the 'back' button
      #
      # @return [nil]
      #
      # @see CWM::Dialog#back_button
      def back_button
        ""
      end

    private

      # Returns a combobox to select the zone
      #
      # @note The widget is 'memoized'.
      #
      # @return [Y2Firewall::Widgets::ZoneOptions]
      def zone_options
        @zone_options ||= Y2Firewall::Widgets::ZoneOptions.new(interface)
      end

      # Determines whether a dialog should be open
      #
      # @return [true]
      def should_open_dialog?
        true
      end
    end
  end
end
