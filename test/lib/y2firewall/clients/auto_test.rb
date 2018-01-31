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
    subject.class.imported = false
    allow(firewalld).to receive(:read)
    allow(firewalld).to receive(:installed?).and_return(true)
    allow(subject).to receive(:importer).and_return(importer)
  end

  describe "#summary" do
    it "returns the summary of all the configured zones" do
      expect(firewalld.api).to receive(:list_all_zones).and_return(["zone1", "zone2"])

      expect(subject.summary).to eq("zone1\nzone2")
    end
  end

  describe "#read" do
    it "reads the current firewalld configuration if firewalld is installed" do
      expect(firewalld).to receive(:installed?).and_return(true)
      expect(firewalld).to receive(:read)

      subject.read
    end
  end

  describe "#import" do
    let(:arguments) do
      { "FW_MASQUERADE" => "yes", "enable_firewall" => false, "start_firewall" => false }
    end

    it "reads the current firewalld configuration" do
      expect(firewalld).to receive(:read)

      subject.import(arguments)
    end

    context "when the current configuration was read correctly" do
      before do
        allow(firewalld).to receive(:read).and_return(true)
      end

      it "pass its arguments to the firewalld importer" do
        expect(importer).to receive(:import).with(arguments)

        subject.import(arguments)
      end

      it "returns true if import success" do
        expect(subject.import(arguments)).to eq(true)
      end

      it "marks the importation as done" do
        subject.import(arguments)
        expect(subject.class.imported).to eq(true)
      end
    end

    context "when the current configuration was not read" do
      it "returns false" do
        expect(firewalld).to receive(:read).and_return(false)
        expect(subject.import(arguments)).to eq(false)
      end

      it "does not mark the importation as done or completed" do
        expect(firewalld).to receive(:read).and_return(false)
        subject.import(arguments)
        expect(subject.class.imported).to eq(false)
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
    it "import empty hash to set defaults" do
      expect(importer).to receive(:import).with({})

      subject.reset
    end
  end

  describe "#write" do
    let(:arguments) do
      { "FW_MASQUERADE" => "yes", "enable_firewall" => false, "start_firewall" => false }
    end

    it "returns false if firewalld is not installed" do
      expect(firewalld).to receive(:installed?).and_return(false)

      expect(subject.write).to eq(false)
    end

    it "tries to import again the profile if it was not imported" do
      allow(subject.class).to receive(:profile).and_return(arguments)
      expect(subject).to receive(:import).with(arguments).and_return(false)

      subject.write
    end

    it "writes the imported configuration" do
      allow(subject.class).to receive(:imported).and_return(true)
      allow(subject).to receive(:activate_service)
      expect(firewalld).to receive(:write)

      subject.write
    end

    it "activates or deactives the firewalld service based on the profile" do
      allow(subject.class).to receive(:imported).and_return(true)
      expect(firewalld).to receive(:write)
      expect(subject).to receive(:activate_service)

      subject.write
    end
  end
end
