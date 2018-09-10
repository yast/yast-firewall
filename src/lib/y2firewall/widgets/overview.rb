# encoding: utf-8

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
require "cwm/widget"
require "cwm/tree"
require "cwm/tree_pager"
require "y2firewall/widgets/pages"
require "y2firewall/helpers/interfaces"

module Y2Firewall
  module Widgets
    # A tree that is told what its items are.
    # We need a tree whose items include Pages that point to the OverviewTreePager.
    class OverviewTree < CWM::Tree
      def initialize(items)
        textdomain "firewall"
        @items = items
      end

      # @macro seeAbstractWidget
      def label
        _("System View")
      end

      attr_reader :items
    end

    # Widget representing firewall overview pager with tree on left side and rest on right side.
    #
    # It has replace point where it displays more details about selected element in firewall.
    class OverviewTreePager < CWM::TreePager
      include Y2Firewall::Helpers::Interfaces

      # Constructor
      def initialize
        textdomain "firewall"

        @fw = Y2Firewall::Firewalld.instance
        super(OverviewTree.new(items))
      end

      # @see http://www.rubydoc.info/github/yast/yast-yast2/CWM%2FTree:items
      def items
        [
          startup_item,
          interfaces_item,
          zones_item,
          # masquerade_item,
          # broadcast_item,
          # logging_item,
          # custom_rules_item
        ]
      end

      # Overrides default behavior of TreePager to register the new state with
      # {UIState} before jumping to the tree node
      def switch_page(page)
        UIState.instance.go_to_tree_node(page)
        super
      end

      # Ensures the tree is properly initialized according to {UIState} after
      # a redraw.
      def initial_page
        UIState.instance.find_tree_node(@pages) || super
      end

    private

      # @return [CWM::PagerTreeItem]
      def startup_item
        page = Pages::Startup.new(self)
        CWM::PagerTreeItem.new(page)
      end

      # @return [CWM::PagerTreeItem]
      def interfaces_item
        ifcs = known_interfaces
        children = ifcs.map { |i| interface_item(i) }
        page = Pages::Interfaces.new(self)
        CWM::PagerTreeItem.new(page, children: children)
      end

      # @return [CWM::PagerTreeItem]
      def interface_item(i)
        page = Pages::Interface.new(i, self)
        CWM::PagerTreeItem.new(page)
      end

      # @return [CWM::PagerTreeItem]
      def zones_item
        zones = @fw.zones
        children = zones.map { |z| zone_item(z) }
        page = Pages::Zones.new(self)
        CWM::PagerTreeItem.new(page, children: children)
      end

      # @return [CWM::PagerTreeItem]
      def zone_item(z)
        page = Pages::Zone.new(z, self)
        CWM::PagerTreeItem.new(page)
      end
    end
  end
end
