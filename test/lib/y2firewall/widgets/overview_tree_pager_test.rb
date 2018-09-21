#!/usr/bin/env rspec
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

require_relative "../../../test_helper.rb"
require "cwm/rspec"
require "y2firewall/widgets/overview_tree_pager"
require "y2firewall/widgets/pages"

RSpec.shared_examples "CWM::TreePager" do
  include_examples "CWM::Pager"
end

describe Y2Firewall::Widgets::OverviewTreePager do
  let(:widget) { described_class.new }

  before do
    fw = double("fake firewall")
    z1 = double(name: "air")
    allow(Y2Firewall::Firewalld).to receive(:instance).and_return(fw)
    allow(fw).to receive(:zones).and_return([z1])

    if1 = {
      "id"   => "eth0",
      "name" => "Intel Ethernet Connection I217-LM",
      "zone" => "external"
    }
    allow_any_instance_of(Y2Firewall::Helpers::Interfaces)
      .to receive(:known_interfaces).and_return([if1])

    startup_page = double("fake page", widget_id: "fake", label: "f", initial: false)
    allow(Y2Firewall::Widgets::Pages::Startup)
      .to receive(:new)
      .and_return startup_page
  end

  describe "#initial_page" do
    it "navigates to the page stored in the UIState instance" do
      expect(Y2Firewall::UIState.instance).to receive(:find_tree_node)
      widget.initial_page
    end
  end

  describe "#switch_page" do
    let(:page) { double("zones page", widget_id: "zones", label: "z", initial: false) }

    it "registers the page in the UIState instance" do
      expect(Y2Firewall::UIState.instance).to receive(:go_to_tree_node).with(page)
      widget.switch_page(page)
    end
  end

  include_examples "CWM::TreePager"
end
