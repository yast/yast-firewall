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

require_relative "../../test_helper"
require "y2firewall/autoyast"

describe Y2Firewall::Autoyast do
  let(:profile) { { "FW_DEV_EXT" => "eth0" } }

  describe "#import" do
    context "when the given profile uses a SuSEFirewall2 schema" do
      it "imports the given profile using the SuSEFirewall strategy" do
        expect(subject).to receive(:strategy_for).with(profile).and_call_original
        expect_any_instance_of(Y2Firewall::ImporterStrategies::SuseFirewall).to receive(:import)

        subject.import(profile)
      end
    end

    context "when the given profile does not use a SuSEFirewall2 schema" do
      let(:profile) { { "zones" => [{ "name" => "public", "interfaces" => "eth0" }] } }

      it "imports the given profile using the Firewalld strategy" do
        expect(subject).to receive(:strategy_for).with(profile).and_call_original
        expect_any_instance_of(Y2Firewall::ImporterStrategies::Firewalld).to receive(:import)

        subject.import(profile)
      end
    end

  end

  describe "#export" do
    let(:zones_definition) do
      ["dmz",
       "  target: default",
       "  interfaces: ",
       "  ports: ",
       "  protocols:",
       "  sources:",
       "",
       "external (active)",
       "  target: default",
       "  interfaces: eth0",
       "  services: ssh samba",
       "  ports: 5901/tcp 5901/udp",
       "  protocols: esp",
       "  sources:"]
    end

    let(:known_zones) { %w[dmz drop external home internal public trusted work] }
    let(:known_services) { %w[http https samba ssh] }

    let(:api) do
      instance_double(Y2Firewall::Firewalld::Api,
        log_denied_packets: "all",
        default_zone:       "work",
        list_all_zones:     zones_definition,
        zones:              known_zones,
        services:           known_services)
    end

    let(:firewalld) { Y2Firewall::Firewalld.instance }

    before do
      firewalld.reset
      allow(firewalld).to receive("api").and_return api
      allow(firewalld).to receive("running?").and_return true
      allow(firewalld).to receive("enabled?").and_return false
      allow(firewalld).to receive("installed?").and_return true
      allow(firewalld).to receive(:modified_from_default).with("zones").and_return(["dmz"])
      firewalld.read
    end

    it "returns a hash with the current firewalld config" do
      config = subject.export

      expect(config).to be_a(Hash)
      expect(config["enable_firewall"]).to eq(false)
      expect(config["start_firewall"]).to eq(true)
      expect(config["log_denied_packets"]).to eq("all")
      expect(config["default_zone"]).to eq("work")

      external = config["zones"].find { |z| z["name"] == "external" }

      expect(external["interfaces"]).to eq(["eth0"])
      expect(external["ports"]).to eq(["5901/tcp", "5901/udp"])
      expect(external["protocols"]).to eq(["esp"])
    end

    it "returned hash is valid for later import" do
      config = subject.export
      expect { subject.import(config) }.to_not raise_error
    end

    context "when 'compact' export is wanted" do
      it "exports only modified zones" do
        config = subject.export(target: "compact")

        expect(config["zones"].size).to eq(1)
        expect(config["zones"].first["name"]) == "dmz"
      end
    end
  end

  describe "#strategy_for" do
    context "when the given profile uses a SuSEFirewall2 schema" do
      it "returns Y2Firewall::ImporterStrategies::SuSEFirewall" do
        expect(subject.send(:strategy_for, profile)).to(
          eq(Y2Firewall::ImporterStrategies::SuseFirewall)
        )
      end
    end

    context "when the given profile does not use a SuSEFirewall2 schema" do
      let(:profile) { { "zones" => [{ "name" => "public", "interfaces" => "eth0" }] } }

      it "returns Y2Firewall::ImporterStrategies::Firewalld" do
        expect(subject.send(:strategy_for, profile)).to(
          eq(Y2Firewall::ImporterStrategies::Firewalld)
        )
      end
    end
  end
end
