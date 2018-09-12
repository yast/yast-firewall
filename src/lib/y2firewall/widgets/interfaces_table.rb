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

module Y2Firewall
  module Widgets
    # A table with all {Y2Firewall::Firewalld::Zone}s.
    class InterfacesTable < ::CWM::Table
      # @!attribute [r] interfaces
      #   @return [Array<Hash>] Zones
      attr_reader :interfaces

      # Constructor
      #
      # @param zones [Array<Y2Firewall::Firewalld::Zone>] Zones
      def initialize(interfaces)
        textdomain "firewall"
        @interfaces = interfaces
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
          [Id(iface["id"]), iface["id"], iface["zone"], iface["name"]]
        end
      end
    end
  end
end
