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

require_relative "../../../test_helper.rb"
require "cwm/rspec"
require "y2firewall/widgets/proposal"
require "y2firewall/proposal_settings"

RSpec.shared_examples "CWM::CheckBox" do
  include_examples "CWM::AbstractWidget"
  include_examples "CWM::ValueBasedWidget"
end

describe Y2Firewall::Widgets do
  let(:proposal_settings) do
    instance_double(
      Y2Firewall::ProposalSettings, enable_firewall: true, enable_sshd: true,
        open_ssh: true, open_vnc: true
    )
  end

  describe Y2Firewall::Widgets::FirewallSSHProposal do
    subject(:widget) { described_class.new(proposal_settings) }

    include_examples "CWM::CustomWidget"

    describe "#initialize" do
      let(:vnc) { true }
      before do
        allow(Yast::Linuxrc).to receive("vnc").and_return(vnc)
      end

      it "initializes all the widgets that will be shown" do
        expect(widget.send("widgets").size).to eq(4)
      end

      context "when vnc was given by Linuxrc" do
        it "shows the open/close VNC Port widget" do
          expect(Y2Firewall::Widgets::OpenVNCPorts).to receive("new")

          described_class.new(proposal_settings)
        end
      end

      context "when vnc was not given by Linuxrc" do
        let(:vnc) { false }

        it "does not show the open/close VNC Port widget" do
          expect(Y2Firewall::Widgets::OpenVNCPorts).to_not receive("new")

          described_class.new(proposal_settings)
        end
      end
    end
  end

  describe Y2Firewall::Widgets::EnableFirewall do
    let(:widgets) do
      [
        instance_double(Y2Firewall::Widgets::OpenVNCPorts, enable: true, disable: true),
        instance_double(Y2Firewall::Widgets::OpenSSHPort, enable: true, disable: true)
      ]
    end

    subject { described_class.new(proposal_settings, widgets) }

    include_examples "CWM::CheckBox"

    describe "#init" do
      context "when firewall service is enabled in the proposal settings" do
        it "initializes the widget checked" do
          allow(proposal_settings).to receive("enable_firewall").and_return(true)
          expect(subject).to receive("value=").with(true)

          subject.init
        end
      end

      context "when firewall service is disabled in the proposal settings" do
        it "initializes the widget unchecked" do
          allow(proposal_settings).to receive("enable_firewall").and_return(false)
          expect(subject).to receive("value=").with(false)

          subject.init
        end
      end
    end

    describe "#handle" do
      before do
        subject.init
      end

      it "returns nil" do
        expect(subject.handle).to eq(nil)
      end

      context "when checked" do
        it "enables all the widgets given at initialization" do
          allow(subject).to receive(:checked?).and_return(true)
          expect(widgets).to all(receive("enable"))

          subject.handle
        end
      end

      context "when unchecked" do
        it "disables all the widgets given at initialization" do
          allow(subject).to receive(:checked?).and_return(false)
          expect(widgets).to all(receive("disable"))

          subject.handle
        end
      end
    end

    describe "#store" do
      context "when checked" do
        it "sets firewall service to be enabled in the proposal settings" do
          allow(subject).to receive(:checked?).and_return(true)
          expect(proposal_settings).to receive("enable_firewall!")

          subject.store
        end
      end

      context "when unchecked" do
        it "sets firewall service to be disabled in the proposal settings" do
          allow(subject).to receive(:checked?).and_return(false)
          expect(proposal_settings).to receive("disable_firewall!")

          subject.store
        end
      end
    end
  end

  describe Y2Firewall::Widgets::EnableSSHD do
    subject { described_class.new(proposal_settings) }

    include_examples "CWM::CheckBox"

    describe "#init" do
      context "when ssh service is enabled in the proposal settings" do
        it "initializes the widget checked" do
          allow(proposal_settings).to receive("enable_sshd").and_return(true)
          expect(subject).to receive("value=").with(true)

          subject.init
        end
      end

      context "when ssh service is disabled in the proposal settings" do
        it "initializes the widget unchecked" do
          allow(proposal_settings).to receive("enable_sshd").and_return(false)
          expect(subject).to receive("value=").with(false)

          subject.init
        end
      end
    end

    describe "#store" do
      context "when checked" do
        it "sets sshd service to be enabled in the proposal settings" do
          allow(subject).to receive(:checked?).and_return(true)
          expect(proposal_settings).to receive("enable_sshd!")

          subject.store
        end
      end

      context "when unchecked" do
        it "sets sshd service to be disabled in the proposal settings" do
          allow(subject).to receive(:checked?).and_return(false)
          expect(proposal_settings).to receive("disable_sshd!")

          subject.store
        end
      end
    end
  end

  describe Y2Firewall::Widgets::OpenSSHPort do
    subject { described_class.new(proposal_settings) }

    include_examples "CWM::CheckBox"

    describe "#init" do
      context "when the firewall service is enabled in the proposal settings" do
        it "initializes enabled the widget" do
          allow(proposal_settings).to receive("enable_firewall").and_return(true)
          expect(subject).to receive("enable")

          subject.init
        end
      end

      context "when the firewall service is disabled in the proposal settings" do
        it "initializes disabled the widget" do
          allow(proposal_settings).to receive("enable_firewall").and_return(false)
          expect(subject).to receive("disable")

          subject.init
        end
      end

      describe "#init" do
        context "when ssh port is opened in the proposal settings" do
          it "initializes the widget checked" do
            allow(proposal_settings).to receive("open_ssh").and_return(true)
            expect(subject).to receive("value=").with(true)

            subject.init
          end
        end

        context "when ssh port is closed in the proposal settings" do
          it "initializes the widget unchecked" do
            allow(proposal_settings).to receive("open_ssh").and_return(false)
            expect(subject).to receive("value=").with(false)

            subject.init
          end
        end
      end
    end

    describe "#store" do
      context "when checked" do
        it "sets ssh ports to be opened in the proposal settings" do
          allow(subject).to receive(:checked?).and_return(true)
          expect(proposal_settings).to receive("open_ssh!")

          subject.store
        end
      end

      context "when unchecked" do
        it "sets ssh ports to be closed in the proposal settings" do
          allow(subject).to receive(:checked?).and_return(false)
          expect(proposal_settings).to receive("close_ssh!")

          subject.store
        end
      end
    end
  end

  describe Y2Firewall::Widgets::OpenVNCPorts do
    subject { described_class.new(proposal_settings) }

    include_examples "CWM::CheckBox"

    describe "#init" do
      context "when the firewall service is enabled in the proposal settings" do
        it "initializes enabled the widget" do
          allow(proposal_settings).to receive("enable_firewall").and_return(true)
          expect(subject).to receive("enable")

          subject.init
        end
      end

      context "when the firewall service is disabled in the proposal settings" do
        it "initializes disabled the widget" do
          allow(proposal_settings).to receive("enable_firewall").and_return(false)
          expect(subject).to receive("disable")

          subject.init
        end
      end

      describe "#init" do
        context "when vnc ports are opened in the proposal settings" do
          it "initializes the widget checked" do
            allow(proposal_settings).to receive("open_vnc").and_return(true)
            expect(subject).to receive("value=").with(true)

            subject.init
          end
        end

        context "when vnc ports are closed in the proposal settings" do
          it "initializes the widget unchecked" do
            allow(proposal_settings).to receive("open_vnc").and_return(false)
            expect(subject).to receive("value=").with(false)

            subject.init
          end
        end
      end
    end

    describe "#store" do
      context "when checked" do
        it "sets vnc ports to be opened in the proposal settings" do
          allow(subject).to receive(:checked?).and_return(true)
          expect(proposal_settings).to receive("open_vnc!")

          subject.store
        end
      end

      context "when unchecked" do
        it "sets vnc ports to be closed in the proposal settings" do
          allow(subject).to receive(:checked?).and_return(false)
          expect(proposal_settings).to receive("close_vnc!")

          subject.store
        end
      end
    end
  end

  describe Y2Firewall::Widgets::SelinuxPolicy do
    subject { described_class.new(proposal_settings) }

    include_examples "CWM::ComboBox"
  end
end
