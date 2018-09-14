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
  # Singleton class to keep the position of the user in the UI and other similar
  # information that needs to be rememberd across UI redraws to give the user a
  # sense of continuity.
  class UIState
    include Yast::I18n

    # Constructor
    #
    # Called through {.create_instance}, starts with a blank situation (which
    # means default for each widget will be honored).
    def initialize
      textdomain "firewall"
      @candidate_nodes = []
    end

    # Method to be called when the user decides to visit a given page by
    # clicking in one node of the general tree.
    #
    # It remembers the decision so the user is taken back to a sensible point of
    # the tree (very often the last he decided to visit) after redrawing.
    #
    # @param [CWM::Page] page associated to the tree node
    def go_to_tree_node(page)
      self.candidate_nodes =
        if page.respond_to?(:zone)
          zone_page_candidates(page)
        else
          [page.label]
        end
      # Landing in a new node, so invalidate previous details about position
      # within a node, they no longer apply
      self.tab = nil
    end

    # Method to be called when the user switches to a tab within a tree node.
    #
    # It remembers the decision so the same tab is showed in case the user stays
    # in the same node after redrawing.
    #
    # @param [CWM::Page] page associated to the tab
    def switch_to_tab(page)
      self.tab = page.label
    end

    # Method to be called when the user operates in a row of a table of zones
    # or creates a new zone.
    #
    # @param zone [String] zone name
    def select_row(zone_name)
      self.row_id = zone_name
    end

    # Select the page to open in the general tree after a redraw
    #
    # @param pages [Array<CWM::Page>] all the pages in the tree
    # @return [CWM::Page, nil]
    def find_tree_node(pages)
      candidate_nodes.each.with_index do |candidate, idx|
        result = pages.find { |page| matches?(page, candidate) }
        if result
          # If we had to use one of the fallbacks, the tab name is not longer
          # trustworthy
          self.tab = nil unless idx.zero?
          return result
        end
      end
      self.tab = nil
      nil
    end

    # Select the tab to open within the node after a redraw
    #
    # @param pages [Array<CWM::Page>] pages for all the possible tabs
    # @return [CWM::Page, nil]
    def find_tab(pages)
      return nil unless tab
      pages.find { |page| page.label == tab }
    end

    # @see #row_id
    attr_accessor :row_id

  protected

    # Where to place the user within the general tree in next redraw
    # @return [Array<Integer, String>]
    attr_accessor :candidate_nodes

    # Concrete tab within the current node to show in the next redraw
    # @return [String, nil]
    attr_reader :tab
    # @see #tab
    def tab=(tab)
      @tab = tab
      # If the user switched to a new tab, invalidate details about the inner
      # table
      self.row_id = nil
    end

    # List of candidate nodes to go back after opening a zone view in the tree
    def zone_page_candidates(page)
      zone = page.zone

      [zone.name]
    end

    # Whether the given page matches with the candidate tree node
    #
    # @param page [CWM::Page]
    # @param candidate [Integer, String]
    # @return boolean
    def matches?(page, candidate)
      page.label == candidate
    end

    class << self
      # Singleton instance
      def instance
        create_instance unless @instance
        @instance
      end

      # Enforce a new clean instance
      def create_instance
        @instance = new
      end

      # Make sure only .instance and .create_instance can be used to
      # create objects
      private :new, :allocate
    end
  end
end
