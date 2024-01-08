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
require "y2firewall/dialogs/modify_zone_interfaces"
require "y2firewall/ui_state"

module Y2Firewall
  module Widgets
    # This button opens a dialog to change the interfaces of the selected zone
    class ZoneInterfacesButton < CWM::PushButton
      # Constructor
      def initialize
        super()
        textdomain "firewall"
      end

      def opt
        [:key_F7]
      end

      # @macro seeAbstractWidget
      def label
        _("C&ustom...")
      end

      # @macro seeAbstractWidget
      def handle
        result = Dialogs::ModifyZoneInterfaces.run
        (result == :ok) ? :redraw : nil
      end
    end
  end
end
