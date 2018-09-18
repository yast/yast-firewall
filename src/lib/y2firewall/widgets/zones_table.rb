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

      # @see CWM::Table#header
      def header
        [
          _("Name"),
          _("Interfaces")
        ]
      end

      # @see CWM::Table#items
      def items
        zones.map { |z| [z.name.to_sym, z.name, z.interfaces.join(", ")] }
      end

      def help
        _("<p>A network zone defines the level of trust for network " \
          "connections.</p>\n<p>Each zone can be used for many network " \
          "connections although a connection can only be part of one zone. " \
          "</p>\n<p>" \
          "<p>The current firewall features supported by zones are:</p>\n" \
          "<ul>" \
          "<li><b>Services:</b> Define a set of ports and/or protocols, " \
          "destination addresses and netfilter kernel helpers to be enabled.</li>" \
          "<li><b>Ports:</b> Single or range of ports <b>(TCP, UDP, SCTP, " \
          "DCCP)</b> to be enabled.</li>" \
          "</ul>\n")
      end
    end
  end
end
