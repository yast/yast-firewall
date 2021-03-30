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

Yast.import "UI"

module Y2Firewall
  module Widgets
    # Table containing a set of firewalld services
    #
    # @example Creating a new table
    #   names = Y2Firewall::Firewalld.instance.current_service_names
    #   table = Y2Firewall::Widgets::Services.new(names)
    #
    # @example Updating content
    #   table.services = ["dhcp", "dhcpv6", "dhcpv6-client"]
    class ServicesTable < ::CWM::Table
      # @!attribute [r] services
      #   @return [Array<String>] Services to be displayed
      attr_reader :services

      alias_method :selected_services, :value

      # Constructor
      #
      # @param services [Array<String>] Services to be displayed
      def initialize(services: [], widget_id: nil)
        textdomain "firewall"
        @services = services
        self.widget_id = widget_id || "services_table:#{object_id}"
      end

      # @macro seeAbstractWidget
      def opt
        [:multiSelection]
      end

      # @see CWM::Table#header
      def header
        [_("Name")]
      end

      # @see CWM::Table#items
      def items
        services.sort_by(&:downcase).map { |s| [s, s] }
      end

      # Updates the list of services
      #
      # @note When running on graphical mode, the new elements are kept selected.
      #
      # @param services [Array<String>] New list of services
      def services=(services)
        old_services = @services
        @services = services
        change_items(items) if displayed?

        return if Yast::UI.TextMode

        new_services = services - old_services
        self.value = new_services
      end
    end
  end
end
