#!/usr/bin/env rspec
# Copyright (c) [2018] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require_relative "../../test_helper"
require "y2firewall/summary_presenter"
require "y2firewall/firewalld"

describe Y2Firewall::SummaryPresenter do
  subject { described_class.new(firewalld) }
  let(:firewalld) { Y2Firewall::Firewalld.instance }
  let(:external) { Y2Firewall::Firewalld::Zone.new(name: "external") }
  let(:dmz) { Y2Firewall::Firewalld::Zone.new(name: "dmz") }
  let(:home) { Y2Firewall::Firewalld::Zone.new(name: "home") }

  describe "#create" do
    before do
      external.services = ["ssh", "http", "https"]
      external.interfaces = ["eth0", "eth1"]
      external.masquerade = true
      external.target = "default"
      dmz.services = ["ssh", "samba"]
      dmz.interfaces = ["eth2"]
      firewalld.zones = [external, dmz, home]
      firewalld.default_zone = "external"
    end

    it "generates a html summary of the current configuration" do
      expect(subject.create).to include("<b>Default zone:</b> external")
      expect(subject.create).to include("external, dmz, home")
    end

    it "does not show empty zones" do
      expect(subject.create).to include("<h3>dmz</h3>")
      expect(subject.create).to_not include("<h3>home</h3>")
    end
  end

  describe "#not_configured" do
    it "returns a not configured html summary with header" do
      expect(subject.not_configured).to include("Not configured")
        .and include("<h3>Firewall configuration</h3>")
    end
  end

  describe "#not_installed" do
    it "returns a not avialable html summary with header" do
      expect(subject.not_installed).to include("not available")
        .and include("<h3>Firewall configuration</h3>")
    end
  end
end
