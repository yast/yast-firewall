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
require "y2firewall/widgets/pages/zones"

describe Y2Firewall::Widgets::Pages::Zones do
  subject { described_class.new(double("fake pager")) }
  before do
    fw = double("fake firewall", zones: [])
    allow(Y2Firewall::Firewalld).to receive(:instance).and_return(fw)
  end

  include_examples "CWM::Page"
end

describe Y2Firewall::Widgets::Pages::Zones::AddButton do
  subject { described_class.new(double("pager"), double("table", value: "dmz")) }
  before do
    allow(Y2Firewall::Dialogs::Zone).to receive(:run)
  end

  include_examples "CWM::PushButton"

  describe "#handle" do
    it "shows zone dialog" do
      expect(Y2Firewall::Dialogs::Zone).to receive(:run)

      subject.handle
    end

    context "zone dialog confirmed" do
      before do
        allow(Y2Firewall::Dialogs::Zone).to receive(:run).and_return(:ok)
      end

      it "returns :redraw" do
        expect(subject.handle).to eq :redraw
      end

      it "adds zone to zones" do
        expect { subject.handle }.to change(subject.firewall, :zones)
      end
    end

    context "zone dialog canceled" do
      before do
        allow(Y2Firewall::Dialogs::Zone).to receive(:run).and_return(:cancel)
      end

      it "returns nil" do
        expect(subject.handle).to eq nil
      end
    end
  end
end

describe Y2Firewall::Widgets::Pages::Zones::EditButton do
  subject { described_class.new(double("pager"), double("table", value: "dmz")) }

  before do
    allow(Y2Firewall::Dialogs::Zone).to receive(:run)

    allow(subject.firewall).to receive(:find_zone).and_return(double(name: "dmz"))
  end

  include_examples "CWM::PushButton"
end

describe Y2Firewall::Widgets::Pages::Zones::RemoveButton do
  subject { described_class.new(double("pager"), double("table", value: "my_zone")) }

  before do
    allow(Y2Firewall::Dialogs::Zone).to receive(:run)

    allow(subject.firewall).to receive(:find_zone).and_return(double(name: "my_zone"))
  end

  include_examples "CWM::PushButton"
end
