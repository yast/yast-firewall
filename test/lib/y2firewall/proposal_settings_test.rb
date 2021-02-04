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
require "y2firewall/proposal_settings"

Yast.import "Linuxrc"
Yast.import "ProductFeatures"

describe Y2Firewall::ProposalSettings do
  subject { described_class.create_instance }
  let(:global_section) do
    {
      "enable_firewall"     => false,
      "enable_sshd"         => false,
      "firewall_enable_ssh" => false
    }
  end
  let(:use_vnc) { false }
  let(:use_ssh) { false }
  let(:root_password) { "secret" }

  before do
    allow(Yast::Linuxrc).to receive(:vnc).and_return(use_vnc)
    allow(Yast::Linuxrc).to receive(:usessh).and_return(use_ssh)
    allow(Yast::UsersSimple).to receive(:GetRootPassword).and_return(root_password)

    allow(Yast::ProductFeatures).to receive("GetSection")
      .with("globals").and_return(global_section)
  end

  describe "#initialize" do
    it "loads the default values from the control file" do
      expect_any_instance_of(described_class).to receive(:load_features)

      described_class.create_instance
    end

    it "initializes selinux configuration" do
      expect(subject.selinux_config).to be_a(Y2Security::SelinuxConfig)
    end

    context "when firewall has been enabled in the control file" do
      let(:global_section) { { "enable_firewall" => true, "enable_sshd" => false } }

      it "sets firewalld service to be enabled" do
        expect_any_instance_of(described_class).to receive(:enable_firewall!)

        described_class.create_instance
      end
    end

    context "when ssh has been enable by Linuxrc" do
      let(:use_ssh) { true }

      it "sets ssh service to be enabled" do
        expect_any_instance_of(described_class).to receive(:enable_sshd!)

        described_class.create_instance
      end

      it "sets the ssh port to be opened" do
        expect_any_instance_of(described_class).to receive(:open_ssh!)

        described_class.create_instance
      end
    end

    context "when vnc has been enable by Linuxrc" do
      let(:use_vnc) { true }

      it "sets the vnc port to be opened" do
        expect_any_instance_of(described_class).to receive(:open_vnc!)

        described_class.create_instance
      end
    end

    context "when no root password was set" do
      before do
        allow(Yast::Linuxrc).to receive(:usessh).and_return(false)
        allow(Yast::UsersSimple).to receive(:GetRootPassword)
          .and_return("")
      end

      it "opens SSH to allow public key authentication" do
        expect_any_instance_of(described_class).to receive(:enable_sshd!)
        expect_any_instance_of(described_class).to receive(:open_ssh!)

        described_class.create_instance
      end
    end
  end

  describe "#enable_firewall!" do
    it "sets firewalld service to be enabled" do
      allow(Yast::PackagesProposal).to receive("AddResolvables")
        .with("firewall", :package, ["firewalld"])

      expect(subject.enable_firewall).to be(false)
      subject.enable_firewall!
      expect(subject.enable_firewall).to be(true)
    end

    it "adds the firewalld package to be installed" do
      expect(Yast::PackagesProposal).to receive("AddResolvables")
        .with("firewall", :package, ["firewalld"])

      subject.enable_firewall!
    end
  end

  describe "#disable_firewall!" do
    it "sets firewalld service to be disabled" do
      allow(Yast::PackagesProposal).to receive("RemoveResolvables")
        .with("firewall", :package, ["firewalld"])

      subject.disable_firewall!
      expect(subject.enable_firewall).to be(false)
    end

    it "removes the firewalld package for current selection" do
      expect(Yast::PackagesProposal).to receive("RemoveResolvables")
        .with("firewall", :package, ["firewalld"])

      subject.disable_firewall!
    end
  end

  describe "#enable_sshd!" do
    it "sets sshd service to be enabled" do
      allow(Yast::PackagesProposal).to receive("AddResolvables")
        .with("firewall", :package, ["openssh"])

      subject.enable_sshd!
      expect(subject.enable_sshd).to be(true)
    end

    it "adds the openssh package to be installed" do
      expect(Yast::PackagesProposal).to receive("AddResolvables")
        .with("firewall", :package, ["openssh"])

      subject.enable_sshd!
    end
  end

  describe "#disable_sshd!" do
    it "sets sshd service to be disabled" do
      allow(Yast::PackagesProposal).to receive("RemoveResolvables")
        .with("firewall", :package, ["openssh"])

      subject.disable_sshd!
      expect(subject.enable_sshd).to be(false)
    end

    it "removes the openssh package for current selection" do
      expect(Yast::PackagesProposal).to receive("RemoveResolvables")
        .with("firewall", :package, ["openssh"])

      subject.disable_sshd!
    end
  end

  describe "#open_ssh!" do
    it "sets the ssh port to be opened" do
      subject.open_ssh = false
      subject.open_ssh!
      expect(subject.open_ssh).to be(true)
    end
  end

  describe "#close_ssh!" do
    it "sets the ssh port to be closed" do
      subject.open_ssh = true
      subject.close_ssh!
      expect(subject.open_ssh).to be(false)
    end
  end

  describe "#open_vnc!" do
    it "sets the vnc port to be opened" do
      subject.open_vnc = false
      subject.open_vnc!
      expect(subject.open_vnc).to be(true)
    end
  end

  describe "#close_vnc!" do
    it "sets the vnc port to be closed" do
      subject.open_vnc = true
      subject.close_vnc!
      expect(subject.open_vnc).to be(false)
    end
  end
end
