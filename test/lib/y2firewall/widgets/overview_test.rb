#!/usr/bin/env rspec

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

require_relative "../../../test_helper.rb"
require "cwm/rspec"
require "y2firewall/widgets/overview"

RSpec.shared_examples "CWM::Tree" do
  include_examples "CWM::CustomWidget"
end

RSpec.shared_examples "CWM::TreePager" do
  include_examples "CWM::Pager"
end

describe Y2Firewall::Widgets::OverviewTreePager do
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

  include_examples "CWM::TreePager"
end

describe Y2Firewall::Widgets::OverviewTree do
  subject { described_class.new([]) }
  include_examples "CWM::Tree"
end
