#!/usr/bin/env rspec

# ------------------------------------------------------------------------------
# Copyright (c) 2018 SUSE LLC
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
require "y2firewall/dialogs/main"

describe Y2Firewall::Dialogs::Main do
  subject { described_class.new }
  let(:firewall) { Y2Firewall::Firewalld.instance }

  before do
    firewall.reset
    allow(firewall).to receive(:read)
    allow_any_instance_of(Y2Firewall::Widgets::OverviewTreePager)
      .to receive(:items).and_return([])
  end

  include_examples "CWM::Dialog"

  describe ".new" do
    it "reads the firewall configuration" do
      expect(firewall).to receive(:read)
      described_class.new
    end
  end

  describe "#contents" do
    it "containts a firewall overview pager widget" do
      widget = subject.contents.nested_find do |item|
        item.is_a?(Y2Firewall::Widgets::OverviewTreePager)
      end

      expect(widget).to_not be(nil)
    end
  end

  describe "#run" do
    let(:result) { :next }
    let(:action) { nil }
    let(:firewall_service) do
      instance_double("Yast2::SystemService",
        save:     true,
        running?: true,
        restart:  nil,
        action:   action)
    end

    before do
      allow_any_instance_of(CWM::Dialog).to receive(:run).and_return(result)
      allow(firewall).to receive(:system_service).and_return(firewall_service)
      allow(firewall).to receive(:modified?).and_return(true)
    end

    context "when the user accepts the changes" do
      it "writes the firewall configuration" do
        expect(firewall).to receive(:write_only)

        subject.run
      end

      it "updates the firewalld systemd service status" do
        expect(firewall.system_service).to receive(:save)

        subject.run
      end

      context "user has not changed the service running state" do
        let(:action) { nil }

        it "restart the running firewalld systemd service" do
          expect(firewall.system_service).to receive(:restart)

          subject.run
        end
      end

      context "service has been stopped by the user" do
        let(:action) { :stop }

        it "do not restart the running firewalld systemd service" do
          expect(firewall.system_service).to_not receive(:restart)

          subject.run
        end
      end

      it "returns :next" do
        expect(subject.run).to eql(:next)
      end
    end

    context "when the user cancels" do
      let(:result) { :abort }

      it "returns :abort" do
        expect(subject.run).to eql(:abort)
      end
    end
  end
end
