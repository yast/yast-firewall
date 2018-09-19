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
require "y2firewall/widgets/zone_options"
require "y2firewall/firewalld/interface"

describe Y2Firewall::Widgets::ZoneOptions do
  include_examples "CWM::ComboBox"

  subject(:widget) { described_class.new(eth0) }

  let(:eth0) { Y2Firewall::Firewalld::Interface.new("eth0") }

  let(:public_zone) do
    instance_double(
      Y2Firewall::Firewalld::Zone, name: "public", interfaces: [], remove_interface: nil
    )
  end

  let(:dmz_zone) do
    instance_double(
      Y2Firewall::Firewalld::Zone, name: "dmz", interfaces: [eth0], remove_interface: nil
    )
  end

  before do
    allow(eth0).to receive(:zone).and_return(dmz_zone)
  end

  describe "#init" do
    it "sets the current value to the zone for the given zone" do
      expect(widget).to receive(:value=).with("dmz")
      widget.init
    end
  end

  describe "#items" do
    before do
      allow(Y2Firewall::Firewalld.instance).to receive(:zones).and_return([public_zone, dmz_zone])
    end

    it "returns a list of selectable items including all known zones" do
      expect(widget.items).to eq(
        [
          ["", "default"],
          ["public", "public"],
          ["dmz", "dmz"]
        ]
      )
    end
  end

  describe "#store" do
    before do
      allow(Y2Firewall::Firewalld.instance).to receive(:zones).and_return([public_zone, dmz_zone])
      #allow(widget).to receive(:selected_zone).and_return(public_zone)
      allow(widget).to receive(:value).and_return(public_zone.name)
    end

    context "when the interface is assigned to a different zone" do
      before do
        allow(public_zone).to receive(:add_interface)
      end

      it "assigns the interface to the selected zone" do
        expect(public_zone).to receive(:add_interface).with("eth0")
        widget.store
      end

      it "removes the interface from any other zone" do
        expect(dmz_zone).to receive(:remove_interface).with("eth0")
        widget.store
      end
    end

    context "when the interface already belongs to the selected zone" do
      before do
        allow(public_zone).to receive(:interfaces).and_return(["eth0"])
      end

      it "does not modify the zone" do
        expect(dmz_zone).to_not receive(:remove_interface)
        expect(public_zone).to_not receive(:add_interface)
        widget.store
      end
    end
  end
end
