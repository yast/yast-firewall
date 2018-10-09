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
  include_examples "CWM::CustomWidget"

  AVAILABLE_SERVICES = ["dhcp", "https", "ssh"].freeze

  subject(:widget) { described_class.new(zone) }

  let(:zone) do
    Y2Firewall::Firewalld::Zone.new(name: "public").tap { |s| s.services = ["dhcp"] }
  end

  let(:firewall) do
    instance_double(Y2Firewall::Firewalld, current_service_names: AVAILABLE_SERVICES)
  end

  let(:available_svcs_table) do
    instance_double(
      Y2Firewall::Widgets::ServicesTable, :services= => nil, selected_services: ["ssh"]
    )
  end

  let(:allowed_svcs_table) do
    instance_double(
      Y2Firewall::Widgets::ServicesTable, :services= => nil, selected_services: ["dhcp"]
    )
  end

  before do
    allow(Y2Firewall::Firewalld).to receive(:instance).and_return(firewall)
    allow(Y2Firewall::Widgets::ServicesTable).to receive(:new)
      .with(widget_id: "known:#{zone.name}").and_return(available_svcs_table)
    allow(Y2Firewall::Widgets::ServicesTable).to receive(:new)
      .with(widget_id: "allowed:#{zone.name}").and_return(allowed_svcs_table)
  end

  describe "#validate" do
    context "when no service has been selected" do
      before do
        allow(available_svcs_table).to receive(:selected_services).and_return([])
        allow(allowed_svcs_table).to receive(:selected_services).and_return([])
      end

      it "returns true" do
        expect(widget.validate).to eq(true)
      end
    end

    context "when some service has been selected" do
      it "warns the user about unsaved changed and ask for continuing" do
        expect(Yast::Popup).to receive("YesNo").with(/Do you really want to continue/)
        widget.validate
      end

      it "returns whether the user wanted to continue or not" do
        expect(Yast::Popup).to receive("YesNo").and_return(false, true)
        expect(widget.validate).to eq(false)
        expect(widget.validate).to eq(true)
      end
    end
  end

  describe "#handle" do
    context "when it receives an event to add a service" do
      let(:event) { { "ID" => :add } }

      it "adds the selected service to the zone" do
        widget.handle(event)
        expect(zone.services).to contain_exactly("dhcp", "ssh")
      end

      it "updates services tables" do
        expect(allowed_svcs_table).to receive(:services=).with(["dhcp", "ssh"])
        expect(available_svcs_table).to receive(:services=).with(["https"])
        widget.handle(event)
      end
    end

    context "when it receives an event to remove a service" do
      let(:event) { { "ID" => :remove } }

      it "removes the selected service from the zone" do
        widget.handle(event)
        expect(zone.services).to be_empty
      end

      it "updates the services tables" do
        expect(available_svcs_table).to receive(:services=).with(["dhcp", "https", "ssh"])
        expect(allowed_svcs_table).to receive(:services=).with([])
        widget.handle(event)
      end
    end

    context "when it receives an event to add all available services" do
      let(:event) { { "ID" => :add_all } }

      it "adds all services to the zone" do
        widget.handle(event)
        expect(zone.services).to eq(AVAILABLE_SERVICES)
      end

      it "updates the services tables" do
        expect(allowed_svcs_table).to receive(:services=).with(AVAILABLE_SERVICES)
        expect(available_svcs_table).to receive(:services=).with([])
        widget.handle(event)
      end
    end

    context "when it receives an event to remove all available services" do
      let(:event) { { "ID" => :remove_all } }

      it "removes all services from the zone" do
        widget.handle(event)
        expect(zone.services).to be_empty
      end

      it "updates the services tables" do
        expect(available_svcs_table).to receive(:services=).with(AVAILABLE_SERVICES)
        expect(allowed_svcs_table).to receive(:services=).with([])
        widget.handle(event)
      end
    end
  end
end
