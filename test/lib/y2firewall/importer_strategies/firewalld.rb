#!/usr/bin/env rspec

# ------------------------------------------------------------------------------
# Copyright (c) 2017 SUSE LLC
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
require "y2firewall/importer_strategies/firewalld"

describe Y2Firewall::ImporterStrategies::Firewalld do
  let(:firewalld) { Y2Firewall::Firewalld.instance }
  let(:known_zones) { Y2Firewall::Firewalld::Zone.known_zones.keys }
  let(:empty_zones) { known_zones.map { |name| Y2Firewall::Firewalld::Zone.new(name: name) } }

  before do
    firewalld.zones = empty_zones
  end

  describe "#import" do
    subject { described_class.new(profile) }

    let(:profile) do
      {
        "default_zone" => "dmz",
        "zones"        => [
          { "name" => "dmz", "interfaces" => ["eth0.12"], "services" => ["samba"] },
          { "name" => "external", "interfaces" => ["eth0"], "services" => ["dhcp"] },
          { "name" => "internal", "interfaces" => ["eth1"], "protocols" => ["icmp"] }
        ]
      }
    end

    context "when the profile is empty" do
      let(:profile) { {} }

      it "returns true" do
        expect(subject.import).to eq(true)
      end
    end

    context "when the profile is not empty" do
      it "configures the zones according to the profile" do
        subject.import

        dmz      = firewalld.find_zone("dmz")
        external = firewalld.find_zone("external")
        internal = firewalld.find_zone("internal")

        expect(dmz.interfaces).to eq(["eth0.12"])
        expect(external.interfaces).to eq(["eth0"])
        expect(internal.interfaces).to eq(["eth1"])
        expect(external.services).to eq(["dhcp"])
        expect(internal.protocols).to eq(["icmp"])
        expect(firewalld.default_zone).to eq("dmz")
      end
    end
  end
end
