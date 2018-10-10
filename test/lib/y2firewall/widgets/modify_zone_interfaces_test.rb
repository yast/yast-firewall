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

require_relative "../../../test_helper"

require "cwm/rspec"
require "y2firewall/widgets/modify_zone_interfaces"

describe Y2Firewall::Widgets::ZoneInterfacesSelector do
  include_examples "CWM::ComboBox"

  subject { described_class.new(interfaces_input) }
  let(:interfaces_input) { Y2Firewall::Widgets::ZoneInterfaces.new }
  let(:firewalld) { Y2Firewall::Firewalld.instance }
  let(:public_zone) do
    instance_double(
      Y2Firewall::Firewalld::Zone, interfaces: ["eth0", "eth1", "wlan0"], name: "public"
    )
  end

  let(:dmz_zone) do
    instance_double(Y2Firewall::Firewalld::Zone, interfaces: ["eth2"], name: "dmz")
  end

  before do
    firewalld.default_zone = "public"
    firewalld.zones = [public_zone, dmz_zone]
  end

  describe "#init" do
    it "selects the default zone as the current selection" do
      expect(subject).to receive(:value=).with("public")
      subject.init
    end

    it "fills the interfaces input field with the default zone interfaces" do
      allow(subject).to receive(:value).and_return("public")
      expect(interfaces_input).to receive(:value=).with("eth0 eth1 wlan0")
      subject.init
    end

    it "fills the interfaces input field with an empty string if there is no default zone" do
      allow(subject).to receive(:value).and_return(nil)
      expect(interfaces_input).to receive(:value=).with("")
      subject.init
    end
  end

  describe "#handle" do
    it "fills the interfaces input field with the selected zone interfaces" do
      allow(subject).to receive(:value).and_return("dmz")
      expect(interfaces_input).to receive(:value=).with("eth2")
      subject.handle
      allow(subject).to receive(:value).and_return("public")
      expect(interfaces_input).to receive(:value=).with("eth0 eth1 wlan0")
      subject.handle
    end
  end

  describe "#store" do
    it "modifies the selected zone interfaces with the interfaces input" do
      allow(subject).to receive(:value).and_return("dmz")
      allow(interfaces_input).to receive(:value).and_return("eth0, eth1")
      expect(dmz_zone).to receive(:interfaces=).with(["eth0", "eth1"])

      subject.store
    end
  end
end

describe Y2Firewall::Widgets::ZoneInterfaces do
  include_examples "CWM::AbstractWidget"

  describe "#items_from_ui" do
    let(:expected) { ["eth0", "eth1", "eth2"] }

    it "parses comma separated items" do
      allow(subject).to receive(:value).and_return("eth0,eth1,eth2")

      expect(subject.items_from_ui).to eq(expected)
    end

    it "parses space separated items" do
      allow(subject).to receive(:value).and_return("eth0 eth1 eth2")

      expect(subject.items_from_ui).to eq(expected)
    end

    it "parses clumsily separated items" do
      allow(subject).to receive(:value).and_return("eth0  eth1 , eth2")
      expect(subject.items_from_ui).to eq(expected)
    end
  end
end
