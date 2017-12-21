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

require_relative "../../test_helper.rb"
require "y2firewall/importer"

describe Y2Firewall::Importer do
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

  describe "#strategy_for" do
    context "when the given profile uses a SuSEFirewall2 schema" do
      it "returns Y2Firewall::ImporterStrategies::SuSEFirewall" do
        expect(subject.strategy_for(profile)).to eq(Y2Firewall::ImporterStrategies::SuseFirewall)
      end
    end

    context "when the given profile does not use a SuSEFirewall2 schema" do
      let(:profile) { { "zones" => [{ "name" => "public", "interfaces" => "eth0" }] } }

      it "returns Y2Firewall::ImporterStrategies::Firewalld" do
        expect(subject.strategy_for(profile)).to eq(Y2Firewall::ImporterStrategies::Firewalld)
      end
    end
  end
end
