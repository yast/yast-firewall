#!/usr/bin/env rspec
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

require_relative "../../../test_helper.rb"
require "cwm/rspec"
require "y2firewall/widgets/overview_tree"
require "cwm/tree_pager"

describe Y2Firewall::Widgets::OverviewTree do
  include_examples "CWM::CustomWidget"

  subject(:widget) { described_class.new([]) }

  describe "#items" do
    subject(:widget) { described_class.new([tree_item1, tree_item2]) }

    let(:tree_item1) { instance_double(CWM::PagerTreeItem) }
    let(:tree_item2) { instance_double(CWM::PagerTreeItem) }

    it "returns the list of included items" do
      expect(widget.items).to eq([tree_item1, tree_item2])
    end
  end
end
