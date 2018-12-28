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
require "cwm/service_widget"
require "y2firewall/widgets/pages/startup"

describe Y2Firewall::Widgets::Pages::Startup do
  subject(:widget) { described_class.new(double("fake pager")) }

  include_examples "CWM::Page"

  let(:service) { double("firewalld") }
  let(:service_widget) { double("ServiceWidget") }
  let(:fw_instance) { double("fw_instance", system_service: service) }

  before do
    allow(Y2Firewall::Firewalld).to receive(:instance).and_return(fw_instance)
    allow(::CWM::ServiceWidget).to receive(:new).and_return(service_widget)
  end

  describe "#contents" do
    it "includes the ::CWM::ServiceWidget content" do
      expect(widget.contents).to include(service_widget)
    end
  end
end
