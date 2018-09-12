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
require "y2firewall/widgets/interfaces_table"

describe Y2Firewall::Widgets::InterfacesTable do
  subject(:widget) { described_class.new(interfaces) }
  let(:interfaces) do
    [
      { "id" => "eth0", "name" => "Intel Ethernet Connection I217-LM", "zone" => "public" },
      { "id" => "eth1", "name" => "Intel Ethernet Connection I217-LM", "zone" => "external" }
    ]
  end

  include_examples "CWM::Table" 

  describe "#items" do
    it "returns the list of interfaces" do
      expect(widget.items).to eq([
        [Id("eth0"), "eth0", "public", "Intel Ethernet Connection I217-LM"],
        [Id("eth1"), "eth1", "external", "Intel Ethernet Connection I217-LM"]
      ])
    end
  end
end
