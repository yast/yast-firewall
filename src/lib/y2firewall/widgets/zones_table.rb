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

require "y2firewall/ui_state"

module Y2Firewall
  module Widgets
    class ZonesTable < ::CWM::Table
      # @!attribute [r] zone
      #   @return [Array<Y2Firewall::Firewalld::Zone>] Zones
      attr_reader :zones

      # Constructor
      #
      # @param zones [Array<Y2Firewall::Firewalld::Zone>] Zones
      def initialize(zones)
        textdomain "firewall"
        @zones = zones
      end

      def init
        initial_id = UIState.instance.row_id
        self.value = initial_id.to_sym if initial_id
      end

      # @see CWM::Table#header
      def header
        [
          _("Name"),
          _("Short"),
          _("Interfaces")
        ]
      end

      # @see CWM::Table#items
      def items
        zones.map { |z| [z.name.to_sym, z.name, z.short, z.interfaces.join(", ")] }
      end
    end
  end
end
