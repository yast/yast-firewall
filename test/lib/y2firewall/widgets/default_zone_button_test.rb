#!/usr/bin/env rspec
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
require "y2firewall/widgets/default_zone_button"

describe Y2Firewall::Widgets::DefaultZoneButton do
  include_examples "CWM::PushButton"

  subject(:widget) { described_class.new(zone) }

  let(:zone) do
    instance_double(
      Y2Firewall::Firewalld::Zone, name: "public", interfaces: [], remove_interface: nil
    )
  end

  describe "#zone=" do
    before do
      allow(Y2Firewall::Firewalld.instance).to receive(:default_zone).and_return(zone.name)
    end

    let(:other_zone) do
      instance_double(Y2Firewall::Firewalld::Zone, name: "dmz")
    end

    it "sets the given zone as the one to act on" do
      expect { widget.zone = other_zone }.to change { widget.zone }.to other_zone
    end

    context "when the given zone is not the default one" do
      let(:default_zone) { other_zone }

      it "enables the button" do
        expect(widget).to receive(:enable)
        widget.zone = other_zone
      end
    end

    context "when the given zone is the default one" do
      it "disables the button" do
        expect(widget).to receive(:disable)
        widget.zone = zone
      end
    end
  end

  describe "#handle" do
    before do
      allow(Y2Firewall::Firewalld.instance).to receive(:default_zone=)
    end

    it "sets the current zone as the default one" do
      expect(Y2Firewall::Firewalld.instance).to receive(:default_zone=).with(zone.name)
      widget.handle
    end

    it "returns :redraw in order to redraw the interface" do
      expect(widget.handle).to eq(:redraw)
    end
  end

  describe "#zone"
end
