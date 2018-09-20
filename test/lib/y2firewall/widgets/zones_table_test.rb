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
require "y2firewall/widgets/zones_table"
require "y2firewall/widgets/default_zone_button"
require "y2firewall/firewalld/interface"

describe Y2Firewall::Widgets::ZonesTable do
  subject(:widget) { described_class.new([public_zone, dmz_zone], default_zone_button) }

  let(:default_zone_button) do
    instance_double(Y2Firewall::Widgets::DefaultZoneButton).as_null_object
  end

  let(:public_zone) do
    instance_double(Y2Firewall::Firewalld::Zone, name: "public", interfaces: ["eth0", "eth1"])
  end

  let(:dmz_zone) do
    instance_double(Y2Firewall::Firewalld::Zone, name: "dmz", interfaces: [])
  end

  before do
    allow(Y2Firewall::Firewalld.instance).to receive(:default_zone).and_return(public_zone.name)
  end

  include_examples "CWM::Table"

  describe "#items" do
    it "returns the list of zones" do
      expect(widget.items).to eq(
        [
          [:public, "public", "eth0, eth1", Yast::UI.Glyph(:CheckMark)],
          [:dmz, "dmz", "", ""]
        ]
      )
    end
  end
end
