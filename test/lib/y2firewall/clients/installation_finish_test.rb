#!/usr/bin/env rspec

require_relative "../../../test_helper"
require "y2firewall/clients/installation_finish"

Yast.import "Service"

describe Y2Firewall::Clients::InstallationFinish do
  before do
    allow_any_instance_of(Y2Firewall::Firewalld::Api).to receive(:running?).and_return(false)
    allow(Y2Security::SelinuxConfig).to receive(:new).and_return(selinux_config)
  end

  let(:proposal_settings) { Y2Firewall::ProposalSettings.instance }
  let(:firewalld) { Y2Firewall::Firewalld.instance }
  let(:selinux_config) { double("SelinuxConfig", save: true, configurable?: true) }

  describe "#title" do
    it "returns translated string" do
      expect(subject.title).to be_a(::String)
    end
  end

  describe "#modes" do
    it "runs on installation and autoinstallation" do
      expect(subject.modes).to eq([:installation, :autoinst])
    end
  end

  describe "#write" do
    let(:enable_sshd) { false }
    let(:installed) { true }

    before do
      allow(proposal_settings).to receive(:enable_sshd).and_return(enable_sshd)
      allow(firewalld).to receive(:installed?).and_return(installed)
      allow(proposal_settings).to receive(:open_ssh).and_return(false)
      allow(proposal_settings).to receive(:selinux_config).and_return(selinux_config)
    end

    it "enables the sshd service if enabled in the proposal" do
      allow(proposal_settings).to receive(:enable_sshd).and_return(true)
      expect(Yast::Service).to receive(:Enable).with("sshd")

      subject.write
    end

    it "saves selinux policy" do
      expect(proposal_settings.selinux_config).to receive(:save)

      subject.write
    end

    context "when firewalld is not installed" do
      let(:installed) { false }

      it "returns true" do
        expect(subject).to_not receive(:configure_firewall)
        expect(subject.write).to eq true
      end
    end

    context "when firewalld is installed" do
      it "configures the firewall according to the proposal settings" do
        expect(subject).to receive(:configure_firewall)

        subject.write
      end

      it "returns true" do
        expect(subject.write).to eq true
      end
    end
  end

  describe "#configure_firewall" do
    let(:enable_firewall) { false }
    let(:api) do
      instance_double(Y2Firewall::Firewalld::Api, remove_service: true, add_service: true)
    end
    let(:installation) { true }

    before do
      allow(proposal_settings).to receive(:enable_firewall).and_return(enable_firewall)
      allow(firewalld).to receive(:api).and_return(api)
      allow(firewalld).to receive(:enable!)
      allow(firewalld).to receive(:disable!)
      allow(Yast::Mode).to receive(:installation).and_return(installation)
      allow(proposal_settings).to receive(:open_ssh).and_return(false)
    end

    context "during an installation" do
      it "enables the firewalld service if enabled in the proposal" do
        allow(proposal_settings).to receive(:enable_firewall).and_return(true)
        expect(firewalld).to receive(:enable!)

        subject.send(:configure_firewall)
      end

      it "disables the firewalld service if disabled in the proposal" do
        expect(firewalld).to receive(:disable!)

        subject.send(:configure_firewall)
      end
    end

    it "adds the ssh service to the default zone if opened in the proposal" do
      expect(proposal_settings).to receive(:open_ssh).and_return(true)
      expect(api).to receive(:add_service).with(proposal_settings.default_zone, "ssh")

      subject.send(:configure_firewall)
    end

    it "removes the ssh service from the default zone if blocked in the proposal" do
      expect(api).to receive(:remove_service).with(proposal_settings.default_zone, "ssh")

      subject.send(:configure_firewall)
    end

    context "when vnc is proposed to be open" do
      let(:service_available) { true }

      before do
        allow(proposal_settings).to receive(:open_vnc).and_return(true)
        allow(api).to receive(:service_supported?).with("tigervnc").and_return(service_available)
      end

      context "and the tigervnc service definition is available" do
        it "adds the tigervnc and the tigervnc-https services to the default zone" do
          expect(api).to receive(:add_service).with(proposal_settings.default_zone, "tigervnc")
          expect(api).to receive(:add_service)
            .with(proposal_settings.default_zone, "tigervnc-https")

          subject.send(:configure_firewall)
        end
      end

      context "and the tigervnc service definition is not available" do
        let(:service_available) { false }
        it "logs the error" do
          expect(subject.log).to receive(:error).with(/service definition is not available/)

          subject.send(:configure_firewall)
        end
      end
    end
  end
end
