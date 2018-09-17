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
require "y2firewall/dialogs/change_zone"

describe Y2Firewall::Dialogs::ChangeZone do
  include_examples "CWM::Dialog"

  subject(:widget) { described_class.new(eth0) }

  let(:eth0) do
    { "id" => "eth0", "zone" => "public", "name" => "Intel Ethernet Connection I217-LM" }
  end

  let(:public_zone) do
    instance_double(Y2Firewall::Firewalld::Zone, interfaces: [], remove_interface: nil)
  end

  describe "#selected_zone" do
    let(:zone_options) do
      instance_double(Y2Firewall::Widgets::ZoneOptions, value: zone_name)
    end

    before do
      allow(Y2Firewall::Firewalld.instance).to receive(:find_zone).with("public")
        .and_return(public_zone)
      allow(Y2Firewall::Widgets::ZoneOptions).to receive(:new)
        .and_return(zone_options)
    end

    context "when a zone was selected" do
      let(:zone_name) { "public" }

      it "returns the selected zone" do
        expect(widget.selected_zone).to eq(public_zone)
      end
    end

    context "when no zone is selected" do
      let(:zone_name) { "" }

      it "returns true" do
        expect(widget.selected_zone).to be_nil
      end
    end
  end

  describe "#next_handler" do
    let(:dmz_zone) do
      instance_double(Y2Firewall::Firewalld::Zone, interfaces: [eth0], remove_interface: nil)
    end

    before do
      allow(Y2Firewall::Firewalld.instance).to receive(:zones).and_return([public_zone, dmz_zone])
      allow(widget).to receive(:selected_zone).and_return(public_zone)
    end

    context "when the interface is assigned to a different zone" do
      before do
        allow(public_zone).to receive(:add_interface)
      end

      it "assigns the interface to the selected zone" do
        expect(public_zone).to receive(:add_interface).with("eth0")
        widget.next_handler
      end

      it "removes the interface from any other zone" do
        expect(dmz_zone).to receive(:remove_interface).with("eth0")
        widget.next_handler
      end
    end

    context "when the interface already belongs to the selected zone" do
      before do
        allow(public_zone).to receive(:interfaces).and_return(["eth0"])
      end

      it "does not modify the zone" do
        expect(dmz_zone).to_not receive(:remove_interface)
        expect(public_zone).to_not receive(:add_interface)
        widget.next_handler
      end
    end

    context "when the interface is assigned to the default zone" do
      before do
        allow(widget).to receive(:selected_zone).and_return(nil)
      end

      it "removes the interface from all zones" do
        expect(dmz_zone).to receive(:remove_interface).with("eth0")
        expect(public_zone).to_not receive(:add_interface)
        widget.next_handler
      end
    end
  end
end
