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
require "y2firewall/clients/firewall"

describe Y2Firewall::Clients::Firewall do
  describe "#run" do
    let(:installed) { true }
    let(:args) { [] }
    before do
      allow(Yast::Package).to receive("CheckAndInstallPackages")
        .with(["firewalld"]).and_return(installed)
      allow(Yast::WFM).to receive("Args").and_return(args)
      allow(subject).to receive(:warn)
    end

    context "when the firewalld package is not installed" do
      let(:installed) { false }
      it "returns :abort" do
        expect(subject.run).to eql(:abort)
      end
    end

    context "when the client is called with some argument" do
      let(:args) { ["list"] }

      it "recommends to use the firewalld cmdline clients" do
        expect(subject).to receive(:warn).with(Y2Firewall::Clients::Firewall::NOT_SUPPORTED)

        subject.run
      end

      it "returns false" do
        expect(subject.run).to eql(false)
      end
    end

    context "when the client is called without arguments" do
      let(:main_dialog) { instance_double("Y2Firewall:::Dialogs::Main", run: true) }

      it "runs the Main dialog" do
        expect(Y2Firewall::Dialogs::Main).to receive(:new).and_return(main_dialog)
        expect(main_dialog).to receive(:run)

        subject.run
      end
    end
  end
end
