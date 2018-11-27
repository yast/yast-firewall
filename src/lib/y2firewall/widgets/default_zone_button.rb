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
    # This button sets a zone as the default one
    class DefaultZoneButton < CWM::PushButton
      # @!attribute [r] zone
      #   @return [Y2Firewall::Firewalld::Zone] Zone to set as 'default'
      attr_reader :zone

      # Constructor
      #
      # @param zone [Y2Firewall::Firewalld::Zone] Zone to set as 'default'
      def initialize(zone)
        textdomain "firewall"
        @zone = zone
      end

      # @macro seeAbstractWidget
      def label
        _("Set As Default")
      end

      # Sets the zone to act on
      #
      # @note If the given zone is the default one then the button is disabled.
      #
      # @param zone [Y2Firewall::Firewalld::Zone] Zone to set as 'default'
      def zone=(zone)
        @zone = zone
        enable_or_disable
      end

      # @macro seeAbstractWidget
      def handle
        firewall.default_zone = zone.name
        :redraw
      end

    private

      # Enables or disables the button depending whether the zone is the default one or not
      def enable_or_disable
        if firewall.default_zone == zone.name
          disable
        else
          enable
        end
      end

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
