# ------------------------------------------------------------------------------
# Copyright (c) 2018 SUSE LLC
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact SUSE.
#
# To contact SUSE about this file by physical or electronic mail, you may find
# current contact information at www.suse.com.
# ------------------------------------------------------------------------------

require "yast"
require "cwm/tree"

module Y2Firewall
  module Widgets
    # A tree that is told what its items are.
    # We need a tree whose items include Pages that point to the OverviewTreePager.
    class OverviewTree < CWM::Tree
      # @!attribute [r] items
      #   @return [Array<CWM::PagerTreeItem>] List of tree items
      attr_reader :items

      # Constructor
      #
      # @param items [Array<CWM::PagerTreeItem>] List of tree items to be included
      def initialize(items)
        super()
        textdomain "firewall"
        @items = items
      end

      # @macro seeAbstractWidget
      def label
        ""
      end
    end
  end
end
