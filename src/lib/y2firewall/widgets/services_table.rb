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

require "cwm/table"

module Y2Firewall
  module Widgets
    class ServicesTable < ::CWM::Table
      # @!attribute [r] services
      #   @return [Array<String>] Services to be displayed
      attr_reader :services

      # Constructor
      #
      # @param services [Array<String>] Services to be displayed
      def initialize(services = [])
        textdomain "firewall"
        @services = services
        self.widget_id = "services_table:#{object_id}"
      end

      # @see CWM::Table#header
      def header
        [_("Name")]
      end

      # @see CWM::Table#items
      def items
        @items ||= services.sort_by(&:downcase).map { |s| [s, s] }
      end

      # Updates the list of services
      #
      # @param services [Array<String>] New list of services
      def update(services)
        old_index = items.map(&:first).index(value) unless items.empty?
        @services = services
        refresh
        self.value = items[old_index].first if old_index && !items.empty?
      end

      def selected_service
        value.to_s
      end

    private

      # Refreshes the table content
      def refresh
        @items = nil
        change_items(items)
      end
    end
  end
end
