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

require_relative "../../../../test_helper.rb"
require "cwm/rspec"
require "y2firewall/widgets/pages/interfaces"

describe Y2Firewall::Widgets::Pages::Interfaces do
  subject(:widget) { described_class.new(double("fake pager")) }

  include_examples "CWM::Page"

  describe "#contents" do
    let(:interfaces) do
      [{ "id" => "eth0", "name" => "Intel Corporation" }]
    end

    before do
      allow(widget).to receive(:known_interfaces).and_return(interfaces)
    end

    it "builds a interfaces table containing known interfaces" do
      expect(Y2Firewall::Widgets::InterfacesTable).to receive(:new)
        .with(interfaces, Y2Firewall::Widgets::ChangeZoneButton)
      widget.contents
    end
  end
end
