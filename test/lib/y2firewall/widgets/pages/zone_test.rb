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

require_relative "../../../../test_helper.rb"
require "cwm/rspec"
require "y2firewall/widgets/pages/zone"

describe Y2Firewall::Widgets::Pages::PortsTab::PortsForProtocols do
  subject { described_class.new(double("fake zone")) }

  describe "#items_from_ui" do
    let(:expected) do
      ["11/tcp", "12/udp", "13/udp"]
    end

    it "parses comma separated items" do
      expect(subject.send(:items_from_ui, "11/tcp,12/udp,13/udp")).to eq(expected)
    end

    it "parses space separated items" do
      expect(subject.send(:items_from_ui, "11/tcp 12/udp 13/udp")).to eq(expected)
    end

    it "parses clumsily separated items" do
      expect(subject.send(:items_from_ui, "11/tcp  12/udp , 13/udp")).to eq(expected)
    end
  end

  let(:ports_h1) { { tcp: ["55555-55666", "44444"], udp: ["33333"] } }
  let(:ports_a1) { ["55555-55666/tcp", "44444/tcp", "33333/udp"] }

  describe "#ports_from_array" do
    it "parses a regular case" do
      expect(subject.send(:ports_from_array, ports_a1)).to eq(ports_h1)
    end
  end

  describe "#ports_to_array" do
    it "formats a regular case" do
      expect(subject.send(:ports_to_array, ports_h1)).to eq(ports_a1)
    end
  end
end
