#!/usr/bin/env rspec

require_relative "../../../test_helper"
require "y2firewall/clients/installation_finish"

Yast.import "Service"

describe Y2Firewall::Clients::InstallationFinish do
  describe "#title" do
    it "returns translated string" do
      expect(subject.title).to be_a(::String)
    end
  end

  describe "#modes" do
    it "runs on installation and autoinstallation" do
      expect(subject.modes).to eq([:installation])
    end
  end

  describe "#write" do
    let(:proposal_settings) { Y2Firewall::ProposalSettings.instance }
    let(:api) do
      instance_double(Y2Firewall::Firewalld::Api, remove_service: true, add_service: true)
    end
    let(:firewalld) { Y2Firewall::Firewalld.instance }
    let(:enable_sshd) { false }
    let(:enable_firewall) { false }
    let(:installed) { true }

    before do
      allow(proposal_settings).to receive("enable_sshd").and_return enable_sshd
      allow(proposal_settings).to receive("enable_firewall").and_return enable_firewall
      allow(firewalld).to receive("api").and_return api
      allow(firewalld).to receive("installed?").and_return installed
      allow(proposal_settings).to receive("open_ssh").and_return false
    end

    it "enables the sshd service if enabled in the proposal" do
      allow(proposal_settings).to receive("enable_sshd").and_return(true)
      expect(Yast::Service).to receive(:Enable).with("sshd")

      subject.write
    end

    context "when firewalld is not installed" do
      let(:installed) { false }

      it "returns true" do
        expect(subject.write).to eq true
      end
    end

    context "when firewalld is installed" do
      it "enables the firewalld service if enabled in the proposal" do
        allow(proposal_settings).to receive("enable_firewall").and_return(true)
        expect(firewalld).to receive("enable!")

        subject.write
      end

      it "disables the firewalld service if disabled in the proposal" do
        expect(firewalld).to receive("disable!")

        subject.write
      end

      it "adds the ssh service to the public zone if opened in the proposal" do
        expect(proposal_settings).to receive("open_ssh").and_return(true)
        expect(firewalld.api).to receive(:add_service).with("public", "ssh")

        subject.write
      end

      it "removes the ssh service from the public zone if blocked in the proposal" do
        expect(firewalld.api).to receive(:remove_service).with("public", "ssh")

        subject.write
      end

      it "adds the vnc service to the public zone if opened in the proposal" do
        allow(proposal_settings).to receive("open_vnc").and_return true
        expect(firewalld.api).to receive(:add_service).with("public", "vnc-server")

        subject.write
      end

      it "returns true" do
        expect(subject.write).to eq true
      end
    end

  end
end
