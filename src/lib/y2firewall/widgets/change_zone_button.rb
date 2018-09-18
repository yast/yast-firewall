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
require "y2firewall/dialogs/change_zone"
require "y2firewall/ui_state"

module Y2Firewall
  module Widgets
    # This button opens a dialog to change the zone for a given interface
    class ChangeZoneButton < CWM::PushButton
      # @!attribute [r] interface
      #   @return [Hash] Interface to act on
      attr_accessor :interface

      # Constructor
      #
      # @param interface [Hash] Interface to act on
      def initialize(interface = nil)
        textdomain "firewall"
        @interface = interface
      end

      # @see seeAbstractWidget
      def label
        _("Change Zone")
      end

      # @see seeAbstractWidget
      def handle
        return nil unless interface
        UIState.instance.select_row(interface["id"])
        result = Dialogs::ChangeZone.run(interface)
        result == :ok ? :redraw : nil
      end
    end
  end
end
