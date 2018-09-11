#!/usr/bin/env rspec
# encoding: utf-8

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

require_relative "../../../test_helper"

require "cwm/rspec"
require "y2firewall/widgets/allowed_services"

describe Y2Firewall::Widgets::AllowedServices do
  AVAILABLE_SERVICES = ["dhcp", "https", "ssh"].freeze

  subject(:widget) { described_class.new(zone) }

  let(:zone) do
    Y2Firewall::Firewalld::Zone.new(name: "public").tap { |s| s.services = ["dhcp"] }
  end

  let(:firewall) do
    instance_double(Y2Firewall::Firewalld, current_service_names: AVAILABLE_SERVICES)
  end

  let(:available_svcs_table) do
    instance_double(Y2Firewall::Widgets::ServicesTable, update: nil, selected_service: "ssh")
  end

  let(:allowed_svcs_table) do
    instance_double(Y2Firewall::Widgets::ServicesTable, update: nil, selected_service: "dhcp")
  end

  before do
    allow(Y2Firewall::Firewalld).to receive(:instance).and_return(firewall)
    allow(Y2Firewall::Widgets::ServicesTable).to receive(:new)
      .with(widget_id: "available:#{zone.name}").and_return(available_svcs_table)
    allow(Y2Firewall::Widgets::ServicesTable).to receive(:new)
      .with(widget_id: "allowed:#{zone.name}").and_return(allowed_svcs_table)
  end

  include_examples "CWM::CustomWidget"

  describe "#handle" do
    context "adding a service to the list of allowed ones" do
      let(:event) { {"ID" => :add} }

      it "adds the selected service to the zone and updates both tables" do
        expect(zone).to receive(:add_service).with("ssh").and_call_original
        expect(allowed_svcs_table).to receive(:update).with(["dhcp", "ssh"])
        expect(available_svcs_table).to receive(:update).with(["https"])

        widget.handle(event)
      end
    end

    context "removing a service from the list of allowed ones" do
      let(:event) { {"ID" => :remove} }

      it "removes the selected service from the zone and updates both tables" do
        expect(zone).to receive(:remove_service).with("dhcp").and_call_original
        expect(available_svcs_table).to receive(:update).with(["dhcp", "https", "ssh"])
        expect(allowed_svcs_table).to receive(:update).with([])

        widget.handle(event)
      end
    end
  end
end
