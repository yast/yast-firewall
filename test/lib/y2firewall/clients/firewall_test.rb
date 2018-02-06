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

Yast.import "CommandLine"

describe Y2Firewall::Clients::Firewall do
  describe "#run" do
    context "when the client is called with some argument" do
      before do
        allow(Yast::WFM).to receive("Args").and_return(["list"])
      end

      it "returns false" do

        expect(subject.run).to eql(false)
      end
    end

    context "when the client is called without arguments" do
      before do
        allow(Yast::WFM).to receive("Args").and_return([])
        allow(Yast::UI).to receive("TextMode").and_return false
      end

      context "and it is called in TextMode" do
        before do
          allow(Yast::UI).to receive("TextMode").and_return true
        end

        it "reports an error" do
          expect(Yast::Popup).to receive("Error")

          subject.run
        end

        it "returns false" do
          allow(Yast::Popup).to receive("Error")

          expect(subject.run).to eq(false)
        end
      end

      context "and the firewall-config package is installed" do
        before do
          allow(Yast::PackageSystem).to receive("CheckAndInstallPackages")
            .with(["firewall-config"]).and_return(true)
        end

        it "runs the firewall-config gui" do
          expect(Yast::Execute).to receive("locally").with("/usr/bin/firewall-config")

          subject.run
        end
      end
    end
  end
end
