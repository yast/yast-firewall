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
    allow(firewalld).to receive(:read)
    allow(subject).to receive(:importer).and_return(importer)
  end

  describe "#summary" do
    it "returns the summary of all the configured zones" do
      expect(firewalld.api).to receive(:list_all_zones).and_return(["zone1", "zone2"])

      expect(subject.summary).to eq("zone1\nzone2")
    end
  end

  describe "#import" do
    let(:arguments) { { "FW_MASQUERADE" => "yes" } }

    it "reads the current firewalld configuration" do
      expect(firewalld).to receive(:read)

      subject.import(arguments)
    end

    it "pass its arguments to the firewalld importer" do
      expect(subject).to receive(:importer).and_return(importer)
      expect(importer).to receive(:import).with(arguments)

      subject.import(arguments)
    end

    it "returns true if import success" do
      expect(subject.import(arguments)).to eq(true)
    end
  end

  describe "#export" do
    it "returns hash with options" do
      expect(subject.export).to be_a(::Hash)
    end
  end

  describe "#reset" do
    it "import empty hash to set defaults" do
      expect(subject).to receive(:importer).and_return(importer)
      expect(importer).to receive(:import).with({})

      subject.reset
    end
  end
end
