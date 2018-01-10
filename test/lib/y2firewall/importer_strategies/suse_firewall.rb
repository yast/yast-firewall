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
require "y2firewall/importer_strategies/suse_firewall"

describe Y2Firewall::ImporterStrategies::SuseFirewall do
  let(:firewalld) { Y2Firewall::Firewalld.instance }
  let(:known_zones) { Y2Firewall::Firewalld::Zone.known_zones.keys }
  let(:empty_zones) { known_zones.map { |name| Y2Firewall::Firewalld::Zone.new(name: name) } }
  let(:masquerade) { "yes" }

  before do
    firewalld.zones = empty_zones
  end

  describe "#import" do
    subject { described_class.new(profile) }

    let(:profile) do
      {
        "FW_DEV_EXT"            => "eth0",
        "FW_DEV_INT"            => "eth1",
        "FW_DEV_DMZ"            => "eth2 any",
        "FW_CONFIGURATIONS_EXT" => "dhcp-server sshd netbios-server vnc-server",
        "FW_SERVICES_EXT_TCP"   => "80 443",
        "FW_SERVICES_EXT_IP"    => "esp",
        "FW_MASQUERADE"         => masquerade
      }
    end

    context "when the profile is empty" do
      let(:profile) { {} }

      it "returns true" do
        expect(subject.import).to eq(true)
      end
    end

    context "when the profile is not empty" do
      before do
        subject.import
      end

      it "configures the INT zone as the trusted" do
        trusted = firewalld.find_zone("trusted")

        expect(trusted.interfaces).to eq(["eth1"])
      end

      it "configures the DMZ zone as the dmz" do
        dmz = firewalld.find_zone("dmz")

        expect(dmz.interfaces).to eq(["eth2"])
      end

      it "sets the default zone as the one with the 'any' interface" do
        expect(firewalld.default_zone).to eql("dmz")
      end

      context "and masquerade is disabled" do
        let(:masquerade) { "no" }

        it "configures the EXT zone as the public" do
          public_zone = firewalld.find_zone("public")

          expect(public_zone.interfaces).to eq(["eth0"])
          expect(public_zone.services).to eq(["dhcp", "ssh", "samba", "vnc-server"])
          expect(public_zone.protocols).to eq(["esp"])
        end
      end

      context "and masquerade is enabled" do
        it "configures the EXT zone as the external" do
          external = firewalld.find_zone("external")

          expect(external.services).to eq(["dhcp", "ssh", "samba", "vnc-server"])
        end
      end
    end
  end
end
