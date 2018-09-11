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
require "y2firewall/widgets/services_table"

describe Y2Firewall::Widgets::ServicesTable do
  include_examples "CWM::CustomWidget"

  subject(:widget) { described_class.new(services: ["dhcp"], widget_id: "table") }

  before do
    allow(Yast::UI).to receive(:QueryWidget).with(Id("table"), :SelectedItems)
      .and_return(["dhcp"])
  end

  describe "#update" do
    it "updates the list of items" do
      subject.update(["ssh"])
      expect(widget.items).to eq([["ssh", "ssh"]])
    end

    context "when some items are added" do
      before do
        allow(Yast::UI).to receive(:TextMode).and_return(textmode)
      end

      context "and YaST is running in graphical mode" do
        let(:textmode) { false }

        it "sets new items as selected" do
          expect(widget).to receive(:value=).with(["ssh"])
          subject.update(["ssh"])
        end
      end

      context "and YaST is running in text mode" do
        let(:textmode) { true }

        it "does not set any item as selected" do
          expect(widget).to_not receive(:value=)
          subject.update(["ssh"])
        end
      end
    end
  end
end
