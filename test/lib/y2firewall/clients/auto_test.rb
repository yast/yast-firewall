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

require_relative "../../../test_helper"
require "y2firewall/clients/auto"

describe Y2Firewall::Clients::Auto do
  let(:firewalld) { Y2Firewall::Firewalld.instance }
  let(:importer) { double("Y2Firewall::Importer", import: true) }

  before do
    allow_any_instance_of(Y2Firewall::Firewalld::Api).to receive(:running?).and_return(false)
    subject.class.imported = false
    allow(firewalld).to receive(:read)
    allow(firewalld).to receive(:installed?).and_return(true)
    allow(subject).to receive(:importer).and_return(importer)
  end

  describe "#summary" do
    let(:installed) { false }

    before do
      allow(firewalld).to receive(:installed?).and_return(installed)
    end

    context "when firewalld is not installed" do
      it "reports when firewalld is not available" do
        expect(subject.summary).to match(/not available/)
      end
    end

    context "when firewalld is installed" do
      let(:installed) { true }
      let(:relations_stub) do
        {
          interfaces: ["eth0", "eth1"],
          services:   ["ssh", "ftp"],
          protocols:  ["udp", "tcp"],
          ports:      ["80"]
        }
      end

      context "but no modified yet" do
        it "reports a not configured summary" do
          firewalld.reset
          expect(subject.summary).to match(/Not configured/)
        end
      end

      context "and the configuration has been modified" do
        before do
          zones = []
          relations_stub.each_pair do |relation, values|
            zone = Y2Firewall::Firewalld::Zone.new(name: "zone_#{relation}")
            allow(zone).to receive(relation).and_return(values)
            zones << zone
          end
          firewalld.zones = zones
          subject.modified
        end

        it "builds a summary" do
          summary = subject.summary

          # general stuff
          expect(summary).to match(/Default zone/)
          expect(summary).to match(/Defined zones/)

          # zone details
          relations_stub.each_pair do |_relation, values|
            values.each { |value| expect(summary).to match(/#{value}/) }
          end
        end
      end
    end
  end

  describe "#read" do
    before do
      allow(firewalld).to receive(:installed?).and_return(true)
    end

    it "returns false if firewalld is not installed" do
      allow(firewalld).to receive(:installed?).and_return(false)
      expect(subject.read).to eql(false)
    end

    context "when a force read is required" do
      it "always reads the current configuration" do
        expect(firewalld).to receive(:read)

        subject.read
      end
    end

    context "when a read is not forced" do
      it "only reads the current configuration if has not beenn read before" do
        expect(firewalld).to receive(:read?).and_return(true, false)
        expect(firewalld).to receive(:read)
        subject.read(force: false)
        expect(firewalld).to_not receive(:read)
        subject.read(force: false)
      end
    end
  end

  describe "#import" do
    let(:i_list) { double("IssuesList", add: nil) }
    let(:read?) { false }

    let(:arguments) do
      { "FW_MASQUERADE"   => "yes",
        "enable_firewall" => false,
        "start_firewall"  => false }
    end

    before do
      allow(subject).to receive(:read).and_return(read?)
      allow(Yast::AutoInstall).to receive(:issues_list).and_return(i_list)
    end

    it "saves the profile being imported for reusing it if needed" do
      subject.class.profile = nil
      subject.import(arguments, true)
      expect(subject.class.profile).to eq(arguments)
    end

    context "when a merge with the current configuration is requested" do
      it "reads the current configuration if has not been read before" do
        expect(subject).to receive(:read).and_return(read?)
        subject.import(arguments, true)
      end

      context "and the read fails" do
        it "returns false" do
          expect(subject).to receive(:read).and_return(read?)
          expect(subject.import(arguments, true)).to eql(false)
        end

        it "does not mark the importation as done or completed" do
          expect(subject).to receive(:read).and_return(read?)
          subject.import(arguments, true)
          expect(subject.class.imported).to eq(false)
        end
      end
    end

    context "when a merge is not requested" do
      it "does not read the current firewalld configuration" do
        expect(subject).to_not receive(:read)

        subject.import(arguments, false)
      end
    end

    context "once the current configuration has been set" do
      it "imports the given profile" do
        expect(importer).to receive(:import).with(arguments)

        subject.import(arguments, false)
      end

      it "returns true if import success" do
        expect(subject.import(arguments, false)).to eq(true)
      end

      it "marks the importation as done" do
        subject.import(arguments, false)
        expect(subject.class.imported).to eq(true)
      end

      it "reports that an interface has been defined twice in zones" do
        expect(firewalld).to receive(:export)
          .and_return("zones" => [{ "interfaces" => ["eth0"], "name" => "public" },
                                  { "interfaces" => ["eth0", "eth0"], "name" => "trusted" }])
        expect(i_list).to receive(:add)
          .with(:invalid_value, "firewall", "interfaces",
            "eth0",
            "This interface has been defined for more than one zone.")
        subject.import(arguments, false)
      end
    end
  end

  describe "#export" do
    before do
      allow(firewalld).to receive(:export)
        .and_return("zones" => {}, "default_zone" => "public", "log_denied_packets" => "unicast")
    end

    it "returns hash with options" do
      expect(subject.export).to be_a(::Hash)
    end
  end

  describe "#reset" do
    let(:arguments) do
      {
        "default_zone"       => "dmz",
        "log_denied_packets" => "unicast",
        "zones"              => [{ "name" => "external", "interfaces" => ["eth0", "eth2"] }]
      }
    end

    it "resets the firewalld current configuration to the defaults" do
      subject.import(arguments, false)
      firewalld.default_zone = "dmz"
      subject.reset
      expect(firewalld.default_zone).to eq("public")
      expect(firewalld.zones).to be_empty
    end
  end

  describe "#write" do
    let(:arguments) do
      { "FW_MASQUERADE" => "yes", "enable_firewall" => false, "start_firewall" => false }
    end

    let(:known_zones) { %w(dmz external) }
    let(:known_services) { %w(http https samba ssh) }

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
       "  protocols:",
       "  sources:"]
    end

    let(:api) do
      instance_double(Y2Firewall::Firewalld::Api,
        log_denied_packets: "off",
        default_zone:       "dmz",
        list_all_zones:     zones_definition,
        zones:              known_zones,
        services:           known_services)
    end

    it "returns false if firewalld is not installed" do
      expect(firewalld).to receive(:installed?).and_return(false)

      expect(subject.write).to eq(false)
    end

    it "tries to import again the profile if needed" do
      allow(subject.class).to receive(:profile).and_return(arguments)
      expect(subject).to receive(:import).with(arguments).and_return(false)

      subject.write
    end

    it "writes the imported configuration" do
      firewalld.default_zone = "drop"
      allow(subject).to receive(:imported?).and_return(true)
      allow(subject).to receive(:activate_service)
      allow(subject).to receive(:import_if_needed)
      expect(firewalld).to receive(:write)

      subject.write
    end

    context "when the write is called from the AutoYaST configuration" do
      before do
        allow(firewalld).to receive("api").and_return api
        allow(firewalld).to receive(:write)
        allow(firewalld).to receive(:running?)
        allow(firewalld).to receive(:enabled?)
      end

      it "maintains the same configuration than before the write" do
        subject.class.ay_config = true
        firewalld.default_zone = "dmz"
        firewalld.zones = []
        expect(subject).to receive(:read).and_call_original
        subject.write
        expect(firewalld.default_zone).to eql("dmz")
        expect(firewalld.zones).to be_empty
      end
    end

    context "when the writes is not called from the AutoYaST configuration" do
      it "activates or deactives the firewalld service based on the profile" do
        subject.class.ay_config = nil
        allow(subject.class).to receive(:imported).and_return(true)
        expect(firewalld).to receive(:write)
        expect(subject).to receive(:activate_service)

        subject.write
      end
    end
  end
end
