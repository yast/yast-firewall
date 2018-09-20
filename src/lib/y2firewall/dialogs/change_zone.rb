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

require "cwm/popup"
require "y2firewall/widgets/zone_options"

module Y2Firewall
  module Dialogs
    # This dialog allows the user to select which zone should be an interface assigned to.
    class ChangeZone < ::CWM::Popup
      # @!attribute [r] interface
      #   @return [Y2Firewall::Firewalld::Interface] Interface to act on
      attr_reader :interface

      # Constructor
      #
      # @param interface [Y2Firewall::Firewalld::Interface] Interface to act on
      def initialize(interface)
        textdomain "firewall"
        @interface = interface
      end

      # @macro seeAbstractWidget
      def title
        _("Change Zone")
      end

      # @macro seeCustomWidget
      def contents
        VBox(zone_options)
      end

    private

      # @return [Array<Yast::Term>] List of buttons to display
      def buttons
        [ok_button, cancel_button]
      end

      # Returns a combobox to select the zone
      #
      # @note The widget is 'memoized'.
      #
      # @return [Y2Firewall::Widgets::ZoneOptions]
      def zone_options
        @zone_options ||= Y2Firewall::Widgets::ZoneOptions.new(interface)
      end
    end
  end
end
