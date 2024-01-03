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

require_relative "../../../../test_helper"
require "cwm/rspec"
require "y2firewall/widgets/pages/zone"

describe Y2Firewall::Widgets do
  let(:fake_zone) { double("fake zone", name: "zoe") }
  subject(:widget) { described_class.new(fake_zone, double("fake pager")) }
  before do
    allow(Y2Firewall::Widgets::AllowedServices)
      .to receive(:new).and_return(double("Allowed Services widget"))
  end

  describe Y2Firewall::Widgets::Pages::Zone do
    include_examples "CWM::Page"
  end

  describe Y2Firewall::Widgets::Pages::ServicesTab do
    include_examples "CWM::Tab"
  end

  describe Y2Firewall::Widgets::Pages::PortsTab do
    subject(:widget) { described_class.new(fake_zone) }
    include_examples "CWM::Tab"
  end
end

describe Y2Firewall::Widgets::Pages::PortsTab::PortsForProtocols do
  let(:fake_zone) { double("fake zone", name: "zoe") }
  subject(:widget) { described_class.new(fake_zone) }
  include_examples "CWM::CustomWidget"

  let(:input) { ["", "", "", ""] }
  before do
    allow(Yast::UI).to receive(:QueryWidget)
      .with(Id(:tcp), :Value).and_return(input[0])
    allow(Yast::UI).to receive(:QueryWidget)
      .with(Id(:udp), :Value).and_return(input[1])
    allow(Yast::UI).to receive(:QueryWidget)
      .with(Id(:sctp), :Value).and_return(input[2])
    allow(Yast::UI).to receive(:QueryWidget)
      .with(Id(:dccp), :Value).and_return(input[3])
  end

  describe "#init" do
    it "initializes the widgets correctly" do
      expect(fake_zone).to receive(:ports).and_return(["22-80/tcp"])
      expect(Yast::UI).to receive(:ChangeWidget).with(Id(:tcp), :Value, "22-80")
      expect(Yast::UI).to receive(:ChangeWidget).with(Id(:udp), :Value, "")
      expect(Yast::UI).to receive(:ChangeWidget).with(Id(:sctp), :Value, "")
      expect(Yast::UI).to receive(:ChangeWidget).with(Id(:dccp), :Value, "")
      expect { widget.init }.to_not raise_error
    end
  end

  describe "#validate and #store" do
    context "input is clean" do
      let(:input) { ["22-80", "", "", ""] }

      it "assigns the ports correctly" do
        expect(fake_zone).to receive(:ports=).with(["22-80/tcp"])
        expect(widget.validate).to eq(true)
        expect { widget.store }.to_not raise_error
      end
    end

    context "input is nonsense" do
      let(:input) { ["- - - - -", "", "", ""] }

      it "fails validation (with a popup)" do
        expect(Yast::UI).to receive(:SetFocus)
        expect(Yast::Popup).to receive(:Error)
        expect(widget.validate).to eq(false)
      end
    end
  end

  describe "#items_from_ui" do
    let(:expected) do
      ["11/tcp", "12/udp", "13/udp"]
    end

    it "parses comma separated items" do
      expect(subject.send(:items_from_ui, "11/tcp,12/udp,13/udp")).to eq(expected)
    end

    it "parses space separated items" do
      expect(subject.send(:items_from_ui, "11/tcp 12/udp 13/udp")).to eq(expected)
    end

    it "parses clumsily separated items" do
      expect(subject.send(:items_from_ui, "11/tcp  12/udp , 13/udp")).to eq(expected)
    end
  end

  let(:ports_h1) { { tcp: ["55555-55666", "44444"], udp: ["33333"] } }
  let(:ports_a1) { ["55555-55666/tcp", "44444/tcp", "33333/udp"] }

  describe "#ports_from_array" do
    it "parses a regular case" do
      expect(subject.send(:ports_from_array, ports_a1)).to eq(ports_h1)
    end
  end

  describe "#ports_to_array" do
    it "formats a regular case" do
      expect(subject.send(:ports_to_array, ports_h1)).to eq(ports_a1)
    end
  end
end
