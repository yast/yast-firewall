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
require "y2firewall/widgets/change_zone_button"

describe Y2Firewall::Widgets::InterfacesTable do
  subject(:widget) { described_class.new(interfaces, change_zone_button) }

  let(:eth0) do
    { "id" => "eth0", "name" => "Intel Ethernet Connection I217-LM", "zone" => "public" }
  end

  let(:eth1) do
    { "id" => "eth1", "name" => "Intel Ethernet Connection I217-LM", "zone" => nil }
  end

  let(:interfaces) { [eth0, eth1] }

  let(:change_zone_button) do
    instance_double(Y2Firewall::Widgets::ChangeZoneButton, :interface= => nil)
  end

  include_examples "CWM::Table"

  describe "#items" do
    it "returns the list of interfaces" do
      expect(widget.items).to eq(
        [
          [:eth0, "eth0", "public", "Intel Ethernet Connection I217-LM"],
          [:eth1, "eth1", "default", "Intel Ethernet Connection I217-LM"]
        ]
      )
    end
  end

  describe "#init" do
    before do
      allow(Y2Firewall::UIState.instance).to receive(:row_id).and_return(row_id)
      allow(widget).to receive(:value).and_return(nil)
    end

    context "when no row has been visited previously" do
      let(:row_id) { nil }

      it "does not select any specific row" do
        expect(widget).to_not receive(:value=)
        widget.init
      end
    end

    context "when a row has been visited" do
      let(:row_id) { :eth0 }

      it "does selects the visited row" do
        expect(widget).to receive(:value=).with(:eth0)
        widget.init
      end
    end
  end

  describe "#handle" do
    context "when the selection is changed" do
      let(:event) { { "EventReason" => "SelectionChanged" } }

      before do
        allow(widget).to receive(:value).and_return(:eth1)
      end

      it "selects the current row in the UI state" do
        expect(Y2Firewall::UIState.instance).to receive(:select_row).with(:eth1)
        widget.handle(event)
      end

      it "updates the button to change the assigned zone" do
        expect(change_zone_button).to receive(:interface=).with(eth1)
        widget.handle(event)
      end
    end

    context "when the selection is not changed" do
      let(:event) { { "EventReason" => "Whatever" } }

      it "does not select the current row in the UI state" do
        expect(Y2Firewall::UIState.instance).to_not receive(:select_row)
        widget.handle(event)
      end
    end
  end

  describe "#selected_interface"
end
