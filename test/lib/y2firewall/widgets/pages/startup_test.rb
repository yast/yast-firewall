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

require_relative "../../../../test_helper.rb"
require "cwm/rspec"
require "y2firewall/widgets/pages/startup"

describe Y2Firewall::Widgets::Pages::Startup do
  include_examples "CWM::Page"

  let(:firewalld) { Y2Firewall::Firewalld.instance }
  let(:system_service) { Yast2::SystemService.build(Y2Firewall::Firewalld::SERVICE) }
  let(:service_status) { ::UI::ServiceStatus.new(system_service.service) }

  before do
    allow(subject).to receive(:status_widget).and_return(service_status)
  end

  describe "#store" do
    let(:enabled) { false }
    let(:reload) { true }

    before do
      allow(firewalld).to receive(:system_service).and_return(system_service)
      allow(service_status).to receive(:enabled_flag?).and_return(enabled)
      allow(service_status).to receive(:reload_flag?).and_return(reload)
    end

    context "when the service status enable flag is selected" do
      let(:enabled) { true }

      it "marks the service to be enabled on boot" do
        expect(system_service).to receive(:start_mode=).with(:on_boot)

        subject.store
      end
    end

    context "when the service status enable flag is not selected" do
      it "marks the service to be enabled manually" do
        expect(system_service).to receive(:start_mode=).with(:manual)

        subject.store
      end
    end

    context "when the service status reload flag is choosen" do
      let(:reload) { true }

      it "marks the service to be reloaded after write" do
        expect(system_service).to receive(:reload)

        subject.store
      end
    end
  end
end
