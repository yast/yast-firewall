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

require "cwm/ui_state"

module Y2Firewall
  # Singleton class to keep the position of the user in the UI and other similar
  # information that needs to be rememberd across UI redraws to give the user a
  # sense of continuity.
  class UIState < CWM::UIState
    # Method to be called when the user decides to visit a given page by
    # clicking in one node of the general tree.
    #
    # It remembers the decision so the user is taken back to a sensible point of
    # the tree (very often the last he decided to visit) after redrawing.
    #
    # @param [CWM::Page] page associated to the tree node
    def go_to_tree_node(page)
      super
      self.candidate_nodes =
        if page.respond_to?(:zone)
          zone_page_candidates(page)
        else
          [page.label]
        end
    end

  protected

    # @see CWM::UIState#textdomain_name
    def textdomain_name
      "firewall"
    end

    # List of candidate nodes to go back after opening a zone view in the tree
    def zone_page_candidates(page)
      zone = page.zone

      [zone.name]
    end
  end
end
