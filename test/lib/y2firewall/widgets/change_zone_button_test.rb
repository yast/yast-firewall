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
require "y2firewall/widgets/change_zone_button"

describe Y2Firewall::Widgets::ChangeZoneButton do
  include_examples "CWM::PushButton"

  subject(:widget) { described_class.new(eth0) }

  let(:eth0) do
    { "id" => "eth0", "zone" => "public", "name" => "Intel Ethernet Connection I217-LM" }
  end

  let(:result) { :next }

  before do
    allow(Y2Firewall::Dialogs::ChangeZone).to receive(:run).and_return(result)
  end

  describe "#handle" do
    it "selects the current row in the UI state" do
      expect(Y2Firewall::UIState.instance).to receive(:select_row).with("eth0")
      widget.handle
    end

    it "opens a dialog to change the zone" do
      expect(Y2Firewall::Dialogs::ChangeZone).to receive(:run)
      widget.handle
    end

    context "when the dialog is accepted" do
      let(:result) { :next }

      it "returns :redraw in order to redraw the interface" do
        expect(widget.handle).to eq(:redraw)
      end
    end

    context "when the dialog is not accepted" do
      let(:result) { :other }

      it "returns nil" do
        expect(widget.handle).to be_nil
      end
    end
  end
end
